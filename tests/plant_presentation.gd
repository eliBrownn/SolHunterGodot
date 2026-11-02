extends "res://tests/plant_diversity.gd"
## Live presentation must preserve ecological identity and fit the shared terrain.

class SlopeTerrain extends FlatTerrain:
	var slope := 0.18
	func surface_height(point: Vector2) -> float: return (point.x-60.5)*slope
	func surface_normal(_point: Vector2) -> Vector3: return Vector3(-slope,1,0).normalized()

func run() -> void:
	var original_sources: Array[String] = Library.sources.duplicate()
	var path := "res://artifacts/plant-presentation/empty-library.json"
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file := FileAccess.open(path,FileAccess.WRITE)
	file.store_string('{"version":1,"plants":[]}')
	file.close()
	Library.refresh([path])
	var terrain := SlopeTerrain.new(18)
	var at := Vector2i(60,60)
	terrain.kind="plant"
	while FloraTraits.role(terrain.world_seed,{"id":FloraCatalog.id_for(at),"cell":[at.x,at.y],"kind":"plant"})!="receiver": at.y+=1
	for biome in range(4):
		terrain.biome=biome
		for role in ["reservoir","warden","mender","regulator"]:
			var traits := {"role":"reservoir" if role=="reservoir" else "receiver","class":"" if role=="reservoir" else role}
			for variant in range(3):
				var item: Resource=Library.procedural_definition(biome,traits,variant)
				check(item.valid(),"Refined palette definitions validate")
				check(item.recipe.leaf_architecture==0 and item.recipe.foliage_palette==0,"Live leaves retain their habitat structure and pigment family")
				var parts: Dictionary=Library.model(item)
				check(parts.triangles<=30000 and parts.surfaces<=12,"Habitat-specific body budget: %s, %d triangles, %d surfaces"%[item.plant_id,parts.triangles,parts.surfaces])
				var box: AABB=parts.bounds
				var scaled: Vector3=box.size*item.scale_for(box)*(1.0+Library.MAX_INSTANCE_VARIATION)
				check(scaled.y<=Library.maximum_height()+0.001 and maxf(scaled.x,scaled.z)<=Library.maximum_width()+0.001,"Visibility bounds include maximum instance variation")
		var data := terrain.sample(at)
		var record: Dictionary=Library.placement(terrain,at,data,"plant",true)
		check(not record.is_empty(),"Functional plants admit on a gentle slope")
		if record.is_empty(): continue
		check(record.transform.basis.y.normalized().is_equal_approx(Vector3.UP),"Ground growth remains upright on slopes")
		check(record.flora_id==FloraCatalog.id_for(at) and record.vastra_anchor.is_finite(),"Fitting preserves the canonical owner and organ anchor")
		check(record==Library.placement(terrain,at,data,"plant",true),"Re-querying a cell reconstructs its exact placement")
		var unvaried: Dictionary=Library.placement(terrain,at,data,"plant",true,0.0)
		var ratio: float=record.transform.basis.y.length()/unvaried.transform.basis.y.length()
		check(ratio>=0.88 and ratio<=1.12 and not is_equal_approx(ratio,1.0),"Per-cell variation is bounded and the zero control disables it")
		terrain.blocked=true
		check(Library.placement(terrain,at,data,"plant",true).is_empty(),"Full-footprint protected access remains mandatory")
		terrain.blocked=false
		terrain.kind="tree"
		var tree: Dictionary=Library.placement(terrain,at,data,"tree",true)
		check(not tree.is_empty() and tree.transform.basis.y.normalized().is_equal_approx(Vector3.UP),"Reservoir trunks remain upright on slopes")
		terrain.kind="plant"
	terrain.slope=tan(deg_to_rad(34.0))
	var hillside := Library.placement(terrain,at,terrain.sample(at),"plant",true)
	check(not hillside.is_empty(),"Plants admit on traversable hillsides")
	if not hillside.is_empty():
		check(absf(hillside.vastra_organs.ground.position.y-terrain.surface_height(Vector2(at)+Vector2(0.5,0.5)))<0.2,"Soil anchor meets terrain without burying the body")
	terrain.slope=0.8
	check(Library.placement(terrain,at,terrain.sample(at),"plant",true).is_empty(),"Steep terrain still rejects placement")
	var small_tree: Resource=Library.procedural_definition(1,{"role":"reservoir","class":""},0)
	var large_tree: Resource=Library.procedural_definition(1,{"role":"reservoir","class":""},2)
	check(large_tree.world_height>10.0 and large_tree.world_height>small_tree.world_height*4.0,"Tree palette retains saplings and towering mature sizes")
	check(large_tree.recipe.branches>small_tree.recipe.branches and large_tree.recipe.tree_fork_depth>small_tree.recipe.tree_fork_depth,"Larger trees grow more scaffold branches and forks")
	check(large_tree.recipe.tree_fork_depth>=3 and large_tree.recipe.leaf_scale<small_tree.recipe.leaf_scale and large_tree.recipe.stem_thickness<small_tree.recipe.stem_thickness,"Mature trees gain recursive generations while leaf and trunk scale stay restrained")
	var small_forks := 0
	var large_forks := 0
	for organ: Dictionary in small_tree.organ_graph:
		if "_fork" in organ.id: small_forks+=1
	for organ: Dictionary in large_tree.organ_graph:
		if "_fork" in organ.id: large_forks+=1
	check(large_forks>small_forks*3,"Mature geometry actually contains more recursive offshoots")
	var mature_plant: Resource=Library.procedural_definition(1,{"role":"receiver","class":"mender"},2)
	var shoots := 0
	for organ: Dictionary in mature_plant.organ_graph:
		if "_fork" in organ.id: shoots+=1
	check(shoots>10 and mature_plant.recipe.leaf_scale<1.0,"Mature plants develop recursive shoots with restrained leaf size")
	check(is_equal_approx(mature_plant.root_burial,0.06),"Root collars sit slightly beneath the terrain plane")
	var foliage_peak := 0
	for biome in range(4):
		for variation in range(5):
			var cover: Resource=Library.foliage_definition(biome,variation,"emanator")
			var art: Dictionary=Library.model(cover)
			foliage_peak=maxi(foliage_peak,art.triangles)
			check(art.triangles<=30000 and art.surfaces<=12,"Recursive ground cover stays within live mesh budgets")
	print("Recursive foliage peak triangles: ",foliage_peak)
	var alternative: Resource=Library.procedural_definition(1,{"role":"reservoir","class":""},3)
	check(alternative.size_class==small_tree.size_class and alternative.recipe.trunk_lean!=small_tree.recipe.trunk_lean,"Each biome retains distinct trunk silhouettes within the same size class")
	check(large_tree.preserve_proportions,"Mature trees preserve uniform fitting")
	var ring: Dictionary=large_tree.organ_graph.filter(func(organ: Dictionary) -> bool: return organ.id=="reservoir_ring")[0]
	check(ring.parent=="trunk_joint0" and ring.position.is_equal_approx(large_tree.organ_anchors.receive),"Tree reservoir ring wraps the first branching junction and owns the intake anchor")
	check(large_tree.world_height<18.0,"Mature trees stay within the reduced scale range")
	var junction: Dictionary=large_tree.organ_graph.filter(func(organ: Dictionary) -> bool: return organ.id=="trunk_joint0")[0]
	var crown_at: Vector3=large_tree.organ_anchors.crown
	check(junction.position.y>crown_at.y*0.4 and junction.position.y<crown_at.y*0.65,"Woodland branching retains a realistic clear lower bole")
	var tree_peak := 0
	for habitat in range(4):
		for variant in range(3,9):
			var extra: Resource=Library.procedural_definition(habitat,{"role":"reservoir","class":""},variant)
			var extra_art: Dictionary=Library.model(extra)
			tree_peak=maxi(tree_peak,extra_art.triangles)
			check(extra.valid() and extra_art.triangles<=30000,"Additional biome silhouettes retain live model budgets")
			check(extra.recipe.spread_ratio>=0.94 and extra.recipe.spread_ratio<=1.37 and extra.recipe.branch_rise_degrees>=42.0 and extra.recipe.branch_rise_degrees<=62.0,"Crown generation avoids both splayed and pinched extremes")
	print("Additional tree silhouette peak triangles: ",tree_peak)
	for tissue: Material in Builder.make_anatomy_materials():
		if tissue is StandardMaterial3D:
			check(tissue.albedo_texture!=null and tissue.normal_texture!=null,"Plant organs carry matching color and normal textures")
	for habitat in range(4):
		var habit: Resource=Library.procedural_definition(habitat,{"role":"reservoir","class":""},1)
		check(habit.recipe.branch_rise_degrees>=30.0 and habit.recipe.branch_rise_degrees<=78.0,"Tree spread stays within its biome habit")
	var cover_peak := 0
	for habitat in range(4):
		for variation in range(5):
			var cover: Resource=Library.foliage_definition(habitat,variation,"emanator",true)
			var art: Dictionary=Library.model(cover)
			cover_peak=maxi(cover_peak,art.triangles)
			check(cover.valid() and art.triangles<=2500,"Ground-cover foliage uses a bounded lightweight mesh")
			check(art.surfaces==1 and art.triangles<=54,"Leaf grass emits only a lightweight leaf surface")
			for piece: Dictionary in art.pieces:
				var material: ShaderMaterial=piece.mesh.surface_get_material(0)
				check(not material.get_shader_parameter("bark_surface") and not material.get_shader_parameter("vastra_surface"),"Grass exposes leaves without shrub bark or organs")
	print("Ground-cover foliage peak triangles: ",cover_peak)
	var settings := NatureSettings.new()
	settings.plant_instance_variation=NAN
	check(not settings.valid(),"Nonfinite variation is rejected")
	settings.plant_instance_variation=0.26
	check(not settings.valid(),"Excessive variation is rejected")
	Library.refresh(original_sources)
	print("PLANT PRESENTATION: %d checks, %d failures"%[checks,failures])
	quit(1 if failures else 0)
