class_name AuthoredPlantLibrary
extends RefCounted
## Authored designs and bounded procedural art on canonical slots. No ledger writes.
const Definition = preload("res://scripts/scenery/plant_definition.gd")
const Art = preload("res://scripts/scenery/nature_art.gd")
const Groundcover = preload("res://scripts/scenery/meadow_art.gd")
const Distribution = preload("res://scripts/scenery/foliage_distribution.gd")
const Species = preload("res://scripts/scenery/plant_species_catalog.gd")
static var official_entries: Dictionary = {}
const MAX_INSTANCE_VARIATION := 0.25
const TREE_HEIGHTS := [2.0,6.5,12.0]
const GROUND_HEIGHTS := [0.08,0.5,1.5]
# Include recipe size variation and the largest permitted per-cell variation.
const PROCEDURAL_HEIGHT_BOUND := 12.0*1.25*(1.0+MAX_INSTANCE_VARIATION)
const PROCEDURAL_WIDTH_BOUND := 12.0*(1.0+MAX_INSTANCE_VARIATION)
static var entries: Array[Resource] = []
static var models: Dictionary = {}
static var procedural_entries: Dictionary = {}
static var foliage_entries: Dictionary = {}
static var loaded := false
static var revision := 0
static var largest_height := PROCEDURAL_HEIGHT_BOUND
static var largest_width := PROCEDURAL_WIDTH_BOUND
const PALETTE_DIRECTORY := "res://resources/plants/runtime_palette"
const PALETTE_INPUTS := ["plant_library.gd", "plant_definition.gd", "procedural_plant_mesh.gd", "plant_vastra_anatomy_mesh.gd", "generic_foliage_mesh.gd", "nature_art.gd"]
static var use_baked_palette := true
static var palette_checked := false
static var palette_current := false
static var sources: Array[String] = ["res://resources/plants/library.json","user://authored_plants/library.json"]

static func refresh(manifests: Array[String] = []) -> void:
	if not manifests.is_empty(): sources = manifests.duplicate()
	entries.clear()
	largest_height=PROCEDURAL_HEIGHT_BOUND
	largest_width=PROCEDURAL_WIDTH_BOUND
	models.clear()
	procedural_entries.clear()
	foliage_entries.clear()
	official_entries.clear()
	palette_checked = false
	var admitted := {}
	for path in sources:
		if not FileAccess.file_exists(path): continue
		var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		if not data is Dictionary or data.get("version")!=1 or not data.get("plants") is Array: continue
		for location in data.plants.slice(0,512):
			if not location is String or not location.begins_with(path.get_base_dir()+"/") or not location.ends_with(".tres") or "/../" in location: continue
			if not ResourceLoader.exists(location): continue
			var item = ResourceLoader.load(location,"",ResourceLoader.CACHE_MODE_IGNORE)
			if item is Definition and item.valid(): admitted[item.plant_id] = item
	var keys := admitted.keys()
	keys.sort()
	for key in keys:
		entries.append(admitted[key])
		if admitted[key].enabled_in_world:
			largest_height=maxf(largest_height,admitted[key].world_height)
			largest_width=maxf(largest_width,admitted[key].world_width)
	loaded = true
	revision += 1

static func all() -> Array[Resource]:
	if not loaded: refresh()
	return entries.duplicate()

## Bake tooling records the implementation inputs; stale/missing art is never trusted.
static func palette_fingerprint() -> String:
	var inputs := "palette-v1"
	for filename in PALETTE_INPUTS:
		inputs += FileAccess.get_sha256("res://scripts/scenery/" + filename)
	inputs += FileAccess.get_sha256("res://tools/bake_runtime_plants.gd")
	inputs += FileAccess.get_sha256(Species.PATH)
	inputs += FileAccess.get_sha256("res://scripts/scenery/plant_species_catalog.gd")
	inputs += FileAccess.get_sha256("res://scripts/presentation/mesh_picking.gd")
	inputs += FileAccess.get_sha256("res://scripts/sols/flora_traits.gd")
	return inputs.sha256_text()

static func baked_definition(key: String) -> Resource:
	if not use_baked_palette: return null
	if not palette_checked:
		palette_checked = true
		var manifest: Variant = JSON.parse_string(FileAccess.get_file_as_string(PALETTE_DIRECTORY + "/manifest.json")) if FileAccess.file_exists(PALETTE_DIRECTORY + "/manifest.json") else null
		# Exported scripts may be remapped/compiled; the bake is packaged with
		# that build. Development/editor binaries additionally check source hashes.
		palette_current = manifest is Dictionary and manifest.get("version", 0) == 1
		if palette_current and OS.has_feature("editor"):
			palette_current = manifest.get("fingerprint", "") == palette_fingerprint()
	if not palette_current: return null
	var path := PALETTE_DIRECTORY + "/" + key + ".res"
	if not ResourceLoader.exists(path): return null
	var item: Resource = load(path)
	if not item is Definition or item.plant_id != key or not item.valid(): return null
	return item

## Twenty shared designs with separate receiving-study and live emanator anatomy.
static func foliage_definition(biome: int, variation: int, circulation: String = "receiver") -> Resource:
	if biome not in [0,1,2,3] or variation<0 or variation>4: return null
	if circulation not in ["receiver","emanator"]: return null
	var key := "foliage_%d_%d"%[biome,variation]+("_emanator" if circulation=="emanator" else "")
	if foliage_entries.has(key): return foliage_entries[key]
	var baked := baked_definition(key)
	if baked != null:
		foliage_entries[key] = baked
		return baked
	var builder = preload("res://scripts/scenery/generic_foliage_mesh.gd").new()
	var settings := {"foliage_variation":variation,"branches":7,"foliage":1.0,"anatomy_scale":1.2,"organic_softness":0.9,"branch_irregularity":0.15,"leaf_asymmetry":0.12,"height_diversity":0.25,"hue_shift":0.0,"biome_palette_variant":variation}
	var specimen: Dictionary=builder.create_sample(biome,0 if circulation=="emanator" else 2,(382+variation)*10000+biome*101+(0 if circulation=="emanator" else 26),settings,builder.make_anatomy_materials())
	var root := Node3D.new()
	for mesh: ArrayMesh in [specimen.body,specimen.anatomy]:
		var node := MeshInstance3D.new()
		node.mesh=mesh
		root.add_child(node)
		node.owner=root
	var packed := PackedScene.new()
	packed.pack(root)
	root.free()
	var item := Definition.new()
	item.plant_id=key
	item.display_name=specimen.growth_plan
	item.scene=packed
	item.growth_category="generic_foliage"
	item.biome=biome
	item.circulation_role=circulation
	item.enabled_in_world=circulation=="emanator"
	item.world_height=[0.45,0.7,0.25,0.9][biome]
	item.world_width=[0.8,0.9,0.6,0.6][biome]
	item.recipe=settings.duplicate()
	item.recipe["roots_below_ground"]=true
	item.recipe.merge({"growth_category":1,"generic_circulation":0 if circulation=="emanator" else 1,"selected_biome":biome+1,"selected_role":1 if circulation=="emanator" else 3,"generation_seed":382+variation,"branch_count":7,"anatomy_thickness":1.2,"foliage_density":1.0,"world_height":item.world_height,"world_width":item.world_width})
	var positions := {}
	for organ: Dictionary in specimen.organs: positions[organ.id]=organ.position
	item.organ_graph=specimen.organs.duplicate(true)
	item.organ_anchors={"ground":positions.ground,"receive":positions.intake,"release":positions.outlet,"crown":positions.reserve}
	foliage_entries[key]=item
	return item

static func model(item: Resource) -> Dictionary:
	if not models.has(item.plant_id):
		models[item.plant_id] = Art.parts(item.scene) if item.get_meta("runtime_palette", false) else Art.compact_parts(item.scene)
		for piece: Dictionary in models[item.plant_id].pieces:
			preload("res://scripts/presentation/mesh_picking.gd").prepare(piece.mesh)
	return models[item.plant_id]

## Approved visual baselines occupy existing ecological slots, without new reserves.
static func official_definition(id: String) -> Resource:
	if official_entries.has(id): return official_entries[id]
	var entry := Species.get_design(id)
	if entry.is_empty() or not entry.live_ecology_eligible: return null
	var key := "official_" + id
	var baked := baked_definition(key)
	if baked != null:
		official_entries[id] = baked
		return baked
	var recipe: Dictionary = entry.baseline_recipe.duplicate(true)
	var settings := recipe.duplicate(true)
	for alias: String in {"branches":"branch_count","leaf_scale":"leaf_size","foliage":"foliage_density","curl":"leaf_curl","anatomy_scale":"anatomy_thickness"}:
		var source: String = {"branches":"branch_count","leaf_scale":"leaf_size","foliage":"foliage_density","curl":"leaf_curl","anatomy_scale":"anatomy_thickness"}[alias]
		settings[alias] = recipe[source]
	var builder = preload("res://scripts/scenery/generic_foliage_mesh.gd").new() if entry.growth_category == "generic_foliage" else preload("res://scripts/scenery/plant_vastra_anatomy_mesh.gd").new()
	var sample: Dictionary
	for sides in [8,4,3]:
		builder.tube_sides = sides
		sample = builder.create_sample(int(recipe.selected_biome)-1,int(recipe.selected_role)-1,int(recipe.specimen_seed_override),settings,builder.make_anatomy_materials())
		var triangles := 0
		for mesh: ArrayMesh in [sample.body,sample.anatomy]:
			for surface in range(mesh.get_surface_count()): triangles += mesh.surface_get_arrays(surface)[Mesh.ARRAY_INDEX].size()/3
		if triangles <= 30000: break
	var body := Node3D.new()
	for mesh: ArrayMesh in [sample.body,sample.anatomy]:
		var piece := MeshInstance3D.new()
		piece.mesh = mesh
		piece.scale = Vector3.ONE * float(recipe.plant_size)
		body.add_child(piece)
		piece.owner = body
	var item := Definition.new()
	item.scene = PackedScene.new()
	item.scene.pack(body)
	body.free()
	item.plant_id = key
	item.catalog_design_id = id
	item.species_id = entry.species_id
	item.display_name = entry.display_name
	item.growth_category = entry.growth_category
	item.biome = int(recipe.selected_biome)-1
	item.circulation_role = entry.circulation_role
	item.specialist_class = entry.specialist_class
	item.size_class = int(recipe.size_class)
	item.world_height = float(recipe.world_height)
	item.world_width = float(recipe.world_width)
	item.preserve_proportions = recipe.preserve_proportions
	item.frequency_percent = 100
	item.enabled_in_world = true
	item.recipe = recipe
	item.organ_graph = sample.organs.duplicate(true)
	item.organ_graph.append_array(sample.get("leaf_surfaces", []))
	var positions := {}
	for organ: Dictionary in item.organ_graph:
		organ.position *= float(recipe.plant_size)
		positions[organ.id] = organ.position
	item.organ_anchors = {"ground":positions.ground,"receive":positions.get("intake",positions.reserve),"release":positions.get("outlet",positions.get("crown",positions.reserve)),"crown":positions.get("crown",positions.reserve)}
	official_entries[id] = item
	return item

static func official_candidates(biome: int, traits: Dictionary) -> Array[String]:
	var result: Array[String] = []
	for entry: Dictionary in Species.all():
		if entry.live_ecology_eligible and int(entry.baseline_recipe.selected_biome)-1 == biome and entry.circulation_role == traits.role and entry.specialist_class == traits["class"]:
			result.append(entry.design_id)
	result.sort()
	return result

## One presentation entry for canonical flora. Grass is the built-in emanator
## body; its blade renderer owns batching, never roles, reserves or admission.
static func add_cell(chunk: Node3D,terrain: WorldTerrain,cell: Vector2i,data: Dictionary,settings: NatureSettings) -> Dictionary:
	var kind := terrain.flora_kind(cell,data)
	if kind.is_empty(): return {}
	var traits := FloraTraits.describe(terrain.world_seed,{"id":FloraCatalog.id_for(cell),"cell":[cell.x,cell.y],"kind":kind},terrain.flora_specialist_percent)
	var body := placement(terrain,cell,data,kind,true,settings.plant_instance_variation,settings.foliage_coverage)
	# An authored emanator replaces the built-in grass body. Surrounding blades
	# on a specialist's cell remain part of that cell's single ecological owner.
	if kind=="plant" and (traits.form!="grass" or body.is_empty() or body.get("growth_category","")=="generic_foliage"):
		Groundcover.add_cell(chunk,terrain,cell,data,settings,traits.role!="emanator" or not body.is_empty())
	if not body.is_empty(): chunk.add_composed_nature(body)
	# Rendering density, disabled grass and rejected art never remove a real
	# plant's transfer endpoint. Generation and the saved ledger own membership.
	if kind=="plant" and not chunk.living_sources.has(cell):
		var anchor := Vector3(cell.x+0.5,terrain.surface_height(Vector2(cell)+Vector2(0.5,0.5))+0.05,cell.y+0.5)
		chunk.register_living_source(cell,"detail",traits.name,anchor)
	return body

static func placement(terrain: WorldTerrain,cell: Vector2i,data: Dictionary,kind: String, procedural_fallback: bool = false, instance_variation: float = 0.12, foliage_coverage: float = 0.0) -> Dictionary:
	if not loaded: refresh()
	if data.ground not in [0,1,2,3] or terrain.flora_kind(cell,data)!=kind: return {}
	var traits := FloraTraits.describe(terrain.world_seed,{"id":FloraCatalog.id_for(cell),"cell":[cell.x,cell.y],"kind":kind},terrain.flora_specialist_percent)
	var candidates: Array[Resource] = []
	for item in entries:
		if item.enabled_in_world and item.biome==data.ground and item.circulation_role==traits.role and item.specialist_class==traits["class"]: candidates.append(item)
	var selected: Resource
	var procedural := false
	if not candidates.is_empty():
		selected = candidates[terrain.roll(cell,771931)%candidates.size()]
		if terrain.roll(cell,771933)%100>=selected.frequency_percent: selected = null
	if selected==null and procedural_fallback and traits.role!="emanator":
		var official := official_candidates(int(data.ground),traits)
		selected = official_definition(official[terrain.roll(cell,771937)%official.size()]) if not official.is_empty() else procedural_definition(int(data.ground),traits,terrain.roll(cell,771937)%3)
		procedural = true
	if selected==null and procedural_fallback and traits.role=="emanator" and foliage_coverage>0.0:
		var proposal := Distribution.proposal(terrain,cell,data,foliage_coverage)
		if proposal.is_empty() or not Distribution.has_space(terrain,cell,proposal,foliage_coverage): return {}
		selected=foliage_definition(int(proposal.biome),int(proposal.variation),"emanator")
		var official := official_candidates(int(proposal.biome),traits)
		if not official.is_empty(): selected = official_definition(official[int(proposal.variation)%official.size()])
		for smaller: float in [1.0,0.72,0.5]:
			var fitted := fit_definition(terrain,cell,kind,selected,false,0.0,float(proposal.scale)*smaller)
			if not fitted.is_empty():
				fitted.merge({"growth_category":"generic_foliage","variation":proposal.variation,"community":proposal.patch_id,"size_factor":float(proposal.scale)*smaller})
				return fitted
		return {}
	if selected==null: return {}
	if procedural:
		for smaller: float in [1.0,0.72,0.5]:
			var fitted := fit_definition(terrain,cell,kind,selected,true,instance_variation,smaller)
			if not fitted.is_empty(): return fitted
		if kind=="tree" and selected.size_class>0:
			var small_tree: Resource=procedural_definition(int(data.ground),traits,0)
			var fitted := fit_definition(terrain,cell,kind,small_tree,true,instance_variation,0.72)
			if not fitted.is_empty(): return fitted
	else:
		var fitted := fit_definition(terrain,cell,kind,selected,false,instance_variation)
		if not fitted.is_empty(): return fitted
	# A canonical tree already blocks this cell even if a broad canopy cannot fit.
	# Keep its body inside its own cell using the current procedural plant palette.
	if kind=="tree" and procedural_fallback:
		var sapling: Resource=procedural_definition(int(data.ground),traits,0)
		return fit_definition(terrain,cell,kind,sapling,true,instance_variation,1.0,true)
	return {}

static func fit_definition(terrain: WorldTerrain,cell: Vector2i,kind: String,selected: Resource,procedural: bool,instance_variation: float,size_multiplier: float = 1.0,confined_tree: bool = false) -> Dictionary:
	var parts := model(selected)
	if not parts.supported or parts.pieces.is_empty() or parts.triangles>30000 or parts.surfaces>12: return {}
	var box: AABB = parts.bounds
	var size_scale: Vector3=selected.scale_for(box)
	size_scale*=size_multiplier
	if procedural:
		# A presentation-only stream: never consumes RNG or changes canonical flora.
		var amount := clampf(instance_variation,0.0,MAX_INSTANCE_VARIATION)
		size_scale *= lerpf(1.0-amount,1.0+amount,float(terrain.roll(cell,771941)%10001)/10000.0)
	var point := Vector2(cell)+Vector2(0.5,0.5)
	var normal := terrain.surface_normal(point)
	if not normal.is_finite() or normal.y<=0.0: return {}
	if not confined_tree and normal.y<cos(deg_to_rad(18.0)): return {}
	var orientation := Basis(Vector3.UP,float(terrain.roll(cell,771935)%6283)/1000.0)
	if confined_tree:
		if kind!="tree": return {}
		var rotated: AABB = Transform3D(orientation*Basis.from_scale(size_scale),Vector3.ZERO)*box
		var narrow := minf(1.0,0.4/maxf(rotated.size.x,rotated.size.z))
		size_scale.x*=narrow
		size_scale.z*=narrow
		size_scale.y*=minf(1.0,1.5/maxf(rotated.size.y,0.001))
	# Low growth follows its ground plane; reservoir trunks remain upright.
	if kind=="plant": orientation = Basis(Quaternion(Vector3.UP,normal))*orientation
	var basis := orientation*Basis.from_scale(size_scale)
	var transform := Transform3D(basis,Vector3(point.x,terrain.surface_height(point),point.y))
	transform.origin -= basis*selected.ground_offset(box)
	var bounds: AABB = transform*box
	var sway_margin:=0.16+maxf(size_scale.x,size_scale.z)*0.12
	if confined_tree and (bounds.position.x-sway_margin<float(cell.x) or bounds.end.x+sway_margin>float(cell.x+1) or bounds.position.z-sway_margin<float(cell.y) or bounds.end.z+sway_margin>float(cell.y+1)): return {}
	for y in range(floori(bounds.position.z-sway_margin),ceili(bounds.end.z+sway_margin)):
		for x in range(floori(bounds.position.x-sway_margin),ceili(bounds.end.x+sway_margin)):
			var at := Vector2i(x,y)
			if terrain.scenery_reserved(at) or terrain.route_axes(at,1)!=0 or terrain.is_camp(at) or terrain.is_landmark(at) or terrain.cabin_footprint.grow(1).has_point(at): return {}
			var sample := terrain.sample(at)
			if sample.ground not in [0,1,2,3] or (sample.obstacle!=0 and not (kind=="tree" and at==cell)): return {}
			if at!=cell and not sample.walkable: return {}
			if selected.growth_category=="generic_foliage" and at!=cell and terrain.flora_kind(at,sample)=="plant":
				var adjacent := FloraTraits.describe(terrain.world_seed,{"id":FloraCatalog.id_for(at),"cell":[at.x,at.y],"kind":"plant"},terrain.flora_specialist_percent)
				if adjacent.role=="receiver": return {}
	var category := "tree" if kind=="tree" else "detail"
	return {"asset":selected.plant_id if selected.get_meta("runtime_palette", false) or selected.scene.resource_path.is_empty() else selected.scene.resource_path,"cell":cell,"transform":transform,"bounds":bounds,"patch":"authored_plant","living":true,"model":parts,"subject":selected.display_name,"category":category,"flora_id":FloraCatalog.id_for(cell),"vastra_organs":world_organs(selected,transform),"vastra_anchor":transform*selected.organ_anchors.receive,"high_anchor":transform*selected.organ_anchors.crown if kind=="tree" else Vector3.INF}

static func maximum_height() -> float:
	if not loaded: refresh()
	return largest_height

static func maximum_width() -> float:
	if not loaded: refresh()
	return largest_width

static func set_weather(direction: Vector2,seconds: float,strength: float,origin: Vector2 = Vector2.ZERO,rain: float = 0.0) -> void:
	Groundcover.set_weather(direction,rain,seconds,origin)
	for parts: Dictionary in models.values():
		for piece: Dictionary in parts.pieces:
			for index in range(piece.mesh.get_surface_count()):
				var material: Material = piece.mesh.surface_get_material(index)
				if material is ShaderMaterial:
					material.set_shader_parameter("wind_time",seconds)
					material.set_shader_parameter("wind_strength",clampf(strength,0,1))
					material.set_shader_parameter("wind_direction",direction.normalized() if direction.length_squared()>0.0001 else Vector2.ZERO)
					material.set_shader_parameter("world_origin",origin)

# A bounded shared palette (48 models), independent of world seed and streaming order.
# The canonical cell selects its variant; geometry never owns flora or reserves.
static func procedural_definition(biome: int, traits: Dictionary, variant: int) -> Resource:
	var role_index := 1 if traits.role=="reservoir" else 3+FloraTraits.CLASSES.find(traits["class"])
	var key := "procedural_%d_%d_%d"%[biome,role_index,variant]
	if procedural_entries.has(key): return procedural_entries[key]
	var baked := baked_definition(key)
	if baked != null:
		procedural_entries[key] = baked
		return baked
	var random := RandomNumberGenerator.new()
	random.seed = 93017+biome*1009+role_index*71+variant*13
	var settings := {"branches":5,"foliage":0.65,"node_count":5,"frond_pairs":4,"leaf_architecture":0,"branch_irregularity":variant*0.3,"leaf_asymmetry":variant*0.25,"height_ratio":random.randf_range(0.75,1.3),"spread_ratio":random.randf_range(0.7,1.2),"branch_twist":random.randf_range(-0.6,0.6),"node_bulk":random.randf_range(0.7,1.5),"leaf_width":random.randf_range(0.65,1.4),"hue_shift":random.randf_range(-12,12)}
	if role_index==1:
		settings.merge({"tree_leaf_cards":true,"foliage":1.25,"foliage_fullness":1.5,"node_count":5,"branches":6,"tree_fork_depth":2,"tree_fork_spread":0.95,"branching_depth":1,"spread_ratio":random.randf_range(1.1,1.5)},true)
	settings.merge({"foliage_palette":0,"biome_palette_variant":posmod(variant+role_index,5),"bark_palette":0,"flower_palette":random.randi_range(0,6),"color_gradient":random.randf_range(0.3,0.6),"branch_reach":random.randf_range(1.1,1.5),"branch_arch":random.randf_range(0.65,1.0)})
	var builder = preload("res://scripts/scenery/plant_vastra_anatomy_mesh.gd").new()
	var sample: Dictionary = builder.create_sample(biome,role_index,random.randi_range(1,10000),settings,preload("res://scripts/scenery/plant_vastra_anatomy_mesh.gd").make_anatomy_materials())
	var root := Node3D.new()
	for mesh: ArrayMesh in [sample.body,sample.anatomy]:
		var node := MeshInstance3D.new()
		node.mesh = mesh
		root.add_child(node)
		node.owner = root
	var packed := PackedScene.new()
	packed.pack(root)
	root.free()
	var item := Definition.new()
	item.plant_id = key
	item.display_name = builder.PLANS[biome*6+role_index]
	item.scene = packed
	item.biome = biome
	item.circulation_role = traits.role
	item.specialist_class = traits["class"]
	item.size_class = variant
	item.world_height = (TREE_HEIGHTS[variant] if role_index==1 else GROUND_HEIGHTS[variant])*random.randf_range(0.7,1.25)
	var box: AABB=sample.body.get_aabb().merge(sample.anatomy.get_aabb())
	var natural_width:=item.world_height*maxf(box.size.x,box.size.z)/maxf(0.000001,box.end.y)
	var normal_width: float=([3.0,5.0,8.0][variant] if role_index==1 else [0.2,0.6,1.3][variant])*1.1
	item.world_width=clampf(natural_width if role_index==1 else minf(natural_width,normal_width),0.02,12.0)
	item.frequency_percent = 100
	item.enabled_in_world = true
	item.recipe = settings.duplicate()
	item.recipe["roots_below_ground"]=true
	item.recipe.merge({"selected_biome":biome+1,"selected_role":role_index+1})
	var positions := {}
	for organ: Dictionary in sample.organs: positions[organ.id] = organ.position
	item.organ_graph = sample.organs.duplicate(true)
	item.organ_graph.append_array(sample.get("leaf_surfaces", []))
	item.organ_anchors = {"ground":positions.ground,"receive":positions.get("intake",positions.reserve),"release":positions.get("outlet",positions.get("crown",positions.reserve)),"crown":positions.get("crown",positions.reserve)}
	procedural_entries[key] = item
	return item

## World-space anatomy belongs to the placed body, never to the saved ledger.
static func world_organs(item: Resource, transform: Transform3D) -> Dictionary:
	var result := {}
	for key in item.organ_anchors:
		result[key] = {"position":transform*item.organ_anchors[key],"parent":""}
	for organ: Dictionary in item.organ_graph:
		result[organ.id] = {"position":transform*organ.position,"parent":organ.parent}
	return result
