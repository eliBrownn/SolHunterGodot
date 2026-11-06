extends RefCounted
## Worker-safe canopy sampling on the same triangles as the visible terrain rings.

const Plan := preload("res://scripts/world/world_map_plan.gd")
const Surface := preload("res://scripts/world/world_map_surface.gd")
const Plants := preload("res://scripts/presentation/map_vegetation.gd")
const Community := preload("res://scripts/world/plant_community.gd")
const SPACING := [16, 16, 24, 32, 48, 64, 96, 128]


static func sample_strip(plan: Plan, surface: Surface, canopy: Community, settings: Dictionary,
		anchor: Vector2i, strip: Rect2i, step: int, ring: int, vertices: PackedVector3Array) -> Dictionary:
	var groups := {}
	var spacing: int = SPACING[ring]
	var bounds := Rect2i(anchor + strip.position, strip.size)
	var first := Vector2i((Vector2(bounds.position) / spacing).floor()) * spacing
	var width := strip.size.x / step + 1
	var depth := strip.size.y / step + 1
	for z in range(first.y, bounds.end.y, spacing):
		for x in range(first.x, bounds.end.x, spacing):
			var cell := Vector2i(x, z)
			var jitter := Vector2(canopy.roll(cell, 17), canopy.roll(cell, 31))
			var point := Vector2(cell) + (Vector2.ONE * 0.22 + jitter * 0.56) * spacing
			if not Rect2(bounds).has_point(point):
				continue
			var ground := plan.sample_world_cell(Vector2i(point.floor()))
			var candidates: PackedFloat32Array = settings.weights.get(ground.biome, PackedFloat32Array())
			if candidates.is_empty():
				continue
			var profile: Vector3 = Plants.HABITATS[ground.biome]
			var grove := smoothstep(0.30, 0.72, canopy.patch_at(cell))
			var density: float = profile.z * lerpf(0.30, 1.5, grove) * lerpf(0.65, 1.25, ground.soil_moisture)
			if canopy.roll(cell, 52) >= density * settings.coverage or not surface.planting_ground(point):
				continue
			var grid := (point - Vector2(bounds.position)) / step
			var tile := Vector2i(grid.floor())
			if tile.x + 1 >= width or tile.y + 1 >= depth:
				continue
			var index := tile.y * width + tile.x
			var height := TerrainHeightfield.interpolate(Vector4(vertices[index].y, vertices[index + 1].y,
				vertices[index + width + 1].y, vertices[index + width].y), grid - Vector2(tile))
			var kind := Plants.Plant.TREE_BASE + _choose_species(candidates, canopy.roll(cell, 101))
			var breadth := maxf(1.0, float(spacing) / 16.0)
			var size: float = settings.scale * lerpf(0.78, 1.16, canopy.roll(cell, 79))
			var basis := Basis(Vector3.UP, canopy.roll(cell, 85) * TAU).scaled(Vector3(breadth, 1.0, breadth) * size)
			var local := point - Vector2(anchor)
			var records: Array = groups.get(kind, [])
			records.append({"transform": Transform3D(basis, Vector3(local.x, height, local.y)),
				"color": Color.WHITE, "hue": Plants.tree_hue(ground.biome)})
			groups[kind] = records
	return groups


static func _choose_species(weights: PackedFloat32Array, fraction: float) -> int:
	var roll := fraction * weights[weights.size() - 1]
	for index in range(0, weights.size() - 1, 2):
		if roll < weights[index + 1]:
			return int(weights[index])
	return int(weights[weights.size() - 2])
