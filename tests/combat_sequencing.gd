extends SceneTree
const BattleTest = preload("res://tests/battle_test_support.gd")
var checks := 0
var failures := 0

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)

func _initialize() -> void:
	create_timer(120).timeout.connect(func() -> void: quit(1))
	run.call_deferred()

func fixture(enemy_speed: int = 10, opponent_at: Vector2i = Vector2i(2, 0)) -> TacticalBattle:
	var settings: BattleSettings = preload("res://resources/battle_settings.tres")
	var hero := settings.starters[2].snapshot()
	var enemy := settings.opponents[0].snapshot()
	hero.max_hp = 40
	hero.defense = 10
	hero.speed = 20
	enemy.max_hp = 40
	enemy.attack = 8
	enemy.speed = enemy_speed
	var battle := TacticalBattle.prepare(WorldTerrain.new(17), Vector2i.ZERO, opponent_at, hero, 36, enemy, settings)
	for at in battle.cells:
		battle.cells[at] = true
	battle.ally_moves.assign([{"id": "mend", "name": "Mend", "effect": "heal", "affinity": "water", "power": 4, "reach": 0, "duration": 1}])
	battle.enemy_moves.assign([{"id": "strike", "name": "Strike", "effect": "damage", "affinity": "earth", "power": 6, "reach": 2, "duration": 1}])
	return battle

func drain(playback: BattlePlayback, delta: float = 10.0) -> void:
	for step in range(512):
		if not playback.busy:
			return
		playback.advance(delta)
	check(false, "Presentation finishes within the fixture bound")

func domain_checks() -> void:
	var direct := fixture()
	direct.deploy(Vector2i(1, 0))
	direct.use_move(0, direct.ally_cell)
	direct.wait_turn()
	check(direct.ally_hp == 36, "Reference calculation heals four then takes four, leaving unchanged final HP")
	var battle := fixture()
	var tuning := SolVisualSettings.new()
	var playback := BattlePlayback.new()
	playback.bind(battle, tuning, 12, {"ally": "owned-1", "enemy": "wild-1"})
	playback.submit("deploy", Vector2i(1, 0))
	drain(playback)
	var trace: Array[Dictionary] = []
	playback.changed.connect(func(step: Dictionary) -> void: trace.append(step))
	check(playback.submit("move_slot", battle.ally_cell, 0), "Accepted healing starts a presentation sequence")
	check(playback.current.kind == "action" and playback.view.ally_hp == 36 and battle.ally_hp == 40, "The move announcement shows pre-heal HP while the atomic action is already resolved")
	check(battle.turn == "ally" and battle.ally_hp == 40, "Healing retains the player's turn until explicit End turn")
	var before := battle.view_snapshot()
	check(not playback.submit("capture", Vector2i.ZERO, -1, 0) and before == battle.view_snapshot() and battle.capture_attempts == 0, "Busy admission rejects another command without effects or capture attempts")
	playback.advance(0.1)
	check(playback.current.kind == "action", "A short frame retains the configured action cue")
	playback.advance(10.0)
	check(playback.current.cue.get("kind") == "heal" and playback.view.ally_hp == 40 and battle.ally_hp == 40, "Healing is displayed separately before any enemy damage")
	drain(playback)
	playback.submit("wait")
	drain(playback)
	var effects: Array[Dictionary] = []
	for step in trace:
		if step.kind == "effect":
			effects.append(step)
	check(effects.size() == 2 and effects[0].cue.kind == "heal" and effects[0].snapshot.ally_hp == 40 and effects[1].cue.kind == "damage" and effects[1].snapshot.ally_hp == 36, "The displayed sequence retains heal-then-hit despite zero net HP change")
	check(effects[0].battle_serial == 12 and effects[0].actor_id == "owned-1" and effects[1].actor_id == "wild-1" and effects[1].recipient_id == "owned-1", "Records identify their battle, actor and actual HP recipient")
	check(battle.view_snapshot() == direct.view_snapshot(), "Stepped presentation preserves the direct domain's resulting state")
	battle.ally_hp = 1
	check(effects[0].snapshot.ally_hp == 40 and effects[1].snapshot.ally_hp == 36, "Recorded intermediate states are detached from later live mutations")
	playback.reset()
	for speed in [0.0, 0.5]:
		var sample := fixture()
		var settings := SolVisualSettings.new()
		settings.action_cue_seconds = speed
		settings.consequence_seconds = speed
		settings.movement_step_seconds = speed
		settings.turn_handoff_seconds = speed
		playback.bind(sample, settings)
		playback.submit("deploy", Vector2i(1, 0))
		drain(playback)
		playback.submit("move_slot", sample.ally_cell, 0)
		drain(playback)
		playback.submit("wait")
		drain(playback)
		check(sample.view_snapshot() == direct.view_snapshot(), "Zero and slower presentation durations preserve identical combat results")
		playback.reset()
	var fast := fixture(30)
	playback.bind(fast, tuning)
	playback.submit("deploy", Vector2i(1, 0))
	check(fast.ally_hp == 36 and fast.turn == "enemy", "A faster enemy awaits its visible deployment handoff")
	drain(playback)
	check(fast.ally_hp == 32 and fast.turn == "ally", "Faster-enemy deployment still grants its actual first turn")
	playback.submit("move_slot", fast.ally_cell, 0)
	drain(playback)
	playback.submit("wait")
	drain(playback)
	check(fast.ally_hp == 32 and fast.round_number == 2 and fast.turn == "ally", "Faster-enemy initiative remains correct in the next round")
	playback.reset()
	var crossing := fixture()
	playback.bind(crossing, tuning)
	playback.submit("deploy", Vector2i(1, 0))
	drain(playback)
	trace.clear()
	crossing.enemy.speed = 30 # A speed change takes effect at the next round boundary.
	playback.submit("move_slot", crossing.ally_cell, 0)
	drain(playback)
	playback.submit("wait")
	drain(playback)
	var enemy_actions := 0
	for step in trace:
		if step.kind == "action" and step.side == "enemy" and step.caption.contains("uses Strike"):
			enemy_actions += 1
	check(enemy_actions == 2 and crossing.ally_hp == 32 and crossing.round_number == 2 and crossing.turn == "ally", "A changed initiative order preserves consecutive enemy activations across rounds")
	playback.reset()
	var walking := fixture(10, Vector2i(4, 0))
	walking.cells[Vector2i(1, 1)] = false
	playback.bind(walking, tuning)
	playback.submit("deploy", Vector2i(1, 0))
	drain(playback)
	trace.clear()
	playback.submit("move", Vector2i(2, 1))
	drain(playback)
	var route: Array[Vector2i] = []
	for step in trace:
		if step.kind == "movement":
			route.append(step.snapshot.ally_cell)
	check(route == [Vector2i(2, 0), Vector2i(2, 1)] and walking.remaining == 0 and walking.actions_remaining == 6, "Displayed movement follows the cardinal detour and spends Speed movement before AP")
	playback.submit("wait")
	playback.reset()
	playback.advance(10.0)
	check(not playback.busy and playback.pending.is_empty() and playback.view == null, "Reset discards pending records and cannot advance an old session")
	for property in ["action_cue_seconds", "consequence_seconds", "movement_step_seconds", "turn_handoff_seconds"]:
		var invalid := SolVisualSettings.new()
		invalid.set(property, NAN)
		check(not invalid.valid(), "Nonfinite battle pacing is rejected")
		invalid.set(property, -0.1)
		check(not invalid.valid(), "Negative battle pacing is rejected")

func run() -> void:
	domain_checks()
	var scene: Node3D = load("res://scenes/world_3d.tscn").instantiate()
	scene.sol_visual_settings = SolVisualSettings.new()
	scene.sol_visual_settings.health_bar_seconds = 0
	scene.sighting_settings = scene.sighting_settings.duplicate(true)
	scene.sighting_settings.wilderness_enabled = false
	scene.sighting_settings.movement_enabled = false
	root.add_child(scene)
	var world: Node2D = scene.world
	world.smoke_mode = true
	world.new_expedition(17)
	world.persistent_state.choose_starter(scene.battle_settings.starters[2].snapshot(), 2)
	var save_path := "user://combat-sequencing-%d.json" % Time.get_ticks_usec()
	world.save_game(save_path)
	var saved_bytes := FileAccess.get_file_as_string(save_path)
	var member: Dictionary = scene.sightings.members[0]
	world.cell = member.home + Vector2i.LEFT
	world.destination = world.cell
	world.rebuild_world()
	scene.encounters.approach_individual(member.id)
	scene.encounters.battle_button.pressed.emit()
	var controller: Node = scene.battles
	var battle: TacticalBattle = controller.session
	battle.ally.speed = 99
	battle.enemy.speed = 1
	for at in battle.cells:
		battle.cells[at] = true
	var release: Vector2i = battle.deployment_tiles()[0]
	for at in battle.deployment_tiles():
		if TacticalBattle.distance(at, battle.enemy_cell) < TacticalBattle.distance(release, battle.enemy_cell):
			release = at
	BattleTest.settle(controller)
	controller.select_cell(release)
	BattleTest.settle(controller)
	battle.ally_hp = int(battle.ally.max_hp) - 4
	battle.enemy.attack = int(battle.ally.defense)
	battle.ally_moves.assign([{"id": "mend", "name": "Mend", "effect": "heal", "affinity": "water", "power": 4, "reach": 0, "duration": 1}])
	battle.enemy_moves.assign([{"id": "strike", "name": "Strike", "effect": "damage", "affinity": "earth", "power": 4, "reach": 4, "duration": 1}])
	controller.update_view()
	controller.choose_move(0)
	var hp_before := battle.ally_hp
	controller.select_cell(battle.ally_cell)
	check(controller.playback.busy and controller.combat_hud.status_label.text.contains("Mend") and controller.combat_hud.cards.ally.hp.text.begins_with(str(hp_before)), "Live move confirmation first shows its actor/move and previous HP")
	check(controller.move_buttons[0].disabled and controller.capture_button.disabled and controller.wait_button.disabled and controller.combat_hud.retreat_button.disabled and controller.move_buttons[0].tooltip_text.contains("current resolution") and controller.combat_hud.log_label.text.contains("uses Mend"), "Mutation controls explain the resolution gate and the log includes the presented action")
	var protected_state := battle.view_snapshot()
	controller.wait_turn()
	controller.capture_enemy()
	controller.choose_move(0)
	controller.select_cell(battle.enemy_cell)
	controller.retreat()
	controller.request_retreat()
	controller.quantum_choice.item_selected.emit(1)
	check(battle.view_snapshot() == protected_state and battle.capture_attempts == 0 and battle.quantum_mode == "position" and not controller.retreat_dialog.visible, "Direct repeated command callbacks cannot bypass the resolution gate")
	controller.open_battle_menu()
	var current_sequence: int = controller.playback.current.sequence
	world.smoke_mode = false
	controller._process(10.0)
	world.smoke_mode = true
	check(controller.playback.current.sequence == current_sequence, "Battle menu pauses presentation without consuming another step")
	controller.close_battle_menu()
	world.save_game(save_path)
	world.load_game(save_path)
	check(FileAccess.get_file_as_string(save_path) == saved_bytes and controller.session == battle and controller.playback.current.sequence == current_sequence, "Saving and loading remain blocked throughout active presentation")
	await capture("action", scene)
	if rendered_capture():
		await create_timer(controller.playback.seconds_left).timeout
	world.smoke_mode = false
	controller._process(10.0)
	world.smoke_mode = true
	check(controller.combat_hud.cards.ally.hp.text.begins_with(str(hp_before + 4)) and controller.combat_hud.cards.ally.bar.value == hp_before + 4, "HP text and bar reveal the intermediate heal together")
	check(world.observation_name(battle.ally_cell).contains("HP %d/" % (hp_before + 4)), "Inspection uses the same presented HP as the battle card")
	await capture("healing", scene)
	BattleTest.settle(controller)
	controller.wait_turn()
	for step in range(100):
		if controller.playback.current.get("cue", {}).get("kind") == "damage":
			break
		if rendered_capture():
			await create_timer(maxf(0.01, controller.playback.seconds_left)).timeout
		controller.advance_resolution(10.0)
	check(controller.playback.busy and controller.combat_hud.cards.ally.hp.text.begins_with(str(hp_before)) and controller.feedback_view.cues.back().kind == "damage", "The enemy hit and reduced HP become visible only in their later step")
	await capture("enemy-hit", scene)
	BattleTest.settle(controller)
	check(not controller.playback.busy and not controller.wait_button.disabled and battle.turn == "ally", "Player controls return after the full response settles")
	controller.request_retreat()
	controller.retreat_dialog.confirmed.emit()
	check(controller.session == battle and world.persistent_state.battle_progress().retreats == 0, "Terminal display retains battle context before the single completion commit")
	BattleTest.settle(controller)
	check(controller.session == null and world.persistent_state.battle_progress().retreats == 1 and world.persistent_state.active_sol_view().hp == hp_before, "Settled retreat commits the actual retained HP once and restores exploration")
	controller.after_command()
	check(world.persistent_state.battle_progress().retreats == 1, "Repeated completion cannot replay a paced result")
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(save_path + suffix):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path + suffix))
	scene.free()
	print("COMBAT SEQUENCING: %d checks, %d failures." % [checks, failures])
	quit(0 if failures == 0 else 1)

func rendered_capture() -> bool:
	return OS.get_cmdline_user_args().has("--capture-sequencing") and DisplayServer.get_name() != "headless"

func capture(name: String, scene: Node3D) -> void:
	if not rendered_capture():
		return
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280, 800)
	scene.battles.frame_battle()
	for frame in range(5):
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/combat-sequencing/%s.png" % name)
