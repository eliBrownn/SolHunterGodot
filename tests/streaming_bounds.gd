extends SceneTree

var checks := 0
var failures := 0

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var scene: Node3D = load("res://scenes/world_3d.tscn").instantiate()
	root.add_child(scene)
	var world: Node2D = scene.world
	world.smoke_mode = true
	world.set_process(false)
	scene.set_process(false)
	var state_before: Dictionary = world.persistent_state.snapshot()
	var home_cells: Array[Dictionary] = world.chunks[Vector2i.ZERO].view.cells.duplicate(true)
	var initial: int = world.pending.size()
	var initial_center: Vector2i = world.terrain.chunk_of(world.cell)
	for coord: Vector2i in world.pending:
		check(scene.ViewStreaming.within_radius(coord, initial_center, 3), "Default generation requests only the nearby three chunk rings")
	var started := Time.get_ticks_msec()
	for frame in range(scene.stream_capacity() * 128):
		if world.pending.is_empty(): break
		world.plan_chunks()
		world._process(0)
		check(scene.resident_detail_count() <= scene.active_view.max_resident_chunks, "Preparation and retirement share the resident bound")
		check(scene.stream_operations_used <= scene.active_view.chunk_operations_per_frame and scene.stream_upload_steps_used <= scene.active_view.chunk_upload_steps_per_frame, "Detail operation/upload caps hold throughout queue draining")
		check(scene.streaming_ground.last_operations <= scene.active_view.ground_operations_per_frame and scene.streaming_ground.last_uploads <= scene.active_view.ground_uploads_per_frame, "Temporary coverage respects frame operation/upload limits")
	print("STREAM AUDIT: initial=%d remaining=%d jobs=%d completed=%d cancelled=%d work_frames=%d elapsed_ms=%d" % [initial, world.pending.size(), scene.stream_jobs_started, scene.stream_jobs_completed, scene.stream_jobs_cancelled, scene.stream_work_frames, Time.get_ticks_msec()-started])
	check(world.pending.is_empty(), "Stationary production queue drains")
	check(scene.stream_jobs_started == scene.stream_jobs_completed and scene.stream_jobs_cancelled == 0, "Stable view finishes each requested job without restarts")
	var jobs: int = scene.stream_jobs_started
	var work_frames: int = scene.stream_work_frames
	for frame in range(120):
		world.plan_chunks()
		world._process(0)
	check(scene.stream_jobs_started == jobs and scene.stream_work_frames == work_frames, "Ready stationary view performs no ordinary chunk generation")
	world.cell = Vector2i(64, 0)
	world.camera.position = world.center(world.cell)
	scene.apply_camera()
	world.plan_chunks()
	check(not world.pending.is_empty(), "Approaching ungenerated chunks resumes the nearby generation queue")
	# Travel faster than preparation, including negative chunks and a return.
	# This exercises cancellation, cache retirement and queue replacement.
	for at in [Vector2i(160, 0), Vector2i(-160, -160), Vector2i(320, 160), Vector2i.ZERO]:
		world.cell = at
		world.camera.position = world.center(at)
		scene.apply_camera()
		world.plan_chunks()
		var center: Vector2i = world.terrain.chunk_of(at)
		var unique := {}
		for coord: Vector2i in world.pending:
			check(scene.ViewStreaming.within_radius(coord, center, scene.active_view.active_chunk_radius), "Requests stay in the hard player radius")
			unique[coord] = true
		check(unique.size() == world.pending.size(), "Queue contains no repeated requests")
		for frame in range(32):
			var published: int = scene.stream_jobs_completed
			world._process(0)
			check(scene.stream_jobs_completed - published <= scene.active_view.chunks_per_frame, "Frame publication budget remains bounded")
			check(world.chunks.size() <= scene.stream_capacity() and scene.resident_detail_count() <= scene.active_view.max_resident_chunks, "Travel bounds live, hidden, retired and preparing detail")
	check(world.terrain.extract_chunk(Vector2i.ZERO) == home_cells, "Returning reconstructs identical generated contents")
	check(world.persistent_state.snapshot() == state_before, "Streaming does not mutate persistent expedition contents")
	check(scene.keep_stream_chunk(Vector2i(scene.active_view.active_chunk_radius + 1, 0)), "Unloading buffer retains the departure boundary")
	check(not scene.keep_stream_chunk(Vector2i(scene.active_view.active_chunk_radius + 2, 0)), "Chunks beyond the unloading buffer retire")
	var tuning: View3DSettings = scene.active_view.duplicate()
	tuning.max_resident_chunks = 64
	tuning.stream_detail_cache_chunks = 8
	check(tuning.valid(), "Lower bounded resident tuning is admitted")
	for azimuth in [0.0, 90.0, 180.0, -90.0]:
		scene.view_azimuth = azimuth
		scene.update_camera_pose()
		var plan: Array[Vector2i] = scene.ViewStreaming.plan(scene.camera, world.camera.position / 32.0, world.cell, tuning, scene.height_bound())
		check(plan.size() <= scene.ViewStreaming.live_capacity(tuning) and plan.has(Vector2i.ZERO), "Tight resident cap prioritizes player coverage through camera turns")
	scene.view_settings = tuning
	scene.apply_view_settings()
	for frame in range(64):
		world._process(0)
		check(scene.resident_detail_count() <= 64 and world.chunks.size() <= scene.stream_capacity(), "Reapplying a smaller cap bounds existing caches and pending work")
	# Deliberately avoid mutating the resource currently applied to the scene.
	tuning = tuning.duplicate()
	tuning.max_resident_chunks = 63
	check(not tuning.valid(), "Invalid resident bounds are rejected")
	print("STREAM BOUNDS: %d checks, %d failures." % [checks, failures])
	print("STREAM PEAKS: detail slices %.3f ms; stages %s; runtime coverage %.3f ms; initial/rebuild coverage %.3f ms; retirement %.3f ms" % [scene.max_stream_slice_ms, str(scene.stream_step_peaks), scene.streaming_ground.max_runtime_ms, scene.streaming_ground.max_prepare_ms, scene.max_retirement_ms])
	scene.environment.sky = null
	scene.free()
	quit(0 if failures == 0 else 1)
