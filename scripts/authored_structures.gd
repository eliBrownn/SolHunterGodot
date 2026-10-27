extends RefCounted
## Bounded authored-site reservation. Rendering and traversal share this footprint.

const CABIN_SIZE := Vector2i(3, 3)
const PREFERRED_ORIGIN := Vector2i(-4, -7)

static func cabin_site(terrain: RefCounted) -> Rect2i:
	for radius in range(25):
		for y in range(-radius, radius + 1):
			for x in range(-radius, radius + 1):
				var distance_squared := x * x + y * y
				if distance_squared > radius * radius or (radius > 0 and distance_squared <= (radius - 1) * (radius - 1)):
					continue
				var footprint := Rect2i(PREFERRED_ORIGIN + Vector2i(x, y), CABIN_SIZE)
				if site_is_clear(terrain, footprint):
					return footprint
	# Omit an impossible site rather than block water, spawn or an essential route.
	return Rect2i()

static func site_is_clear(terrain: RefCounted, footprint: Rect2i) -> bool:
	var clearance := footprint.grow(1)
	for y in range(clearance.position.y, clearance.end.y):
		for x in range(clearance.position.x, clearance.end.x):
			var cell := Vector2i(x, y)
			if cell == Vector2i.ZERO or terrain.route_axes(cell, 2) != 0:
				return false
			if terrain.natural_ground(cell) == WorldTerrain.Ground.WATER:
				return false
	return true
