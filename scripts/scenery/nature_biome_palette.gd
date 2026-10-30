class_name NatureBiomePalette
extends Resource
## Visual interpretation of an existing generated habitat. Never changes ecology or collision cells.

@export_enum("Meadow", "Woodland", "Heath", "Marsh") var ground := 0
## Blocking trees retain generated anchors; this palette changes their appearance.
@export var trees: Array[PackedScene] = []
## Tree height multiplier relative to the shared Nature Settings height. Rebuild to apply.
@export_range(0.5, 1.3, 0.05) var tree_height_scale := 1.0
## Subtle multiplier over the existing continuous climate tint. Rebuild to apply.
@export var ground_tint := Color.WHITE
## Multiply cloned tree/plant materials; source models and individual affinity stay unchanged.
@export var tree_tint := Color.WHITE
@export var detail_tint := Color.WHITE
## Independent per-tree height variation around the habitat's shared scale.
@export_range(0.0, 0.45, 0.05) var scale_variation := 0.3
## Shared regional size variation inherited by local groves, before individual variation.
@export_range(0.0, 0.2, 0.02) var regional_scale_variation := 0.1
## Coherent cosmetic grove/ground-cover patch width in world cells.
@export_range(3, 12, 1) var cluster_cells := 6
## Percent of cosmetic clusters admitted before individual plant density.
@export_range(30, 90, 1) var cluster_fill := 68
## Admitted cosmetic plants, with uniform scale and shared footprint/slope checks.
@export var details: Array[NatureAssetEntry] = []
## Cosmetic placement chance within stable clusters. Never adds blocking cells.
@export_range(0, 40, 1) var density_percent := 24

func valid() -> bool:
	if ground not in [0, 1, 2, 3] or trees.is_empty() or trees.size() > 8 or trees.has(null) or details.is_empty() or details.size() > 8:
		return false
	if not is_finite(tree_height_scale) or tree_height_scale < 0.5 or tree_height_scale > 1.3 or density_percent < 0 or density_percent > 40:
		return false
	if not is_finite(scale_variation) or scale_variation < 0 or scale_variation > 0.45 or cluster_cells < 3 or cluster_cells > 12 or cluster_fill < 30 or cluster_fill > 90:
		return false
	if not is_finite(regional_scale_variation) or regional_scale_variation < 0 or regional_scale_variation > 0.2:
		return false
	for tint in [ground_tint, tree_tint, detail_tint]:
		if not tint.is_equal_approx(tint.clamp()) or tint.a != 1:
			return false
		for channel in [tint.r, tint.g, tint.b]:
			if not is_finite(channel):
				return false
	for entry in details:
		if entry == null or not entry.valid():
			return false
	return true

func detail_patch(terrain: WorldTerrain, coord: Vector2i) -> NaturePatch:
	var patch := NaturePatch.new()
	patch.patch_id = ["meadow", "woodland", "heath", "marsh"][ground]
	var region_size: int = terrain.geography.REGION
	var region := Vector2i(WorldTerrain.floor_div(coord.x * 16, region_size), WorldTerrain.floor_div(coord.y * 16, region_size))
	patch.bounds = Rect2i(region * region_size, Vector2i(region_size, region_size))
	patch.habitats.assign([ground])
	patch.entries = details
	patch.density_percent = density_percent
	return patch

func tree_scale_at(terrain: WorldTerrain, cell: Vector2i) -> float:
	var region: Vector2i = terrain.geography.region(Vector2(cell))
	var grove := Vector2i(WorldTerrain.floor_div(cell.x, cluster_cells * 2), WorldTerrain.floor_div(cell.y, cluster_cells * 2))
	var regional := lerpf(1.0 - regional_scale_variation, 1.0 + regional_scale_variation, float(terrain.roll(region, 83121) % 1001) / 1000.0)
	var variation := float(terrain.roll(grove, 83119) % 1001) / 1000.0 * 0.7 + float(terrain.roll(cell, 83123) % 1001) / 1000.0 * 0.3
	return regional * lerpf(1.0 - scale_variation, 1.0 + scale_variation, variation)
