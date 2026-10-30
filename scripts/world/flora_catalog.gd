class_name FloraCatalog
extends RefCounted
## Budgeted read-only catalogue of canonical terrain flora, independent of rendering.
const REGION_SIZE := 12
const CACHE_LIMIT := 96
var terrain: WorldTerrain
var regions: Dictionary = {}
var pending: Array[Vector2i] = []
var building := Vector2i(2147483647, 2147483647)
var build_cells := 0
var geography_prepared := 0
var build_nodes: Array[Dictionary] = []
var focus := Vector2i.ZERO
var active_radius := 1
var protected: Dictionary = {}

func _init(source: WorldTerrain) -> void:
	terrain = source

static func region(cell: Vector2i) -> Vector2i:
	return Vector2i(WorldTerrain.floor_div(cell.x, REGION_SIZE), WorldTerrain.floor_div(cell.y, REGION_SIZE))

static func id_for(cell: Vector2i) -> String:
	return AffinityImprint.key(cell)

func request(center: Vector2i, radius: int, tree_reach: float) -> void:
	focus = region(center)
	active_radius = radius
	var halo := radius + ceili(tree_reach / REGION_SIZE)
	var wanted: Array[Vector2i] = []
	protected.clear()
	for y in range(-halo, halo + 1):
		for x in range(-halo, halo + 1):
			var owner := focus + Vector2i(x, y)
			protected[owner] = true
			if not regions.has(owner): wanted.append(owner)
	wanted.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		var da := a.distance_squared_to(focus)
		var db := b.distance_squared_to(focus)
		return da < db if da != db else (a.x < b.x or (a.x == b.x and a.y < b.y)))
	if wanted.has(building):
		wanted.erase(building)
		wanted.push_front(building)
	elif build_cells > 0 or geography_prepared > 0:
		build_cells = 0
		geography_prepared = 0
		building = Vector2i(2147483647, 2147483647)
		build_nodes.clear()
	pending = wanted
	trim()

func advance(deadline: int, generated: Callable = Callable()) -> Array[Dictionary]:
	var admitted: Array[Dictionary] = []
	while not pending.is_empty() and Time.get_ticks_usec() < deadline:
		if building != pending[0]:
			building = pending[0]
			build_cells = 0
			geography_prepared = 0
			build_nodes.clear()
		# Warm the same canonical road dependencies one region at a time, rather
		# than allowing the first flora sample to compile them all atomically.
		var low: Vector2i = terrain.geography.region(Vector2(building * REGION_SIZE - Vector2i.ONE)) - Vector2i(2, 2)
		var high: Vector2i = terrain.geography.region(Vector2(building * REGION_SIZE + Vector2i(REGION_SIZE, REGION_SIZE))) + Vector2i(2, 2)
		var width := high.x - low.x + 1
		var count := width * (high.y - low.y + 1)
		if geography_prepared < count:
			terrain.geography.paths(terrain, low + Vector2i(geography_prepared % width, geography_prepared / width))
			geography_prepared += 1
			continue
		var cell := building * REGION_SIZE + Vector2i(build_cells % REGION_SIZE, build_cells / REGION_SIZE)
		var data: Dictionary = generated.call(cell) if generated.is_valid() else terrain.sample(cell)
		var kind := terrain.flora_kind(cell, data)
		if not kind.is_empty() and absi(cell.x) <= 1000000 and absi(cell.y) <= 1000000: build_nodes.append({"id": id_for(cell), "cell": [cell.x, cell.y], "kind": kind})
		build_cells += 1
		if build_cells == REGION_SIZE * REGION_SIZE:
			regions[building] = build_nodes.duplicate(true)
			trim()
			for row in build_nodes:
				if row.kind == "tree" or (absi(building.x - focus.x) <= active_radius and absi(building.y - focus.y) <= active_radius): admitted.append(row)
			pending.pop_front()
			building = Vector2i(2147483647, 2147483647)
			build_cells = 0
			geography_prepared = 0
	return admitted

func active_ids() -> Array[String]:
	var result: Array[String] = []
	for y in range(-active_radius, active_radius + 1):
		for x in range(-active_radius, active_radius + 1):
			for row: Dictionary in regions.get(focus + Vector2i(x, y), []): result.append(row.id)
	result.sort()
	return result

## Null means the complete neighborhood is not ready. Never select from a partial
## catalogue, which would bias transfers toward whatever the camera loaded first.
func trees_near(cell: Vector2i, reach: float) -> Variant:
	var low := region(cell - Vector2i(ceili(reach), ceili(reach)))
	var high := region(cell + Vector2i(ceili(reach), ceili(reach)))
	var result: Array[Dictionary] = []
	for y in range(low.y, high.y + 1):
		for x in range(low.x, high.x + 1):
			var owner := Vector2i(x, y)
			if not regions.has(owner): return null
			for row: Dictionary in regions[owner]:
				if row.kind == "tree" and row.id != id_for(cell) and Vector2(cell).distance_to(Vector2(row.cell[0], row.cell[1])) <= reach: result.append(row)
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.id < b.id)
	return result

func plants_near(cell: Vector2i, reach: float) -> Variant:
	# Only complete active-area records can receive root packets. No partial-camera
	# source list or speculative tree-only halo admits a plant into the ledger.
	var low := region(cell - Vector2i(ceili(reach), ceili(reach)))
	var high := region(cell + Vector2i(ceili(reach), ceili(reach)))
	var result: Array[Dictionary] = []
	for y in range(low.y, high.y + 1):
		for x in range(low.x, high.x + 1):
			var owner := Vector2i(x, y)
			if not regions.has(owner): return null
			for row: Dictionary in regions[owner]:
				if row.kind == "plant" and row.id != id_for(cell) and Vector2(cell).distance_to(Vector2(row.cell[0], row.cell[1])) <= reach: result.append(row)
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.id < b.id)
	return result

func trim() -> void:
	while regions.size() > CACHE_LIMIT:
		var evicted := false
		for owner: Vector2i in regions:
			if not protected.has(owner):
				regions.erase(owner)
				evicted = true
				break
		if not evicted: break

func active_definitions() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for y in range(-active_radius, active_radius + 1):
		for x in range(-active_radius, active_radius + 1): result.append_array(regions.get(focus + Vector2i(x, y), []))
	return result
