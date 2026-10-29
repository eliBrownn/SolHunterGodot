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

static func plan(camera: Camera3D, origin: Vector2, player: Vector2i, settings: View3DSettings, height: float, minimum_height: float = 0.0) -> Array[Vector2i]:
	var planes := camera.get_frustum()
	var desired: Dictionary = {}
	var local := Vector2i(WorldTerrain.floor_div(player.x, 16), WorldTerrain.floor_div(player.y, 16))
	# Keep near terrain and the tactical arena resident, even behind the camera.
	for y in range(-1, 2):
		for x in range(-1, 2):
			desired[local + Vector2i(x, y)] = true
	var camera_ground := origin + Vector2(camera.position.x, camera.position.z)
	var middle := Vector2i(floori(camera_ground.x / 16), floori(camera_ground.y / 16))
	for y in range(-1, 2):
		for x in range(-1, 2):
			desired[middle + Vector2i(x, y)] = true
	var radius := ceili((settings.render_distance + settings.stream_margin) / 16.0) + 1
	for y in range(-radius, radius + 1):
		for x in range(-radius, radius + 1):
			var coord := middle + Vector2i(x, y)
			if visible_with_planes(planes, Vector2(coord * 16) - origin, height, settings.stream_margin, minimum_height):
				desired[coord] = true
	var result: Array[Vector2i] = []
	result.assign(desired.keys())
	result.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return Vector2(a * 16 + Vector2i(8, 8)).distance_squared_to(origin) < Vector2(b * 16 + Vector2i(8, 8)).distance_squared_to(origin))
	return result
