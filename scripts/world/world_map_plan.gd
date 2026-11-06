class_name WorldMapPlan
extends RefCounted
## Finite, seed-addressable geography. This plan exists before any terrain chunks.

const VERSION := 7
const TUNDRA_MIN_ELEVATION := 0.30
const MARSH_MAX_ELEVATION := 0.115
const SIZE := Vector2i(640, 480)
const WORLD_CELLS_PER_SAMPLE := 96
const WORLD_ORIGIN := -SIZE * WORLD_CELLS_PER_SAMPLE / 2
const WaterPlan := preload("res://scripts/world/world_map_water.gd")
# The first six IDs retain the existing WorldTerrain ground order.
enum Biome { PLAINS, WOODLAND, HEATH, MARSH, OCEAN, COAST, DESERT, JUNGLE, SAVANNA, ALPINE, TUNDRA, TAIGA, LAKE }

var _seed: int
var _elevation := PackedFloat32Array()
var _temperature := PackedFloat32Array()
var _moisture := PackedFloat32Array()
var _biomes := PackedByteArray()
var _natural_biomes := PackedByteArray()
var _coast_distance := PackedInt32Array()
var _water: WaterPlan


func _init(seed_value: int) -> void:
	_seed = seed_value
	var count := SIZE.x * SIZE.y
	_elevation.resize(count)
	_temperature.resize(count)
	_moisture.resize(count)
	_biomes.resize(count)
	_natural_biomes.resize(count)
	_coast_distance.resize(count)
	_build_geography()
	_measure_distance_from_ocean()
	_build_climate()
	_water = WaterPlan.new(SIZE, _elevation, _moisture, _temperature)
	for index in count:
		var natural := _classify(index)
		_natural_biomes[index] = natural
		_biomes[index] = _irrigated_biome(index, natural) if _water.irrigation[index] > 0 else natural


func sample_world_cell(cell: Vector2i) -> Dictionary:
	# Categorical biomes are sampled from the parent map cell. Continuous fields
	# interpolate between sample centers, independent of terrain chunk boundaries.
	var map_position := Vector2(cell - WORLD_ORIGIN) / WORLD_CELLS_PER_SAMPLE
	if not Rect2(Vector2.ZERO, Vector2(SIZE)).has_point(map_position):
		return {"biome": Biome.OCEAN, "natural_biome": Biome.OCEAN, "land": false, "elevation": 0.0, "temperature": 0.0, "moisture": 1.0,
			"soil_moisture": 1.0, "lake_level": 0.0, "river_flow": 0.0, "river_to": null, "irrigation_intake": null}
	var at := Vector2i(map_position.floor())
	var index := at.y * SIZE.x + at.x
	var biome := int(_biomes[index])
	var blend_position := (map_position - Vector2(0.5, 0.5)).clamp(Vector2.ZERO, Vector2(SIZE - Vector2i.ONE))
	var moisture := _blend(_moisture, blend_position)
	var intake := _water.irrigation[index] - 1
	return {
		"biome": biome, "natural_biome": int(_natural_biomes[index]),
		"land": biome != Biome.OCEAN and biome != Biome.LAKE,
		"elevation": _blend(_elevation, blend_position) if biome != Biome.OCEAN else 0.0,
		"temperature": _blend(_temperature, blend_position),
		"moisture": moisture,
		"soil_moisture": maxf(moisture, 0.72) if intake >= 0 else moisture,
		"lake_level": _water.lakes[index],
		"river_flow": _water.rivers[index],
		"river_to": _world_center(_water.receivers[index]) if _water.rivers[index] > 0.0 else null,
		"irrigation_intake": _world_center(intake) if intake >= 0 else null,
	}


func _world_center(index: int) -> Vector2i:
	return WORLD_ORIGIN + Vector2i(index % SIZE.x, index / SIZE.x) * WORLD_CELLS_PER_SAMPLE \
		+ Vector2i.ONE * (WORLD_CELLS_PER_SAMPLE / 2)


func terrain_layers() -> Dictionary:
	# Packed snapshots for the terrain sampler. The plan never mutates after construction.
	return {"elevation": _elevation, "biome": _biomes, "lake_level": _water.lakes,
		"river_flow": _water.rivers, "downstream": _water.receivers, "irrigation": _water.irrigation}


func export_layers() -> Dictionary:
	return {
		"version": VERSION, "seed": _seed, "width": SIZE.x, "height": SIZE.y,
		"cells_per_sample": WORLD_CELLS_PER_SAMPLE, "origin": [WORLD_ORIGIN.x, WORLD_ORIGIN.y],
		"elevation": Array(_elevation), "temperature": Array(_temperature),
		"moisture": Array(_moisture), "biome": Array(_biomes), "natural_biome": Array(_natural_biomes),
		"river_flow": Array(_water.rivers), "downstream": Array(_water.receivers),
		"lake_level": Array(_water.lakes), "irrigation": Array(_water.irrigation),
	}


func _build_geography() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = _seed
	var continental := _noise(0x57a31, 1.0, 3)
	var coastal := _noise(0x711f, 1.0, 2)
	var landforms: Array[Vector4] = []
	var belts: Array[PackedVector2Array] = []
	# Seeded continental arrangements leave broad basins between major landforms.
	# The same seed also controls each landform's offset, size and secondary arm.
	var layouts := [
		[Vector4(0.25, 0.27, 0.20, 0.17), Vector4(0.72, 0.25, 0.20, 0.16),
			Vector4(0.33, 0.72, 0.20, 0.19), Vector4(0.76, 0.69, 0.14, 0.19)],
		[Vector4(0.27, 0.45, 0.21, 0.36), Vector4(0.71, 0.29, 0.20, 0.19),
			Vector4(0.73, 0.72, 0.18, 0.18)],
		[Vector4(0.25, 0.32, 0.19, 0.22), Vector4(0.72, 0.31, 0.19, 0.23),
			Vector4(0.58, 0.73, 0.27, 0.16)],
	]
	for anchor: Vector4 in layouts[posmod(_seed, layouts.size())]:
		var center := Vector2(anchor.x, anchor.y) + Vector2(rng.randf_range(-0.055, 0.055), rng.randf_range(-0.06, 0.06))
		var radii := Vector2(anchor.z, anchor.w) * rng.randf_range(0.86, 1.16)
		landforms.append(Vector4(center.x, center.y, radii.x, radii.y))
		var arm := center + Vector2(rng.randf_range(-0.14, 0.14), rng.randf_range(-0.12, 0.12))
		landforms.append(Vector4(arm.x, arm.y, radii.x * 0.66, radii.y * 0.63))
		var belt := PackedVector2Array()
		var angle := rng.randf_range(-1.2, 1.2)
		for segment in 8:
			var along := (float(segment) / 7.0 - 0.5) * radii.x * 1.63
			var bend := rng.randf_range(-0.025, 0.025) + sin(segment * 0.9) * radii.y * 0.18
			belt.append(center + Vector2(along, bend).rotated(angle))
		belts.append(belt)
	# Small shelves and islands, separate from the continental ridges.
	for island in 24:
		var center := Vector2(rng.randf_range(0.08, 0.92), rng.randf_range(0.09, 0.91))
		var radius := rng.randf_range(0.007, 0.035)
		landforms.append(Vector4(center.x, center.y, radius, radius * rng.randf_range(0.55, 1.1)))

	for z in SIZE.y:
		for x in SIZE.x:
			var p := (Vector2(x, z) + Vector2(0.5, 0.5)) / Vector2(SIZE)
			var land := -1.0
			for shape in landforms:
				var local := (p - Vector2(shape.x, shape.y)) / Vector2(shape.z, shape.w)
				land = maxf(land, 1.0 - local.length())
			land += continental.get_noise_2dv(p * 5.0) * 0.58 + coastal.get_noise_2dv(p * 27.0) * 0.16
			var edge := minf(minf(p.x, 1.0 - p.x), minf(p.y, 1.0 - p.y))
			land -= 1.25 * (1.0 - smoothstep(0.015, 0.065, edge))
			if land <= 0.0:
				continue
			var distance := 1.0
			for belt in belts:
				for segment in belt.size() - 1:
					var nearest := Geometry2D.get_closest_point_to_segment(p, belt[segment], belt[segment + 1])
					distance = minf(distance, p.distance_to(nearest))
			# Narrow crests sit above wider, lower foothills. Slow variation along
			# each belt leaves room for saddles instead of repeated small spikes.
			var crest := pow(maxf(0.0, 1.0 - distance / 0.051), 1.45)
			var foothills := 1.0 - smoothstep(0.014, 0.089, distance)
			var ridge := 0.82 * crest + 0.18 * foothills
			var roughness := 0.85 + coastal.get_noise_2dv(p * 19.0) * 0.18
			var inland := smoothstep(0.0, 0.23, land)
			var basin_relief := coastal.get_noise_2dv(p * 35.0) * 0.027 * inland
			_elevation[z * SIZE.x + x] = clampf(0.012 + land * 0.28 + ridge * roughness * inland + basin_relief, 0.0, 1.0)


func _measure_distance_from_ocean() -> void:
	for z in SIZE.y:
		for x in SIZE.x:
			var index := z * SIZE.x + x
			if _elevation[index] <= 0.0:
				continue
			var left := _coast_distance[index - 1] if x > 0 else 0
			var up := _coast_distance[index - SIZE.x] if z > 0 else 0
			_coast_distance[index] = mini(left, up) + 1
	for z in range(SIZE.y - 1, -1, -1):
		for x in range(SIZE.x - 1, -1, -1):
			var index := z * SIZE.x + x
			var right := _coast_distance[index + 1] if x < SIZE.x - 1 else 0
			var down := _coast_distance[index + SIZE.x] if z < SIZE.y - 1 else 0
			_coast_distance[index] = mini(_coast_distance[index], mini(right, down) + 1)


func _build_climate() -> void:
	var climate := _noise(0x1c507, 1.0, 3)
	var windward := PackedFloat32Array()
	windward.resize(SIZE.x * SIZE.y)
	for z in SIZE.y:
		var latitude := absf((z + 0.5) / SIZE.y * 2.0 - 1.0)
		var subtropical_dry_belt := smoothstep(0.16, 0.39, latitude) * (1.0 - smoothstep(0.49, 0.69, latitude))
		var equatorial_rain := 1.0 - smoothstep(0.08, 0.34, latitude)
		for wind in [1, -1]:
			var humidity := 1.0
			var previous_height := 0.0
			for column in SIZE.x:
				var x: int = column if wind == 1 else SIZE.x - 1 - column
				var index := z * SIZE.x + x
				var height := _elevation[index]
				var variation := climate.get_noise_2d(float(x) / 85.0, float(z) / 85.0)
				var rising := maxf(0.0, height - previous_height)
				if height == 0.0:
					humidity = minf(1.0, humidity + 0.028)
				else:
					humidity = maxf(0.08, humidity - 0.0025 - rising * 1.0)
				var interior := smoothstep(8.0, 48.0, float(_coast_distance[index]))
				var rain := clampf(humidity * 0.70 + rising * 2.1 + variation * 0.19
					+ equatorial_rain * 0.24 - subtropical_dry_belt * (0.17 + interior * 0.20), 0.0, 1.0)
				if wind == 1:
					windward[index] = rain
					_temperature[index] = clampf(1.0 - pow(latitude, 1.18) * 0.86 - height * 0.43 + variation * 0.07, 0.0, 1.0)
				else:
					_moisture[index] = 1.0 if height == 0.0 else lerpf(windward[index], rain, 0.28)
				previous_height = height


func _classify(index: int) -> int:
	var height := _elevation[index]
	if height <= 0.0:
		return Biome.OCEAN
	if _water.lakes[index] > 0.0:
		return Biome.LAKE
	if height < 0.032 and _coast_distance[index] <= 4:
		return Biome.COAST
	var heat := _temperature[index]
	var wet := _moisture[index]
	if height > 0.62:
		return Biome.ALPINE
	if heat < 0.24 and height >= TUNDRA_MIN_ELEVATION:
		return Biome.TUNDRA
	if heat < 0.36 and wet > 0.28:
		return Biome.TAIGA
	if heat > 0.50 and wet < 0.23:
		return Biome.DESERT
	if heat > 0.66 and wet > 0.58:
		return Biome.JUNGLE
	if wet > 0.64 and height < MARSH_MAX_ELEVATION and heat > 0.35:
		return Biome.MARSH
	if height > 0.35 or heat < 0.40 or wet < 0.24:
		return Biome.HEATH
	if heat > 0.62 and wet < 0.48:
		return Biome.SAVANNA
	if wet > 0.45:
		return Biome.WOODLAND
	return Biome.PLAINS


func _irrigated_biome(index: int, natural: int) -> int:
	match natural:
		Biome.DESERT, Biome.SAVANNA:
			return Biome.PLAINS
		Biome.HEATH:
			# Moisture can green a dry heath. Cold and high heath still has
			# the same climate and elevation.
			if _temperature[index] >= 0.40 and _elevation[index] <= 0.35:
				return Biome.PLAINS
		Biome.PLAINS, Biome.WOODLAND:
			if _elevation[index] < MARSH_MAX_ELEVATION and _temperature[index] > 0.35 and _moisture[index] >= 0.40:
				return Biome.MARSH
	return natural


func _noise(salt: int, frequency: float, octaves: int) -> FastNoiseLite:
	var noise := FastNoiseLite.new()
	TerrainHeightfield.configure(noise, _seed ^ salt, frequency)
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.fractal_octaves = octaves
	return noise


func _blend(layer: PackedFloat32Array, p: Vector2) -> float:
	var a := Vector2i(p.floor())
	var b := (a + Vector2i.ONE).min(SIZE - Vector2i.ONE)
	var f := p - Vector2(a)
	return lerpf(lerpf(layer[a.y * SIZE.x + a.x], layer[a.y * SIZE.x + b.x], f.x),
		lerpf(layer[b.y * SIZE.x + a.x], layer[b.y * SIZE.x + b.x], f.x), f.y)
