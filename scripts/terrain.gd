class_name WorldTerrain
extends RefCounted
## Immutable generated defaults. All decisions use seed, version and absolute cells.

const GENERATION_VERSION := 8 # Admitted woodland site and shared access reservations.
const Structures = preload("res://scripts/authored_structures.gd")
const CELL_SIZE := 32
const CHUNK_SIZE := 16
const CAMP := Vector2i.ZERO
const LANDMARK_X := 78
enum Ground { MEADOW, FOREST, HEATH, MARSH, WATER, SAND }
const COLORS := [Color("455b42"), Color("30483d"), Color("655f48"),
	Color("3b5550"), Color("254853"), Color("83765a")]

var world_seed: int
var generation_version: int
var climate: Dictionary
var noise := FastNoiseLite.new()
var moisture := FastNoiseLite.new()
var vastra := FastNoiseLite.new()
var cabin_footprint := Rect2i()
var scenery_parameters: Dictionary
var scenery_site: Dictionary = {}
var relief: Dictionary
var heightfield: TerrainHeightfield
var _height_cache: Dictionary = {}
var _normal_cache: Dictionary = {}
var _slope_cache: Dictionary = {}
var _pond_cache: Dictionary = {}
const CacheWindow = preload("res://scripts/derived_cache_window.gd")
var _height_window := CacheWindow.new(65536)
var _normal_window := CacheWindow.new(65536)
var _slope_window := CacheWindow.new(32768)
var _pond_window := CacheWindow.new(256)
var _landmark_height := 0.0
var _cabin_height := 0.0
var geography := preload("res://scripts/terrain_geography.gd").new()

static func default_relief() -> Dictionary:
	return (preload("res://resources/terrain_rolling.tres") as TerrainReliefSettings).parameters()

static func default_climate() -> Dictionary:
	return {"moisture_frequency": 0.012, "dry_threshold": 0.42, "wet_threshold": 0.58}

static func valid_climate(value: Variant) -> bool:
	if not value is Dictionary:
		return false
	for key in ["moisture_frequency", "dry_threshold", "wet_threshold"]:
		var number: Variant = value.get(key)
		if not (number is float or number is int) or not is_finite(float(number)):
			return false
	return value.moisture_frequency >= 0.001 and value.moisture_frequency <= 0.1 and value.dry_threshold >= 0.0 and value.wet_threshold <= 1.0 and value.dry_threshold < value.wet_threshold

static func default_scenery() -> Dictionary:
	return preload("res://resources/scenery/woodland_shelter.tres").parameters()

func _init(seed_value: int = 2601026, climate_parameters: Dictionary = {}, relief_parameters: Dictionary = {}, site_parameters: Dictionary = {}) -> void:
	world_seed = seed_value
	generation_version = GENERATION_VERSION
	climate = climate_parameters.duplicate(true) if valid_climate(climate_parameters) else default_climate()
	noise.seed = seed_value
	noise.frequency = 0.014
	moisture.seed = seed_value ^ 0x3912
	moisture.noise_type = FastNoiseLite.TYPE_PERLIN
	moisture.frequency = climate.moisture_frequency
	vastra.seed = seed_value ^ 0x7315
	vastra.frequency = 0.022
	relief = relief_parameters.duplicate(true) if TerrainReliefSettings.valid_parameters(relief_parameters) else default_relief()
	var tuning := TerrainReliefSettings.new()
	for key in relief:
		tuning.set(key, relief[key])
	heightfield = TerrainHeightfield.new(seed_value, tuning)
	cabin_footprint = Structures.cabin_site(self)
	_landmark_height = heightfield.surface_height(Vector2(landmark()) + Vector2(0.5, 0.5))
	if cabin_footprint.has_area():
		var center := Vector2(cabin_footprint.position) + Vector2(cabin_footprint.size) * 0.5
		_cabin_height = 0.0 if center.length() < 14.0 else heightfield.surface_height(center)
	scenery_parameters = (site_parameters if ScenerySiteTemplate.valid_parameters(site_parameters) else default_scenery()).duplicate(true)
	var site_template := ScenerySiteTemplate.new()
	for key in scenery_parameters:
		site_template.set(key, int(scenery_parameters[key]) if key != "site_key" else scenery_parameters[key])
	scenery_site = site_template.plan(self)

func scenery_reserved(cell: Vector2i) -> bool:
	return scenery_site.get("admitted", false) and (scenery_site.reservation.has_point(cell) or scenery_site.approach.has_point(cell))

func pond_at(cell: Vector2i) -> Dictionary:
	if _pond_cache.has(cell):
		return _pond_cache[cell]
	var result: Dictionary = geography.cell_basin(self, cell).descriptor
	if result.is_empty():
		result = {"level": 0.0}
	_pond_window.store(_pond_cache, cell, result)
	return result

func vertex_height(cell: Vector2i) -> float:
	if _height_cache.has(cell):
		return _height_cache[cell]
	var point := Vector2(cell)
	var height := heightfield.vertex_height(cell)
	var raw_height := height
	var basin: Dictionary = geography.basin(self, point)
	var lake: float = basin.distance
	if lake < 4.0:
		var level: float = basin.descriptor.level
		# Continuous bed and rising bank; the rendered horizontal plane intersects
		# these exact triangles instead of following square cell edges.
		var bank := level + (sqrt(maxf(lake, 0.0)) - 1.0) * 3.0
		var bed := maxf(level - 0.65, bank)
		height = lerpf(bed, maxf(height, level + 0.65), smoothstep(1.5, 4.0, lake))
	# Keep the required dry approach on its gentle raw grade. Pond candidates
	# already reserve its water-free envelope; blend only the outer bank here.
	var approach_distance := absf(point.y - trail_y(cell.x))
	height = lerpf(raw_height, height, smoothstep(4.0, 9.0, approach_distance))
	# Place descriptors are selected from flat habitat data before height queries.
	height = lerpf(0.0, height, smoothstep(5.0, 14.0, point.length()))
	height = lerpf(_landmark_height, height, smoothstep(5.0, 14.0, point.distance_to(Vector2(landmark()) + Vector2(0.5, 0.5))))
	if cabin_footprint.has_area():
		var box := Rect2(Vector2(cabin_footprint.position), Vector2(cabin_footprint.size))
		var center := box.get_center()
		var delta := (point - center).abs() - box.size * 0.5
		var outside := Vector2(maxf(0, delta.x), maxf(0, delta.y)).length()
		height = lerpf(_cabin_height, height, smoothstep(1.0, 9.0, outside))
	# Retire one old derived entry instead of discarding the entire working set.
	_height_window.store(_height_cache, cell, height)
	return height

func corners(cell: Vector2i) -> Vector4:
	return Vector4(vertex_height(cell), vertex_height(cell + Vector2i.RIGHT), vertex_height(cell + Vector2i.ONE), vertex_height(cell + Vector2i.DOWN))

func surface_height(point: Vector2) -> float:
	var cell := Vector2i(floori(point.x), floori(point.y))
	return TerrainHeightfield.interpolate(corners(cell), point - Vector2(cell))

func surface_normal(point: Vector2) -> Vector3:
	var cell := Vector2i(floori(point.x), floori(point.y))
	var offset := point - Vector2(cell)
	var h := corners(cell)
	var gradient := Vector2(h.y - h.x, h.z - h.y) if offset.y <= offset.x else Vector2(h.z - h.w, h.w - h.x)
	return Vector3(-gradient.x, 1, -gradient.y).normalized()

func vertex_normal(cell: Vector2i) -> Vector3:
	if _normal_cache.has(cell):
		return _normal_cache[cell]
	var normal := Vector3((vertex_height(cell + Vector2i.LEFT) - vertex_height(cell + Vector2i.RIGHT)) * 0.5, 1, (vertex_height(cell + Vector2i.UP) - vertex_height(cell + Vector2i.DOWN)) * 0.5).normalized()
	_normal_window.store(_normal_cache, cell, normal)
	return normal

func slope_fits(cell: Vector2i) -> bool:
	if _slope_cache.has(cell):
		return _slope_cache[cell]
	var h := corners(cell)
	var limit := tan(deg_to_rad(float(relief.walkable_slope_degrees)))
	var valid := Vector2(h.y - h.x, h.z - h.y).length() <= limit and Vector2(h.z - h.w, h.w - h.x).length() <= limit
	_slope_window.store(_slope_cache, cell, valid)
	return valid

func display_height(point: Vector2) -> float:
	var cell := Vector2i(floori(point.x), floori(point.y))
	return maxf(float(pond_at(cell).level), surface_height(point)) if lake_distance(cell) < 1.8 else surface_height(point)

func essential_route_clear() -> bool:
	var previous := Vector2i(0, trail_y(0) - 1)
	for x in range(LANDMARK_X + 1):
		var cell := Vector2i(x, trail_y(x) - 1)
		if not fits(cell, 3) or (x > 0 and not can_step(previous, cell, 3)):
			return false
		previous = cell
	return true

func roll(cell: Vector2i, salt: int) -> int:
	# Keep intermediate integers in a bounded range, including at negative coordinates.
	var value := posmod(cell.x * 73856093 + cell.y * 19349663 + world_seed * 83492791 + salt * 26544357, 2147483647)
	value = posmod((value ^ (value >> 13)) * 1274126177, 2147483647)
	return value

func trail_y(x: int) -> int:
	var old_anchors := sin(float(x) * 0.071) * 5.0 + sin(float(x) * 0.19) * 2.0
	# Combined derivative < 0.99 cell/cell, for every seeded phase; integer
	# centers therefore never jump two rows between essential route steps.
	var bend := sin(float(x) * PI / LANDMARK_X) * sin(float(x) * 0.035 + float(roll(Vector2i.ZERO, 720) % 100) / 100) * 3.3
	return roundi(old_anchors + bend)

func landmark() -> Vector2i:
	return Vector2i(LANDMARK_X, trail_y(LANDMARK_X))

func chunk_of(cell: Vector2i) -> Vector2i:
	return Vector2i(floor_div(cell.x, CHUNK_SIZE), floor_div(cell.y, CHUNK_SIZE))

static func floor_div(value: int, divisor: int) -> int:
	return (value - posmod(value, divisor)) / divisor

func is_camp(cell: Vector2i) -> bool:
	return Vector2(cell).length() <= 5.0

func is_landmark(cell: Vector2i) -> bool:
	return Vector2(cell - landmark()).length() <= 4.0

func route_axes(cell: Vector2i, margin: int = 0) -> int:
	return geography.axes(self, cell, margin)

func is_trail(cell: Vector2i) -> bool:
	return route_axes(cell) != 0

func lake_distance(cell: Vector2i) -> float:
	return float(geography.cell_basin(self, cell).distance)

func natural_ground(cell: Vector2i) -> int:
	var lake := lake_distance(cell)
	var height := noise.get_noise_2d(cell.x, cell.y)
	var wet := wetness_at(cell)
	if lake <= 1.0:
		return Ground.WATER
	if lake <= 1.25:
		return Ground.SAND
	if wet >= float(climate.wet_threshold):
		return Ground.MARSH
	if wet <= float(climate.dry_threshold):
		return Ground.HEATH
	if height > 0.12:
		return Ground.FOREST
	return Ground.MEADOW

func wetness_at(cell: Vector2i) -> float:
	return clampf(0.5 + moisture.get_noise_2d(cell.x, cell.y) * 0.5, 0.0, 1.0)

func sample(cell: Vector2i) -> Dictionary:
	var ground := natural_ground(cell)
	var route := route_axes(cell)
	var reserved := is_camp(cell) or is_landmark(cell) or route != 0
	var obstacle := obstacle_at(cell, ground, reserved)
	var visible_trail := absi(cell.y - trail_y(cell.x)) <= 1 or route_axes(cell, -2) != 0
	return {"ground": ground, "trail": route != 0, "trail_visible": visible_trail,
		"route_axes": route,
		"obstacle": obstacle, "walkable": ground != Ground.WATER and obstacle == 0 and slope_fits(cell),
		"tint": habitat_tint(cell),
		"variation": roll(cell, 3) % 7,
		"wetness": wetness_at(cell),
		"concentration": clampi(roundi(50 + vastra.get_noise_2d(cell.x, cell.y) * 45), 0, 100),
		"overload": 0}

func obstacle_at(cell: Vector2i, ground: int, reserved: bool) -> int:
	if scenery_reserved(cell):
		return 3 if cell in scenery_site.blockers else 0
	if cabin_footprint.has_area():
		if cabin_footprint.has_point(cell):
			return 3
		if cabin_footprint.grow(1).has_point(cell):
			return 0
	if reserved or ground == Ground.WATER:
		return 0
	var chance := roll(cell, 2) % 100
	if chance < (6 if ground == Ground.FOREST else 2):
		var clear_tree := route_axes(cell, 2) == 0
		if clear_tree:
			return 1
	if chance > 97 and route_axes(cell, 1) == 0:
		return 2
	return 0

func is_walkable(cell: Vector2i) -> bool:
	var ground := natural_ground(cell)
	var place := is_camp(cell) or is_landmark(cell)
	var route := is_trail(cell)
	return ground != Ground.WATER and obstacle_at(cell, ground, place or route) == 0 and slope_fits(cell)

func habitat_tint(cell: Vector2i) -> Color:
	var wet := wetness_at(cell)
	var height := noise.get_noise_2d(cell.x, cell.y)
	var dry_weight := 1.0 - smoothstep(float(climate.dry_threshold) - 0.08, float(climate.dry_threshold) + 0.08, wet)
	var wet_weight := smoothstep(float(climate.wet_threshold) - 0.08, float(climate.wet_threshold) + 0.08, wet)
	var tint := Color("a7b59c").lerp(Color("c5b196"), dry_weight * 0.8)
	tint = tint.lerp(Color("82aaa5"), wet_weight * 0.8)
	return tint.lerp(Color("929e85"), smoothstep(0.12, 0.65, height) * 0.2)

func can_step(from: Vector2i, to: Vector2i, footprint: int = 1) -> bool:
	var change := to - from
	if footprint < 1 or footprint > 3 or change == Vector2i.ZERO or absi(change.x) > 1 or absi(change.y) > 1:
		return false
	if not fits(from, footprint):
		return false
	if not fits(to, footprint):
		return false
	if change.x != 0 and change.y != 0:
		return fits(from + Vector2i(change.x, 0), footprint) and fits(from + Vector2i(0, change.y), footprint)
	return true

func fits(cell: Vector2i, footprint: int = 1) -> bool:
	if footprint < 1 or footprint > 3:
		return false
	for y in range(footprint):
		for x in range(footprint):
			if not is_walkable(cell + Vector2i(x, y)):
				return false
	return true

func extract_chunk(coord: Vector2i) -> Array[Dictionary]:
	var cells: Array[Dictionary] = []
	for y in range(CHUNK_SIZE):
		for x in range(CHUNK_SIZE):
			cells.append(sample(coord * CHUNK_SIZE + Vector2i(x, y)))
	return cells

