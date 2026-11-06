extends SceneTree

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

func drain(world: Node2D) -> void:
	# Capacity limits resident chunks. A time-budgeted chunk may need multiple
	# preparation frames, particularly with cold geography caches or a 1 ms budget.
	for frame in range(world.host.stream_capacity() * 64):
		if world.pending.is_empty():
			return
		world._process(0)
	check(false, "Streaming queue drains within its configured capacity")

func run() -> void:
	var image := Image.create(4, 4, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	for y in range(4):
		for x in range(2):
			image.set_pixel(x, y, Color.WHITE)
	var cutout := PlaneMesh.new()
	cutout.size = Vector2(2, 2)
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	material.albedo_texture = ImageTexture.create_from_image(image)
	cutout.material = material
	var picking := preload("res://scripts/presentation/mesh_picking.gd")
	check(picking.ray(cutout, Vector3(-0.5, 1, 0), Vector3.DOWN) != null, "Scenery triangle picking accepts opaque texture pixels")
	check(picking.ray(cutout, Vector3(0.5, 1, 0), Vector3.DOWN) == null, "Scenery triangle picking passes through transparent foliage gaps")
	var scene: Node3D = load("res://scenes/world_3d.tscn").instantiate()
	root.add_child(scene)
	var world: Node2D = scene.world
	world.smoke_mode = true
	world.new_expedition(17)
	check(scene.player_visual.model.scene_file_path.ends_with("grave_knight.tscn"), "Production player uses the supplied grave knight")
	for animation in ["Idle_A", "Walking_A", "Running_A"]:
		check(scene.player_visual.animator.has_animation(animation), "Grave knight has its %s animation" % animation)
	check(scene.camera.projection == Camera3D.PROJECTION_PERSPECTIVE, "Main game view uses perspective projection")
	check(scene.camera.far == scene.active_view.render_distance+preload("res://scripts/scenery/plant_library.gd").maximum_height() and scene.camera.fov == scene.active_view.field_of_view, "Camera preserves configured terrain distance with headroom for tall plant bounds")
	check(scene.environment.background_mode == Environment.BG_SKY and scene.environment.sky.sky_material.shader == scene.active_view.sky_shader, "Supplied procedural sky is connected to the real environment")
	check(scene.environment.sky.sky_material.get_shader_parameter("cloud_tex_01") == scene.active_view.cloud_primary, "Supplied cloud noise preset is used by the sky")
	check(scene.environment.fog_depth_end < scene.camera.far and scene.environment.fog_depth_begin < scene.environment.fog_depth_end, "Depth fog obscures the far clipping boundary")
	check(scene.viewport.size == Vector2i(2, 2), "3D mode uses the minimum hidden viewport rather than a full 2D render target")
	for row in world.chunks.values():
		check(row.props.is_empty(), "3D streamed chunks do not duplicate scenery as hidden 2D sprites")
	var before: Dictionary = world.persistent_state.snapshot()
	var size: Vector2 = root.get_visible_rect().size
	for azimuth in [0.0, 90.0, 180.0, -90.0]:
		scene.view_azimuth = azimuth
		var expected: Vector2 = Vector2.UP.rotated(-deg_to_rad(azimuth))
		check(scene.movement_direction(Vector2.UP).is_equal_approx(expected), "W follows camera heading at %.0f degrees" % azimuth)
		for tilt in [10.0, 35.0, 80.0]:
			scene.view_elevation = tilt
			scene.apply_camera()
			var desired: Array[Vector2i] = scene.stream_plan()
			check(desired.size() <= scene.stream_capacity(), "View-dependent queue remains bounded")
			for y in [0.05, 0.5, 0.95]:
				for x in [0.05, 0.5, 0.95]:
					var pointer := size * Vector2(x, y)
					var hit: Variant = scene.pointer_world(pointer)
					if hit != null:
						var cell := Vector2i((hit / 32.0).floor())
						check(desired.has(world.terrain.chunk_of(cell)), "Ground visible at each orbit/tilt is included in the stream plan")
	check(world.persistent_state.snapshot() == before, "Orbit, tilt and frustum changes never mutate saved simulation")
	scene.view_azimuth = 20
	check(scene.movement_direction(Vector2.UP).is_equal_approx(Vector2.UP), "Shallow orbit angles choose the nearest existing grid heading")
	scene.view_azimuth = 30
	check(scene.movement_direction(Vector2.UP).is_equal_approx(Vector2(-1, -1).normalized()), "Orbit past the nearest-heading boundary selects diagonal movement")
	var old_size := root.size
	var old_revision: int = scene.view_revision
	root.size = Vector2i(1600, 900)
	await process_frame
	check(scene.view_revision > old_revision, "Viewport aspect changes invalidate the 3D stream plan")
	var panel: Control = scene.battles.combat_hud.tray
	var right_margin := panel.get_viewport_rect().size.x - panel.get_rect().end.x
	var ribbon_limit: float = world.menu.settings.combat_width * sqrt(world.menu.settings.text_scale)
	check(panel.position.x >= 16 and absf(right_margin - panel.position.x) < 1 and panel.size.x <= ribbon_limit + 1, "Compact battle ribbon stays centered, bounded and within both viewport margins after resize")
	root.size = old_size
	await process_frame
	scene.view_azimuth = 90
	scene.view_elevation = 35
	scene.apply_camera()
	world.smoke_mode = false
	Input.action_press("north")
	world._process(world.expedition_parameters().move_seconds)
	Input.action_release("north")
	world.smoke_mode = true
	check(world.cell == Vector2i.LEFT, "Actual WASD polling moves screen-forward after a 90-degree orbit")
	world.new_expedition(17)
	scene.view_settings = scene.active_view.duplicate(false)
	scene.view_settings.render_distance = 48
	scene.apply_view_settings()
	var short_plan: Array[Vector2i] = scene.stream_plan()
	scene.view_settings.render_distance = 96
	scene.apply_view_settings()
	check(scene.stream_plan().size() > short_plan.size() and scene.camera.far == 96+preload("res://scripts/scenery/plant_library.gd").maximum_height(), "Increasing render distance expands the streamed frustum and preserves plant headroom")
	var old_pending: int = world.pending.size()
	var old_live: int = world.chunks.size()
	world._process(0)
	check(world.chunks.size() - old_live <= scene.active_view.chunks_per_frame and world.pending.size() >= old_pending - scene.active_view.chunks_per_frame, "Asset/chunk publication respects the per-frame budget")
	if world.pending.size() > 1:
		var prepared_coord: Vector2i = world.pending[-1]
		scene.prepare_stream_chunk(prepared_coord, Time.get_ticks_usec())
		var admitted_job: RefCounted = scene.stream_job
		scene.view_revision += 1
		world.plan_chunks()
		check(scene.stream_job == admitted_job and world.pending[0] == prepared_coord, "Replanning preserves an admitted chunk at the queue front rather than cancelling partial work")
	drain(world)
	check(world.chunks.size() == scene.solid_chunks.size() and world.chunks.size() <= scene.stream_capacity(), "Steady-state 3D and simulation chunk lifetimes stay aligned")
	for coord in scene.stream_plan():
		check(world.chunks.has(coord), "Queue completion covers every desired chunk")
	var resident_before_turn: Dictionary = scene.solid_chunks.duplicate()
	scene.view_azimuth = -90
	scene.apply_camera()
	var preserved := 0
	for coord in resident_before_turn:
		if scene.keep_stream_chunk(coord) and scene.solid_chunks.has(coord):
			preserved += 1
			check(scene.solid_chunks[coord] == resident_before_turn[coord], "Turning retains published nearby scenery without reloading its assets")
	check(preserved > 0, "Camera-turn journey exercises resident scenery")
	check(world.pending.size() > 0, "Orbit replans streaming without requiring movement to another chunk")
	world._process(0)
	scene.update_horizon(0)
	check(is_equal_approx(scene.environment.fog_depth_end, scene.active_view.render_distance - 4) and not scene.streaming_ground.chunks.is_empty(), "A fast turn keeps the distant horizon steady while temporary ground covers queued terrain")
	drain(world)
	scene.update_horizon(2)
	check(is_equal_approx(scene.environment.fog_depth_end, scene.active_view.render_distance - 4), "Horizon retains its configured distance once streaming catches up")
	var saw_detail := false
	for chunk in scene.solid_chunks.values():
		for mesh in chunk.get_children():
			if mesh.name.begins_with("nature_detail_"):
				saw_detail = true
				if mesh.name.begins_with("nature_detail_meadow"):
					check(mesh.visibility_range_end == minf(scene.active_view.grass_distance, scene.active_view.render_distance) and mesh.visibility_range_end_margin == 8.0 and mesh.visibility_range_fade_mode == GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF, "Dense grass has a bounded draw distance and fade band")
				else:
					check(mesh.visibility_range_end == scene.active_view.detail_distance, "Small assets use their separate decoration draw distance")
	check(saw_detail, "Distance-culling test exercises actual nature decoration")
	scene._process(1.0)
	check(scene.scenery_fades.is_empty(), "Published scenery completes its bounded arrival fade")
	var returning_coord: Vector2i = scene.solid_chunks.keys()[0]
	var returning_chunk: Node3D = scene.solid_chunks[returning_coord]
	var returning_cells: Array[Dictionary] = returning_chunk.get_meta("source_cells")
	scene.remove_solid(returning_coord)
	scene.publish_solid(returning_coord, returning_cells)
	check(scene.solid_chunks[returning_coord] == returning_chunk and not scene.scenery_fades.has(returning_chunk), "Cached scenery reuses geometry without disappearing into another arrival fade")
	for mesh in returning_chunk.get_children():
		if mesh is GeometryInstance3D and mesh.name.begins_with("nature_"):
			check(is_zero_approx(mesh.transparency), "Returning plants keep their normal cutout/depth pass on the first visible frame")
	scene._process(1.0)
	scene.view_settings.render_distance = 4
	scene.apply_view_settings()
	check(scene.camera.far == 72+preload("res://scripts/scenery/plant_library.gd").maximum_height() and scene.active_view.valid(), "Invalid distance policy falls back to connected defaults with plant headroom")
	if OS.get_cmdline_user_args().has("--capture-view") and DisplayServer.get_name() != "headless":
		scene.view_elevation = 12
		scene.view_azimuth = 25
		scene.target_size = 18
		scene.apply_camera()
		drain(world)
		await capture("horizon")
		scene.view_elevation = 55
		scene.view_azimuth = -60
		scene.target_size = 35
		scene.apply_camera()
		drain(world)
		await capture("wide")
	scene.environment.sky = null
	scene.free()
	if DisplayServer.get_name() != "headless":
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
	print("3D VIEW: %d checks, %d failures." % [checks, failures])
	quit(0 if failures == 0 else 1)

func capture(name: String) -> void:
	DirAccess.make_dir_recursive_absolute("res://artifacts/view3d")
	for frame in range(4):
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/view3d/%s.png" % name)
