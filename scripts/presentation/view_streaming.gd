extends RefCounted
## Conservative frustum/AABB intersection, including tall imported assets and a prefetch margin.

static func visible(camera: Camera3D, relative: Vector2, height: float, margin: float = 0.0, minimum_height: float = 0.0) -> bool:
	return visible_with_planes(camera.get_frustum(), relative, height, margin, minimum_height)

static func visible_with_planes(planes: Array[Plane], relative: Vector2, height: float, margin: float = 0.0, minimum_height: float = 0.0) -> bool:
	var center := Vector3(relative.x + 8, (height + minimum_height) * 0.5, relative.y + 8)
	var extent := Vector3(8 + margin, (height - minimum_height) * 0.5 + 0.5, 8 + margin)
	for plane in planes:
		var radius: float = plane.normal.abs().dot(extent)
		if plane.distance_to(center) > radius:
			return false
	return true

static func plan(camera: Camera3D, origin: Vector2, player: Vector2i, settings: View3DSettings, height: float, minimum_height: float = 0.0, asset_margin: float = 0.0, lookahead: Vector2 = Vector2.ZERO) -> Array[Vector2i]:
	var planes := camera.get_frustum()
	var desired: Dictionary = {}
	var local := Vector2i(WorldTerrain.floor_div(player.x, 16), WorldTerrain.floor_div(player.y, 16))
	# Keep near terrain and the tactical arena resident, even behind the camera.
	for y in range(-2, 3):
		for x in range(-2, 3):
			desired[local + Vector2i(x, y)] = true
	var camera_ground := origin + Vector2(camera.position.x, camera.position.z)
	var middle := Vector2i(floori(camera_ground.x / 16), floori(camera_ground.y / 16))
	for y in range(-1, 2):
		for x in range(-1, 2):
			desired[middle + Vector2i(x, y)] = true
	var margin:=maxf(settings.stream_margin,asset_margin)
	var radius := ceili((settings.render_distance + margin) / 16.0) + 1
	for y in range(-radius, radius + 1):
		for x in range(-radius, radius + 1):
			var coord := middle + Vector2i(x, y)
			if visible_with_planes(planes, Vector2(coord * 16) - origin, height, margin, minimum_height):
				desired[coord] = true
	if not lookahead.is_zero_approx():
		var ahead := Vector2i(((Vector2(player)+lookahead)/16.0).floor())
		for y in range(-1,2):
			for x in range(-1,2): desired[ahead+Vector2i(x,y)] = true
	var result: Array[Vector2i] = []
	for coord: Vector2i in desired:
		if within_radius(coord, local, settings.active_chunk_radius):
			result.append(coord)
	result.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		if settings.spiral_chunk_loading: return spiral_index(facing_offset(a-local,lookahead)) < spiral_index(facing_offset(b-local,lookahead))
		if lookahead.is_zero_approx(): return Vector2(a*16+Vector2i(8,8)).distance_squared_to(origin) < Vector2(b*16+Vector2i(8,8)).distance_squared_to(origin)
		var near_a := Vector2(a*16+Vector2i(8,8)).distance_squared_to(Vector2(player)) < 24.0*24.0
		var near_b := Vector2(b*16+Vector2i(8,8)).distance_squared_to(Vector2(player)) < 24.0*24.0
		if near_a != near_b: return near_a
		return Vector2(a*16+Vector2i(8,8)).distance_squared_to(Vector2(player)+lookahead) < Vector2(b*16+Vector2i(8,8)).distance_squared_to(Vector2(player)+lookahead))
	# Reserve space for the hidden cache and one unfinished preparation job.
	result.resize(mini(result.size(), live_capacity(settings)))
	return result

## Square spiral: center, east, south, west, north, then the next ring.
## Filtering this order to desired chunks preserves the existing visibility/radius rules.
static func spiral_index(offset: Vector2i) -> int:
	var ring := maxi(absi(offset.x), absi(offset.y))
	if ring == 0: return 0
	var base := (2*ring-1)*(2*ring-1)
	if offset.x == ring and offset.y > -ring: return base + offset.y + ring - 1
	if offset.y == ring: return base + 2*ring + ring - 1 - offset.x
	if offset.x == -ring: return base + 4*ring + ring - 1 - offset.y
	return base + 6*ring + offset.x + ring - 1

## Start each ring toward travel; keep all nearer rings ahead of outer scenery.
static func facing_offset(offset: Vector2i, heading: Vector2) -> Vector2i:
	if heading.is_zero_approx(): return offset
	if absf(heading.x) >= absf(heading.y):
		return offset if heading.x >= 0 else -offset
	return Vector2i(offset.y,-offset.x) if heading.y >= 0 else Vector2i(-offset.y,offset.x)

static func within_radius(coord: Vector2i, center: Vector2i, radius: int) -> bool:
	return absi(coord.x - center.x) <= radius and absi(coord.y - center.y) <= radius

static func live_capacity(settings: View3DSettings) -> int:
	return settings.max_resident_chunks - settings.stream_detail_cache_chunks - (settings.chunk_preparation_jobs if settings.threaded_chunk_preparation else 1)
