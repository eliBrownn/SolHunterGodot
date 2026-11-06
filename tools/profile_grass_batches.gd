extends SceneTree
## Matched GPU/culling comparison using the production scene and identical grass.
var edge := 8

func _initialize() -> void:
	create_timer(180).timeout.connect(func(): quit(1))
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--batch="): edge = int(arg.trim_prefix("--batch="))
	run.call_deferred()

func run() -> void:
	if edge not in [4, 8, 16]: quit(1); return
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280, 800)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	RenderingServer.viewport_set_measure_render_time(root.get_viewport_rid(), true)
	var scene: Node3D = load("res://scenes/world_3d.tscn").instantiate()
	scene.nature_settings = scene.nature_settings.duplicate(true)
	scene.nature_settings.meadow_batch_cells = edge
	# Sixteen-cell mode reproduces the former unthinned grass treatment.
	if edge == 16: scene.nature_settings.meadow_appearance.distant_density = 1.0
	root.add_child(scene)
	current_scene = scene
	var world: Node2D = scene.world
	world.smoke_mode = true
	scene.atmosphere_settings = scene.atmosphere_settings.duplicate()
	scene.atmosphere_settings.cycle_enabled = false
	scene.atmosphere_settings.starting_phase = 0.5
	scene.atmosphere_settings.weather = "clear"
	scene.apply_atmosphere_settings()
	var report := {"batch_edge": edge, "distant_density": scene.nature_settings.meadow_appearance.distant_density, "viewport": [1280, 800], "scope": "Desktop production-scene comparison; same generated clumps and draw distance; simulation frozen in measured windows", "views": []}
	report["sources"] = {}
	for path in ["scripts/scenery/meadow_art.gd", "scripts/scenery/meadow_appearance.gd", "scripts/scenery/nature_art.gd", "shaders/meadow.gdshader", "resources/nature_biomes.tres", "resources/meadow_appearance.tres"]:
		report.sources[path] = FileAccess.get_sha256("res://" + path)
	for angle in [0, 90, 180, 270]:
		scene.view_azimuth = angle
		scene.apply_camera()
		for frame in range(12000):
			if world.pending.is_empty(): break
			world._process(0.0)
		if not world.pending.is_empty():
			push_error("Grass comparison requires a completely prepared view")
			quit(1)
			return
		world.process_mode = Node.PROCESS_MODE_DISABLED
		scene.set_process(false)
		for frame in range(30): await process_frame
		var gpu := 0.0
		var calls := 0.0
		var primitives := 0.0
		var began := Time.get_ticks_usec()
		for frame in range(90):
			await process_frame
			gpu += RenderingServer.viewport_get_measured_render_time_gpu(root.get_viewport_rid()) / 90.0
			calls += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME) / 90.0
			primitives += Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME) / 90.0
		report.views.append({"azimuth": angle, "frame_ms": (Time.get_ticks_usec() - began) / 90000.0, "gpu_ms": gpu, "draw_calls": calls, "primitives": primitives})
		DirAccess.make_dir_recursive_absolute("res://artifacts/world-optimization")
		if angle == 0:
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://artifacts/world-optimization/grass-%d.png" % edge)
		# Isolate vegetation raster work from changing creature/tree/UI costs.
		var original_mask: int = scene.camera.cull_mask
		for chunk in scene.solid_chunks.values():
			for view in chunk.get_children():
				if view is MultiMeshInstance3D and view.name.begins_with("nature_detail_meadow"):
					view.layers |= 1 << 19
		scene.camera.cull_mask = 1 << 19
		world.hud.hide()
		for frame in range(30): await process_frame
		var grass_gpu := 0.0
		for frame in range(90):
			await process_frame
			grass_gpu += RenderingServer.viewport_get_measured_render_time_gpu(root.get_viewport_rid()) / 90.0
		report.views[-1]["grass_only_gpu_ms"] = grass_gpu
		report.views[-1]["grass_only_primitives"] = Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)
		scene.camera.cull_mask = original_mask
		world.hud.show()
		world.process_mode = Node.PROCESS_MODE_INHERIT
	FileAccess.open("res://artifacts/world-optimization/grass-%d.json" % edge, FileAccess.WRITE).store_string(JSON.stringify(report, "\t"))
	print("GRASS PROFILE: ", JSON.stringify(report))
	scene.free()
	quit()
