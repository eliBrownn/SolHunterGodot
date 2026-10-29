class_name CombatHud
extends PanelContainer
const MenuTheme = preload("res://scripts/menu_theme.gd")
## Presentation only: commands and previews always delegate to the existing battle authority.
var controller: Node
var top := HBoxContainer.new()
var tray := PanelContainer.new()
var tray_scroll := ScrollContainer.new()
var contents := VBoxContainer.new()
var command_header := HBoxContainer.new()
var cards: Dictionary = {}
var moves := GridContainer.new()
var phase_label: Label
var round_label: Label
var status_label: Label
var intent_label: Label
var log_label: Label
var target_label: Label
var cancel_button: Button
var log_panel := PanelContainer.new()
var log_toggle: Button
var canvas := Control.new()
var retreat_button: Button
var retry_button: Button
var layout_dirty := true
var last_layout_inputs: Array = []
var layout_updates := 0

func bind(owner_controller: Node) -> void:
	controller = owner_controller
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	theme = MenuTheme.build(controller.world.host.menu_settings if controller.world.host.menu_settings != null and controller.world.host.menu_settings.valid() else MenuSettings.new())
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(canvas)
	canvas.add_child(top)
	top.add_theme_constant_override("separation", 14)
	build_card("ally")
	var turn_box := VBoxContainer.new()
	turn_box.custom_minimum_size.x = 100
	turn_box.alignment = BoxContainer.ALIGNMENT_CENTER
	phase_label = text("DEPLOYMENT", 14, Color("e1c791"))
	phase_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	phase_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	turn_box.add_child(phase_label)
	round_label = text("", 12)
	round_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	round_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	turn_box.add_child(round_label)
	var turn_panel := PanelContainer.new()
	turn_panel.add_theme_stylebox_override("panel", MenuTheme.box(Color("182c25"), Color("827651")))
	turn_panel.add_child(turn_box)
	top.add_child(turn_panel)
	build_card("enemy")
	canvas.add_child(tray)
	tray_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	tray_scroll.follow_focus = true
	tray.add_child(tray_scroll)
	contents.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	contents.add_theme_constant_override("separation", 5)
	tray_scroll.add_child(contents)
	var header := command_header
	contents.add_child(header)
	status_label = text("", 13, Color("e1c791"))
	status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(status_label)
	cancel_button = controller.button("Cancel target · Esc", controller.cancel_targeting, header)
	cancel_button.custom_minimum_size.y = 26
	contents.add_child(moves)
	moves.add_theme_constant_override("h_separation", 10)
	moves.add_theme_constant_override("v_separation", 7)
	for slot in range(5):
		var action: Button = controller.button("", controller.choose_move.bind(slot), moves)
		action.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		action.custom_minimum_size.y = 30
		action.toggle_mode = true
		action.add_theme_font_size_override("font_size", 13)
		controller.move_buttons.append(action)
	controller.attack_button = controller.move_buttons[0]
	target_label = text("", 12)
	contents.add_child(target_label)
	var actions := HFlowContainer.new()
	actions.add_theme_constant_override("separation", 10)
	contents.add_child(actions)
	controller.capture_button = controller.button("Use Seal", controller.capture_enemy, actions)
	controller.wait_button = controller.button("End turn", controller.wait_turn, actions)
	retry_button = controller.button("Retry result", controller.retry_completion, actions)
	retry_button.hide()
	controller.quantum_choice = OptionButton.new()
	for label in ["Chosen position", "Stabilize field", "Entangle tiles"]:
		controller.quantum_choice.add_item(label)
	controller.quantum_choice.item_selected.connect(func(index: int) -> void:
		if controller.session != null and not controller.playback.busy and not controller.modal_open():
			controller.session.quantum_mode = ["position", "stabilize", "entangle"][index]
			controller.update_view())
	actions.add_child(controller.quantum_choice)
	controller.button("More · Esc", controller.open_battle_menu, actions).tooltip_text = "Battle log, retreat and battlefield camera"
	for action in actions.get_children():
		if action is Button:
			action.add_theme_font_size_override("font_size", 13)
			action.custom_minimum_size.y = 28
	intent_label = text("", 14, Color("e1c791"))
	contents.add_child(intent_label)
	intent_label.hide()
	canvas.add_child(log_panel)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	log_panel.add_child(scroll)
	log_label = text("", 14)
	log_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(log_label)
	log_panel.hide()
	controller.battle_shield = ColorRect.new()
	controller.battle_shield.color = Color(0, 0, 0, 0.35)
	controller.battle_shield.mouse_filter = Control.MOUSE_FILTER_STOP
	controller.battle_shield.z_index = 9
	canvas.add_child(controller.battle_shield)
	controller.battle_shield.hide()
	controller.battle_menu = PanelContainer.new()
	canvas.add_child(controller.battle_menu)
	controller.battle_menu.z_index = 10
	var menu_rows := VBoxContainer.new()
	controller.battle_menu.add_child(menu_rows)
	menu_rows.add_child(text("BATTLE MENU", 20, Color("e1c791")))
	menu_rows.add_child(text("Battle input is suspended.", 16))
	controller.button("Resume · Esc", controller.close_battle_menu, menu_rows)
	controller.button("Frame battlefield", controller.frame_battle, menu_rows)
	log_toggle = controller.button("Battle log", toggle_log, menu_rows)
	retreat_button = controller.button("Retreat…", controller.request_retreat, menu_rows)
	controller.world.accessibility.wrap_panel(controller.battle_menu)
	controller.battle_menu.hide()
	# Combat buttons cannot execute tactical commands from keyboard focus.
	disable_tactical_focus(canvas)
	controller.world.hud.add_child(self)
	get_viewport().size_changed.connect(request_layout)
	contents.minimum_size_changed.connect(request_layout)
	top.minimum_size_changed.connect(request_layout)
	visibility_changed.connect(request_layout)
	fit_layout()
	hide()

func disable_tactical_focus(node: Node) -> void:
	if node is BaseButton:
		node.focus_mode = Control.FOCUS_NONE
	for child in node.get_children():
		disable_tactical_focus(child)

func text(value: String, font_size: int, color: Color = Color("e6e9df")) -> Label:
	var label: Label = controller.world.label(value, font_size, color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label

func build_card(side: String) -> void:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	panel.add_child(box)
	var name_label := text("", 16)
	name_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	name_label.clip_text = true
	box.add_child(name_label)
	var metadata := text("", 13, Color("b5c6bb"))
	metadata.autowrap_mode = TextServer.AUTOWRAP_OFF
	metadata.clip_text = true
	box.add_child(metadata)
	metadata.hide()
	var health := HBoxContainer.new()
	box.add_child(health)
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.custom_minimum_size.y = 6
	health.add_child(bar)
	var hp := text("", 12)
	hp.autowrap_mode = TextServer.AUTOWRAP_OFF
	hp.custom_minimum_size.x = 64
	hp.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	health.add_child(hp)
	var effects := text("", 12, Color("b5c6bb"))
	effects.autowrap_mode = TextServer.AUTOWRAP_OFF
	effects.clip_text = true
	effects.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	box.add_child(effects)
	cards[side] = {"panel": panel, "name": name_label, "metadata": metadata, "bar": bar, "hp": hp, "effects": effects, "target": -1.0, "tween": null}

func fit_layout() -> void:
	layout_dirty = false
	layout_updates += 1
	var viewport_size := get_viewport_rect().size
	var text_scale: float = controller.world.menu.settings.text_scale
	if controller.battle_shield != null:
		controller.battle_shield.size = viewport_size
	if controller.battle_menu != null:
		controller.battle_menu.size = Vector2(minf(420 * sqrt(text_scale), viewport_size.x - 48), minf(240 * text_scale, viewport_size.y - 48))
		controller.battle_menu.position = (viewport_size - controller.battle_menu.size) * 0.5
	var compact := viewport_size.x < 900 * text_scale
	moves.columns = 2 if compact else 4
	for row in cards.values():
		row.name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if text_scale > 1 else TextServer.AUTOWRAP_OFF
		row.name.clip_text = text_scale <= 1
	var top_width := minf(viewport_size.x - 32, controller.world.menu.settings.combat_health_width * sqrt(text_scale))
	top.position = Vector2((viewport_size.x - top_width) * 0.5, 12)
	top.size = Vector2(top_width, 0)
	var height := minf(contents.get_combined_minimum_size().y + 12, viewport_size.y * 0.45)
	var tray_width := minf(viewport_size.x - 32, controller.world.menu.settings.combat_width * sqrt(text_scale))
	tray.size = Vector2(tray_width, height)
	tray.position = Vector2((viewport_size.x - tray_width) * 0.5, viewport_size.y - tray.size.y - 12)
	log_panel.size = Vector2(minf(360 * sqrt(text_scale), viewport_size.x - 48), maxf(60, minf(230, tray.position.y - top.get_rect().end.y - 24)))
	log_panel.position = Vector2(viewport_size.x - log_panel.size.x - 24, top.get_rect().end.y + 12)
	last_layout_inputs = layout_inputs()

func layout_inputs() -> Array:
	var settings: MenuSettings = controller.world.menu.settings
	return [get_viewport_rect().size, settings.text_scale, settings.combat_health_width, settings.combat_width]

func request_layout() -> void:
	layout_dirty = true

func _process(_delta: float) -> void:
	if visible and (layout_dirty or layout_inputs() != last_layout_inputs):
		# A later minimum-size signal requests the next-frame text-wrap correction.
		# Settled content no longer rewrites every Control rectangle each frame.
		fit_layout()

func reset() -> void:
	log_panel.hide()
	for row in cards.values():
		if row.tween != null and row.tween.is_valid():
			row.tween.kill()
		row.target = -1.0

func toggle_log() -> void:
	controller.close_battle_menu()
	log_panel.visible = not log_panel.visible
	log_toggle.text = "Close log" if log_panel.visible else "Battle log"

func refresh() -> void:
	request_layout()
	var battle: TacticalBattle = controller.display_battle()
	if battle == null:
		return
	var resolving: bool = controller.playback.busy
	for side in ["ally", "enemy"]:
		var profile: Dictionary = battle.ally if side == "ally" else battle.enemy
		var row: Dictionary = cards[side]
		var hp := battle.unit_hp(side)
		row.name.text = "%s%s   Lv %d" % ["Wild " if side == "enemy" else "", profile.display_name, profile.level]
		row.name.tooltip_text = row.name.text
		row.metadata.text = "%s  /  %s" % [str(profile.affinity).capitalize(), str(profile.class_id).capitalize()]
		row.metadata.tooltip_text = row.metadata.text
		var passive: ClassBuffDefinition = controller.settings.class_buffs.definition(profile.class_id)
		if passive != null:
			var unit := " tiles" if profile.class_id == "skyborne" else (" turns" if profile.class_id == "feyborn" else "%")
			row.panel.tooltip_text = row.metadata.text + "\n" + "%s · %d%s\n%s" % [passive.display_name, battle.passives.potency(side), unit, passive.description]
		row.hp.text = "%d / %d" % [hp, profile.max_hp]
		var summary := battle.status_summary(side)
		row.effects.text = summary
		row.effects.visible = not summary.is_empty()
		row.effects.tooltip_text = summary
		row.bar.max_value = profile.max_hp
		var fraction := float(hp) / float(profile.max_hp)
		var color := Color("81b990") if fraction > 0.5 else (Color("e1ba65") if fraction > 0.25 else Color("ed8176"))
		var fill := MenuTheme.box(color, color, 4)
		fill.set_content_margin_all(0)
		row.bar.add_theme_stylebox_override("fill", fill)
		if row.target != float(hp):
			if row.tween != null and row.tween.is_valid():
				row.tween.kill()
			if row.target < 0 or controller.sightings.visual_settings.health_bar_seconds == 0:
				row.bar.value = hp
			else:
				row.tween = create_tween()
				row.tween.tween_property(row.bar, "value", float(hp), controller.sightings.visual_settings.health_bar_seconds)
			row.target = float(hp)
	phase_label.text = "DEPLOYMENT" if battle.phase == "deployment" else ("YOUR TURN" if battle.turn == "ally" else "OPPONENT TURN")
	if battle.phase not in ["deployment", "active"]:
		phase_label.text = str(battle.phase).to_upper()
	round_label.text = "Choose a release tile" if battle.phase == "deployment" else "R%02d · AP %d/%d · Free move %d" % [battle.round_number, battle.actions_remaining, battle.action_points, battle.remaining]
	status_label.text = "Release your companion" if battle.phase == "deployment" else ("Choose a target · Left-click confirms" if controller.aimed_slot >= 0 else "Click a blue tile to move, or choose a move")
	if resolving:
		status_label.text = controller.playback.current.get("caption", "")
		if status_label.text.is_empty():
			status_label.text = "Resolving consequences…"
	elif controller.completion_failed:
		status_label.text = "Result could not be recorded · Retry to continue"
	elif not controller.commander_ready():
		status_label.text = "Trainer running to the outside command position"
	retry_button.visible = controller.completion_failed
	status_label.visible = resolving or battle.phase == "deployment" or controller.completion_failed or not controller.commander_ready()
	cancel_button.visible = controller.aimed_slot >= 0 and not resolving
	command_header.visible = status_label.visible or cancel_button.visible
	moves.visible = battle.phase == "active"
	controller.capture_button.visible = battle.phase == "active"
	controller.wait_button.visible = battle.phase == "active"
	tray.tooltip_text = "Free movement comes from Speed; extra movement spends AP. Moves keep your turn open. End turn when finished. Right-click to inspect."
	intent_label.text = "Actions resume after resolution" if resolving else battle.enemy_intent()
	if not battle.activity.is_empty():
		intent_label.text += "   |   Imprint: " + battle.winner().capitalize()
	phase_label.tooltip_text = intent_label.text
	round_label.tooltip_text = intent_label.text
	var shown_log: Array[String] = battle.log.duplicate()
	if resolving and not controller.playback.current.caption.is_empty():
		shown_log.append(controller.playback.current.caption)
	log_label.text = "BATTLE LOG\n\n" + "\n".join(shown_log.slice(maxi(0, shown_log.size() - 30)))
	var displayed_moves := battle.moves_for("ally")
	for slot in range(controller.move_buttons.size()):
		var action: Button = controller.move_buttons[slot]
		action.visible = slot < displayed_moves.size()
		if not action.visible:
			continue
		var move: Dictionary = displayed_moves[slot]
		var legal: Array[Vector2i] = controller.legal_targets(slot)
		action.disabled = resolving or battle.phase != "active" or battle.turn != "ally" or legal.is_empty()
		var supply := "fallback" if move.id == "last_effort" else "%d/%d" % [battle.uses_left("ally", move), SolMove.uses(move)]
		action.text = "%s · %s · %s" % [move.name, "Passive" if move.effect == "passive" else "%d AP" % SolMove.cost(move), supply]
		action.set_pressed_no_signal(slot == controller.aimed_slot)
		var tint: Color = controller.sightings.visual_settings.color_for(move.affinity)
		action.add_theme_stylebox_override("normal", MenuTheme.box(Color("233932"), Color(tint, 0.65)))
		action.tooltip_text = controller.move_description(move)
		if resolving:
			action.tooltip_text += "\nWait for the current resolution to finish."
		elif legal.is_empty() and move.effect != "passive":
			action.tooltip_text += "\n" + controller.no_target_reason(move)
	controller.capture_button.disabled = resolving or battle.capture_chance() <= 0
	controller.capture_button.text = "Seal %.0f%% · %d AP" % [battle.capture_chance() * 100.0, battle.seal_action_points]
	controller.capture_button.tooltip_text = "Costs %d AP. Unlimited testing Seals. Failure ends your turn; success resolves capture." % battle.seal_action_points
	controller.wait_button.disabled = resolving or battle.phase != "active" or battle.turn != "ally"
	controller.wait_button.tooltip_text = "Finish your turn and let the opponent act. Unspent AP and free movement do not carry over."
	retreat_button.disabled = resolving or controller.completion_failed or battle.phase not in ["deployment", "active"]
	controller.quantum_choice.disabled = resolving or controller.completion_failed or not controller.commander_ready() or battle.phase != "active"
	controller.quantum_choice.visible = battle.ally_moves.any(func(move: Dictionary) -> bool: return move.effect == "quantum")
	refresh_target()

func refresh_target() -> void:
	var battle: TacticalBattle = controller.display_battle()
	if battle == null:
		return
	if controller.completion_failed:
		target_label.visible = true
		target_label.text = "The resolved outcome is retained · Retry does not repeat actions or rolls"
		return
	if not controller.commander_ready():
		target_label.visible = true
		target_label.text = "Deployment opens on arrival · Throw range starts at the trainer"
		return
	target_label.visible = battle.phase == "deployment" or controller.aimed_slot >= 0
	if controller.playback.busy:
		target_label.visible = false
		target_label.text = "Resolution in progress · Inspect or open the battle menu to pause"
		return
	var at: Vector2i = controller.cursor
	if battle.phase == "deployment":
		target_label.text = "Release here · Left-click to confirm" if battle.deployment_tiles().has(at) else "Unavailable release tile · Choose a blue tile near the trainer"
		return
	if controller.aimed_slot < 0:
		var options := battle.reachable()
		if battle.phase == "active" and battle.turn == "ally" and battle.actions_remaining == 0 and battle.remaining == 0:
			target_label.visible = true
			target_label.text = "No AP or free movement left · End turn to continue"
			return
		if options.has(at) and not options[at].is_empty():
			target_label.visible = true
			var cost := battle.route_cost(battle.ally_cell, options[at], "ally")
			target_label.text = "Move %d tiles · costs %d free movement + %d AP · click to commit" % [options[at].size(), mini(cost, battle.remaining), maxi(0, cost - battle.remaining)]
		else:
			if not battle.bounds.has_point(at):
				target_label.text = "Outside the arena · Choose a reachable blue tile"
			elif not battle.passable(at):
				target_label.text = "Blocked ground · Choose a reachable blue tile"
			elif at == battle.enemy_cell or at == battle.trainer:
				target_label.text = "Occupied ground · Choose a move to act, or a blue tile to reposition"
			else:
				target_label.text = "Blue: reachable ground · Click a move to aim · Right-click to inspect"
		return
	var move: Dictionary = battle.moves_for("ally")[controller.aimed_slot]
	if not battle.can_use(controller.aimed_slot, at):
		target_label.text = "Choose a highlighted tile. This position is not a legal target."
	elif move.effect == "damage" and controller.sightings.visual_settings.damage_preview:
		var damage := mini(battle.enemy_hp, battle.damage_for("ally", move, battle.ally_cell))
		target_label.text = "%s → %s   ·   %d damage   ·   %d HP remaining%s" % [move.name, battle.enemy.display_name, damage, battle.enemy_hp - damage, "   ·   Exhausts target" if damage >= battle.enemy_hp else ""]
	elif move.effect == "heal":
		target_label.text = "%s   ·   Restores %d HP" % [move.name, mini(int(move.power), int(battle.ally.max_hp) - battle.ally_hp)]
	elif move.effect == "field":
		target_label.text = "%s   ·   Highlighted area affects both sides   ·   %d rounds" % [move.name, move.duration]
	else:
		target_label.text = "%s   ·   Left-click to confirm   ·   Esc cancels" % move.name
	var secondary := SolMove.secondary_summary(move)
	if battle.can_use(controller.aimed_slot, at):
		target_label.text += " · %d AP → %d left" % [SolMove.cost(move), battle.actions_remaining - SolMove.cost(move)]
	if not secondary.is_empty():
		target_label.text += " · + " + secondary
