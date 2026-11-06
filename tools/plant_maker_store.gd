extends RefCounted
## Append-only plant revisions; publish the manifest only after a successful bake.
const Definition = preload("res://scripts/scenery/plant_definition.gd")
const Library = preload("res://scripts/scenery/plant_library.gd")

static func save_plant(maker: Node3D,display_name: String,enable: bool,root: String,existing_id: String = "") -> Dictionary:
	var species: Dictionary=preload("res://scripts/scenery/plant_species_catalog.gd").get_design(maker.catalog_design_id)
	if not maker.catalog_design_id.is_empty():
		if not preload("res://scripts/scenery/plant_species_catalog.gd").valid_recipe(maker.recipe_values(),maker.catalog_design_id): return {"error":"This variation is outside its official species limits. Restore the preset or customize as a new design."}
		if enable and not species.live_ecology_eligible: return {"error":"This official visual has no live ecological assignment. Save an anatomy draft."}
	if maker.growth_category==1 and maker.generic_circulation==1 and enable: return {"error":"Unclassed receiver foliage remains an anatomy draft. Use the emanator ground-cover role for live foliage."}
	if display_name.strip_edges().is_empty() or display_name.length()>80: return {"error":"Give the plant a name of 1–80 characters."}
	if maker.specimens.size()!=1: return {"error":"Select one biome and one base form before saving."}
	if not (root.begins_with("res://") or root.begins_with("user://")) or ".." in root: return {"error":"Invalid plant library location."}
	var original_meshes: Array[ArrayMesh]=[]
	var original_triangles:=0
	for part_name in ["OuterGrowth","ConnectedVastraAnatomy"]:
		var mesh: ArrayMesh=maker.beds[0].node.find_child(part_name,true,false).mesh
		original_meshes.append(mesh)
		original_triangles+=triangle_count(mesh)
	var export_meshes: Array[ArrayMesh]=original_meshes
	if original_triangles>30000 and not species.is_empty():
		# Rebuild the same connected procedural paths with fewer radial tube faces.
		# Mesh decimation can erase small roots or expose the internal anatomy.
		for sides in [4,3]:
			var builder=maker.create_builder()
			builder.tube_sides=sides
			var sample: Dictionary=builder.create_sample(maker.selected_biome-1,maker.selected_role-1,maker.specimen_seed_override,maker.generation_settings(),builder.make_anatomy_materials())
			if sample.organs!=maker.specimens[0].organs: return {"error":"Runtime geometry changed the anatomical anchors; source preview was preserved."}
			export_meshes=[sample.body,sample.anatomy]
			if triangle_count(sample.body)+triangle_count(sample.anatomy)<=30000: break
		var count:=0
		for mesh in export_meshes: count+=triangle_count(mesh)
		if count>30000: return {"error":"This species needs a separate runtime optimization pass; its approved preview was preserved."}
	var id := existing_id
	if id.is_empty():
		for character in display_name.to_lower():
			if character in "abcdefghijklmnopqrstuvwxyz0123456789": id += character
			elif character in " _-": id += "_"
		id = id.left(45)+"_"+str(Time.get_ticks_usec())
	for character in id:
		if character not in "abcdefghijklmnopqrstuvwxyz0123456789_": return {"error":"Invalid plant identity."}
	var directory := root.path_join(id).path_join("v_"+str(Time.get_unix_time_from_system()).replace(".","_")+"_"+str(Time.get_ticks_usec()))
	if DirAccess.make_dir_recursive_absolute(directory)!=OK: return {"error":"Cannot write the library folder. Use a writable project or personal library."}
	var data: Dictionary = maker.specimens[0]
	var specimen: Node3D = maker.beds[0].node
	var baked := Node3D.new()
	baked.name = "Plant"
	var copied := {}
	var mesh_index:=0
	for part_name in ["OuterGrowth","ConnectedVastraAnatomy"]:
		var mesh: ArrayMesh = export_meshes[mesh_index].duplicate()
		mesh_index+=1
		for surface in range(mesh.get_surface_count()):
			var material: Material = mesh.surface_get_material(surface)
			if not copied.has(material):
				var clone: Material = material.duplicate()
				if clone is ShaderMaterial: clone.set_shader_parameter("wind_time",0.0)
				copied[material] = clone
			mesh.surface_set_material(surface,copied[material])
		var mesh_path := directory.path_join(part_name.to_snake_case()+".res")
		if ResourceSaver.save(mesh,mesh_path)!=OK:
			baked.free()
			return {"error":"Could not save the finished plant mesh."}
		var piece := MeshInstance3D.new()
		piece.name = part_name
		piece.mesh = ResourceLoader.load(mesh_path,"",ResourceLoader.CACHE_MODE_IGNORE)
		piece.scale = Vector3.ONE*maker.plant_size
		baked.add_child(piece)
		piece.owner = baked
	var scene := PackedScene.new()
	var packed := scene.pack(baked)
	baked.free()
	var scene_path := directory.path_join("plant.tscn")
	if packed!=OK or ResourceSaver.save(scene,scene_path)!=OK: return {"error":"Could not save the ready-to-use plant scene."}
	var definition := Definition.new()
	definition.plant_id = id
	definition.catalog_design_id=maker.catalog_design_id
	definition.species_id=maker.species_id
	definition.display_name = display_name.strip_edges()
	definition.scene = load(scene_path)
	definition.growth_category = "generic_foliage" if maker.growth_category==1 else "role_form"
	definition.biome = maker.selected_biome-1
	definition.circulation_role = data.role
	definition.specialist_class = data["class"]
	if definition.growth_category!="generic_foliage" and definition.circulation_role=="receiver" and definition.specialist_class.is_empty() and species.is_empty(): definition.specialist_class = ["warden","mender","regulator"][maker.receiver_class]
	definition.enabled_in_world = enable
	definition.size_class = maker.size_class
	definition.world_height = maker.world_height
	definition.world_width = maker.world_width
	definition.preserve_proportions = maker.preserve_proportions
	definition.frequency_percent = maker.world_frequency
	definition.recipe = maker.recipe_values()
	definition.recipe["roots_below_ground"]=true
	var highest := Vector3.ZERO
	var positions := {}
	for organ: Dictionary in data.organs:
		positions[organ.id] = organ.position*maker.plant_size
		if organ.position.y*maker.plant_size>highest.y: highest = organ.position*maker.plant_size
	definition.organ_graph = data.organs.duplicate(true)
	definition.organ_graph.append_array(data.get("leaf_surfaces", []))
	for organ: Dictionary in definition.organ_graph: organ.position *= maker.plant_size
	definition.organ_anchors = {"ground":positions.ground,"receive":positions.get("intake",positions.reserve),"release":positions.get("outlet",highest),"crown":positions.get("crown",highest)}
	if not definition.valid(): return {"error":"The plant's role, dimensions or anatomy did not pass validation."}
	var parts: Dictionary = preload("res://scripts/scenery/nature_art.gd").parts(definition.scene)
	if not parts.supported or parts.triangles>30000 or parts.surfaces>12: return {"error":"The plant exceeds the runtime geometry limit. Reduce nodes or foliage and save again."}
	var path := directory.path_join("definition.tres")
	if ResourceSaver.save(definition,path)!=OK: return {"error":"Could not save the editable plant definition."}
	definition.take_over_path(path)
	var manifest_path := root.path_join("library.json")
	var paths: Array = []
	if FileAccess.file_exists(manifest_path):
		var previous: Variant = JSON.parse_string(FileAccess.get_file_as_string(manifest_path))
		if not previous is Dictionary or previous.get("version")!=1 or not previous.get("plants") is Array: return {"error":"Existing library index is unreadable; it was preserved."}
		for old_path in previous.plants:
			if not old_path is String: continue
			var old = load(old_path) if ResourceLoader.exists(old_path) else null
			if old is Definition and old.plant_id==id: continue
			paths.append(old_path)
	paths.append(path)
	var temporary := manifest_path+".tmp"
	var file := FileAccess.open(temporary,FileAccess.WRITE)
	if file==null: return {"error":"Could not write the library index."}
	file.store_string(JSON.stringify({"version":1,"plants":paths},"  "))
	file.close()
	var backup := manifest_path+".backup_"+str(Time.get_ticks_usec())
	var existed := FileAccess.file_exists(manifest_path)
	if existed and DirAccess.rename_absolute(manifest_path,backup)!=OK: return {"error":"Could not preserve the previous library index; no update was published."}
	if DirAccess.rename_absolute(temporary,manifest_path)!=OK:
		if existed: DirAccess.rename_absolute(backup,manifest_path)
		return {"error":"Could not publish the library index. The previous index was restored."}
	if manifest_path not in Library.sources: Library.sources.append(manifest_path)
	Library.refresh()
	return {"definition":definition,"path":path,"scene":scene_path,"id":id}

static func triangle_count(mesh: ArrayMesh) -> int:
	var count:=0
	for surface in range(mesh.get_surface_count()):
		var arrays:=mesh.surface_get_arrays(surface)
		var indices: Variant=arrays[Mesh.ARRAY_INDEX]
		count+=(indices.size() if indices!=null and not indices.is_empty() else arrays[Mesh.ARRAY_VERTEX].size())/3
	return count

