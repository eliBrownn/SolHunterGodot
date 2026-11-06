extends SceneTree
var failures := 0
var checks := 0
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)
func _initialize() -> void:
	create_timer(420).timeout.connect(func(): quit(1))
	run.call_deferred()
func run() -> void:
	var lab: Control = load("res://scenes/development_workstation.tscn").instantiate()
	lab.session_path = "res://artifacts/development-workstation/journey-%d.cfg" % Time.get_ticks_usec()
	root.add_child(lab)
	lab.save_timer.stop()
	lab.picker.select(lab.FIXTURES.keys().find("Grass / single blades"))
	lab.load_fixture()
	var view: Node = lab.station_tools
	var review: Node = lab.review_tools
	check(view.subjects.size() == 4, "Four grass patches can be selected")
	review.tasks.select(0)
	review.start_task()
	check(lab.paused and is_equal_approx(lab.fixture.elapsed,2.0), "Guided grass task stops at its known time")
	var first: Dictionary = lab.fixture.vastra_network.readings()
	review.selected_time = 2
	review.replay_to_time()
	check(lab.fixture.vastra_network.readings() == first, "Same grass setup/time reproduces ledger readings")
	view.choose_subject(2)
	view.frame_selected()
	var before_camera: Dictionary = lab.camera_settings()
	check(view.selected != null and before_camera._view.active, "Selection can frame a grass patch")
	lab.overrides["blade_height"] = 0.7
	lab.load_fixture()
	check(lab.camera_settings()._view.transform.is_equal_approx(before_camera._view.transform), "Common camera survives a rebuild")
	check(view.subject_picker.get_item_text(view.subject_picker.selected).contains("Heath"), "Selected patch survives a rebuild")
	lab.set_baseline()
	review.title.text = "Wind review"
	review.next_change.text = "Reduce height"
	review.state.select(1)
	review.save_review()
	check(review.records.size() == 1, "Named review records its setup")
	var saved_id: String = review.current_review
	var review_path: String = review.review_path
	lab.overrides["blade_height"] = 0.9
	lab.load_fixture()
	review.open_review()
	check(is_equal_approx(lab.fixture.blade_height,0.7) and review.state.selected == 1, "Opening review restores settings and review state")
	review.write_change_note()
	check(FileAccess.file_exists(review_path.get_base_dir()+"/reviews/"+saved_id+"-change.md"), "Review creates a concrete change note")
	lab.picker.select(0)
	lab.load_fixture()
	review.tasks.select(0)
	review.start_task()
	check(lab.paused and is_equal_approx(lab.fixture.elapsed,1.0), "Guided transfer stops at the requested time")
	check(lab.fixture.plant_nodes.source.selected == 2 and lab.fixture.plant_nodes.target.selected == 0, "Guided transfer uses named source and target")
	var transfer_total: float = lab.fixture.plant_nodes.stored_total()
	review.selected_time = 1
	review.replay_to_time()
	check(is_equal_approx(lab.fixture.plant_nodes.stored_total(),transfer_total), "Transfer replay preserves conserved total")
	for station in ["Lighting / shadows","Materials / response grid","Water / depth and foam","Readability / scale and occlusion","Particles / density and overdraw","Animation / slope and actions","Plants / procedural forms","Plants / biomes & Vastra anatomy","Forest / pixels","Forest / style","Terrain / landforms","Biomes / assets","Vessels / appearance","Animation / flight","Animation / swimming","Sols / model exercises","Sols / Ashquill","Sols / Rattlehorn","Sols / Rimefold","World / cohesive sample","Sols / species pilot","Sols / traversal pilot","Story / controlled preview"]:
		if "--quick" in OS.get_cmdline_user_args() and station in ["World / cohesive sample","Sols / species pilot","Sols / traversal pilot","Story / controlled preview"]: continue
		lab.picker.select(lab.FIXTURES.keys().find(station))
		lab.load_fixture()
		print("REVIEW STATION: ",station)
		await process_frame
		check(lab.fixture != null and (lab.station_box.get_child_count() > 0 or lab.parameter_box.get_child_count() > 0), station + " exposes its controls in the sidebar")
		check(view.camera != null, station + " has a shared inspection camera")
		var camera_state: Dictionary = lab.camera_settings()
		view.frame_all()
		lab.apply_camera(camera_state)
		view.set_view_mode(2)
		view.set_view_mode(0)
		check(view.saved_materials.is_empty(), station + " restores original materials after inspection")
		if station == "Biomes / assets":
			lab.fixture.show_page(1)
			view._process(0.3)
			var valid := true
			for item in view.subjects:
				if not is_instance_valid(item.node): valid = false
			check(valid, "Changing biome pages refreshes selectable objects")
	var session: String = lab.session_path
	lab.picker.select(0)
	lab.load_fixture()
	lab.save_workspace()
	lab.free()
	await process_frame
	lab = load("res://scenes/development_workstation.tscn").instantiate()
	lab.session_path = session
	root.add_child(lab)
	lab.save_timer.stop()
	check(lab.review_tools.records.has(saved_id), "Review library survives application reopening")
	lab.review_tools.open_review()
	check(is_equal_approx(lab.fixture.blade_height,0.7) and lab.review_tools.next_change.text == "Reduce height", "Reopened review restores setup and next change")
	print("LAB REVIEW JOURNEY: %d checks, %d failures" % [checks,failures])
	lab.free()
	await process_frame
	quit(1 if failures else 0)
