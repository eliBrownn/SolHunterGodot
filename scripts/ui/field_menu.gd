extends Node
## One exploration menu; UI preferences are separate from authoritative expedition saves.

const MenuTheme = preload("res://scripts/ui/menu_theme.gd")
const SECTIONS := [["guide", "Field Guide", "Recorded sightings"], ["sols", "Sols", "Party, storage & moves"], ["bag", "Bag", "Seals & supplies"], ["trainer", "Trainer", "Your expedition"], ["journal", "Journal", "Journey & session notes"], ["save", "Save", "Keep your progress"], ["options", "Options", "Make yourself comfortable"]]
var world: Node2D
var settings: MenuSettings
var frame := Panel.new()
var backdrop := ColorRect.new()
var header := PanelContainer.new()
var resize_handle := Button.new()
var launcher := Button.new()
var page_stack := Control.new()
var pages: Dictionary = {}
var navigation: Dictionary = {}
var section_heading: Label
var title: Label
var subtitle: Label
var feedback: Label
var frame_style: StyleBoxFlat
var preferences_path := "user://menu_preferences.cfg"
var save_path := ExpeditionSave.SAVE_PATH
var opened := false
var selected := "sols"
var requested_scale := 1.0
var opacity := 0.97
var dragging := false
var resizing := false
var pointer_origin := Vector2.ZERO
var drag_rect := Rect2()
var save_timer := Timer.new()
var scale_slider: HSlider
var opacity_slider: HSlider
var party_summary: Label
var sol_screen: Control
var sol_selection := ""
var sol_filter := "party"
var sol_tab := "details"
var sol_info_section := "overview"
var sol_starter := 0
var sol_list_scroll := 0
var sol_detail_scroll := 0
var feedback_age := 0.0
var last_feedback := ""
var guide_context: Dictionary = {}
var guide_back: Button
var text_slider: HSlider
var collection_state: ExpeditionState
var collection_refresh_pending := false


func bind(source: Node2D, tuning: MenuSettings) -> void:
	world = source
	settings = tuning.duplicate(false) if tuning != null and tuning.valid() else MenuSettings.new()
	if tuning == null or not tuning.valid():
		push_warning("Invalid menu settings; using default field-menu layout.")
	requested_scale = settings.ui_scale
	opacity = settings.background_opacity
	backdrop.color = Color(0.025, 0.05, 0.04, 0.08)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	world.hud.add_child(backdrop)
	frame.theme = MenuTheme.build(settings)
	frame_style = MenuTheme.box(Color(settings.background, opacity), settings.surface.lightened(0.25), 14)
	frame_style.shadow_color = Color(0, 0, 0, 0.35)
	frame_style.shadow_size = 12
	frame.add_theme_stylebox_override("panel", frame_style)
	frame.custom_minimum_size = settings.minimum_size
	frame.size = settings.window_size
	world.hud.add_child(frame)
	build_shell()
	frame.position = (frame.get_viewport_rect().size - frame.size * requested_scale * settings.size_multiplier) * 0.5
	if settings.remember_layout:
		load_preferences()
	fit_layout()
	backdrop.hide()
	frame.hide()
	launcher.text = "Menu · R"
	launcher.tooltip_text = "R · menu\nEsc · pause\nWASD · walk\nShift · run\nMiddle-drag · camera\nWheel · zoom\nHome · reset camera"
	launcher.theme = frame.theme
	launcher.anchor_left = 1
	launcher.anchor_right = 1
	launcher.offset_left = -154
	launcher.offset_right = -24
	launcher.offset_top = 128
	launcher.offset_bottom = 170
	launcher.pressed.connect(func() -> void: open(selected))
	world.hud.add_child(launcher)
	world.state_replaced.connect(on_state)
	watch_collection(world.persistent_state)
	get_viewport().size_changed.connect(fit_layout)
	get_window().focus_exited.connect(finish_drag)
	save_timer.one_shot = true
	save_timer.wait_time = 0.25
	save_timer.timeout.connect(save_preferences)
	add_child(save_timer)

func caption(text: String, size: int = 16, color: Color = Color.TRANSPARENT) -> Label:
	var label: Label = world.label(text, size, settings.text if color == Color.TRANSPARENT else color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label

func button(text: String, action: Callable, parent: Node) -> Button:
	var node := Button.new()
	node.text = text
	node.custom_minimum_size.y = 30
	node.pressed.connect(action)
	parent.add_child(node)
	return node

func build_shell() -> void:
	var shell := VBoxContainer.new()
	shell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shell.offset_left = 18
	shell.offset_right = -18
	shell.offset_top = 12
	shell.offset_bottom = -18
	shell.add_theme_constant_override("separation", 8)
	frame.add_child(shell)
	header.custom_minimum_size.y = 32
	header.mouse_default_cursor_shape = Control.CURSOR_MOVE
	header.gui_input.connect(begin_drag)
	header.tooltip_text = "Drag to move this window."
	header.add_theme_stylebox_override("panel", MenuTheme.box(Color.TRANSPARENT, Color.TRANSPARENT, 0))
	shell.add_child(header)
	var top := HBoxContainer.new()
	header.add_child(top)
	var brand := caption("Sols", 22, settings.accent)
	section_heading = brand
	brand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(brand)
	button("Close", close, top).tooltip_text = "Close menu · R"
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 12)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	shell.add_child(body)
	var sidebar := VBoxContainer.new()
	sidebar.custom_minimum_size.x = 124
	sidebar.add_theme_constant_override("separation", 4)
	var sidebar_scroll := ScrollContainer.new()
	sidebar_scroll.custom_minimum_size.x = 124
	sidebar_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sidebar_scroll.follow_focus = true
	body.add_child(sidebar_scroll)
	sidebar_scroll.add_child(sidebar)
	var group := ButtonGroup.new()
	for index in range(SECTIONS.size()):
		var section: Array = SECTIONS[index]
		var nav := button(str(section[1]), select_page.bind(section[0]), sidebar)
		nav.alignment = HORIZONTAL_ALIGNMENT_LEFT
		nav.toggle_mode = true
		nav.button_group = group
		nav.custom_minimum_size.y = 34
		nav.flat = false
		nav.add_theme_color_override("font_pressed_color", settings.accent)
		nav.add_theme_color_override("font_hover_pressed_color", settings.accent)
		nav.tooltip_text = section[2]
		navigation[section[0]] = nav
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 6)
	body.add_child(content)
	title = caption("", 26, settings.accent)
	subtitle = caption("", 14, settings.text.darkened(0.2))
	content.add_child(title)
	content.add_child(subtitle)
	title.hide()
	subtitle.hide()
	page_stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(page_stack)
	for section in SECTIONS:
		var page := VBoxContainer.new()
		page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		page.add_theme_constant_override("separation", 12)
		page_stack.add_child(page)
		pages[section[0]] = page
		page.hide()
	world.journal_notes.size_flags_vertical = Control.SIZE_EXPAND_FILL
	world.journal_notes.add_theme_font_size_override("normal_font_size", settings.font_size)
	world.journal_notes.selection_enabled = true
	guide_back = button("All entries", func() -> void:
		guide_context.clear()
		guide_back.hide()
		world.refresh_discoveries(), pages.guide)
	guide_back.hide()
	pages.guide.add_child(world.journal_notes)
	world.history.size_flags_vertical = Control.SIZE_EXPAND_FILL
	world.history.add_theme_font_size_override("normal_font_size", settings.font_size)
	world.history.selection_enabled = true
	pages.journal.add_child(world.history)
	feedback = caption("", 13, settings.text.darkened(0.2))
	feedback.hide()
	shell.add_child(feedback)
	resize_handle.text = "◢"
	resize_handle.flat = false
	resize_handle.tooltip_text = "Drag to resize this window."
	resize_handle.mouse_default_cursor_shape = Control.CURSOR_FDIAGSIZE
	resize_handle.anchor_left = 1
	resize_handle.anchor_right = 1
	resize_handle.anchor_top = 1
	resize_handle.anchor_bottom = 1
	resize_handle.offset_left = -30
	resize_handle.offset_top = -30
	resize_handle.gui_input.connect(begin_resize)
	frame.add_child(resize_handle)

func _process(delta: float) -> void:
	if opened:
		apply_text_size()
	if feedback.text != last_feedback:
		last_feedback = feedback.text
		feedback_age = 0.0
	feedback_age += delta
	feedback.visible = not feedback.text.is_empty() and feedback_age < 3.0
	launcher.visible = not opened and not world.paused and not world.encounter_active and not world.confirmation.visible

func open(section: String = "") -> void:
	if world.paused or world.encounter_active or world.confirmation.visible:
		return
	if not opened:
		feedback.text = ""
		world.observation_menu.hide()
		if not world.inspection_card.pin.button_pressed:
			world.inspected_cell = null
		world.inspection_panel.hide()
		world.interaction_hint.get_parent().hide()
		opened = true
	backdrop.show()
	frame.show()
	# HUD labels are built after the menu; raise the modal above every HUD sibling.
	world.hud.move_child(backdrop, -1)
	world.hud.move_child(frame, -1)
	launcher.hide()
	select_page(section if pages.has(section) else selected)
	fit_layout()
	navigation[selected].grab_focus()

func close() -> void:
	if not opened:
		return
	finish_drag()
	if selected == "sols" and is_instance_valid(sol_screen) and sol_screen.is_inside_tree():
		sol_screen.remember_scroll()
	opened = false
	for child in world.hud.get_children():
		if child is Window and child.get_meta("field_menu_owned", false):
			child.hide()
			child.queue_free()
	frame.hide()
	backdrop.hide()
	launcher.release_focus()

func on_state(_state: ExpeditionState) -> void:
	guide_context.clear()
	guide_back.hide()
	watch_collection(_state)
	close()
	sol_selection = ""
	sol_tab = "details"
	sol_info_section = "overview"
	sol_filter = "party"
	sol_list_scroll = 0
	sol_detail_scroll = 0

func watch_collection(state: ExpeditionState) -> void:
	if collection_state != null and collection_state.battle_progress_changed.is_connected(queue_collection_refresh):
		collection_state.battle_progress_changed.disconnect(queue_collection_refresh)
	collection_state = state
	collection_state.battle_progress_changed.connect(queue_collection_refresh)

func queue_collection_refresh() -> void:
	if not opened or selected != "sols" or collection_refresh_pending:
		return
	collection_refresh_pending = true
	# Capture focus before the command's embedded editor replaces its own buttons.
	var focused := frame.get_viewport().gui_get_focus_owner()
	var action: String = focused.get_meta("training_action", "") if focused != null and frame.is_ancestor_of(focused) else ""
	refresh_collection.call_deferred(collection_state, action)

func refresh_collection(state: ExpeditionState, action: String) -> void:
	collection_refresh_pending = false
	if state != collection_state or state != world.persistent_state or not opened or selected != "sols":
		return
	if is_instance_valid(sol_screen) and sol_screen.is_inside_tree():
		sol_screen.remember_scroll()
	refresh_page()
	apply_text_size()
	if not action.is_empty():
		restore_training_focus.call_deferred(action)

func restore_training_focus(action: String) -> void:
	if not opened or selected != "sols":
		return
	for control in frame.find_children("*", "Button", true, false):
		if control.get_meta("training_action", "") == action and not control.disabled:
			control.grab_focus()
			return
	if is_instance_valid(sol_screen) and sol_screen.tabs.has(sol_tab):
		sol_screen.tabs[sol_tab].grab_focus()

func select_page(section: String) -> void:
	if not pages.has(section):
		return
	if selected == "sols" and is_instance_valid(sol_screen) and sol_screen.is_inside_tree():
		sol_screen.remember_scroll()
	selected = section
	feedback.text = ""
	for key in pages:
		pages[key].visible = key == section
		navigation[key].set_pressed_no_signal(key == section)
	for item in SECTIONS:
		if item[0] == section:
			section_heading.text = item[1]
			section_heading.tooltip_text = item[2]
			title.text = item[1]
			subtitle.text = item[2]
	refresh_page()

func clear_page(page: VBoxContainer) -> void:
	for child in page.get_children():
		page.remove_child(child)
		child.queue_free()

func scroll_rows(page: VBoxContainer) -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(scroll)
	var rows := VBoxContainer.new()
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rows.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rows.add_theme_constant_override("separation", 8)
	scroll.add_child(rows)
	return rows

func refresh_page() -> void:
	if selected == "guide":
		subtitle.text = "%d recorded sightings · first encounters stay in Field Notes" % world.persistent_state.discovery_entries().size()
		world.refresh_discoveries()
		return
	if selected == "journal":
		subtitle.text = world.objective.text
		return
	var page: VBoxContainer = pages[selected]
	clear_page(page)
	var rows := scroll_rows(page)
	match selected:
		"sols": build_sols(rows)
		"bag":
			rows.add_child(caption("Retraining items: %d" % world.persistent_state.retraining_items(), 20, settings.accent))
			rows.add_child(caption("Use a retraining item in Sols to return allocated training points. IVs remain fixed.", 15))
			rows.add_child(caption("Basic Seals", 24, settings.accent))
			rows.add_child(caption("∞  Testing supply", 28, Color("9fcca7")))
			rows.add_child(caption("This expedition currently uses unlimited testing Seals. During combat, the Seal button shows your capture chance before an attempt."))
			rows.add_child(caption("Captured Sols appear in Sols. A full party sends new companions to storage.", 15))
			if world.host.battles != null and not world.host.battles.settings.enabled:
				rows.add_child(caption("Combat capture is disabled for this scene.", 15, settings.accent))
		"trainer": build_trainer(rows)
		"save": build_save(rows)
		"options": build_options(rows)

func open_observed_entry(identity: String, subject: String, description: String, at: Vector2i) -> void:
	guide_context = {"key": identity, "title": subject, "description": description, "cell": at}
	open("guide")
	refresh_observed_entry()

func refresh_observed_entry() -> void:
	guide_back.show()
	var lines: Array[String] = [str(guide_context.title), str(guide_context.description)]
	for entry in world.persistent_state.discovery_entries():
		if not str(guide_context.key).is_empty() and entry.key == guide_context.key:
			lines.append(entry.description)
			for detail in entry.details:
				lines.append(str(detail))
			lines.append("First seen: %d, %d" % [entry.first_seen[0], entry.first_seen[1]])
			world.journal_notes.text = "\n\n".join(lines)
			return
	lines.append("Observed at %d, %d" % [guide_context.cell.x, guide_context.cell.y])
	world.journal_notes.text = "\n\n".join(lines)

func build_sols(rows: VBoxContainer) -> void:
	var battles: Node = world.host.battles
	if battles == null or not battles.settings.enabled:
		rows.add_child(caption("Companion selection is disabled for this scene."))
		return
	party_summary = caption("", 17, settings.accent)
	rows.add_child(party_summary)
	party_summary.hide()
	update_party_summary()
	sol_screen = preload("res://scripts/ui/sol_menu.gd").new()
	rows.add_child(sol_screen)
	sol_screen.bind(self)

func update_party_summary() -> void:
	if not is_instance_valid(party_summary):
		return
	var owned: Dictionary = world.persistent_state.collection_view().owned
	var party := 0
	for id in owned:
		if world.persistent_state.individual_view(id).location == "party":
			party += 1
	party_summary.text = "Party %d / %d · Storage %d" % [party, CollectionProgress.PARTY_LIMIT, owned.size() - party]

func choose_starter(index: int) -> void:
	var battles: Node = world.host.battles
	if battles == null or not battles.settings.enabled or not battles.settings.valid() or index < 0 or index >= battles.settings.starters.size():
		return
	var profile: BattleProfile = battles.settings.starters[index]
	if not world.persistent_state.choose_starter(profile.snapshot(), index, profile.evolution_forms):
		feedback.text = "An existing team cannot be replaced by another starter choice."
		return
	close()
	world.message("%s joined your party." % profile.display_name)

func build_trainer(rows: VBoxContainer) -> void:
	var state: ExpeditionState = world.persistent_state
	var progress := state.battle_progress()
	rows.add_child(caption("EXPLORER", 22, settings.accent))
	rows.add_child(caption(world.location_label.text + " · " + world.objective.text, 18))
	rows.add_child(caption("Companions  %d\nRecorded sightings  %d\nVictories  %d    Captures  %d\nRecoverable defeats  %d    Retreats  %d" % [state.collection_view().owned.size(), state.discovery_entries().size(), progress.wins, progress.captures, progress.losses, progress.retreats]))
	rows.add_child(caption("Expedition %d · Position %d, %d" % [world.terrain.world_seed, world.cell.x, world.cell.y], 14, settings.text.darkened(0.2)))
	if world.host.has_method("apply_atmosphere_settings"):
		rows.add_child(caption(world.host.atmosphere_controller.status.text, 16))

func build_save(rows: VBoxContainer) -> void:
	rows.add_child(caption("Keep your expedition", 22, settings.accent))
	rows.add_child(caption("Save your journey, companions and lasting world changes on this device. A new expedition leaves your previous save available until you save again.", 16))
	rows.add_child(caption("A saved expedition is available." if FileAccess.file_exists(save_path) else "No saved expedition yet.", 15))
	button("Save expedition · F5", func() -> void:
		world.save_game(save_path)
		feedback.text = world.toast.text
		refresh_page(), rows)
	var load_button := button("Load expedition · F9", func() -> void:
		world.load_game(save_path)
		feedback.text = world.toast.text, rows)
	load_button.disabled = not FileAccess.file_exists(save_path)
	button("New expedition…", world.ask_new, rows)

func slider(rows: VBoxContainer, text: String, minimum: float, maximum: float, step: float, value: float, action: Callable, suffix: String = "") -> HSlider:
	var heading := HBoxContainer.new()
	rows.add_child(heading)
	var name_label := caption(text)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(name_label)
	var number: Label = world.label("%d%s" % [roundi(value), suffix], 15, settings.accent)
	number.set_meta("ui_keep_single_line", true)
	heading.add_child(number)
	var control := HSlider.new()
	control.set_meta("pad_label", text)
	control.min_value = minimum
	control.max_value = maximum
	control.step = step
	control.value = value
	control.custom_minimum_size.y = 26
	control.value_changed.connect(func(amount: float) -> void:
		number.text = "%d%s" % [roundi(amount), suffix]
		action.call(amount))
	rows.add_child(control)
	return control

func build_options(rows: VBoxContainer) -> void:
	if world.host.has_method("apply_view_settings"):
		rows.add_child(caption("Pixel effect · testing", 16))
		var pixels := OptionButton.new()
		pixels.name = "PixelEffect"
		for text in ["Off", "Very light · 1.25x", "Light · 1.5x", "Medium · 1.75x", "Strong · 2x", "Deep · 3x"]:
			pixels.add_item(text)
		pixels.select(world.host.active_view.pixel_effect_level)
		pixels.item_selected.connect(func(index: int) -> void:
			world.host.view_settings = world.host.active_view.duplicate(false)
			world.host.view_settings.pixel_effect_level = index
			world.host.apply_view_settings())
		rows.add_child(pixels)
	if world.host.audio != null:
		rows.add_child(caption("Audio", 20, settings.accent))
		for category: String in world.host.audio.volumes:
			slider(rows, category + " volume", 0, 100, 1, world.host.audio.volumes[category], func(value: float) -> void:
				world.host.audio.set_volume(category, value), "%")
	rows.add_child(caption("Interface", 20, settings.accent))
	text_slider = slider(rows, "Text size", 100, 200, 5, settings.text_scale * 100, func(value: float) -> void:
		settings.text_scale = value / 100.0
		apply_text_size()
		save_timer.start(), "%")
	scale_slider = slider(rows, "Menu scale", 75, 125, 5, requested_scale * 100, func(value: float) -> void:
		requested_scale = value / 100.0
		fit_layout()
		save_timer.start(), "%")
	opacity_slider = slider(rows, "Background opacity", 70, 100, 5, opacity * 100, func(value: float) -> void:
		opacity = value / 100.0
		frame_style.bg_color = Color(settings.background, opacity)
		save_timer.start(), "%")
	if world.host.gamepad != null:
		world.host.gamepad.build_options(rows)
	button("Reset menu layout", reset_layout, rows)
	rows.add_child(caption("Camera · applies immediately", 20, settings.accent))
	slider(rows, "Camera speed", 5, 100, 5, world.host.camera_drag_sensitivity * 100, func(value: float) -> void: world.host.camera_drag_sensitivity = value / 100.0, "%")
	button("Reset camera", world.host.reset_camera, rows)
	if world.host.has_method("apply_view_settings"):
		rows.add_child(caption("Graphics · current session", 20, settings.accent))

		slider(rows, "Field of view", 35, 75, 1, world.host.active_view.field_of_view, func(value: float) -> void:
			world.host.view_settings = world.host.active_view.duplicate(false)
			world.host.view_settings.field_of_view = value
			world.host.apply_view_settings(), "°")
		slider(rows, "View distance", 48, 128, 8, world.host.active_view.render_distance, func(value: float) -> void:
			world.host.view_settings = world.host.active_view.duplicate(false)
			world.host.view_settings.render_distance = value
			world.host.apply_view_settings())

func handle_input(event: InputEvent) -> void:
	if event.is_action_pressed("field_menu"):
		close()
	elif event.is_action_pressed("companion"):
		if selected == "sols": close()
		else: select_page("sols")
	elif event.is_action_pressed("journal"):
		if selected == "guide": close()
		else: select_page("guide")
	elif event.is_action_pressed("save_expedition"):
		world.save_game(save_path)
		feedback.text = world.toast.text
	elif event.is_action_pressed("load_expedition"):
		world.load_game(save_path)
	elif selected == "sols" and world.persistent_state.active_sol_view().is_empty() and event is InputEventKey and event.pressed and event.physical_keycode in [KEY_1, KEY_2, KEY_3]:
		choose_starter(int(event.physical_keycode) - int(KEY_1))

func begin_drag(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		dragging = true
		pointer_origin = event.global_position
		drag_rect = Rect2(frame.position, frame.size)
		header.accept_event()

func begin_resize(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		resizing = true
		pointer_origin = event.global_position
		drag_rect = Rect2(frame.position, frame.size)
		resize_handle.accept_event()

func _input(event: InputEvent) -> void:
	if not opened or not (dragging or resizing):
		return
	if event is InputEventMouseMotion:
		if dragging:
			frame.position = drag_rect.position + event.global_position - pointer_origin
		else:
			var available := (frame.get_viewport_rect().size - drag_rect.position - Vector2(12, 12)) / frame.scale.x
			frame.size = (drag_rect.size + (event.global_position - pointer_origin) / frame.scale.x).clamp(settings.minimum_size, available.max(settings.minimum_size))
		fit_layout()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		finish_drag()
		get_viewport().set_input_as_handled()

func finish_drag() -> void:
	if dragging or resizing:
		dragging = false
		resizing = false
		save_preferences()

func fit_layout() -> void:
	if not is_instance_valid(frame) or not frame.is_inside_tree():
		return
	var viewport_size := frame.get_viewport_rect().size
	var available := (viewport_size - Vector2(24, 24)).max(Vector2.ONE)
	var actual_scale := minf(requested_scale * settings.size_multiplier, minf(available.x / settings.minimum_size.x, available.y / settings.minimum_size.y))
	frame.scale = Vector2.ONE * actual_scale
	var reading_minimum := settings.window_size * sqrt(settings.text_scale) if settings.text_scale > 1 else settings.minimum_size
	frame.size = frame.size.max(reading_minimum).min(available / actual_scale)
	frame.position = frame.position.clamp(Vector2(12, 12), (viewport_size - frame.size * actual_scale - Vector2(12, 12)).max(Vector2(12, 12)))

func reset_layout() -> void:
	requested_scale = settings.ui_scale
	opacity = settings.background_opacity
	frame.size = settings.window_size
	frame_style.bg_color = Color(settings.background, opacity)
	frame.position = (frame.get_viewport_rect().size - frame.size * requested_scale * settings.size_multiplier) * 0.5
	fit_layout()
	save_preferences()
	if opened and selected == "options":
		refresh_page()

func save_preferences() -> void:
	if not settings.remember_layout:
		return
	var config := ConfigFile.new()
	config.set_value("menu", "version", 1)
	config.set_value("menu", "position", frame.position)
	config.set_value("menu", "size", frame.size)
	config.set_value("menu", "scale", requested_scale)
	config.set_value("menu", "opacity", opacity)
	config.set_value("menu", "text_scale", settings.text_scale)
	if config.save(preferences_path) != OK:
		feedback.text = "Menu changes apply now; this device could not remember the layout."

func load_preferences() -> bool:
	var config := ConfigFile.new()
	if config.load(preferences_path) != OK or config.get_value("menu", "version", 0) != 1:
		return false
	var position: Variant = config.get_value("menu", "position")
	var size: Variant = config.get_value("menu", "size")
	var scale: Variant = config.get_value("menu", "scale")
	var alpha: Variant = config.get_value("menu", "opacity")
	var text_size: Variant = config.get_value("menu", "text_scale", settings.text_scale)
	if not (text_size is float or text_size is int) or not is_finite(text_size) or text_size < 1 or text_size > 2:
		return false
	if not position is Vector2 or not position.is_finite() or not size is Vector2 or not size.is_finite() or size.x < settings.minimum_size.x or size.y < settings.minimum_size.y or size.x > 8192 or size.y > 8192:
		return false
	if not (scale is float or scale is int) or not is_finite(scale) or scale < 0.75 or scale > 1.25 or not (alpha is float or alpha is int) or not is_finite(alpha) or alpha < 0.7 or alpha > 1:
		return false
	settings.text_scale = float(text_size)
	requested_scale = float(scale)
	opacity = float(alpha)
	frame.position = position
	frame.size = size
	frame_style.bg_color = Color(settings.background, opacity)
	fit_layout()
	return true

func apply_text_size() -> void:
	fit_layout()
	var tooltip_size := roundi(settings.font_size * settings.text_scale * settings.base_text_multiplier)
	if frame.theme.get_font_size("font_size", "TooltipLabel") != tooltip_size:
		frame.theme.set_font_size("font_size", "TooltipLabel", tooltip_size)
	preload("res://scripts/ui/ui_text.gd").apply(frame, settings.text_scale, true, settings.base_text_multiplier)
	var nav_list: Control = navigation.sols.get_parent()
	nav_list.custom_minimum_size.x = 124 * settings.text_scale
	nav_list.get_parent().custom_minimum_size.x = 124 * settings.text_scale
	if world.accessibility != null:
		world.accessibility.set_text_scale(settings.text_scale)
	if selected == "sols" and is_instance_valid(sol_screen) and sol_screen.is_inside_tree():
		sol_screen.adapt_layout()
