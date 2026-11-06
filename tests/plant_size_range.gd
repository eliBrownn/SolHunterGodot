extends SceneTree
const Library=preload("res://scripts/scenery/plant_library.gd")
const Definition=preload("res://scripts/scenery/plant_definition.gd")
const MakerTests=preload("res://tests/plant_maker.gd")
var failures:=0
var checks:=0
func _initialize() -> void:
	create_timer(90).timeout.connect(func(): quit(1))
	run.call_deferred()
func check(condition: bool,message: String) -> void:
	checks+=1
	if not condition:
		failures+=1
		push_error(message)
func run() -> void:
	var folder:="res://artifacts/plant-size/test_"+str(Time.get_ticks_usec())
	DirAccess.make_dir_recursive_absolute(folder)
	var file:=FileAccess.open(folder+"/library.json",FileAccess.WRITE)
	file.store_string('{"version":1,"plants":[]}')
	file.close()
	var original: Array[String]=Library.sources.duplicate()
	Library.refresh([folder+"/library.json"])
	var maker: Node3D=load("res://scenes/plant_maker.tscn").instantiate()
	maker.selected_biome=1
	maker.selected_role=1
	root.add_child(maker)
	maker.show_scale_reference=false
	maker.preview_event=0
	maker.preserve_proportions=false
	for dimensions in [Vector2(0.02,0.02),Vector2(20,0.5),Vector2(4,12)]:
		maker.world_height=dimensions.x
		maker.world_width=dimensions.y
		maker.rebuild_maker()
		var size: Vector3=maker.beds[0].bounds.size*maker.plant_size
		check(is_equal_approx(maker.beds[0].bounds.end.y*maker.plant_size,dimensions.x),"Preview reaches requested above-ground height")
		check(is_equal_approx(maxf(size.x,size.z),dimensions.y),"Height and width adjust independently")
		check(maker.camera.position.is_finite() and maker.camera.far>maker.distance_value,"Camera supports size extremes")
		if dimensions.x==0.02: check(maker.distance_value<1 and maker.camera.near<0.01,"Tiny plants support close inspection")
	maker.world_height=20
	maker.world_width=0.5
	maker.world_frequency=100
	maker.rebuild_maker()
	maker.save_root=folder
	maker.name_edit.text="Size range fixture"
	var saved: Dictionary=maker.save_current(true)
	check(not saved.has("error"),"Large plant publishes without the old cap")
	if not saved.has("error"):
		var loaded=ResourceLoader.load(saved.path,"",ResourceLoader.CACHE_MODE_IGNORE)
		check(loaded.valid() and loaded.world_height==20 and not loaded.preserve_proportions,"Size survives save/load")
		var terrain=MakerTests.FlatTerrain.new(18)
		var cell:=Vector2i(60,60)
		while FloraTraits.role(terrain.world_seed,{"id":FloraCatalog.id_for(cell),"cell":[cell.x,cell.y],"kind":"plant"})!="emanator": cell.x+=1
		var record: Dictionary=Library.placement(terrain,cell,terrain.sample(cell),"plant")
		check(not record.is_empty(),"Tall ground plant enters a safe matching cell")
		if not record.is_empty(): check(is_equal_approx(record.bounds.end.y,20),"Runtime retains full above-ground plant height with roots buried")
		check(Library.maximum_height()>=20,"Visibility includes enabled tall plants")
		terrain.blocked[cell]=true
		check(Library.placement(terrain,cell,terrain.sample(cell),"plant").is_empty(),"Large plants obey protected access")
		loaded.world_height=0.02
		loaded.world_width=0.02
		check(loaded.valid(),"Smallest dimensions validate")
		loaded.world_height=21
		check(not loaded.valid(),"Out-of-range dimensions reject")
	var box:=AABB(Vector3.ZERO,Vector3(2,4,1))
	var fit:=Definition.new()
	fit.world_height=12
	fit.world_width=3
	check(fit.scale_for(box).is_equal_approx(Vector3.ONE*1.5),"Natural proportions fit uniformly")
	fit.preserve_proportions=false
	check(fit.scale_for(box).is_equal_approx(Vector3(1.5,3,1.5)),"Independent dimensions use separate scales")
	maker.apply_size_preset(6)
	check(maker.world_height==20,"Exceptional preset reaches new limit")
	maker.apply_size_preset(0)
	check(maker.world_height==0.05,"Tiny preset remains available")
	maker.free()
	Library.refresh(original)
	await process_frame
	print("PLANT SIZE RANGE: %d checks, %d failures"%[checks,failures])
	quit(1 if failures else 0)
