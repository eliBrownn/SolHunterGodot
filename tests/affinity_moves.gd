extends SceneTree
const BattleTest = preload("res://tests/battle_test_support.gd")
var checks := 0
var failures := 0
var library: MoveLibrary = preload("res://resources/move_library.tres")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func _initialize() -> void:
	create_timer(120).timeout.connect(func() -> void: quit(1))
	run.call_deferred()

func fixture() -> TacticalBattle:
	var tuning: BattleSettings = preload("res://resources/battle_settings.tres")
	var battle := TacticalBattle.prepare(WorldTerrain.new(17), Vector2i.ZERO, Vector2i(3, 0), tuning.starters[0].snapshot(), 44, tuning.opponents[1].snapshot(), tuning)
	for at in battle.cells:
		battle.cells[at] = true
		battle.protected_cells[at] = false
	battle.deploy(Vector2i(1, 0))
	var hero := library.book("bramblepup")
	var foe := library.book("seedmote")
	battle.set_movebooks(hero, foe)
	return battle

func run() -> void:
	check(library.valid(), "Authored move library and explicit species pools validate")
	for move in library.moves:
		check(move.affinity in AffinityImprint.IDS, "Every authored move has one approved affinity")
	var battle := fixture()
	check(not battle.activity.size() and battle.imprint().is_empty(), "Deployment and movement do not contribute activity")
	battle.ally_moves = [library.find("mend")]
	check(battle.use_move(0, battle.ally_cell) and battle.vastra_overloads.get(AffinityImprint.key(battle.ally_cell), 0) < 0, "Healing at full health restores environmental Vastra and earns an imprint event")
	battle = fixture()
	battle.ally_moves = [library.find("mend")]
	battle.ally_hp -= 4
	check(battle.use_move(0, battle.ally_cell) and battle.activity.get("water") == 1, "Successful healing credits the move's Water affinity, not the Earth Sol")
	check(battle.affected.has(battle.ally_cell), "Self-healing affects the user's tile explicitly")
	battle = fixture()
	battle.record_move(library.find("heat"), [Vector2i(2, 0)])
	battle.record_move(library.find("current"), [Vector2i(2, 1)])
	check(battle.winner() == "water", "Latest successful move among tied leaders wins")
	battle.record_move(library.find("heat"), [Vector2i(2, 0)])
	battle.record_move(library.find("wind"), [Vector2i(1, 1)])
	check(battle.winner() == "fire", "A later non-leading affinity cannot override the activity winner")
	check(battle.imprint().tiles.size() == 3 and not battle.affected.has(battle.ally_cell), "All affected tiles are unioned without implicitly including the actor")
	var step := Vector2i(2, 0)
	battle.fields[step] = {"kind": "warp", "direction": Vector2i.RIGHT, "round": 1, "expires": 8}
	check(battle.step_cost(Vector2i(2, -1), step) == 0 and battle.step_cost(Vector2i(1, 0), step) == 2, "Void shared warp zones shorten one route direction and lengthen another")
	battle.fields[step].kind = "wet"
	check(battle.step_cost(Vector2i(1, 0), step) == 0 and battle.step_cost(Vector2i(3, 0), step) == 2, "Water currents aid and oppose movement equally for either team")
	battle.fields[step].kind = "barrier"
	check(not battle.paths(Vector2i(1, 0), 1, battle.enemy_cell).has(step), "Earth barriers reject ordinary traversal")
	battle.cells[Vector2i(2, 1)] = false
	var crossing := battle.paths(Vector2i(1, 1), 2, battle.enemy_cell, true)
	check(crossing.has(Vector2i(3, 1)) and not crossing.has(Vector2i(2, 1)), "Spectral crosses one thin obstacle and lands only on legal ground")
	battle.protected_cells[Vector2i(2, 1)] = true
	check(not battle.paths(Vector2i(1, 1), 2, battle.enemy_cell, true).has(Vector2i(3, 1)), "Spectral cannot phase through protected building geometry")
	battle = fixture()
	battle.ally_moves = [library.find("superpose")]
	check(battle.use_move(0, Vector2i(1, 2)) and battle.ally_cell == Vector2i(1, 2) and battle.activity.quantum == 1, "Quantum position is player-chosen, bounded and consumes the move action")
	battle = fixture()
	battle.ally_moves = [library.find("superpose")]
	battle.quantum_mode = "stabilize"
	check(not battle.use_move(0, Vector2i(1, 1)) and battle.activity.is_empty(), "Quantum stabilization without a field is a no-effect action")
	battle = fixture()
	battle.ally_moves = [library.find("entangle")]
	check(battle.use_move(0, Vector2i(1, 2)) and battle.links.get(Vector2i(1, 0)) == Vector2i(1, 2), "Quantum entanglement links two chosen legal locations")
	battle = fixture()
	battle.fields[battle.ally_cell] = {"kind": "charge", "direction": Vector2i.RIGHT, "round": battle.round_number, "expires": 8}
	var health := battle.ally_hp
	battle.tick_fields()
	check(battle.ally_hp == health, "Lightning charge is warned before its later-round discharge")
	battle.round_number += 1
	battle.tick_fields()
	check(battle.ally_hp == health - 2 and battle.disrupted.ally, "Lightning discharge damages and disrupts without matching-affinity immunity")
	await verify_live()
	print("AFFINITY MOVES: %d checks, %d failures." % [checks, failures])
	quit(0 if failures == 0 else 1)

func verify_live() -> void:
	var scene: Node3D = (load("res://scenes/world_3d.tscn") as PackedScene).instantiate()
	# Use an isolated editable catalog while exercising the current save contract.
	scene.sighting_settings = preload("res://resources/sighting_settings.tres").duplicate(true)
	root.add_child(scene)
	var world: Node2D = scene.world
	world.smoke_mode = true
	world.new_expedition(17)
	var controller: Node = scene.battles
	controller.open_choice()
	controller.choose(0)
	var state: ExpeditionState = world.persistent_state
	var hero := state.starter_view()
	var book := state.movebook(hero.id)
	check(book.equipped.size() == 4 and state.individual_view(hero.id).affinity == "earth", "New expeditions have canonical affinity and four saved moves")
	check(not state.learn_move(hero.id, library.find("charge")), "Species eligibility alone cannot bypass the new level unlock")
	check(not state.learn_move(hero.id, library.find("fin_strike")), "Moves outside the species pool cannot be learned")
	check(not state.equip_moves(hero.id, ["strike", "strike"]), "Duplicate equipped moves are rejected")
	check(state.equip_moves(hero.id, ["strike", "heat", "barrier", "current"]), "Four learned moves can be equipped outside battle")
	check(state.movebook(hero.id).learned.has("barrier"), "Reordering keeps all remembered moves intact")
	controller.open_choice()
	check(controller.loadout.opened and world.paused, "C after selection opens the actual outside-battle loadout panel")
	if OS.get_cmdline_user_args().has("--capture-affinities") and DisplayServer.get_name() != "headless":
		await capture("loadout")
	controller.loadout.close()
	var member: Dictionary = scene.sightings.members[0]
	world.cell = member.home + Vector2i.LEFT
	world.destination = world.cell
	world.rebuild_world()
	scene.encounters.approach_nearest()
	scene.encounters.battle_button.pressed.emit()
	check(not state.equip_moves(hero.id, ["strike"]), "Battle locks equipped and learned move mutations")
	BattleTest.settle(controller)
	controller.select_cell(controller.session.deployment_tiles()[0])
	BattleTest.settle(controller)
	var session: TacticalBattle = controller.session
	var target := session.ally_cell + Vector2i.DOWN
	controller.choose_move(1)
	BattleTest.settle(controller)
	controller.select_cell(target)
	BattleTest.settle(controller)
	check(session.activity.get("fire") == 1 and not session.fields.is_empty(), "Actual battle controls resolve a Fire move and record its own affinity")
	if OS.get_cmdline_user_args().has("--capture-affinities") and DisplayServer.get_name() != "headless":
		await capture("battle")
	var report := session.imprint()
	controller.retreat()
	BattleTest.settle(controller)
	var tiles := state.affinity_tiles()
	check(not tiles.is_empty() and tiles[report.tiles[0]].affinity == report.winner, "Retreat atomically commits the battle winner onto every affected tile")
	var before := state.snapshot()
	var detached := state.environment_view(Vector2i(int(report.tiles[0].split(":")[0]), int(report.tiles[0].split(":")[1])), {})
	detached.conditions.clear()
	check(state.snapshot() == before, "Environment inspection returns detached conditions rather than writable saved state")
	check(not state.complete_battle(1, hero.hp, "retreat", 3, report) and state.snapshot() == before, "Duplicate result receipts cannot repaint or refresh condition recovery")
	for at in tiles:
		check(tiles[at].affinity == report.winner, "All affected tiles share the battle-wide winner")
	var path := "user://affinity-moves-%d.json" % Time.get_ticks_usec()
	world.save_game(path)
	world.load_game(path)
	state = world.persistent_state
	check(state.snapshot() == before, "Saved learned/equipped moves, imprints and conditions survive an exact reload")
	var restored_current := ExpeditionState.restore(before, 17)
	check(restored_current != null and restored_current.starter_view().profile.affinity == "earth" and restored_current.starter_view().id == hero.id and restored_current.starter_view().hp == before.battle.hp, "Current signed-Vastra saves preserve starter identity, affinity and health")
	for pair in [["grove", "earth"], ["ember", "fire"], ["tide", "water"], ["gale", "air"]]:
		check(AffinityImprint.canonical(pair[0]) == pair[1], "Owner-approved legacy affinity alias is explicit")
	var malformed := before.duplicate(true)
	malformed.affinity_tiles[report.tiles[0]].conditions = {"wet": {"level": 3, "since": -1, "interval": 8, "direction": [1, 0]}}
	check(ExpeditionState.restore(malformed, 17) == null, "Invalid recovery timing rejects before replacing live state")
	malformed = before.duplicate(true)
	malformed.movebooks[hero.id].equipped.append("not_learned")
	check(ExpeditionState.restore(malformed, 17) == null, "Invalid fifth/unlearned move rejects before restoring")
	for outcome in ["victory", "exhaustion"]:
		var copy := ExpeditionState.restore(before, 17)
		var serial := copy.begin_battle(member.id)
		check(serial > 0 and copy.complete_battle(serial, 0 if outcome == "exhaustion" else 1, outcome, 3, report) and copy.affinity_tiles() == tiles, "Every terminal outcome uses the same atomic imprint commit")
	var bad_report := report.duplicate(true)
	bad_report.fields[report.tiles[0]] = {"kind": "heat", "direction": true}
	check(AffinityImprint.apply(tiles, bad_report, state.activity_tick(), ExpeditionState.MAX_TILE_DELTAS) == null, "Malformed field reports fail validation without partial writes")
	for tick in range(8):
		state.advance_time(0.75)
	var staged := false
	for row in state.affinity_tiles().values():
		for effect in row.conditions.values():
			staged = staged or int(effect.level) == 2
	check(staged, "Conditions recover gradually through saved stages rather than disappearing on load")
	for tick in range(16):
		state.advance_time(0.75)
	state.recover_affinity_conditions()
	for row in state.affinity_tiles().values():
		check(row.affinity == report.winner and row.conditions.is_empty(), "Gradual condition recovery never reverts persistent tile affinity")
	if OS.get_cmdline_user_args().has("--capture-affinities") and DisplayServer.get_name() != "headless":
		await capture("imprint")
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(path + suffix):
			DirAccess.remove_absolute(path + suffix)
	scene.free()

func capture(name: String) -> void:
	DirAccess.make_dir_recursive_absolute("res://artifacts/affinities")
	for frame in range(5):
		await process_frame
	await RenderingServer.frame_post_draw
	get_root().get_texture().get_image().save_png("res://artifacts/affinities/%s.png" % name)
