extends SceneTree
const Builder = preload("res://scripts/scenery/generic_foliage_mesh.gd")
const Library = preload("res://scripts/scenery/plant_library.gd")
const Store = preload("res://tools/plant_maker_store.gd")
var checks := 0
var failures := 0

func check(condition: bool, message: String) -> void:
	checks+=1
	if not condition:
		failures+=1
		push_error(message)

func signature(mesh: ArrayMesh) -> int:
	var arrays := []
	for surface in range(mesh.get_surface_count()): arrays.append(mesh.surface_get_arrays(surface))
	return hash(arrays)

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var builder := Builder.new()
	var materials := builder.make_anatomy_materials()
	var identities := {}
	for biome in range(4):
		var shapes := {}
		for variation in range(5):
			var settings := {"foliage_variation":variation,"branches":7}
			var sample := builder.create_sample(biome,2,71,settings,materials)
			var repeated := builder.create_sample(biome,2,71,settings,materials)
			check(signature(sample.body)==signature(repeated.body) and signature(sample.anatomy)==signature(repeated.anatomy),"Exact seeded reconstruction")
			shapes[signature(sample.body)]=true
			var changed := builder.create_sample(biome,2,72,settings,materials)
			check(signature(sample.body)!=signature(changed.body),"Individuals differ within a form")
			check(sample["class"].is_empty() and sample.growth_category=="generic_foliage","No specialist class")
			for density: float in [0.0,2.0]:
				var extreme := builder.create_sample(biome,2,71,{"foliage_variation":variation,"branches":14,"foliage":1.8,"foliage_fullness":density,"leaf_scale":12.0},materials)
				check(extreme.vertices>0 and extreme.vertices<60000,"Bounded geometry at fullness and leaf-size limits")
			var reached := {"ground":true}
			var anchors := {}
			for organ: Dictionary in sample.organs: anchors[organ.id]=organ.position
			for link: Dictionary in sample.links:
				check(reached.has(link.from),"Anatomy remains rooted")
				check(link.path[0]==anchors[link.from] and link.path.back()==anchors[link.to],"Conductors end at their organs")
				reached[link.to]=true
			check(reached.size()==sample.organs.size(),"All organs connected")
			for mesh: ArrayMesh in [sample.body,sample.anatomy]:
				var finite := true
				for surface in range(mesh.get_surface_count()):
					for point: Vector3 in mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]: finite=finite and point.is_finite()
				check(finite,"Finite geometry")
			var item: Resource=Library.foliage_definition(biome,variation)
			check(item.valid() and not item.enabled_in_world,"Reusable draft definition")
			check(not identities.has(item.plant_id),"Unique identity")
			identities[item.plant_id]=true
			var model := Library.model(item)
			check(model.supported and model.triangles<=30000 and model.surfaces<=12,"Runtime geometry budget")
			item.enabled_in_world=true
			check(not item.valid(),"Draft cannot silently enter the expedition")
			item.enabled_in_world=false
		check(shapes.size()==5,"Five structural silhouettes per habitat")
	var maker: Node3D=load("res://scenes/plant_maker.tscn").instantiate()
	maker.growth_category=1
	maker.selected_biome=2
	maker.foliage_variation=3
	root.add_child(maker)
	check(maker.specimens.size()==1 and maker.specimens[0].growth_plan=="Arching stems","Maker selects foliage builder")
	check(maker.role_picker.disabled and maker.publish_button.disabled,"Draft-only controls")
	var directory := "res://artifacts/generic-foliage/test_"+str(Time.get_ticks_usec())
	var saved: Dictionary=Store.save_plant(maker,"Woodland arch",false,directory)
	check(not saved.has("error"),"Foliage draft saves")
	if saved.has("definition"):
		var item: Resource=ResourceLoader.load(saved.path,"",ResourceLoader.CACHE_MODE_IGNORE)
		check(item.valid() and item.growth_category=="generic_foliage" and item.specialist_class.is_empty(),"Saved category and class survive reload")
		check(int(item.recipe.foliage_variation)==3,"Variation survives save")
		maker.foliage_variation=0
		maker.load_definition(item)
		check(maker.foliage_variation==3 and maker.specimens[0].growth_plan=="Arching stems","Maker reload restores form")
	check(Store.save_plant(maker,"Forbidden live foliage",true,directory).has("error"),"Store blocks live admission")
	maker.load_definition(Library.foliage_definition(1,0))
	var palette_scene: Node3D=Library.foliage_definition(1,0).scene.instantiate()
	check(signature(palette_scene.get_child(0).mesh)==signature(maker.beds[0].node.find_child("OuterGrowth",true,false).mesh),"Library recipe reconstructs its baked body in the maker")
	palette_scene.free()
	var legacy: Resource=Library.procedural_definition(0,{"role":"reservoir","class":""},0)
	maker.load_definition(legacy)
	check(maker.growth_category==0,"Loading an older role recipe clears foliage mode")
	maker.review_all_foliage()
	check(maker.specimens.size()==20 and maker.beds.size()==20,"Review opens all twenty designs")
	var positions := {}
	var forms := {}
	for bed: Dictionary in maker.beds:
		positions[bed.node.position]=true
		forms[Vector2i(bed.biome,bed.variation)]=true
	check(positions.size()==20 and forms.size()==20,"All twenty forms have separate review positions")
	check(maker.draft_button.disabled and maker.publish_button.disabled,"Comparison cannot save an ambiguous specimen")
	maker.biome_picker.select(2)
	maker.refresh_view()
	check(maker.specimens.size()==5 and maker.foliage_picker.item_count==6,"Biome comparison shows five forms and named selectors")
	check(maker.foliage_picker.get_item_text(1)=="Divided frond","Variation selector uses habitat form names")
	maker.foliage_picker.select(3)
	maker.foliage_picker.item_selected.emit(3)
	check(maker.specimens.size()==1 and maker.specimens[0].growth_plan=="Hanging folds" and not maker.draft_button.disabled,"Named selector focuses one editable draft")
	var before := signature(maker.beds[0].node.find_child("OuterGrowth",true,false).mesh)
	maker.foliage_fullness=2.0
	maker.rebuild_maker()
	check(signature(maker.beds[0].node.find_child("OuterGrowth",true,false).mesh)!=before,"Fullness tuning changes the selected geometry")
	maker.cutaway=true
	maker.silhouette_view=true
	maker.rebuild_maker()
	check(not maker.beds[0].node.find_child("OuterGrowth",true,false).visible,"Cutaway survives preview rebuild")
	check(maker.beds[0].node.find_child("ConnectedVastraAnatomy",true,false).material_override!=null,"Silhouette applies after preview rebuild")
	maker.foliage_picker.select(0)
	maker.foliage_picker.item_selected.emit(0)
	check(maker.specimens.size()==5 and maker.beds[4].node.find_child("ConnectedVastraAnatomy",true,false).material_override!=null,"Comparison preserves silhouette and anatomy review")
	maker.load_definition(Library.foliage_definition(1,0))
	check(not maker.compare_foliage_variations and maker.specimens.size()==1,"Loading a draft exits comparison")
	maker.free()
	print("GENERIC FOLIAGE: %d checks, %d failures"%[checks,failures])
	quit(1 if failures else 0)
