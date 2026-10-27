class_name WorldTerrain
extends RefCounted
## Immutable generated defaults. All decisions use seed, version and absolute cells.

const GENERATION_VERSION := 4
const CELL_SIZE := 32
const CHUNK_SIZE := 16
const ROUTE_SPACING := 96
const ROUTE_HALF_WIDTH := 3
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

func _init(seed_value: int = 2601026, climate_parameters: Dictionary = {}) -> void:
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

func roll(cell: Vector2i, salt: int) -> int:
	# Keep intermediate integers in a bounded range, including at negative coordinates.
	var value := posmod(cell.x * 73856093 + cell.y * 19349663 + world_seed * 83492791 + salt * 26544357, 2147483647)
	value = posmod((value ^ (value >> 13)) * 1274126177, 2147483647)
	return value

func trail_y(x: int) -> int:
	return roundi(sin(float(x) * 0.071) * 5.0 + sin(float(x) * 0.19) * 2.0)

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

func network_offset(index: int, horizontal: bool) -> int:
	var key := Vector2i(index, 0) if horizontal else Vector2i(0, index)
	return roll(key, 11 if horizontal else 12) % 17 - 8

func network_center(index: int, along: int, horizontal: bool) -> int:
	# Each route is a function of absolute coordinates, never of chunk order.
	# Its bounded, slowly varying deviation keeps neighboring cells connected.
	var phase := float(roll(Vector2i(index, 0), 21 if horizontal else 22) % 6283) / 1000.0
	return index * ROUTE_SPACING + network_offset(index, horizontal) + roundi(sin(float(along) * 0.015 + phase) * 3.0)

func nearest_route_index(value: int) -> int:
	return floor_div(value + ROUTE_SPACING / 2, ROUTE_SPACING)

func route_axes(cell: Vector2i, margin: int = 0) -> int:
	# Bit 1: an east-west route, bit 2: a north-south route.
	var result := 1 if absi(cell.y - trail_y(cell.x)) <= 2 + margin else 0
	var row := nearest_route_index(cell.y)
	var column := nearest_route_index(cell.x)
	# The central east-west route already serves row zero.
	var maximum_offset := ROUTE_HALF_WIDTH + margin + 11
	if row != 0 and absi(cell.y - row * ROUTE_SPACING) <= maximum_offset and absi(cell.y - network_center(row, cell.x, true)) <= ROUTE_HALF_WIDTH + margin:
		result |= 1
	if absi(cell.x - column * ROUTE_SPACING) <= maximum_offset and absi(cell.x - network_center(column, cell.y, false)) <= ROUTE_HALF_WIDTH + margin:
		result |= 2
	return result

func is_trail(cell: Vector2i) -> bool:
	return route_axes(cell) != 0

func lake_distance(cell: Vector2i) -> float:
	# Seeded, bounded basins occupy area interiors; routes follow dry margins.
	# Water is independent of route selection and chunk generation order.
	var area := Vector2i(floor_div(cell.x, ROUTE_SPACING), floor_div(cell.y, ROUTE_SPACING))
	if roll(area, 31) % 5 == 0:
		return INF
	var center := area * ROUTE_SPACING + Vector2i(42 + roll(area, 32) % 13, 42 + roll(area, 33) % 13)
	var delta := cell - center
	var radius_x := 11 + roll(area, 34) % 8
	var radius_y := 10 + roll(area, 35) % 8
	if absi(delta.x) > radius_x + 3 or absi(delta.y) > radius_y + 3:
		return INF
	var dx := float(delta.x) / radius_x
	var dy := float(delta.y) / radius_y
	return dx * dx + dy * dy + noise.get_noise_2d(cell.x * 3.0, cell.y * 3.0) * 0.12

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
		"obstacle": obstacle, "walkable": ground != Ground.WATER and obstacle == 0,
		"tint": habitat_tint(cell),
		"variation": roll(cell, 3) % 7,
		"wetness": wetness_at(cell),
		"concentration": clampi(roundi(50 + vastra.get_noise_2d(cell.x, cell.y) * 45), 0, 100),
		"overload": 0}

func obstacle_at(cell: Vector2i, ground: int, reserved: bool) -> int:
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
	return ground != Ground.WATER and obstacle_at(cell, ground, place or route) == 0

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

