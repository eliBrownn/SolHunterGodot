class_name NatureComposition
extends Resource
## Sample-only cosmetic rules. Generation, territories and individuals remain authoritative.
@export var world_seed := 2601026
@export var patches: Array[NaturePatch] = []
## Existing sign geometry marks the optional pond excursion. Rebuild/restart to apply.
@export var orientation_marker := Vector2i(28, 16)

const RequiredSpaces = preload("res://resources/scenery/required_spaces.tres")

func valid() -> bool:
	if world_seed < 0 or world_seed > 2147483646 or patches.is_empty() or patches.size() > 3:
		return false
	for i in range(patches.size()):
		if patches[i] == null or not patches[i].valid():
			return false
		for j in range(i):
			if patches[i].bounds.intersects(patches[j].bounds) or patches[i].patch_id == patches[j].patch_id:
				return false
	return true

func patch_at(terrain: WorldTerrain, cell: Vector2i) -> NaturePatch:
	if terrain.world_seed != world_seed:
		return null
	for patch in patches:
		if patch.bounds.has_point(cell):
			return patch
	return null

func placement(terrain: WorldTerrain, cell: Vector2i, patch: NaturePatch) -> Dictionary:
	var data := terrain.sample(cell)
	if not data.ground in patch.habitats or data.obstacle != 0:
		return {}
	# Independent cosmetic salts; no dependence on chunk visitation or mutable state.
	var cluster := Vector2i(WorldTerrain.floor_div(cell.x, 3), WorldTerrain.floor_div(cell.y, 3))
	if terrain.roll(cluster, 83109) % 100 >= 68 or terrain.roll(cell, 83111) % 100 >= patch.density_percent:
		return {}
	var roll := terrain.roll(cell, 83113)
	var entry: NatureAssetEntry = patch.entries[roll % patch.entries.size()]
	var model := entry.admitted_model()
	if model.is_empty():
		return {}
	var water: bool = data.ground == WorldTerrain.Ground.WATER
	if water != (entry.surface == NatureAssetEntry.Surface.WATER):
		return {}
	if not water and not data.walkable:
		return {}
	if entry.surface == NatureAssetEntry.Surface.BANK:
		var adjacent := false
		for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			adjacent = adjacent or terrain.natural_ground(cell + offset) == WorldTerrain.Ground.WATER
		if not adjacent:
			return {}
	var point := Vector2(cell) + Vector2(0.5, 0.5)
	var yaw := float(roll % 6283) / 1000.0
	var basis := Basis(Vector3.UP, yaw).scaled(Vector3.ONE * entry.uniform_scale)
	var box: AABB = model.bounds
	var height: float = terrain.pond_at(cell).level + 0.012 if water else terrain.surface_height(point) - 0.015
	var transform := Transform3D(basis, Vector3(point.x, height, point.y))
	transform.origin -= basis * Vector3(box.get_center().x, box.position.y, box.get_center().z)
	var visual: AABB = transform * box
	if maxf(visual.size.x, visual.size.z) > entry.maximum_width:
		return {}
	var rect := Rect2(Vector2(visual.position.x, visual.position.z), Vector2(visual.size.x, visual.size.z)).grow(0.08)
	var owner := Rect2(Vector2(terrain.chunk_of(cell) * 16), Vector2(16, 16))
	if not owner.encloses(rect) or not Rect2(patch.bounds).encloses(rect):
		return {}
	# Entire transformed footprint, not the anchor: protect routes, places,
	# blockers and stable encounter clearings, including across neighboring cells.
	for y in range(floori(rect.position.y), ceili(rect.end.y)):
		for x in range(floori(rect.position.x), ceili(rect.end.x)):
			var at := Vector2i(x, y)
			if terrain.scenery_reserved(at) or terrain.route_axes(at, 1) != 0 or terrain.is_camp(at) or terrain.is_landmark(at) or terrain.cabin_footprint.grow(1).has_point(at):
				return {}
			for clearing in RequiredSpaces.anchors_for(patch.patch_id):
				if maxi(absi(at.x - clearing.x), absi(at.y - clearing.y)) <= SceneryRequiredSpaces.RADIUS:
					return {}
			var sample := terrain.sample(at)
			if sample.obstacle != 0 or (sample.ground == WorldTerrain.Ground.WATER) != water:
				return {}
			if water and not is_equal_approx(terrain.pond_at(at).level, height - 0.012):
				return {}
	if not water:
		for corner in [rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y), point]:
			if terrain.surface_normal(corner).angle_to(Vector3.UP) > deg_to_rad(entry.maximum_slope) or absf(terrain.surface_height(corner) - (height + 0.015)) > 0.12:
				return {}
	else:
		for corner in [rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y), point]:
			if terrain.surface_height(corner) > height - 0.025:
				return {}
	return {"asset": entry.scene.resource_path, "cell": cell, "transform": transform, "bounds": visual, "surface": entry.surface, "patch": patch.patch_id, "model": model}
