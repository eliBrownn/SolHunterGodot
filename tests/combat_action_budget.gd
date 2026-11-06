extends "res://tests/combat_sequencing.gd"

var library: MoveLibrary = preload("res://resources/move_library.tres")

func ready_battle() -> TacticalBattle:
	var battle := fixture()
	battle.automatic_enemies = false
	battle.ally_moves.assign([library.find("current"), library.find("strike"), library.find("focus"), library.find("ward")])
	battle.deploy(Vector2i(1, 0))
	return battle

func run() -> void:
	var settings := preload("res://resources/battle_settings.tres").duplicate(true) as BattleSettings
	settings.action_points = 0
	check(not settings.valid(), "Zero turn budgets reject")
	for invalid in [0, -1, 13, 1.5, true]:
		var move := library.find("strike")
		move.action_points = invalid
		check(not SolMove.valid(move), "Move costs reject zero, negative, excessive, fractional and boolean values")
	var battle := ready_battle()
	check(battle.actions_remaining == 6 and battle.remaining == 2, "Turns start with six AP plus Speed-derived movement")
	var hp := battle.enemy_hp
	check(battle.use_move(0, Vector2i(1, 1)) and battle.actions_remaining == 4 and battle.turn == "ally" and battle.round_number == 1, "Terrain costs two AP and leaves the current turn open")
	check(battle.use_move(1, battle.enemy_cell) and battle.actions_remaining == 0 and battle.enemy_hp < hp and battle.turn == "ally", "Terrain and attack fit in the same turn")
	var before := battle.view_snapshot()
	var serial := battle.action_serial
	check(not battle.use_move(1, battle.enemy_cell) and before == battle.view_snapshot() and serial == battle.action_serial, "Unaffordable moves reject without any mutation or announcement")
	check(battle.wait_turn() and battle.turn == "enemy" and battle.actions_remaining == 6, "Only explicit End turn hands off and refills the next actor")
	battle = ready_battle()
	check(battle.use_move(1, battle.enemy_cell) and battle.use_move(0, Vector2i(1, 1)) and battle.actions_remaining == 0, "Attack then terrain is equally legal")
	battle = ready_battle()
	check(battle.use_move(0, Vector2i(1, 1)) and battle.use_move(2, battle.ally_cell) and battle.use_move(3, battle.ally_cell) and battle.actions_remaining == 0, "All six points may fund three different setup actions without attacking")
	check(not battle.statuses.ally.is_empty() and battle.enemy_hp == 40, "Setup-only turns change tactical state without requiring damage")
	battle = ready_battle()
	battle.use_move(2, battle.ally_cell)
	before = battle.view_snapshot()
	check(not battle.use_move(2, battle.ally_cell) and before == battle.view_snapshot(), "Identical buffs cannot be stacked repeatedly for value")
	battle = ready_battle()
	battle.use_move(0, Vector2i(1, 1))
	before = battle.view_snapshot()
	serial = battle.action_serial
	check(not battle.use_move(0, Vector2i(1, 1)) and before == battle.view_snapshot() and serial == battle.action_serial, "Unchanged terrain rejects before spending points, activity or presentation")
	battle = ready_battle()
	battle.ally_moves.assign([library.find("mend"), library.find("strike")])
	check(battle.use_move(0, battle.ally_cell) and battle.actions_remaining == 2 and not battle.can_use(1, battle.enemy_cell), "Healing uses the four-point combat cost and competes with attacking")
	check(battle.capture_chance() == 0, "A spent combat budget cannot purchase a free Seal attempt")
	battle = ready_battle()
	check(battle.move_ally(Vector2i(1, 2)) and battle.remaining == 0 and battle.actions_remaining == 6, "Speed movement is spent before shared AP")
	check(battle.move_ally(Vector2i(1, 3)) and battle.actions_remaining == 5, "Extra cardinal movement spends one shared point")
	check(battle.move_ally(Vector2i(1, 2)) and battle.actions_remaining == 4, "Retracing a route never refunds movement or AP")
	battle = ready_battle()
	var speed_buff := library.find("focus")
	speed_buff.stat = "speed"
	speed_buff.power = 100
	battle.ally_moves.assign([speed_buff])
	battle.use_move(0, battle.ally_cell)
	check(battle.remaining == 2, "Speed changes never refill the current movement allowance")
	battle.finish_turn()
	battle.finish_turn()
	check(battle.remaining == 3 and battle.actions_remaining == 6, "Next turn derives a fresh capped allowance from effective Speed")
	battle = ready_battle()
	battle.ally_moves[1].action_points = 3
	check(battle.use_move(1, battle.enemy_cell) and battle.use_move(1, battle.enemy_cell) and battle.actions_remaining == 0, "Per-move costs permit future three-point moves without changing turn logic")
	battle = ready_battle()
	battle.ally_moves.assign([library.find("spores")])
	battle.use_move(0, battle.enemy_cell)
	check(battle.enemy_hp == 40, "Status effects do not tick merely because a move was used")
	battle.wait_turn()
	battle.finish_turn()
	check(battle.enemy_hp == 38, "Status effects tick once at their recipient's actual turn boundary")
	battle = ready_battle()
	battle.enemy_moves.assign([library.find("strike")])
	battle.enemy_moves[0].action_points = 2
	battle.wait_turn()
	var ally_hp := battle.ally_hp
	check(battle.advance_enemy() and battle.actions_remaining == 4 and battle.turn == "enemy", "Enemy moves spend the same shared budget without premature handoff")
	battle.advance_enemy()
	battle.advance_enemy()
	check(battle.actions_remaining == 0 and battle.ally_hp < ally_hp, "Enemy can use multiple affordable moves")
	battle.advance_enemy()
	check(battle.turn == "ally" and battle.actions_remaining == 6, "Enemy finishes safely once no affordable action remains")
	battle = ready_battle()
	battle.wait_turn()
	battle.ally_cell = Vector2i(-3, 0)
	battle.enemy_cell = Vector2i(3, 0)
	battle.remaining = 0
	var plan := battle.plan_enemy()
	var routes := battle.paths(battle.enemy_cell, battle.actions_remaining, battle.ally_cell, false, "enemy")
	if plan.slot >= 0:
		check(battle.route_cost(battle.enemy_cell, routes[plan.cell], "enemy") + SolMove.cost(battle.enemy_moves[plan.slot]) <= battle.actions_remaining, "Enemy plans reserve AP for the move after movement")
	else:
		check(routes.has(plan.cell), "Enemy approach stays inside the shared movement budget")
	await live_checks()
	print("COMBAT ACTION BUDGET: %d checks, %d failures." % [checks, failures])
	quit(0 if failures == 0 else 1)

func live_checks() -> void:
	var scene: Node3D = load("res://scenes/world_3d.tscn").instantiate()
	scene.sighting_settings = scene.sighting_settings.duplicate(true)
	scene.sighting_settings.wilderness_enabled = false
	scene.sighting_settings.movement_enabled = false
	root.add_child(scene)
	scene.world.smoke_mode = true
	scene.world.new_expedition(17)
	var controller: Node = scene.battles
	scene.world.persistent_state.choose_starter(scene.battle_settings.starters[0].snapshot(), 0)
	var member: Dictionary = scene.sightings.members[0]
	scene.world.cell = member.home + Vector2i.LEFT
	scene.world.destination = scene.world.cell
	scene.world.rebuild_world()
	scene.encounters.approach_nearest()
	scene.encounters.battle_button.pressed.emit()
	var battle: TacticalBattle = controller.session
	BattleTest.settle(controller)
	controller.select_cell(battle.deployment_tiles()[0])
	BattleTest.settle(controller)
	controller.update_view()
	check(controller.combat_hud.round_label.text.contains("AP 6/6") and controller.move_buttons[0].text.contains("4 AP"), "Live HUD exposes the budget and move costs")
	controller.choose_move(1)
	var target: Vector2i = controller.legal_targets(1)[0]
	controller.select_cell(target)
	check(controller.playback.busy, "Live terrain placement uses sequenced presentation")
	BattleTest.settle(controller)
	check(controller.session == battle and battle.turn == "ally" and battle.actions_remaining == 4 and controller.combat_hud.round_label.text.contains("AP 4/6"), "Terrain playback returns control with the attack budget retained")
	if DisplayServer.get_name() != "headless":
		root.size = Vector2i(1280, 800)
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://artifacts/combat-action-budget/budget.png")
	controller.retreat()
	BattleTest.settle(controller)
	check(controller.session == null and ExpeditionState.restore(scene.world.persistent_state.snapshot(), 17) != null, "Explicit retreat still completes and preserves a valid expedition")
	scene.queue_free()
	await process_frame
