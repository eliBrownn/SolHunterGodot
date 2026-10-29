extends "res://tests/combat_sequencing.gd"

var library: MoveLibrary = preload("res://resources/move_library.tres")

func ready(ids: Array) -> TacticalBattle:
	var battle := fixture()
	battle.automatic_enemies = false
	battle.ally_moves.clear()
	for id in ids:
		battle.ally_moves.append(library.find(id))
	battle.deploy(Vector2i(1, 0))
	return battle

func next_turn(battle: TacticalBattle) -> void:
	battle.wait_turn()
	if battle.phase == "active":
		battle.finish_turn()

func run() -> void:
	check(library.valid(), "Expanded early library validates as connected species content")
	var roles: Dictionary = {}
	for move in library.moves:
		check(SolMove.valid(move.snapshot()), "Authored move schema validates costs, supply and effect contracts")
		roles[move.affinity] = true
	check(roles.size() == AffinityImprint.IDS.size(), "All approved affinities have authored early moves")
	for species in library.species_catalog.entries:
		var book := library.book(species.species_id)
		check(MoveLibrary.valid_book(book) and book.learned.size() > book.equipped.size() and book.equipped.size() == 4, "Each catalog species has immediately remembered alternatives but only four equipped slots")
	for invalid in [0, -1, 41, 2.5, true]:
		var move := library.find("strike")
		move.max_uses = invalid
		check(not SolMove.valid(move), "Use ceilings reject malformed values")
	var passive := library.find("grit_guard")
	passive.action_points = 1
	check(not SolMove.valid(passive), "Automatic passives cannot masquerade as paid manual moves")
	var hybrid := library.find("static_tap")
	hybrid.secondary_power = 0
	check(not SolMove.valid(hybrid), "Hybrid statuses must author a real secondary magnitude")
	var battle := ready(["strike"])
	battle.ally_moves[0].max_uses = 1
	var before := battle.view_snapshot()
	check(not battle.use_move(0, battle.trainer) and before == battle.view_snapshot(), "Invalid targets consume neither AP nor a move use")
	var preview := battle.damage_for("ally", battle.ally_moves[0], battle.ally_cell)
	check(battle.uses_left("ally", battle.ally_moves[0]) == 1, "Read-only damage forecasts do not consume supply")
	check(battle.use_move(0, battle.enemy_cell) and battle.uses_left("ally", battle.ally_moves[0]) == 0 and battle.enemy_hp == 40 - preview, "One successful primary move spends exactly one use")
	next_turn(battle)
	before = battle.view_snapshot()
	check(not battle.use_move(0, battle.enemy_cell) and before == battle.view_snapshot(), "A fresh turn does not refill an exhausted move")
	var fallback := battle.moves_for("ally")
	check(fallback.back().id == "last_effort" and battle.ally_moves.size() == 1, "Fallback becomes available without changing the saved loadout")
	var imprint := battle.activity.duplicate()
	check(battle.use_move(fallback.size() - 1, battle.enemy_cell) and battle.activity == imprint and battle.actions_remaining == 2, "Fallback spends AP but adds no affinity activity")
	check(ready(["strike"]).uses_left("ally", library.find("strike")) == SolMove.uses(library.find("strike")), "A new encounter starts with fresh move supply")
	battle = ready(["strike"])
	battle.ally_moves.clear()
	battle.move_uses.ally.legacy_basic = 16
	check(battle.moves_for("ally")[0].id == "last_effort" and battle.attack(), "An exhausted prototype basic also has a legal fallback")
	var forbidden := library.find("strike")
	forbidden.id = "last_effort"
	check(not SolMove.valid(forbidden), "A learned move cannot impersonate the unlimited fallback")
	battle = ready(["strike", "strike"])
	battle.ally_moves[0].max_uses = 1
	battle.ally_moves[1].max_uses = 1
	battle.use_move(0, battle.enemy_cell)
	check(battle.uses_left("ally", battle.ally_moves[1]) == 0, "Duplicate identities cannot create extra uses by changing slot")
	battle = ready(["smoulder"])
	var hit := battle.damage_for("ally", battle.ally_moves[0], battle.ally_cell)
	battle.use_move(0, battle.enemy_cell)
	check(battle.enemy_hp == 40 - hit and battle.fields.size() == 1 and battle.fields[battle.enemy_cell].kind == "heat", "Terrain hybrid deals its predicted hit and creates exactly one shared tile")
	check(battle.activity.fire == 1 and battle.uses_left("ally", battle.ally_moves[0]) == SolMove.uses(battle.ally_moves[0]) - 1 and battle.actions_remaining == 2, "A hybrid counts one use, one action cost and one imprint event")
	check(battle.fields[battle.enemy_cell].round == battle.round_number, "New hybrid heat does not silently deal an immediate second hit")
	battle = ready(["static_tap"])
	var movement := battle.remaining
	battle.use_move(0, battle.enemy_cell)
	check(battle.statuses.enemy.speed_down.magnitude == 5 and battle.remaining == movement and battle.turn == "ally", "A hybrid applies its small status without a second turn or movement refill")
	battle = ready(["soothing_guard"])
	battle.ally_hp = 40
	battle.tile_overloads[battle.ally_cell] = VastraCombat.MIN_OVERLOAD
	check(battle.use_move(0, battle.ally_cell) and battle.ally_hp == 40 and battle.statuses.ally.protect.magnitude == 8 and battle.actions_remaining == 1, "Hybrid support remains useful at full HP when its protective component has value")
	battle = ready(["soothing_guard"])
	battle.ally_hp = 40
	battle.tile_overloads[battle.ally_cell] = VastraCombat.MIN_OVERLOAD
	battle.statuses.ally.protect = {"magnitude": 15, "turns": 1}
	before = battle.view_snapshot()
	check(not battle.use_move(0, battle.ally_cell) and before == battle.view_snapshot(), "A weak hybrid cannot refresh a stronger guard when neither healing nor restoration has value")
	battle = ready(["mend"])
	battle.ally_hp = 20
	var healing := battle.ally_moves[0]
	for use in range(SolMove.uses(healing)):
		battle.ally_hp = 20
		check(battle.use_move(0, battle.ally_cell), "Each available healing use can be executed once")
		next_turn(battle)
	check(not battle.can_use(0, battle.ally_cell) and battle.uses_left("ally", healing) == 0, "Healing cannot continue indefinitely across turns")
	battle = ready(["strike", "stillwater"])
	battle.ally_hp = 20
	check(not battle.can_use(1, battle.ally_cell), "An equipped passive cannot be manually executed")
	for use in range(4):
		next_turn(battle)
	check(battle.ally_hp == 26 and battle.uses_left("ally", battle.ally_moves[1]) == 0 and battle.activity.is_empty(), "Stationary renewal triggers only three useful heals and never farms imprint activity")
	battle = ready(["strike", "stillwater"])
	battle.ally_hp = 40
	next_turn(battle)
	check(battle.uses_left("ally", battle.ally_moves[1]) == 3, "A passive wastes no charge at full HP")
	battle.ally_hp = 20
	battle.move_ally(Vector2i(1, 1))
	next_turn(battle)
	check(battle.ally_hp == 20 and battle.uses_left("ally", battle.ally_moves[1]) == 3, "Movement prevents stationary passive recovery")
	battle = ready(["strike", "grit_guard"])
	battle.wait_turn()
	var guard_preview := battle.damage_for("enemy", battle.enemy_moves[0], battle.enemy_cell)
	var supply := battle.uses_left("ally", battle.ally_moves[1])
	check(battle.guard_slot("ally") == 1 and supply == 3, "Stationary guard prepares without consuming a reaction")
	var hp := battle.ally_hp
	battle.execute_move("enemy", 0, battle.ally_cell)
	check(battle.ally_hp == hp - guard_preview and battle.uses_left("ally", battle.ally_moves[1]) == supply - 1 and battle.guard_slot("ally") == -1, "A guarded hit matches its preview and consumes exactly one passive charge")
	battle.finish_turn()
	battle.passive_guard.ally = true
	battle.move_ally(Vector2i(1, 1))
	check(battle.guard_slot("ally") == -1, "Moving breaks guard readiness without inventing a charge refund")
	battle = ready(["quick_fang", "heavy_swing"])
	var quick := battle.damage_for("ally", battle.ally_moves[0], battle.ally_cell)
	var heavy := battle.damage_for("ally", battle.ally_moves[1], battle.ally_cell)
	check(quick < heavy and SolMove.cost(battle.ally_moves[0]) < SolMove.cost(battle.ally_moves[1]) and SolMove.uses(battle.ally_moves[0]) > SolMove.uses(battle.ally_moves[1]), "Light and heavy early moves trade damage, AP and supply in the actual calculation")
	battle = ready(["strike"])
	battle.enemy_moves.assign([library.find("static_tap")])
	battle.enemy_moves[0].max_uses = 1
	battle.wait_turn()
	var planned := battle.plan_enemy()
	check(planned.slot == 0 and battle.advance_enemy() and battle.statuses.ally.has("speed_down") and battle.uses_left("enemy", battle.enemy_moves[0]) == 0, "Enemy planning and execution apply the same finite hybrid effect")
	var state := ExpeditionState.new(17)
	var settings: BattleSettings = preload("res://resources/battle_settings.tres")
	state.choose_starter(settings.starters[0].snapshot(), 0)
	var identity: String = state.active_sol_view().id
	var book := library.book("bramblepup")
	check(state.admit_movebook(identity, book), "Expanded starting book is admitted for the real individual")
	var restored := ExpeditionState.restore(JSON.parse_string(JSON.stringify(state.snapshot(), "", true, true)), 17)
	check(restored != null and restored.movebook(identity) == book, "New cost, supply, hybrid and passive authoring survives save/load")
	await live_supply_checks()
	print("EARLY COMBAT MOVES: %d checks, %d failures." % [checks, failures])
	quit(0 if failures == 0 else 1)

func live_supply_checks() -> void:
	var scene: Node3D = load("res://scenes/world_3d.tscn").instantiate()
	scene.sighting_settings = scene.sighting_settings.duplicate(true)
	scene.sighting_settings.wilderness_enabled = false
	scene.sighting_settings.movement_enabled = false
	root.add_child(scene)
	var world: Node2D = scene.world
	world.smoke_mode = true
	world.new_expedition(17)
	world.persistent_state.choose_starter(scene.battle_settings.starters[0].snapshot(), 0)
	var member: Dictionary = scene.sightings.members[0]
	world.cell = member.home + Vector2i.LEFT
	world.destination = world.cell
	world.rebuild_world()
	scene.encounters.approach_nearest()
	scene.encounters.battle_button.pressed.emit()
	var controller: Node = scene.battles
	BattleTest.settle(controller)
	var battle: TacticalBattle = controller.session
	controller.select_cell(battle.deployment_tiles()[0])
	BattleTest.settle(controller)
	battle.ally_moves.assign([library.find("strike"), library.find("smoulder"), library.find("grit_guard"), library.find("gentle_mend")])
	battle.move_uses.ally.strike = SolMove.uses(battle.ally_moves[0])
	controller.update_view()
	check(controller.move_buttons[0].disabled and controller.move_buttons[0].text.contains("0/16") and controller.move_buttons[0].tooltip_text.contains("No uses"), "The live HUD explains depleted supply")
	check(controller.move_buttons[2].disabled and controller.move_buttons[2].text.contains("Passive") and controller.move_buttons[2].text.contains("3/3"), "Passive cards display their actual limited reactions without arming a manual command")
	battle.move_uses.ally.smoulder = SolMove.uses(battle.ally_moves[1])
	controller.update_view()
	check(controller.move_buttons[4].visible and controller.move_buttons[4].text.contains("Last Effort"), "The exhausted real loadout exposes its fallback through ordinary controls")
	if DisplayServer.get_name() != "headless":
		root.size = Vector2i(1280, 800)
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://artifacts/early-moves/supply.png")
	# Complete a fallback-only victory through real aiming/playback and persistence.
	battle.enemy_cell = battle.ally_cell + Vector2i.RIGHT
	battle.cells[battle.enemy_cell] = true
	battle.fields.clear()
	battle.enemy_hp = 1
	controller.update_view()
	controller.choose_move(4)
	check(controller.aimed_slot == 4, "Ordinary targeting can arm the visible fallback action")
	controller.select_cell(battle.enemy_cell)
	BattleTest.settle(controller)
	check(controller.session == null and world.persistent_state.battle_progress().wins == 1 and world.persistent_state.affinity_tiles().is_empty(), "Fallback victory completes exactly once without manufacturing an affinity imprint")
	scene.queue_free()
	await process_frame
