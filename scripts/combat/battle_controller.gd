extends Node
const BoardFx = preload("res://scripts/presentation/combat_board_fx.gd")
## UI/lifecycle bridge. TacticalBattle owns turns; ExpeditionState owns durable results.

var world: Node2D
var encounters: Node
var sightings: Node3D
var settings: BattleSettings
var session: TacticalBattle
var movebook_validation := preload("res://scripts/core/runtime_validation_cache.gd").new()
var movebook_templates: Dictionary = {}
var movebook_template_revision := -1
var source_state: ExpeditionState
var serial := 0
var enemy_id := ""
var overload_baseline: Dictionary = {}
var selection_panel: PanelContainer
var choice_buttons: Array[Button] = []
var choice_preview: SubViewportContainer
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
var cursor_marker: MeshInstance3D
var visuals := Node3D.new()
var visual_seconds := 0.0
var library: MoveLibrary
var loadout: Node
var move_buttons: Array[Button] = []
var aimed_slot := -1
var quantum_choice: OptionButton
var feedback_view: Node3D
var progression: ProgressionSettings
var capture_button: Button
var combat_hud: CombatHud
var hidden_exploration: Array[Control] = []
var preview_nodes: Array[Node3D] = []
var impacts: Dictionary = {}
var retreat_dialog: ConfirmationDialog = preload("res://scripts/ui/mouse_confirmation.gd").new()
var retreat_session: TacticalBattle
var battle_menu: PanelContainer
var battle_shield: ColorRect
var playback := BattlePlayback.new()
var completion_failed := false
var completion_session: TacticalBattle
var completion_packet: Dictionary = {}
var commander_was_ready := true
var visual_layout: Dictionary = {}
var tile_pool: Array[MeshInstance3D] = []
var preview_pool: Array[MeshInstance3D] = []
var tile_used := 0
var preview_used := 0
var tile_meshes: Dictionary = {}
var unit_views: Dictionary = {}
var reserve_panel: PanelContainer
var reserves_declined := false
var risk_dialog: ConfirmationDialog = preload("res://scripts/ui/mouse_confirmation.gd").new()
var storm_outline: MeshInstance3D


func bind(source: Node2D, entry: Node, actors: Node3D, tuning: BattleSettings) -> void:
	world = source
	encounters = entry
	sightings = actors
	settings = tuning if tuning != null and tuning.valid() else preload("res://resources/battle_settings.tres")
	if settings != tuning:
		push_warning("Invalid battle settings; using the default prototype roster.")
	library = world.host.move_library if world.host.move_library != null and world.host.move_library.valid() else preload("res://resources/move_library.tres")
	progression = world.host.progression_settings if world.host.progression_settings != null and world.host.progression_settings.valid() else preload("res://resources/progression_settings.tres")
	world.host.add_child(visuals)
	prepare_board_rendering()
	build_ui()
	feedback_view = preload("res://scripts/combat/battle_feedback.gd").new()
	world.host.add_child(feedback_view)
	feedback_view.bind(world, sightings.visual_settings)
	playback.changed.connect(show_resolution)
	playback.readiness_settings = world.host.readiness_settings
	playback.settled.connect(after_command)
	loadout = preload("res://scripts/combat/move_loadout.gd").new()
	add_child(loadout)
	loadout.bind(self)
	encounters.battle_button.disabled = not settings.enabled
	encounters.battle_requested.connect(begin_battle)
	encounters.battle_retreat_requested.connect(retreat)
	world.companion_requested.connect(open_choice)
	world.refuge_recovery_requested.connect(recover)
	world.battle_input_requested.connect(handle_input)
	world.withdraw_requested.connect(cancel_choice)
	world.state_replaced.connect(on_state)
	on_state(world.persistent_state)

func button(text: String, action: Callable, box: Container) -> Button:
	var node := Button.new()
	node.text = text
	node.custom_minimum_size.y = 42
	node.pressed.connect(action)
	box.add_child(node)
	return node

func build_ui() -> void:
	risk_dialog.title = "Limited storm protection"
	risk_dialog.dialog_text = "Your field kit offers limited protection against this battle storm. Exposure can cause blackout even while your Sol remains healthy. Continue?"
	risk_dialog.ok_button_text = "Enter anyway"
	world.hud.add_child(risk_dialog)
	retreat_dialog.title = "Retreat from this encounter?"
	retreat_dialog.dialog_text = "Leave this battle and retain your companion’s remaining health."
	retreat_dialog.ok_button_text = "Retreat"
	world.hud.add_child(retreat_dialog)
	retreat_dialog.confirmed.connect(func() -> void:
		var expected := retreat_session
		cancel_retreat()
		if session != null and session == expected:
			# Confirmation commits one complete withdrawal readiness, replacing the draft.
			if playback.timeline != null and playback.timeline.planning:
				playback.timeline.clear()
				if playback.submit("retreat"):
					playback.submit("wait")
				after_command()
			else:
				retreat())
	retreat_dialog.canceled.connect(cancel_retreat)
	selection_panel = world.panel_at(Rect2(350, 170, 580, 450))
	var choices := VBoxContainer.new()
	choices.add_theme_constant_override("separation", 16)
	selection_panel.add_child(choices)
	choices.add_child(world.label("CHOOSE YOUR COMPANION", 23, Color("e1c791")))
	choices.add_child(world.label("Choose a companion for this expedition.", 16))
	selection_panel.theme = world.menu.frame.theme
	choice_preview = preload("res://scripts/ui/sol_model_preview.gd").new()
	choice_preview.custom_minimum_size = Vector2(0, world.menu.settings.preview_height)
	choices.add_child(choice_preview)
	choice_preview.show_profile(settings.starters[0].snapshot(), sightings.visual_settings, world.menu.settings, settings.species_catalog)
	for index in range(settings.starters.size()):
		var option: BattleProfile = settings.starters[index]
		var starter_button := button("%d · %s — HP %d · %s" % [index + 1, option.display_name, option.max_hp, option.move_name], choose.bind(index), choices)
		choice_buttons.append(starter_button)
		var inspect := func() -> void: choice_preview.show_profile(option.snapshot(), sightings.visual_settings, world.menu.settings, settings.species_catalog)
		starter_button.mouse_entered.connect(inspect)
		starter_button.focus_entered.connect(inspect)
	button("Cancel · Escape", cancel_choice, choices)
	selection_panel.hide()
	combat_hud = CombatHud.new()
	combat_hud.bind(self)
	retreat_dialog.theme = combat_hud.theme
	battle_panel = combat_hud
	status_label = combat_hud.status_label
	intent_label = combat_hud.intent_label
	log_label = combat_hud.log_label
	companion_label = world.label("C · Choose companion", 16, Color("e1c791"))
	companion_label.position = Vector2(42, 646)
	world.hud.add_child(companion_label)

func on_state(state: ExpeditionState) -> void:
	risk_dialog.hide()
	if is_instance_valid(reserve_panel): reserve_panel.queue_free()
	reserve_panel = null
	overload_baseline.clear()
	playback.reset()
	completion_failed = false
	completion_session = null
	completion_packet.clear()
	world.host.player_visual.reset_sideline()
	world.host.camera_focus = Vector3.ZERO
	world.host.apply_camera()
	close_battle_menu()
	retreat_dialog.hide()
	retreat_session = null
	restore_exploration_hud()
	combat_hud.reset()
	if source_state != null and source_state.battle_progress_changed.is_connected(refresh_companion):
		source_state.battle_progress_changed.disconnect(refresh_companion)
	source_state = state
	source_state.configure_progression(progression)
	source_state.configure_sol_stats(settings.sol_stats, settings.class_buffs)
	source_state.battle_progress_changed.connect(refresh_companion)
	ensure_movebooks()
	session = null
	serial = 0
	enemy_id = ""
	choosing = false
	pending_target.clear()
	selection_panel.hide()
	battle_panel.hide()
	sightings.battle_hidden_ids.clear()
	clear_visuals()
	feedback_view.reset()
	impacts.clear()
	refresh_companion()

func refresh_companion() -> void:
	ensure_movebooks()
	companion_label.visible = settings.enabled and session == null
	var hero := source_state.active_sol_view()
	companion_label.text = "C · Sols" if hero.is_empty() else "%s · %d/%d HP" % [hero.profile.display_name, hero.hp, hero.profile.max_hp]

func open_choice() -> void:
	if not settings.valid() or not settings.enabled or world.moving or world.confirmation.visible or session != null:
		return
	if not source_state.active_sol_view().is_empty():
		loadout.open(source_state.active_sol_view().id)
		return
	choosing = true
	world.encounter_active = true
	world.paused = true
	world.pause_panel.hide()
	encounters.encounter_panel.hide()
	selection_panel.show()
	choice_buttons[0].grab_focus()

func choose(index: int) -> void:
	if not choosing or index < 0 or index >= settings.starters.size() or not settings.valid():
		return
	if not source_state.choose_starter(settings.starters[index].snapshot(), index, settings.starters[index].evolution_forms):
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

func begin_battle(target: Dictionary, risk_accepted: bool = false) -> void:
	if session != null or not settings.valid() or not settings.enabled or not source_state.wild_available(target.id):
		return
	var hero := source_state.active_sol_view()
	if hero.is_empty():
		pending_target = target.duplicate(true)
		open_choice()
		return
	if hero.hp <= 0:
		world.message("Your companion is exhausted. Return to the refuge and choose Recover party.", false)
		encounters.encounter_panel.show()
		return
	if playback.readiness_settings != null and playback.readiness_settings.enabled and playback.readiness_settings.gear_protection < 0.25 and not risk_accepted:
		var expected_state := source_state
		var expected_target := target.duplicate(true)
		for connection in risk_dialog.confirmed.get_connections(): risk_dialog.confirmed.disconnect(connection.callable)
		risk_dialog.confirmed.connect(func() -> void:
			if source_state == expected_state: begin_battle(expected_target, true), CONNECT_ONE_SHOT)
		risk_dialog.popup_centered()
		return
	if source_state.individual_view(hero.id).location != "party":
		world.message("Bring your companion into the party before battle.", false)
		return
	var record := source_state.individual_view(target.id)
	var travel: Dictionary = source_state.roaming_view(target.id).get("traversal", {})
	if not travel.is_empty() and travel.mode != "ground":
		world.message("Wait for this Sol to return to land before battle.", false)
		return
	ensure_movebooks([hero.id, target.id])
	var opponent := source_state.wild_profile(target.id)
	if opponent.is_empty() or opponent.class_id != record.class_id:
		world.message("This Sol has no compatible authored battle profile.", false)
		return
	# Wild profiles supply combat stats; affinity belongs to the actual individual.
	opponent.affinity = record.affinity
	var enemy_cell: Vector2i = target.cell
	var sizes := {"ally": int(source_state.individual_view(hero.id).footprint), "enemy": int(record.footprint)}
	var prepared := TacticalBattle.prepare(world.terrain, world.cell, enemy_cell, hero.profile, int(hero.hp), opponent, settings, true, sizes)
	if prepared == null:
		world.message("No connected release space here. Withdraw and reposition.", false)
		encounters.encounter_panel.show()
		return
	ensure_movebooks([hero.id, target.id])
	if source_state.movebook(hero.id).is_empty() or source_state.movebook(target.id).is_empty():
		world.message("Both Sols need authored species move pools before battle.", false)
		encounters.encounter_panel.show()
		return
	prepared.set_movebooks(source_state.movebook(hero.id), source_state.movebook(target.id))
	prepared.set_class_passives(source_state.stat_view(hero.id), source_state.stat_view(target.id), settings.class_buffs)
	prepared.recovery_interval = library.recovery_interval
	prepared.seal_power = settings.seal_power
	prepared.field_damage = library.field_damage
	prepared.rough_cost = library.rough_cost
	prepared.assisted_cost = library.assisted_cost
	prepared.resisted_cost = library.resisted_cost
	prepared.vastra_settings = (world.vastra_settings if world.vastra_settings != null and world.vastra_settings.valid() else VastraSettings.new()).duplicate(true)
	var saved_tiles := source_state.affinity_tiles()
	var initial_overloads: Dictionary = {}
	for at: Vector2i in prepared.cells:
		var environment := source_state.environment_view(at, world.terrain.sample(at))
		prepared.tile_concentrations[at] = int(environment.concentration)
		prepared.tile_overloads[at] = int(environment.overload)
		initial_overloads[AffinityImprint.key(at)] = int(environment.overload)
		prepared.tile_affinities[at] = environment.affinity
		var row: Dictionary = saved_tiles.get(AffinityImprint.key(at), {})
		for kind in row.get("conditions", {}):
			var effect: Dictionary = row.conditions[kind]
			prepared.fields[at] = {"kind": kind, "direction": Vector2i(int(effect.direction[0]), int(effect.direction[1])), "round": 0, "expires": int(effect.level) + 1}
	prepared.commander_route = BattleCommander.plan(prepared, world.cell, world.can_step)
	if not prepared.commander_route.is_empty():
		prepared.trainer = prepared.commander_route.back()
	if not prepared.passable(enemy_cell) or prepared.commander_route.is_empty() or prepared.deployment_tiles().is_empty():
		world.message("No safe outside command position with throw space here. Withdraw and reposition.", false)
		encounters.encounter_panel.show()
		return
	if playback.readiness_settings != null and playback.readiness_settings.enabled and not source_state.return_prepared():
		world.message("Renew your return preparation at camp before another confrontation.", false)
		return
	var combat_area: Dictionary = prepared.cells if playback.readiness_settings != null and playback.readiness_settings.enabled else {}
	var token := source_state.begin_battle(target.id, combat_area)
	if token == 0:
		world.message("Battle cannot start: check party health or persistent terrain capacity.", false)
		return
	feedback_view.reset()
	combat_hud.reset()
	impacts.clear()
	hide_exploration_hud()
	session = prepared
	reserves_declined = false
	overload_baseline = initial_overloads
	completion_failed = false
	completion_session = null
	commander_was_ready = false
	world.host.player_visual.sideline_walk_speed = settings.commander_run_speed
	world.host.player_visual.update_sideline(0.0)
	playback.bind(session, sightings.visual_settings, token, {"ally": hero.id, "enemy": target.id})
	quantum_choice.select(0)
	session.capture_seed = world.terrain.world_seed ^ token ^ int(target.id.hash())
	aimed_slot = -1
	serial = token
	enemy_id = target.id
	encounters.battle_running = true
	encounters.encounter_panel.hide()
	world.encounter_active = true
	# Encounter ownership locks exploration input; only a real pause stops time.
	world.paused = false
	sightings.battle_hidden_ids[enemy_id] = true
	cursor = session.deployment_tiles()[0]
	battle_panel.show()
	update_view()

func recover() -> void:
	if world.paused or world.confirmation.visible or world.encounter_active or world.moving or not world.terrain.is_camp(world.cell):
		world.message("Recover your companion at the refuge with H.", false)
		return
	var recovered := source_state.recover_party()
	source_state.prepare_return()
	world.message("Party recovered. Return preparation renewed." if recovered else "Party healthy. Return preparation renewed.", false)

func select_cell(cell: Vector2i) -> void:
	if session == null or modal_open() or playback.busy or completion_failed or not commander_ready():
		return
	if session.phase == "deployment":
		if not playback.submit("deploy", cell):
			world.message("Choose a highlighted release tile.", false)
	elif aimed_slot >= 0:
		if playback.submit("move_slot", cell, aimed_slot):
			aimed_slot = -1
		else:
			world.message("Choose a highlighted target that produces an effect.", false)
	else:
		if not playback.submit("move", cell):
			world.message("Hover open ground to preview a reachable route, or select a move first.", false)
	after_command()

func attack() -> void:
	if session != null:
		var moves: Array[Dictionary] = session.moves_for("ally")
		for slot in range(moves.size()):
			if moves[slot].effect == "damage" and not legal_targets(slot).is_empty():
				choose_move(slot)
				return

func wait_turn() -> void:
	if session != null and not playback.busy and not modal_open() and not completion_failed and commander_ready():
		aimed_slot = -1
		playback.submit("wait")
		after_command()

func retreat() -> void:
	if session != null and not playback.busy and not completion_failed:
		playback.submit("retreat")
		after_command()

func after_command() -> void:
	if session == null or playback.busy or completion_failed:
		return
	if session.phase == "exhaustion" and session.ally_hp == 0 and playback.timeline != null and not playback.timeline.blackout and not reserves_declined and not source_state.battle_replacements().is_empty():
		show_reserves()
		return
	if session.phase in ["victory", "exhaustion", "retreat", "captured"]:
		var outcome := session.phase
		var imprint := session.imprint()
		var counts := session.activity.duplicate()
		var history := session.last_activity.duplicate()
		var previous := source_state.active_sol_view()
		var previous_training: int = int(source_state.stat_view(previous.id).earned)
		var previous_moves: Dictionary = source_state.movebook(previous.id).learned
		var details := {"participated": session.participated, "contributed": session.contributed, "enemy_level": int(session.enemy.level), "move_definitions": library.definitions(), "vastra_overloads": session.vastra_overloads.duplicate(true), "vastra_overload_baseline": overload_baseline.duplicate(true)}
		if playback.timeline != null and playback.timeline.blackout: details["emergency_recall"] = true
		if outcome == "captured":
			details.capture = {"profile": session.enemy.duplicate(true), "hp": session.enemy_hp, "unlocks": library.levels_for(session.enemy.species_id, Array(progression.unlock_levels))}
		var protection: int = encounters.settings.withdrawal_safe_steps if encounters.settings.valid() else 3
		if completion_packet.is_empty():
			completion_packet = {"serial": serial, "hp": session.ally_hp, "outcome": outcome, "protection": protection, "imprint": imprint.duplicate(true), "details": details.duplicate(true)}
		if not source_state.complete_battle(int(completion_packet.serial), int(completion_packet.hp), str(completion_packet.outcome), int(completion_packet.protection), completion_packet.imprint, completion_packet.details):
			completion_failed = true
			completion_session = session
			world.message("Result could not be recorded. Use Retry result to continue.", false)
			update_view()
			return
		var return_blocked := false
		if outcome != "exhaustion" and not session.commander_route.is_empty():
			var route: Array[Vector2i] = [world.cell]
			route.append_array(session.commander_route)
			for index in range(route.size() - 1, 0, -1):
				if not world.can_step(route[index], route[index - 1]):
					return_blocked = true
					break
			if return_blocked:
				world.cell = session.trainer
				world.destination = world.cell
				world.moving = false
		close_battle_menu()
		retreat_dialog.hide()
		retreat_session = null
		playback.reset()
		completion_session = null
		completion_packet.clear()
		session = null
		overload_baseline.clear()
		serial = 0
		impacts.clear()
		sightings.battle_hidden_ids.erase(enemy_id)
		enemy_id = ""
		clear_visuals()
		battle_panel.hide()
		restore_exploration_hud()
		encounters.battle_running = false
		encounters.withdraw()
		encounters.safe_steps = 0 # The persistent battle receipt owns post-battle protection.
		if outcome == "exhaustion":
			world.cell = Vector2i.ZERO
		# Combat takes place in this expedition. Returning control must not discard
		# its terrain, scenery, caches or unfinished chunk preparation.
		world.destination = world.cell
		world.moving = false
		world.progress = 0.0
		world.explorer.position = world.center(world.cell)
		world.explorer.walking = false
		world.explorer.running = false
		world.camera.position = world.explorer.position
		world.host.camera_focus = Vector3.ZERO
		world.host.apply_camera()
		world.plan_chunks()
		world.update_hud()
		sightings.rebuild(true)
		refresh_companion()
		var result_cause: String = source_state.battle_progress().last_result.get("cause", "")
		feedback_view.show_result(outcome, source_state.active_sol_view(), imprint, counts, history, result_cause)
		if outcome == "victory":
			var current := source_state.active_sol_view()
			var growth := "\nXP +%d · total %d\nTraining +%d · unspent %d" % [int(current.xp) - int(previous.xp), int(current.xp), int(source_state.stat_view(current.id).earned) - previous_training, int(source_state.stat_view(current.id).earned) - SolStats.spent(source_state.stat_view(current.id))]
			if current.profile.level > previous.profile.level:
				growth += "\nLevel up: %d → %d" % [previous.profile.level, current.profile.level]
			for id in source_state.movebook(current.id).learned:
				if not previous_moves.has(id):
					growth += "\nLearned: " + str(source_state.movebook(current.id).learned[id].name)
			feedback_view.result_text.text += growth
		elif outcome == "captured":
			var captured := source_state.companion_view(source_state.battle_progress().last_result.enemy_id)
			feedback_view.result_text.text += "\nJoined: %s · Lv %d\n%s / %s" % [captured.profile.display_name, captured.profile.level, str(captured.profile.affinity).capitalize(), SolSpeciesCatalog.class_display_name(captured.profile.class_id)]
		var result_message: String = {"victory": "Victory. The wild Sol is exhausted. Save your expedition with F5.", "exhaustion": "Your companion is exhausted, not lost. Back at the refuge: right-click your trainer to recover.", "retreat": "Retreated safely. Your companion's remaining health is retained.", "captured": "Sol sealed. Choose your companion with C; F5 saves."}[outcome]
		if result_cause == "commander_blackout": result_message = "Commander blackout. Your companion was recalled with its remaining HP. Recover and renew your return preparation at camp."
		if return_blocked:
			result_message += " Return path blocked: remaining at the outside command position."
		world.message(result_message)
		return
	update_view()

func retry_completion() -> void:
	if completion_failed and session != null and session == completion_session and source_state == world.persistent_state and not completion_packet.is_empty() and serial == int(completion_packet.serial) and not playback.busy and not modal_open():
		completion_failed = false
		after_command()

func commander_ready() -> bool:
	if session == null or session.commander_route.is_empty():
		return true
	var model: Node3D = world.host.player_visual
	return model.sideline_session == session and model.sideline_route.is_empty() and model.presentation_cell.is_equal_approx(Vector2(session.trainer))

func frame_battle() -> void:
	if session == null:
		return
	var shown := display_battle()
	var ally := shown.trainer if shown.phase == "deployment" else shown.ally_cell
	var midpoint := (point(ally) + point(shown.enemy_cell)) * 0.5
	world.host.camera_focus = midpoint
	world.host.apply_camera()

func modal_open() -> bool:
	return risk_dialog.visible or (is_instance_valid(reserve_panel) and reserve_panel.visible) or retreat_dialog.visible or (battle_menu != null and battle_menu.visible) or (world.host.gamepad != null and world.host.gamepad.detail_window.visible)

func show_reserves() -> void:
	if is_instance_valid(reserve_panel): return
	reserve_panel = world.panel_at(Rect2(350, 170, 580, 450))
	var rows := VBoxContainer.new()
	reserve_panel.add_child(rows)
	rows.add_child(world.label("Emergency protection · choose a healthy reserve", 18))
	rows.add_child(world.label("Combat and exposure are paused during selection.", 14))
	var expected := session
	for identity in source_state.battle_replacements():
		var individual := source_state.companion_view(identity)
		button("%s · %d HP" % [individual.profile.display_name, individual.hp], func() -> void:
			if session != expected or session.ally_hp != 0: return
			var old_size: int = session.unit_footprints.ally
			var new_size: int = int(source_state.individual_view(identity).footprint)
			if new_size > maxi(old_size, int(session.unit_footprints.enemy)):
				world.message("This reserve needs a larger arena. Recall and prepare another approach.", false)
				return
			session.unit_footprints.ally = new_size
			if not session.can_occupy("ally", session.ally_cell) or not source_state.replace_exhausted_battle_ally(serial, identity):
				session.unit_footprints.ally = old_size
				return
			var selected := source_state.active_sol_view()
			session.ally = selected.profile.duplicate(true)
			session.ally_hp = selected.hp
			session.ally_moves.clear()
			var book := source_state.movebook(identity)
			for id in book.equipped: session.ally_moves.append(book.learned[id].duplicate(true))
			session.statuses.ally.clear()
			session.move_uses.ally.clear()
			session.phasing.ally = false
			session.passives.admit("ally", source_state.stat_view(identity))
			playback.identities.ally = identity
			playback.terminal_recorded = false
			playback.timeline.replace_ally()
			playback.view = playback.timeline.preview
			reserve_panel.queue_free()
			reserve_panel = null
			update_view(), rows).focus_mode = Control.FOCUS_NONE
	button("Recall and return", func() -> void:
		reserve_panel.queue_free()
		reserve_panel = null
		# Declining another deployment completes the exhausted-party outcome once.
		reserves_declined = true
		after_command(), rows).focus_mode = Control.FOCUS_NONE

func close_battle_menu() -> void:
	if battle_shield != null:
		battle_shield.hide()
	if battle_menu != null:
		battle_menu.hide()

func open_battle_menu() -> void:
	if session == null:
		return
	world.observation_menu.hide()
	battle_shield.show()
	battle_menu.show()
	combat_hud.fit_layout()

func cancel_retreat() -> void:
	retreat_dialog.hide()
	retreat_session = null
	if battle_shield != null:
		battle_shield.hide()

func request_retreat() -> void:
	if session == null or playback.busy or completion_failed or session.phase not in ["deployment", "active"]:
		return
	close_battle_menu()
	aimed_slot = -1
	retreat_dialog.dialog_text = "Leave this battle and retain your companion’s remaining health."
	if playback.timeline != null:
		retreat_dialog.dialog_text = "Replace the current draft with a withdrawal attempt and commit it now. This spends your readiness action. "
		retreat_dialog.dialog_text += "You are beyond the opponent’s move range." if playback.timeline.withdrawal_ready() else "You are still within the opponent’s move range: this attempt will fail. Reposition first to escape."
	retreat_session = session
	battle_shield.show()
	retreat_dialog.popup_centered()

func handle_input(event: InputEvent) -> void:
	if loadout.opened:
		return
	if choosing:
		if event is InputEventKey and event.pressed and event.physical_keycode in [KEY_1, KEY_2, KEY_3]:
			choose(int(event.physical_keycode) - int(KEY_1))
		return
	if session == null:
		return
	# Tactical commands are mouse actions. Escape only navigates presentation layers.
	world.battle_input_consumed = true
	if retreat_dialog.visible:
		if event.is_action_pressed("pause_expedition"):
			cancel_retreat()
		return
	if event.is_action_pressed("pause_expedition"):
		if battle_menu.visible:
			close_battle_menu()
		elif aimed_slot >= 0:
			cancel_targeting()
		else:
			open_battle_menu()
		return
	if battle_menu.visible:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and not event.double_click:
		var cell: Variant = world.host.pointer_cell(event.position)
		if cell != null:
			cursor = cell
			select_cell(cell)
	elif event is InputEventMouseMotion:
		var cell: Variant = world.host.pointer_cell(event.position)
		if cell != null and cell != cursor and session.bounds.has_point(cell):
			cursor = cell
			update_target_preview()

func clear_visuals() -> void:
	visual_layout.clear()
	clear_target_preview()
	cursor_marker = null
	for node in visuals.get_children():
		node.free()
	tile_pool.clear()
	preview_pool.clear()
	tile_meshes.clear()
	unit_views.clear()
	tile_used = 0
	preview_used = 0

func begin_visual_update() -> void:
	clear_target_preview()
	cursor_marker = null
	tile_used = 0
	for node in tile_pool:
		node.hide()
	for row in unit_views.values():
		row.sprite.hide()
		row.ring.hide()

func point(cell: Vector2i) -> Vector3:
	var relative: Vector2 = world.center(cell) - world.camera.position
	return Vector3(relative.x / 32.0, world.host.ground_height(Vector2(cell) + Vector2(0.5, 0.5)) + 0.13, relative.y / 32.0)

func new_tile_marker() -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	node.material_override = material
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return node

func tile_marker_mesh() -> TorusMesh:
	if not tile_meshes.has("marker"):
		var ring := TorusMesh.new()
		ring.inner_radius = 0.38 - sightings.visual_settings.board_ring_width
		ring.outer_radius = 0.38
		ring.rings = 24
		ring.ring_segments = 6
		tile_meshes["marker"] = ring
	return tile_meshes["marker"]

func prepare_board_rendering() -> void:
	# Retain representative hidden instances so first combat can reuse pipelines.
	# This owns no actors, tactical state or gameplay updates.
	if get_node_or_null("PreparedBoardRendering") != null: return
	var prepared := Node3D.new()
	prepared.name = "PreparedBoardRendering"
	prepared.hide()
	prepared.process_mode = Node.PROCESS_MODE_DISABLED
	add_child(prepared)
	var marker := new_tile_marker()
	marker.mesh = tile_marker_mesh()
	prepared.add_child(marker)
	BoardFx.apply(marker, BoardFx.ring_points(0.38 - sightings.visual_settings.board_ring_width * 0.5), Color.WHITE, sightings.visual_settings)
	var field := new_tile_marker()
	field.name = "PreparedFieldMarker"
	field.mesh = tile_marker_mesh()
	field.material_override = field_marker_material("earth", 0.0)
	prepared.add_child(field)
	var ring := MeshInstance3D.new()
	ring.name = "PreparedUnitRing"
	ring.mesh = unit_ring_mesh()
	ring.material_override = unit_ring_material(Color.WHITE)
	prepared.add_child(ring)
	# ImmediateMesh surfaces contain positions only, matching the live boundary
	# and grid vertex format rather than a primitive mesh's extra attributes.
	for boundary in [true, false]:
		var mesh := ImmediateMesh.new()
		mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES, board_line_material(boundary))
		for vertex in [Vector3.ZERO, Vector3.RIGHT, Vector3.FORWARD]: mesh.surface_add_vertex(vertex)
		mesh.surface_end()
		var line := MeshInstance3D.new()
		line.name = "PreparedBoundary" if boundary else "PreparedGrid"
		line.mesh = mesh
		if not boundary: line.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		prepared.add_child(line)

func field_marker_material(affinity: String, phase_value: float) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = preload("res://shaders/vastra_current.gdshader")
	material.set_shader_parameter("current_color", sightings.visual_settings.color_for(affinity))
	material.set_shader_parameter("opacity", 0.32)
	material.set_shader_parameter("phase", phase_value)
	return material

func unit_ring_mesh() -> TorusMesh:
	var mesh := TorusMesh.new()
	mesh.inner_radius = 0.44 - sightings.visual_settings.board_ring_width
	mesh.outer_radius = 0.44
	mesh.rings = 32
	mesh.ring_segments = 8
	return mesh

func unit_ring_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	return material

func board_line_material(boundary: bool) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	if boundary:
		material.albedo_color = Color(0.55, 0.85, 0.8, 0.5)
		material.emission_enabled = true
		material.emission = Color(0.25, 0.55, 0.45)
	else:
		material.albedo_color = Color(0.82, 0.9, 0.85, sightings.visual_settings.board_grid_opacity)
	return material

func tile(cell: Vector2i, color: Color, preview: bool = false) -> MeshInstance3D:
	var pool := preview_pool if preview else tile_pool
	var index := preview_used if preview else tile_used
	var node: MeshInstance3D
	if index < pool.size():
		node = pool[index]
	else:
		node = new_tile_marker()
		visuals.add_child(node)
		pool.append(node)
	if preview:
		preview_used += 1
	else:
		tile_used += 1
	if not node.material_override is StandardMaterial3D:
		var neutral := StandardMaterial3D.new()
		neutral.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		neutral.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		node.material_override = neutral
	var material: StandardMaterial3D = node.material_override
	material.albedo_color = color
	node.mesh = tile_marker_mesh()
	node.mesh.inner_radius = 0.38 - sightings.visual_settings.board_ring_width
	node.position = point(cell)
	node.scale = Vector3(1, 0.15, 1)
	BoardFx.apply(node, BoardFx.ring_points(0.38 - sightings.visual_settings.board_ring_width * 0.5), color, sightings.visual_settings)
	node.show()
	return node

func unit(cell: Vector2i, profile: Dictionary, side: String = "enemy") -> void:
	var shown := display_battle()
	var tuning: SolVisualSettings = sightings.visual_settings
	var entry: SolSpeciesRecord = settings.species_catalog.find(profile.species_id) if settings.species_catalog != null else null
	var signature := [profile.species_id, profile.affinity, tuning.diameter, tuning.hover_height, tuning.aura_opacity, tuning.effect_count, tuning.effect_speed, tuning.palette, entry.presentation_scene if entry != null else null, tuning.board_ring_width, tuning.board_ember_rise, tuning.board_ember_size, tuning.board_ember_opacity]
	if unit_views.has(side):
		var row: Dictionary = unit_views[side]
		if row.signature == signature:
			if row.sprite.has_method("sync_locomotion") and row.motion.target != cell:
				if playback.busy and playback.current.kind == "movement":
					row.motion.append(cell, playback.duration("movement"))
				else:
					row.motion.reset(cell)
					row.sprite.call("reset_locomotion")
			row.sprite.set_meta("world_cell", cell)
			row.sprite.ground_y = point(cell).y
			row.sprite.position = point(cell)
			row.sprite.phase = float(cell.x)
			row.sprite.animate(visual_seconds, sightings.settings.bob_pixels, sightings.settings.bob_cycles)
			row.ring.position = point(cell) + Vector3(0, 0.03, 0)
			sync_unit_motion(row, 0.0)
			row.sprite.show()
			row.ring.show()
			return
		row.sprite.free()
		row.ring.free()
		unit_views.erase(side)
	var sprite := SolSpeciesView.create(profile.species_id, profile.affinity, sightings.visual_settings, float(cell.x), settings.species_catalog)
	if sprite == null:
		return
	sprite.set_meta("world_cell", cell)
	sprite.ground_y = point(cell).y
	sprite.position = point(cell)
	sprite.animate(visual_seconds, sightings.settings.bob_pixels, sightings.settings.bob_cycles)
	visuals.add_child(sprite)
	var ring := MeshInstance3D.new()
	ring.mesh = unit_ring_mesh()
	var material := unit_ring_material(Color("91d9ba") if cell == shown.ally_cell and shown.phase != "deployment" else Color("ef9587"))
	ring.material_override = material
	ring.position = point(cell) + Vector3(0, 0.03, 0)
	ring.scale.y = 0.2
	BoardFx.apply(ring, BoardFx.ring_points(0.44 - tuning.board_ring_width * 0.5), material.albedo_color, tuning)
	visuals.add_child(ring)
	var motion := SolMotionTrack.new()
	motion.reset(cell)
	unit_views[side] = {"sprite": sprite, "ring": ring, "signature": signature.duplicate(true), "motion": motion}
	sync_unit_motion(unit_views[side], 0.0)

func sync_unit_motion(row: Dictionary, delta: float) -> void:
	if not row.sprite.has_method("sync_locomotion"):
		return
	var at: Vector2 = row.motion.advance(delta) + Vector2(0.5, 0.5)
	var relative: Vector2 = at - world.camera.position / 32.0
	var ground: float = world.host.ground_height(at)
	row.sprite.position = Vector3(relative.x, ground, relative.y)
	row.sprite.call("sync_locomotion", at, delta, world.host.ground_height)
	row.sprite.animate(visual_seconds, sightings.settings.bob_pixels, sightings.settings.bob_cycles)
	row.ring.position = Vector3(relative.x, ground + 0.16, relative.y)

func update_view() -> void:
	if session == null:
		return
	var shown := display_battle()
	companion_label.hide()
	combat_hud.refresh()
	var available: Variant = [] if playback.busy else (shown.deployment_tiles() if shown.phase == "deployment" else shown.reachable().keys())
	if aimed_slot >= 0 and not playback.busy:
		available = []
		for target: Vector2i in shown.cells:
			if shown.can_use(aimed_slot, target):
				available.append(target)
	var tuning: SolVisualSettings = sightings.visual_settings
	var show_cursor := not playback.busy and (session.phase == "deployment" or aimed_slot >= 0)
	var route: Array = playback.current.route if playback.busy else []
	var layout := {"fields": shown.fields, "cells": session.cells, "available": available,
		"species": [shown.ally.species_id, shown.enemy.species_id],
		"ally_cell": shown.ally_cell, "enemy_cell": shown.enemy_cell, "deployed": shown.phase != "deployment",
		"affinities": [shown.ally.affinity, shown.enemy.affinity], "cursor": cursor if show_cursor else Vector2i.ZERO,
		"show_cursor": show_cursor, "route": route, "camera_origin": world.camera.position,
		"orb_tuning": [tuning.diameter, tuning.hover_height, tuning.aura_opacity, tuning.effect_count, tuning.effect_speed, tuning.palette],
		"board_tuning": [tuning.board_ring_width, tuning.board_boundary_width, tuning.board_ember_rise, tuning.board_ember_size, tuning.board_ember_opacity, tuning.board_grid_width, tuning.board_grid_opacity]}
	if visual_layout == layout and visuals.get_child_count() > 0:
		update_target_preview()
		return
	begin_visual_update()
	update_storm_outline()
	visual_layout = layout.duplicate(true)
	for cell: Vector2i in session.cells:
		if shown.fields.has(cell):
			var field_affinity: String = {"heat": "fire", "wet": "water", "rough": "earth", "barrier": "earth", "wind": "air", "charge": "lightning", "warp": "void", "phase": "spectral", "entangled": "quantum"}[shown.fields[cell].kind]
			var marker := tile(cell, Color.WHITE)
			marker.material_override = field_marker_material(field_affinity, float(cell.x + cell.y))
			marker.scale = Vector3(1, 2, 1)
			BoardFx.apply(marker, BoardFx.ring_points(0.38 - tuning.board_ring_width * 0.5), tuning.color_for(field_affinity), tuning)
		elif available.has(cell) and show_cursor:
			tile(cell, Color(0.85, 0.9, 0.88, 0.4))
	if not playback.busy and (session.phase == "deployment" or aimed_slot >= 0):
		cursor_marker = tile(cursor, Color(0.9, 0.8, 0.3, 0.65))
		cursor_marker.position.y += 0.02
	var planning: bool = playback.timeline != null and playback.timeline.planning
	unit(session.enemy_cell if planning else shown.enemy_cell, shown.enemy, "enemy")
	if shown.phase != "deployment":
		unit(session.ally_cell if planning else shown.ally_cell, shown.ally, "ally")
	if planning and shown.ally_cell != session.ally_cell:
		tile(shown.ally_cell, Color(1.0, 0.8, 0.3, 0.3))
	if playback.busy and not playback.current.route.is_empty():
		for at: Vector2i in playback.current.route:
			tile(at, Color(1.0, 0.85, 0.4, 0.35))
	update_target_preview()

func display_battle() -> TacticalBattle:
	return playback.view if playback.view != null else session

func update_storm_outline() -> void:
	if is_instance_valid(storm_outline): storm_outline.free()
	if playback.readiness_settings == null or not playback.readiness_settings.enabled or session.phase not in ["deployment", "active"]: return
	var mesh := ImmediateMesh.new()
	var material := board_line_material(true)
	var tuning: SolVisualSettings = sightings.visual_settings
	var ember_points := PackedVector3Array()
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES, material)
	for cell: Vector2i in session.cells:
		for direction in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			if session.cells.has(cell + direction): continue
			var center := point(cell) + Vector3(direction.x, 0, direction.y) * 0.5
			var tangent := Vector3(-direction.y, 0, direction.x) * 0.5
			var across := Vector3(direction.x, 0, direction.y) * tuning.board_boundary_width * 0.5
			# Sample the edge height, keeping the mask and emission on terrain.
			for segment in range(4):
				var ends: Array[Vector3] = []
				for fraction: float in [float(segment) / 4.0, float(segment + 1) / 4.0]:
					var at := center - tangent + tangent * 2.0 * fraction
					var map_at: Vector2 = Vector2(at.x, at.z) + world.camera.position / 32.0
					at.y = world.host.ground_height(map_at) + 0.08
					ends.append(at)
				for vertex in [ends[0] - across, ends[0] + across, ends[1] + across, ends[0] - across, ends[1] + across, ends[1] - across]:
					mesh.surface_add_vertex(vertex)
				ember_points.append((ends[0] + ends[1]) * 0.5)
	mesh.surface_end()
	storm_outline = MeshInstance3D.new()
	storm_outline.name = "BattleStormBoundary"
	storm_outline.mesh = mesh
	visuals.add_child(storm_outline)
	BoardFx.apply(storm_outline, ember_points, material.albedo_color, tuning)
	update_board_grid()

func board_surface_point(at: Vector3, lift: float = 0.045) -> Vector3:
	var map_at: Vector2 = Vector2(at.x, at.z) + world.camera.position / 32.0
	return Vector3(at.x, world.host.ground_height(map_at) + lift, at.z)

func update_board_grid() -> void:
	var mesh := ImmediateMesh.new()
	var material := board_line_material(false)
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES, material)
	# Each shared edge is drawn once. The separate boundary owns the outer edges.
	for cell: Vector2i in session.cells:
		for direction: Vector2i in [Vector2i.RIGHT, Vector2i.DOWN]:
			if not session.cells.has(cell + direction): continue
			var center := point(cell) + Vector3(direction.x, 0, direction.y) * 0.5
			var tangent := Vector3(-direction.y, 0, direction.x) * 0.5
			var across: Vector3 = Vector3(direction.x, 0, direction.y) * sightings.visual_settings.board_grid_width * 0.5
			for segment in range(4):
				var first := center - tangent + tangent * (float(segment) / 2.0)
				var last := center - tangent + tangent * (float(segment + 1) / 2.0)
				for vertex: Vector3 in [first - across, first + across, last + across, first - across, last + across, last - across]:
					mesh.surface_add_vertex(board_surface_point(vertex))
	mesh.surface_end()
	var grid := MeshInstance3D.new()
	grid.name = "BattleGroundGrid"
	grid.mesh = mesh
	grid.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	storm_outline.add_child(grid)

func activity_reservations() -> Dictionary:
	# Reserve committed and displayed combatant cells while wildlife keeps moving.
	var occupied: Dictionary = {}
	if session == null:
		return occupied
	for battle: TacticalBattle in [session, display_battle()]:
		occupied[battle.trainer] = true
		occupied[battle.enemy_cell] = true
		if battle.phase != "deployment":
			occupied[battle.ally_cell] = true
	for at: Vector2i in session.commander_route:
		occupied[at] = true
	return occupied

func show_resolution(step: Dictionary) -> void:
	update_view()
	if step.kind == "effect" and not step.cue.is_empty() and unit_views.has(step.actor):
		var actor_view: Node3D = unit_views[step.actor].sprite
		if actor_view.has_method("play_action"):
			actor_view.call("play_action", "attack", visual_seconds)
	if not step.cue.is_empty():
		receive_feedback(step.cue)

func advance_resolution(delta: float, advance_commander: bool = true) -> void:
	if session != null and not world.paused and not modal_open() and not world.observation_menu.visible:
		for row in unit_views.values():
			sync_unit_motion(row, delta)
		if advance_commander:
			world.host.player_visual.update_sideline(delta)
		var ready := commander_ready()
		if ready != commander_was_ready:
			commander_was_ready = ready
			update_view()
		playback.advance(delta)

func _exit_tree() -> void:
	playback.reset()

func _process(delta: float) -> void:
	if session == null or world.smoke_mode:
		return
	advance_resolution(delta, false)
	if session == null:
		return
	visual_seconds += delta
	for marker in tile_pool:
		if marker.visible and marker.material_override is ShaderMaterial:
			marker.material_override.set_shader_parameter("clock_seconds", visual_seconds)
	for at in impacts.keys():
		impacts[at].age += delta
		if impacts[at].age >= sightings.visual_settings.impact_seconds:
			impacts.erase(at)
	for node in visuals.get_children():
		if node is SolOrb:
			if node.has_method("apply_impact"):
				node.call("apply_impact", Color.WHITE, 0.0)
			node.orb_material.albedo_color = node.tint
			node.animate(visual_seconds, sightings.settings.bob_pixels, sightings.settings.bob_cycles)
			node.scale = Vector3.ONE
			var hit: Dictionary = impacts.get(node.get_meta("world_cell"), {})
			if not hit.is_empty() and sightings.visual_settings.impact_seconds > 0:
				var fraction: float = float(hit.age) / sightings.visual_settings.impact_seconds
				var pulse := sin(fraction * PI)
				node.orb_material.albedo_color = node.orb_material.albedo_color.lerp(Color.WHITE if hit.kind == "damage" else Color("b6ffe0"), (1.0 - fraction) * 0.7)
				node.scale = Vector3(1.0 + pulse * 0.12, 1.0 - pulse * 0.12, 1.0 + pulse * 0.12)
				if node.has_method("apply_impact"):
					node.call("apply_impact", Color.WHITE if hit.kind == "damage" else Color("b6ffe0"), (1.0 - fraction) * 0.7)

func ensure_movebooks(identities: Variant = null) -> void:
	if source_state == null or library == null:
		return
	var pending: Array = source_state.individual_ids() if identities == null else identities
	var books_checked := false
	var books_valid := false
	for identity in pending:
		if not source_state.has_movebook(identity):
			var record := source_state.individual_view(identity)
			if not books_checked:
				books_valid = movebook_validation.check(library, [preload("res://resources/sol_ecology/behavior_library.tres")])
				books_checked = true
				if movebook_template_revision != movebook_validation.validation_runs:
					movebook_templates.clear()
					movebook_template_revision = movebook_validation.validation_runs
			var book: Dictionary = {}
			if books_valid:
				if not movebook_templates.has(record.species_id):
					book = library.book(record.species_id, movebook_validation)
					if not book.is_empty(): movebook_templates[record.species_id] = book
				book = movebook_templates.get(record.species_id,{})
			if not book.is_empty():
				source_state.admit_movebook(identity, book)
		var record := source_state.individual_view(identity)
		var authored := settings.opponent(record.species_id, record.affinity)
		var forms := settings.evolution_forms_for(record.species_id)
		if not authored.is_empty():
			authored.affinity = record.affinity
			source_state.admit_stat_profile(identity, authored, forms)
		source_state.configure_learning(identity, library.levels_for(record.species_id, Array(progression.unlock_levels)))

func choose_move(slot: int) -> void:
	if session == null or playback.busy or completion_failed or not commander_ready() or modal_open() or session.phase != "active" or slot < 0 or slot >= session.moves_for("ally").size():
		return
	var targets := legal_targets(slot)
	if targets.is_empty():
		world.message(no_target_reason(session.moves_for("ally")[slot]), false)
		return
	aimed_slot = slot
	var move: Dictionary = session.moves_for("ally")[slot]
	cursor = session.ally_cell if move.effect in ["heal", "buff", "protect", "phase", "anchor"] else session.enemy_cell
	if not targets.has(cursor):
		cursor = targets[0]
	after_command()

func move_description(move: Dictionary) -> String:
	var descriptions := {
		"damage": str(move.get("category", "physical")).capitalize() + " damage. Damage the opponent. Terrain and range must permit the hit.",
		"heal": "Restore your own HP and environmental Vastra where restoration remains possible.",
		"phase": "Cross a thin obstacle on your next movement; land on open ground.",
		"anchor": "Hold your footing against wind displacement.",
		"quantum": "Choose position, field stabilization, or linked terrain using the Quantum selector.",
		"buff": "Raise your " + str(move.get("stat", "attack")).replace("_", " ") + ".",
		"debuff": "Reduce the opponent stat; Construct resists the magnitude.",
		"poison": "Inflict damage at the end of the recipient turn.",
		"protect": "Reduce direct damage for a limited number of turns.",
		"field": "Shape shared terrain. Both sides are affected.",
		"passive": "Automatic while equipped; occupies one of your four move slots."}
	var supply := "Fallback action · no use limit" if move.id == "last_effort" else "%d uses per battle" % SolMove.uses(move)
	if session != null and move.id != "last_effort":
		supply = "%d/%d uses remaining this battle" % [session.uses_left("ally", move), SolMove.uses(move)]
	var detail: String = move.get("description", "")
	if detail.is_empty():
		detail = descriptions[move.effect]
	var extra := ""
	if move.get("secondary_effect", "none") != "none":
		extra = "\nSecondary: " + SolMove.secondary_summary(move)
	elif move.effect in ["field", "anchor"]:
		extra = "\nLifetime: %d tactical rounds" % int(move.duration)
	elif move.effect in ["buff", "debuff", "poison", "protect"]:
		extra = "\nLifetime: %d recipient turns" % int(move.duration)
	var potency := " · %d%% damage" % int(move.get("damage_percent", 100)) if move.effect == "damage" else ""
	var ending := "Add moves and movement, then Commit plan. Aim stays fixed during execution." if playback.timeline != null else "Moves keep your turn open. Choose End turn when finished."
	return "%s · %s · %d AP\n%s\n%s\nRange: %d cells · Power: %d%s%s\n%s" % [move.name, str(move.affinity).capitalize(), SolMove.cost(move), supply, detail, int(move.reach), int(move.power), potency, extra, ending]

func capture_enemy() -> void:
	if session == null or playback.busy or completion_failed or not commander_ready() or modal_open() or session.capture_chance() <= 0:
		return
	aimed_slot = -1
	var random := RandomNumberGenerator.new()
	random.seed = session.capture_seed + session.capture_attempts * 104729
	playback.submit("capture", Vector2i.ZERO, -1, random.randf())
	after_command()


func legal_targets(slot: int) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	if session == null or playback.busy or session.phase != "active" or session.turn != "ally":
		return result
	var projected: TacticalBattle = playback.timeline.preview if playback.timeline != null and playback.timeline.planning else session
	for cell: Vector2i in projected.cells:
		if projected.can_use(slot, cell):
			result.append(cell)
	result.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.y < b.y if a.y != b.y else a.x < b.x)
	return result

func receive_feedback(event: Dictionary) -> void:
	feedback_view.receive(event)
	if event.kind == "damage":
		for row in unit_views.values():
			if row.sprite.get_meta("world_cell") == event.cell and row.sprite.has_method("play_action"):
				row.sprite.call("play_action", "hit", visual_seconds)
	if event.kind in ["damage", "heal"] and sightings.visual_settings.feedback_enabled and sightings.visual_settings.impact_seconds > 0:
		impacts[event.cell] = {"kind": event.kind, "age": 0.0}

func no_target_reason(move: Dictionary) -> String:
	if session == null or session.phase != "active":
		return "Release your companion before choosing a move."
	if move.effect == "passive":
		return "Equipped passive · triggers automatically when its condition is met."
	var projected := display_battle()
	if projected.uses_left("ally", move) <= 0:
		return "No uses left this battle. Choose another move; uses refresh at battle entry."
	if SolMove.cost(move) > projected.actions_remaining:
		return "Needs %d AP; %d remaining." % [SolMove.cost(move), projected.actions_remaining]
	if move.effect == "heal" and projected.ally_hp >= int(projected.ally.max_hp):
		return "Your companion is already at full HP."
	if move.effect == "damage":
		return "No clear target in range. Hover open ground to preview a route, then click to reposition."
	return "No legal target would benefit from this move right now."

func cancel_targeting() -> void:
	if session == null:
		return
	aimed_slot = -1
	update_view()

func clear_target_preview() -> void:
	for node in preview_nodes:
		if is_instance_valid(node):
			node.hide()
	preview_nodes.clear()
	preview_used = 0

func preview_tile(at: Vector2i, tint: Color, small: bool = false) -> void:
	var marker := tile(at, tint, true)
	marker.position.y += 0.035
	if small:
		marker.scale = Vector3(0.3, 1, 0.3)
	preview_nodes.append(marker)

func update_target_preview() -> void:
	clear_target_preview()
	if session == null:
		return
	if playback.busy:
		combat_hud.refresh_target()
		return
	if is_instance_valid(cursor_marker):
		cursor_marker.position = point(cursor) + Vector3(0, 0.06, 0)
	combat_hud.refresh_target()
	if not sightings.visual_settings.target_previews:
		return
	var projected := display_battle()
	var opacity: float = sightings.visual_settings.preview_opacity
	if projected.phase == "active" and aimed_slot < 0:
		var options := projected.reachable()
		if options.has(cursor):
			for at: Vector2i in options[cursor]:
				preview_tile(at, Color(1.0, 0.85, 0.4, opacity), true)
	elif aimed_slot >= 0 and projected.can_use(aimed_slot, cursor):
		var move: Dictionary = projected.moves_for("ally")[aimed_slot]
		var area: Array[Vector2i] = [cursor]
		if move.effect == "field":
			area = [projected.ally_cell, cursor] if move.affinity == "quantum" else projected.field_area(cursor)
			if projected.links.has(cursor) and not area.has(projected.links[cursor]):
				area.append(projected.links[cursor])
		elif move.effect == "quantum" and projected.quantum_mode == "entangle":
			area = [projected.ally_cell, cursor]
		var color: Color = sightings.visual_settings.color_for(move.affinity)
		color.a = opacity
		for at in area:
			preview_tile(at, color)

func hide_exploration_hud() -> void:
	hidden_exploration.clear()
	for node in world.hud.get_children():
		if node is Control and node != battle_panel and node != selection_panel and node != world.confirmation and node.visible:
			hidden_exploration.append(node)
			node.hide()

func restore_exploration_hud() -> void:
	for node in hidden_exploration:
		if is_instance_valid(node):
			node.show()
	hidden_exploration.clear()
