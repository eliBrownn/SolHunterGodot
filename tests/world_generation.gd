extends SceneTree
## Stress dry routes, water, chunk borders, and incompatible-save rejection.
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
	var seeds := [0, 1, 2, 17, 19, 71, 2601026, 88881, 999999, 123456789, 2147483646]
	var found_water := false
	for seed_value in seeds:
		var terrain := WorldTerrain.new(seed_value)
		check(terrain.essential_route_clear(), "Essential refuge-to-waystone route supports 3x3 traversal, seed %d" % seed_value)
		var graph: Array = terrain.geography.paths(terrain, Vector2i.ZERO)
		check(not graph.is_empty(), "Starting district has dry winding approaches, seed %d" % seed_value)
		var other := WorldTerrain.new(seed_value)
		check(graph == other.geography.paths(other, Vector2i.ZERO), "Road descriptors reproduce independently")
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
	for old_version in [1, 2, 3, 4, 5, 6]:
		var old_save := ExpeditionSave.snapshot(1, Vector2i.ZERO, true, true, old_version)
		var old_json := JSON.stringify(old_save)
		var file := FileAccess.open(path, FileAccess.WRITE)
		file.store_string(old_json)
		file.close()
		check(ExpeditionSave.read_save(path).is_empty(), "Obsolete development generation is rejected")
		check(FileAccess.get_file_as_string(path) == old_json, "Rejected old saves are not rewritten")
	var current := ExpeditionSave.snapshot(1, Vector2i.ZERO, true, true)
	check(ExpeditionSave.write(current, path) == OK, "Current development save writes")
	check(ExpeditionSave.read_save(path).relief == WorldTerrain.default_relief(), "Current save reconstructs its relief contract")
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	if FileAccess.file_exists(path + ".bak"):
		DirAccess.remove_absolute(path + ".bak")
	print("GENERATION: %d checks, %d failures across %d seeds." % [checks, failures, seeds.size()])
	quit(0 if failures == 0 else 1)
