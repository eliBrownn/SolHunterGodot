extends SceneTree
var failures := 0

func check(value: bool, message: String) -> void:
	if not value: failures += 1; push_error(message)

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var folder := "res://artifacts/lab-sol-session"
	DirAccess.make_dir_recursive_absolute(folder)
	var path := folder.path_join("session_%d.json" % Time.get_ticks_usec())
	var first: Control = load("res://scenes/sol_lab.tscn").instantiate()
	root.add_child(first)
	first.lab_session_path = path
	first.checkpoint()
	first.document.body_length = 1.7
	first.selected = "Core"
	first.yaw = 1.1
	first.sync_controls()
	check(first.lab_save_workspace(), "Save the local Sol editor session")
	var second: Control = load("res://scenes/sol_lab.tscn").instantiate()
	root.add_child(second)
	second.lab_session_path = path
	check(second.lab_load_workspace(), "Restore the local Sol editor session")
	check(is_equal_approx(float(second.document.body_length), 1.7) and second.selected == "Core" and is_equal_approx(second.yaw, 1.1), "Draft, selected anatomy and camera survive restoration")
	check(second.undo_stack.size() == first.undo_stack.size(), "Undo history survives restoration")
	var malformed: Dictionary = first.lab_session_snapshot()
	malformed.distance = "invalid"
	check(not second.lab_restore_session(malformed), "Invalid camera data is rejected before touching the viewport")
	var invalid := folder.path_join("future_%d.json" % Time.get_ticks_usec())
	var file := FileAccess.open(invalid, FileAccess.WRITE)
	file.store_string('{"version":999}')
	file.close()
	second.lab_session_path = invalid
	check(not second.lab_load_workspace() and second.lab_session_path != invalid and FileAccess.get_file_as_string(invalid) == '{"version":999}', "Incompatible session remains intact and gets a recovery destination")
	first.queue_free()
	second.queue_free()
	await process_frame
	print("LAB SOL SESSION: ", failures, " failures")
	quit(1 if failures else 0)
