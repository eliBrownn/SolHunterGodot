extends "res://tests/combat_sequencing.gd"

class RejectingState extends ExpeditionState:
	var reject := true
	var attempts := 0
	func complete_battle(token: int, hp: int, outcome: String, protection: int, imprint: Dictionary = {}, details: Dictionary = {}) -> bool:
		attempts += 1
		return false if reject else super.complete_battle(token, hp, outcome, protection, imprint, details)

func move(effect: String, affinity: String = "earth", power: int = 2, duration: int = 2) -> Dictionary:
	return {"id": effect, "name": effect.capitalize(), "effect": effect, "affinity": affinity, "power": power, "reach": 4, "duration": duration}

func scenario(moves: Array[Dictionary], hero_class: String = "", potency: int = 0) -> Dictionary:
	var battle := fixture()
	battle.enemy_moves[0].reach = 0
	if not hero_class.is_empty():
		battle.set_class_passives({"class_id": hero_class, "potency": potency}, {}, preload("res://resources/class_buff_settings.tres"))
	battle.ally_moves.assign(moves)
	var playback := BattlePlayback.new()
	playback.bind(battle, SolVisualSettings.new(), 99, {"ally": "owned", "enemy": "wild"})
	playback.submit("deploy", Vector2i(1, 0))
	drain(playback)
	var trace: Array[Dictionary] = []
	playback.changed.connect(func(step: Dictionary) -> void: trace.append(step))
	return {"battle": battle, "playback": playback, "trace": trace}

func caused(trace: Array, cause: String) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	for step in trace:
		if step.cause == cause:
			found.append(step)
	return found

func automatic_checks() -> void:
	var s := scenario([move("poison")])
	s.playback.submit("move_slot", s.battle.enemy_cell, 0)
	drain(s.playback)
	s.playback.submit("wait")
	drain(s.playback)
	var ticks := caused(s.trace, "poison")
	check(ticks.size() == 1 and ticks[0].cue.amount == 2 and ticks[0].actor_id.is_empty() and ticks[0].caption.contains("Poison"), "Poison has a named automatic cause without claiming the current actor cast it")
	check(s.battle.enemy_hp == 38 and s.battle.statuses.enemy.poison.turns == 1 and s.battle.activity.earth == 1, "Poison damage/duration retain their rules and ticks add no activity")
	s.trace.clear()
	s.playback.submit("wait")
	drain(s.playback)
	var expiries := caused(s.trace, "status_duration")
	check(not s.battle.statuses.enemy.has("poison") and expiries.back().caption.to_lower().contains("expired") and not expiries.back().snapshot.statuses.enemy.has("poison"), "Expiry is named and displayed with the condition actually removed")
	s.playback.reset()
	s = scenario([move("protect", "earth", 50, 1)])
	s.battle.enemy_moves[0].reach = 2
	s.playback.submit("move_slot", s.battle.ally_cell, 0)
	drain(s.playback)
	s.playback.submit("wait")
	drain(s.playback)
	check(s.battle.ally_hp == 34 and not caused(s.trace, "damage_modifiers").is_empty(), "Protection names its contribution while retaining the original reduced damage")
	s.playback.submit("wait")
	drain(s.playback)
	check(s.battle.ally_hp == 30 and not s.battle.statuses.ally.has("protect"), "Recipient-turn protection expires at the original rule boundary")
	s.playback.reset()
	s = scenario([move("heal")], "verdant", 3)
	s.playback.submit("wait")
	drain(s.playback)
	var roots := caused(s.trace, "class_passive")
	check(s.battle.ally_hp == 37 and roots.size() == 1 and roots[0].caption.contains("Rooted Renewal") and roots[0].actor_id == "owned", "Passive recovery is a named separate HP change attributed to its actual owner")
	s.playback.reset()
	s = scenario([move("damage", "fire", 3)], "cinderkin", 5)
	s.playback.submit("move_slot", s.battle.enemy_cell, 0)
	drain(s.playback)
	check(caused(s.trace, "damage_modifiers")[0].caption.contains("Kindling"), "A class damage modifier is explained by the same calculation used to execute the hit")
	s.playback.submit("wait")
	drain(s.playback)
	s.trace.clear()
	s.playback.submit("wait")
	drain(s.playback)
	check(caused(s.trace, "class_passive")[0].caption.contains("Kindling reset"), "A non-attacking turn visibly resets Kindling")
	s.playback.reset()
	s = scenario([move("heal")], "stonebound", 5)
	s.playback.submit("wait")
	drain(s.playback)
	check(caused(s.trace, "class_passive")[0].caption.contains("defense ready"), "Stationary defense has a visible activation")
	s.trace.clear()
	s.playback.submit("move", Vector2i(1, 1))
	drain(s.playback)
	check(not s.battle.passives.units.ally.stone and caused(s.trace, "class_passive")[0].caption.contains("ends after movement"), "Movement visibly ends stationary defense without changing path cost")
	s.playback.reset()
	s = scenario([move("heal")])
	s.battle.fields[s.battle.ally_cell] = {"kind": "heat", "direction": Vector2i.RIGHT, "round": 0, "expires": 4}
	s.battle.fields[s.battle.enemy_cell] = {"kind": "charge", "direction": Vector2i.RIGHT, "round": 0, "expires": 4}
	for at in [Vector2i(2, -1), Vector2i(2, 1), Vector2i(3, 0)]:
		s.battle.cells[at] = false # Isolate discharge rather than testing the planner's hazard avoidance.
	s.playback.submit("wait")
	drain(s.playback)
	check(caused(s.trace, "heat").size() == 1 and caused(s.trace, "lightning").size() == 1 and caused(s.trace, "discharge").size() == 1, "Heat and warned discharge have distinct named consequences")
	check(not caused(s.trace, "heat_spread").is_empty() and s.battle.activity.is_empty(), "Grouped heat spread displays terrain changes without successful-move activity")
	s.playback.reset()
	s = scenario([move("heal")])
	for at in s.battle.cells:
		s.battle.fields[at] = {"kind": "rough", "direction": Vector2i.RIGHT, "round": 0, "expires": 2}
	s.playback.tuning.consequence_seconds = 0
	s.playback.tuning.action_cue_seconds = 0
	s.playback.tuning.turn_handoff_seconds = 0
	s.playback.submit("wait")
	drain(s.playback)
	check(caused(s.trace, "field_expiry").size() == 1 and caused(s.trace, "field_expiry")[0].affected_cells.size() == s.battle.cells.size() and s.battle.fields.is_empty(), "A full arena of expiring fields produces one bounded grouped consequence")
	check(not s.playback.busy and s.playback.pending.is_empty(), "Zero holds and large advancement complete without dropping state or leaving a command gate")
	s.playback.reset()

func move_checks() -> void:
	var s := scenario([move("field", "air")])
	s.playback.submit("move_slot", s.battle.enemy_cell, 0)
	drain(s.playback)
	var pushes := caused(s.trace, "wind_displacement")
	check(pushes.size() == 1 and pushes[0].snapshot.enemy_cell == Vector2i(3, 0) and pushes[0].affected_cells == [Vector2i(2, 0), Vector2i(3, 0)], "Wind's displacement displays its actual source and legal landing after terrain placement")
	check(s.battle.activity.air == 1 and caused(s.trace, "field_placement").size() == 1, "Field creation and displacement still count as one successful move")
	s.playback.reset()
	for affinity in ["air", "earth"]:
		s = scenario([move("field", affinity)])
		var target := Vector2i(2, 0) if affinity == "air" else Vector2i(1, 1)
		var direction := Vector2i.RIGHT if affinity == "air" else Vector2i.DOWN
		for at in s.battle.field_area(target):
			s.battle.fields[at] = {"kind": "wind" if affinity == "air" else "rough", "direction": direction, "round": 1, "expires": 3}
		var accepted: bool = s.playback.submit("move_slot", target, 0)
		drain(s.playback)
		check(accepted and s.battle.activity.get(affinity, 0) == 1, "A displacement or newly raised barrier cannot mutate combat while reporting a rejected field command")
		s.playback.reset()
	s = scenario([move("field", "water")])
	for at in s.battle.field_area(Vector2i(1, 1)):
		s.battle.fields[at] = {"kind": "wet", "direction": Vector2i.DOWN, "round": 1, "expires": 3}
	var unchanged: Dictionary = s.battle.view_snapshot()
	check(not s.playback.submit("move_slot", Vector2i(1, 1), 0) and unchanged == s.battle.view_snapshot() and not s.playback.busy, "A genuinely unchanged field rejects without changing HP, movement, status, activity or initiative")
	s.playback.reset()
	s = scenario([move("anchor", "earth", 0, 1)])
	s.playback.submit("move_slot", s.battle.ally_cell, 0)
	drain(s.playback)
	check(s.battle.status_summary("ally").contains("Stable Footing") and caused(s.trace, "anchor").size() == 1, "Footing readiness is shown from the presented domain flags")
	s.playback.submit("wait")
	drain(s.playback)
	s.playback.submit("wait")
	drain(s.playback)
	check(caused(s.trace, "anchor_expiry").size() == 1 and not s.battle.status_summary("ally").contains("Stable Footing"), "Footing expiry is named at its existing round boundary")
	s.playback.reset()
	s = scenario([move("phase", "spectral")])
	s.battle.enemy_cell = Vector2i(4, 0)
	s.playback.submit("move_slot", s.battle.ally_cell, 0)
	drain(s.playback)
	s.battle.cells[Vector2i(2, 0)] = false
	s.battle.protected_cells[Vector2i(2, 0)] = false
	s.playback.submit("move", Vector2i(3, 0))
	drain(s.playback)
	check(s.battle.ally_cell == Vector2i(3, 0) and not s.battle.phasing.ally and caused(s.trace, "phase").size() == 1, "Phasing readiness and its legal open landing retain their existing consumption rule")
	s.playback.reset()
	for mode in ["position", "stabilize", "entangle"]:
		s = scenario([move("quantum", "quantum")])
		s.battle.quantum_mode = mode
		var target := Vector2i(1, 1)
		if mode == "stabilize":
			s.battle.fields[target] = {"kind": "rough", "direction": Vector2i.RIGHT, "round": 0, "expires": 9}
		s.playback.submit("move_slot", target, 0)
		drain(s.playback)
		var correct: bool = s.battle.ally_cell == target if mode == "position" else (not s.battle.fields.has(target) if mode == "stabilize" else s.battle.links.has(target))
		check(correct and s.battle.activity.quantum == 1 and not caused(s.trace, "quantum_" + mode if mode != "entangle" else "field_placement").is_empty(), "Each explicit Quantum choice shows its own actual consequence and one activity event")
		s.playback.reset()

func capture_checks() -> void:
	var s := scenario([move("damage")])
	s.playback.submit("capture", Vector2i.ZERO, -1, 0.999)
	drain(s.playback)
	check(s.battle.capture_attempts == 1 and s.battle.phase == "active" and caused(s.trace, "capture_failed").size() == 1, "A failed Seal reports failure and spends exactly one attempt before enemy activation")
	var failure_index := -1
	var enemy_index := -1
	for index in range(s.trace.size()):
		if s.trace[index].cause == "capture_failed": failure_index = index
		if s.trace[index].kind == "action" and s.trace[index].side == "enemy": enemy_index = index
	check(failure_index >= 0 and enemy_index > failure_index, "The failed-Seal consequence is presented before the opponent response")
	s.trace.clear()
	s.playback.submit("capture", Vector2i.ZERO, -1, 0.0)
	drain(s.playback)
	check(s.battle.phase == "captured" and caused(s.trace, "captured").size() == 1 and caused(s.trace, "captured")[0].caption.contains("sealed"), "Successful capture has an explicit terminal step without a new damage/activity rule")
	s.playback.reset()
	s = scenario([move("damage", "fire", 100)])
	s.battle.enemy_hp = 1
	s.playback.submit("move_slot", s.battle.enemy_cell, 0)
	drain(s.playback)
	check(s.battle.phase == "victory" and caused(s.trace, "victory").size() == 1, "A final hit is followed by an explicit exhausted-opponent outcome")
	s.playback.reset()
	s = scenario([move("heal")])
	s.battle.ally_hp = 1
	s.battle.statuses.ally.poison = {"magnitude": 3, "turns": 1}
	s.playback.submit("wait")
	drain(s.playback)
	check(s.battle.phase == "exhaustion" and caused(s.trace, "poison")[0].cue.amount == 1 and caused(s.trace, "exhaustion").size() == 1, "Lethal poison shows actual capped damage before exhaustion, without an enemy action")
	s.playback.reset()

func commander_checks() -> void:
	var battle := fixture()
	var before := battle.view_snapshot()
	var route := BattleCommander.plan(battle, Vector2i.ZERO, func(_a: Vector2i, _b: Vector2i) -> bool: return true)
	check(route.back() == Vector2i(-5, 0) and before == battle.view_snapshot(), "Commander planning chooses the farthest side and shortest exit there without mutating combat")
	var previous := Vector2i.ZERO
	var legal := true
	for at in route:
		legal = legal and TacticalBattle.distance(previous, at) == 1 and at != battle.enemy_cell
		previous = at
	check(legal and not battle.bounds.has_point(route.back()) and battle.enemy_cell == Vector2i(2, 0), "Commander follows cardinal legal steps outside the arena without moving the enemy")
	battle.trainer = route.back()
	check(battle.paths(battle.enemy_cell, battle.cells.size(), Vector2i(999, 999)).has(Vector2i.ZERO), "The original trainer tile becomes available to tactical traversal")
	var release_ok := true
	var beyond_old_origin := false
	for at in battle.deployment_tiles():
		release_ok = release_ok and TacticalBattle.distance(at, battle.trainer) <= battle.release_range
		beyond_old_origin = beyond_old_origin or TacticalBattle.distance(at, Vector2i.ZERO) > battle.release_range
	check(release_ok and beyond_old_origin, "Release tiles use the new physical command position, not the old encounter origin")
	check(BattleCommander.plan(battle, Vector2i.ZERO, func(_a: Vector2i, b: Vector2i) -> bool: return absi(b.x) <= 3 and absi(b.y) <= 3).is_empty(), "An enclosed arena has no fabricated command route")
	var fallback := BattleCommander.plan(battle, Vector2i.ZERO, func(_a: Vector2i, b: Vector2i) -> bool: return b.x > -5)
	check(not fallback.is_empty() and fallback.back().x > -5, "A blocked farthest side falls back to a reachable side with legal release space")

func live_checks() -> void:
	var scene: Node3D = load("res://scenes/world_3d.tscn").instantiate()
	scene.sighting_settings = scene.sighting_settings.duplicate(true)
	scene.sighting_settings.wilderness_enabled = false
	scene.sighting_settings.movement_enabled = false
	root.add_child(scene)
	var world: Node2D = scene.world
	world.smoke_mode = true
	world.new_expedition(17)
	var state := RejectingState.new(17)
	world.replace_persistent_state(state)
	world.state_replaced.emit(state)
	world.rebuild_world()
	state.choose_starter(scene.battle_settings.starters[0].snapshot(), 0)
	var save_path := "user://combat-consequences-%d.json" % Time.get_ticks_usec()
	world.save_game(save_path)
	var original_bytes := FileAccess.get_file_as_string(save_path)
	var member: Dictionary = scene.sightings.members[0]
	world.cell = member.home + Vector2i.LEFT
	world.destination = world.cell
	world.rebuild_world()
	var origin: Vector2i = world.cell
	scene.encounters.approach_individual(member.id)
	scene.encounters.battle_button.pressed.emit()
	var controller: Node = scene.battles
	var battle: TacticalBattle = controller.session
	check(battle != null and not battle.bounds.has_point(battle.trainer) and not controller.commander_ready(), "Live battle stages an outside command position and waits for the trainer run")
	await capture_phase2("trainer-running", scene)
	controller.select_cell(battle.deployment_tiles()[0])
	check(battle.phase == "deployment", "Deployment cannot start from an unarrived throw origin")
	controller.open_battle_menu()
	var position: Vector2 = scene.player_visual.presentation_cell
	controller.advance_resolution(10.0)
	check(scene.player_visual.presentation_cell == position, "Battle menu also pauses the trainer route")
	controller.close_battle_menu()
	BattleTest.settle(controller)
	check(scene.player_visual.presentation_cell == Vector2(battle.trainer) and not world.observation_name(origin).contains("Trainer"), "The arrived model matches the authoritative throw origin and the old tile is no longer a trainer target")
	await capture_phase2("outside-command", scene)
	controller.select_cell(battle.deployment_tiles()[0])
	BattleTest.settle(controller)
	battle.statuses.ally.poison = {"magnitude": 2, "turns": 1}
	controller.wait_turn()
	for step in range(100):
		if controller.playback.current.get("cause", "") == "poison":
			break
		controller.advance_resolution(10.0)
	await capture_phase2("poison", scene)
	BattleTest.settle(controller)
	battle.ally_moves.assign([controller.library.find("current")])
	controller.choose_move(0)
	controller.select_cell(battle.ally_cell)
	BattleTest.settle(controller)
	var report := battle.imprint()
	var hp := battle.enemy_hp
	var attempts := battle.capture_attempts
	controller.playback.submit("capture", Vector2i.ZERO, -1, 0.0)
	check(controller.session == battle and state.attempts == 0, "Capture presentation holds the live battle before any persistent completion")
	BattleTest.settle(controller)
	check(controller.completion_failed and controller.combat_hud.retry_button.visible and controller.session == battle and state.attempts == 1 and not controller.feedback_view.result_panel.visible, "A rejected completion keeps battlefield context and a visible retry without a false result recap")
	await capture_phase2("retry-result", scene)
	var protected_snapshot := state.snapshot()
	world.save_game(save_path)
	world.load_game(save_path)
	check(world.persistent_state == state and FileAccess.get_file_as_string(save_path) == original_bytes, "A pending rejected result stays unsavable and cannot be replaced through load")
	controller.after_command()
	controller.capture_enemy()
	controller.retreat()
	check(state.attempts == 1 and state.snapshot() == protected_snapshot and battle.capture_attempts == attempts + 1, "Rejected completion cannot silently retry or repeat a capture roll")
	controller.combat_hud.retry_button.pressed.emit()
	check(state.attempts == 2 and controller.completion_failed and state.snapshot() == protected_snapshot, "An explicitly rejected retry remains recoverable without partial persistent writes")
	state.reject = false
	battle.enemy_hp = maxi(1, hp - 1) # Retry must use the frozen resolved capture, not later view data.
	controller.combat_hud.retry_button.pressed.emit()
	check(controller.session == null and state.attempts == 3 and state.battle_progress().captures == 1 and state.companion_view(member.id).hp == hp, "Retry records the same captured individual and retained HP once, without replaying battle actions")
	check(not report.is_empty() and state.affinity_tiles()[report.tiles[0]].affinity == report.winner and state.active_sol_view().xp == 0, "Capture retry applies the existing move imprint once and grants no capture XP")
	controller.combat_hud.retry_button.pressed.emit()
	check(state.attempts == 3 and state.battle_progress().captures == 1, "Stale retry callbacks cannot replay a successful result")
	world.new_expedition(17)
	controller.combat_hud.retry_button.pressed.emit()
	check(not controller.completion_failed and controller.completion_session == null and not scene.player_visual.returning, "State replacement clears retry authority and obsolete trainer routes")
	var invalid_settings: BattleSettings = scene.battle_settings.duplicate(true)
	invalid_settings.commander_run_speed = NAN
	check(not invalid_settings.valid(), "Nonfinite commander speed is rejected by its connected Inspector resource")
	for outcome in ["victory", "exhaustion", "retreat"]:
		world.new_expedition(17)
		world.persistent_state.choose_starter(scene.battle_settings.starters[0].snapshot(), 0)
		member = scene.sightings.members[0]
		world.cell = member.home + Vector2i.LEFT
		world.destination = world.cell
		world.rebuild_world()
		var encounter_origin: Vector2i = world.cell
		scene.encounters.approach_individual(member.id)
		scene.encounters.battle_button.pressed.emit()
		BattleTest.settle(controller)
		battle = controller.session
		check(scene.player_visual.sideline_walk_speed == scene.battle_settings.commander_run_speed, "The active commander run uses the connected battle setting")
		controller.select_cell(battle.deployment_tiles()[0])
		BattleTest.settle(controller)
		var token: int = controller.serial
		if outcome == "victory":
			for at in battle.cells:
				battle.cells[at] = true
			battle.enemy_hp = 1
			battle.ally_moves.assign([move("damage", "fire", 1000)])
			battle.ally_moves[0].reach = 20
			controller.choose_move(0)
			controller.select_cell(battle.enemy_cell)
		elif outcome == "exhaustion":
			battle.ally_hp = 1
			battle.statuses.ally.poison = {"magnitude": 2, "turns": 1}
			controller.wait_turn()
		else:
			battle.ally_moves.assign([controller.library.find("barrier")])
			battle.ally_moves[0].reach = 20
			controller.choose_move(0)
			controller.select_cell(encounter_origin)
			BattleTest.settle(controller)
			controller.request_retreat()
			controller.retreat_dialog.confirmed.emit()
		check(controller.session == battle and controller.playback.busy, "Every live terminal path retains its context until the last consequence is presented")
		BattleTest.settle(controller)
		var saved: Dictionary = world.persistent_state.snapshot()
		check(controller.session == null and world.persistent_state.battle_progress().last_result.outcome == outcome and not world.encounter_active, "Each paced terminal path commits its actual outcome and returns to exploration")
		check(not world.persistent_state.complete_battle(token, 0 if outcome == "exhaustion" else 1, outcome, 3) and world.persistent_state.snapshot() == saved, "Each terminal receipt rejects replay without changing rewards, health or imprints")
		if outcome == "exhaustion":
			check(world.cell == Vector2i.ZERO and world.persistent_state.active_sol_view().hp == 0, "Paced exhaustion retains refuge recovery and the same zero-HP companion")
		if outcome == "retreat":
			check(world.cell == battle.trainer and world.persistent_state.environment_view(encounter_origin, {}).conditions.has("barrier"), "A barrier on the freed origin remains intact and the trainer safely stays outside instead of returning into it")
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(save_path + suffix):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path + suffix))
	scene.free()

func run() -> void:
	automatic_checks()
	move_checks()
	capture_checks()
	commander_checks()
	await live_checks()
	print("COMBAT CONSEQUENCES: %d checks, %d failures." % [checks, failures])
	quit(0 if failures == 0 else 1)

func capture_phase2(name: String, scene: Node3D) -> void:
	if not OS.get_cmdline_user_args().has("--capture-consequences") or DisplayServer.get_name() == "headless":
		return
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280, 800)
	scene.battles.frame_battle()
	if name == "retry-result":
		await create_timer(scene.sightings.visual_settings.feedback_seconds).timeout
	for frame in range(5):
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/combat-consequences/%s.png" % name)
