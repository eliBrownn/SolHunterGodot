extends SceneTree
const Community = preload("res://scripts/world/plant_community.gd")
var checks := 0
var failures := 0

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)

func site(cell: Vector2i) -> Dictionary:
	return {"admitted":absi(cell.x)>2,"wetness":0.7,"height":0.0}

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var layout := Community.new()
	var accepted := {}
	for habitat in range(4):
		layout.configure(73,10,0.9,4,0.65,habitat)
		accepted.clear()
		for y in range(-12,12):
			for x in range(-12,12):
				var cell := Vector2i(x,y)
				var row := layout.sample(cell,site)
				if not row.is_empty():
					accepted[cell] = row
					check(absf(x+0.5)-float(row.radius)>2.0,"Full footprint stays off protected strip")
		check(not accepted.is_empty(),"Habitat produces plants")
		layout.clear_cache()
		for y in range(11,-13,-1):
			for x in range(11,-13,-1):
				var cell := Vector2i(x,y)
				check(layout.sample(cell,site)==accepted.get(cell,{}),"Reverse query order and cache reconstruction preserve placement")
		for cell: Vector2i in accepted:
			for other: Vector2i in accepted:
				if cell == other or accepted[cell].tree != accepted[other].tree: continue
				check(Vector2(cell).distance_to(Vector2(other))>=float(accepted[cell].radius)+float(accepted[other].radius),"Accepted same-layer footprints do not overlap")
	var fixture: Node3D = load("res://scenes/plant_community_lab.tscn").instantiate()
	root.add_child(fixture)
	check(fixture.readings.size()==2,"Both comparison beds are built")
	check(fixture.readings[1].shared_bodies<=2,"Geometry palette stays bounded")
	fixture.free()
	layout.configure(73,10,0.0,2,0.65,1)
	check(layout.sample(Vector2i(-8,-8),site).is_empty(),"Zero coverage is empty")
	Engine.set_meta("workstation_session_path","res://artifacts/plant-communities/test-workspace.cfg")
	var host: Control = load("res://scenes/development_workstation.tscn").instantiate()
	root.add_child(host)
	host.picker.select(host.FIXTURES.keys().find("Plants / communities"))
	host.load_fixture()
	for key in ["patch_size","coverage","spacing","canopy_influence","generation_seed"]:
		check(host.parameter_box.find_child(key+"Slider",true,false) is HSlider,"Usable slider for "+key)
	host.apply_parameter("spacing",3.0)
	for frame in range(2): await process_frame
	check(is_equal_approx(host.fixture.spacing,3.0),"Shared controls rebuild the connected setting")
	host.queue_free()
	for frame in range(3): await process_frame
	print("PLANT COMMUNITY: %d checks, %d failures"%[checks,failures])
	quit(1 if failures else 0)
