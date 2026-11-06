extends SceneTree
const Builder = preload("res://scripts/scenery/procedural_plant_mesh.gd")
var failures := 0
var checks := 0

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func _initialize() -> void:
	run.call_deferred()

func geometry(mesh: ArrayMesh) -> Array:
	var data := []
	for surface in range(mesh.get_surface_count()):
		var arrays := mesh.surface_get_arrays(surface)
		data.append([arrays[Mesh.ARRAY_VERTEX],arrays[Mesh.ARRAY_TEX_UV],arrays[Mesh.ARRAY_NORMAL]])
	return data

func run() -> void:
	var lab: Control = load("res://scenes/development_workstation.tscn").instantiate()
	root.add_child(lab)
	lab.picker.select(lab.FIXTURES.keys().find("Plants / procedural forms"))
	lab.load_fixture()
	check(lab.viewport.own_world_3d,"Plant review uses isolated world")
	check(lab.fixture.specimens.size() == 24,"All growth forms have three seed variants")
	var settings := {"branches":8,"foliage":1.0,"leaf_scale":1.0,"curl":0.35}
	var materials: Array[Material] = lab.fixture.materials
	for family in range(8):
		var builder := Builder.new()
		var first := builder.create(family,730000+family,settings,materials)
		var repeat := builder.create(family,730000+family,settings,materials)
		var different := builder.create(family,740000+family,settings,materials)
		check(geometry(first) == geometry(repeat),"Same seed reconstructs exact geometry: %d" % family)
		check(geometry(first) != geometry(different),"Seed changes specimen: %d" % family)
		for profile in [{"branches":3,"foliage":0.4,"leaf_scale":0.5,"curl":0.0},{"branches":14,"foliage":1.8,"leaf_scale":1.6,"curl":1.0}]:
			var mesh := builder.create(family,11,profile,materials)
			var bounds := mesh.get_aabb()
			check(bounds.position.is_finite() and bounds.size.is_finite() and bounds.size.y > 0,"Finite nonempty geometry at tuning limits: %d" % family)
			check(builder.counts.reduce(func(sum: int,n: int): return sum+n,0) < 120000,"Specimen remains within lab geometry budget: %d" % family)
	lab.fixture.family_picker.select(4)
	lab.fixture.select_family(4)
	var visible := 0
	for bed in lab.fixture.samples.get_children():
		if bed.visible: visible += 1
	check(visible == 1,"Family selector isolates one bed")
	var sliders := 0
	for node in lab.descendants(lab.parameter_box):
		if node is HSlider: sliders += 1
	check(sliders >= 7,"Numeric tuning exposed as workstation sliders")
	var old_seed: int = lab.fixture.generation_seed
	var seed_button: Button = lab.find_child("SeedVariations",true,false)
	seed_button.pressed.emit()
	await process_frame
	await process_frame
	check(lab.fixture.generation_seed == old_seed+1,"New seed button updates the hosted fixture")
	lab.overrides["generation_seed"] = 74
	lab.overrides["branch_count"] = 10
	lab.load_fixture()
	check(lab.fixture.generation_seed == 74 and lab.fixture.branch_count == 10,"Workstation rebuild applies tuning")
	lab.set_paused(true)
	check(lab.fixture.process_mode == Node.PROCESS_MODE_DISABLED,"Workstation pause freezes plant wind clock")
	check(lab.report().readings.specimens.size() == 24,"Capture report includes specimen measurements")
	lab.picker.select(0)
	lab.overrides.clear()
	lab.load_fixture()
	check(lab.viewport.msaa_3d == Viewport.MSAA_DISABLED,"Leaving plant fixture restores viewport anti-aliasing")
	lab.free()
	await process_frame
	print("PROCEDURAL PLANTS: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
