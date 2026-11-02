extends "res://tools/review_cohesive_sample.gd"
## Actual production terrain/vegetation fixtures. No player save is read or written.
var publication: Array = []
func finish_view() -> void:
	for frame in range(180 if "--quick" in OS.get_cmdline_user_args() else 900):
		await process_frame
		if world.pending.is_empty() and scene.stream_job == null: break
	publication.append({"queued_detail": world.pending.size(), "published_detail": world.chunks.size()})
	await settle(30)

func run() -> void:
	output_directory = "res://artifacts/world_generation_next/rendered"
	DirAccess.make_dir_recursive_absolute(output_directory)
	Engine.max_fps = 60
	scene = load("res://scenes/world_3d.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	world = scene.world
	world.smoke_mode = true
	scene.active_view = scene.active_view.duplicate()
	scene.active_view.chunk_work_ms = 8.0
	scene.active_view.chunks_per_frame = 4
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280, 800)
	condition("clear")
	var pond: Dictionary = {}
	for descriptor: Dictionary in world.terrain.geography.basins(world.terrain, Vector2i(-1, -1)):
		if descriptor.has("channel"):
			pond = descriptor
			break
	check(not pond.is_empty(), "Default seed admits a real pond-fed channel")
	if not pond.is_empty():
		var middle: Vector2 = pond.channel[1]
		await fixture(Vector2i(middle) + Vector2i(0, 5))
		scene.target_size = 38
		scene.view_elevation = 58
		scene.view_azimuth = 0
		scene.apply_camera()
		await finish_view()
		await capture("connected-channel")
		scene.target_size = 12
		scene.view_elevation = 25
		scene.apply_camera()
		await finish_view()
		await capture("grass-and-bank")
	if "--water-only" in OS.get_cmdline_user_args():
		scene.environment.sky = null
		scene.free()
		print("CONNECTED WATER RENDER REVIEW: ", failures.size(), " failures; publication=", publication)
		quit(0 if failures.is_empty() else 1)
		return
	var best := 0.0
	var mountain := Vector2i.ZERO
	for y in range(96, 385, 16):
		for x in range(-192, 385, 16):
			var at := Vector2i(x, y)
			var ridge: float = world.terrain.heightfield.mountain_height_at(Vector2(at))
			if ridge > best:
				best = ridge
				mountain = at
	await fixture(mountain + Vector2i(0, 16))
	scene.target_size = 34
	scene.view_elevation = 24
	scene.view_azimuth = 0
	scene.apply_camera()
	await finish_view()
	await capture("mountain-range")
	FileAccess.open(output_directory + "/report.json", FileAccess.WRITE).store_string(JSON.stringify({
		"seed": world.terrain.world_seed, "generation": world.terrain.generation_version,
		"channel": str(pond), "mountain": str(mountain), "ridge_height": best,
		"grass_height": scene.active_nature.meadow_height,
		"grass_width": load("res://resources/meadow_appearance.tres").blade_width,
		"publication": publication, "failures": failures, "scope": "Production renderer with repositioned player/camera and 8 ms/four-chunk review budget. Remaining queued detail is reported; not a normal-input journey, shipping performance result or owner acceptance."}, "\t"))
	scene.environment.sky = null
	scene.free()
	print("WATER AND MOUNTAIN RENDER REVIEW: ", failures.size(), " failures")
	quit(0 if failures.is_empty() else 1)
