extends SceneTree
var failures := 0
var lab: Control
const Relic = preload("res://scripts/scenery/procedural_relic.gd")
const Carving = preload("res://scripts/scenery/relic_carving.gd")

func _initialize() -> void:
	create_timer(60).timeout.connect(func(): quit(1))
	run.call_deferred()

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)

func picture(title: String) -> void:
	if DisplayServer.get_name() == "headless": return
	if is_instance_valid(lab): lab.fixture.update_flow_readings()
	for i in range(6): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/relic-" + title + ".png")

func run() -> void:
	var plain := Relic.stone_mesh({"size": Vector3.ONE, "taper": 0.05, "bevel": 0.08})
	var route: Array[PackedVector3Array] = [PackedVector3Array([Vector3(-0.4, 0, 0.5), Vector3(0.4, 0, 0.5)])]
	var cut := Carving.carve(plain, route, Vector3(10, 10, 10), 0)
	var cut_arrays := cut.surface_get_arrays(0)
	var indented := 0
	for i in range(cut_arrays[Mesh.ARRAY_VERTEX].size()):
		if cut_arrays[Mesh.ARRAY_COLOR][i].a > 0.3:
			indented += 1
			check(cut_arrays[Mesh.ARRAY_VERTEX][i].z < 0.49, "Fissure vertices recede into the owning stone")
	check(indented > 0, "Stone mesh contains actual recessed fissure geometry")
	var vertical_walls := 0
	var flat_floors := 0
	for i in range(cut_arrays[Mesh.ARRAY_VERTEX].size()):
		var color: Color = cut_arrays[Mesh.ARRAY_COLOR][i]
		var normal: Vector3 = cut_arrays[Mesh.ARRAY_NORMAL][i]
		if color.r < 0.2 and absf(normal.z) < 0.0001: vertical_walls += 1
		if color.a > 0.9 and normal.z > 0.999 and is_equal_approx(cut_arrays[Mesh.ARRAY_VERTEX][i].z, 0.4): flat_floors += 1
	check(vertical_walls > 0 and flat_floors > 0, "Etch-outs have perpendicular walls and a constant-depth flat floor")
	for family in range(1, 8):
		var intact := Relic.layout(family, 73, 1.0, 0.0, 0, 12, 1.0)
		var skeletal := Relic.layout(family, 73, 1.0, 2.0, 0, 12, 1.0)
		check(not skeletal.is_empty() and skeletal.parts.size() < intact.parts.size(), "Expanded missing-stonework range removes supported courses")
		check(intact.parts.size() <= Relic.MAX_PARTS, "Maximum course count respects the parent geometry budget")
	check(Relic.layout(3, 73, 1.0, 0.7, 0, 12, 0.0) != Relic.layout(3, 73, 1.0, 0.7, 0, 12, 1.0), "Break variation creates independent course-height patterns")
	for housing in range(3):
		for purpose in range(3):
			var node: Node3D = load("res://scenes/relic_vastra_node.tscn").instantiate()
			node.housing_style = housing
			node.purpose = purpose
			node.automatic_output = false
			root.add_child(node)
			check(node.has_node("Core") and node.get_node("InputPort").position == Vector3(-0.65, 0, 0.12) and node.get_node("OutputPort").position == Vector3(0.65, 0, 0.12), "Every node housing preserves its core and port contract")
			check(not node.intake(NAN) and not node.intake(101), "Invalid or unavailable intake leaves supply intact")
			check(node.intake(50) and not node.intake(1), "Intake debits finite supply and rejects duplicate departures")
			check(is_equal_approx(node.accounting_total(), 100) and node.reserve == 0, "In-flight input is conserved without early credit")
			node.advance(node.travel_seconds)
			check(node.reserve == 50 and node.source == 50, "Input credits its relic on arrival")
			check(node.operate() and not node.operate(), "Purpose debits its reserve once per output departure")
			check(node.delivered == 0 and node.spent == 0 and node.operation_count == 0, "Output effects wait for arrival")
			node.advance(node.travel_seconds)
			check(is_equal_approx(node.accounting_total(), 100) and node.operation_count == 1, "Purpose output preserves total energy and completes once")
			check((node.delivered > 0 and node.spent == 0) if purpose == 1 else (node.spent > 0 and node.delivered == 0), "Relay credits a receiver; information operations spend energy")
			node.advance(node.travel_seconds * 3)
			check(node.operation_count == 1 and node.reserve <= 100, "Completed packets cannot replay or exceed capacity")
			node.reset_test()
			check(node.accounting_total() == 100 and node.reserve == 0 and node.operation_count == 0, "Explicit reset restores only the lab supply")
			node.free()
	check(Relic.layout(0, 73, 1.0, 0.5, 6).is_empty(), "Invalid family is rejected")
	check(Relic.layout(1, 73, NAN, 0.5, 6).is_empty(), "Nonfinite geometry tuning is rejected")
	for family in range(1, 8):
		var first := Relic.layout(family, 73, 1.0, 0.45, 0)
		check(first.input_channel[0] == first.node_anchor + Vector3(-0.65, 0, 0.12) and first.input_channel[-1] == first.node_anchor + Vector3(0, 0, 0.1), "Mapped intake crevices connect input port to core")
		check(first.output_channel[0] == first.node_anchor + Vector3(0, 0, 0.1) and first.output_channel[-1] == first.node_anchor + Vector3(0.65, 0, 0.12), "Mapped output crevices connect core to output port")
		check(first == Relic.layout(family, 73, 1.0, 0.45, 0), "Seeded layout reproduces family %d" % family)
		check(first != Relic.layout(family, 74, 1.0, 0.45, 0), "Different seeds vary family %d" % family)
		var dressed := Relic.layout(family, 73, 1.0, 0.45, 16)
		check(dressed.parts.slice(0, first.parts.size()) == first.parts and dressed.marks == first.marks, "Rubble does not reroll structure or markings")
		var sample := Relic.stone_mesh(first.parts[0])
		var arrays := sample.surface_get_arrays(0)
		var outward := true
		for i in range(arrays[Mesh.ARRAY_VERTEX].size()):
			if arrays[Mesh.ARRAY_NORMAL][i].dot(arrays[Mesh.ARRAY_VERTEX][i]) <= 0: outward = false
		check(outward, "Generated stone has outward face normals")
		for seed_value in [0, 17, 99999]:
			for wear in [0.0, 0.5, 1.0]:
				var candidate := Relic.layout(family, seed_value, 1.3, wear, 16)
				check(candidate.parts.size() <= Relic.MAX_PARTS, "Geometry stays within its shared piece budget")
				for part in candidate.parts:
					check(part.at.is_finite() and part.size.is_finite() and part.size.x > 0 and part.size.y > 0 and part.size.z > 0, "Generated modules have finite positive dimensions")
	root.size = Vector2i(1600, 1000)
	lab = load("res://scenes/development_workstation.tscn").instantiate()
	lab.session_path = "res://artifacts/relic-workspace-test-%d.cfg" % Time.get_ticks_usec()
	root.add_child(lab)
	lab.save_timer.stop()
	lab.open_browser("Creative additions")
	var dialog: AcceptDialog
	var entries: ItemList
	for child in lab.get_children():
		if child is AcceptDialog: dialog = child
	if dialog:
		for node in lab.descendants(dialog):
			if node is ItemList: entries = node
	check(entries != null and entries.item_count == 1, "Creative additions browser isolates its concept section")
	if entries:
		check(entries.get_item_metadata(0) == "Creative additions / relics", "Relics appear in creative additions")
		entries.select(0)
		dialog.confirmed.emit()
	else:
		quit(1)
		return
	await process_frame
	check(lab.active_key == "relic_concept_preview", "Creative browser opens the relic fixture")
	check(lab.viewport.own_world_3d, "Concept uses an isolated 3D world")
	check(lab.fixture.has_node("Marker") and lab.fixture.has_node("Arch") and lab.fixture.has_node("Foundation"), "All three families are visible")
	check(lab.parameter_box.find_child("concentrationSlider", true, false) != null, "Concentration has a usable slider")
	check(lab.parameter_box.find_child("overloadSlider", true, false) != null, "Signed condition has a separate slider")
	check(lab.fixture.workstation_readings().scope == "concept_only", "Readings identify synthetic concept scope")
	check(lab.review_tools.task_list.size() >= 4, "Guided condition and stonework reviews are available")
	check(lab.parameter_box.find_child("stone_coursesSlider", true, false) != null and lab.parameter_box.find_child("break_variationSlider", true, false) != null, "Course count and uneven break variation have usable sliders")
	check(lab.parameter_box.find_child("generation_seedSlider", true, false) != null and lab.parameter_box.find_child("damageSlider", true, false) != null, "Procedural controls are exposed as lab sliders")
	check(lab.fixture.vastra_nodes.size() == 3, "Each relic has one consistent Vastra node")
	for node in lab.fixture.vastra_nodes:
		var attached_stonework := false
		for child in node.get_children():
			if child is MeshInstance3D and str(child.name) not in ["Inbound packet", "Outbound packet", "Inbound strand", "Outbound strand"]: attached_stonework = true
		check(node.get_node("Core") is Marker3D and not attached_stonework, "Stone contains the node cuts; no attached housing or channel geometry remains")
	for style in range(3):
		var surface: StandardMaterial3D = lab.fixture.RelicMaterials.create(style, Color.WHITE, 1.0)
		check(surface.albedo_texture != null and surface.normal_texture != null and surface.roughness_texture != null and surface.ao_texture != null, "Every stone style uses authored PBR maps")
		check("Rock051" in surface.albedo_texture.resource_path and "Rock051" in surface.normal_texture.resource_path and surface.metallic_texture != null, "Every variant uses the owner-selected Rock051 surface maps")
	var saved_layouts: Dictionary = lab.fixture.layouts.duplicate(true)
	await picture("creative-section")
	lab.set_paused(true)
	var intake_button := lab.station_box.find_child("RelicAction_intake", true, false) as Button
	check(intake_button != null, "Lab exposes its real intake action")
	if intake_button:
		intake_button.pressed.emit()
		for node in lab.fixture.vastra_nodes:
			check(not node.incoming.is_empty() and node.source == 80 and node.reserve == 0, "Lab intake action starts a conserved departure for each relic")
			node.reset_test()
	lab.set_paused(false)
	lab.overrides = {"concentration": 90, "overload": 70, "display_family": 2}
	lab.load_fixture()
	check(lab.fixture.has_node("Arch") and not lab.fixture.has_node("Marker"), "Family selector focuses the selected structure")
	check(lab.fixture.concentration == 90 and lab.fixture.overload == 70, "Richness and disruption coexist independently")
	check(lab.fixture.layouts[2] == saved_layouts[2], "Vastra and family filtering do not reroll geometry")
	check(lab.fixture.vastra_nodes[0].disruption > 0, "Disturbance affects fissure presentation without changing geometry")
	await picture("disrupted-arch")
	lab.overrides = {"overload": -65, "display_family": 0}
	lab.load_fixture()
	check(lab.fixture.overload == -65 and lab.fixture.vastra_nodes[0].disruption == 0, "Restorative state uses the carved fissures without separate markings")
	lab.save_workspace()
	lab.picker.select(0)
	lab.load_fixture()
	lab.picker.select(lab.FIXTURES.keys().find("Creative additions / relics"))
	lab.load_fixture()
	check(lab.fixture.overload == -65 and lab.fixture.concentration == 90, "Switching stations retains the concept draft")
	root.size = Vector2i(1100, 720)
	await picture("compact-section")
	lab.overrides = {"generation_seed": 492, "damage": 0.8, "rubble_count": 12}
	lab.load_fixture()
	check(lab.fixture.layouts[1] != saved_layouts[1], "Lab applies a new procedural design")
	await picture("procedural-variation")
	var design_button := lab.station_box.find_child("NextRelicDesign", true, false) as Button
	check(design_button != null, "New design action is available")
	if design_button:
		design_button.pressed.emit()
		await process_frame
		await process_frame
		check(lab.fixture.generation_seed == 493 and lab.fixture.damage == 0.8, "New design advances the seed while retaining tuning")
	for style in range(3):
		lab.overrides = {"node_style": style, "material_style": style, "display_family": 0, "overload": 0, "generation_seed": 73}
		lab.load_fixture()
		lab.set_paused(true)
		for node in lab.fixture.vastra_nodes:
			node.automatic_output = false
			check(node.intake(20), "Each styled relic accepts a finite packet")
			node.advance(node.travel_seconds)
			node.operate()
			node.advance(node.travel_seconds * 0.5)
		await picture("node-style-%d" % style)
		for node in lab.fixture.vastra_nodes:
			node.advance(node.travel_seconds)
			check(node.effect.visible and node.accounting_total() == 100, "Each purpose produces its paid output with conserved energy")
		await picture("node-output-%d" % style)
	for family in range(4, 8):
		lab.overrides = {"display_family": family, "node_style": (family - 4) % 3, "material_style": (family - 4) % 3, "damage": 0.45, "generation_seed": 73}
		lab.load_fixture()
		lab.set_paused(true)
		check(lab.fixture.layouts.has(family) and lab.fixture.vastra_nodes.size() == 1, "Reference-inspired family has generated geometry and one shared node")
		lab.fixture.camera.size = 11
		lab.fixture.camera.look_at(Vector3(0, 2, 0))
		var node: Node3D = lab.fixture.vastra_nodes[0]
		node.automatic_output = false
		node.intake(20)
		node.advance(node.travel_seconds)
		node.operate()
		node.advance(node.travel_seconds)
		await picture("reference-family-%d" % family)
	for wear in [0.0, 0.8, 2.0]:
		lab.overrides = {"display_family":3, "stone_courses":12, "damage":wear, "break_variation":1.0, "material_style":0, "show_purpose_labels":false}
		lab.load_fixture()
		lab.set_paused(true)
		lab.fixture.camera.size = 13
		lab.fixture.camera.look_at(Vector3(0, 2.8, 0))
		await picture("stonework-range-" + str(wear))
	lab.overrides = {"display_family": 1, "stone_courses":5, "damage":0.45, "node_style": 1, "material_style": 0, "show_purpose_labels": false, "concentration": 15}
	lab.load_fixture()
	lab.set_paused(true)
	lab.fixture.camera.position = Vector3(2.5, 2.9, 5)
	lab.fixture.camera.size = 4.3
	lab.fixture.camera.look_at(Vector3(0, 1.5, 0))
	await picture("ancient-carving-closeup")
	if DisplayServer.get_name() != "headless": lab.viewport.get_texture().get_image().save_png("res://artifacts/relic-ancient-stone.png")
	lab.free()
	await process_frame
	print("RELIC CONCEPT: %d failures" % failures)
	quit(1 if failures else 0)
