extends SceneTree
## Camera turns must not bring the loading horizon into the playable foreground.
var checks := 0
var failures := 0

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)

func _initialize() -> void:
	create_timer(120).timeout.connect(func() -> void: quit(1))
	run.call_deferred()

func run() -> void:
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280, 800)
	var scene: Node3D = load("res://scenes/world_3d.tscn").instantiate()
	root.add_child(scene)
	var world: Node2D = scene.world
	world.smoke_mode = true
	world.new_expedition(17)
	world.set_process(false)
	scene.set_process(false)
	scene.atmosphere_settings = scene.atmosphere_settings.duplicate(false)
	scene.atmosphere_settings.cycle_enabled = false
	scene.atmosphere_settings.starting_phase = 0.5
	scene.atmosphere_settings.weather = "clear"
	scene.apply_atmosphere_settings()
	var before: Dictionary = world.persistent_state.snapshot()
	var horizon: float = scene.active_view.render_distance - 4.0
	check(scene.active_view.fog_start_fraction >= 0.8, "Default clear-weather fog starts in the distant fifth of the view")
	var smallest := INF
	for pose in [Vector3(90, 35, 22), Vector3(-90, 10, 40), Vector3(180, 80, 8), Vector3(0, 35, 22)]:
		scene.view_azimuth = pose.x
		scene.view_elevation = pose.y
		scene.target_size = pose.z
		scene.apply_camera()
		# Coverage now shares the detailed preparation budget. Let its queue
		# finish over bounded slices before checking complete horizon coverage.
		for preparation in range(scene.stream_capacity()):
			scene.prepare_stream_ground(Time.get_ticks_usec() + 4000)
		scene.update_horizon(1.0 / 60.0)
		scene.atmosphere_controller.update()
		smallest = minf(smallest, scene.environment.fog_depth_end)
		check(is_equal_approx(scene.environment.fog_depth_end, horizon), "Fog stays at its configured distance through orbit, tilt and zoom with queued terrain")
		check(is_equal_approx(scene.environment.fog_depth_begin, horizon * scene.active_view.fog_start_fraction), "Clear-weather fog onset stays steady while terrain is queued")
		var needed := 0
		for coord: Vector2i in world.pending:
			if scene.ViewStreaming.visible(scene.camera, Vector2(coord * 16) - world.camera.position / 32.0, scene.height_bound(), 0.0, -scene.height_bound()):
				needed += 1
				check(scene.streaming_ground.chunks.has(coord), "Every visible queued chunk has temporary ground before rendering")
		check(scene.streaming_ground.chunks.size() == needed and needed <= scene.stream_capacity(), "Temporary ground contains only the bounded visible pending set")
		print("FOG POSE: %s; queued %d; begin %.2f; end %.2f" % [pose, world.pending.size(), scene.environment.fog_depth_begin, scene.environment.fog_depth_end])
		if OS.get_cmdline_user_args().has("--capture-fog") and DisplayServer.get_name() != "headless":
			DirAccess.make_dir_recursive_absolute("res://artifacts/fog-horizon")
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://artifacts/fog-horizon/angle-%d.png" % int(pose.x))
	var queued: int = world.pending.size()
	var resident: int = world.chunks.size()
	var next: Vector2i = world.pending.front()
	world._process(0)
	scene.update_horizon(0)
	check(world.chunks.size() - resident <= scene.active_view.chunks_per_frame and queued - world.pending.size() <= scene.active_view.chunks_per_frame, "Detailed terrain and scenery retain the configured publication budget")
	if not scene.solid_chunks.has(next):
		var visible: bool = scene.ViewStreaming.visible(scene.camera, Vector2(next * 16) - world.camera.position / 32.0, scene.height_bound(), 0.0, -scene.height_bound())
		check(world.pending.has(next) and (not visible or scene.streaming_ground.chunks.has(next)), "Partial preparation retains visible temporary ground until atomic publication")
	for frame in range(256):
		if scene.solid_chunks.has(next):
			break
		world._process(0)
		scene.update_horizon(0)
	check(not scene.streaming_ground.chunks.has(next) and scene.solid_chunks.has(next), "Published terrain replaces temporary ground without overlapping meshes")
	# Publication count is bounded separately from resumable preparation frames.
	for frame in range(scene.stream_capacity() * 64):
		if world.pending.is_empty():
			break
		world._process(0)
	scene.update_horizon(0)
	check(world.pending.is_empty() and scene.streaming_ground.chunks.is_empty(), "Temporary ground retires when the detailed queue drains")
	check(is_equal_approx(scene.environment.fog_depth_end, horizon), "Queue completion does not animate the fog horizon")
	var drag_start := InputEventMouseButton.new()
	drag_start.button_index = MOUSE_BUTTON_MIDDLE
	drag_start.pressed = true
	scene._unhandled_input(drag_start)
	var max_drag_ms := 0.0
	for frame in range(36):
		var started := Time.get_ticks_usec()
		var drag := InputEventMouseMotion.new()
		drag.relative = Vector2(40, sin(frame * 0.5) * 12)
		scene._unhandled_input(drag)
		world._process(0)
		scene._process(1.0 / 60.0)
		max_drag_ms = maxf(max_drag_ms, (Time.get_ticks_usec() - started) / 1000.0)
		check(is_equal_approx(scene.environment.fog_depth_end, horizon), "Middle-drag input keeps the horizon stable throughout a full orbit")
		if DisplayServer.get_name() != "headless":
			await process_frame
	drag_start.pressed = false
	scene._input(drag_start)
	print("FOG DRAG: 36 steps; maximum camera/stream update %.2f ms (CPU only)." % max_drag_ms)
	var invalid_view: View3DSettings = scene.active_view.duplicate(false)
	invalid_view.stream_ground_step = 3
	check(not invalid_view.valid(), "Temporary ground rejects a grid spacing that cannot tile chunk edges")
	for coord in [Vector2i(-1, -1), Vector2i(2, 2)]:
		var step: int = scene.active_view.stream_ground_step
		var mesh: ArrayMesh = scene.streaming_ground.build(world.terrain, coord, step)
		var vertices: PackedVector3Array = mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		var correct := true
		for tile in range((16 / step) * (16 / step)):
			var local := Vector2i(tile % (16 / step), tile / (16 / step)) * step
			var cell: Vector2i = coord * 16 + local
			var sample := cell + Vector2i(step / 2, step / 2)
			var water: bool = world.terrain.natural_ground(sample) == WorldTerrain.Ground.WATER
			var offsets := [Vector2i.ZERO, Vector2i(step, 0), Vector2i(step, step), Vector2i(0, step)]
			for corner in range(4):
				var expected: float = world.terrain.pond_at(sample).level if water else world.terrain.vertex_height(cell + offsets[corner])
				correct = correct and is_equal_approx(vertices[tile * 4 + corner].y, expected)
		check(correct, "Temporary LOD samples use canonical land/water heights, including negative coordinates")
	var known_ground: Node = scene.streaming_ground
	var old_step: int = scene.active_view.stream_ground_step
	scene.view_settings = scene.active_view.duplicate(false)
	scene.view_settings.stream_ground_step = 8
	scene.apply_view_settings()
	world._process(0)
	scene.update_horizon(0)
	check(scene.streaming_ground.sample_step == 8 and scene.streaming_ground == known_ground, "Reapplying view settings connects the temporary-ground resolution without replacing the world")
	scene.view_settings.stream_ground_step = old_step
	scene.apply_view_settings()
	world._process(0)
	scene.update_horizon(0)
	scene.atmosphere_settings.weather = "rain"
	scene.apply_atmosphere_settings()
	check(is_equal_approx(scene.environment.fog_depth_begin, horizon * scene.active_view.fog_start_fraction * scene.atmosphere_settings.rain_fog_fraction), "Rain keeps its intentional earlier fog onset without changing the horizon")
	check(world.persistent_state.snapshot() == before, "Changing the fog presentation leaves expedition state intact")
	world.new_expedition(42)
	world._process(0)
	scene.update_horizon(0)
	check(scene.streaming_ground.source == world.terrain, "World replacement discards temporary geometry from the previous seed")
	print("FOG HORIZON: %d checks, %d failures; nearest horizon %.2f; maximum temporary-ground preparation %.2f ms." % [checks, failures, smallest, scene.streaming_ground.max_prepare_ms])
	scene.environment.sky = null
	scene.free()
	quit(0 if failures == 0 else 1)
