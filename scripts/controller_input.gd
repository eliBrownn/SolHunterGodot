extends Node
## Routes one controller through world, UI and native popup layers. Domain commands stay in their owners.
const Focus = preload("res://scripts/controller_focus.gd")
var world: Node2D
var settings: ControllerSettings
var preferences_path := "user://controller_preferences.cfg"
var active := false
var device := -1
var axes := [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
var held: Dictionary = {}
var focus := Focus.new()
var target_cell := Vector2i.ZERO
var target_id := ""
var target_manual := false
var battle_actions := false
var direction := Vector2i.ZERO
var repeat_left := 0.0
var zoom_left := 0.0
var listening := ""
var show_bindings := false
var detail_window := Window.new()
var detail_text := RichTextLabel.new()
var prompts := Label.new()
var last_surface: Node
var suspend := false
var windows: Array[WeakRef] = []
var escape_pattern := RegEx.create_from_string("\\bEsc\\b")

func bind(source: Node2D) -> void:
	world = source
	focus.formatter = input_text
	var tuning: ControllerSettings = world.host.controller_settings
	settings = tuning.duplicate(true) if tuning != null and tuning.valid() else ControllerSettings.new()
	settings.load_preferences(preferences_path)
	settings.install_actions()
	Input.joy_connection_changed.connect(connection_changed)
	get_tree().node_added.connect(on_node_added)
	get_window().focus_exited.connect(clear_held)
	get_window().focus_entered.connect(func() -> void: suspend = false)
	world.state_replaced.connect(on_state)
	prompts.add_theme_font_size_override("font_size", 12)
	prompts.set_meta("ui_keep_single_line", true)
	prompts.add_theme_color_override("font_color", world.menu.settings.accent)
	prompts.add_theme_color_override("font_shadow_color", Color.BLACK)
	prompts.add_theme_constant_override("shadow_offset_x", 1)
	prompts.add_theme_constant_override("shadow_offset_y", 1)
	prompts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	prompts.z_index = 100
	world.hud.add_child(prompts)
	build_details()
	for node in world.hud.find_children("*", "Window", true, false):
		bridge_window(node)
	prompts.hide()
	target_cell = world.cell

func build_details() -> void:
	detail_window.title = "Details"
	detail_window.transient = true
	detail_window.exclusive = true
	detail_window.visible = false
	world.hud.add_child(detail_window)
	var panel := PanelContainer.new()
	panel.theme = world.menu.frame.theme
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	detail_window.add_child(panel)
	var rows := VBoxContainer.new()
	panel.add_child(rows)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.follow_focus = true
	rows.add_child(scroll)
	detail_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_text.fit_content = true
	detail_text.scroll_active = false
	detail_text.add_theme_font_size_override("normal_font_size", 16)
	scroll.add_child(detail_text)
	var close := Button.new()
	close.text = "Close"
	close.pressed.connect(detail_window.hide)
	rows.add_child(close)
	detail_window.close_requested.connect(detail_window.hide)

func on_node_added(node: Node) -> void:
	if node is Window and world.hud.is_ancestor_of(node):
		bridge_window.call_deferred(node)

func bridge_window(window: Window) -> void:
	if is_instance_valid(window) and not window.has_meta("pad_bridge"):
		window.set_meta("pad_bridge", true)
		windows.append(weakref(window))
		var bridge := preload("res://scripts/controller_window_input.gd").new()
		bridge.router = self
		bridge.surface = window
		window.add_child(bridge)

func clear_held() -> void:
	for index in range(axes.size()):
		axes[index] = 0.0
	held.clear()
	direction = Vector2i.ZERO
	repeat_left = 0
	suspend = true

func connection_changed(id: int, connected: bool) -> void:
	if id == device and not connected:
		clear_held()
		active = false
		device = -1
		listening = ""
		set_tactical_focus(false)
		world.menu.launcher.text = "Menu · R"
		prompts.text = "Controller disconnected · Mouse / keyboard available"
		prompts.show()

func on_state(_state: ExpeditionState) -> void:
	clear_held()
	suspend = false
	target_cell = world.cell
	target_id = ""
	target_manual = false
	battle_actions = false
	detail_window.hide()
	focus.root = null
	focus.current = null

func set_tactical_focus(enabled: bool) -> void:
	if world.host.battles == null:
		return
	for node in world.host.battles.combat_hud.find_children("*", "BaseButton", true, false):
		if not node.has_meta("pad_desktop_text") and input_text(node.text) != node.text:
			node.set_meta("pad_desktop_text", node.text)
		if node.has_meta("pad_desktop_text"):
			node.text = input_text(str(node.get_meta("pad_desktop_text"))) if enabled else str(node.get_meta("pad_desktop_text"))
		node.focus_mode = Control.FOCUS_ALL if enabled else Control.FOCUS_NONE
		if not enabled:
			node.release_focus()
	if not enabled:
		for node in world.hud.find_children("*", "BaseButton", true, false):
			if node.has_meta("pad_desktop_text"):
				node.text = str(node.get_meta("pad_desktop_text"))

func handle_event(event: InputEvent, surface: Viewport = null) -> void:
	if not (event is InputEventJoypadButton or event is InputEventJoypadMotion):
		if active and ((event is InputEventKey and event.pressed) or event is InputEventMouseButton or (event is InputEventMouseMotion and event.relative.length() > 2)):
			active = false
			clear_held()
			set_tactical_focus(false)
			prompts.hide()
			world.menu.launcher.text = "Menu · R"
		if surface == detail_window and event.is_action_pressed("ui_cancel"):
			detail_window.hide()
			surface.set_input_as_handled()
		return
	if surface == null:
		surface = world.hud.get_viewport()
	surface.set_input_as_handled()
	var meaningful: bool = event.pressed if event is InputEventJoypadButton else absf(event.axis_value) > settings.deadzone
	if not active and not meaningful:
		return
	if active and event.device != device:
		return
	if not active:
		clear_held()
		focus.current = null
		focus.root = null
		active = true
		device = event.device
		set_tactical_focus(true)
	suspend = false
	if event is InputEventJoypadMotion:
		if event.axis < axes.size():
			axes[event.axis] = clampf(event.axis_value, -1, 1)
		update_direction()
		return
	var button: int = event.button_index
	if not event.pressed:
		held.erase(button)
		update_direction()
		return
	if held.has(button):
		return # An opening/held press cannot also accept the next dialog.
	held[button] = true
	if not listening.is_empty():
		if button == settings.buttons.back:
			listening = ""
		elif settings.bind_button(listening, button):
			listening = ""
			settings.install_actions()
			save_settings()
			world.menu.refresh_page()
		return
	if button in [JOY_BUTTON_DPAD_UP, JOY_BUTTON_DPAD_DOWN, JOY_BUTTON_DPAD_LEFT, JOY_BUTTON_DPAD_RIGHT]:
		update_direction()
		return
	for action in settings.buttons:
		if event.is_action_pressed("pad_" + str(action)):
			perform(action)
			break

func stick(x: int, y: int) -> Vector2:
	var value := Vector2(axes[x], axes[y]).limit_length(1)
	var magnitude := value.length()
	return Vector2.ZERO if magnitude <= settings.deadzone else value.normalized() * ((magnitude - settings.deadzone) / (1.0 - settings.deadzone))

func movement_vector() -> Vector2:
	if not active or suspend or ui_root() != null or world.host.battles.session != null or not listening.is_empty():
		return Vector2.ZERO
	# Existing locomotion is an eight-direction tile walk, with a separate run modifier.
	return stick(0, 1).normalized()

func sprinting() -> bool:
	return not movement_vector().is_zero_approx() and held.has(settings.buttons.sprint)

func visible_popup() -> Window:
	for index in range(windows.size() - 1, -1, -1):
		var window: Window = windows[index].get_ref()
		if window == null:
			windows.remove_at(index)
			continue
		if window.visible:
			return window
	return null

func ui_root() -> Node:
	var popup := visible_popup()
	if popup != null:
		return popup
	if world.menu.opened:
		return world.menu.frame
	if world.pause_panel.visible:
		return world.pause_panel
	var battle: Node = world.host.battles
	if battle == null:
		return null
	for panel in [battle.battle_menu, battle.selection_panel, battle.loadout.panel, world.host.encounters.encounter_panel, battle.feedback_view.result_panel]:
		if panel.visible:
			return panel
	return battle.combat_hud.tray if battle_actions and battle.session != null else null

func update_direction() -> void:
	var value := Vector2(float(held.has(JOY_BUTTON_DPAD_RIGHT)) - float(held.has(JOY_BUTTON_DPAD_LEFT)), float(held.has(JOY_BUTTON_DPAD_DOWN)) - float(held.has(JOY_BUTTON_DPAD_UP)))
	# Left stick navigates UI/battle; in exploration it exclusively moves the player.
	if value.is_zero_approx() and (ui_root() != null or world.host.battles.session != null):
		value = stick(0, 1)
	var next := Vector2i.ZERO
	if value.length() > 0.45:
		next = Vector2i(int(signf(value.x)), 0) if absf(value.x) > absf(value.y) else Vector2i(0, int(signf(value.y)))
	if next != direction:
		direction = next
		repeat_left = settings.repeat_delay
		if direction != Vector2i.ZERO:
			navigate(direction)

func navigate(step: Vector2i) -> void:
	var root := ui_root()
	if root is PopupMenu:
		popup_move(root, step.y if step.y != 0 else step.x)
	elif root != null:
		focus.move(root, step)
	elif world.host.battles.session != null:
		var battle: Node = world.host.battles
		var change := Vector2i(world.host.movement_direction(Vector2(step)).round())
		var next: Vector2i = battle.cursor + change
		if battle.session.bounds.has_point(next):
			battle.cursor = next
			battle.update_target_preview()
	else:
		target_cell += Vector2i(world.host.movement_direction(Vector2(step)).round())
		if Vector2(target_cell - world.cell).length() > 24:
			target_cell = world.cell
		target_id = ""
		target_manual = true

func popup_move(popup: PopupMenu, step: int) -> void:
	var index := popup.get_focused_item()
	for attempt in range(popup.item_count):
		index = posmod(index + step, popup.item_count)
		if not popup.is_item_separator(index) and not popup.is_item_disabled(index):
			popup.set_focused_item(index)
			return

func popup_confirm(popup: PopupMenu) -> void:
	var index := popup.get_focused_item()
	if index < 0 or popup.is_item_disabled(index) or popup.is_item_separator(index):
		popup_move(popup, 1)
		return
	if popup.get_parent() is OptionButton:
		var option: OptionButton = popup.get_parent()
		option.select(index)
		popup.hide()
		option.item_selected.emit(index)
	else:
		popup.id_pressed.emit(popup.get_item_id(index))
		popup.hide()

func perform(action: String) -> void:
	var root := ui_root()
	var battle: Node = world.host.battles
	if action == "back":
		back(root)
	elif action == "menu":
		if root is Window:
			return
		if world.menu.opened:
			world.menu.close()
		elif battle.session != null:
			battle.open_battle_menu()
		else:
			world.menu.open()
	elif action == "pause":
		if world.menu.opened:
			world.toggle_pause()
		elif root != null or battle.session != null:
			back(root)
		else:
			world.toggle_pause()
	elif action == "confirm":
		if root is PopupMenu:
			popup_confirm(root)
		elif root != null:
			focus.activate(root)
			if battle.session != null and battle.aimed_slot >= 0 and not battle.modal_open():
				battle_actions = false
		elif battle.session != null:
			battle.select_cell(battle.cursor)
		else:
			open_target(false)
	elif action == "details":
		if root == detail_window:
			return
		if root is PopupMenu:
			var item: int = root.get_focused_item()
			show_details(root.get_item_tooltip(item) if item >= 0 else "Choose an action with the directional controls.")
		elif root != null:
			focus.ensure(root)
			if is_instance_valid(focus.current):
				var text: String = focus.current.tooltip_text
				if text.is_empty() and focus.current is BaseButton:
					text = focus.current.text
				if root == battle.combat_hud.tray:
					for move_button in battle.move_buttons:
						if move_button.visible:
							text += "\n\n" + move_button.text + "\n" + move_button.tooltip_text
				show_details(text)
		elif battle.session != null:
			show_details(battle_information())
		else:
			open_target(true)
	elif action == "targets":
		if root == battle.combat_hud.tray or (root == null and battle.session != null):
			battle_actions = not battle_actions
		elif root == null:
			cycle_target(1)
	elif action in ["previous", "next"] and root == null:
		cycle_target(-1 if action == "previous" else 1)
	elif action == "reset_camera" and root == null:
		world.host.reset_camera()
		if battle.session != null:
			battle.frame_battle()

func back(root: Node) -> void:
	var battle: Node = world.host.battles
	if root is ConfirmationDialog:
		root.get_cancel_button().pressed.emit()
	elif root is Window:
		root.hide()
	elif world.menu.opened:
		world.menu.close()
	elif world.pause_panel.visible:
		world.toggle_pause()
	elif battle.modal_open():
		battle.cancel_retreat()
		battle.close_battle_menu()
	elif world.host.encounters.encounter_panel.visible:
		world.host.encounters.withdraw()
	elif battle.loadout.opened:
		battle.loadout.close()
	elif battle.choosing:
		battle.cancel_choice()
	elif battle.feedback_view.result_panel.visible:
		battle.feedback_view.result_panel.hide()
	elif battle.session != null:
		if battle.aimed_slot >= 0:
			battle.cancel_targeting()
		elif battle_actions:
			battle_actions = false
		else:
			battle.open_battle_menu()
	elif world.inspection_card.visible:
		world.inspection_card.dismiss()
	else:
		world.toggle_pause()

func open_target(details: bool) -> void:
	world.open_observation(Vector2(24, 100), target_cell, target_id)
	if details:
		world.context_action(6)
	else:
		world.observation_menu.set_focused_item(-1)
		popup_move(world.observation_menu, 1)

func cycle_target(step: int) -> void:
	var battle: Node = world.host.battles
	if battle.session != null:
		var choices: Array = battle.legal_targets(battle.aimed_slot) if battle.aimed_slot >= 0 else battle.session.deployment_tiles() if battle.session.phase == "deployment" else battle.session.reachable().keys()
		choices.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.y < b.y or (a.y == b.y and a.x < b.x))
		if not choices.is_empty():
			battle.cursor = choices[posmod(choices.find(battle.cursor) + step, choices.size())]
			battle.update_target_preview()
		return
	var choices: Array[Dictionary] = [{"id": "", "cell": world.cell}]
	for member in world.host.sightings.members:
		if member.sprite.visible and world.persistent_state.wild_available(member.id):
			choices.append({"id": member.id, "cell": world.host.sightings.current_cell(member)})
	for prop in world.place_props:
		choices.append({"id": "", "cell": Vector2i((prop.position / 32.0).floor())})
	var index := -1
	for at in range(choices.size()):
		if choices[at].id == target_id and choices[at].cell == target_cell:
			index = at
	var selected: Dictionary = choices[posmod(index + step, choices.size())]
	target_id = selected.id
	target_cell = selected.cell
	target_manual = true

func show_details(text: String) -> void:
	detail_text.text = input_text(text) if not text.is_empty() else "No additional information is recorded for this control."
	var bounds: Vector2 = world.hud.get_viewport().get_visible_rect().size
	detail_window.popup_centered(Vector2i(Vector2(620, 420).min(bounds - Vector2(48, 48))))

func battle_information() -> String:
	var battle: Node = world.host.battles
	var hud: CombatHud = battle.combat_hud
	var lines: Array[String] = [world.observation_name(battle.cursor), hud.phase_label.text + " · " + hud.round_label.text, hud.intent_label.text, hud.target_label.text]
	for side in ["ally", "enemy"]:
		var card: Dictionary = hud.cards[side]
		lines.append("\n" + card.name.text + " · HP " + card.hp.text + "\n" + card.metadata.text + "\n" + card.panel.tooltip_text + "\n" + card.effects.text)
	return "\n".join(lines)

func input_text(text: String) -> String:
	return escape_pattern.sub(text, button_name("back"), true).replace("Left-click", button_name("confirm")).replace("Right-click", button_name("confirm") + " Options").replace(" · F5", "").replace(" · F9", "").replace("F5", button_name("menu") + " → Save").replace("F9", button_name("menu") + " → Save")

func button_name(action: String) -> String:
	var index: int = settings.buttons[action]
	var name := Input.get_joy_name(device).to_lower() if Input.get_connected_joypads().has(device) else ""
	var face := ["A", "B", "X", "Y"]
	var other := {4: "View", 6: "Menu", 7: "LS", 8: "RS", 9: "LB", 10: "RB"}
	if "playstation" in name or "dualsense" in name or "dualshock" in name:
		face = ["Cross", "Circle", "Square", "Triangle"]
		other = {4: "Share", 6: "Options", 7: "L3", 8: "R3", 9: "L1", 10: "R1"}
	elif "nintendo" in name or "switch" in name:
		face = ["B", "A", "Y", "X"]
		other = {4: "−", 6: "+", 7: "LS", 8: "RS", 9: "L", 10: "R"}
	return face[index] if index < 4 else other.get(index, "Button %d" % index)

func save_settings() -> void:
	if settings.save_preferences(preferences_path) != OK:
		world.menu.feedback.text = "Controller changes apply now; preferences could not be saved."

func build_options(rows: VBoxContainer) -> void:
	var menu: Node = world.menu
	rows.add_child(menu.caption("Controller", 20, menu.settings.accent))
	menu.button("Controller guide", func() -> void: show_details("Left stick: move / menu navigation\nD-pad: world or battle tile / menu navigation\nRight stick: camera / scroll details\nTriggers: zoom\n%s: choose or interact\n%s: back (never direct retreat)\n%s: details without hover\n%s: target cycle / battle actions\n%s / %s: previous / next target\n%s: live field menu\n%s: pause\n%s: run while held\n%s: reset camera" % [button_name("confirm"), button_name("back"), button_name("details"), button_name("targets"), button_name("previous"), button_name("next"), button_name("menu"), button_name("pause"), button_name("sprint"), button_name("reset_camera")]), rows)
	menu.slider(rows, "Stick deadzone", 5, 50, 1, settings.deadzone * 100, func(value: float) -> void: settings.deadzone = value / 100; save_settings(), "%")
	menu.slider(rows, "Controller camera speed", 30, 180, 5, settings.camera_speed, func(value: float) -> void: settings.camera_speed = value; save_settings(), "°/s")
	menu.button("Invert camera Y: " + ("On" if settings.invert_camera_y else "Off"), func() -> void: settings.invert_camera_y = not settings.invert_camera_y; save_settings(); menu.refresh_page(), rows)
	menu.button("Button bindings · " + ("Hide" if show_bindings else "Show"), func() -> void: show_bindings = not show_bindings; menu.refresh_page(), rows)
	if show_bindings:
		for action in ControllerSettings.DEFAULT_BUTTONS:
			var button: Button = menu.button("%s · %s" % [ControllerSettings.NAMES[action], button_name(action)], func() -> void: listening = action, rows)
			button.tooltip_text = "Press a new controller button. Conflicts swap bindings; Back cancels. D-pad and Guide are reserved."
	menu.button("Reset controller settings", func() -> void: settings = ControllerSettings.new(); settings.install_actions(); save_settings(); menu.refresh_page(), rows)

func _process(delta: float) -> void:
	if not active or world.host.battles == null:
		return
	var root := ui_root()
	if root != last_surface:
		last_surface = root
		direction = Vector2i.ZERO
		repeat_left = settings.repeat_delay
	if root != null and not root is PopupMenu:
		focus.ensure(root)
	if not suspend and not listening.is_empty():
		prompts.text = "Press a button for %s · %s Cancel" % [ControllerSettings.NAMES[listening], button_name("back")]
	else:
		update_direction()
		repeat_left -= maxf(0, delta)
		if direction != Vector2i.ZERO and repeat_left <= 0:
			navigate(direction)
			repeat_left = settings.repeat_interval
		var look := stick(2, 3)
		if root != null:
			if not look.is_zero_approx() and not root is PopupMenu:
				focus.scroll(root, look.y * delta * 500)
		elif not suspend:
			if not look.is_zero_approx():
				world.host.view_azimuth = wrapf(world.host.view_azimuth - look.x * settings.camera_speed * delta, -180, 180)
				world.host.view_elevation = clampf(world.host.view_elevation + look.y * settings.camera_speed * delta * (-1 if settings.invert_camera_y else 1), 10, 80)
				world.host.apply_camera()
			zoom_left -= delta
			if absf(axes[5] - axes[4]) > 0.4 and zoom_left <= 0:
				world.host.zoom_camera(-signf(axes[5] - axes[4]))
				zoom_left = settings.repeat_interval
		prompts.text = "%s Choose · %s Back · %s Details" % [button_name("confirm"), button_name("back"), button_name("details")] if root != null else ("%s Place / move · %s Actions · %s Details" if world.host.battles.session != null else "%s Options · %s Targets · %s Details") % [button_name("confirm"), button_name("targets"), button_name("details")]
	if world.host.battles.session == null and root == null and not world.paused:
		if not target_manual or Vector2(target_cell - world.cell).length() > 24:
			target_cell = world.cell
		if not target_id.is_empty():
			for member in world.host.sightings.members:
				if member.id == target_id:
					target_cell = world.host.sightings.current_cell(member)
		world.hover_cell = target_cell
		world.interaction_hint.text = world.observation_name(target_cell)
		world.interaction_hint.get_parent().show()
	prompts.show()
	prompts.position = Vector2(24, world.hud.get_viewport().get_visible_rect().size.y - prompts.size.y - 4)
	if world.host.battles.session != null:
		prompts.position.y = world.host.battles.combat_hud.tray.position.y - prompts.size.y - 4
	world.menu.launcher.text = "Menu · " + button_name("menu")
