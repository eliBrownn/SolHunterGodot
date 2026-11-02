extends RefCounted
## Draft-only recipe reconstruction. Never writes the approved catalog or palette.
const Library = preload("res://scripts/scenery/plant_library.gd")
const Builder = preload("res://scripts/scenery/plant_vastra_anatomy_mesh.gd")
const Foliage = preload("res://scripts/scenery/generic_foliage_mesh.gd")
const REGISTRY = "res://docs/reference/plant_review_registry.json"

static func registry() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(REGISTRY))

static func source(row: Dictionary) -> Resource:
	var id: String = row.plant_id
	# Only read the stored recipe/dimensions here; draft geometry is rebuilt below.
	# This does not admit an out-of-date bake to the live renderer.
	var stored := Library.PALETTE_DIRECTORY+"/"+id+".res"
	if ResourceLoader.exists(stored): return load(stored)
	if id.begins_with("official_"):
		return Library.official_definition(id.trim_prefix("official_"))
	if id.begins_with("procedural_"):
		var fields := id.split("_")
		var role := int(fields[2])
		return Library.procedural_definition(int(fields[1]), {"role":"reservoir" if role==1 else "receiver", "class":"" if role==1 else FloraTraits.CLASSES[role-3]}, int(fields[3]))
	if id.begins_with("foliage_"):
		var fields := id.split("_")
		return Library.foliage_definition(int(fields[1]), int(fields[2]), "emanator", id.ends_with("_cover"))
	for item in Library.all():
		if item.plant_id == id: return item
	return null

static func is_bush(row: Dictionary, item: Resource) -> bool:
	return item != null and item.growth_category=="generic_foliage" and not str(row.plant_id).ends_with("_cover")

static func revised(row: Dictionary, config: Dictionary) -> bool:
	if config.overrides.has(row.code): return true
	if not config.get("general_foliage_review",true): return false
	var id: String = row.plant_id
	if id.begins_with("foliage_"): return not id.ends_with("_cover")
	if id.begins_with("official_"):
		return Library.Species.get_design(id.trim_prefix("official_")).get("growth_category","")=="generic_foliage"
	return false

static func draft(row: Dictionary, config: Dictionary) -> Dictionary:
	var original := source(row)
	if original==null: return {}
	var instruction: Dictionary=config.overrides.get(row.code,{})
	if instruction.get("base","")=="original" and str(row.plant_id).begins_with("procedural_"):
		# Recover the generator's exact original seed and scaffold, then change leaves.
		var fields: PackedStringArray=str(row.plant_id).split("_")
		var was_baked:=Library.use_baked_palette
		Library.use_baked_palette=false
		Library.procedural_entries.erase(row.plant_id)
		original=Library.procedural_definition(int(fields[1]),{"role":"reservoir","class":""},int(fields[3]))
		Library.use_baked_palette=was_baked
	var item: Resource = original.duplicate()
	var settings: Dictionary = item.recipe.duplicate(true)
	for alias in {"branches":"branch_count", "leaf_scale":"leaf_size", "foliage":"foliage_density", "curl":"leaf_curl", "anatomy_scale":"anatomy_thickness"}:
		var key: String = {"branches":"branch_count", "leaf_scale":"leaf_size", "foliage":"foliage_density", "curl":"leaf_curl", "anatomy_scale":"anatomy_thickness"}[alias]
		if settings.has(key): settings[alias]=settings[key]
	var generic := is_bush(row, item)
	var role := 1 if item.circulation_role=="reservoir" else (0 if item.circulation_role=="emanator" else 3+FloraTraits.CLASSES.find(item.specialist_class))
	var seed_value := int(settings.get("specimen_seed_override", 382+int(settings.get("foliage_variation",0))))
	if role==1 and not instruction.get("base","")=="original":
		# Reconstruct the live presentation adjustments, keeping catalog values intact.
		settings.merge({"branch_reach":1.2,"branch_rise_degrees":[50.0,55.0,48.0,57.0][item.biome],"branch_curve":0.05,"tree_fork_spread":0.72,"foliage_fullness":1.35}, true)
	elif role!=1 and not generic:
		settings["plant_recursive_depth"]=1+item.size_class
		settings["leaf_scale"]=float(settings.get("leaf_scale",1.0))*pow(0.8,item.size_class)
	if generic and config.get("general_foliage_review",true):
		settings.merge(config.general_foliage_settings, true)
		settings.merge(config.get("biome_foliage_settings",{}).get(row.biome,{}), true)
		# Vary leaf silhouette independently per design, using a saved review seed.
		var random := RandomNumberGenerator.new()
		random.seed=hash(row.plant_id)+10312026
		settings.merge({"leaf_architecture":random.randi_range(1,4),"tip_taper":random.randf_range(0.45,1.5),"leaf_lobes":random.randi_range(1,5),"lobe_depth":random.randf_range(0.08,0.5),"curl":random.randf_range(0.15,0.5)}, true)
	var resolved: Dictionary=config.get("resolved_inputs",{}).get(row.code,{})
	if not resolved.is_empty():
		settings=resolved.settings.duplicate(true)
		seed_value=int(resolved.seed)
	var override: Dictionary = config.overrides.get(row.code,{})
	if not override.is_empty():
		settings.merge(override.settings, true)
		if int(override.seed)>0: seed_value=int(override.seed)
	# JSON numbers are floats; the existing shared builder expects integer counts.
	for key in ["branches","node_count","leaf_architecture","leaf_lobes","frond_pairs","tree_fork_depth","branching_depth","plant_recursive_depth","foliage_variation","crown_habit"]:
		if settings.has(key): settings[key]=int(settings[key])
	var builder = Foliage.new() if generic else Builder.new()
	builder.tube_sides=4
	var sample: Dictionary = builder.create_sample(item.biome,role,seed_value,settings,builder.make_anatomy_materials())
	var body := Node3D.new()
	for mesh in Library.live_meshes(sample,role==1):
		var piece := MeshInstance3D.new()
		piece.mesh=mesh
		piece.scale=Vector3.ONE*float(settings.get("plant_size",1.0))
		body.add_child(piece)
		piece.owner=body
	item.scene=PackedScene.new()
	item.scene.pack(body)
	body.free()
	item.plant_id=original.plant_id+"_review_"+config.revision
	item.plant_id=item.plant_id.replace("-","_")
	# A proposed replacement is a detached draft, never an approved species copy.
	item.catalog_design_id=""
	item.species_id=""
	item.enabled_in_world=false
	item.recipe=settings.duplicate(true)
	item.recipe["roots_below_ground"]=true
	item.set_meta("runtime_palette",false)
	var positions := {}
	item.organ_graph=sample.organs.duplicate(true)
	item.organ_graph.append_array(sample.get("leaf_surfaces",[]))
	for organ: Dictionary in item.organ_graph:
		organ.position*=float(settings.get("plant_size",1.0))
		positions[organ.id]=organ.position
	item.organ_anchors={"ground":positions.ground,"receive":positions.get("intake",positions.get("reservoir_ring",positions.reserve)),"release":positions.get("outlet",positions.get("crown",positions.reserve)),"crown":positions.get("crown",positions.reserve)}
	return {"definition":item,"settings":settings,"seed":seed_value,"sample":sample,"source":original}
