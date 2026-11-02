extends RefCounted
## Main-owned bounded scheduling; workers never capture this coordinator or its host.
const Context = preload("res://scripts/presentation/chunk_build_context.gd")
const Task = preload("res://scripts/presentation/chunk_preparation_task.gd")
var slots: Array[Dictionary] = []
var loader := preload("res://scripts/presentation/chunk_asset_loader.gd").new()
var source: WorldTerrain
var tuning: NatureSettings
var content := -1
var epoch := 0
var failed := false
var closed := false
var submitted := 0
var collected := 0
var completed := 0
var discarded := 0
var asset_wait_frames := 0
var max_capture_ms := 0.0
var max_compute_ms := 0.0
var peak_result_bytes := 0
var latencies: Array[float] = []
var cached_p95_ms := 0.0
var announced := {}
var retired: Array[RefCounted] = []
var owner := OS.get_thread_caller_id()

func prime(terrain: WorldTerrain, nature: NatureSettings, revision: int, concurrency: int) -> void:
	# Capture immutable descriptors at the existing startup/rebuild boundary.
	sync_inputs(terrain,nature,revision)
	var limit := clampi(concurrency,1,2)
	while slots.size() < limit: slots.append({"context":null,"task":null,"handle":-1,"state":"idle","epoch":epoch})
	for index in range(limit):
		var slot: Dictionary = slots[index]
		if slot.task != null or slot.context != null: continue
		var began := Time.get_ticks_usec()
		slot.context = Context.new()
		slot.context.capture(source,tuning)
		slot.epoch = epoch
		max_capture_ms = maxf(max_capture_ms,(Time.get_ticks_usec()-began)/1000.0)

func reservations() -> int:
	var count := retired.size()
	for slot in slots:
		if slot.task != null: count += 1
	return count

func sync_inputs(terrain: WorldTerrain, nature: NatureSettings, revision: int) -> void:
	assert(OS.get_thread_caller_id() == owner)
	if source == terrain and tuning == nature and content == revision: return
	invalidate()
	source = terrain
	tuning = nature
	content = revision
	failed = false

func poll() -> void:
	assert(OS.get_thread_caller_id() == owner)
	var deadline := Time.get_ticks_usec() + 250
	while not retired.is_empty() and Time.get_ticks_usec() < deadline:
		if retired[0].retire_data_step(): retired.pop_front()
	loader.advance()
	for slot in slots:
		if slot.handle < 0 or not WorkerThreadPool.is_task_completed(slot.handle): continue
		WorkerThreadPool.wait_for_task_completion(slot.handle)
		collected += 1
		slot.handle = -1
		var task: RefCounted = slot.task
		if task.is_cancelled() or task.epoch != epoch:
			discarded += 1
			retire_task(task)
			slot.task = null
			if slot.epoch != epoch: slot.context = null
			continue
		if task.finished_phase != task.phase and task.failure.is_empty(): task.failure = "Incomplete worker stage"
		if not task.failure.is_empty():
			push_warning("Background chunk rejected: " + task.failure + ". Continuing with serial preparation.")
			failed = true
			retire_task(task)
			invalidate()
			return
		max_compute_ms = maxf(max_compute_ms,task.compute_ms)
		if task.phase == 0: slot.state = "assets"
		else:
			slot.state = "ready"
			peak_result_bytes = maxi(peak_result_bytes,task.result_bytes)

func advance(wanted: Array[Vector2i], deadline: int, capacity: int, concurrency: int) -> void:
	assert(OS.get_thread_caller_id() == owner)
	poll()
	if failed or closed or source == null or not retired.is_empty(): return
	for slot in slots:
		if slot.task == null: continue
		if not wanted.has(slot.task.coord):
			if slot.handle >= 0: slot.task.cancel()
			else:
				discarded += 1
				retire_task(slot.task)
				slot.task = null
			continue
		if slot.state != "assets" or slot.handle >= 0: continue
		var task: RefCounted = slot.task
		for path in task.paths:
			if Time.get_ticks_usec() >= deadline: break
			var key: String = path.get_file().get_basename()
			if task.context.definitions.has(key): continue
			# The pinned dummy renderer reported RID initialization errors with
			# threaded mesh acquisition during publication. Headless correctness
			# runs acquire assets inline; rendered runs exercise the async path.
			if DisplayServer.get_name() == "headless":
				task.context.prepare_definition(key)
				continue
			var single: Array[String] = [path]
			if loader.ensure(single): task.context.prepare_definition(key)
			else: asset_wait_frames += 1
		var ready := true
		for path in task.paths:
			if not task.context.definitions.has(path.get_file().get_basename()): ready = false
		if ready:
			task.phase = 1
			slot.state = "computing"
			slot.handle = WorkerThreadPool.add_task(task.run,false,"Chunk geometry and grass")
			submitted += 1
	if Time.get_ticks_usec() >= deadline or reservations() >= capacity: return
	var limit := clampi(concurrency,1,2)
	while slots.size() < limit: slots.append({"context":null,"task":null,"handle":-1,"state":"idle","epoch":epoch})
	for index in range(limit):
		var slot: Dictionary = slots[index]
		if slot.task != null: continue
		var next: Variant = null
		for coord in wanted:
			var present := false
			for other in slots:
				if other.task != null and other.task.coord == coord: present = true
			if not present:
				next = coord
				break
		if next == null: return
		if reservations() >= capacity: return
		if slot.context == null or slot.context.definitions.size() > 128:
			var began := Time.get_ticks_usec()
			slot.context = Context.new()
			slot.context.capture(source,tuning)
			max_capture_ms = maxf(max_capture_ms,(Time.get_ticks_usec()-began)/1000.0)
		slot.epoch = epoch
		var task := Task.new()
		task.context = slot.context
		task.coord = next
		task.epoch = epoch
		task.requested_usec = announced.get(next,Time.get_ticks_usec())
		slot.task = task
		slot.state = "generating"
		slot.handle = WorkerThreadPool.add_task(task.run,false,"Chunk terrain and dependencies")
		submitted += 1
		if reservations() >= capacity or Time.get_ticks_usec() >= deadline: break

func note_requests(wanted: Array[Vector2i]) -> void:
	for coord in announced.keys():
		if not wanted.has(coord): announced.erase(coord)
	for coord in wanted:
		if not announced.has(coord): announced[coord] = Time.get_ticks_usec()

func ready_coord(wanted: Array[Vector2i]) -> Variant:
	for coord in wanted:
		for slot in slots:
			if slot.task != null and slot.state == "ready" and slot.task.coord == coord and slot.task.epoch == epoch: return coord
	return null

func take(coord: Vector2i) -> RefCounted:
	assert(OS.get_thread_caller_id() == owner)
	for slot in slots:
		if slot.task == null or slot.state != "ready" or slot.task.coord != coord or slot.task.epoch != epoch: continue
		var task: RefCounted = slot.task
		var data: RefCounted = task.data
		for key in data.meshes: data.meshes[key] = task.context.registry[data.meshes[key]]
		for object in data.pick_objects: object.mesh = task.context.registry[object.mesh]
		data.catalog = null
		slot.task = null
		slot.state = "idle"
		return task
	return null

func published(coord: Vector2i, requested_usec: int) -> void:
	completed += 1
	latencies.append((Time.get_ticks_usec()-requested_usec)/1000.0)
	if latencies.size() > 512: latencies.pop_front()
	var sorted := latencies.duplicate()
	sorted.sort()
	cached_p95_ms = sorted[int((sorted.size()-1)*0.95)]
	announced.erase(coord)

func invalidate() -> void:
	assert(OS.get_thread_caller_id() == owner)
	epoch += 1
	announced.clear()
	loader.invalidate()
	for slot in slots:
		if slot.handle >= 0: slot.task.cancel()
		else:
			if slot.task != null: retire_task(slot.task)
			slot.task = null
			slot.context = null
			slot.state = "idle"

func shutdown() -> void:
	assert(OS.get_thread_caller_id() == owner)
	closed = true
	invalidate()
	for slot in slots:
		if slot.handle >= 0:
			WorkerThreadPool.wait_for_task_completion(slot.handle)
			collected += 1
			slot.handle = -1
		if slot.task != null: retire_task(slot.task)
	slots.clear()
	retired.clear()
	loader.shutdown()

func retire_task(task: RefCounted) -> void:
	if task.data == null: return
	task.data.cell_work.clear() # Break the cursor's self-reference after execution ends.
	task.data.catalog = null
	retired.append(task.data)
	task.data = null

func statistics() -> Dictionary:
	var sorted := latencies.duplicate()
	sorted.sort()
	var oldest := 0.0
	for began in announced.values(): oldest = maxf(oldest,(Time.get_ticks_usec()-began)/1000.0)
	return {"submitted":submitted,"collected":collected,"completed":completed,"discarded":discarded,"reserved":reservations(),"missing":announced.size(),"oldest_request_ms":oldest,"asset_wait_frames":asset_wait_frames,"max_capture_ms":max_capture_ms,"max_compute_ms":max_compute_ms,"peak_result_bytes":peak_result_bytes,"latency_p50_ms":sorted[int((sorted.size()-1)*0.50)] if not sorted.is_empty() else 0.0,"latency_p95_ms":sorted[int((sorted.size()-1)*0.95)] if not sorted.is_empty() else 0.0,"latency_max_ms":sorted.back() if not sorted.is_empty() else 0.0,"failed":failed,"assets":loader.statistics()}
