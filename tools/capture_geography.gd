extends SceneTree
## Matched camera fixtures; no save writes or simulation acceptance claims.
var scene: Node3D
var world: Node2D

func _initialize() -> void:
	create_timer(120).timeout.connect(func() -> void: quit(1))
	run.call_deferred()

func run() -> void:
	var output := "res://artifacts/geography/before"
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--output="):
			output = argument.trim_prefix("--output=")
	DirAccess.make_dir_recursive_absolute(output)
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280, 800)
	Engine.max_fps = 60
	scene = load("res://scenes/world_3d.tscn").instantiate()
	root.add_child(scene)
	world = scene.world
	world.smoke_mode = true
	world.new_expedition(2601026)
	var fixtures := [{"cell": Vector2i(32, 3), "name": "approach", "azimuth": -45.0}, {"cell": Vector2i(32, 32), "name": "pond", "azimuth": 180.0}, {"cell": Vector2i(95, 8), "name": "junction", "azimuth": -25.0}]
	if WorldTerrain.GENERATION_VERSION >= 7:
		fixtures.append({"cell": Vector2i(32, world.terrain.trail_y(32)), "name": "current_approach", "azimuth": -45.0})
		var bank := Vector2i(24, 23)
		for y in range(20, 40):
			var at := Vector2i(28, y)
			if world.terrain.fits(at) and world.terrain.natural_ground(at + Vector2i.DOWN) == WorldTerrain.Ground.WATER:
				bank = at
				break
		fixtures.append({"cell": bank, "name": "dry_bank", "azimuth": 180.0})
	var manifest: Array = []
	for fixture in fixtures:
		world.cell = fixture.cell
		world.destination = world.cell
		world.rebuild_world()
		scene.view_azimuth = fixture.azimuth
		scene.view_elevation = 35
		scene.apply_camera()
		for frame in range(240):
			await process_frame
			if frame > 20 and world.pending.is_empty():
				break
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(output + "/" + fixture.name + ".png")
		manifest.append({"name": fixture.name, "cell": str(fixture.cell), "walkable": world.terrain.fits(fixture.cell), "azimuth": fixture.azimuth, "elevation": 35, "seed": 2601026, "generation": WorldTerrain.GENERATION_VERSION})
	FileAccess.open(output + "/version.txt", FileAccess.WRITE).store_string(str(WorldTerrain.GENERATION_VERSION))
	FileAccess.open(output + "/views.json", FileAccess.WRITE).store_string(JSON.stringify(manifest, "\t"))
	scene.environment.sky = null
	scene.free()
	quit()
