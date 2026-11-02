extends SceneTree
var checks := 0
var failures := 0

func check(value: bool, description: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(description)

func _initialize() -> void:
	create_timer(150).timeout.connect(func() -> void: quit(1))
	run.call_deferred()

func drainage_checks(heights: PackedFloat64Array, width: int, height: int) -> void:
	var result := TerrainDrainage.analyze(heights, width, height)
	check(result.order.size() == heights.size(), "Drainage analysis visits every finite-grid sample")
	var outlet_mass := 0
	for start in range(heights.size()):
		var at := start
		var steps := 0
		while result.receivers[at] >= 0 and steps <= heights.size():
			var next: int = result.receivers[at]
			check(result.filled[next] <= result.filled[at], "Receivers descend or cross a resolved flat at spill elevation")
			at = next
			steps += 1
		check(steps < heights.size(), "Every receiver path terminates without a cycle")
		if result.receivers[start] < 0:
			outlet_mass += result.accumulation[start]
	check(outlet_mass == heights.size(), "Contributing area is conserved at finite-grid boundary outlets")
	check(result == TerrainDrainage.analyze(heights, width, height), "Drainage graph is deterministic on equal-height ties")

func run() -> void:
	connected_water_and_ranges()
	var bowl := PackedFloat64Array()
	for y in range(5):
		for x in range(5):
			bowl.append(2.0 if x in [0,4] or y in [0,4] else -2.0)
	drainage_checks(bowl, 5, 5)
	var filled: PackedFloat64Array = TerrainDrainage.analyze(bowl,5,5).filled
	check(filled[12] == 2.0, "Enclosed low ground records its actual spill depth")
	var setting: TerrainReliefSettings = preload("res://resources/terrain_exploration.tres").duplicate()
	check(TerrainReliefSettings.valid_parameters(JSON.parse_string(JSON.stringify(setting.parameters()))), "Noise family remains valid after JSON save decoding")
	var fractional := setting.parameters()
	fractional.elevation_noise = 1.5
	check(not TerrainReliefSettings.valid_parameters(fractional), "Fractional noise enum corruption is rejected")
	var kinds := {}
	for seed_value in [2601026,7,19]:
		for family in [FastNoiseLite.TYPE_SIMPLEX_SMOOTH, FastNoiseLite.TYPE_PERLIN]:
			setting.elevation_noise = family
			var terrain := WorldTerrain.new(seed_value, {}, setting.parameters())
			check(terrain.essential_route_clear(), "Exploration relief retains required multi-cell refuge-to-waystone access")
			for district in [Vector2i(-1,-1),Vector2i.ZERO,Vector2i(1,0)]:
				for path in terrain.geography.paths(terrain,district):
					var previous: Variant = null
					var connected := true
					for segment in range(path.size()-1):
						var a: Vector2 = path[segment]
						var b: Vector2 = path[segment+1]
						var steps := maxi(1,ceili(a.distance_to(b)*2.0))
						for offset in range(steps+1):
							var at := Vector2i(a.lerp(b,float(offset)/steps).floor())-Vector2i.ONE
							if previous != null and previous != at and not terrain.can_step(previous,at,3):
								connected = false
							previous = at
					check(connected,"Every admitted regional road permits the actual three-cell movement consumer, including diagonal corners")
			var heights := PackedFloat64Array()
			for y in range(9):
				for x in range(9):
					heights.append(terrain.heightfield.surface_height(Vector2(x * 16, y * 16)))
			drainage_checks(heights,9,9)
			var before := terrain.heightfield.raw_height(Vector2(63,71))
			for y in range(-7,8):
				for x in range(-7,8):
					kinds[terrain.heightfield.landform_at(Vector2(x*128+64,y*128+64)).kind] = true
			check(before == terrain.heightfield.raw_height(Vector2(63,71)), "Evicting landform descriptors cannot reroll their geometry")
			for x in [-128,0,128]:
				check(absf(terrain.heightfield.raw_height(Vector2(x-0.001,50))-terrain.heightfield.raw_height(Vector2(x+0.001,50))) < 0.01, "Adjacent landform districts join continuously at absolute coordinates")
			var restored := WorldTerrain.new(seed_value, terrain.climate, terrain.relief, terrain.scenery_parameters)
			for at in [Vector2i(24,32),Vector2i(64,64),Vector2i(-32,-16)]:
				check(terrain.sample(at) == restored.sample(at), "Captured noise/landform/drainage settings reconstruct the same gameplay samples")
	for kind in [0,1,2,3]:
		check(kinds.has(kind), "Seeded regional descriptors exercise every authored landform family")
	print("EXPLORATION GEOGRAPHY: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)

func connected_water_and_ranges() -> void:
	var settings: TerrainReliefSettings = load("res://resources/terrain_exploration.tres")
	var connections := 0
	for seed_value in [2601026, 7, 19]:
		var terrain := WorldTerrain.new(seed_value, {}, settings.parameters())
		check(terrain.essential_route_clear(), "Mountain/channel generation preserves the actual required three-cell journey")
		var restored := WorldTerrain.new(seed_value, terrain.climate, JSON.parse_string(JSON.stringify(terrain.relief)), terrain.scenery_parameters)
		for area in [Vector2i.ZERO, Vector2i(-1, -1), Vector2i(1, 0)]:
			var descriptors: Array = terrain.geography.basins(terrain, area)
			check(descriptors == restored.geography.basins(restored, area), "Saved settings reconstruct complete connected water descriptors")
			for pond: Dictionary in descriptors:
				if not pond.has("channel"): continue
				connections += 1
				for segment in range(pond.channel.size() - 1):
					var a: Vector2 = pond.channel[segment]
					var b: Vector2 = pond.channel[segment + 1]
					for step in range(ceili(a.distance_to(b)) + 1):
						var at := a.lerp(b, float(step) / maxi(1, ceili(a.distance_to(b))))
						check(terrain.geography.basin_distance(pond, at) <= 1.0, "Every channel segment stays connected to its pond and terminal pool")
						var cell := Vector2i(at.floor())
						check(terrain.natural_ground(cell) == WorldTerrain.Ground.WATER and not terrain.fits(cell), "Channel centers are canonical nonwalkable water, not cosmetic ribbons")
						check(terrain.vertex_height(cell) == restored.vertex_height(cell), "Channel ground reconstructs independently of query order")
				var before := descriptors.duplicate(true)
				terrain.geography.ponds.clear()
				check(before == terrain.geography.basins(terrain, area), "Evicting pond/channel descriptors does not change geography")
		var peak := 0.0
		for y in range(-256, 513, 16):
			for x in range(-384, 641, 16):
				var at := Vector2(x, y)
				var ridge := terrain.heightfield.mountain_height_at(at)
				peak = maxf(peak, ridge)
				check(ridge >= 0.0 and ridge <= settings.mountain_height, "Overlapping range parents respect the shared ridge height budget")
		check(peak > settings.mountain_height * 0.7, "Each review seed contains substantial mountain ranges")
		for boundary in [-384, 0, 384]:
			for offset in range(-256, 513, 16):
				for axis in [0, 1]:
					var at := Vector2(boundary, offset) if axis == 0 else Vector2(offset, boundary)
					var delta := Vector2(0.001, 0) if axis == 0 else Vector2(0, 0.001)
					check(absf(terrain.heightfield.raw_height(at - delta) - terrain.heightfield.raw_height(at + delta)) < 0.02, "Mountain ranges remain continuous across positive and negative parent boundaries")
	check(connections > 0, "Review seeds exercise real pond/channel/pool connections")
