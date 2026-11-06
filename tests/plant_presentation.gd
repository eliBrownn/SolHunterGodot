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
				check(parts.triangles<=30000 and parts.surfaces<=12,"Habitat-specific bodies retain runtime budgets")
				var box: AABB=parts.bounds
				var scaled: Vector3=box.size*item.scale_for(box)*(1.0+Library.MAX_INSTANCE_VARIATION)
				check(scaled.y<=Library.maximum_height() and maxf(scaled.x,scaled.z)<=Library.maximum_width(),"Visibility bounds include maximum instance variation")
		var data := terrain.sample(at)
		var record: Dictionary=Library.placement(terrain,at,data,"plant",true)
		check(not record.is_empty(),"Functional plants admit on a gentle slope")
		if record.is_empty(): continue
		check(record.transform.basis.y.normalized().is_equal_approx(terrain.surface_normal(Vector2(at))),"Ground growth follows the local surface normal")
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
	terrain.slope=0.5
	check(Library.placement(terrain,at,terrain.sample(at),"plant",true).is_empty(),"Steep terrain still rejects placement")
	var settings := NatureSettings.new()
	settings.plant_instance_variation=NAN
	check(not settings.valid(),"Nonfinite variation is rejected")
	settings.plant_instance_variation=0.26
	check(not settings.valid(),"Excessive variation is rejected")
	Library.refresh(original_sources)
	print("PLANT PRESENTATION: %d checks, %d failures"%[checks,failures])
	quit(1 if failures else 0)
