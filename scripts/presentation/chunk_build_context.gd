extends RefCounted
## Exclusively leased evaluation caches and main-captured, immutable model descriptors.
const Library = preload("res://scripts/scenery/plant_library.gd")
const Art = preload("res://scripts/scenery/nature_art.gd")
var terrain: WorldTerrain
var nature: NatureSettings
var entries: Array[Resource] = []
var official := {}
var definitions := {}
var models := {}
var assets := {}
var simple := {}
var scene_models := {}
var custom_tokens := {}
var registry := {} # Main-owned retained mesh references; workers only carry integer tokens.
var surface_uvs := {}
var distribution_field := FastNoiseLite.new()
var grass_field := FastNoiseLite.new()
var failure := ""
var tints: Array[Color] = [Color.WHITE]

func capture(source: WorldTerrain, tuning: NatureSettings) -> void:
	assert(OS.get_thread_caller_id() == OS.get_main_thread_id())
	for biome in tuning.biomes:
		if not tints.has(biome.detail_tint): tints.append(biome.detail_tint)
	terrain = WorldTerrain.new(0, {}, {}, {}, {}, true)
	for key in ["world_seed", "generation_version", "flora_specialist_percent", "cabin_footprint", "_landmark_height", "_cabin_height", "geography_ready"]:
		terrain.set(key, source.get(key))
	for key in ["climate", "relief", "community_parameters", "scenery_parameters", "cabin_layout", "scenery_site"]:
		terrain.set(key, source.get(key).duplicate(true))
	for key in ["noise", "moisture", "vastra", "affinity_noise"]:
		terrain.set(key, source.get(key).duplicate())
	var relief := TerrainReliefSettings.new()
	for key in source.relief: relief.set(key, source.relief[key])
	terrain.heightfield = TerrainHeightfield.new(source.world_seed, relief)
	var community: Dictionary = terrain.community_parameters
	terrain.community_layout.configure(source.world_seed, community.patch_size, community.coverage, community.spacing, community.canopy_influence, 0)
	terrain.community_layout.trees_only = true
	terrain._wetland_composition = snapshot_resource(source._wetland_composition)
	nature = snapshot_resource(tuning)
	distribution_field.seed = source.world_seed
	distribution_field.frequency = 0.075
	grass_field.seed = source.world_seed
	grass_field.frequency = 1.0 / tuning.grass_patch_cells
	for biome in range(4):
		for role in ["emanator", "reservoir", "receiver"]:
			for specialist in ([""] if role != "receiver" else FloraTraits.CLASSES):
				var traits := {"role":role,"class":specialist}
				official["%d:%s:%s" % [biome,role,specialist]] = Library.official_candidates(biome,traits).duplicate()
	for item in Library.all():
		capture_definition(item.plant_id, item)
		entries.append(definitions[item.plant_id])
	var renderer: Script = load("res://scripts/presentation/solid_chunk.gd")
	for key in ["post", "prop", "wall", "roof"]:
		var mesh: Mesh = renderer.mesh_for(key)
		registry[mesh.get_instance_id()] = mesh
		simple[key] = {"mesh":mesh.get_instance_id(),"bounds":mesh.get_aabb()}
	for key in ["grass_0", "grass_1", "grass_2", "grass_3", "trail_0", "trail_1", "trail_2", "trail_3", "trail_4", "trail_5", "trail_6", "trail_7"]:
		surface_uvs[key] = renderer.mesh_for(key).surface_get_arrays(0)[Mesh.ARRAY_TEX_UV].duplicate()

func snapshot_resource(source: Resource) -> Resource:
	if source == null: return null
	if source is NatureAssetEntry:
		var entry := preload("res://scripts/presentation/chunk_snapshot_entry.gd").new()
		for property in source.get_property_list():
			if property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE and property.usage & PROPERTY_USAGE_STORAGE:
				entry.set(property.name, source.get(property.name))
		entry.captured = capture_model(source.admitted_model())
		return entry
	var copy := source.duplicate(false)
	for property in source.get_property_list():
		if not (property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE and property.usage & PROPERTY_USAGE_STORAGE): continue
		var value: Variant = source.get(property.name)
		if value is Resource and not value is PackedScene and value.get_script() != null:
			copy.set(property.name, snapshot_resource(value))
		elif value is Array:
			var items: Array = value.duplicate()
			for index in range(items.size()):
				if items[index] is Resource and not items[index] is PackedScene: items[index] = snapshot_resource(items[index])
			copy.set(property.name,items)
		elif value is Dictionary: copy.set(property.name,value.duplicate(true))
	# Rock scenes are opaque identity references; no worker instantiates them.
	if source is NatureSettings:
		for scene in source.rocks:
			scene_models[scene] = {"compact":capture_model(Art.compact_parts(scene),false),"raw":capture_model(Art.parts(scene),false)}
	return copy

func capture_model(source: Dictionary, tint_variants: bool = true) -> Dictionary:
	if source.is_empty(): return {}
	var output := source.duplicate()
	var pieces: Array[Dictionary] = []
	for piece in source.pieces:
		var token: int = piece.mesh.get_instance_id()
		registry[token] = piece.mesh
		capture_custom(piece.mesh)
		pieces.append({"mesh":token,"transform":piece.transform,"bounds":piece.mesh.get_aabb()})
	output.pieces = pieces
	var variants := {}
	for tint in tints:
		if not tint_variants: break
		if tint == Color.WHITE: continue
		var tinted := Art.tint_parts(source,tint)
		var rows: Array[Dictionary] = []
		for piece in tinted.pieces:
			var token: int = piece.mesh.get_instance_id()
			registry[token] = piece.mesh
			capture_custom(piece.mesh)
			rows.append({"mesh":token,"transform":piece.transform,"bounds":piece.mesh.get_aabb()})
		var variant := output.duplicate()
		variant.pieces = rows
		variants[hash(tint)] = variant
	output["tints"] = variants
	return output

func capture_definition(key: String, source: Resource) -> void:
	if source == null:
		definitions[key] = null
		return
	var item := source.duplicate(false)
	item.recipe = source.recipe.duplicate(true)
	item.organ_anchors = source.organ_anchors.duplicate(true)
	item.organ_graph = source.organ_graph.duplicate(true)
	assets[item.plant_id] = item.plant_id if source.get_meta("runtime_palette",false) or source.scene.resource_path.is_empty() else source.scene.resource_path
	item.scene = null
	# Living palette bodies use their authored colors; only scene dressing tints.
	models[item.plant_id] = capture_model(Library.model(source),false)
	definitions[key] = item

func prepare_definition(key: String) -> void:
	assert(OS.get_thread_caller_id() == OS.get_main_thread_id())
	if definitions.has(key): return
	var item: Resource
	if key.begins_with("official_"): item = Library.official_definition(key.trim_prefix("official_"))
	elif key.begins_with("foliage_"):
		var parts := key.split("_")
		item = Library.foliage_definition(int(parts[1]),int(parts[2]),parts[3],key.ends_with("_cover"))
	elif key.begins_with("procedural_"):
		var parts := key.split("_")
		var role := int(parts[2])
		item = Library.procedural_definition(int(parts[1]),{"role":"reservoir" if role == 1 else "receiver","class":"" if role == 1 else FloraTraits.CLASSES[role-3]},int(parts[3]))
	capture_definition(key,item)

func definition(key: String) -> Resource:
	if not definitions.has(key):
		failure = "Uncaptured chunk dependency: " + key
		return null
	return definitions[key]

func tint_model(source: Dictionary, tint: Color) -> Dictionary:
	if tint == Color.WHITE: return source
	return source.get("tints",{}).get(hash(tint), source)

func scene_model(scene: PackedScene, tint: Color, compact: bool) -> Dictionary:
	return tint_model(scene_models[scene]["compact" if compact else "raw"],tint)

func capture_custom(mesh: Mesh) -> void:
	var custom := false
	for index in range(mesh.get_surface_count()):
		var material: Material = mesh.surface_get_material(index)
		if material is ShaderMaterial and material.shader != null:
			var path: String = material.shader.resource_path
			if path in ["res://shaders/tree_leaf_cards.gdshader", "res://shaders/meadow.gdshader"] or (path == "res://shaders/procedural_plant_foliage.gdshader" and not material.get_shader_parameter("bark_surface")): custom = true
	custom_tokens[mesh.get_instance_id()] = custom
