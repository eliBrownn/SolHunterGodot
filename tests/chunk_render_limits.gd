extends SceneTree
## Geometry equivalence, hard operation caps and retirement/admission backpressure.
const Ground = preload("res://scripts/presentation/streaming_ground.gd")
const CoarseJob = preload("res://scripts/presentation/coarse_ground_job.gd")
const DetailJob = preload("res://scripts/presentation/stream_chunk_job.gd")
var checks := 0
var failures := 0

class UploadProbe extends Node3D:
	var calls := 0
	var last_finish_uploaded := true
	func finish_step() -> bool:
		calls += 1
		return calls >= 9

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)

func _initialize() -> void:
	run.call_deferred()

func geometry(chunk: Node3D) -> Dictionary:
	var result := {}
	for child in chunk.get_children():
		if child is MultiMeshInstance3D:
			var surfaces: Array = []
			for surface in range(child.multimesh.mesh.get_surface_count()): surfaces.append(child.multimesh.mesh.surface_get_arrays(surface))
			result[str(child.name)] = [surfaces, child.multimesh.buffer]
		elif child is MeshInstance3D:
			result[str(child.name)] = child.mesh.surface_get_arrays(0)
	return result

func run() -> void:
	var terrain := WorldTerrain.new(17)
	var nature: NatureSettings = load("res://resources/nature_settings.tres")
	var baseline: Script = load("res://artifacts/chunk-limits/streaming_ground_before.gd") if "--paired" in OS.get_cmdline_user_args() else null
	var reference_ms := 0.0
	var current_ms := 0.0
	var max_slice_ms := 0.0
	for coord in [Vector2i(-1,-1), Vector2i(0,0), Vector2i(3,3)]:
		# Match warm canonical dependencies before either CPU measurement.
		Ground.build(terrain, coord, 4, nature)
		for spacing in [1,4,8]:
			var expected: ArrayMesh
			if baseline != null:
				baseline.build(terrain, coord, spacing, nature) # Warm the same canonical query working set.
				var began := Time.get_ticks_usec()
				expected = baseline.build(terrain, coord, spacing, nature)
				reference_ms += (Time.get_ticks_usec() - began) / 1000.0
			var job := CoarseJob.new(terrain, coord, spacing, nature)
			check(not job.advance(Time.get_ticks_usec()-1, 7) and job.operations == 0, "Expired coverage deadline does no mesh work")
			var done := false
			while not done:
				var began := Time.get_ticks_usec()
				done = job.advance(Time.get_ticks_usec()+1000000, 7)
				var duration := (Time.get_ticks_usec()-began)/1000.0
				current_ms += duration
				max_slice_ms = maxf(max_slice_ms,duration)
				check(job.operations <= 7 and job.uploads <= 1, "Coarse assembly obeys operation and single-upload bounds")
				check(done or job.mesh == null, "Incomplete geometry is never published")
			check(job.vertex_cache.size() <= 289, "Vertex attribute cache is bounded by the chunk grid")
			if expected != null:
				check(expected.surface_get_arrays(0) == job.mesh.surface_get_arrays(0), "Sliced cached coverage exactly matches previous vertices, colors, normals, UVs, blends and indices")
	if baseline != null:
		var previous: Script = load("res://artifacts/chunk-limits/solid_chunk_before.gd")
		var current: Script = load("res://scripts/presentation/solid_chunk.gd")
		var elapsed := [0.0, 0.0]
		for coord in [Vector2i.ZERO, Vector2i(-1,-1), Vector2i(3,3)]:
			var cells := terrain.extract_chunk(coord)
			for script in [previous, current]:
				var warm: Node3D = script.new()
				warm.build(cells, terrain, coord, nature)
				warm.free()
		for coord in [Vector2i.ZERO, Vector2i(-1,-1), Vector2i(3,3)]:
			var cells := terrain.extract_chunk(coord)
			var snapshots: Array = []
			for script in [previous, current]:
				var chunk: Node3D = script.new()
				var began := Time.get_ticks_usec()
				chunk.build(cells, terrain, coord, nature)
				elapsed[0 if script == previous else 1] += (Time.get_ticks_usec()-began)/1000.0
				snapshots.append([geometry(chunk), chunk.living_sources.duplicate(true), chunk.cosmetic_records.duplicate(true)])
				chunk.free()
			check(snapshots[0] == snapshots[1], "Detailed vertex reuse preserves all uploaded geometry, instances, cosmetics and living-source records")
		print("DETAIL CPU previous %.3f ms, current %.3f ms (both paths warmed, previous first)" % elapsed)
	var probe := UploadProbe.new()
	var detail := DetailJob.new(terrain, Vector2i.ZERO, nature, probe)
	detail.geography_prepared = detail.geography_count
	detail.generated = 256
	detail.built = 256
	check(not detail.advance(Time.get_ticks_usec()+1000000, 128, 2) and probe.calls == 2, "Detail finalization cannot exceed its upload-step cap even with spare time")
	check(detail.last_operations == 2 and detail.last_upload_steps == 2, "Detail counters expose actual work")
	check(not detail.advance(Time.get_ticks_usec()+1000000, 1, 8) and detail.last_operations == 1, "Operation cap also bounds finalization")
	detail.discard()
	var retired_chunk: Node3D = load("res://scripts/presentation/solid_chunk.gd").new()
	var shared_cells := [{"height": 2.0, "identity": "unchanged"}]
	retired_chunk.set_meta("source_cells", shared_cells)
	for index in range(96):
		retired_chunk.pick_objects.append({"cell": index})
		retired_chunk.living_sources[index] = {"cell": index}
	var original_count: int = retired_chunk.pick_objects.size()
	retired_chunk.retire_step()
	check(original_count - retired_chunk.pick_objects.size() == 32, "A cleanup step releases only a bounded group of owned picking records")
	while not retired_chunk.retire_step(): pass
	check(shared_cells == [{"height": 2.0, "identity": "unchanged"}], "Incremental disposal cannot mutate shared source-cell metadata")
	retired_chunk.free()
	var scene: Node3D = load("res://scenes/world_3d.tscn").instantiate()
	root.add_child(scene)
	scene.world.smoke_mode = true
	scene.world.set_process(false)
	scene.set_process(false)
	var before: Dictionary = scene.world.persistent_state.snapshot()
	scene.active_view = scene.active_view.duplicate()
	scene.active_view.retirement_steps_per_frame = 2
	for index in range(3):
		var retired := Node3D.new()
		for child in range(12): retired.add_child(Node3D.new())
		scene.retired_solid.append(retired)
	scene.retire_detail(Time.get_ticks_usec()-1)
	check(scene.retirement_steps_used == 0, "Expired retirement deadline frees nothing")
	while not scene.retired_solid.is_empty():
		scene.retire_detail(Time.get_ticks_usec()+1000000)
		check(scene.retirement_steps_used <= 2, "Retirement frees bounded children rather than whole chunk bursts")
	var jobs: int = scene.stream_jobs_started
	scene.prepare_stream_chunk(Vector2i(99,99), Time.get_ticks_usec()-1)
	check(scene.stream_jobs_started == jobs, "Expired preparation does not admit new jobs")
	while scene.resident_detail_count() < scene.active_view.max_resident_chunks:
		scene.retired_solid.append(Node3D.new())
	var prepared: Variant = scene.prepare_stream_chunk(Vector2i(99,99), Time.get_ticks_usec()+1000000)
	check(prepared == null and scene.stream_jobs_started == jobs, "Resident limit applies backpressure instead of forcing mass eviction")
	check(scene.world.persistent_state.snapshot() == before, "Rendering limits never mutate authoritative expedition contents")
	check(scene.active_view.valid(), "Default bounded streaming and Vastra settings are valid")
	scene.active_view.vastra_distance = NAN
	check(not scene.active_view.valid(), "Nonfinite effect ranges are rejected")
	scene.environment.sky = null
	scene.free()
	print("CHUNK LIMITS: %d checks, %d failures; previous CPU %.3f ms, sliced CPU %.3f ms, max 7-operation slice %.3f ms" % [checks,failures,reference_ms,current_ms,max_slice_ms])
	quit(0 if failures == 0 else 1)
