extends PanelContainer
## Compact, read-only inspection view. World/ExpeditionState remain the data authorities.
const MenuTheme = preload("res://scripts/ui/menu_theme.gd")
var heading := Label.new()
var access := Label.new()
var tile_affinity := Label.new()
var appearance := Label.new()
var pin := Button.new()
var journal := Button.new()
var observe_actions := HBoxContainer.new()
var observe_remaining := 0.0
var journal_identity := ""
var stacked_cards: Array[PanelContainer] = []
var snapshot := false
var layout_frames := 3
var details_label := Label.new()
var details_scroll := ScrollContainer.new()
var more := Button.new()
var close_button := Button.new()
var readings: Dictionary = {}
var target_cell := Vector2i.ZERO
var settings: MenuSettings
var world: Node2D
var current_scale := -1.0
var last_reading: Array = []
var ecology_details := false
var metrics := HBoxContainer.new()
var extra_actions := HBoxContainer.new()
func bind(source: Node2D, tuning: MenuSettings) -> void:
	world = source
	settings = tuning if tuning != null and tuning.valid() else MenuSettings.new()
	theme = MenuTheme.build(settings)
	add_theme_stylebox_override("panel", MenuTheme.box(Color(settings.background, 0.97), settings.surface.lightened(0.25), 6))
	position = Vector2(24, 100)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 7)
	add_child(rows)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 8)
	rows.add_child(top)
	heading.add_theme_font_size_override("font_size", 14)
	heading.set_meta("ui_keep_single_line", true)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.clip_text = true
	heading.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	top.add_child(heading)
	appearance.add_theme_font_size_override("font_size", 13)
	appearance.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	appearance.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tile_affinity.add_theme_font_size_override("font_size", 12)
	rows.add_child(tile_affinity)
	tile_affinity.hide()
	rows.add_child(appearance)
	appearance.hide()
	close_button.text = "×"
	close_button.flat = false
	close_button.custom_minimum_size = Vector2(22, 22)
	close_button.add_theme_font_size_override("font_size", 18)
	close_button.add_theme_color_override("font_color", settings.text)
	close_button.add_theme_color_override("font_pressed_color", settings.accent)
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]:
		var style := MenuTheme.box(Color.TRANSPARENT, settings.accent if state in ["hover", "focus"] else Color.TRANSPARENT, 3)
		style.set_content_margin_all(2)
		close_button.add_theme_stylebox_override(state, style)
	close_button.tooltip_text = "Close inspection"
	close_button.pressed.connect(dismiss)
	top.add_child(close_button)
	metrics.add_theme_constant_override("separation", 8)
	rows.add_child(metrics)
	metrics.hide()
	for entry in [["wetness", "Wetness", Color("78b5c9")], ["vastra", "Vastra", Color("d7c187")], ["overload", "Overload", Color("cd9389")]]:
		var line := VBoxContainer.new()
		line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.add_theme_constant_override("separation", 2)
		metrics.add_child(line)
		var label := Label.new()
		label.text = entry[1]
		label.add_theme_font_size_override("font_size", 11)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.tooltip_text = {"wetness": "Terrain wetness, from 0 to 100.", "vastra": "Vastra concentration, from 0 to 100.", "overload": "Ecological balance: negative is restorative, zero is neutral, positive is overloaded. Both return toward zero."}[entry[0]]
		line.add_child(label)
		var amount := Label.new()
		amount.add_theme_font_size_override("font_size", 13)
		amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		line.add_child(amount)
		var bar := ProgressBar.new()
		bar.show_percentage = false
		bar.max_value = 100
		if entry[0] == "overload":
			bar.min_value = VastraCombat.MIN_OVERLOAD
		var track := MenuTheme.box(settings.surface, Color.TRANSPARENT, 2)
		track.set_content_margin_all(0)
		var fill := MenuTheme.box(entry[2], Color.TRANSPARENT, 2)
		fill.set_content_margin_all(0)
		bar.add_theme_stylebox_override("background", track)
		bar.add_theme_stylebox_override("fill", fill)
		line.add_child(bar)
		readings[entry[0]] = {"label": label, "value": amount, "bar": bar}
	var footer := extra_actions
	rows.add_child(footer)
	footer.hide()
	access.add_theme_font_size_override("font_size", 11)
	access.set_meta("ui_keep_single_line", true)
	access.size_flags_horizontal = Control.SIZE_SHRINK_END
	top.add_child(access)
	top.move_child(access, 1)
	more.text = "Details"
	more.flat = false
	more.add_theme_color_override("font_pressed_color", settings.accent)
	more.add_theme_color_override("font_hover_pressed_color", settings.accent)
	more.toggle_mode = true
	more.custom_minimum_size = Vector2(60, 22)
	more.add_theme_font_size_override("font_size", 12)
	more.tooltip_text = "Coordinates, target information and local conditions"
	more.toggled.connect(func(expanded: bool) -> void:
		metrics.visible = expanded
		extra_actions.hide()
		details_scroll.visible = expanded and ecology_details
		more.text = "Less" if expanded else "Details"
		more.tooltip_text = "Return to compact inspection" if expanded else "Right-click the target and choose Details"
		reset_size()
		fit_card())
	footer.add_child(more)
	more.hide()
	details_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	details_scroll.follow_focus = true
	rows.add_child(details_scroll)
	rows.add_child(observe_actions)
	observe_actions.add_theme_constant_override("separation", 6)
	pin.icon = preload("res://assets/ui/pin.svg")
	pin.toggle_mode = true
	pin.custom_minimum_size = Vector2(22, 22)
	pin.tooltip_text = "Keep this observation open"
	pin.toggled.connect(func(pinned: bool) -> void:
		pin.tooltip_text = "Unpin observation" if pinned else "Keep this observation open"
		observe_remaining = settings.observe_seconds
		modulate.a = 1.0)
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]:
		pin.add_theme_stylebox_override(state, close_button.get_theme_stylebox(state).duplicate())
	pin.add_theme_color_override("icon_pressed_color", settings.accent)
	top.add_child(pin)
	top.move_child(pin, 0)
	pin.hide()
	journal.text = "Journal"
	journal.tooltip_text = "Open this target's journal page"
	journal.pressed.connect(func() -> void:
		world.menu.open_observed_entry(journal_identity, heading.text, appearance.text, target_cell))
	observe_actions.add_child(journal)
	observe_actions.hide()
	details_label.add_theme_font_size_override("font_size", 12)
	details_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	details_scroll.add_child(details_label)
	details_label.minimum_size_changed.connect(fit_card)
	details_scroll.hide()
	rows.move_child(footer, -1)
	get_viewport().size_changed.connect(fit_card)
	if not snapshot:
		world.state_replaced.connect(func(_state: ExpeditionState) -> void:
			for card in stacked_cards.duplicate():
				card.dismiss()
			dismiss())
	hide()
func update_reading(cell: Vector2i, subject: String, terrain_name: String, data: Dictionary, recovery: String) -> void:
	ecology_details = data.has("vessel") or not data.get("flora_reserve", {}).get("traits", {}).is_empty()
	tile_affinity.text = "Tile affinity: " + str(data.affinity).capitalize() if data.has("affinity") else ""
	tile_affinity.visible = data.has("affinity")
	var scale: float = world.menu.settings.text_scale if world.menu != null else settings.text_scale
	var reading := [cell, subject, terrain_name, data, recovery, scale, settings.inspection_width, settings.inspection_meter_height, world.menu.settings.base_text_multiplier if world.menu != null else 1.0]
	if reading == last_reading:
		show()
		return
	# Copy nested conditions so in-place environment changes invalidate this view.
	last_reading = reading.duplicate(true)
	target_cell = cell
	var name: String = subject.get_slice(" · ", 0)
	heading.text = name
	heading.tooltip_text = subject
	var barrier: bool = data.get("conditions", {}).has("barrier")
	var blocked: bool = int(data.obstacle) == 3 or not bool(data.walkable) or barrier
	access.text = "Blocked" if blocked else "Passable"
	access.tooltip_text = "Building blocks traversal." if int(data.obstacle) == 3 else ("A lingering barrier blocks traversal." if barrier else access.text)
	access.add_theme_color_override("font_color", Color("d49b92") if blocked else Color("a4c8ac"))
	var values := {"wetness": roundi(float(data.wetness) * 100), "vastra": int(data.concentration), "overload": int(data.overload)}
	for key in readings:
		readings[key].bar.max_value = 100
		readings[key].value.text = "%d / 100" % values[key]
		readings[key].bar.value = values[key]
		readings[key].bar.tooltip_text = readings[key].value.text
	var reserve: Dictionary = data.get("flora_reserve", {})
	readings.vastra.label.text = "Swarm reserve" if reserve.get("swarm", false) else ("Vastra reserve" if not reserve.is_empty() else "Vastra")
	readings.vastra.label.tooltip_text = "Stored plant energy. Rises with absorption/arrival and falls on transfer or repair. Excess is expelled around tree roots." if not reserve.is_empty() else "Vastra concentration, from 0 to 100."
	if reserve.get("swarm", false): readings.vastra.label.tooltip_text = "Stored swarm energy, transferred from vegetation and spent on response. Separate from ambient concentration."
	readings.vastra.value.tooltip_text = ""
	if not reserve.is_empty():
		readings.vastra.bar.step = 0.01
		readings.vastra.bar.max_value = float(reserve.capacity)
		readings.vastra.bar.value = float(reserve.energy)
		readings.vastra.value.text = "%.1f / %.0f" % [reserve.energy, reserve.capacity]
		readings.vastra.bar.tooltip_text = readings.vastra.value.text
		if float(reserve.get("roots", 0.0)) > 0:
			var root_text := "Around roots: %.1f Vastra, available to nearby plants and Sols." % float(reserve.roots)
			readings.vastra.value.tooltip_text = root_text
			readings.vastra.bar.tooltip_text += "\n" + root_text
	var facts := PackedStringArray(["Cell %s · %s" % [cell, terrain_name]])
	if not reserve.is_empty():
		facts.append("Ambient concentration: %d / 100" % int(data.concentration))
		if float(reserve.get("roots", 0.0)) > 0: facts.append("Around roots: %.1f Vastra" % float(reserve.roots))
	var traits: Dictionary = reserve.get("traits", {})
	if not traits.is_empty():
		facts.append("Growth form: %s / circulation: %s" % [str(traits.form).capitalize(), str(traits.role).capitalize()])
		if not str(traits["class"]).is_empty(): facts.append("Plant class: " + str(traits["class"]).capitalize())
		facts.append("Current activity: " + str(reserve.get("activity", "idle")).capitalize())
		if reserve.get("trace", false): facts.append("Recent local disturbance trace present")
	var swarm: Dictionary = data.get("vessel", {})
	if not swarm.is_empty():
		facts.append("Swarm activity: " + str(swarm.state).capitalize())
		facts.append("Local group: observations do not identify an unseen cause")
		if int(swarm.storm_until) > world.persistent_state.activity_tick(): facts.append("Vastra storm active here")
	if int(data.overload) < 0:
		facts.append("Restorative Vastra · supports habitat and wildlife recovery")
	elif int(data.overload) > 0:
		facts.append("Overloaded Vastra · disturbed ecological conditions")
	if subject != name:
		facts.append(subject)
	if data.has("affinity"):
		facts.append("Tile affinity: " + str(data.affinity).capitalize())
	for kind in data.get("conditions", {}):
		facts.append("%s · recovery stage %d/3" % [str(kind).capitalize(), int(data.conditions[kind].level)])
	if not recovery.is_empty():
		facts.append(recovery)
	details_label.text = "\n".join(facts)
	details_scroll.visible = more.button_pressed and ecology_details
	tooltip_text = "Right-click the target and choose Details"
	if not is_equal_approx(scale, current_scale):
		preload("res://scripts/ui/ui_text.gd").apply(self, scale, true, world.menu.settings.base_text_multiplier)
		heading.autowrap_mode = TextServer.AUTOWRAP_OFF
		access.autowrap_mode = TextServer.AUTOWRAP_OFF
		more.autowrap_mode = TextServer.AUTOWRAP_OFF
		current_scale = scale
	for entry in readings.values():
		entry.bar.custom_minimum_size.y = settings.inspection_meter_height
		entry.label.autowrap_mode = TextServer.AUTOWRAP_OFF
		entry.value.autowrap_mode = TextServer.AUTOWRAP_OFF
		entry.value.custom_minimum_size.x = 0
	show()
	fit_card()
func fit_card() -> void:
	if not is_inside_tree():
		return
	var available := get_viewport_rect().size - Vector2(24, 24)
	var width: float = maxf(settings.inspection_width, 260) if more.button_pressed or appearance.visible else settings.inspection_width
	custom_minimum_size.x = minf(width * maxf(1.0, current_scale), available.x)
	details_scroll.custom_minimum_size.y = minf(details_label.get_minimum_size().y, 110.0 * maxf(1.0, current_scale))
	size = Vector2(custom_minimum_size.x, 0)
	position = position.clamp(Vector2(12, 12), (get_viewport_rect().size - size - Vector2(12, 12)).max(Vector2(12, 12)))
func dismiss() -> void:
	if snapshot:
		world.inspection_card.stacked_cards.erase(self)
		hide()
		queue_free()
		return
	observe_remaining = 0
	modulate.a = 1.0
	world.examine = false
	world.inspected_cell = null
	world.inspected_subject = ""
	world.inspected_appearance = ""
	world.hover_outline.hide()
	more.set_pressed_no_signal(false)
	more.text = "Details"
	details_scroll.hide()
	metrics.hide()
	extra_actions.hide()
	hide()

func show_appearance(description: String) -> void:
	appearance.text = description
	appearance.visible = not description.is_empty()
	tile_affinity.visible = description.is_empty() and not tile_affinity.text.is_empty()
	access.visible = description.is_empty()
	observe_actions.visible = not description.is_empty()
	pin.visible = not description.is_empty()
	if description.is_empty():
		modulate.a = 1.0
	if not description.is_empty():
		more.button_pressed = false
		metrics.hide()
		details_scroll.hide()
		extra_actions.hide()
	fit_card()

func begin_observation() -> void:
	journal_identity = world.observation_member_id
	pin.set_pressed_no_signal(false)
	pin.tooltip_text = "Keep this observation open"
	observe_remaining = settings.observe_seconds
	modulate.a = 1.0

func _process(delta: float) -> void:
	layout_frames = maxi(0, layout_frames - 1)
	if not snapshot and world.inspected_appearance.is_empty():
		return
	if snapshot:
		visible = not world.menu.opened and not world.paused and not world.encounter_active
	if world == null or not appearance.visible or pin.button_pressed:
		return
	observe_remaining = maxf(0.0, observe_remaining - delta)
	modulate.a = clampf(observe_remaining / 0.35, 0.0, 1.0)
	if observe_remaining <= 0:
		dismiss()

func archive_observation() -> void:
	if not appearance.visible or not visible or last_reading.is_empty():
		return
	var card: PanelContainer = get_script().new()
	card.snapshot = true
	world.hud.add_child(card)
	card.bind(world, settings)
	card.update_reading(last_reading[0], last_reading[1], last_reading[2], last_reading[3], last_reading[4])
	card.show_appearance(appearance.text)
	card.journal_identity = journal_identity
	card.observe_remaining = observe_remaining
	card.pin.set_pressed_no_signal(pin.button_pressed)
	stacked_cards.append(card)

func arrange_stack(top: float) -> void:
	var y := top
	var settling := false
	for card in stacked_cards + [self]:
		if not card.visible:
			continue
		card.fit_card()
		card.position = Vector2(24, y)
		y += card.size.y + 8
		settling = settling or card.layout_frames > 0
	if settling:
		return
	if y > get_viewport_rect().size.y - 24:
		for card in stacked_cards:
			if not card.pin.button_pressed:
				card.dismiss()
				arrange_stack(top)
				return
		# Existing pins retain their places when there is no room for another card.
		if visible:
			dismiss()
			arrange_stack(top)
		elif not stacked_cards.is_empty():
			stacked_cards[-1].dismiss()
			arrange_stack(top)
