class_name NatureSettings
extends Resource
## Cosmetic biome palettes; never changes generated cells, collision, IDs or saves.

## Optional seed-specific, bounded scenery study. Null retains the current global art.
## Restart/rebuild applies; loaded expeditions keep gameplay state and generation.
@export var composition: NatureComposition

## Forest and meadow tree variants. Applied when chunks are rebuilt.
@export var common_trees: Array[PackedScene] = [preload("res://assets/nature/CommonTree_1.gltf"), preload("res://assets/nature/CommonTree_2.gltf"), preload("res://assets/nature/Pine_1.gltf"), preload("res://assets/nature/Pine_2.gltf")]
## Heath and marsh tree variants. Applied when chunks are rebuilt.
@export var hardy_trees: Array[PackedScene] = [preload("res://assets/biome_placeholders/dry_tree.tscn"), preload("res://assets/nature/DeadTree_1.gltf")]
## Existing rock obstacles select deterministically from this palette.
@export var rocks: Array[PackedScene] = [preload("res://assets/nature/Rock_Medium_1.gltf"), preload("res://assets/nature/Rock_Medium_2.gltf"), preload("res://assets/nature/Rock_Medium_3.gltf")]
## Nonblocking decoration on existing free ground, outside routes and authored places.
@export var undergrowth: Array[PackedScene] = [preload("res://assets/nature/Bush_Common.gltf"), preload("res://assets/nature/Bush_Common_Flowers.gltf"), preload("res://assets/nature/Grass_Common_Short.gltf"), preload("res://assets/nature/Fern_1.gltf"), preload("res://assets/nature/Mushroom_Common.gltf")]
## Approximate tree height in world cells before per-cell size variation.
@export_range(2.0, 7.0, 0.25) var tree_height := 3.5
## Rock obstacle height in world cells before per-cell variation.
@export_range(0.3, 1.2, 0.05) var rock_height := 0.65
## Nonblocking decoration height in world cells.
@export_range(0.1, 0.8, 0.05) var undergrowth_height := 0.35
## Percent of otherwise free, non-route cells decorated. Visual only; restart/rebuild to apply.
@export_range(0, 40, 1) var undergrowth_percent := 12

func valid() -> bool:
	if composition != null and not composition.valid():
		return false
	for palette in [common_trees, hardy_trees, rocks, undergrowth]:
		if palette.is_empty() or palette.size() > 16 or palette.has(null):
			return false
	return is_finite(tree_height) and tree_height >= 2 and tree_height <= 7 and is_finite(rock_height) and rock_height >= 0.3 and rock_height <= 1.2 and is_finite(undergrowth_height) and undergrowth_height >= 0.1 and undergrowth_height <= 0.8 and undergrowth_percent >= 0 and undergrowth_percent <= 40
