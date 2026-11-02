extends SceneTree
## Repeatable visual review of the workspace, independent of personal lab settings.
func _initialize() -> void:
	create_timer(60).timeout.connect(func(): quit(1))
	run.call_deferred()

func settle() -> void:
	for frame in range(12): await process_frame
	await RenderingServer.frame_post_draw

func screenshot(name: String) -> void:
	await settle()
	root.get_texture().get_image().save_png("res://artifacts/development-workstation/" + name + ".png")

func run() -> void:
	root.size = Vector2i(1600, 1000)
	var lab: Control = load("res://scenes/development_workstation.tscn").instantiate()
	lab.session_path = "res://artifacts/development-workstation/visual-session-%d.cfg" % Time.get_ticks_usec()
	root.add_child(lab)
	lab.save_timer.stop()
	lab.capture_directory = "res://artifacts/development-workstation/captures"
	lab.sessions.clear()
	lab.picker.select(0)
	lab.load_fixture()
	await screenshot("workspace-vastra")
	lab.picker.select(lab.FIXTURES.keys().find("Grass / single blades"))
	lab.load_fixture()
	await screenshot("workspace-grass")
	await lab.set_baseline()
	lab.overrides["blade_height"] = 0.85
	lab.load_fixture()
	lab.sidebar.current_tab = 1
	await screenshot("workspace-compare")
	await lab.capture()
	var paired: Variant = JSON.parse_string(FileAccess.get_file_as_string(lab.last_capture_path + ".json"))
	if not FileAccess.file_exists(lab.last_capture_path + ".png") or paired.get("capture_kind") != "preview":
		push_error("Paired preview capture failed")
		quit(1)
		return
	await lab.capture(true)
	paired = JSON.parse_string(FileAccess.get_file_as_string(lab.last_capture_path + ".json"))
	if paired.get("capture_kind") != "workspace":
		push_error("Workspace capture failed")
		quit(1)
		return
	root.size = Vector2i(1100, 720)
	lab.sidebar.current_tab = 0
	await screenshot("workspace-short")
	lab.open_browser()
	await screenshot("workspace-browser")
	var session_path: String = lab.session_path
	lab.queue_free()
	if FileAccess.file_exists(session_path): DirAccess.remove_absolute(session_path)
	await process_frame
	print("LAB WORKSPACE VISUAL REVIEW COMPLETE")
	quit()
