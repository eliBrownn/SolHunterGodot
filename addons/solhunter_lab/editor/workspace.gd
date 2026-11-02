@tool
extends MarginContainer
## Editor navigation and focused input; simulation remains in the runtime adapter.
const Catalogue = preload("res://addons/solhunter_lab/editor/catalogue.gd")
const SESSION_KEY := "solhunter_lab_runtime_session_v1"
const BridgeClient = preload("res://addons/solhunter_lab/editor/bridge_client.gd")
var bridge: RefCounted
var preview := TextureRect.new()
var browse_box := VBoxContainer.new()
var browse_toggle := Button.new()
var standalone_button := Button.new()
var refresh_button := Button.new()
var close_button := Button.new()
var bridge_speed := OptionButton.new()
var transport_picker := OptionButton.new()
var metrics_label := Label.new()
var last_image_revision := -1
var frame_elapsed := 0.0
var preview_rate := 10.0
var last_size := Vector2i.ZERO
var dependency_snapshot := ""
var source_stale := false
var restart_pending_id := ""
var preference_path := "res://.godot/editor/solhunter_lab_workspace.cfg"
var preference_writable := true
var chrome_labels: Array[Control] = []
var view_options := Button.new()
var redraw := Button.new()
var show_view_options := false
var dependency_thread: Thread
var dependency_queue: Dictionary = {}
var dependency_generation := 0
var active_dependency_generation := 0
var active_dependency_action := ""
var catalogue: Array[Dictionary] = []
var shown: Array[Dictionary] = []
var selected_id := "plants.maker"
var refresh_pending := false
var search := LineEdit.new()
var stations := ItemList.new()
var heading := Label.new()
var description := Label.new()
var storage := Label.new()
var status := Label.new()
var diagnostics := Label.new()
var launch_button := Button.new()
var process_timer := Timer.new()

func _ready() -> void:
	bridge = BridgeClient.new()
	var preferences := ConfigFile.new()
	if preferences.load(preference_path) == OK:
		if int(preferences.get_value("workspace", "version", 0)) == 1:
			selected_id = str(preferences.get_value("workspace", "station", selected_id))
			preview_rate = float(preferences.get_value("workspace", "rate", 10.0))
			if preview_rate not in [0.0, 10.0, 20.0]: preview_rate = 10.0
			bridge.preview_rate = preview_rate
			bridge.transport_format = "png" if preferences.get_value("workspace", "format", "jpg") == "png" else "jpg"
		else: preference_writable = false
	for edge in ["left", "right", "top", "bottom"]:
		add_theme_constant_override("margin_" + edge, 16)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 12)
	add_child(layout)
	var title := Label.new()
	title.text = "SolHunter Lab"
	title.add_theme_font_size_override("font_size", 24)
	layout.add_child(title)
	var introduction := Label.new()
	introduction.text = "Choose a station to tune, view, compare and review."
	introduction.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(introduction)
	chrome_labels.assign([title, introduction])
	search.placeholder_text = "Search stations"
	search.text_changed.connect(func(_text: String): filter_stations())
	layout.add_child(browse_box)
	browse_box.add_child(search)
	stations.custom_minimum_size.y = 160
	stations.size_flags_vertical = Control.SIZE_FILL
	stations.item_selected.connect(func(index: int): select_station(index); save_preferences())
	browse_box.add_child(stations)
	heading.add_theme_font_size_override("font_size", 19)
	layout.add_child(heading)
	for label in [description, storage, status, diagnostics]:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		layout.add_child(label)
	launch_button.text = "Open in Lab"
	launch_button.pressed.connect(open_in_lab)
	var actions := HFlowContainer.new()
	layout.add_child(actions)
	actions.add_child(launch_button)
	browse_toggle.text = "Browse stations"
	browse_toggle.pressed.connect(func(): browse_box.visible = not browse_box.visible)
	actions.add_child(browse_toggle)
	view_options.text = "View options"
	view_options.pressed.connect(func(): show_view_options = not show_view_options)
	actions.add_child(view_options)
	standalone_button.text = "Open standalone"
	standalone_button.pressed.connect(launch_selected)
	actions.add_child(standalone_button)
	refresh_button.text = "Reload source"
	refresh_button.tooltip_text = "Save local work and restart this preview against current project files."
	refresh_button.pressed.connect(func():
		restart_pending_id = bridge.station_id
		bridge.send({"command": "close"}))
	actions.add_child(refresh_button)
	close_button.text = "Save & close preview"
	close_button.pressed.connect(func():
		if dependency_thread != null and dependency_thread.is_started():
			dependency_generation += 1
			dependency_queue.clear()
		elif bridge.busy: bridge.cancel_opening()
		else: bridge.send({"command": "close"}))
	actions.add_child(close_button)
	for rate in ["Live preview · 10 fps", "Live preview · 20 fps", "On demand"]: bridge_speed.add_item(rate)
	bridge_speed.tooltip_text = "Transport refresh only. Runtime simulation and screenshot fidelity are unchanged."
	bridge_speed.select([10.0, 20.0, 0.0].find(preview_rate))
	bridge_speed.item_selected.connect(func(index: int):
		preview_rate = [10.0, 20.0, 0.0][index]
		bridge.preview_rate = preview_rate
		save_preferences())
	actions.add_child(bridge_speed)
	transport_picker.add_item("Interactive picture · JPEG 95%")
	transport_picker.add_item("Exact picture · PNG")
	transport_picker.tooltip_text = "Preview transport only. Station captures keep their original fidelity."
	transport_picker.select(1 if bridge.transport_format == "png" else 0)
	transport_picker.item_selected.connect(func(index: int):
		bridge.transport_format = "png" if index == 1 else "jpg"
		bridge.send({"command": "transport", "format": bridge.transport_format})
		save_preferences())
	actions.add_child(transport_picker)
	redraw.text = "Refresh picture"
	redraw.pressed.connect(func(): bridge.request_frame())
	actions.add_child(redraw)
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.size_flags_vertical = Control.SIZE_EXPAND_FILL
	preview.custom_minimum_size = Vector2(240, 180)
	preview.focus_mode = Control.FOCUS_ALL
	preview.gui_input.connect(forward_preview_input)
	preview.focus_exited.connect(func(): bridge.send({"command": "release_inputs"}))
	layout.add_child(preview)
	metrics_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(metrics_label)
	process_timer.wait_time = 0.75
	process_timer.timeout.connect(refresh_process_status)
	add_child(process_timer)
	visibility_changed.connect(update_visibility)
	reload_catalogue()
	if bridge.connected:
		browse_box.hide()
		description.hide()
		storage.hide()
	update_visibility()

func queue_catalogue_refresh() -> void:
	if refresh_pending:
		return
	refresh_pending = true
	call_deferred("reload_catalogue")

func reload_catalogue() -> void:
	refresh_pending = false
	var result := Catalogue.discover()
	catalogue.assign(result.stations)
	diagnostics.text = "\n".join(PackedStringArray(result.errors))
	filter_stations()
	if bridge != null and bridge.connected:
		var current := Catalogue.find(bridge.station_id)
		if current.is_empty(): source_stale = true
		else: queue_dependency_check(current, "refresh")

func filter_stations() -> void:
	stations.clear()
	shown.clear()
	for entry in catalogue:
		var label: String = entry.domain + " / " + entry.title
		if not search.text.is_empty() and not search.text.to_lower() in (label + " " + entry.description).to_lower():
			continue
		shown.append(entry)
		stations.add_item(label)
	var index := 0
	for i in range(shown.size()):
		if shown[i].id == selected_id:
			index = i
	if shown.is_empty():
		heading.text = "No matching stations"
		description.text = "Try a different search."
		storage.text = ""
	else:
		stations.select(index)
		select_station(index)
	refresh_process_status()

func select_station(index: int) -> void:
	if index < 0 or index >= shown.size():
		return
	var entry: Dictionary = shown[index]
	selected_id = entry.id
	heading.text = entry.domain + " / " + entry.title
	description.text = entry.description + "\n" + entry.reason
	storage.text = "Storage: " + entry.storage
	refresh_process_status()

func launch_arguments(entry: Dictionary) -> PackedStringArray:
	return PackedStringArray(["--path", ProjectSettings.globalize_path("res://"), entry.scene])

func launch_selected() -> void:
	refresh_process_status()
	if standalone_button.disabled:
		return
	var entry: Dictionary = shown[stations.get_selected_items()[0]]
	if not Catalogue.validate(entry).is_empty():
		status.text = "The fixture changed. Refresh the catalogue before opening it."
		queue_catalogue_refresh()
		return
	var pid := OS.create_process(OS.get_executable_path(), launch_arguments(entry), false)
	if pid <= 0:
		status.text = "Could not start the lab. Check Godot's output and try again."
		return
	# Editor-session metadata survives plugin disable/re-enable, never a disk PID.
	Engine.set_meta(SESSION_KEY, {"pid": pid, "title": entry.title})
	refresh_process_status()

func refresh_process_status() -> void:
	var session: Dictionary = Engine.get_meta(SESSION_KEY, {})
	var running := not session.is_empty() and OS.is_process_running(int(session.pid))
	if not running and not session.is_empty():
		Engine.remove_meta(SESSION_KEY)
	status.text = ("Running: " + str(session.title) + ". Save your work and close that window to return.") if running else "Ready. Tuning and saving happen in the standalone window."
	standalone_button.disabled = running or shown.is_empty() or (bridge != null and (bridge.connected or bridge.busy))
	launch_button.disabled = running or shown.is_empty()
	launch_button.text = "Lab is running" if running else "Open in Lab"

func update_visibility() -> void:
	if bridge != null: bridge.send({"command": "suspend", "value": not is_visible_in_tree()})
	set_process(is_visible_in_tree())
	if is_visible_in_tree():
		refresh_process_status()
		process_timer.start()
	else:
		process_timer.stop()

func selected_entry() -> Dictionary:
	for entry in catalogue:
		if entry.id == selected_id: return entry
	return {}

func open_in_lab() -> void:
	var entry := selected_entry()
	if entry.is_empty(): return
	if entry.get("host") == "standalone":
		launch_selected()
		return
	queue_dependency_check(entry, "open")

func queue_dependency_check(entry: Dictionary, action: String) -> void:
	if action == "refresh" and dependency_thread != null and dependency_thread.is_started() and active_dependency_action == "open": return
	if action == "refresh" and not dependency_queue.is_empty() and dependency_queue.action == "open": return
	dependency_generation += 1
	dependency_queue = {"entry":entry.duplicate(true), "action":action, "generation":dependency_generation}
	start_dependency_check()

func start_dependency_check() -> void:
	if dependency_queue.is_empty() or (dependency_thread != null and dependency_thread.is_started()): return
	var request := dependency_queue.duplicate(true)
	dependency_queue.clear()
	active_dependency_generation = int(request.generation)
	active_dependency_action = str(request.action)
	dependency_thread = Thread.new()
	if dependency_thread.start(calculate_dependencies.bind(request)) != OK:
		dependency_thread = null
		diagnostics.text = "Could not start the dependency check. Try opening this station again."

func calculate_dependencies(request: Dictionary) -> Dictionary:
	# FileAccess/JSON/RegEx only; the worker never touches scene or editor objects.
	request["fingerprint"] = Catalogue.fingerprint(request.entry)
	return request

func open_verified_station(entry: Dictionary, fingerprint: String) -> void:
	if bridge.connected and (source_stale or (bridge.station_snapshots.has(entry.id) and bridge.station_snapshots[entry.id] != fingerprint)):
		restart_pending_id = entry.id
		bridge.send({"command":"close"})
		return
	if bridge.start(entry):
		save_preferences()
		dependency_snapshot = fingerprint
		source_stale = false
		browse_box.hide()
		description.hide()
		storage.hide()
		for label in chrome_labels: label.hide()
		bridge.send({"command": "suspend", "value": false})

func _process(delta: float) -> void:
	if bridge == null: return
	bridge.poll()
	if dependency_thread != null and dependency_thread.is_started() and not dependency_thread.is_alive():
		var result: Dictionary = dependency_thread.wait_to_finish()
		dependency_thread = null
		if int(result.generation) == dependency_generation:
			if result.action == "open": open_verified_station(result.entry, str(result.fingerprint))
			elif bridge.connected:
				if dependency_snapshot.is_empty(): dependency_snapshot = str(bridge.metrics.get("snapshot", result.fingerprint))
				if str(result.fingerprint) != dependency_snapshot: source_stale = true
		start_dependency_check()
	if not restart_pending_id.is_empty() and not bridge.connected:
		var entry := Catalogue.find(restart_pending_id)
		if not entry.is_empty() and bridge.start(entry):
			dependency_snapshot = ""
			source_stale = false
			restart_pending_id = ""
	status.text = bridge.message
	var checking := dependency_thread != null and dependency_thread.is_started() and active_dependency_generation == dependency_generation
	if checking: status.text = "Checking station dependencies…"
	if source_stale: status.text += " · Source changed: reload to use current definitions. Existing pictures and overrides retain their old snapshot."
	close_button.disabled = not bridge.connected and not checking and not bridge.busy
	close_button.text = "Cancel opening" if checking or bridge.busy else "Save & close preview"
	var browsing: bool = browse_box.visible or not bridge.connected
	heading.visible = browsing
	description.visible = browsing
	storage.visible = browsing
	diagnostics.visible = not diagnostics.text.is_empty()
	status.visible = checking or source_stale or bridge.busy or not bridge.message.begins_with("Ready")
	launch_button.visible = browsing
	standalone_button.visible = browsing
	view_options.visible = bridge.connected
	view_options.text = "View · %s · %s" % ["Exact" if bridge.transport_format == "png" else "Interactive", "On demand" if preview_rate == 0 else "%d fps" % int(preview_rate)]
	for option in [bridge_speed, transport_picker, redraw, metrics_label]: option.visible = show_view_options
	refresh_button.visible = source_stale or show_view_options
	refresh_button.disabled = not bridge.connected or bridge.busy
	if bridge.image_revision != last_image_revision and bridge.latest_image != null:
		last_image_revision = bridge.image_revision
		preview.texture = ImageTexture.create_from_image(bridge.latest_image)
	var desired := Vector2i(clampi(int(preview.size.x), 800, 1920), clampi(int(preview.size.y), 600, 1200))
	if bridge.connected and desired != last_size:
		last_size = desired
		bridge.send({"command": "resize", "width": desired.x, "height": desired.y})
	frame_elapsed += delta
	if preview_rate > 0 and frame_elapsed > 1.0 / preview_rate:
		frame_elapsed = 0.0
		bridge.request_frame()
	if not bridge.metrics.is_empty():
		metrics_label.text = "Simulation median %.1f ms · p95 %.1f ms · capture %.1f ms · %s · %s picture · %s" % [float(bridge.metrics.get("median_ms", 0)), float(bridge.metrics.get("p95_ms", 0)), float(bridge.metrics.get("capture_ms", 0)), str(bridge.metrics.get("renderer", "opening")), str(bridge.metrics.get("transport", "jpg")), str(bridge.metrics.get("viewport", ""))]

func forward_preview_input(event: InputEvent) -> void:
	if bridge == null or not bridge.connected or bridge.busy or preview.texture == null: return
	var packet := {"command": "input"}
	if event is InputEventMouse:
		var image_size := preview.texture.get_size()
		var factor := minf(preview.size.x / image_size.x, preview.size.y / image_size.y)
		var offset := (preview.size - image_size * factor) * 0.5
		var at: Vector2 = (event.position - offset) / factor
		if not Rect2(Vector2.ZERO, image_size).has_point(at): return
		packet.merge({"x": at.x, "y": at.y, "mask": event.button_mask})
		if event is InputEventMouseButton:
			preview.grab_focus()
			packet.merge({"kind": "button", "button": event.button_index, "pressed": event.pressed, "double": event.double_click})
		elif event is InputEventMouseMotion:
			packet.merge({"kind": "motion", "dx": event.relative.x / factor, "dy": event.relative.y / factor})
		else: return
	elif event is InputEventKey:
		packet.merge({"kind": "key", "keycode": event.keycode, "physical": event.physical_keycode, "unicode": event.unicode, "pressed": event.pressed, "echo": event.echo})
	else: return
	if event is InputEventWithModifiers:
		packet.merge({"shift": event.shift_pressed, "ctrl": event.ctrl_pressed, "alt": event.alt_pressed})
	bridge.send(packet)
	preview.accept_event()

func suspend_bridge() -> void:
	if bridge != null: bridge.send({"command": "suspend", "value": true})

func shutdown_bridge() -> void:
	save_preferences()
	if dependency_thread != null and dependency_thread.is_started(): dependency_thread.wait_to_finish()
	dependency_thread = null
	set_process(false)
	preview.texture = null
	if bridge != null: bridge.shutdown()

func save_preferences() -> void:
	if not preference_writable: return
	var preferences := ConfigFile.new()
	preferences.set_value("workspace", "version", 1)
	preferences.set_value("workspace", "station", selected_id)
	preferences.set_value("workspace", "rate", preview_rate)
	preferences.set_value("workspace", "format", bridge.transport_format)
	DirAccess.make_dir_recursive_absolute(preference_path.get_base_dir())
	if preferences.save(preference_path) != OK: diagnostics.text = "Could not save local Lab layout preferences."
