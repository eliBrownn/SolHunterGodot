extends SceneTree
## Stress dry routes, water, chunk borders, and save migration.
var failures := 0
var checks := 0

func check(value: bool, description: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(description)

func _initialize() -> void:
	run.call_deferred()

func check_segment(terrain: WorldTerrain, index: int, horizontal: bool) -> bool:
	var previous := Vector2i.ZERO
	for along in range(-180, 181):
		var across := terrain.network_center(index, along, horizontal)
		# Top-left coordinate of a 3x3 footprint centered on the route.
		var cell := Vector2i(along, across - 1) if horizontal else Vector2i(across - 1, along)
		if not terrain.fits(cell, 3):
			return false
		if along > -180 and not terrain.can_step(previous, cell, 3):
			return false
		previous = cell
	return true

func check_junction(terrain: WorldTerrain, row: int, column: int) -> bool:
	var x := terrain.network_center(column, row * 96, false)
	var y := terrain.network_center(row, x, true) if row != 0 else terrain.trail_y(x)
	x = terrain.network_center(column, y, false)
	y = terrain.network_center(row, x, true) if row != 0 else terrain.trail_y(x)
	var grid := AStarGrid2D.new()
	grid.region = Rect2i(x - 12, y - 12, 25, 25)
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	grid.update()
	for cy in range(y - 12, y + 13):
		for cx in range(x - 12, x + 13):
			var point := Vector2i(cx, cy)
			grid.set_point_solid(point, not terrain.fits(point, 3))
	var west_x := x - 10
	var east_x := x + 9
	var north_y := y - 10
	var south_y := y + 9
	var west := Vector2i(west_x, (terrain.network_center(row, west_x, true) if row != 0 else terrain.trail_y(west_x)) - 1)
	var east := Vector2i(east_x, (terrain.network_center(row, east_x, true) if row != 0 else terrain.trail_y(east_x)) - 1)
	var north := Vector2i(terrain.network_center(column, north_y, false) - 1, north_y)
	var south := Vector2i(terrain.network_center(column, south_y, false) - 1, south_y)
	for target in [east, north, south]:
		if grid.get_id_path(west, target).is_empty():
			return false
	return true

func run() -> void:
	var seeds := [0, 1, 2, 17, 71, 2601026, 88881, 999999, 123456789, 2147483646]
	var found_water := false
	for seed_value in seeds:
		var terrain := WorldTerrain.new(seed_value)
		for index in [-2, -1, 1, 2]:
			check(check_segment(terrain, index, true), "Horizontal route, seed %d row %d, 3x3 footprint" % [seed_value, index])
		for index in [-2, -1, 0, 1, 2]:
			check(check_segment(terrain, index, false), "Vertical route, seed %d column %d, 3x3 footprint" % [seed_value, index])
		for crossing in [Vector2i(-1, -1), Vector2i(0, 0), Vector2i(1, 1)]:
			check(check_junction(terrain, crossing.y, crossing.x), "Network junction, seed %d at %s" % [seed_value, crossing])
		for chunk in [Vector2i(-7, -7), Vector2i(-1, -1), Vector2i.ZERO, Vector2i(2, 6)]:
			var data := terrain.extract_chunk(chunk)
			var second := WorldTerrain.new(seed_value)
			var identical := true
			for i in range(data.size() - 1, -1, -1):
				var cell: Vector2i = chunk * 16 + Vector2i(i % 16, floori(float(i) / 16))
				if data[i] != second.sample(cell) or data[i].walkable != second.is_walkable(cell):
					identical = false
					break
			check(identical, "Chunk/sample, reverse-order and traversal agreement at %s, seed %d" % [chunk, seed_value])
		var dry_routes := true
		var water_blocked := true
		for y in range(-96, 96):
			for x in range(-96, 96):
				var point := Vector2i(x, y)
				var ground := terrain.natural_ground(point)
				if ground == WorldTerrain.Ground.WATER:
					found_water = true
					water_blocked = water_blocked and not terrain.is_walkable(point)
					dry_routes = dry_routes and not terrain.is_trail(point)
		check(dry_routes, "Route reservations avoid natural water, seed %d" % seed_value)
		check(water_blocked, "Water blocks movement, seed %d" % seed_value)
	check(found_water, "Water exists in sampled worlds")
	check(WorldTerrain.floor_div(-2147483648, 16) == -134217728, "Exact integer floor at extreme negative coordinate")
	check(WorldTerrain.floor_div(-17, 16) == -2, "Negative floor division")
	var terrain := WorldTerrain.new()
	check(not terrain.fits(Vector2i.ZERO, 0) and not terrain.fits(Vector2i.ZERO, 4), "Invalid footprints rejected")
	check(not terrain.can_step(Vector2i.ZERO, Vector2i.ZERO), "Stationary step rejected")
	check(terrain.moisture.noise_type == FastNoiseLite.TYPE_PERLIN, "Moisture uses Perlin noise")
	var dry_settings := {"moisture_frequency": 0.012, "dry_threshold": 0.95, "wet_threshold": 0.99}
	var wet_settings := {"moisture_frequency": 0.012, "dry_threshold": 0.01, "wet_threshold": 0.05}
	var dry_world := WorldTerrain.new(42, dry_settings)
	var wet_world := WorldTerrain.new(42, wet_settings)
	var point := Vector2i(-20, -20)
	check(dry_world.natural_ground(point) == WorldTerrain.Ground.HEATH and wet_world.natural_ground(point) == WorldTerrain.Ground.MARSH, "Thresholds change habitat at the same moisture")
	check(dry_world.habitat_tint(point) != wet_world.habitat_tint(point), "Thresholds change the visible ground tint")
	check(dry_world.wetness_at(point) == wet_world.wetness_at(point), "Thresholds do not change the moisture field")
	check(dry_world.sample(point).concentration == wet_world.sample(point).concentration, "Climate thresholds do not change Vastra")
	check(not WorldTerrain.valid_climate({"moisture_frequency": 0.012, "dry_threshold": 0.8, "wet_threshold": 0.2}), "Reversed thresholds rejected")
	check(not WorldTerrain.valid_climate({"moisture_frequency": 0.0, "dry_threshold": 0.3, "wet_threshold": 0.7}), "Out-of-range frequency rejected")
	var other_frequency := WorldTerrain.new(42, {"moisture_frequency": 0.08, "dry_threshold": 0.42, "wet_threshold": 0.58})
	check(absf(dry_world.wetness_at(point) - other_frequency.wetness_at(point)) > 0.000001, "Moisture frequency changes the field")
	var same_climate := WorldTerrain.new(42, dry_settings)
	check(dry_world.extract_chunk(Vector2i(-2, 2)) == same_climate.extract_chunk(Vector2i(-2, 2)), "Seed and climate reproduce chunk defaults")
	var path := "user://generation-compatibility-test.json"
	for old_version in [1, 2, 3, 4]:
		var old_save := ExpeditionSave.snapshot(1, Vector2i.ZERO, true, true, old_version)
		var old_json := JSON.stringify(old_save)
		var file := FileAccess.open(path, FileAccess.WRITE)
		file.store_string(old_json)
		file.close()
		var restored := ExpeditionSave.read_save(path)
		check(restored.get("generation_version") == WorldTerrain.GENERATION_VERSION and restored.get("migrated_from") == old_version, "Older save migrates to current generation")
		check(restored.get("seed") == 1 and restored.get("returned") and restored.get("player") == [0, 0], "Migration preserves seed, progress and safe position")
		check(FileAccess.get_file_as_string(path) == old_json, "Migration leaves original file untouched until save")
	# An old position submerged by the new geography relocates to dry ground.
	var water_cell := Vector2i.ZERO
	var migration_terrain := WorldTerrain.new(1)
	for y in range(-96, 192):
		for x in range(-96, 192):
			if migration_terrain.natural_ground(Vector2i(x, y)) == WorldTerrain.Ground.WATER:
				water_cell = Vector2i(x, y)
				break
		if water_cell != Vector2i.ZERO:
			break
	check(water_cell != Vector2i.ZERO, "Find water to exercise relocation")
	var moved_save := ExpeditionSave.snapshot(1, water_cell, true, false, 2)
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(moved_save))
	file.close()
	var moved := ExpeditionSave.read_save(path)
	check(not moved.is_empty() and moved.migration_moved and moved.landmark_visited, "Blocked legacy position is relocated and progress preserved")
	if not moved.is_empty():
		check(migration_terrain.fits(Vector2i(int(moved.player[0]), int(moved.player[1]))), "Migrated position is passable")
		check(ExpeditionSave.read_save(path).player == moved.player, "Migration relocation is deterministic")
		var original_json := FileAccess.get_file_as_string(path)
		check(ExpeditionSave.write(moved, path) == OK, "Write migrated save")
		check(FileAccess.get_file_as_string(path + ".bak") == original_json, "Saving migration backs up original save")
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	if FileAccess.file_exists(path + ".bak"):
		DirAccess.remove_absolute(path + ".bak")
	print("GENERATION: %d checks, %d failures across %d seeds." % [checks, failures, seeds.size()])
	quit(0 if failures == 0 else 1)
