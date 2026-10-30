extends SceneTree
var lab: Control
func _initialize() -> void:
	create_timer(90).timeout.connect(func(): quit(1))
	run.call_deferred()
func settle() -> void:
	for i in range(8): await process_frame
	await RenderingServer.frame_post_draw
func picture(title: String) -> void:
	await settle()
	root.get_texture().get_image().save_png("res://artifacts/development-workstation/upgraded-"+title+".png")
func run() -> void:
	root.size = Vector2i(1600,1000)
	lab = load("res://scenes/development_workstation.tscn").instantiate()
	lab.session_path = "res://artifacts/development-workstation/visual-upgrade-%d.cfg" % Time.get_ticks_usec()
	root.add_child(lab)
	lab.save_timer.stop()
	lab.capture_directory = "res://artifacts/development-workstation/captures"
	lab.review_tools.start_task()
	await picture("vastra")
	lab.picker.select(lab.FIXTURES.keys().find("Grass / single blades"))
	lab.load_fixture()
	lab.review_tools.start_task()
	await picture("grass-settings")
	lab.station_tools.choose_subject(2)
	lab.station_tools.frame_selected()
	lab.sidebar.current_tab = 4
	lab.station_tools.scale_lines.show()
	await picture("inspect")
	lab.station_tools.set_view_mode(1)
	await picture("edges")
	lab.station_tools.set_view_mode(2)
	await picture("normals")
	lab.station_tools.set_view_mode(0)
	lab.station_tools.frame_all()
	await lab.set_baseline()
	lab.overrides["blade_height"] = 0.8
	lab.load_fixture()
	lab.sidebar.current_tab = 1
	lab.review_tools.comparison_slider.value = 0.5
	await picture("compare")
	lab.review_tools.comparison_slider.value = 1
	lab.review_tools.title.text = "Grass in wind"
	lab.review_tools.next_change.text = "Use shorter blades so the ground stays visible."
	lab.review_tools.state.select(1)
	await lab.review_tools.save_review()
	var saved_id: String = lab.review_tools.current_review
	var library_path: String = lab.review_tools.review_path
	lab.review_tools.open_review()
	if lab.review_tools.current_review != saved_id or lab.baseline_view.texture == null:
		push_error("Review did not restore its before picture")
		quit(1)
		return
	lab.sidebar.current_tab = 2
	await picture("review")
	lab.review_tools.capture_without_labels = true
	await lab.capture()
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(lab.last_capture_path+".json"))
	if data.capture_kind != "preview": push_error("Preview/report pair failed"); quit(1); return
	root.size = Vector2i(1100,720)
	lab.sidebar.current_tab = 0
	await picture("short")
	lab.picker.select(lab.FIXTURES.keys().find("Lighting / shadows"))
	lab.load_fixture()
	await picture("lighting")
	var session: String = lab.session_path
	lab.free()
	await process_frame
	var reopened: Control = load("res://scenes/development_workstation.tscn").instantiate()
	reopened.session_path = session
	root.add_child(reopened)
	reopened.save_timer.stop()
	if not reopened.review_tools.records.has(saved_id): push_error("Saved review library did not reopen"); quit(1); return
	reopened.review_tools.open_review()
	if reopened.baseline_view.texture == null: push_error("Saved before picture did not reopen"); quit(1); return
	reopened.free()
	await process_frame
	print("LAB UPGRADE VISUAL REVIEW: pictures, overlays, comparison, paired capture and reopened review passed")
	quit()
