extends SceneTree
const Library = preload("res://scripts/scenery/plant_library.gd")
const Definition = preload("res://scripts/scenery/plant_definition.gd")
const Store = preload("res://tools/plant_maker_store.gd")
const Chunk = preload("res://scripts/presentation/solid_chunk.gd")
var checks := 0
var failures := 0

class FlatTerrain extends WorldTerrain:
	var blocked := {}
	var kind := "plant"
	func sample(cell: Vector2i) -> Dictionary:
		return {"ground":0,"obstacle":1 if kind=="tree" and cell==Vector2i(60,60) else 0,"walkable":kind!="tree" or cell!=Vector2i(60,60)}
	func flora_kind(_cell: Vector2i,_data: Dictionary) -> String: return kind
	func scenery_reserved(cell: Vector2i) -> bool: return blocked.has(cell)
	func route_axes(_cell: Vector2i,_margin: int=0) -> int: return 0
	func is_camp(_cell: Vector2i) -> bool: return false
	func is_landmark(_cell: Vector2i) -> bool: return false
	func surface_height(_point: Vector2) -> float: return 0.0
	func surface_normal(_point: Vector2) -> Vector3: return Vector3.UP

func check(condition: bool,message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func _initialize() -> void:
	create_timer(90).timeout.connect(func(): quit(1))
	run.call_deferred()

func run() -> void:
	var library_root := "res://artifacts/plant-maker/test_"+str(Time.get_ticks_usec())
	DirAccess.make_dir_recursive_absolute(library_root)
	var manifest := FileAccess.open(library_root+"/library.json",FileAccess.WRITE)
	manifest.store_string('{"version":1,"plants":[]}')
	manifest.close()
	var original_sources: Array[String] = Library.sources.duplicate()
	Library.refresh([library_root+"/library.json"])
	Engine.set_meta("workstation_session_path",library_root+"/workspace.cfg")
	var lab: Control = load("res://scenes/development_workstation.tscn").instantiate()
	root.add_child(lab)
	lab.picker.select(lab.FIXTURES.keys().find("Plants / maker & library"))
	lab.overrides.clear()
	lab.load_fixture()
	var maker: Node3D = lab.fixture
	maker.save_root=library_root
	check(maker.selected_biome==0 and maker.selected_role==0 and maker.specimens.size()==24,"Editor starts with every biome and plant form")
	check(maker.scale_reference.visible and is_equal_approx(maker.reference_height,1.8),"Common-scale overview includes a standing reference")
	var view = lab.station_tools
	var original_view: Dictionary = view.snapshot_camera()
	view.orbit_distance=304.4
	view.camera.far=10.0
	view.camera_active=true
	view.update_camera()
	check(view.camera.far>view.orbit_distance,"Orbit controls keep distant plant previews inside the clipping range")
	var distant_view: Dictionary = view.snapshot_camera()
	view.camera.far=10.0
	view.restore_camera(distant_view)
	check(view.camera.far>view.orbit_distance,"Restoring a distant saved plant view repairs its clipping range")
	view.camera.far=10.0
	view._process(0.0)
	check(view.camera.far>view.orbit_distance,"Active view survives fixture clipping-range updates")
	view.restore_camera(original_view)
	var tree_height:=0.0
	var low_height:=0.0
	for bed: Dictionary in maker.beds:
		if bed.role_index==1: tree_height=maxf(tree_height,bed.bounds.size.y*maker.plant_size)
		else: low_height=maxf(low_height,bed.bounds.size.y*maker.plant_size)
	check(tree_height>low_height*4.0,"Overview keeps trees and small plants at comparative game sizes")
	check(maker.scene_layout==0 and maker.biome_stages.get_child_count()==12,"Default viewer uses four biome patches, titles and ordinary-foliage groups")
	var ordinary_count:=0
	var specialist_count:=0
	for group: Node in maker.biome_stages.get_children():
		if group.name.begins_with("CommonUnderstory"): ordinary_count+=group.get_child_count()
	for bed: Dictionary in maker.beds:
		if bed.node.visible and bed.role_index>=3: specialist_count+=1
	check(ordinary_count>specialist_count,"Natural scenes are dominated by ordinary foliage")
	maker.preview_specialist_percent=0
	maker.refresh_view()
	for bed: Dictionary in maker.beds:
		if bed.role_index>=3: check(not bed.node.visible,"A natural area may contain no specialist class")
	maker.scene_layout=2
	maker.refresh_view()
	var all_visible:=0
	for bed: Dictionary in maker.beds:
		if bed.node.visible: all_visible+=1
	check(all_visible==24,"The explicit all-design collection still exposes every editable form")
	maker.scene_layout=0
	maker.preview_specialist_percent=5
	maker.refresh_view()
	for bed: Dictionary in maker.beds:
		check(not bed.node.find_child("SampleGround",true,false).visible,"Scene layout hides isolated specimen pots")
	maker.scene_layout=1
	maker.refresh_view()
	check(not maker.biome_stages.visible,"Plant grid remains available")
	maker.scene_layout=0
	maker.refresh_view()
	check(maker.draft_button.disabled and maker.publish_button.disabled,"Overview cannot accidentally publish an ambiguous plant")
	check(Store.save_plant(maker,"Overview",false,library_root).has("error"),"Store rejects multi-specimen saves before writing")
	maker.biome_picker.select(1)
	maker.role_picker.select(1)
	maker.refresh_view()
	check(maker.specimens.size()==1 and not maker.draft_button.disabled,"Focused editing enables one valid save")
	maker.size_class=2
	check(maker.size_class_range().x>=0.8,"Large class has a useful ordinary-plant range")
	check(maker.specimens.size()==1,"Maker generates only the selected plant")
	check(Store.save_plant(maker,"",true,library_root).has("error"),"Empty names cannot publish an asset")
	maker.name_edit.text="Test amber fan"
	var draft: Dictionary = maker.save_current(false)
	check(not draft.has("error"),"Save draft bakes a native scene and editable definition")
	if draft.has("error"):
		lab.free()
		Library.refresh(original_sources)
		quit(1)
		return
	check(draft.definition.size_class==2,"Saved plant retains its physical size class")
	check(draft.definition.valid() and not draft.definition.enabled_in_world,"Draft is a validated asset without world activation")
	check(FileAccess.file_exists(draft.scene) and FileAccess.file_exists(draft.path),"Scene and recipe are saved on disk")
	var instance: Node3D = load(draft.scene).instantiate()
	check(instance.find_child("ScaleReference",true,false)==null,"Reference figure and ruler are excluded from game assets")
	check(instance.get_script()==null and instance.get_child_count()==2,"Saved scene has no maker UI, lab scripts or ground pedestal")
	check(instance.get_child(0) is MeshInstance3D and instance.get_child(1) is MeshInstance3D,"Saved scene contains real generated meshes")
	instance.free()
	maker.world_frequency=100
	var published: Dictionary = maker.save_current(true)
	check(not published.has("error") and published.id==draft.id,"Updating publishes a new revision under the same plant identity")
	check(FileAccess.file_exists(draft.path) and published.path!=draft.path,"Earlier saved revision is preserved")
	check(Library.all().size()==1 and Library.all()[0].enabled_in_world,"Library index points to one enabled current revision")
	var terrain := FlatTerrain.new(18)
	var cell := Vector2i(60,60)
	while FloraTraits.role(terrain.world_seed,{"id":FloraCatalog.id_for(cell),"cell":[cell.x,cell.y],"kind":"plant"})!="emanator": cell.x+=1
	var record := Library.placement(terrain,cell,terrain.sample(cell),"plant")
	check(not record.is_empty(),"Enabled plant is selected for a matching canonical biome/role cell")
	if not record.is_empty():
		var chunk := Chunk.new()
		chunk.cell_origin=Vector2i.ZERO
		var nature := NatureSettings.new()
		nature.meadow_enabled=true
		Library.add_cell(chunk,terrain,cell,terrain.sample(cell),nature)
		check(not chunk.batches.keys().any(func(key): return str(key).begins_with("nature_detail_meadow")),"Authored emanator replaces built-in grass instead of layering a second body")
		check(chunk.living_sources.size()==1 and chunk.living_sources[cell].flora_id==FloraCatalog.id_for(cell),"Game rendering registers exactly the existing canonical flora identity")
		check(chunk.living_sources[cell].anchor.is_equal_approx(record.vastra_anchor),"Plant's authored receiving organ supplies the functional anchor")
		chunk.free()
	terrain.blocked[cell]=true
	check(Library.placement(terrain,cell,terrain.sample(cell),"plant").is_empty(),"Protected access rejects a saved plant")
	terrain.blocked.clear()
	var wrong_biome := terrain.sample(cell)
	wrong_biome.ground=2
	check(Library.placement(terrain,cell,wrong_biome,"plant").is_empty(),"Saved plant respects its authored biome")
	var wrong_role_cell := cell+Vector2i.ONE
	while FloraTraits.role(terrain.world_seed,{"id":FloraCatalog.id_for(wrong_role_cell),"cell":[wrong_role_cell.x,wrong_role_cell.y],"kind":"plant"})=="emanator": wrong_role_cell.x+=1
	check(Library.placement(terrain,wrong_role_cell,terrain.sample(wrong_role_cell),"plant").is_empty(),"Appearance cannot override a cell's existing specialist role")
	Library.set_weather(Vector2.RIGHT,23.5,0.7)
	var parts: Dictionary = Library.model(Library.all()[0])
	check(parts.pieces[0].mesh.surface_get_material(0).get_shader_parameter("wind_time")==23.5,"Baked materials consume the live weather clock")
	var saved_recipe: Dictionary = published.definition.recipe.duplicate()
	maker.height_ratio=1.7
	maker.load_definition(published.definition)
	await process_frame
	await process_frame
	maker=lab.fixture
	maker.save_root=library_root
	check(maker.selected_biome==saved_recipe.selected_biome and maker.selected_role==saved_recipe.selected_role,"Loaded recipe retains biome and role selectors")
	check(maker.height_ratio==saved_recipe.height_ratio and maker.editing_id==published.id,"Library load restores editable plant settings and identity")
	var biome: int = maker.selected_biome
	var role: int = maker.selected_role
	var before: int = maker.generation_seed
	maker.randomize_plant(927)
	await process_frame
	await process_frame
	maker=lab.fixture
	maker.save_root=library_root
	check(maker.selected_biome==biome and maker.selected_role==role,"Randomizer honors biome and role locks")
	check(maker.generation_seed!=before and maker.specimens.size()==1,"Randomizer rebuilds one mathematical specimen")
	check(maker.editing_id.is_empty(),"Randomizing a saved plant starts a new identity and preserves the official design")
	check(Library.all().any(func(item): return item.plant_id==published.id and item.enabled_in_world),"Official plant remains enabled after rolling a new candidate")
	var randomized: Dictionary = maker.recipe_values()
	maker.load_definition(published.definition)
	await process_frame
	await process_frame
	maker=lab.fixture
	maker.randomize_plant(927)
	await process_frame
	await process_frame
	maker=lab.fixture
	check(maker.recipe_values()==randomized,"Randomizer results are reproducible from the same initial recipe and seed")
	maker.keep_biome=false
	maker.keep_role=false
	maker.randomize_plant(146)
	var expected_biome: int=maker.selected_biome
	var expected_role: int=maker.selected_role
	await process_frame
	await process_frame
	maker=lab.fixture
	maker.save_root=library_root
	check(maker.selected_biome==expected_biome and maker.selected_role==expected_role,"Unlocked randomizer selections survive the workstation rebuild")
	maker.biome_picker.select(1)
	maker.refresh_view()
	# A tree and an unclassed receiver exercise the other authoring-to-runtime roles.
	maker.role_picker.select(2)
	maker.refresh_view()
	maker.save_root=library_root
	maker.editing_id=""
	maker.name_edit.text="Test reservoir"
	maker.world_frequency=100
	# Use the bounded tree recipe; prior random rolls may leave dense shrub settings.
	for key in {"node_count":5,"branch_count":6,"branching_depth":1,"foliage_fullness":1.5,"foliage_density":1.25}:
		maker.set(key,{"node_count":5,"branch_count":6,"branching_depth":1,"foliage_fullness":1.5,"foliage_density":1.25}[key])
	maker.rebuild_maker()
	var tree: Dictionary = maker.save_current(true)
	check(not tree.has("error") and tree.definition.circulation_role=="reservoir","Reservoir saves as an eligible tree asset: "+str(tree.get("error","ok")))
	terrain.kind="tree"
	var tree_record := Library.placement(terrain,Vector2i(60,60),terrain.sample(Vector2i(60,60)),"tree")
	check(not tree_record.is_empty() and tree_record.category=="tree" and tree_record.high_anchor.is_finite(),"Tree replacement retains tree category and authored crown anchor")
	maker.role_picker.select(3)
	maker.refresh_view()
	maker.editing_id=""
	maker.name_edit.text="Test receiver"
	maker.receiver_class=2
	var receiver: Dictionary = maker.save_current(true)
	check(not receiver.has("error") and receiver.definition.circulation_role=="receiver" and receiver.definition.specialist_class=="regulator","Generic receiver form gets an explicit existing specialist class before world use")
	var invalid = receiver.definition.duplicate()
	invalid.world_height=NAN
	check(not invalid.valid(),"Corrupt physical dimensions are rejected")
	invalid=receiver.definition.duplicate(true)
	invalid.recipe.height_ratio=NAN
	check(not invalid.valid(),"Corrupt generator values cannot reenter the maker")
	lab.free()
	Library.refresh(original_sources)
	await process_frame
	print("PLANT MAKER: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)

