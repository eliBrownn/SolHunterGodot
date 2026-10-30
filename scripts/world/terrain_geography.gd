extends RefCounted
## Versioned absolute geography, independent of render chunks and ecology.
## Pond queries visit nine regions, road tiles at most 25; all work is bounded.
const REGION := 128
const CacheWindow = preload("res://scripts/core/derived_cache_window.gd")
var ponds: Dictionary = {}
var roads: Dictionary = {}
var admitted_roads: Dictionary = {}
var admitted_road_window := CacheWindow.new(256)
var tiles: Dictionary = {}
var cell_basins: Dictionary = {}
var cell_roads: Dictionary = {}
var pond_window := CacheWindow.new(256)
var road_window := CacheWindow.new(256)
var tile_window := CacheWindow.new(256)
var basin_cell_window := CacheWindow.new(32768)
var road_cell_window := CacheWindow.new(32768)
var drainage: Dictionary = {}
var drainage_window := CacheWindow.new(128)

func local_drainage(t: RefCounted, area: Vector2i) -> Dictionary:
	if drainage.has(area):
		return drainage[area]
	var heights := PackedFloat64Array()
	for y in range(9):
		for x in range(9):
			heights.append(t.heightfield.surface_height(Vector2(area * REGION + Vector2i(x, y) * 16)))
	var result := TerrainDrainage.analyze(heights, 9, 9)
	result["raw"] = heights
	drainage_window.store(drainage, area, result)
	return result

func flow_center(t: RefCounted, area: Vector2i, initial: Vector2, reach: float) -> Vector2:
	var field := local_drainage(t, area)
	var best := INF
	var selected := initial
	var influence: float = t.relief.drainage_influence
	for dy in [-8, 0, 8]:
		for dx in [-8, 0, 8]:
			var candidate := (initial + Vector2(dx, dy)).clamp(Vector2(area * REGION) + Vector2(24,24), Vector2(area * REGION) + Vector2(104,104))
			if absf(candidate.y) < reach + 12 or candidate.distance_to(Vector2(t.landmark())) < reach + 16 or candidate.length() < reach + 18:
				continue
			var local := (candidate - Vector2(area * REGION)) / 16.0
			var index := clampi(roundi(local.y), 1, 7) * 9 + clampi(roundi(local.x), 1, 7)
			var capture := log(1.0 + float(field.accumulation[index])) + maxf(0.0, field.filled[index] - field.raw[index])
			var score: float = t.heightfield.surface_height(candidate) + candidate.distance_to(initial) * (1.0 - influence) * 0.2 - influence * capture * 0.6
			if score < best:
				best = score
				selected = candidate
	return selected

func cell_basin(t: RefCounted, cell: Vector2i) -> Dictionary:
	if cell_basins.has(cell):
		return cell_basins[cell]
	var found := basin(t, Vector2(cell) + Vector2(0.5, 0.5))
	basin_cell_window.store(cell_basins, cell, found)
	return found

func region(at: Vector2) -> Vector2i:
	return Vector2i(floori(at.x / REGION), floori(at.y / REGION))

func basins(t: RefCounted, area: Vector2i) -> Array:
	if ponds.has(area):
		return ponds[area]
	var result: Array = []
	var count: int = t.roll(area, 701) % (int(t.relief.pond_candidates) + 1)
	if area == Vector2i.ZERO:
		count = maxi(1, count) # The representative district includes a pond approach.
	for index in range(count):
		var salt := index * 19
		var center := Vector2(area * REGION) + Vector2(40 + t.roll(area, 702 + salt) % 49, 40 + t.roll(area, 703 + salt) % 49)
		if area == Vector2i.ZERO and index == 0:
			center = Vector2(32 + t.roll(area, 702) % 11, 35 + t.roll(area, 703) % 9)
		var radii := Vector2(7 + t.roll(area, 704 + salt) % 17, 6 + t.roll(area, 705 + salt) % 12) * float(t.relief.pond_scale)
		if area == Vector2i.ZERO and index == 0:
			radii = Vector2(11 + t.roll(area, 704) % 5, 9 + t.roll(area, 705) % 4) * float(t.relief.pond_scale)
		var reach := maxf(radii.x, radii.y) * 1.22 + 7
		if float(t.relief.drainage_influence) > 0:
			center = flow_center(t, area, center, reach)
		# Whole descriptors are omitted near authored travel and foundations.
		# The main approach stays within fourteen cells of its authored axis.
		if absf(center.y) < reach + 12 or center.distance_to(Vector2(t.landmark())) < reach + 16 or center.length() < reach + 18:
			continue
		var clear := true
		for prior: Dictionary in result:
			if center.distance_to(prior.center) < reach + float(prior.reach):
				clear = false
		if not clear:
			continue
		result.append({"center": center, "radii": radii, "reach": reach,
			"angle": float(t.roll(area, 706 + salt) % 6283) / 1000,
			"phase": float(t.roll(area, 707 + salt) % 6283) / 1000,
			"level": t.heightfield.surface_height(center) - 0.22,
			"id": Vector3i(area.x, area.y, index)})
	pond_window.store(ponds, area, result)
	return result

static func basin_distance(descriptor: Dictionary, at: Vector2) -> float:
	var delta: Vector2 = (at - Vector2(descriptor.center)).rotated(-float(descriptor.angle)) / Vector2(descriptor.radii)
	var angle := delta.angle()
	var rim := 1.0 + 0.13 * sin(angle * 3 + float(descriptor.phase)) + 0.07 * sin(angle * 5 - float(descriptor.phase))
	return delta.length_squared() / (rim * rim)

func basin(t: RefCounted, at: Vector2) -> Dictionary:
	var area := region(at)
	var best := INF
	var clearance := INF
	var found: Dictionary = {}
	for y in range(-1, 2):
		for x in range(-1, 2):
			for descriptor: Dictionary in basins(t, area + Vector2i(x, y)):
				if at.distance_squared_to(descriptor.center) > pow(float(descriptor.reach) * 2, 2):
					continue
				clearance = minf(clearance, at.distance_to(descriptor.center) - float(descriptor.reach))
				var distance := basin_distance(descriptor, at)
				if distance < best:
					best = distance
					found = descriptor
	return {"distance": best, "descriptor": found, "clearance": clearance}

func hub(t: RefCounted, area: Vector2i) -> Vector2:
	var initial := Vector2(area * REGION) + Vector2(32 + t.roll(area, 730) % 65, 32 + t.roll(area, 731) % 65)
	for index in range(17):
		var at := (initial + Vector2.from_angle(index * 2.4) * (index * 3)).clamp(Vector2(area * REGION) + Vector2(16, 16), Vector2(area * REGION) + Vector2(112, 112))
		if float(basin(t, at).clearance) > 0:
			return at
	return initial

func connection(t: RefCounted, a: Vector2, b: Vector2, key: Vector2i, salt: int) -> Array:
	var best: Array = []
	var best_cost := INF
	var normal := (b - a).orthogonal().normalized()
	for candidate in range(5):
		var points: Array = []
		var cost := 0.0
		var previous := a
		var previous_height: float = t.heightfield.surface_height(a)
		var bend := float(t.roll(key, salt) % 41 - 20) + (candidate - 2) * 19
		for index in range(33):
			var progress := float(index) / 32
			var at := a.lerp(b, progress) + normal * sin(progress * PI) * bend * float(t.relief.route_bend)
			if float(basin(t, at).clearance) < 0:
				cost = INF
				break
			if t.heightfield.surface_normal(at).angle_to(Vector3.UP) > deg_to_rad(float(t.relief.walkable_slope_degrees)):
				cost = INF
				break
			var height: float = t.heightfield.surface_height(at)
			cost += at.distance_to(previous) + absf(height - previous_height) * 15
			points.append(at)
			previous = at
			previous_height = height
		if cost < best_cost:
			best = points
			best_cost = cost
	return best

func raw_paths(t: RefCounted, area: Vector2i) -> Array:
	if roads.has(area):
		return roads[area]
	var result: Array = []
	var start := hub(t, area)
	# Asymmetric degrees: east continuation, seeded north link and optional spur.
	for direction in [Vector2i.RIGHT, Vector2i.DOWN]:
		if direction == Vector2i.DOWN and t.roll(area, 741) % 100 < 38:
			continue
		var path := connection(t, start, hub(t, area + direction), area, 742 + direction.x)
		if not path.is_empty():
			result.append(path)
	if t.roll(area, 744) % 100 < 55:
		var finish: Vector2 = start + Vector2.from_angle(float(t.roll(area, 745) % 6283) / 1000) * (24 + t.roll(area, 746) % 35)
		var path := connection(t, start, finish, area, 747)
		if not path.is_empty():
			result.append(path)
	# A bounded spur connects each nearby district to the anchored main approach.
	if area.y == 0 or area.y == -1:
		var finish := Vector2(start.x, t.trail_y(roundi(start.x)))
		var path := connection(t, start, finish, area, 748)
		if not path.is_empty():
			result.append(path)
	road_window.store(roads, area, result)
	return result

func path_traversable(t: RefCounted, path: Array) -> bool:
	var checked := {}
	var previous: Variant = null
	for index in range(path.size() - 1):
		var a: Vector2 = path[index]
		var b: Vector2 = path[index + 1]
		var steps := maxi(1, ceili(a.distance_to(b) * 2.0))
		for step in range(steps + 1):
			var center := Vector2i(a.lerp(b, float(step) / steps).floor())
			var centers: Array[Vector2i] = [center]
			if previous != null and center.x != previous.x and center.y != previous.y:
				centers.append(Vector2i(center.x,previous.y))
				centers.append(Vector2i(previous.x,center.y))
			previous = center
			for crossing in centers:
				for y in range(-1,2):
					for x in range(-1,2):
						var at := crossing + Vector2i(x,y)
						if checked.has(at):
							continue
						checked[at] = true
						if t.cabin_footprint.has_point(at) or t.natural_ground(at) == t.Ground.WATER or not t.slope_fits(at):
							return false
	return true

func paths(t: RefCounted, area: Vector2i) -> Array:
	var candidates := raw_paths(t,area)
	if not t.geography_ready:
		return candidates # Initial cabin placement reserves raw route descriptors.
	if admitted_roads.has(area):
		return admitted_roads[area]
	var result: Array = []
	for path in candidates:
		if path_traversable(t,path):
			result.append(path)
	admitted_road_window.store(admitted_roads,area,result)
	return result

func route_tile(t: RefCounted, coord: Vector2i) -> Array:
	if tiles.has(coord):
		return tiles[coord]
	var result: Array = []
	var bounds := Rect2(Vector2(coord * 16) - Vector2(8, 8), Vector2(32, 32))
	var area := region(bounds.get_center())
	for y in range(-2, 3):
		for x in range(-2, 3):
			for path: Array in paths(t, area + Vector2i(x, y)):
				for index in range(path.size() - 1):
					var a: Vector2 = path[index]
					var b: Vector2 = path[index + 1]
					if bounds.intersects(Rect2(a.min(b), (b - a).abs()).grow(0.001)):
						result.append([a, b, 1 if absf(b.x - a.x) >= absf(b.y - a.y) else 2])
	tile_window.store(tiles, coord, result)
	return result

func axes(t: RefCounted, cell: Vector2i, margin: int) -> int:
	var result := 1 if absi(cell.y - t.trail_y(cell.x)) <= 3 + margin else 0
	if not cell_roads.has(cell):
		var at := Vector2(cell) + Vector2(0.5, 0.5)
		var distances := Vector2(INF, INF)
		for segment: Array in route_tile(t, t.chunk_of(cell)):
			var axis := int(segment[2]) - 1
			distances[axis] = minf(distances[axis], at.distance_squared_to(Geometry2D.get_closest_point_to_segment(at, segment[0], segment[1])))
		road_cell_window.store(cell_roads, cell, distances)
	var distances: Vector2 = cell_roads[cell]
	if distances.x <= pow(3.5 + margin, 2):
		result |= 1
	if distances.y <= pow(3.5 + margin, 2):
		result |= 2
	return result
