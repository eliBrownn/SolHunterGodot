extends Node
## UI/lifecycle bridge. TacticalBattle owns turns; ExpeditionState owns durable results.

var world: Node2D
var encounters: Node
var sightings: Node3D
var settings: BattleSettings
var session: TacticalBattle
var source_state: ExpeditionState
var serial := 0
var enemy_id := ""
var selection_panel: PanelContainer
var choice_buttons: Array[Button] = []
var battle_panel: PanelContainer
var status_label: Label
var intent_label: Label
var log_label: Label
var attack_button: Button
var wait_button: Button
var companion_label: Label
var pending_target: Dictionary = {}
var choosing := false
var cursor := Vector2i.ZERO
var visuals := Node3D.new()
var visual_seconds := 0.0

func bind(source: Node2D, entry: Node, actors: Node3D, tuning: BattleSettings) -> void:
	world = source
	encounters = entry
	sightings = actors
	settings = tuning if tuning != null and tuning.valid() else preload("res://resources/battle_settings.tres")
	if settings != tuning:
		push_warning("Invalid battle settings; using the default prototype roster.")
	world.host.add_child(visuals)
	build_ui()
	encounters.battle_button.disabled = not settings.enabled
	encounters.battle_requested.connect(begin_battle)
	encounters.battle_retreat_requested.connect(retreat)
	world.companion_requested.connect(open_choice)
	world.refuge_recovery_requested.connect(recover)
	world.battle_input_requested.connect(handle_input)
	world.withdraw_requested.connect(cancel_choice)
	world.state_replaced.connect(on_state)
	on_state(world.persistent_state)

func button(text: String, action: Callable, box: VBoxContainer) -> Button:
	var node := Button.new()
	node.text = text
	node.custom_minimum_size.y = 42
	node.pressed.connect(action)
	box.add_child(node)
	return node

func build_ui() -> void:
	selection_panel = world.panel_at(Rect2(350, 170, 580, 450))
	var choices := VBoxContainer.new()
	choices.add_theme_constant_override("separation", 16)
	selection_panel.add_child(choices)
	choices.add_child(world.label("CHOOSE YOUR COMPANION", 23, Color("e1c791")))
	choices.add_child(world.label("Choose a companion for this expedition.", 16))
	for index in range(settings.starters.size()):
		var option: BattleProfile = settings.starters[index]
		choice_buttons.append(button("%d · %s — HP %d · %s" % [index + 1, option.display_name, option.max_hp, option.move_name], choose.bind(index), choices))
	button("Cancel · Escape", cancel_choice, choices)
	selection_panel.hide()
	battle_panel = world.panel_at(Rect2(890, 145, 365, 535))
	var actions := VBoxContainer.new()
	actions.add_theme_constant_override("separation", 12)
	battle_panel.add_child(actions)
	actions.add_child(world.label("TACTICAL ENCOUNTER", 21, Color("e1c791")))
	status_label = world.label("", 16)
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.custom_minimum_size = Vector2(325, 100)
	actions.add_child(status_label)
	intent_label = world.label("", 15, Color("edc498"))
	intent_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intent_label.custom_minimum_size.y = 60
	actions.add_child(intent_label)
	attack_button = button("Basic attack · Space", attack, actions)
	wait_button = button("End turn · Enter", wait_turn, actions)
	button("Retreat · Escape", retreat, actions)
	log_label = world.label("", 14)
	log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	actions.add_child(log_label)
	battle_panel.hide()
	companion_label = world.label("C · Choose companion", 16, Color("e1c791"))
	companion_label.position = Vector2(42, 646)
	world.hud.add_child(companion_label)

func on_state(state: ExpeditionState) -> void:
	if source_state != null and source_state.battle_progress_changed.is_connected(refresh_companion):
		source_state.battle_progress_changed.disconnect(refresh_companion)
	source_state = state
	source_state.battle_progress_changed.connect(refresh_companion)
	session = null
	serial = 0
	enemy_id = ""
	choosing = false
	pending_target.clear()
	selection_panel.hide()
	battle_panel.hide()
	sightings.battle_hidden_ids.clear()
	clear_visuals()
	refresh_companion()

func refresh_companion() -> void:
	companion_label.visible = settings.enabled
	var hero := source_state.starter_view()
	companion_label.text = "C · Choose companion" if hero.is_empty() else "%s · HP %d/%d · H recover at refuge" % [hero.profile.display_name, hero.hp, hero.profile.max_hp]

func open_choice() -> void:
	if not settings.valid() or not settings.enabled or world.moving or world.confirmation.visible or session != null:
		return
	if not source_state.starter_view().is_empty():
		world.message("Your chosen companion is " + str(source_state.starter_view().profile.display_name) + ".", false)
		return
	choosing = true
	world.encounter_active = true
	world.paused = true
	world.pause_panel.hide()
	world.journal_panel.hide()
	encounters.encounter_panel.hide()
	selection_panel.show()
	choice_buttons[0].grab_focus()

func choose(index: int) -> void:
	if not choosing or index < 0 or index >= settings.starters.size() or not settings.valid():
		return
	if not source_state.choose_starter(settings.starters[index].snapshot(), index):
		world.message("A companion cannot be chosen again or over an existing owned team.", false)
		return
	choosing = false
	selection_panel.hide()
	world.message("%s joined your party." % settings.starters[index].display_name)
	if not pending_target.is_empty() and not encounters.active_target.is_empty():
		var target := pending_target.duplicate(true)
		pending_target.clear()
		begin_battle(target)
	else:
		world.encounter_active = false
		world.paused = false

func cancel_choice() -> void:
	if not choosing:
		return
	choosing = false
	selection_panel.hide()
	pending_target.clear()
	if not encounters.active_target.is_empty():
		encounters.withdraw()
	else:
		world.encounter_active = false
		world.paused = false

func begin_battle(target: Dictionary) -> void:
	if session != null or not settings.valid() or not settings.enabled or not source_state.wild_available(target.id):
		return
	var hero := source_state.starter_view()
	if hero.is_empty():
		pending_target = target.duplicate(true)
		open_choice()
		return
	if hero.hp <= 0:
		world.message("Your companion is exhausted. Return to the refuge and press H.", false)
		encounters.encounter_panel.show()
		return
	if source_state.individual_view(hero.id).location != "party":
		world.message("Bring your companion into the party before battle.", false)
		return
	var record := source_state.individual_view(target.id)
	var opponent := settings.opponent(record.species_id)
	if opponent.is_empty() or opponent.class_id != record.class_id:
		world.message("This Sol has no compatible authored battle profile.", false)
		return
	# Wild profiles supply combat stats; affinity belongs to the actual individual.
	opponent.affinity = record.affinity
	var enemy_cell: Vector2i = target.cell
	var prepared := TacticalBattle.prepare(world.terrain, world.cell, enemy_cell, hero.profile, int(hero.hp), opponent, settings)
	if prepared == null:
		world.message("No connected release space here. Withdraw and reposition.", false)
		encounters.encounter_panel.show()
		return
	var token := source_state.begin_battle(target.id)
	if token == 0:
		return
	session = prepared
	serial = token
	enemy_id = target.id
	encounters.battle_running = true
	encounters.encounter_panel.hide()
	world.encounter_active = true
	world.paused = true
	sightings.battle_hidden_ids[enemy_id] = true
	cursor = session.deployment_tiles()[0]
	battle_panel.show()
	update_view()

func recover() -> void:
	if world.encounter_active or world.moving or not world.terrain.is_camp(world.cell):
		world.message("Recover your companion at the refuge with H.", false)
		return
	world.message("Your companion recovered fully." if source_state.recover_starter() else "Your companion needs no recovery.", false)

func select_cell(cell: Vector2i) -> void:
	if session == null:
		return
	if session.phase == "deployment":
		session.deploy(cell)
	else:
		session.move_ally(cell)
	after_command()

func attack() -> void:
	if session != null:
		session.attack()
		after_command()

func wait_turn() -> void:
	if session != null:
		session.wait_turn()
		after_command()

func retreat() -> void:
	if session != null:
		session.retreat()
		after_command()

func after_command() -> void:
	if session == null:
		return
	if session.phase in ["victory", "exhaustion", "retreat"]:
		var outcome := session.phase
		var protection: int = encounters.settings.withdrawal_safe_steps if encounters.settings.valid() else 3
		if not source_state.complete_battle(serial, session.ally_hp, outcome, protection):
			world.message("Battle result could not be committed. The encounter remains open.", false)
			return
		session = null
		serial = 0
		sightings.battle_hidden_ids.erase(enemy_id)
		enemy_id = ""
		clear_visuals()
		battle_panel.hide()
		encounters.battle_running = false
		encounters.withdraw()
		encounters.safe_steps = 0 # The persistent battle receipt owns post-battle protection.
		if outcome == "exhaustion":
			world.cell = Vector2i.ZERO
			world.destination = world.cell
			world.moving = false
		world.rebuild_world()
		world.message({"victory": "Victory. The wild Sol is exhausted. Save your expedition with F5.", "exhaustion": "Your companion is exhausted, not lost. Back at the refuge: press H to recover.", "retreat": "Retreated safely. Your companion's remaining health is retained."}[outcome])
		return
	update_view()

func handle_input(event: InputEvent) -> void:
	if choosing:
		if event is InputEventKey and event.pressed and event.physical_keycode in [KEY_1, KEY_2, KEY_3]:
			choose(int(event.physical_keycode) - int(KEY_1))
		return
	if session == null:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var point: Variant = world.host.pointer_world()
		if point != null:
			select_cell(Vector2i((point / 32.0).floor()))
	elif event is InputEventKey and event.pressed:
		if event.physical_keycode == KEY_ESCAPE:
			retreat()
		elif event.physical_keycode == KEY_SPACE:
			attack()
		elif event.physical_keycode == KEY_ENTER:
			if session.phase == "deployment":
				select_cell(cursor)
			else:
				wait_turn()
		else:
			var direction: Vector2i = {KEY_W: Vector2i.UP, KEY_UP: Vector2i.UP, KEY_A: Vector2i.LEFT, KEY_LEFT: Vector2i.LEFT, KEY_S: Vector2i.DOWN, KEY_DOWN: Vector2i.DOWN, KEY_D: Vector2i.RIGHT, KEY_RIGHT: Vector2i.RIGHT}.get(event.physical_keycode, Vector2i.ZERO)
			if direction != Vector2i.ZERO:
				if session.phase == "deployment":
					if session.bounds.has_point(cursor + direction):
						cursor += direction
					update_view()
				else:
					select_cell(session.ally_cell + direction)

func clear_visuals() -> void:
	for node in visuals.get_children():
		node.free()

func point(cell: Vector2i) -> Vector3:
	var relative: Vector2 = world.center(cell) - world.camera.position
	return Vector3(relative.x / 32.0, 0.13, relative.y / 32.0)

func tile(cell: Vector2i, color: Color) -> void:
	var node := MeshInstance3D.new()
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(0.93, 0.93)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = color
	node.mesh = mesh
	node.material_override = material
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.position = point(cell)
	visuals.add_child(node)

func unit(cell: Vector2i, profile: Dictionary) -> void:
	var sprite := SolOrb.new()
	sprite.configure(profile.affinity, sightings.visual_settings, float(cell.x))
	sprite.ground_y = 0.13
	sprite.position = point(cell)
	sprite.animate(visual_seconds, sightings.settings.bob_pixels, sightings.settings.bob_cycles)
	visuals.add_child(sprite)
	var label := Label3D.new()
	label.text = profile.display_name + " · " + str(profile.affinity).capitalize()
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 20
	label.pixel_size = 0.012
	label.position.y = sightings.visual_settings.diameter * 0.5 + 0.3
	sprite.add_child(label)

func update_view() -> void:
	if session == null:
		return
	status_label.text = "%s HP %d/%d\n%s HP %d/%d\n%s" % [session.ally.display_name, session.ally_hp, session.ally.max_hp, session.enemy.display_name, session.enemy_hp, session.enemy.max_hp,
		"Click blue tile / arrows + Enter to deploy" if session.phase == "deployment" else "Round %d · movement %d/%d\nBlue tiles / arrows move your Sol" % [session.round_number, session.remaining, session.movement]]
	intent_label.text = session.enemy_intent()
	attack_button.text = "%s · %d damage · Space" % [session.ally.move_name, TacticalBattle.damage(session.ally, session.enemy)]
	if session.phase == "active" and not session.can_attack():
		attack_button.text = "%s · out of range" % session.ally.move_name
	attack_button.disabled = not session.can_attack()
	wait_button.disabled = session.phase != "active"
	var start := maxi(0, session.log.size() - 3)
	log_label.text = "\n".join(session.log.slice(start))
	clear_visuals()
	var available: Variant = session.deployment_tiles() if session.phase == "deployment" else session.reachable().keys()
	for cell: Vector2i in session.cells:
		var color := Color(0.4, 0.4, 0.4, 0.12)
		if not session.cells[cell]:
			color = Color(0.5, 0.15, 0.12, 0.15)
		elif available.has(cell):
			color = Color(0.2, 0.65, 0.9, 0.45)
		if cell == session.enemy_cell:
			color = Color(0.9, 0.25, 0.2, 0.6)
		elif session.phase == "deployment" and cell == cursor:
			color = Color(0.9, 0.8, 0.3, 0.65)
		elif session.phase == "active" and cell == session.ally_cell:
			color = Color(0.3, 0.9, 0.6, 0.65)
		tile(cell, color)
	unit(session.enemy_cell, session.enemy)
	if session.phase != "deployment":
		unit(session.ally_cell, session.ally)

func _process(delta: float) -> void:
	if session == null or world.smoke_mode:
		return
	visual_seconds += delta
	for node in visuals.get_children():
		if node is SolOrb:
			node.animate(visual_seconds, sightings.settings.bob_pixels, sightings.settings.bob_cycles)
