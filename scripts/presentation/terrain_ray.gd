extends RefCounted
## Exact first surface hit through a bounded XZ grid traversal; no physics copy.

static func intersect(terrain: WorldTerrain, origin: Vector3, direction: Vector3, reach: float) -> Variant:
	var cell := Vector2i(floori(origin.x), floori(origin.z))
	var step_x := 1 if direction.x > 0 else -1
	var step_z := 1 if direction.z > 0 else -1
	var delta_x := absf(1.0 / direction.x) if absf(direction.x) > 0.0000001 else INF
	var delta_z := absf(1.0 / direction.z) if absf(direction.z) > 0.0000001 else INF
	var next_x := (cell.x + (1 if step_x > 0 else 0) - origin.x) / direction.x if is_finite(delta_x) else INF
	var next_z := (cell.y + (1 if step_z > 0 else 0) - origin.z) / direction.z if is_finite(delta_z) else INF
	for iteration in range(ceili(reach * 3.0) + 8):
		var h := terrain.corners(cell)
		var a := Vector3(cell.x, h.x, cell.y)
		var b := Vector3(cell.x + 1, h.y, cell.y)
		var c := Vector3(cell.x + 1, h.z, cell.y + 1)
		var d := Vector3(cell.x, h.w, cell.y + 1)
		var closest: Variant = null
		for triangle in [[a, b, c], [a, c, d]]:
			var hit: Variant = Geometry3D.ray_intersects_triangle(origin, direction, triangle[0], triangle[1], triangle[2])
			if hit != null and origin.distance_to(hit) <= reach and (closest == null or origin.distance_squared_to(hit) < origin.distance_squared_to(closest)):
				closest = hit
		if terrain.lake_distance(cell) < 1.8 and absf(direction.y) > 0.0000001:
			var level: float = terrain.pond_at(cell).level
			var travel := (level - origin.y) / direction.y
			var water_hit := origin + direction * travel
			var point := Vector2(water_hit.x, water_hit.z)
			if travel >= 0 and travel <= reach and Vector2i(point.floor()) == cell and terrain.surface_height(point) <= level and (closest == null or origin.distance_squared_to(water_hit) < origin.distance_squared_to(closest)):
				closest = water_hit
		if closest != null:
			return closest
		if minf(next_x, next_z) > reach:
			break
		if next_x < next_z:
			cell.x += step_x
			next_x += delta_x
		else:
			cell.y += step_z
			next_z += delta_z
	return null
