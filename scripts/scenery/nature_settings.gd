class_name NatureSettings
extends Resource
const MeadowStyle = preload("res://scripts/scenery/meadow_appearance.gd")
## Cosmetic biome palettes; never changes generated cells, collision, IDs or saves.

## Optional seed-specific, bounded scenery study. Null retains the current global art.
## Restart/rebuild applies; loaded expeditions keep gameplay state and generation.
@export var composition: NatureComposition

## Per-habitat scenery for every seed. Empty retains the original shared palettes.
## Restart/rebuild applies to loaded worlds too; generated habitat and saves stay authoritative.
@export var biomes: Array[NatureBiomePalette] = []
## Blend neighboring habitat colors at boundaries; zero keeps each palette's full tint.
@export_range(0.0, 1.0, 0.05) var biome_edge_blend := 1.0
## Radius in cells for the weighted neighboring biome tint. Rebuild/restart;
## presentation only, including loaded worlds. Larger values widen the transition.
@export_range(1,8,1) var biome_blend_cells := 4
## Base turf color beneath foliage. Rebuild/restart applies to all loaded terrain.
@export var ground_base_color := Color(0.48, 0.57, 0.34, 1.0)
## Per-cell procedural plant size variation (fraction); 0 keeps exact palette sizes.
## Rebuild/restart applies. Authored designs and canonical flora/reserves are unchanged.
@export_range(0.0, 0.25, 0.01) var plant_instance_variation := 0.22
## Visual foliage patches and leaf-grass clump density on existing emanator cells.
## Grass density varies smoothly across cells; zero disables the bodies only.
## Rebuild/restart applies to loaded worlds. Membership and saved reserves are unchanged.
@export_range(0.0,1.0,0.05) var foliage_coverage := 0.65
## World foliage body scale, applied before path/terrain fitting. Rebuild/restart; grass blade heights retain their own controls.
@export_range(0.5,3.0,0.1) var foliage_size_multiplier := 2.0
@export_group("Plant reserve appearance")
## Fraction of authored saturation retained at empty reserve. Full reserve retains authored colors. Reapply/restart; no damage state is changed.
@export_range(0.0,1.0,0.05) var reserve_saturation_floor := 0.35
## Downward displacement of free leaf tips at empty reserve, in model units. Zero disables droop. Reapply/restart.
@export_range(0.0,0.6,0.02) var reserve_droop := 0.30
## Seconds to blend reserve posture and pigment, using the saved active clock. Reapply/restart.
@export_range(0.1,3.0,0.1) var reserve_transition_seconds := 1.2
@export_group("Leaf grass")
## Above-ground blade height ranges in cells. Smooth patch variation blends short, medium and tall ranges. Restart/rebuild; presentation only.
@export var grass_short_height := Vector2(0.08, 0.16)
@export var grass_medium_height := Vector2(0.16, 0.30)
@export var grass_tall_height := Vector2(0.30, 0.48)
## Approximate width of coherent height patches, in cells. Restart/rebuild.
@export_range(4.0, 48.0, 1.0) var grass_patch_cells := 16.0
## Minimum clearance around solid stems/exposed roots, in cells. Canopies do not exclude grass. Restart/rebuild.
@export_range(0.02, 0.3, 0.01) var grass_base_clearance := 0.10
## Strength of inexpensive ground-level grass texture as individual clumps fade. Zero disables this visual layer. Restart/rebuild.
@export_range(0.0, 1.0, 0.05) var grass_ground_strength := 0.35
@export_group("")
## Original ground texture contrast; zero gives smooth turf. Rebuild/restart applies.
@export_range(0.0, 1.0, 0.05) var ground_texture_strength := 0.15

@export_group("Terrain materials")
## Shared 512px grass/earth/rock layers. Rebuild/restart applies to loaded worlds.
@export var terrain_palette: Texture2DArray = preload("res://resources/terrain_palette.res")
## Optional OpenGL normal layers. Unassigned by default; assign 13 layers before enabling depth.
@export var terrain_normals: Texture2DArray
## Optional parallax layers. Unassigned by default; assign 13 layers before enabling relief.
@export var terrain_heights: Texture2DArray
## Apparent surface depth as a fraction of texture repeat; zero disables parallax.
## Rebuild/restart applies; physical ground height and collision stay unchanged.
@export_range(0.0, 0.1, 0.005) var terrain_relief_depth := 0.0
## Fade depth-map work over the last 40% of this camera distance. Zero keeps full detail.
@export_range(0.0, 128.0, 4.0) var terrain_relief_distance := 56.0
## Fade normal-map work over the last 40% of this distance. Zero keeps full detail.
@export_range(0.0, 128.0, 4.0) var terrain_normal_distance := 88.0
## Enable the licensed geography materials; disabled restores the original turf.
@export var terrain_palette_enabled := true
## Surface repeat size in world cells. Rebuild/restart applies.
@export_range(1.0, 16.0, 0.5) var terrain_tile_size := 4.0
## Material color blended into the existing biome palette. Rebuild/restart applies.
@export_range(0.0, 1.0, 0.05) var terrain_color_strength := 0.45
## Restrained surface color contrast. Rebuild/restart applies.
@export_range(0.0, 1.0, 0.05) var terrain_detail_strength := 0.35
## Light-responsive texture relief; zero gives flat shading. Rebuild/restart applies.
## Uses the supplied normal maps in the existing geographic material coordinates.
@export_range(0.0, 1.0, 0.05) var terrain_depth_strength := 0.0
## Shared softness for all terrain material transitions. Rebuild/restart applies.
@export_range(0.0,1.0,0.05) var terrain_blend_softness := 1.0
## Geographic edge breakup, shared across tiles and render distances.
@export_range(0.0,0.4,0.02) var terrain_blend_detail := 0.18
## Supplied Ground019 trail color/detail share. Normals and relief use its matching maps.
@export_range(0.0,1.0,0.05) var trail_texture_strength := 0.85
## Slope angle where supplied rock textures begin replacing turf/soil. Rebuild/restart applies.
@export_range(0.0, 88.0, 1.0) var terrain_cliff_start_degrees := 32.0
## Slope angle with full exposed rock; must exceed the start angle. Rebuild/restart applies.
@export_range(1.0, 89.0, 1.0) var terrain_cliff_full_degrees := 52.0
@export_group("")

static var _weight_source: WeakRef
static var _vertex_weights: Dictionary = {}
static var _weight_window := preload("res://scripts/core/derived_cache_window.gd").new(32768)

## Disposable material samples shared by adjacent faces, skirts and both LODs.
## Weak ownership releases old expeditions; bounded eviction only recomputes values.
static func terrain_vertex_weights(terrain: WorldTerrain, vertex: Vector2i) -> Vector3:
	if OS.get_thread_caller_id() != OS.get_main_thread_id():
		if terrain._material_vertex_weights.has(vertex): return terrain._material_vertex_weights[vertex]
		var owned_result := calculate_vertex_weights(terrain,vertex)
		terrain._material_weight_window.store(terrain._material_vertex_weights,vertex,owned_result)
		return owned_result
	if _weight_source == null or _weight_source.get_ref() != terrain:
		_weight_source = weakref(terrain)
		_vertex_weights.clear()
	if _vertex_weights.has(vertex): return _vertex_weights[vertex]
	var result := calculate_vertex_weights(terrain,vertex)
	_weight_window.store(_vertex_weights,vertex,result)
	return result

static func calculate_vertex_weights(terrain: WorldTerrain, vertex: Vector2i) -> Vector3:
	var path := 0.0
	var soil := 0.0
	var core := 0.0
	for offset in [Vector2i.ZERO, Vector2i.LEFT, Vector2i.UP, Vector2i(-1, -1)]:
		var at: Vector2i = vertex + offset
		soil += float([0.0, 0.65, 0.55, 0.5, 1.0, 1.0][terrain.natural_ground(at)]) * 0.25
		var weight := 0.0
		# Review terrains may provide authored sample masks; preserve those overrides.
		var visible_trail: bool = terrain.trail_visible_at(at) if terrain.get_script() == WorldTerrain else terrain.sample(at).trail_visible
		if visible_trail:
			weight = 1.0
			core += 0.25
		elif terrain.route_axes(at, -1) != 0: weight = 0.7
		elif terrain.route_axes(at) != 0: weight = 0.35
		elif terrain.route_axes(at, 1) != 0: weight = 0.08
		path += weight * 0.25
	var result := Vector3(path, soil, maxf(soil, core))
	return result

## Vertex weights shared by neighboring tiles and both terrain render distances.
static func terrain_soil_at(terrain: WorldTerrain, vertex: Vector2i) -> float:
	return terrain_vertex_weights(terrain, vertex).z

## Separate continuous path and habitat-soil weights at an absolute shared vertex.
## Shoulders bridge the protected road corridor into surrounding turf, never add flora.
static func terrain_blend_at(terrain: WorldTerrain, vertex: Vector2i) -> PackedFloat32Array:
	var weights := terrain_vertex_weights(terrain, vertex)
	var woodland := 0.0
	for offset in [Vector2i.ZERO,Vector2i.LEFT,Vector2i.UP,Vector2i(-1,-1)]:
		if terrain.natural_ground(vertex+offset)==WorldTerrain.Ground.FOREST: woodland+=0.25
	return PackedFloat32Array([weights.x, weights.y, woodland])

func apply_terrain_material(target: ShaderMaterial) -> void:
	preload("res://scripts/presentation/ground_reserve_view.gd").register(target)
	target.set_shader_parameter("grass_ground_strength", grass_ground_strength if meadow_enabled else 0.0)
	target.set_shader_parameter("terrain_blend_softness",terrain_blend_softness)
	target.set_shader_parameter("terrain_blend_detail",terrain_blend_detail)
	target.set_shader_parameter("trail_texture_strength",trail_texture_strength)
	target.set_shader_parameter("terrain_cliff_start_degrees",terrain_cliff_start_degrees)
	target.set_shader_parameter("terrain_cliff_full_degrees",terrain_cliff_full_degrees)
	target.set_shader_parameter("terrain_palette", terrain_palette)
	target.set_shader_parameter("terrain_normals", terrain_normals)
	target.set_shader_parameter("terrain_heights", terrain_heights)
	target.set_shader_parameter("terrain_relief_depth", terrain_relief_depth if terrain_heights != null else 0.0)
	target.set_shader_parameter("terrain_relief_distance", terrain_relief_distance)
	target.set_shader_parameter("terrain_normal_distance", terrain_normal_distance)
	target.set_shader_parameter("terrain_palette_enabled", terrain_palette_enabled)
	target.set_shader_parameter("terrain_tile_size", terrain_tile_size)
	target.set_shader_parameter("terrain_color_strength", terrain_color_strength)
	target.set_shader_parameter("terrain_detail_strength", terrain_detail_strength)
	target.set_shader_parameter("terrain_depth_strength", terrain_depth_strength if terrain_normals != null else 0.0)
	target.set_shader_parameter("terrain_region_size", float(preload("res://scripts/world/terrain_geography.gd").REGION))

func apply_plant_material(target: ShaderMaterial) -> void:
	if target.shader == null or target.shader.resource_path not in ["res://shaders/procedural_plant_foliage.gdshader","res://shaders/tree_leaf_cards.gdshader","res://shaders/meadow.gdshader"]: return
	target.set_shader_parameter("reserve_saturation_floor",reserve_saturation_floor)
	target.set_shader_parameter("reserve_droop",reserve_droop)
	target.set_shader_parameter("reserve_transition_seconds",reserve_transition_seconds)

## Retired imported-tree palettes, retained empty for old resource compatibility.
## Live tree geometry comes from the procedural plant library.
@export var common_trees: Array[PackedScene] = []
@export var hardy_trees: Array[PackedScene] = []
@export var nonliving_trees: Array[PackedScene] = []
## Existing rock obstacles select deterministically from this palette.
@export var rocks: Array[PackedScene] = [preload("res://assets/nature/Rock_Medium_1.gltf"), preload("res://assets/nature/Rock_Medium_2.gltf"), preload("res://assets/nature/Rock_Medium_3.gltf")]
## Nonblocking decoration on existing free ground, outside routes and authored places.
@export var undergrowth: Array[PackedScene] = [preload("res://assets/nature/Bush_Common.gltf"), preload("res://assets/nature/Bush_Common_Flowers.gltf"), preload("res://assets/nature/Fern_1.gltf"), preload("res://assets/nature/Mushroom_Common.gltf")]
## Approximate tree height in world cells before per-cell size variation.
@export_range(2.0, 7.0, 0.25) var tree_height := 3.5
## Rock obstacle height in world cells before per-cell variation.
@export_range(0.3, 1.2, 0.05) var rock_height := 0.65
## Nonblocking decoration height in world cells.
@export_range(0.1, 0.8, 0.05) var undergrowth_height := 0.35
## Percent of otherwise free, non-route cells decorated. Visual only; restart/rebuild to apply.
@export_range(0, 40, 1) var undergrowth_percent := 12
@export_group("Continuous meadow")
## Individual blades on canonical grass cells in all four land biomes. Restart/rebuild applies to loaded worlds too.
@export var meadow_enabled := false
## Grass batch edge in cells. Smaller batches improve frustum/distance culling at the cost of draw calls. Restart/rebuild applies.
@export_enum("4 cells:4", "8 cells:8", "16 cells:16") var meadow_batch_cells: int = 8
## Shared blade shading and active-clock wind. Restart/rebuild applies.
@export var meadow_appearance: MeadowStyle = preload("res://resources/meadow_appearance.tres")
## Individual blades per cell edge (2 to 16); chunk batching and existing detail distance bound rendering.
@export_range(2, 16, 1) var meadow_divisions := 7
## Blade height in world cells before gentle visual variation. Restart/rebuild to apply.
@export_range(0.15, 1.2, 0.01) var meadow_height := 0.18

func valid() -> bool:
	if not is_finite(foliage_size_multiplier) or foliage_size_multiplier < 0.5 or foliage_size_multiplier > 3.0: return false
	if not is_finite(reserve_saturation_floor) or reserve_saturation_floor < 0.0 or reserve_saturation_floor > 1.0: return false
	if not is_finite(reserve_droop) or reserve_droop < 0.0 or reserve_droop > 0.6: return false
	if not is_finite(reserve_transition_seconds) or reserve_transition_seconds < 0.1 or reserve_transition_seconds > 3.0: return false
	for heights in [grass_short_height, grass_medium_height, grass_tall_height]:
		if not heights.is_finite() or heights.x < 0.02 or heights.y > 1.2 or heights.x > heights.y: return false
	if grass_short_height.x > grass_medium_height.x or grass_short_height.y > grass_medium_height.y or grass_medium_height.x > grass_tall_height.x or grass_medium_height.y > grass_tall_height.y: return false
	if not is_finite(grass_patch_cells) or grass_patch_cells < 4.0 or grass_patch_cells > 48.0: return false
	if not is_finite(grass_base_clearance) or grass_base_clearance < 0.02 or grass_base_clearance > 0.3: return false
	if not is_finite(grass_ground_strength) or grass_ground_strength < 0.0 or grass_ground_strength > 1.0: return false
	if not is_finite(terrain_cliff_start_degrees) or not is_finite(terrain_cliff_full_degrees): return false
	if terrain_cliff_start_degrees < 0.0 or terrain_cliff_full_degrees > 89.0 or terrain_cliff_start_degrees >= terrain_cliff_full_degrees: return false
	for distance in [terrain_relief_distance, terrain_normal_distance]:
		if not is_finite(distance) or distance < 0.0 or distance > 128.0: return false
	if not is_finite(foliage_coverage) or foliage_coverage<0.0 or foliage_coverage>1.0: return false
	if not is_finite(plant_instance_variation) or plant_instance_variation<0.0 or plant_instance_variation>0.25: return false
	if meadow_batch_cells not in [4, 8, 16]: return false
	if not is_finite(terrain_blend_detail) or terrain_blend_detail < 0.0 or terrain_blend_detail > 0.4: return false
	if terrain_palette == null or terrain_palette.get_layers() != 13: return false
	if terrain_heights != null and terrain_heights.get_layers() != 13: return false
	if terrain_relief_depth > 0.0 and terrain_heights == null: return false
	if not is_finite(terrain_relief_depth) or terrain_relief_depth < 0.0 or terrain_relief_depth > 0.1: return false
	if terrain_normals != null and terrain_normals.get_layers() != 13: return false
	if terrain_depth_strength > 0.0 and terrain_normals == null: return false
	if not is_finite(terrain_tile_size) or terrain_tile_size < 1.0 or terrain_tile_size > 16.0: return false
	for strength in [terrain_color_strength, terrain_detail_strength, terrain_depth_strength, terrain_blend_softness, trail_texture_strength]:
		if not is_finite(strength) or strength < 0.0 or strength > 1.0: return false
	if meadow_appearance==null or not meadow_appearance.valid(): return false
	if not is_finite(ground_texture_strength) or ground_texture_strength < 0.0 or ground_texture_strength > 1.0:
		return false
	for channel in [ground_base_color.r, ground_base_color.g, ground_base_color.b, ground_base_color.a]:
		if not is_finite(channel) or channel < 0.0 or channel > 1.0: return false
	if meadow_divisions < 2 or meadow_divisions > 16 or not is_finite(meadow_height) or meadow_height < 0.15 or meadow_height > 1.2:
		return false
	if not is_finite(biome_edge_blend) or biome_edge_blend < 0 or biome_edge_blend > 1:
		return false
	if biome_blend_cells < 1 or biome_blend_cells > 8: return false
	if composition != null and not composition.valid():
		return false
	var grounds := {}
	for biome in biomes:
		if biome == null or not biome.valid() or grounds.has(biome.ground):
			return false
		grounds[biome.ground] = true
	if not common_trees.is_empty() or not hardy_trees.is_empty() or not nonliving_trees.is_empty(): return false
	for palette in [rocks, undergrowth]:
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
	if biome_edge_blend <= 0.0: return base
	var neighbors := Color(0, 0, 0, 0)
	# Nine fixed samples keep reconstruction work bounded as the radius grows.
	# Include the center, avoiding the old cross-only kernel's color inversion.
	for y in [-1,0,1]:
		for x in [-1,0,1]:
			var weight: float = (2.0 if x==0 else 1.0)*(2.0 if y==0 else 1.0)
			var adjacent := biome_for(terrain.natural_ground(cell+Vector2i(x,y)*biome_blend_cells))
			neighbors += (adjacent.ground_tint if adjacent != null else base)*weight
	return base.lerp(neighbors / 16.0, biome_edge_blend)

func tree_is_living(scene: PackedScene) -> bool:
	return scene not in nonliving_trees
