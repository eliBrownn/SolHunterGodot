class_name NatureSettings
extends Resource
## Cosmetic biome palettes; never changes generated cells, collision, IDs or saves.

## Optional seed-specific, bounded scenery study. Null retains the current global art.
## Restart/rebuild applies; loaded expeditions keep gameplay state and generation.
@export var composition: NatureComposition

## Per-habitat scenery for every seed. Empty retains the original shared palettes.
## Restart/rebuild applies to loaded worlds too; generated habitat and saves stay authoritative.
@export var biomes: Array[NatureBiomePalette] = []
## Blend neighboring habitat colors at boundaries; zero keeps each palette's full tint.
@export_range(0.0, 1.0, 0.05) var biome_edge_blend := 0.5
## Base turf color beneath foliage. Rebuild/restart applies to all loaded terrain.
@export var ground_base_color := Color(0.48, 0.57, 0.34, 1.0)
## Original ground texture contrast; zero gives smooth turf. Rebuild/restart applies.
@export_range(0.0, 1.0, 0.05) var ground_texture_strength := 0.15

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
@export_group("Continuous meadow")
## Nonblocking grass on free meadow/woodland ground. Restart/rebuild applies to loaded worlds too.
@export var meadow_enabled := false
## Clumps per cell edge (2 to 4); chunk batching and existing detail distance bound rendering.
@export_range(2, 4, 1) var meadow_divisions := 3
## Blade height in world cells before gentle visual variation. Restart/rebuild to apply.
@export_range(0.15, 0.65, 0.01) var meadow_height := 0.32

func valid() -> bool:
	if not is_finite(ground_texture_strength) or ground_texture_strength < 0.0 or ground_texture_strength > 1.0:
		return false
	for channel in [ground_base_color.r, ground_base_color.g, ground_base_color.b, ground_base_color.a]:
		if not is_finite(channel) or channel < 0.0 or channel > 1.0: return false
	if meadow_divisions < 2 or meadow_divisions > 4 or not is_finite(meadow_height) or meadow_height < 0.15 or meadow_height > 0.65:
		return false
	if not is_finite(biome_edge_blend) or biome_edge_blend < 0 or biome_edge_blend > 1:
		return false
	if composition != null and not composition.valid():
		return false
	var grounds := {}
	for biome in biomes:
		if biome == null or not biome.valid() or grounds.has(biome.ground):
			return false
		grounds[biome.ground] = true
	for palette in [common_trees, hardy_trees, rocks, undergrowth]:
		if palette.is_empty() or palette.size() > 16 or palette.has(null):
			return false
	return is_finite(tree_height) and tree_height >= 2 and tree_height <= 7 and is_finite(rock_height) and rock_height >= 0.3 and rock_height <= 1.2 and is_finite(undergrowth_height) and undergrowth_height >= 0.1 and undergrowth_height <= 0.8 and undergrowth_percent >= 0 and undergrowth_percent <= 40

func canopy_height_bound() -> float:
	var bound := tree_height * 1.15
	for biome in biomes:
		bound = maxf(bound, tree_height * biome.tree_height_scale * (1.0 + biome.scale_variation) * (1.0 + biome.regional_scale_variation))
	return bound

func biome_for(ground: int) -> NatureBiomePalette:
	for biome in biomes:
		if biome.ground == ground:
			return biome
	return null

func ground_tint_at(terrain: WorldTerrain, cell: Vector2i) -> Color:
	var biome := biome_for(terrain.natural_ground(cell))
	var base := biome.ground_tint if biome != null else Color.WHITE
	var neighbors := Color(0, 0, 0, 0)
	for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		var adjacent := biome_for(terrain.natural_ground(cell + offset))
		neighbors += adjacent.ground_tint if adjacent != null else base
	return base.lerp(neighbors / 4.0, biome_edge_blend)
