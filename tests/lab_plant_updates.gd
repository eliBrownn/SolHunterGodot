extends SceneTree
var failures := 0

func check(value: bool, message: String) -> void:
	if not value: failures += 1; push_error(message)

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	Engine.set_meta("lab_initial_station", "plant_maker")
	Engine.set_meta("workstation_session_path", "res://artifacts/lab-plant-updates-%d.cfg" % Time.get_ticks_usec())
	var host: Control = load("res://scenes/development_workstation.tscn").instantiate()
	host.sessions = {"plant_maker":{"settings":{"selected_biome":1,"selected_role":1}, "context":{"selected_biome":1,"selected_role":1}}}
	root.add_child(host)
	host.save_timer.stop()
	var fixture_id: int = host.fixture.get_instance_id()
	host.station_tools.choose_subject(0)
	var selected_id: String = host.station_tools.selected_id
	host.station_tools.set_view_mode(1)
	host.apply_parameter("wind_strength", 0.9)
	check(host.fixture.get_instance_id() == fixture_id and host.station_tools.selected_id == selected_id and host.station_tools.subject_picker.selected == 1, "Presentation edits preserve fixture and selection")
	host.apply_parameter("leaf_curl", 0.65)
	check(host.fixture.get_instance_id() == fixture_id and host.station_tools.selected_id == selected_id and is_instance_valid(host.station_tools.selected), "Geometry edits preserve compatible selection in the same authoring scene")
	var body: MeshInstance3D = host.fixture.beds[0].node.find_child("OuterGrowth", true, false)
	check(body.material_override != null and host.station_tools.view_mode == 1, "Geometry rebuild retains the wireframe inspection mode")
	host.undo_tuning()
	body = host.fixture.beds[0].node.find_child("OuterGrowth", true, false)
	check(body.material_override != null and host.station_tools.selected_id == selected_id, "Undo retains inspection mode and selection")
	check(host.fixture.cache_vertices <= host.fixture.CACHE_VERTEX_LIMIT and host.fixture.cache_order.size() <= host.fixture.CACHE_ENTRY_LIMIT, "Recipe cache respects both budgets")
	host.queue_free()
	await process_frame
	print("LAB PLANT UPDATES: ", failures, " failures")
	quit(1 if failures else 0)
