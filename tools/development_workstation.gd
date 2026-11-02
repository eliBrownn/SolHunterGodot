extends Control
## One review surface; fixtures retain their own controls and isolated World3D.
const MenuTheme = preload("res://scripts/ui/menu_theme.gd")
const MENU_SETTINGS = preload("res://resources/menu_settings.tres")
const Catalogue = preload("res://tools/lab_station_catalogue.gd")
var FIXTURES: Dictionary = Catalogue.fixture_map()
const StationTools = preload("res://tools/lab_station_tools.gd")
const ReviewTools = preload("res://tools/lab_review_tools.gd")
var station_tools: Node
var review_tools: Node
var viewport := SubViewport.new()
var picker := OptionButton.new()
var notes := TextEdit.new()
var metrics := Label.new()
var message := Label.new()
var pause_button := Button.new()
var fixture: Node
var paused := false
var ticks := 0
var baseline: Dictionary = {}
var overrides: Dictionary = {}
var parameter_box := VBoxContainer.new()
var elapsed := 0.0
var frame_sum := 0.0
var frame_count := 0
var last_ms := 0.0
var stepping := false
var sidebar := TabContainer.new()
var parameter_scroll: ScrollContainer
var station_box := VBoxContainer.new()
var compare_text := Label.new()
var baseline_view := TextureRect.new()
var baseline_overlay := TextureRect.new()
var preview_stack := Control.new()
var station_description := Label.new()
var status := Label.new()
var sessions: Dictionary = {}
var favorites: Array = []
var baseline_images: Dictionary = {}
var active_key := ""
var defaults: Dictionary = {}
var default_camera: Dictionary = {}
var undo_settings: Dictionary = {}
var undo_controls: Dictionary = {}
var reset_live_controls := false
var restore_scroll := 0
var focus_path := NodePath()
var save_timer := Timer.new()
var group_states: Dictionary = {}
var preset_name := LineEdit.new()
var preset_picker := OptionButton.new()
var presets: Dictionary = {}
var capture_history := VBoxContainer.new()
var capture_directory := "user://workstation"
var last_capture_path := ""
var measuring := false
var measurement_warmup := 0.0
var measurement_samples: Array[float] = []
var measurement_result: Dictionary = {}
var measurement_context: Dictionary = {}
var session_path := "user://workstation/workspace.cfg"
var revision_cache := ""
var unresolved_settings: Dictionary = {}
var unresolved_controls: Dictionary = {}

func _input(event: InputEvent) -> void:
	if event is InputEventKey or event is InputEventMouseButton or (event is InputEventMouseMotion and event.button_mask != 0):
		if save_timer.is_inside_tree() and not Engine.has_meta("lab_bridge_attached"): save_timer.start()
		if station_tools: station_tools.queue_control_refresh()

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	install_theme()
	if Engine.has_meta("workstation_session_path"): session_path = str(Engine.get_meta("workstation_session_path"))
	var config := ConfigFile.new()
	if config.load(session_path) == OK:
		sessions = config.get_value("workspace", "stations", {})
		presets = config.get_value("workspace", "presets", {})
		favorites = config.get_value("workspace", "favorites", [])
	var background := ColorRect.new()
	background.color = MENU_SETTINGS.background
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + edge, 12)
	add_child(margin)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 8)
	margin.add_child(layout)
	var heading := Label.new()
	heading.text = "SOLHUNTER / DEVELOPMENT LAB · try, compare, improve"
	heading.add_theme_color_override("font_color", MENU_SETTINGS.accent)
	layout.add_child(heading)
	var controls := HFlowContainer.new()
	layout.add_child(controls)
	for label in FIXTURES: picker.add_item(label)
	picker.custom_minimum_size.x = 230
	picker.tooltip_text = "Choose a station. Each station remembers its setup and notes."
	controls.add_child(picker)
	picker.item_selected.connect(func(_index: int): load_fixture())
	button(controls, "Browse", open_browser)
	button(controls, "Creative additions", func(): open_browser("Creative additions"))
	pause_button.text = "Pause"
	controls.add_child(pause_button)
	pause_button.pressed.connect(func(): set_paused(not paused))
	button(controls, "One frame", step_once)
	button(controls, "Restart", restart_fixture)
	button(controls, "Take picture", capture)
	button(controls, "Hide / show settings", func(): sidebar.visible = not sidebar.visible)
	var body := HSplitContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.split_offset = int(config.get_value("workspace", "split", 950))
	layout.add_child(body)
	preview_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preview_stack.custom_minimum_size = Vector2(240, 180)
	body.add_child(preview_stack)
	var container := SubViewportContainer.new()
	container.stretch = true
	preview_stack.add_child(container)
	container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	viewport.own_world_3d = true
	viewport.handle_input_locally = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	container.add_child(viewport)
	baseline_overlay.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	baseline_overlay.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	baseline_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	baseline_overlay.hide()
	preview_stack.add_child(baseline_overlay)
	baseline_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sidebar.custom_minimum_size.x = 360
	body.add_child(sidebar)
	sidebar.add_theme_font_size_override("font_size",14)
	for tab_state in ["tab_selected","tab_unselected","tab_hovered"]:
		var tab_style := MenuTheme.box(MENU_SETTINGS.surface if tab_state == "tab_selected" else MENU_SETTINGS.background,MENU_SETTINGS.accent if tab_state == "tab_selected" else MENU_SETTINGS.background)
		tab_style.content_margin_left = 5
		tab_style.content_margin_right = 5
		sidebar.add_theme_stylebox_override(tab_state,tab_style)
	sidebar.tab_changed.connect(func(_index: int):
		if is_instance_valid(fixture): refresh_compare())
	var controls_page := tab_page("Settings")
	station_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	controls_page.add_child(station_description)
	var actions := HFlowContainer.new()
	controls_page.add_child(actions)
	button(actions, "Reset view", reset_camera)
	button(actions, "Undo change", undo_tuning)
	button(actions, "Reset settings", restore_defaults)
	preset_name.placeholder_text = "Name this setup"
	var preset_section := fold_section(controls_page, "Saved settings", false)
	preset_section.add_child(preset_name)
	var preset_row := HBoxContainer.new()
	preset_section.add_child(preset_row)
	preset_picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preset_row.add_child(preset_picker)
	button(preset_row, "Save", save_preset)
	button(preset_row, "Load", load_preset)
	controls_page.add_child(station_box)
	controls_page.add_child(parameter_box)
	parameter_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	station_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	station_box.set_meta("workspace", self)
	var compare_page := tab_page("Compare")
	var compare_actions := HFlowContainer.new()
	compare_page.add_child(compare_actions)
	button(compare_actions, "Take before picture", set_baseline)
	button(compare_actions, "Use before settings", restore_baseline)
	button(compare_actions, "Before / now", toggle_baseline)
	baseline_view.custom_minimum_size.y = 160
	baseline_view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	baseline_view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	compare_page.add_child(baseline_view)
	compare_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	compare_page.add_child(compare_text)
	var notes_page := tab_page("Review")
	var note_hint := Label.new()
	note_hint.text = "What are you checking? What happened? What should change?"
	note_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	notes_page.add_child(note_hint)
	notes.custom_minimum_size.y = 260
	notes.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	notes.placeholder_text = "What I am checking:\nWhat I expected:\nWhat I saw:\nWhat to change:"
	notes_page.add_child(notes)
	button(notes_page, "Copy test details", func(): DisplayServer.clipboard_set(JSON.stringify(report(), "  ")); message.text = "Report copied")
	button(notes_page, "Take full-screen picture", func(): capture(true))
	button(notes_page, "Open picture folder", func(): OS.shell_open(ProjectSettings.globalize_path(capture_directory)))
	notes_page.add_child(capture_history)
	var diagnostics := tab_page("Speed")
	metrics.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	diagnostics.add_child(metrics)
	button(diagnostics, "Check speed · about 7 seconds", begin_measurement)
	var limits := Label.new()
	limits.text = "Speed includes the whole lab window. It is not a handheld-device result.\nPause stops the test; some shader effects can still move. One frame advances the view, not an exact replay."
	limits.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	diagnostics.add_child(limits)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(status)
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(message)
	station_tools = StationTools.new()
	add_child(station_tools)
	station_tools.process_priority = 1000
	station_tools.bind(self, tab_page("View"))
	review_tools = ReviewTools.new()
	add_child(review_tools)
	review_tools.bind(self, controls_page, compare_page, notes_page)
	button(preset_row, "Rename", rename_preset)
	button(preset_row, "Delete", delete_preset)
	picker.select(clampi(int(config.get_value("workspace", "last_station", 0)), 0, FIXTURES.size()-1))
	if "--grass-prototype" in OS.get_cmdline_user_args(): picker.select(FIXTURES.keys().find("Grass / single blades"))
	if "--plant-prototype" in OS.get_cmdline_user_args(): picker.select(FIXTURES.keys().find("Plants / procedural forms"))
	if "--plant-anatomy" in OS.get_cmdline_user_args(): picker.select(FIXTURES.keys().find("Plants / biomes & Vastra anatomy"))
	if "--plant-communities" in OS.get_cmdline_user_args(): picker.select(FIXTURES.keys().find("Plants / communities"))
	if Engine.has_meta("lab_initial_station"):
		var initial := FIXTURES.values().find(str(Engine.get_meta("lab_initial_station")))
		if initial >= 0: picker.select(initial)
	load_fixture()
	add_child(save_timer)
	save_timer.wait_time = 2.0
	save_timer.one_shot = true
	save_timer.timeout.connect(func(): save_workspace(body.split_offset))
	save_timer.start()

func tab_page(title: String) -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.name = title
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sidebar.add_child(scroll)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 10)
	scroll.add_child(content)
	if title == "Settings": parameter_scroll = scroll
	return content

func fold_section(parent: Node, title: String, expanded: bool) -> VBoxContainer:
	var toggle := Button.new()
	toggle.toggle_mode = true
	toggle.set_meta("lab_fold",true)
	toggle.alignment = HORIZONTAL_ALIGNMENT_LEFT
	toggle.button_pressed = bool(group_states.get(title, expanded))
	toggle.text = ("▾ " if toggle.button_pressed else "▸ ") + title
	parent.add_child(toggle)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.visible = toggle.button_pressed
	parent.add_child(content)
	toggle.toggled.connect(func(open: bool):
		content.visible = open
		toggle.text = ("▾ " if open else "▸ ") + title
		group_states[title] = open)
	return content

func install_theme() -> void:
	theme = MenuTheme.build(MENU_SETTINGS)
	# Reuse the field menu palette for the lab's additional editing controls.
	for kind in ["LineEdit", "TextEdit"]:
		theme.set_stylebox("normal", kind, MenuTheme.box(MENU_SETTINGS.surface, MENU_SETTINGS.surface.lightened(0.1)))
		theme.set_stylebox("focus", kind, MenuTheme.box(Color.TRANSPARENT, MENU_SETTINGS.accent))
		theme.set_color("font_color", kind, MENU_SETTINGS.text)

func button(parent: Node, text: String, action: Callable) -> void:
	var item := Button.new()
	item.text = text
	if text == "One frame": item.tooltip_text = "Show the next frame, then pause. Some effects may keep moving."
	elif text == "Undo change": item.tooltip_text = "Undo the last shared setting change or reset. Older test sliders keep their own behavior."
	elif text == "Restart": item.tooltip_text = "Restart this test without losing settings, view, notes or the before picture."
	elif text == "Take picture": item.tooltip_text = "Save a picture of this test with its notes and settings."
	item.pressed.connect(action)
	parent.add_child(item)

func load_fixture() -> void:
	var key: String = FIXTURES[picker.get_item_text(picker.selected)]
	var packed := load("res://scenes/%s.tscn" % key) as PackedScene
	if packed == null:
		message.text = "Could not load station: " + key + ". Previous workspace is retained."
		return
	var same := key == active_key
	var applied := overrides.duplicate(true)
	if is_instance_valid(fixture):
		remember_station()
		if station_tools: station_tools.before_load()
		fixture.free()
	for child in station_box.get_children(): child.free()
	active_key = key
	revision_cache = ""
	var session: Dictionary = sessions.get(key, {})
	unresolved_settings = session.get("unresolved_settings", {}).duplicate(true)
	unresolved_controls = session.get("unresolved_controls", {}).duplicate(true)
	overrides = session.get("settings", {}).duplicate(true)
	if same: overrides.merge(applied, true)
	else:
		undo_settings.clear()
		undo_controls.clear()
	group_states = session.get("groups", {}).duplicate(true)
	notes.text = str(session.get("notes", ""))
	baseline = session.get("baseline", {}).duplicate(true)
	paused = bool(session.get("paused", paused))
	fixture = packed.instantiate()
	fixture.set_meta("development_workstation", true)
	defaults = exported_settings(fixture)
	var admitted := admit_settings(fixture, overrides)
	for setting in admitted.values: fixture.set(setting, admitted.values[setting])
	if fixture.has_method("workstation_restore_context"):
		var context: Dictionary = session.get("context",{}).duplicate(true)
		if same: context.merge(applied,true)
		fixture.call("workstation_restore_context",context)
	overrides.clear()
	viewport.add_child(fixture)
	if fixture.has_method("workstation_context"):
		var consumed_context: Dictionary = fixture.call("workstation_context")
		for context_key in consumed_context: admitted.unresolved.erase(context_key)
	unresolved_settings.merge(admitted.unresolved, true)
	if fixture.has_method("workstation_dock_controls"):
		fixture.call("workstation_dock_controls", station_box)
	if station_tools: station_tools.after_load()
	default_camera = camera_settings()
	apply_camera(session.get("camera", {}))
	if not reset_live_controls:
		if session.get("control_revision", "") == control_revision(): restore_controls(session.get("controls", {}))
		else: unresolved_controls.merge(session.get("controls", {}), true)
	reset_live_controls = false
	for node in descendants(fixture):
		if node is GPUParticles3D or node is GPUParticles2D: node.set_meta("workstation_speed", node.speed_scale)
	set_paused(paused)
	ticks = 0
	elapsed = 0.0
	frame_sum = 0.0
	frame_count = 0
	cancel_measurement()
	build_parameters()
	restore_scroll = int(session.get("scroll", 0))
	parameter_scroll.set_deferred("scroll_vertical", restore_scroll)
	if not focus_path.is_empty():
		var focus := parameter_box.find_child(str(focus_path), true, false) as Control
		if focus: focus.grab_focus.call_deferred()
	focus_path = NodePath()
	baseline_overlay.hide()
	baseline_view.texture = baseline_images.get(key)
	station_description.text = station_purpose(key)
	refresh_compare()
	refresh_presets()
	if review_tools: review_tools.after_load()
	DisplayServer.window_set_title("SolHunter — Development lab")
	message.text = "Ready. Right-drag to turn the view; scroll to zoom."
	if not unresolved_settings.is_empty() or not unresolved_controls.is_empty():
		message.text += " Older incompatible tuning is retained in this workspace's unresolved values."

static func admit_settings(target: Node, values: Dictionary) -> Dictionary:
	var admitted := {}
	var unresolved := {}
	var properties := {}
	for property in target.get_property_list():
		if int(property.usage) & PROPERTY_USAGE_SCRIPT_VARIABLE and int(property.usage) & PROPERTY_USAGE_EDITOR: properties[property.name] = property
	for key in values:
		var value: Variant = values[key]
		if not properties.has(key):
			unresolved[key] = value
			continue
		var property: Dictionary = properties[key]
		var expected: int = property.type
		if typeof(value) != expected and not (expected in [TYPE_INT, TYPE_FLOAT] and typeof(value) in [TYPE_INT, TYPE_FLOAT]):
			unresolved[key] = value
			continue
		if expected in [TYPE_INT, TYPE_FLOAT]:
			if not is_finite(float(value)):
				unresolved[key] = value
				continue
			if property.hint == PROPERTY_HINT_RANGE:
				var limits: PackedStringArray = str(property.hint_string).split(",")
				if float(value) < float(limits[0]) or float(value) > float(limits[1]):
					unresolved[key] = value
					continue
			if property.hint == PROPERTY_HINT_ENUM:
				var valid: Array[int] = []
				for item in str(property.hint_string).split(","):
					valid.append(int(item.get_slice(":", 1)) if ":" in item else valid.size())
				if int(value) not in valid:
					unresolved[key] = value
					continue
		admitted[key] = convert(value, expected)
	return {"values": admitted, "unresolved": unresolved}

func exported_settings(target: Node) -> Dictionary:
	var values := {}
	for property in target.get_property_list():
		if int(property.usage) & PROPERTY_USAGE_SCRIPT_VARIABLE and int(property.usage) & PROPERTY_USAGE_EDITOR:
			var value: Variant = target.get(property.name)
			if typeof(value) in [TYPE_BOOL, TYPE_INT, TYPE_FLOAT, TYPE_STRING]: values[property.name] = value
	return values

func camera_settings() -> Dictionary:
	var values := {}
	if station_tools: values["_view"] = station_tools.snapshot_camera()
	for property in fixture.get_property_list():
		if property.name in ["yaw", "pitch", "distance", "distance_value", "camera_yaw", "camera_pitch", "camera_distance"]:
			values[property.name] = fixture.get(property.name)
	return values

func apply_camera(values: Dictionary) -> void:
	for key in values:
		if key != "_view": fixture.set(key, values[key])
	if fixture.has_method("update_camera"): fixture.call("update_camera")
	if station_tools and values.has("_view"): station_tools.restore_camera(values._view)

func control_address(root: Node, node: Node) -> String:
	var parts: Array[String] = []
	while node != root:
		parts.push_front(str(node.get_index()))
		node = node.get_parent()
	return "/".join(parts)

func control_at(root: Node, address: String) -> Node:
	var node := root
	if address.is_empty(): return node
	for part in address.split("/"):
		if not part.is_valid_int() or int(part) >= node.get_child_count(): return null
		node = node.get_child(int(part))
	return node

func control_settings() -> Dictionary:
	var values := {}
	if not station_tools: return values
	var controls: Dictionary = station_tools.control_map()
	for key in controls:
		var node: Node = controls[key]
		if node is OptionButton: values[key] = node.selected
		elif node is Range: values[key] = node.value
		elif node is BaseButton: values[key] = node.button_pressed
	return values

func restore_controls(values: Dictionary) -> void:
	if not station_tools: return
	var controls: Dictionary = station_tools.control_map()
	if fixture.has_method("workstation_restore_controls"):
		fixture.call("workstation_restore_controls", values, controls)
		return
	for key in values:
		var node: Node = controls.get(key)
		if node is OptionButton:
			var index := int(values[key])
			if index >= 0 and index < node.item_count:
				node.select(index)
				node.item_selected.emit(index)
		elif node is Range: node.value = float(values[key])
		elif node is BaseButton and node.toggle_mode: node.button_pressed = bool(values[key])

func control_revision() -> String:
	if not revision_cache.is_empty(): return revision_cache
	for entry in Catalogue.discover().stations:
		if entry.get("fixture_key", "") == active_key:
			revision_cache = "workspace-4:" + Catalogue.fingerprint(entry, true)
			return revision_cache
	return "workspace-4:unregistered"

func remember_station() -> void:
	if not is_instance_valid(fixture) or active_key.is_empty(): return
	sessions[active_key] = {"review_draft": review_tools.draft() if review_tools else {}, "control_revision": control_revision(), "settings": exported_settings(fixture), "notes": notes.text, "camera": camera_settings(), "controls": control_settings(), "paused": paused, "baseline": baseline.duplicate(true), "visited_at": Time.get_unix_time_from_system(), "scroll": parameter_scroll.scroll_vertical, "groups": group_states.duplicate(true)}
	sessions[active_key]["unresolved_settings"] = unresolved_settings.duplicate(true)
	sessions[active_key]["unresolved_controls"] = unresolved_controls.duplicate(true)
	if fixture.has_method("workstation_context"): sessions[active_key]["context"]=fixture.call("workstation_context")

func save_workspace(split: int = 950) -> bool:
	remember_station()
	var config := ConfigFile.new()
	var saved := sessions.duplicate(true)
	# Baseline images are session-only; never restore a report without its image.
	for key in saved: saved[key].erase("baseline")
	config.set_value("workspace", "stations", saved)
	config.set_value("workspace", "presets", presets)
	config.set_value("workspace", "favorites", favorites)
	config.set_value("workspace", "last_station", picker.selected)
	config.set_value("workspace", "split", split)
	DirAccess.make_dir_recursive_absolute(session_path.get_base_dir())
	if config.save(session_path) != OK:
		message.text = "Could not save local workspace settings."
		return false
	return true

func apply_parameter(key: String, value: Variant) -> void:
	var selected_before: String = station_tools.selected_id if station_tools else ""
	undo_settings = exported_settings(fixture)
	undo_controls = control_settings()
	var focused := get_viewport().gui_get_focus_owner()
	if focused != null and parameter_box.is_ancestor_of(focused): focus_path = NodePath(str(focused.name))
	overrides[key] = value
	if fixture.has_method("workstation_apply_parameter") and fixture.call("workstation_apply_parameter", key, value):
		overrides.erase(key)
		build_parameters()
		refresh_tuned_station(selected_before)
		refresh_compare()
		if not Engine.has_meta("lab_bridge_attached"): save_timer.start()
		return
	if fixture.has_method("workstation_reframe_on_change") and fixture.call("workstation_reframe_on_change",key): overrides["maker_fit_view"]=true
	load_fixture.call_deferred()

func refresh_tuned_station(previous_id: String) -> void:
	if not station_tools: return
	station_tools.model_bounds.clear()
	station_tools.subjects.clear()
	station_tools.collect_subjects()
	station_tools.refresh_subject_picker()
	var index := -1
	for i in range(station_tools.subjects.size()):
		if station_tools.subjects[i].id == previous_id: index = i; break
	station_tools.choose_subject(index)
	if fixture.get_meta("lab_update_effect", "geometry") != "presentation" and station_tools.view_mode != 0:
		station_tools.set_view_mode(station_tools.view_mode)

func restart_fixture() -> void:
	load_fixture()

func restore_defaults() -> void:
	undo_settings = exported_settings(fixture)
	undo_controls = control_settings()
	reset_live_controls = true
	overrides = defaults.duplicate(true)
	load_fixture()

func undo_tuning() -> void:
	var selected_before: String = station_tools.selected_id if station_tools else ""
	if undo_settings.is_empty():
		message.text = "No shared tuning change to undo."
		return
	var previous := exported_settings(fixture)
	var previous_controls := control_settings()
	var restoring_controls := undo_controls.duplicate(true)
	if fixture.has_method("workstation_apply_parameters") and fixture.call("workstation_apply_parameters", undo_settings):
		restore_controls(restoring_controls)
		undo_settings = previous
		undo_controls = previous_controls
		build_parameters()
		refresh_tuned_station(selected_before)
		refresh_compare()
		if not Engine.has_meta("lab_bridge_attached"): save_timer.start()
		return
	overrides = undo_settings.duplicate(true)
	load_fixture()
	restore_controls(restoring_controls)
	undo_settings = previous
	undo_controls = previous_controls
	refresh_compare()

func reset_camera() -> void:
	apply_camera(default_camera)
	if station_tools: station_tools.reset_view()

func station_purpose(key: String) -> String:
	for entry in Catalogue.discover().stations:
		if entry.get("fixture_key", "") == key: return entry.description
	return "Station metadata is unavailable."

func set_paused(value: bool) -> void:
	var was_paused := paused
	paused = value
	pause_button.text = "Resume" if paused else "Pause"
	if is_instance_valid(fixture): fixture.process_mode = Node.PROCESS_MODE_DISABLED if paused else Node.PROCESS_MODE_INHERIT
	viewport.physics_object_picking = not paused
	# GPU particles do not inherit Node processing pauses.
	for node in descendants(fixture):
		if node is GPUParticles3D or node is GPUParticles2D:
			if paused and not was_paused: node.set_meta("workstation_speed", node.speed_scale)
			node.speed_scale = 0.0 if paused else float(node.get_meta("workstation_speed", 1.0))

func step_once() -> void:
	if stepping: return
	stepping = true
	set_paused(false)
	await get_tree().process_frame
	await get_tree().process_frame
	set_paused(true)
	stepping = false

func descendants(node: Node) -> Array[Node]:
	var result: Array[Node] = []
	if not is_instance_valid(node): return result
	result.append(node)
	for child in node.get_children(): result.append_array(descendants(child))
	return result

func _process(delta: float) -> void:
	if not paused:
		frame_sum += delta * 1000.0
		frame_count += 1
		last_ms = frame_sum / frame_count
	update_measurement(delta)
	status.text = "%s · %s · %.1f s · before picture %s" % [picker.get_item_text(picker.selected), "Paused · some effects may still move" if paused else "Running", elapsed, "saved" if not baseline.is_empty() else "not taken"]
	if not paused:
		elapsed += delta
		ticks += 1
	var speed := "Not checked yet"
	if not measurement_result.is_empty():
		speed = "Average %.2f ms · slow frames %.2f ms · %d samples" % [float(measurement_result.mean_ms),float(measurement_result.p95_ms),int(measurement_result.samples)] if measurement_result.get("status") == "Complete" else str(measurement_result.get("status",""))
	metrics.text = "Speed check: %s\n\n%s · %.1f seconds\nCurrent average: %.2f ms per frame\nDrawing work: %d calls · %d objects\nPicture size: %s" % [speed,"Paused" if paused else "Running",elapsed,last_ms,viewport.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE,Viewport.RENDER_INFO_DRAW_CALLS_IN_FRAME),viewport.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE,Viewport.RENDER_INFO_OBJECTS_IN_FRAME),str(viewport.size)]


func build_parameters() -> void:
	for child in parameter_box.get_children():
		parameter_box.remove_child(child)
		child.queue_free()
	var parameter_count := 0
	var parameter_group := ""
	var parameter_parent := parameter_box
	var properties := fixture.get_property_list()
	if fixture.has_method("workstation_parameter_info"):
		properties.sort_custom(func(a: Dictionary, b: Dictionary): return int(fixture.call("workstation_parameter_info", str(a.name)).get("order", 1000)) < int(fixture.call("workstation_parameter_info", str(b.name)).get("order", 1000)))
	for property in properties:
		if not (int(property.usage) & PROPERTY_USAGE_SCRIPT_VARIABLE and int(property.usage) & PROPERTY_USAGE_EDITOR): continue
		var key: String = property.name
		var value: Variant = fixture.get(key)
		if typeof(value) not in [TYPE_BOOL, TYPE_INT, TYPE_FLOAT, TYPE_STRING]: continue
		var info: Dictionary = fixture.call("workstation_parameter_info",key) if fixture.has_method("workstation_parameter_info") else {}
		if bool(info.get("hidden",false)): continue
		var group: String = str(info.get("group",""))
		if not group.is_empty() and group != parameter_group:
			parameter_group = group
			parameter_parent = fold_section(parameter_box, group, group in ["Appearance", "Coverage", "Motion", "View"])
			button(parameter_parent, "Reset this group", func(): reset_parameter_group(group))
		parameter_count += 1
		var display_name: String = str(info.get("label",simple_parameter_name(key)))
		var label := Label.new()
		label.text = display_name + (" •" if value != defaults.get(key, value) else "")
		label.tooltip_text = str(info.get("help",""))
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var label_row := HBoxContainer.new()
		parameter_parent.add_child(label_row)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label_row.add_child(label)
		button(label_row, "↺", func(): apply_parameter(key, defaults[key]))
		if typeof(value) == TYPE_BOOL:
			var toggle := CheckButton.new()
			toggle.text = "On"
			toggle.button_pressed = value
			parameter_parent.add_child(toggle)
			toggle.name = key + "Toggle"
			toggle.toggled.connect(func(enabled: bool): apply_parameter(key, enabled))
			continue
		if typeof(value) in [TYPE_INT, TYPE_FLOAT] and int(property.hint) == PROPERTY_HINT_RANGE:
			var limits: PackedStringArray = str(property.hint_string).split(",")
			var slider := HSlider.new()
			slider.name = key + "Slider"
			slider.min_value = float(info.get("min",limits[0]))
			slider.max_value = float(info.get("max",limits[1]))
			slider.step = float(limits[2]) if limits.size() > 2 else (1.0 if typeof(value) == TYPE_INT else 0.01)
			slider.exp_edit = bool(info.get("exponential",false)) and slider.min_value>0.0
			slider.value = float(value)
			slider.custom_minimum_size = Vector2(100,28)
			slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			slider.tooltip_text = "Drag to adjust; release to apply. Arrow keys also work."
			label.text = "%s: %s%s" % [display_name,str(value), " •" if value != defaults.get(key, value) else ""]
			var slider_row := HBoxContainer.new()
			parameter_parent.add_child(slider_row)
			slider_row.add_child(slider)
			var precise := SpinBox.new()
			precise.name = key + "Number"
			precise.min_value = slider.min_value
			precise.max_value = slider.max_value
			precise.step = slider.step
			precise.value = slider.value
			precise.update_on_text_changed = false
			precise.tooltip_text = "Type an exact number, then press Enter or use the small arrows."
			precise.custom_minimum_size.x = 90
			slider_row.add_child(precise)
			precise.value_changed.connect(func(number: float): slider.value = number)
			slider.value_changed.connect(func(number: float): precise.set_value_no_signal(number))
			var debounce := Timer.new()
			debounce.one_shot = true
			debounce.wait_time = 0.3
			slider.add_child(debounce)
			var apply_slider := func():
				if slider.has_meta("dragging") and slider.get_meta("dragging"): return
				apply_parameter(key, slider.value if typeof(value) == TYPE_FLOAT else int(slider.value))
			debounce.timeout.connect(apply_slider)
			slider.drag_started.connect(func(): slider.set_meta("dragging",true))
			slider.drag_ended.connect(func(changed: bool):
				slider.set_meta("dragging",false)
				if changed: debounce.stop(); apply_slider.call())
			slider.value_changed.connect(func(number: float):
				var converted: Variant = int(number) if typeof(value) == TYPE_INT else number
				overrides[key] = converted
				message.text = "Release to apply · " + display_name
				label.text = "%s: %s" % [display_name,str(converted)]
				debounce.start())
			continue
		if int(property.hint) == PROPERTY_HINT_ENUM:
			var selector := OptionButton.new()
			var options := str(property.hint_string).split(",")
			for option in options:
				var parts := option.split(":")
				selector.add_item(parts[0], int(parts[1]) if parts.size() > 1 else selector.item_count)
			selector.select(selector.get_item_index(int(value)) if typeof(value) == TYPE_INT else options.find(str(value)))
			parameter_parent.add_child(selector)
			selector.item_selected.connect(func(index: int): apply_parameter(key, selector.get_item_id(index) if typeof(value) == TYPE_INT else options[index]))
			continue
		var edit := LineEdit.new()
		edit.text = str(value)
		parameter_parent.add_child(edit)
		var apply := func():
			if typeof(value) in [TYPE_INT, TYPE_FLOAT] and not edit.text.is_valid_float():
				message.text = "Enter a number for " + key
				return
			var converted: Variant = convert(edit.text, typeof(value))
			if typeof(value) == TYPE_BOOL: converted = edit.text.to_lower() in ["true", "1", "yes"]
			if int(property.hint) == PROPERTY_HINT_RANGE:
				var limits: PackedStringArray = str(property.hint_string).split(",")
				converted = clampf(float(converted), float(limits[0]), float(limits[1]))
				if typeof(value) == TYPE_INT: converted = int(converted)
			apply_parameter(key, converted)
		edit.text_submitted.connect(func(_text: String): apply.call())
		button(parameter_parent, "Apply", apply)
	if parameter_count == 0:
		var empty := Label.new()
		empty.text = "Use the test controls above. Extra project settings are available in Godot."
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		parameter_parent.add_child(empty)

func report() -> Dictionary:
	var state := {}
	if is_instance_valid(fixture):
		for property in fixture.get_property_list():
			if not int(property.usage) & PROPERTY_USAGE_SCRIPT_VARIABLE: continue
			var value: Variant = fixture.get(property.name)
			if typeof(value) in [TYPE_BOOL, TYPE_INT, TYPE_FLOAT, TYPE_STRING, TYPE_VECTOR2, TYPE_VECTOR3]: state[property.name] = value
	var controls := control_settings()
	for node in descendants(fixture):
		if node is Range: controls[str(fixture.get_path_to(node))] = node.value
		elif node is OptionButton: controls[str(fixture.get_path_to(node))] = node.get_item_text(node.selected) if node.selected >= 0 else ""
		elif node is BaseButton and node.toggle_mode: controls[str(fixture.get_path_to(node))] = node.button_pressed
	var camera := viewport.get_camera_3d()
	var readings := {}
	if is_instance_valid(fixture) and fixture.has_method("workstation_readings"): readings = fixture.call("workstation_readings")
	if is_instance_valid(fixture) and fixture.get("plant_nodes") is Node:
		var plants: Node = fixture.get("plant_nodes")
		readings = {"total": plants.get("total"), "stored_total": plants.call("stored_total"), "received": plants.get("received")}
		var rows: Array = []
		for row in plants.get("rows"):
			var values := {}
			for key in row:
				if typeof(row[key]) in [TYPE_BOOL, TYPE_INT, TYPE_FLOAT, TYPE_STRING]: values[key] = row[key]
			rows.append(values)
		readings["plants"] = rows
	return {"schema": 3, "view_options": {"names":station_tools.labels_visible,"tips":station_tools.hints_visible,"mode":station_tools.view_mode,"ruler":is_instance_valid(station_tools.scale_lines) and station_tools.scale_lines.visible,"endpoints":station_tools.endpoint_toggle.button_pressed}, "test":review_tools.current_task, "setup": exported_settings(fixture), "camera_settings": camera_settings(), "restorable_controls": control_settings(), "measurement": measurement_result, "renderer": RenderingServer.get_current_rendering_method(), "fixture": FIXTURES[picker.get_item_text(picker.selected)], "timestamp": Time.get_datetime_string_from_system(), "notes": notes.text, "paused": paused, "frames": ticks, "elapsed_seconds": elapsed, "host_mean_ms": last_ms, "viewport_size": str(viewport.size), "fixture_state": state, "readings": readings, "controls": controls, "camera_transform": str(camera.global_transform) if camera else "none", "baseline": baseline.duplicate(true) if not baseline.is_empty() else {}}

func capture(workspace: bool = false) -> void:
	var directory := capture_directory
	if DirAccess.make_dir_recursive_absolute(directory) != OK:
		message.text = "Could not create capture folder"
		return
	var hidden: Dictionary = station_tools.hide_for_picture() if review_tools.capture_without_labels and not workspace else {}
	await RenderingServer.frame_post_draw
	var stem := directory + "/" + active_key + "_" + str(Time.get_unix_time_from_system()).replace(".", "_")
	var image := get_viewport().get_texture().get_image() if workspace else viewport.get_texture().get_image()
	if not hidden.is_empty(): station_tools.restore_after_picture(hidden)
	var result := image.save_png(stem + ".png")
	var file := FileAccess.open(stem + ".json", FileAccess.WRITE)
	if result != OK or file == null:
		message.text = "Capture failed; check available disk space"
		return
	var data := report()
	data["capture_kind"] = "workspace" if workspace else "preview"
	data["picture_options"] = {"names_and_tips_hidden":not hidden.is_empty()}
	file.store_string(JSON.stringify(data, "  "))
	file.close()
	last_capture_path = stem
	var thumbnail := TextureRect.new()
	thumbnail.texture = ImageTexture.create_from_image(image)
	thumbnail.custom_minimum_size.y = 100
	thumbnail.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	thumbnail.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	capture_history.add_child(thumbnail)
	var recent := Button.new()
	recent.text = active_key + " · open capture"
	recent.pressed.connect(func(): OS.shell_open(ProjectSettings.globalize_path(stem + ".png")))
	capture_history.add_child(recent)
	if capture_history.get_child_count() > 16:
		capture_history.get_child(0).queue_free()
		capture_history.get_child(1).queue_free()
	message.text = "Saved PNG + report:\n" + ProjectSettings.globalize_path(stem)


func set_baseline() -> void:
	if DisplayServer.get_name() == "headless":
		baseline.clear()
		baseline = report()
	else:
		var hidden: Dictionary = station_tools.hide_for_picture() if review_tools.capture_without_labels else {}
		await RenderingServer.frame_post_draw
		if not is_instance_valid(fixture): return
		baseline.clear()
		baseline = report()
		baseline_images[active_key] = ImageTexture.create_from_image(viewport.get_texture().get_image())
		baseline_view.texture = baseline_images[active_key]
		if not hidden.is_empty(): station_tools.restore_after_picture(hidden)
	refresh_compare()
	message.text = "Before picture saved. Change a setting, then compare. Save a review to keep the picture after closing."

func refresh_compare() -> void:
	if baseline.is_empty():
		compare_text.text = "Take a before picture, then change one thing. You can restore its settings here."
		return
	var changes: Array[String] = []
	var before: Dictionary = baseline.get("setup", {})
	var current := exported_settings(fixture)
	for key in current:
		if current[key] != before.get(key): changes.append("%s: %s → %s" % [key.capitalize(), str(before.get(key)), str(current[key])])
	if control_settings() != baseline.get("restorable_controls", {}): changes.append("Some test controls changed.")
	if str(viewport.size) != baseline.get("viewport_size", ""): changes.append("The picture size changed. Speed results may not compare fairly.")
	if camera_settings() != baseline.get("camera_settings", {}): changes.append("The view moved. Use the before camera to line it up.")
	compare_text.text = "What changed:\n" + ("The settings match." if changes.is_empty() else "\n".join(changes)) + "\nMoving effects may be at different times."

func toggle_baseline() -> void:
	if not baseline_images.has(active_key):
		message.text = "Take a before picture first."
		return
	baseline_overlay.texture = baseline_images[active_key]
	baseline_overlay.material = null
	baseline_overlay.visible = not baseline_overlay.visible
	message.text = "Showing before · click Before / now to return" if baseline_overlay.visible else "Showing now"

func restore_baseline() -> void:
	if baseline.is_empty(): return
	var saved := baseline.duplicate(true)
	overrides = saved.get("setup", {}).duplicate(true)
	load_fixture()
	apply_camera(saved.get("camera_settings", {}))
	restore_controls(saved.get("restorable_controls", {}))
	refresh_compare()

func save_preset() -> void:
	var title := preset_name.text.strip_edges()
	if title.is_empty():
		message.text = "Give these settings a name first."
		return
	var station_presets: Dictionary = presets.get(active_key, {})
	if station_presets.has(title):
		message.text = "That name is already used. Pick another name, or rename the saved item."
		return
	station_presets[title] = {"schema": 1, "control_revision": control_revision(), "settings": exported_settings(fixture), "camera": camera_settings(), "controls": control_settings()}
	presets[active_key] = station_presets
	save_workspace()
	refresh_presets()
	message.text = "Settings saved: " + title

func refresh_presets() -> void:
	preset_picker.clear()
	for title in presets.get(active_key, {}): preset_picker.add_item(title)

func load_preset() -> void:
	if preset_picker.selected < 0: return
	var saved: Dictionary = presets[active_key][preset_picker.get_item_text(preset_picker.selected)]
	if int(saved.get("schema", 0)) != 1:
		message.text = "This preset uses an unsupported format."
		return
	overrides = saved.settings.duplicate(true)
	load_fixture()
	apply_camera(saved.camera)
	if saved.get("control_revision", "") == control_revision(): restore_controls(saved.controls)
	else: message.text = "This test has changed since you saved it. Settings and view restored; check the test controls."
	refresh_compare()

func open_browser(initial_query: String = "") -> void:
	var dialog := AcceptDialog.new()
	dialog.title = "Creative additions · concepts to review" if not initial_query.is_empty() else "Choose a test · favorites and recent tests first"
	dialog.size = Vector2i(620, 540)
	add_child(dialog)
	var box := VBoxContainer.new()
	dialog.add_child(box)
	var search := LineEdit.new()
	search.placeholder_text = "Find relics, grass, plants, lighting…"
	box.add_child(search)
	var list := ItemList.new()
	list.custom_minimum_size = Vector2(560, 300)
	box.add_child(list)
	var description := Label.new()
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(description)
	var populate := func(query: String):
		list.clear()
		var titles: Array = FIXTURES.keys()
		titles.sort_custom(func(a: String, b: String):
			if favorites.has(a) != favorites.has(b): return favorites.has(a)
			return float(sessions.get(FIXTURES[a], {}).get("visited_at", 0)) > float(sessions.get(FIXTURES[b], {}).get("visited_at", 0)))
		for title in titles:
			if query.is_empty() or query.to_lower() in str(title).to_lower():
				list.add_item(("★ " if favorites.has(title) else "") + title)
				list.set_item_metadata(list.item_count-1, title)
	search.text = initial_query
	populate.call(initial_query)
	search.text_changed.connect(populate)
	list.item_selected.connect(func(index: int): description.text = station_purpose(FIXTURES[list.get_item_metadata(index)]))
	button(box, "Add / remove favorite", func():
		if list.get_selected_items().is_empty(): return
		var title: String = list.get_item_metadata(list.get_selected_items()[0])
		if favorites.has(title): favorites.erase(title)
		else: favorites.append(title)
		save_workspace()
		populate.call(search.text))
	var open := func():
		if list.get_selected_items().is_empty(): return
		picker.select(FIXTURES.keys().find(list.get_item_metadata(list.get_selected_items()[0])))
		load_fixture()
		dialog.queue_free()
	list.item_activated.connect(func(_index: int): open.call())
	dialog.confirmed.connect(open)
	dialog.canceled.connect(dialog.queue_free)
	dialog.popup_centered()
	search.grab_focus()

func begin_measurement() -> void:
	if paused:
		message.text = "Press Resume before checking speed."
		return
	measuring = true
	measurement_context = {"viewport": viewport.size, "setup": exported_settings(fixture), "controls": control_settings(), "camera": camera_settings()}
	measurement_warmup = 2.0
	measurement_samples.clear()
	measurement_result = {"status": "Getting ready…"}

func cancel_measurement() -> void:
	if measuring: measurement_result = {"status": "Stopped because the test or view changed"}
	measuring = false

func update_measurement(delta: float) -> void:
	if not measuring: return
	if paused or viewport.size != measurement_context.get("viewport") or exported_settings(fixture) != measurement_context.get("setup") or control_settings() != measurement_context.get("controls") or camera_settings() != measurement_context.get("camera"):
		cancel_measurement()
		return
	if measurement_warmup > 0:
		measurement_warmup -= delta
		return
	measurement_samples.append(delta * 1000.0)
	var total := 0.0
	for sample in measurement_samples: total += sample
	if total < 5000: return
	measurement_samples.sort()
	measurement_result = {"status": "Complete", "samples": measurement_samples.size(), "seconds": total / 1000.0, "mean_ms": total / measurement_samples.size(), "p95_ms": measurement_samples[int((measurement_samples.size()-1)*0.95)], "viewport": str(viewport.size), "renderer": RenderingServer.get_current_rendering_method()}
	measuring = false


func rename_preset() -> void:
	if preset_picker.selected < 0: return
	var title := preset_name.text.strip_edges()
	var old := preset_picker.get_item_text(preset_picker.selected)
	var saved: Dictionary = presets.get(active_key,{})
	if title.is_empty() or (title != old and saved.has(title)):
		message.text = "Enter a new, unused name."
		return
	var value: Variant = saved[old]
	saved.erase(old)
	saved[title] = value
	presets[active_key] = saved
	save_workspace()
	refresh_presets()
	message.text = "Renamed settings to " + title

func delete_preset() -> void:
	if preset_picker.selected < 0: return
	var title := preset_picker.get_item_text(preset_picker.selected)
	presets[active_key].erase(title)
	save_workspace()
	refresh_presets()
	message.text = "Deleted saved settings: " + title


func reset_parameter_group(group: String) -> void:
	undo_settings = exported_settings(fixture)
	undo_controls = control_settings()
	for key in defaults:
		var info: Dictionary = fixture.call("workstation_parameter_info",key) if fixture.has_method("workstation_parameter_info") else {}
		if str(info.get("group","")) == group: overrides[key] = defaults[key]
	load_fixture()


func simple_parameter_name(key: String) -> String:
	return str({"max_members":"Particle limit","trail_samples":"Trail detail","field_radius":"Effect radius","generation_seed":"Random pattern","study_seed":"Random pattern","scatter_seed":"Random pattern","exercise":"Movement test","walk_speed":"Travel speed (m/s)","affinity":"Sol affinity","mood_strength":"Mood strength","mood_transition_seconds":"Mood change time (seconds)","pixel_filter_enabled":"Use pixel effect","nearest_textures":"Use sharp texture pixels","effect_mode":"Pixel size"}.get(key,key.capitalize()))
