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
var hubs: Dictionary = {}
var hub_window := CacheWindow.new(256)
var path_jobs: Dictionary = {}
var basin_jobs: Dictionary = {}
var drainage_jobs: Dictionary = {}
var path_basin_prepared: Dictionary = {}

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
	while not prepare_basins(t, area): pass
	return ponds[area]

## One raw drainage sample, pond candidate or channel attempt per call. The same
## deterministic builder serves synchronous generation and cooperative streaming.
func prepare_basins(t: RefCounted, area: Vector2i) -> bool:
	if ponds.has(area): return true
	if not basin_jobs.has(area):
		if basin_jobs.size() >= 128: basin_jobs.erase(basin_jobs.keys()[0])
		var count: int = t.roll(area, 701) % (int(t.relief.pond_candidates) + 1)
		if area == Vector2i.ZERO: count = maxi(1, count)
		basin_jobs[area] = {"result": [], "count": count, "candidate": 0, "channel": 0, "attempt": 0, "cost": INF, "chosen": [], "level": 0.0}
	var job: Dictionary = basin_jobs[area]
	if job.count > 0 and float(t.relief.drainage_influence) > 0 and not drainage.has(area):
		prepare_drainage(t, area)
		return false
	if job.candidate < job.count:
		build_basin_candidate(t, area, job.candidate, job.result)
		job.candidate += 1
		return false
	if float(t.relief.stream_length) > 0.0 and job.channel < job.result.size():
		var pond: Dictionary = job.result[job.channel]
		var evaluated := channel_candidate(t, area, pond, job.result, job.attempt)
		if float(evaluated.cost) < float(job.cost):
			job.cost = evaluated.cost
			job.chosen = evaluated.points
			job.level = evaluated.level
		job.attempt += 1
		if job.attempt == 24:
			if not job.chosen.is_empty():
				apply_channel(t, pond, job.chosen, job.level)
				job.channel = job.result.size() # First accepted channel owns the region.
			else:
				job.channel += 1
			job.attempt = 0
			job.cost = INF
			job.chosen = []
		return false
	pond_window.store(ponds, area, job.result)
	basin_jobs.erase(area)
	return true

func prepare_drainage(t: RefCounted, area: Vector2i) -> void:
	if not drainage_jobs.has(area):
		if drainage_jobs.size() >= 128: drainage_jobs.erase(drainage_jobs.keys()[0])
		drainage_jobs[area] = PackedFloat64Array()
	var heights: PackedFloat64Array = drainage_jobs[area]
	if heights.size() < 81:
		var index := heights.size()
		heights.append(t.heightfield.surface_height(Vector2(area * REGION + Vector2i(index % 9, index / 9) * 16)))
		drainage_jobs[area] = heights
		return
	var result := TerrainDrainage.analyze(heights, 9, 9)
	result["raw"] = heights
	drainage_window.store(drainage, area, result)
	drainage_jobs.erase(area)

func build_basin_candidate(t: RefCounted, area: Vector2i, index: int, result: Array) -> void:
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
		return
	var clear := true
	for prior: Dictionary in result:
		if center.distance_to(prior.center) < reach + float(prior.reach):
			clear = false
	if not clear:
		return
	result.append({"center": center, "radii": radii, "reach": reach,
		"angle": float(t.roll(area, 706 + salt) % 6283) / 1000,
		"phase": float(t.roll(area, 707 + salt) % 6283) / 1000,
		"level": t.heightfield.surface_height(center) - 0.22,
		"id": Vector3i(area.x, area.y, index)})

func attach_channel(t: RefCounted, area: Vector2i, pond: Dictionary, siblings: Array) -> bool:
	var best_score := INF
	var chosen: Array = []
	var chosen_level: float = pond.level
	for attempt in range(24):
		var evaluated := channel_candidate(t, area, pond, siblings, attempt)
		if float(evaluated.cost) < best_score:
			best_score = evaluated.cost
			chosen = evaluated.points
			chosen_level = evaluated.level
	if chosen.is_empty(): return false
	apply_channel(t, pond, chosen, chosen_level)
	return true

func apply_channel(t: RefCounted, pond: Dictionary, chosen: Array, level: float) -> void:
	pond["channel"] = chosen
	pond["channel_width"] = float(t.relief.stream_width)
	pond["pool_radius"] = float(t.relief.stream_width) * 2.2
	pond["level"] = level
	var run := maxf(Vector2(pond.radii).x, Vector2(pond.radii).y) * 1.3 + float(t.relief.stream_length)
	pond["query_reach"] = maxf(float(pond.reach), run + float(pond.pool_radius) * 2.0)

func channel_candidate(t: RefCounted, area: Vector2i, pond: Dictionary, siblings: Array, attempt: int) -> Dictionary:
	var width: float = t.relief.stream_width
	var pool_radius := width * 2.2
	var start: Vector2 = pond.center
	var run := maxf(Vector2(pond.radii).x, Vector2(pond.radii).y) * 1.3 + float(t.relief.stream_length)
	var angle := float(t.roll(area, 780) % 6283) / 1000.0 + attempt * TAU / 12.0
	var direction := Vector2.from_angle(angle)
	var length_scale := 1.0 if attempt < 12 else 0.65
	var finish := start + direction * run * length_scale
	var middle := start.lerp(finish, 0.6) + direction.orthogonal() * sin(angle * 3.0) * 4.0
	var points: Array[Vector2] = [start, middle, finish]
	var valid := true
	var score := 0.0
	var low: float = pond.level
	var high: float = pond.level
	for segment in range(2):
		for index in range(17):
			var at := points[segment].lerp(points[segment + 1], float(index) / 16.0)
			var edge := at - Vector2(area * REGION)
			var margin := pool_radius * 2.0 + 8.0
			if edge.x < margin or edge.y < margin or edge.x > REGION - margin or edge.y > REGION - margin or absf(at.y) < margin + 14.0 or at.length() < margin + 18.0 or at.distance_to(Vector2(t.landmark())) < margin + 16.0:
				valid = false
				break
			for other: Dictionary in siblings:
				if other.id != pond.id and at.distance_to(other.center) < float(other.reach) * 2.0 + margin:
					valid = false
			var raw: float = t.heightfield.surface_height(at)
			low = minf(low, raw)
			high = maxf(high, raw)
			var difference := absf(raw - float(pond.level))
			# Avoid cutting a level channel through a hillside or building a dam.
			if difference > 2.5: valid = false
			score += difference
		if not valid: break
	# Fit a shallow common level below the whole corridor. Never build a
	# raised water ribbon across low ground; omit it when this needs a deep cut.
	var level := minf(float(pond.level), low - 0.1)
	valid = valid and high - level <= 2.0 and float(pond.level) - level <= 1.2
	return {"points": points if valid else [], "cost": score if valid else INF, "level": level}

static func pond_distance(descriptor: Dictionary, at: Vector2) -> float:
	var delta: Vector2 = (at - Vector2(descriptor.center)).rotated(-float(descriptor.angle)) / Vector2(descriptor.radii)
	var angle := delta.angle()
	var rim := 1.0 + 0.13 * sin(angle * 3 + float(descriptor.phase)) + 0.07 * sin(angle * 5 - float(descriptor.phase))
	return delta.length_squared() / (rim * rim)

static func bank_rise(descriptor: Dictionary, at: Vector2) -> float:
	if not descriptor.has("channel"): return 3.0
	# A pond's three-cell bank rise must not be squeezed into a narrow channel.
	# Blend outside the pond rather than introducing a second confluence seam.
	return lerpf(3.0, minf(3.0, float(descriptor.channel_width) * 0.4), smoothstep(1.0, 2.5, pond_distance(descriptor, at)))

static func basin_distance(descriptor: Dictionary, at: Vector2) -> float:
	var distance := pond_distance(descriptor, at)
	if descriptor.has("channel"):
		var points: Array = descriptor.channel
		for index in range(points.size() - 1):
			var nearest := Geometry2D.get_closest_point_to_segment(at, points[index], points[index + 1])
			distance = minf(distance, at.distance_squared_to(nearest) / pow(float(descriptor.channel_width), 2.0))
		distance = minf(distance, at.distance_squared_to(points[-1]) / pow(float(descriptor.pool_radius), 2.0))
	return distance

func basin(t: RefCounted, at: Vector2) -> Dictionary:
	var area := region(at)
	var best := INF
	var clearance := INF
	var found: Dictionary = {}
	for y in range(-1, 2):
		for x in range(-1, 2):
			for descriptor: Dictionary in basins(t, area + Vector2i(x, y)):
				if at.distance_squared_to(descriptor.center) > pow(float(descriptor.get("query_reach", descriptor.reach)) * 2, 2):
					continue
				clearance = minf(clearance, at.distance_to(descriptor.center) - float(descriptor.reach))
				if descriptor.has("channel"):
					for index in range(descriptor.channel.size() - 1):
						var nearest := Geometry2D.get_closest_point_to_segment(at, descriptor.channel[index], descriptor.channel[index + 1])
						clearance = minf(clearance, at.distance_to(nearest) - float(descriptor.channel_width) * 2.0 - 2.0)
					clearance = minf(clearance, at.distance_to(descriptor.channel[-1]) - float(descriptor.pool_radius) * 2.0 - 2.0)
				var distance := basin_distance(descriptor, at)
				if distance < best:
					best = distance
					found = descriptor
	return {"distance": best, "descriptor": found, "clearance": clearance}

func hub(t: RefCounted, area: Vector2i) -> Vector2:
	if hubs.has(area): return hubs[area]
	var initial := Vector2(area * REGION) + Vector2(32 + t.roll(area, 730) % 65, 32 + t.roll(area, 731) % 65)
	for index in range(17):
		var at := (initial + Vector2.from_angle(index * 2.4) * (index * 3)).clamp(Vector2(area * REGION) + Vector2(16, 16), Vector2(area * REGION) + Vector2(112, 112))
		if float(basin(t, at).clearance) > 0:
			hub_window.store(hubs, area, at)
			return at
	hub_window.store(hubs, area, initial)
	return initial

func connection(t: RefCounted, a: Vector2, b: Vector2, key: Vector2i, salt: int) -> Array:
	var best: Array = []
	var best_cost := INF
	for candidate in range(5):
		var evaluated := connection_candidate(t, a, b, key, salt, candidate)
		if float(evaluated.cost) < best_cost:
			best = evaluated.points
			best_cost = evaluated.cost
	return best

func connection_candidate(t: RefCounted, a: Vector2, b: Vector2, key: Vector2i, salt: int, candidate: int) -> Dictionary:
	var normal := (b - a).orthogonal().normalized()
	var points: Array = []
	var cost := 0.0
	var previous := a
	var previous_height: float = t.heightfield.surface_height(a)
	var bend := float(t.roll(key, salt) % 41 - 20) + (candidate - 2) * 19
	for index in range(33):
		var progress := float(index) / 32
		var at := a.lerp(b, progress) + normal * sin(progress * PI) * bend * float(t.relief.route_bend)
		if float(basin(t, at).clearance) < 0 or t.heightfield.surface_normal(at).angle_to(Vector3.UP) > deg_to_rad(float(t.relief.walkable_slope_degrees)):
			return {"points": points, "cost": INF}
		var height: float = t.heightfield.surface_height(at)
		cost += at.distance_to(previous) + absf(height - previous_height) * 15
		points.append(at)
		previous = at
		previous_height = height
	return {"points": points, "cost": cost}

func raw_paths(t: RefCounted, area: Vector2i) -> Array:
	if roads.has(area):
		return roads[area]
	var result: Array = []
	for request: Dictionary in path_requests(t, area):
		var path := connection(t, request.a, request.b, area, request.salt)
		if not path.is_empty(): result.append(path)
	road_window.store(roads, area, result)
	return result

func path_requests(t: RefCounted, area: Vector2i) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var start := hub(t, area)
	# Asymmetric degrees: east continuation, seeded north link and optional spur.
	for direction in [Vector2i.RIGHT, Vector2i.DOWN]:
		if direction == Vector2i.DOWN and t.roll(area, 741) % 100 < 38:
			continue
		result.append({"a": start, "b": hub(t, area + direction), "salt": 742 + direction.x})
	if t.roll(area, 744) % 100 < 55:
		var finish: Vector2 = start + Vector2.from_angle(float(t.roll(area, 745) % 6283) / 1000) * (24 + t.roll(area, 746) % 35)
		result.append({"a": start, "b": finish, "salt": 747})
	# A bounded spur connects each nearby district to the anchored main approach.
	if area.y == 0 or area.y == -1:
		var finish := Vector2(start.x, t.trail_y(roundi(start.x)))
		result.append({"a": start, "b": finish, "salt": 748})
	return result

func path_traversable(t: RefCounted, path: Array) -> bool:
	var progress := {"checked": {}, "previous": null}
	for index in range(path.size() - 1):
		if not path_segment_traversable(t, path[index], path[index + 1], progress): return false
	return true

func path_segment_traversable(t: RefCounted, a: Vector2, b: Vector2, progress: Dictionary) -> bool:
	var steps := maxi(1, ceili(a.distance_to(b) * 2.0))
	for step in range(steps + 1):
		var center := Vector2i(a.lerp(b, float(step) / steps).floor())
		var centers: Array[Vector2i] = [center]
		if progress.previous != null and center.x != progress.previous.x and center.y != progress.previous.y:
			centers.append(Vector2i(center.x, progress.previous.y))
			centers.append(Vector2i(progress.previous.x, center.y))
		progress.previous = center
		for crossing in centers:
			for y in range(-1, 2):
				for x in range(-1, 2):
					var at := crossing + Vector2i(x, y)
					if progress.checked.has(at): continue
					progress.checked[at] = true
					if t.cabin_footprint.has_point(at) or t.natural_ground(at) == t.Ground.WATER or not t.slope_fits(at): return false
	return true

func paths(t: RefCounted, area: Vector2i) -> Array:
	if t.geography_ready and admitted_roads.has(area): return admitted_roads[area]
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
	path_jobs.erase(area)
	path_basin_prepared.erase(area)
	return result

## Yield between individual route segments, rather than validating a whole
## district inside the first cell's streaming step. Publish only complete regions.
func prepare_paths(t: RefCounted, area: Vector2i) -> bool:
	if admitted_roads.has(area): return true
	if not path_basin_prepared.has(area):
		if path_basin_prepared.size() >= 256: path_basin_prepared.erase(path_basin_prepared.keys()[0])
		path_basin_prepared[area] = 0
	var warmed: int = path_basin_prepared[area]
	if warmed < 49:
		var owner := area + Vector2i(warmed % 7 - 3, warmed / 7 - 3)
		if prepare_basins(t, owner): path_basin_prepared[area] = warmed + 1
		return false
	if not path_jobs.has(area):
		# Partial jobs are disposable and bounded, including cancelled stream jobs.
		if path_jobs.size() >= 32: path_jobs.erase(path_jobs.keys()[0])
		path_jobs[area] = {"paths": roads.get(area, []), "index": 0, "segment": 0, "checked": {}, "previous": null, "result": [], "requests": path_requests(t, area) if not roads.has(area) else [], "request": 0, "candidate": 0, "best": [], "cost": INF}
		return false
	var job: Dictionary = path_jobs[area]
	if job.request < job.requests.size():
		var request: Dictionary = job.requests[job.request]
		var evaluated := connection_candidate(t, request.a, request.b, area, request.salt, job.candidate)
		if float(evaluated.cost) < float(job.cost):
			job.best = evaluated.points
			job.cost = evaluated.cost
		job.candidate += 1
		if job.candidate == 5:
			if not job.best.is_empty(): job.paths.append(job.best)
			job.request += 1
			job.candidate = 0
			job.best = []
			job.cost = INF
			if job.request == job.requests.size(): road_window.store(roads, area, job.paths)
		return false
	if job.index >= job.paths.size():
		admitted_road_window.store(admitted_roads, area, job.result)
		path_jobs.erase(area)
		path_basin_prepared.erase(area)
		return true
	var path: Array = job.paths[job.index]
	if job.segment >= path.size() - 1:
		job.result.append(path)
		job.index += 1
		job.segment = 0
		job.checked = {}
		job.previous = null
		return false
	if not path_segment_traversable(t, path[job.segment], path[job.segment + 1], job):
		job.index += 1
		job.segment = 0
		job.checked = {}
		job.previous = null
		return false
	job.segment += 1
	return false

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
