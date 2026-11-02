extends SceneTree
## Catalogue admission and the actual editor workspace without fixture side effects.
const Catalogue = preload("res://addons/solhunter_lab/editor/catalogue.gd")
const Workspace = preload("res://addons/solhunter_lab/editor/workspace.gd")
var failures := 0

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)

func _initialize() -> void:
	create_timer(30).timeout.connect(func(): quit(1))
	run.call_deferred()

func run() -> void:
	var result := Catalogue.discover()
	check(result.errors.is_empty(), "Registered station metadata must validate")
	check(result.stations.size() >= 3, "Initial authoring entry points must be discoverable")
	var entry: Dictionary = result.stations[0].duplicate(true)
	entry.scene = "res://scenes/../project.godot"
	check(not Catalogue.validate(entry).is_empty(), "Reject scene traversal")
	entry = result.stations[0].duplicate(true)
	entry.execution = "editor"
	check(not Catalogue.validate(entry).is_empty(), "Do not admit unproved editor adapters")
	entry = result.stations[0].duplicate(true)
	entry.contract_version = 99
	check(not Catalogue.validate(entry).is_empty(), "Reject unsupported contracts")
	var folder := "user://lab_plugin_test_" + str(OS.get_process_id())
	DirAccess.make_dir_recursive_absolute(folder)
	for file in ["a.json", "b.json"]:
		var output := FileAccess.open(folder.path_join(file), FileAccess.WRITE)
		if output == null:
			push_error("Cannot create disposable station metadata: " + str(FileAccess.get_open_error()))
			quit(1)
			return
		output.store_string(JSON.stringify(result.stations[0]))
		output.close()
	var duplicates := Catalogue.discover(folder)
	check(duplicates.stations.size() == 1 and duplicates.errors.size() == 1, "Reject duplicate station IDs")
	for file in ["a.json", "b.json"]:
		DirAccess.remove_absolute(folder.path_join(file))
	DirAccess.remove_absolute(folder)
	var workspace := Workspace.new()
	workspace.preference_path = "res://artifacts/lab-unit-preferences-%d.cfg" % Time.get_ticks_usec()
	root.size = Vector2i(1000, 700)
	workspace.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(workspace)
	await process_frame
	check(workspace.selected_id == "plants.maker", "Plant Maker is the initial station")
	check(not workspace.launch_button.disabled, "Valid fixture can launch")
	check(workspace.find_children("*", "Node3D", true, false).is_empty(), "Browsing must not instantiate runtime fixtures")
	workspace.search.text = "no_such_station"
	workspace.filter_stations()
	check(workspace.shown.is_empty() and workspace.launch_button.disabled, "No matches disables launch")
	workspace.search.text = "appearance authoring"
	workspace.filter_stations()
	check(workspace.shown.size() == 1 and workspace.selected_id == "sols.authoring", "Search includes station metadata")
	var args := workspace.launch_arguments(workspace.shown[0])
	check(args.size() == 3 and args[0] == "--path" and args[2] == "res://scenes/sol_lab.tscn", "Explicit standalone scene overrides main game startup")
	workspace.hide()
	check(workspace.process_timer.is_stopped(), "Hidden workspace must stop polling")
	workspace.show()
	check(not workspace.process_timer.is_stopped(), "Visible workspace resumes status updates")
	workspace.queue_catalogue_refresh()
	workspace.queue_catalogue_refresh()
	await process_frame
	check(not workspace.refresh_pending, "Filesystem bursts coalesce into one refresh")
	if "--render" in OS.get_cmdline_user_args():
		workspace.search.text = ""
		workspace.filter_stations()
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://artifacts/lab-plugin-workspace.png")
	workspace.queue_free()
	await process_frame
	check(not paused, "Lab must not pause the containing SceneTree")
	print("LAB PLUGIN: ", failures, " failures")
	quit(1 if failures else 0)
