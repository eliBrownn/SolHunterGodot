extends "res://tools/review_cohesive_sample.gd"
## Actual game view, live AI and isolated cosmetic weather fixtures; no player-save writes.
func run() -> void:
	output_directory = "res://artifacts/water/final"
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--output="):
			output_directory = argument.trim_prefix("--output=")
	DirAccess.make_dir_recursive_absolute(output_directory)
	Engine.max_fps = 60
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280, 800)
	scene = load("res://scenes/world_3d.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	world = scene.world
	check(not world.smoke_mode, "Water review keeps normal AI enabled")
	report = {"engine": Engine.get_version_info().string, "driver": RenderingServer.get_current_rendering_driver_name(), "seed": world.terrain.world_seed, "generation": world.terrain.generation_version, "appearance": resource_values(load("res://resources/water_appearance.tres")), "viewport": [1280,800], "samples": {}, "method": "Single rendered cosmetic review, normal AI, paced frame intervals. Not a matched performance comparison or owner/device acceptance."}
	await fixture(Vector2i(28,28))
	scene.view_azimuth = 180
	scene.apply_camera()
	for kind in ["daylight", "night", "rain"]:
		condition(kind)
		await settle(60)
		report.samples[kind] = await measured_frames(120)
		await capture("pond_" + kind)
	condition("daylight")
	scene.target_size = maxf(scene.active_view.minimum_distance, 8.0)
	scene.apply_camera()
	await settle(90)
	await capture("shore_closeup")
	finish_review()
