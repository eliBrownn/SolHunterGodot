extends "res://tools/profile_current_expedition.gd"
## W0 world review using the existing normal-input journey controller.
## Screenshots and traversal evidence are not a human enjoyment assessment.

func _initialize() -> void:
	create_timer(600).timeout.connect(func() -> void:
		push_error("World exploration review timed out")
		quit(1))
	run.call_deferred()

func nearby_ground(target: Vector2i) -> Vector2i:
	for radius in range(9):
		for y in range(-radius, radius + 1):
			for x in range(-radius, radius + 1):
				var at := target + Vector2i(x, y)
				if world.terrain.fits(at):
					return at
	return world.cell

func route(target: Vector2i) -> Array[Vector2i]:
	# Pond detours can leave the older waystone profiler's narrow Y window.
	var grid := AStarGrid2D.new()
	grid.region = Rect2i(-32, -48, 176, 144)
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	grid.update()
	for y in range(grid.region.position.y, grid.region.end.y):
		for x in range(grid.region.position.x, grid.region.end.x):
			var at := Vector2i(x, y)
			grid.set_point_solid(at, not world.terrain.fits(at))
	return grid.get_id_path(world.cell, target)

func run() -> void:
	var seed_value := 2601026
	output_directory = "res://artifacts/world_exploration/w0"
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--seed="):
			seed_value = int(argument.trim_prefix("--seed="))
		if argument.begins_with("--output="):
			output_directory = argument.trim_prefix("--output=")
	DirAccess.make_dir_recursive_absolute(output_directory)
	Engine.max_fps = 60
	scene = load("res://scenes/world_3d.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	world = scene.world
	world.new_expedition(seed_value)
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280, 800)
	root.title = "SolHunter — world exploration review %d" % seed_value
	check(not world.smoke_mode, "Normal simulation remains enabled")
	check(world.terrain.world_seed == seed_value, "Requested review seed was admitted")
	report = {"seed": seed_value, "generation": world.terrain.generation_version,
		"engine": Engine.get_version_info(), "expedition": world.expedition_parameters(),
		"nature": resource_values(scene.active_nature), "stops": [],
		"method": "Existing normal-input waypoint controller with normal clock/AI/contact. Fixed requested review destinations; nearby legal ground selected where necessary. No teleports or gameplay speed-up. Contact policy: observe then withdraw. Not free-choice human play or enjoyment acceptance."}
	await settle(60)
	await capture("refuge")
	var stops := [{"name": "woodland", "at": Vector2i(32, 16)},
		{"name": "pond", "at": Vector2i(28, 32)},
		{"name": "waystone", "at": world.terrain.landmark()},
		{"name": "dryland", "at": Vector2i(104, 24)},
		{"name": "return", "at": Vector2i.ZERO}]
	for stop in stops:
		var target := nearby_ground(stop.at)
		var journey := await traverse(target)
		await settle(20)
		await capture(stop.name)
		report.stops.append({"name": stop.name, "requested": str(stop.at),
			"actual": str(world.cell), "habitat": world.terrain.natural_ground(world.cell),
			"location_label": world.location_label.text, "viewport": str(root.size),
			"journey": journey})
		print("WORLD REVIEW: seed %d / %s / %s" % [seed_value, stop.name, world.cell])
		if not failures.is_empty():
			break
	report["contacts"] = contacts
	report["roaming_seen"] = roaming_seen
	report["failures"] = failures
	FileAccess.open(output_directory + "/review.json", FileAccess.WRITE).store_string(JSON.stringify(report, "\t"))
	release_movement()
	scene.environment.sky = null
	scene.free()
	print("WORLD REVIEW COMPLETE: seed %d / %d failures" % [seed_value, failures.size()])
	quit(0 if failures.is_empty() else 1)
