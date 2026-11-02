extends SceneTree
var failures := 0
func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)
func _initialize() -> void:
	run.call_deferred()
func run() -> void:
	var prototype = preload("res://tools/grass_blade_preview.gd")
	var shape: ArrayMesh = prototype.blade_mesh(0.045,0.22)
	var vertices: PackedVector3Array = shape.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	check(vertices.size() == 21,"A single connected blade has seven nondegenerate triangles")
	check(is_zero_approx(shape.get_aabb().position.y) and is_equal_approx(shape.get_aabb().end.y,1.0),"Blade root and tip use normalized height")
	var lab: Control = load("res://scenes/development_workstation.tscn").instantiate()
	root.add_child(lab)
	lab.picker.select(lab.FIXTURES.keys().find("Grass / single blades"))
	lab.load_fixture()
	check(lab.fixture.materials.size() == 4,"All four biome samples are present")
	var sliders: Array[Node] = lab.parameter_box.find_children("*Slider","HSlider",true,false)
	check(sliders.size() == 11,"All grass and Vastra numeric settings have sliders")
	var density_slider: HSlider = lab.parameter_box.find_child("blades_per_square_metreSlider",true,false)
	density_slider.drag_started.emit()
	density_slider.value = 150
	check(lab.overrides.blades_per_square_metre == 150,"Slider changes the connected setting")
	density_slider.drag_ended.emit(true)
	await process_frame
	await process_frame
	check(lab.fixture.blades_per_square_metre == 150,"Releasing the slider applies the value")
	lab.overrides["blades_per_square_metre"] = 100
	lab.load_fixture()
	var network: Node3D = lab.fixture.vastra_network
	check(network.endpoints.size() == 8,"Four grass reserves and four tree reserves have explicit visual endpoints")
	network.advance(ExpeditionContract.ACTIVITY_INTERVAL)
	check(not network.layers.is_empty(),"The real plant ledger emits visible transfers")
	var ledger: Dictionary = network.state.flora_view()
	check(PlantVastra.valid(ledger,network.state.activity_tick()),"Seeded fixture and transfers pass production ledger validation")
	for layer in network.layers.values():
		var flight: Dictionary = layer.flight
		check(layer.node.get_meta("source_flora_id") == flight.source and layer.node.get_meta("target_flora_id") == flight.target,"Particle endpoints retain actual transfer identities")
		check(network.endpoints[flight.source].flora_id == flight.source_node.id and network.endpoints[flight.target].flora_id == flight.target_node.id,"Visual source/target match functional source/target")
		check(layer.finish == (network.endpoints[flight.target].anchor if flight.root else network.endpoints[flight.target].high_anchor),"Root returns land at roots; outgoing packets land at the receiving tree")
	var root_seen := false
	for layer in network.layers.values():
		if layer.flight.root: root_seen = true
	check(root_seen,"Real tree root stock creates ground-return packets")
	lab.overrides["vastra_visibility"] = 0.0
	lab.load_fixture()
	network = lab.fixture.vastra_network
	network.advance(ExpeditionContract.ACTIVITY_INTERVAL)
	for layer in network.layers.values(): check(not layer.node.visible,"Zero visibility hides optics without stopping transactions")
	check(network.readings().valid and absf(network.readings().conservation_error) < 0.001,"Hidden effects preserve conserved state")
	for index in range(20): network.advance(ExpeditionContract.ACTIVITY_INTERVAL)
	check(network.readings().valid and absf(network.readings().conservation_error) < 0.001,"Arrivals and repeated sends remain valid and conserved")
	lab.overrides["vastra_visibility"] = 0.55
	lab.load_fixture()
	var before: Array = lab.fixture.blade_counts.duplicate()
	lab.overrides["blades_per_square_metre"] = 200
	lab.overrides["wind_strength"] = 0.0
	lab.load_fixture()
	for index in range(4): check(lab.fixture.blade_counts[index] == before[index]*2,"Density override rebuilds individual blades")
	await process_frame
	await process_frame
	check(is_zero_approx(lab.fixture.materials[0].get_shader_parameter("wind_strength")),"Wind off reaches the actual grass shader")
	lab.set_paused(true)
	var clock: float = lab.fixture.elapsed
	await process_frame
	await process_frame
	check(lab.fixture.elapsed == clock,"Lab pause freezes the blade wind clock")
	check(lab.report().readings.triangles_per_blade == 7,"Review reports include blade geometry")
	lab.free()
	print("GRASS BLADE PREVIEW: %d failures" % failures)
	quit(1 if failures else 0)

