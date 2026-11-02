@tool
extends EditorPlugin
## Enabled only by tools/check_lab_plugin_editor.py in a disposable project.
var failures := 0

func _enter_tree() -> void:
	run.call_deferred()

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)

func panels() -> Array[Node]:
	return EditorInterface.get_editor_main_screen().find_children("SolHunterLab", "", false, false)

func run() -> void:
	await get_tree().create_timer(2.0).timeout
	check(panels().size() == 1, "Plugin registers exactly one panel")
	for cycle in range(2):
		EditorInterface.set_main_screen_editor("SolHunter Lab")
		await get_tree().process_frame
		var panel: Control = panels()[0]
		check(panel.is_visible_in_tree(), "Selecting the main-screen tab shows the workspace")
		check(not panel.process_timer.is_stopped(), "Shown panel monitors its child process")
		EditorInterface.set_main_screen_editor("Script")
		await get_tree().process_frame
		check(not panel.visible and panel.process_timer.is_stopped(), "Switching tabs suspends workspace polling")
		EditorInterface.set_plugin_enabled("solhunter_lab", false)
		await get_tree().process_frame
		check(panels().is_empty(), "Disable removes the panel")
		EditorInterface.set_plugin_enabled("solhunter_lab", true)
		await get_tree().process_frame
		check(panels().size() == 1, "Re-enable registers exactly one panel")
	EditorInterface.set_main_screen_editor("SolHunter Lab")
	await get_tree().process_frame
	var panel: Control = panels()[0]
	panel.open_in_lab()
	panel.close_button.pressed.emit()
	await get_tree().create_timer(0.5).timeout
	check(not panel.bridge.connected and panel.bridge.pid <= 0, "Cancelling dependency preparation does not start a runtime")
	panel.open_in_lab()
	for attempt in range(60):
		await get_tree().create_timer(0.5).timeout
		if panel.bridge.connected and panel.bridge.image_revision > 0:
			break
	check(panel.bridge.connected, "Runtime bridge connects")
	check(panel.bridge.image_revision > 0, "Preview arrives in the editor")
	panel.bridge.send({"command":"input", "kind":"button", "button":1, "x":40, "y":30, "pressed":true})
	panel.bridge.send({"command":"input", "kind":"button", "button":1, "x":40, "y":30, "pressed":false})
	await get_tree().create_timer(1.0).timeout
	check(FileAccess.file_exists("user://lab_child_started.txt"), "Standalone scene ran in the isolated child process")
	check(FileAccess.file_exists("user://lab_child_clicked.txt"), "Editor input invokes the runtime control")
	check(not get_tree().paused, "Editor stays unpaused")
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://editor-workspace.png")
	get_tree().root.mode = Window.MODE_WINDOWED
	get_tree().root.size = Vector2i(1000, 700)
	await get_tree().create_timer(0.5).timeout
	var image_size: Vector2 = panel.preview.texture.get_size()
	var factor: float = minf(panel.preview.size.x / image_size.x, panel.preview.size.y / image_size.y)
	var offset: Vector2 = (panel.preview.size - image_size * factor) * 0.5
	var click := InputEventMouseButton.new()
	click.position = offset + Vector2(40, 30) * factor
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	panel.forward_preview_input(click)
	click.pressed = false
	panel.forward_preview_input(click)
	await get_tree().create_timer(0.5).timeout
	check(FileAccess.get_file_as_string("user://lab_child_clicked.txt") == "2", "Compact preview input maps to exactly one runtime click")
	check(panel.preview.size.y >= 180, "Compact editor retains a usable preview area")
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://editor-compact.png")
	var previous_pid: int = panel.bridge.pid
	var changed := FileAccess.open("res://child.gd", FileAccess.READ)
	var contents := changed.get_as_text()
	changed.close()
	changed = FileAccess.open("res://child.gd", FileAccess.WRITE)
	changed.store_string(contents + "\n# Source drift fixture\n")
	changed.close()
	panel.queue_catalogue_refresh()
	for attempt in range(60):
		await get_tree().create_timer(0.1).timeout
		if panel.source_stale: break
	check(panel.source_stale, "A dependency edit marks the open preview stale")
	panel.refresh_button.pressed.emit()
	for attempt in range(100):
		await get_tree().create_timer(0.1).timeout
		if panel.bridge.connected and panel.bridge.pid != previous_pid and not panel.bridge.busy: break
	check(panel.bridge.connected and panel.bridge.pid != previous_pid and not panel.source_stale, "Reload starts a fresh runtime against current source")
	EditorInterface.set_plugin_enabled("solhunter_lab", false)
	await get_tree().create_timer(0.5).timeout
	check(panels().is_empty(), "Disable with an active preview removes the editor surface")
	EditorInterface.set_plugin_enabled("solhunter_lab", true)
	EditorInterface.set_main_screen_editor("SolHunter Lab")
	await get_tree().process_frame
	panel = panels()[0]
	panel.open_in_lab()
	for attempt in range(80):
		await get_tree().create_timer(0.1).timeout
		if panel.bridge.connected and not panel.bridge.busy: break
	check(panel.bridge.connected, "Re-enabled plugin can reopen after its previous helper saves and exits")
	panel.bridge.send({"command":"close"})
	await get_tree().create_timer(1.0).timeout
	check(not panel.bridge.connected, "Graceful close releases the runtime connection")
	print("LAB EDITOR: ", failures, " failures")
	get_tree().quit(1 if failures else 0)
