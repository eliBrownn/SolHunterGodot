extends RefCounted
## Finite worker stage on one exclusively leased context. Never owns a scene node.
const Data = preload("res://scripts/presentation/chunk_build_data.gd")
const Planner = preload("res://scripts/presentation/chunk_asset_plan.gd")
const Row = preload("res://scripts/presentation/chunk_buffer_task.gd")
const MAX_RESULT_BYTES := 32 * 1024 * 1024
const MAX_INSTANCES := 32768
var context: RefCounted
var coord := Vector2i.ZERO
var epoch := 0
var phase := 0
var cells: Array[Dictionary] = []
var paths: Array[String] = []
var data: RefCounted
var lock := Mutex.new()
var cancelled := false
var failure := ""
var compute_ms := 0.0
var result_bytes := 0
var worker_id := -1
var finished_phase := -1
var pick_bounds := AABB()
var traversal: Array[AABB] = []
var requested_usec := 0

func cancel() -> void:
	lock.lock()
	cancelled = true
	lock.unlock()

func is_cancelled() -> bool:
	lock.lock()
	var value := cancelled
	lock.unlock()
	return value

func run() -> void:
	var began := Time.get_ticks_usec()
	worker_id = WorkerThreadPool.get_caller_task_id()
	if phase == 0: generate()
	else: prepare()
	compute_ms += (Time.get_ticks_usec() - began) / 1000.0

func generate() -> void:
	var terrain: WorldTerrain = context.terrain
	var low := terrain.geography.region(Vector2(coord * 16 - Vector2i(2,2))) - Vector2i(2,2)
	var high := terrain.geography.region(Vector2(coord * 16 + Vector2i(17,17))) + Vector2i(2,2)
	for y in range(low.y, high.y + 1):
		for x in range(low.x, high.x + 1):
			while not terrain.geography.prepare_paths(terrain,Vector2i(x,y)):
				if is_cancelled(): return
	for index in range(256):
		if is_cancelled(): return
		var cell := coord * 16 + Vector2i(index % 16, index / 16)
		var sample := terrain.sample(cell)
		cells.append(sample)
		for path in Planner.for_cell(terrain,cell,sample,context.nature,context):
			if not paths.has(path): paths.append(path)
		if paths.size() > 128:
			failure = "Chunk dependency ceiling exceeded"
			return
	finished_phase = 0

func prepare() -> void:
	data = Data.new()
	data.catalog = context
	data.surface_uvs = context.surface_uvs
	context.failure = ""
	for index in range(256):
		while not data.build_cell_step(cells,context.terrain,coord,context.nature,index):
			if is_cancelled() or not context.failure.is_empty():
				failure = context.failure
				return
		if is_cancelled() or not context.failure.is_empty():
			failure = context.failure
			return
	var count := 0
	for kind in data.batches:
		var buffer := PackedFloat32Array()
		var groups := {}
		var row_index := 0
		var custom: bool = context.custom_tokens.get(data.meshes.get(kind,-1),false)
		for entry in data.batches[kind]:
			count += 1
			if count % 32 == 0 and is_cancelled(): return
			if count > MAX_INSTANCES:
				failure = "Chunk instance ceiling exceeded"
				return
			Row.append_row(buffer,entry.transform,entry.color,custom)
			if entry.has("plant_cell"):
				if not groups.has(entry.plant_cell): groups[entry.plant_cell] = {}
				var individual: bool = entry.plant_pivot == entry.transform.origin
				var suffix := ":roots" if individual else ":"+str(entry.plant_pivot)
				if not groups[entry.plant_cell].has(suffix): groups[entry.plant_cell][suffix] = {"indices":PackedInt32Array(),"pivot":entry.plant_pivot,"individual_roots":individual}
				groups[entry.plant_cell][suffix].indices.append(row_index)
			row_index += 1
		data.prepared_buffers[kind] = buffer
		data.prepared_groups[kind] = groups
	for index in range(data.pick_objects.size()):
		if index % 32 == 0 and is_cancelled(): return
		var object: Dictionary = data.pick_objects[index]
		object.inverse = object.transform.affine_inverse()
		var box: AABB = object.transform * object.bounds.grow(0.02)
		traversal.append(box)
		pick_bounds = box if index == 0 else pick_bounds.merge(box)
	data.terrain_vertex_cache.clear()
	data.build_biome_patches.clear()
	result_bytes = var_to_bytes([cells,data.batches,data.terrain_surfaces,data.pick_objects,data.cosmetic_records,data.living_sources,data.prepared_buffers,data.prepared_groups,traversal]).size()
	if result_bytes > MAX_RESULT_BYTES: failure = "Chunk result byte ceiling exceeded"
	finished_phase = 1
