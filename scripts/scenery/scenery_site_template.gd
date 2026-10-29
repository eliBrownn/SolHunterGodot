class_name ScenerySiteTemplate
extends Resource
## Small open woodland shelter. No settlement, reward or encounter semantics.
## Layout defaults are generation-versioned; captured parameters reconstruct loads.

## Stable authored key. Changing this or layout parameters requires a new expedition.
@export var site_key := "woodland_shelter"
## Search center in absolute world cells, independent of render chunks.
@export var preferred_x := 32
## Maximum candidate origins to inspect, in cells along the existing approach.
@export_range(1, 48) var search_candidates := 24
## Shared admitted module budget for the entire site, including optional trim.
@export_range(5, 16) var element_budget := 8
## Cosmetic optional roof trim. Does not affect identity, reservations or blockers.
var roof_trim := true

func parameters() -> Dictionary:
	return {"site_key": site_key, "preferred_x": preferred_x, "search_candidates": search_candidates, "element_budget": element_budget}

static func valid_parameters(value: Variant) -> bool:
	return value is Dictionary and value.size() == 4 and value.get("site_key") == "woodland_shelter" and SolSpeciesDefinition.whole(value.get("preferred_x"), -1000000, 1000000) and SolSpeciesDefinition.whole(value.get("search_candidates"), 1, 48) and SolSpeciesDefinition.whole(value.get("element_budget"), 5, 16)

func valid() -> bool:
	return valid_parameters(parameters())

func plan(terrain: WorldTerrain) -> Dictionary:
	if not valid():
		return {"admitted": false, "reason": "invalid_definition", "attempts": 0}
	var reasons: Dictionary = {}
	for index in range(search_candidates):
		# Stable site-purpose salt; detail never consumes this search sequence.
		var shift := int((index + 1) / 2) * (1 if index % 2 else -1)
		var x := preferred_x + shift
		var anchor := Vector2i(x, terrain.trail_y(x) + 10)
		var footprint := Rect2i(anchor - Vector2i(2, 0), Vector2i(5, 5))
		var approach := Rect2i(Vector2i(x - 1, terrain.trail_y(x)), Vector2i(3, 10))
		var reason := rejection(terrain, footprint, approach)
		if not reason.is_empty():
			reasons[reason] = int(reasons.get(reason, 0)) + 1
			continue
		return assemble(terrain, footprint, approach, index + 1, reasons)
	return {"admitted": false, "reason": "no_suitable_site", "attempts": search_candidates, "rejections": reasons}

func rejection(terrain: WorldTerrain, footprint: Rect2i, approach: Rect2i) -> String:
	if footprint.grow(1).intersects(terrain.cabin_footprint.grow(1)):
		return "reserved_site"
	var low := INF
	var high := -INF
	var woodland := false
	for y in range(footprint.position.y - 1, footprint.end.y + 1):
		for x in range(footprint.position.x - 1, footprint.end.x + 1):
			var at := Vector2i(x, y)
			if terrain.is_camp(at) or terrain.is_landmark(at) or terrain.route_axes(at, 1) != 0:
				return "required_access"
			if terrain.natural_ground(at) == WorldTerrain.Ground.WATER or not terrain.slope_fits(at):
				return "ground_or_obstacle"
			woodland = woodland or terrain.natural_ground(at) == WorldTerrain.Ground.FOREST
			var height := terrain.surface_height(Vector2(at) + Vector2(0.5, 0.5))
			low = minf(low, height)
			high = maxf(high, height)
	if not woodland:
		return "not_woodland"
	if high - low > 0.5:
		return "foundation_grade"
	for y in range(approach.position.y, approach.end.y):
		for x in range(approach.position.x, approach.end.x):
			var at := Vector2i(x, y)
			if terrain.is_camp(at) or terrain.is_landmark(at) or terrain.cabin_footprint.has_point(at) or terrain.natural_ground(at) == WorldTerrain.Ground.WATER or not terrain.slope_fits(at):
				return "approach_blocked"
	return ""

func assemble(terrain: WorldTerrain, footprint: Rect2i, approach: Rect2i, attempts: int, reasons: Dictionary) -> Dictionary:
	var id := "%d/site/%s" % [terrain.world_seed, site_key]
	var parent := "%d/region/%d,%d" % [terrain.world_seed, WorldTerrain.floor_div(footprint.position.x, 128), WorldTerrain.floor_div(footprint.position.y, 128)]
	var posts: Array[Vector2i] = [footprint.position, footprint.position + Vector2i(4, 0), footprint.position + Vector2i(0, 4), footprint.position + Vector2i(4, 4)]
	var top := -INF
	for cell in posts:
		top = maxf(top, terrain.surface_height(Vector2(cell) + Vector2(0.5, 0.5)) + 2.2)
	var elements: Array[Dictionary] = []
	for i in range(posts.size()):
		var at := Vector2(posts[i]) + Vector2(0.5, 0.5)
		var ground := terrain.surface_height(at)
		elements.append(element(id + "/building/post_%d" % i, id + "/building", "post", Vector3(at.x, (ground + top) * 0.5, at.y), Vector3(0.3, top - ground, 0.3), Color("72523b")))
	var center := Vector2(footprint.position) + Vector2(footprint.size) * 0.5
	elements.append(element(id + "/building/roof", id + "/building", "roof", Vector3(center.x, top + 0.35, center.y), Vector3(5.0, 0.7, 5.0), Color("665a4f")))
	# Preference yields to the shared parent budget. Hard access never yields.
	if roof_trim and elements.size() < element_budget:
		elements.append(element(id + "/building/trim", id + "/building/roof", "prop", Vector3(center.x, top, center.y - 2.35), Vector3(4.8, 0.12, 0.12), Color("a88458")))
	return {"admitted": true, "id": id, "parent_id": parent, "definition": parameters(), "generation_version": terrain.generation_version, "footprint": footprint, "reservation": footprint.grow(1), "approach": approach, "blockers": posts, "elements": elements, "budget_used": elements.size(), "attempts": attempts, "rejections": reasons}

static func element(id: String, parent: String, kind: String, position: Vector3, size: Vector3, color: Color) -> Dictionary:
	var transform := Transform3D(Basis.from_scale(size), position)
	return {"id": id, "parent_id": parent, "kind": kind, "transform": transform, "bounds": transform * AABB(-Vector3.ONE * 0.5, Vector3.ONE), "color": color}
