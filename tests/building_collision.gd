extends SceneTree
## Structure placement, movement/render agreement, and forward save migration.

var failures := 0
var checks := 0

func check(value: bool, description: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(description)

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	for seed_value in [0, 1, 2, 17, 71, 2601026, 88881, 999999, 123456789, 2147483646]:
		var terrain := WorldTerrain.new(seed_value)
		var footprint: Rect2i = terrain.cabin_footprint
		check(footprint.has_area(), "Cabin has a valid bounded site, seed %d" % seed_value)
		if not footprint.has_area():
			continue
		check(WorldTerrain.new(seed_value).cabin_footprint == footprint, "Cabin placement is deterministic")
		check(not footprint.has_point(Vector2i.ZERO), "Spawn remains outside the building")
		var clearance := footprint.grow(1)
		for y in range(clearance.position.y, clearance.end.y):
			for x in range(clearance.position.x, clearance.end.x):
				var cell := Vector2i(x, y)
				check(terrain.route_axes(cell, 2) == 0 and terrain.natural_ground(cell) != WorldTerrain.Ground.WATER, "Structure and approach avoid protected routes and water")
				if footprint.has_point(cell):
					check(terrain.sample(cell).obstacle == 3 and not terrain.is_walkable(cell), "Building tile is consistently blocked in sampling and movement")
					var chunk: Array[Dictionary] = terrain.extract_chunk(terrain.chunk_of(cell))
					check(not chunk[posmod(cell.y, 16) * 16 + posmod(cell.x, 16)].walkable, "Prepared chunk agrees with building collision at negative coordinates")
				else:
					check(terrain.fits(cell), "Reserved one-tile approach stays traversable")
		var west := footprint.position + Vector2i(-1, 1)
		var east := footprint.position + Vector2i(footprint.size.x, 1)
		var north := footprint.position + Vector2i(1, -1)
		var south := footprint.position + Vector2i(1, footprint.size.y)
		for entry in [[west, Vector2i.RIGHT], [east, Vector2i.LEFT], [north, Vector2i.DOWN], [south, Vector2i.UP]]:
			check(not terrain.can_step(entry[0], entry[0] + entry[1]), "Building blocks entry from each wall")
		check(not terrain.can_step(footprint.position + Vector2i(-1, 0), footprint.position + Vector2i(0, -1)), "Diagonal movement cannot clip the building corner")
		check(not terrain.fits(footprint.position + Vector2i(-2, 0), 3), "Large footprints cannot overlap a building")
		var grid := AStarGrid2D.new()
		grid.region = footprint.grow(2)
		grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
		grid.update()
		for y in range(grid.region.position.y, grid.region.end.y):
			for x in range(grid.region.position.x, grid.region.end.x):
				var at := Vector2i(x, y)
				grid.set_point_solid(at, not terrain.fits(at))
		var route := grid.get_id_path(west, east)
		check(not route.is_empty(), "Player can walk around the building")
		for i in range(1, route.size()):
			check(terrain.can_step(route[i - 1], route[i]), "Detour agrees with real traversal")
	var scene: Node3D = (load("res://scenes/world_3d.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	var world: Node2D = scene.world
	world.smoke_mode = true
	var site: Rect2i = world.terrain.cabin_footprint
	world.cell = site.position + Vector2i(-1, 1)
	world.rebuild_world()
	var before: Vector2 = world.explorer.position
	world.advance_movement(1.0, Vector2.RIGHT)
	check(world.cell == site.position + Vector2i(-1, 1) and world.explorer.position == before and not world.moving, "Live movement stops before the wall without visual penetration")
	world.advance_movement(float(world.expedition_parameters().move_seconds), Vector2.DOWN)
	check(world.cell == site.position + Vector2i(-1, 2), "A blocked step does not prevent the next legal direction")
	if DisplayServer.get_name() != "headless":
		var foundation: Transform3D = scene.place_root.get_node("prop").multimesh.get_instance_transform(0)
		var scale := foundation.basis.get_scale()
		check(Vector2(foundation.origin.x, foundation.origin.z).distance_to(Vector2(site.position) + Vector2(site.size) * 0.5) < 0.001, "Rendered foundation center matches the collision reservation")
		check(Vector2(scale.x, scale.z).distance_to(Vector2(site.size)) < 0.001, "Rendered foundation bounds exactly match blocked tiles")
	else:
		print("BUILDINGS: 2 GPU foundation readbacks require a rendered run.")
	var climate := {"moisture_frequency": 0.025, "dry_threshold": 0.35, "wet_threshold": 0.62}
	var target := WorldTerrain.new(2601026, climate)
	var legacy := ExpeditionSave.snapshot(2601026, target.cabin_footprint.position, true, false, 4, climate)
	var path := "user://building-migration-%d.json" % Time.get_ticks_usec()
	var original := JSON.stringify(legacy)
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(original)
	file.close()
	check(ExpeditionSave.read_save(path).is_empty(), "Old building-era saves require a new expedition")
	var live_terrain: RefCounted = world.terrain
	world.load_game(path)
	check(world.terrain == live_terrain and FileAccess.get_file_as_string(path) == original, "Rejected old save leaves world and source bytes intact")
	var blocked := ExpeditionSave.snapshot(2601026, target.cabin_footprint.position, false, false, WorldTerrain.GENERATION_VERSION, climate)
	check(not ExpeditionSave.validate(blocked) and ExpeditionSave.write(blocked, path) == ERR_INVALID_DATA, "Current saves cannot persist an occupied building tile")
	var malformed := legacy.duplicate(true)
	malformed.climate.dry_threshold = 0.9
	malformed.climate.wet_threshold = 0.1
	check(not ExpeditionSave.validate(malformed), "Malformed old data is rejected")
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(path + suffix):
			DirAccess.remove_absolute(path + suffix)
	if DisplayServer.get_name() != "headless":
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
	scene.environment.sky = null
	scene.free()
	if DisplayServer.get_name() != "headless":
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
	print("BUILDINGS: %d checks, %d failures." % [checks, failures])
	quit(0 if failures == 0 else 1)
