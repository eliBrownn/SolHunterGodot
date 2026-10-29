extends RefCounted
## Bounded authored-site reservation. Rendering and traversal share this footprint.

const CABIN_SIZE := Vector2i(3, 3)
const PREFERRED_ORIGIN := Vector2i(-4, -7)

## Resolve the existing authored cabin once. Views consume this layout verbatim.
static func cabin_layout(terrain: RefCounted) -> Dictionary:
	var footprint: Rect2i = terrain.cabin_footprint
	if not footprint.has_area():
		return {"admitted": false}
	var center := Vector2(footprint.position) + Vector2(footprint.size) * 0.5
	var origin := Vector3(center.x, terrain.surface_height(center), center.y)
	var width := float(footprint.size.x)
	var depth := float(footprint.size.y)
	var id := "%d/site/cabin" % terrain.world_seed
	var modules := [
		["foundation", "prop", Vector3(0, 0.12, 0), Vector3(width, 0.24, depth), Color("777d76")],
		["walls", "wall", Vector3(0, 1.04, 0), Vector3(width - 0.2, 1.60, depth - 0.2), Color.WHITE],
		["roof", "roof", Vector3(0, 2.27, 0), Vector3(width + 0.3, 0.86, depth + 0.3), Color("665a4f")],
		["door", "prop", Vector3(0, 0.86, depth * 0.5 - 0.085), Vector3(0.64, 1.24, 0.05), Color("594431")],
		["window_west", "prop", Vector3(-0.94, 1.13, depth * 0.5 - 0.075), Vector3(0.48, 0.44, 0.06), Color("d1bb81")],
		["window_east", "prop", Vector3(0.94, 1.13, depth * 0.5 - 0.075), Vector3(0.48, 0.44, 0.06), Color("d1bb81")],
	]
	var elements: Array[Dictionary] = []
	for module in modules:
		elements.append(ScenerySiteTemplate.element(id + "/building/" + module[0], id + "/building", module[1], origin + module[2], module[3], module[4]))
	return {"admitted": true, "id": id, "subject": "Cabin", "footprint": footprint, "reservation": footprint.grow(1), "elements": elements}

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
