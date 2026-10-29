extends SceneTree
## Geography v7: bounded descriptors, reconstruction and smooth shores.
const Chunk = preload("res://scripts/solid_chunk.gd")
const Ray = preload("res://scripts/terrain_ray.gd")
var checks := 0
var failures := 0

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)

func _initialize() -> void:
	run.call_deferred()

func border(t: WorldTerrain, coord: Vector2i, x: int) -> Dictionary:
	var chunk := Chunk.new()
	chunk.build(t.extract_chunk(coord), t, coord)
	var result := {"ground": {}, "water": []}
	for kind in ["ground", "water"]:
		if not chunk.has_node(kind):
			continue
		var arrays: Array = chunk.get_node(kind).mesh.surface_get_arrays(0)
		for index in range(arrays[Mesh.ARRAY_VERTEX].size()):
			var v: Vector3 = arrays[Mesh.ARRAY_VERTEX][index] + Vector3(coord.x * 16, 0, coord.y * 16)
			if absf(v.x - x) > 0.00001:
				continue
			if kind == "ground":
				result.ground[v.z] = [v.y, arrays[Mesh.ARRAY_NORMAL][index]]
			elif not result.water.has(v):
				check(absf(v.y - float(t.pond_at(Vector2i(floori(v.x), floori(v.z))).level)) < 0.00001, "Final production water vertices stay on their descriptor's horizontal plane")
				result.water.append(v)
	chunk.free()
	return result

func production_border(t: WorldTerrain, pond: Dictionary) -> void:
	var x := roundi(float(pond.center.x) / 16) * 16
	var coord := Vector2i(WorldTerrain.floor_div(x, 16) - 1, floori(float(pond.center.y) / 16))
	var a := border(t, coord, x)
	# Independent generator and publication order, including pond-shaping vertices.
	var other := WorldTerrain.new(t.world_seed, t.climate, t.relief)
	var b := border(other, coord + Vector2i.RIGHT, x)
	check(a.ground == b.ground and a.ground.size() == 17, "Independent final production borders share exact heights and normals")
	check(not a.water.is_empty() and a.water.size() == b.water.size(), "Actual horizontal water intersects both neighboring chunks")
	for vertex: Vector3 in a.water:
		var closest := INF
		for candidate: Vector3 in b.water:
			closest = minf(closest, vertex.distance_to(candidate))
		check(closest < 0.00001, "Clipped water seam agrees within 0.00001 world cells")

func run() -> void:
	var start := Time.get_ticks_msec()
	for seed_value in [0, 17, 19, 2601026, 2147483646]:
		var t := WorldTerrain.new(seed_value)
		check(t.essential_route_clear(), "Anchored 3x3 outbound/return remains safe: %d" % seed_value)
		var second := WorldTerrain.new(seed_value, t.climate, t.relief)
		for area in [Vector2i(-1, -1), Vector2i.ZERO, Vector2i(1, 1), Vector2i(7812, -7812)]:
			var ponds: Array = t.geography.basins(t, area)
			check(ponds.size() <= 3 and ponds == second.geography.basins(second, area), "Bounded repeatable pond descriptors")
			var paths: Array = t.geography.paths(t, area)
			check(paths.size() <= 4 and paths == second.geography.paths(second, area), "Bounded repeatable road descriptors")
			for path: Array in paths:
				check(path.size() == 33, "Road work is bounded per descriptor")
				for point: Vector2 in path:
					check(float(t.geography.basin(t, point).clearance) >= 0, "Selected road avoids pond/bank envelope in world cells")
		for cell in [Vector2i(15, 16), Vector2i(-17, -16), Vector2i(1000000, -1000000)]:
			check(t.sample(cell) == second.sample(cell) and t.corners(cell) == second.corners(cell), "Final terrain reconstructs at seams and coordinate limits")
	var t := WorldTerrain.new()
	check(t.landmark() == Vector2i(78, -2), "Waystone anchor stays fixed")
	var custom := t.relief.duplicate(true)
	custom.route_bend = 1.5
	custom.pond_scale = 0.6
	custom.pond_candidates = 1.0
	var tuned := WorldTerrain.new(t.world_seed, t.climate, custom)
	check(tuned.relief == custom and tuned.geography.basins(tuned, Vector2i.ZERO)[0].radii != t.geography.basins(t, Vector2i.ZERO)[0].radii, "Saved Inspector controls change actual pond descriptors")
	check(tuned.geography.paths(tuned, Vector2i.ZERO) != t.geography.paths(t, Vector2i.ZERO), "Route bend changes actual selected geometry")
	custom.pond_candidates = 1.5
	check(not TerrainReliefSettings.valid_parameters(custom), "Fractional pond candidate count rejects")
	custom.pond_candidates = 1.0
	custom.route_bend = 1.6
	check(not TerrainReliefSettings.valid_parameters(custom), "Out-of-range bend rejects")
	var pond_count := 0
	var shapes: Dictionary = {}
	var water_count := 0
	for y in range(-1, 2):
		for x in range(-1, 2):
			for pond: Dictionary in t.geography.basins(t, Vector2i(x, y)):
				pond_count += 1
				shapes[str(pond.radii)] = true
				var center := Vector2i(pond.center)
				for dy in range(-30, 31):
					for dx in range(-30, 31):
						var cell := center + Vector2i(dx, dy)
						if t.natural_ground(cell) != WorldTerrain.Ground.WATER:
							continue
						water_count += 1
						check(not t.is_trail(cell) and not t.fits(cell), "Water stays outside routes and excludes ordinary walking")
						var at := Vector2(cell) + Vector2(0.37, 0.61)
						var hit: Variant = Ray.intersect(t, Vector3(at.x, 30, at.y), Vector3.DOWN, 60)
						check(hit != null and absf(hit.y - t.display_height(at)) < 0.00001, "Picking matches continuous bed/level water intersection")
	check(pond_count > 2 and shapes.size() > 2 and water_count > 100, "Representative districts have multiple distinct pond shapes")
	production_border(t, t.geography.basins(t, Vector2i.ZERO)[0])
	var negative_ponds: Array = t.geography.basins(t, Vector2i(-1, -1))
	check(not negative_ponds.is_empty(), "Negative-coordinate production pond fixture exists")
	if not negative_ponds.is_empty():
		production_border(t, negative_ponds[0])
	var cells := [Vector2i(32, 7), Vector2i(32, 32), Vector2i(95, 8), Vector2i(-144, -160)]
	var baseline: Array = []
	for cell in cells:
		baseline.append([t.sample(cell), t.corners(cell), t.vertex_normal(cell)])
	# Small disposable windows force real retirement and reinsertion, not just clear().
	t.geography.basin_cell_window.capacity = 8
	t.geography.road_cell_window.capacity = 8
	t.geography.cell_basins.clear()
	t.geography.cell_roads.clear()
	for index in range(24):
		t.sample(Vector2i(index * 33, index * -23))
	check(t.geography.cell_basins.size() <= 8 and t.geography.cell_roads.size() <= 8, "New cell descriptor caches retire within their configured bounds")
	t._height_cache.clear()
	t._normal_cache.clear()
	t._slope_cache.clear()
	for index in range(cells.size() - 1, -1, -1):
		var cell: Vector2i = cells[index]
		check(baseline[index] == [t.sample(cell), t.corners(cell), t.vertex_normal(cell)], "Cache turnover and reversed reconstruction preserve final generation")
	var fingerprint: Array = []
	for cell in [Vector2i.ZERO,Vector2i(32,7),Vector2i(32,32),Vector2i(95,8),Vector2i(-144,-160),Vector2i(1000000,-1000000)]:
		var row := t.sample(cell)
		fingerprint.append([cell.x, cell.y, row.ground, row.route_axes, row.obstacle, "%.7f" % t.vertex_height(cell)])
	check(JSON.stringify(fingerprint).sha256_text() == "1983c5393879a78b3b11aea3f51568da1cf2d293d37145685ebfe898e9c0d03c", "Pinned Godot 4.7.2 generation-7 representative fingerprint")
	var snapshot := ExpeditionSave.snapshot(t.world_seed, Vector2i.ZERO, false, false, t.generation_version, t.climate, {}, t.relief)
	check(ExpeditionSave.validate(snapshot), "Current settings save admission")
	snapshot.generation_version = 6
	check(not ExpeditionSave.validate(snapshot), "Prior geography explicitly rejected")
	print("TERRAIN GEOGRAPHY: %d checks, %d failures, %d ms, %d ponds." % [checks, failures, Time.get_ticks_msec() - start, pond_count])
	quit(0 if failures == 0 else 1)
