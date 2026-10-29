extends Node
## Explicitly invoked dialogue; no automatic campaign triggers or invented story content.
signal finished(event_id: String, choice_id: String)
var world: Node2D
var event: StoryEvent
var source_state: ExpeditionState
var window := Window.new()
var rows := VBoxContainer.new()
var was_paused := false

func bind(source: Node2D) -> void:
	world = source
	window.title = "Conversation"
	window.transient = true
	window.exclusive = true
	window.hide()
	world.hud.add_child(window)
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.theme = world.menu.frame.theme
	window.add_child(panel)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	panel.add_child(scroll)
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rows.add_theme_constant_override("separation", 12)
	scroll.add_child(rows)
	window.close_requested.connect(window.hide)
	window.window_input.connect(func(input: InputEvent) -> void:
		if input.is_action_pressed("ui_cancel"):
			window.hide())
	window.visibility_changed.connect(func() -> void:
		if not window.visible and event != null:
			world.paused = was_paused
			event = null
			source_state = null)
	world.state_replaced.connect(func(_state: ExpeditionState) -> void: window.hide())

func play(content: StoryEvent) -> bool:
	if content == null or window.visible or world.moving or world.paused or world.encounter_active or world.menu.opened or world.confirmation.visible or world.observation_menu.visible:
		return false
	var choices := content.available_choices(world.persistent_state.story_view())
	if choices.is_empty():
		return false
	for child in rows.get_children():
		rows.remove_child(child)
		child.queue_free()
	event = content
	source_state = world.persistent_state
	was_paused = world.paused
	world.paused = true
	world.host.camera_dragging = false
	window.title = content.title
	var prose := RichTextLabel.new()
	prose.bbcode_enabled = false
	prose.fit_content = true
	prose.scroll_active = false
	prose.custom_minimum_size.y = 100
	prose.text = (content.speaker + "\n\n" if not content.speaker.is_empty() else "") + content.text
	rows.add_child(prose)
	# Leave is always the first/default control: opening dialogue is never consent.
	var leave := Button.new()
	leave.text = "Leave for now"
	leave.pressed.connect(window.hide)
	rows.add_child(leave)
	window.set_meta("pad_default_focus", weakref(leave))
	for choice in choices:
		var button := Button.new()
		button.text = choice.label
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.pressed.connect(select.bind(choice.id))
		rows.add_child(button)
	# The simulation lives in a hidden 2×2 viewport in full 3D; size UI from the host.
	var available: Vector2 = world.host.get_viewport().get_visible_rect().size
	window.size = Vector2i(Vector2(620, 440).min(available * 0.9))
	window.popup_centered()
	leave.grab_focus()
	return true

func select(choice_id: String) -> bool:
	if not window.visible or event == null or source_state != world.persistent_state:
		return false
	var completed_id := event.id
	if not source_state.record_story_choice(event, choice_id):
		return false
	window.hide()
	finished.emit(completed_id, choice_id)
	return true
