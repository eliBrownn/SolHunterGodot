extends SceneTree
## Isolate the broad phase from generation and check exact triangle/water hits.
const Ray = preload("res://scripts/presentation/terrain_ray.gd")

class Surface extends WorldTerrain:
	func _init() -> void:
		pass
	func vertex_height(cell: Vector2i) -> float:
		return sin(cell.x * 0.17) * 2.0 + cos(cell.y * 0.23)
	func corners(cell: Vector2i) -> Vector4:
		return Vector4(vertex_height(cell), vertex_height(cell + Vector2i.RIGHT), vertex_height(cell + Vector2i.ONE), vertex_height(cell + Vector2i.DOWN))
	func lake_distance(_cell: Vector2i) -> float:
		return 0.0
	func pond_at(_cell: Vector2i) -> Dictionary:
		return {"level": 0.5}

var failures := 0

func exhaustive(terrain: Surface, origin: Vector3, direction: Vector3, reach: float) -> Variant:
	var closest: Variant = null
	var endpoint := origin + direction * reach
	for z in range(floori(minf(origin.z, endpoint.z)) - 1, ceili(maxf(origin.z, endpoint.z)) + 2):
		for x in range(floori(minf(origin.x, endpoint.x)) - 1, ceili(maxf(origin.x, endpoint.x)) + 2):
			var h := terrain.corners(Vector2i(x, z))
			var a := Vector3(x, h.x, z)
			var b := Vector3(x + 1, h.y, z)
			var c := Vector3(x + 1, h.z, z + 1)
			var d := Vector3(x, h.w, z + 1)
			for triangle in [[a, b, c], [a, c, d]]:
				var hit: Variant = Geometry3D.ray_intersects_triangle(origin, direction, triangle[0], triangle[1], triangle[2])
				if hit != null and origin.distance_to(hit) <= reach and (closest == null or origin.distance_squared_to(hit) < origin.distance_squared_to(closest)):
					closest = hit
	if absf(direction.y) > 0.0000001:
		var travel := (0.5 - origin.y) / direction.y
		var hit := origin + direction * travel
		if travel >= 0 and travel <= reach and terrain.surface_height(Vector2(hit.x, hit.z)) <= 0.5 and (closest == null or origin.distance_squared_to(hit) < origin.distance_squared_to(closest)):
			closest = hit
	return closest

func _initialize() -> void:
	var terrain := Surface.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 69137
	var reference: Script = load("res://artifacts/picking-optimization/terrain_ray_before.gd") if "--paired" in OS.get_cmdline_user_args() else null
	var rays: Array = []
	for index in range(2000):
		var origin := Vector3(rng.randf_range(-12, 12), rng.randf_range(-5, 10), rng.randf_range(-12, 12))
		var direction := Vector3(rng.randf_range(-1, 1), rng.randf_range(-1, 1), rng.randf_range(-1, 1)).normalized()
		rays.append([origin, direction * [0.5, 1.0, 2.0][index % 3]])
	for origin in [Vector3(0, 0.5, 0), Vector3(1, 3, -1), Vector3(0, -3, 0)]:
		for direction in [Vector3.UP, Vector3.DOWN, Vector3.LEFT, Vector3.RIGHT, Vector3.FORWARD, Vector3.BACK]:
			rays.append([origin, direction])
	for row in rays:
		var actual: Variant = Ray.intersect(terrain, row[0], row[1], 30.0)
		# Rays originating underwater can hit submerged terrain as before.
		if actual != null:
			var point := Vector2(actual.x, actual.z)
			if absf(actual.y - terrain.surface_height(point)) > 0.0001 and not (absf(actual.y - 0.5) < 0.0001 and terrain.surface_height(point) <= 0.5001):
				failures += 1
		if reference != null:
			var expected: Variant = reference.intersect(terrain, row[0], row[1], 30.0)
			if not ((actual == null and expected == null) or (actual != null and expected != null and actual.is_equal_approx(expected))):
				failures += 1
	for row in rays.slice(0, 200):
		var direction: Vector3 = row[1].normalized()
		var actual: Variant = Ray.intersect(terrain, row[0], direction, 8.0)
		var expected: Variant = exhaustive(terrain, row[0], direction, 8.0)
		if not ((actual == null and expected == null) or (actual != null and expected != null and actual.is_equal_approx(expected))):
			failures += 1
	for x in range(-10, 11):
		var point := Vector2(x + 0.25, x * 0.5 + 0.75)
		var hit: Variant = Ray.intersect(terrain, Vector3(point.x, 10, point.y), Vector3.DOWN, 20)
		if hit == null or absf(hit.y - terrain.display_height(point)) > 0.0001:
			failures += 1
		if Ray.intersect(terrain, Vector3(point.x, 10, point.y), Vector3.RIGHT, 20) != null:
			failures += 1
	if reference != null:
		for sample in [["sky", Vector3(0.5, 20, 0.5), Vector3(1, 0.02, 0.3).normalized()], ["ground", Vector3(0.5, 20, 0.5), Vector3(1, -0.5, 0.3).normalized()]]:
			for implementation in [reference, Ray]:
				var start := Time.get_ticks_usec()
				for repetition in range(2000):
					implementation.intersect(terrain, sample[1], sample[2], 100.0)
				print("PICKING CPU ", sample[0], " ", "previous" if implementation == reference else "current", ": ", (Time.get_ticks_usec() - start) / 1000.0, " ms")
	print("TERRAIN RAY: %d rays, %d failures" % [rays.size(), failures])
	quit(0 if failures == 0 else 1)
