extends SceneTree

var checks := 0
var failures := 0

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func _initialize() -> void:
	create_timer(120).timeout.connect(func() -> void: quit(1))
	run.call_deferred()

func press(world: Node2D, key: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = key
	event.pressed = true
	world.handle_input(event)

func config() -> BattleSettings:
	var source: BattleSettings = load("res://resources/battle_settings.tres")
	var settings := BattleSettings.new()
	for profile in source.starters:
		settings.starters.append(profile.duplicate(true))
	for profile in source.opponents:
		settings.opponents.append(profile.duplicate(true))
	return settings

func approach(world: Node2D, scene: Node3D, member_index: int = 0) -> void:
	var member: Dictionary = scene.sightings.members[member_index]
	world.cell = member.home + Vector2i.LEFT
	world.destination = world.cell
	world.moving = false
	world.rebuild_world()
	press(world, KEY_R)
	scene.encounters.battle_button.pressed.emit()

func play_to_victory(controller: Node) -> void:
	for step in range(100):
		if controller.session == null:
			return
		var battle: TacticalBattle = controller.session
		if battle.phase == "deployment":
			var best: Vector2i = battle.deployment_tiles()[0]
			for cell in battle.deployment_tiles():
				if TacticalBattle.distance(cell, battle.enemy_cell) < TacticalBattle.distance(best, battle.enemy_cell):
					best = cell
			controller.select_cell(best)
		elif battle.can_attack():
			controller.attack()
		else:
			var best := battle.ally_cell
			for cell: Vector2i in battle.reachable():
				if TacticalBattle.distance(cell, battle.enemy_cell) < TacticalBattle.distance(best, battle.enemy_cell):
					best = cell
			if best != battle.ally_cell:
				controller.select_cell(best)
			else:
				controller.wait_turn()

func run() -> void:
	var tuning := config()
	check(tuning.valid() and tuning.starters[0].display_name == "Bramblepup" and tuning.starters[1].display_name == "Ashkit" and tuning.starters[2].display_name == "Rillfin", "Default editable roster matches the source's explicit provisional trio")
	verify_domain(tuning)
	var scene: Node3D = (load("res://scenes/world_3d.tscn") as PackedScene).instantiate()
	scene.battle_settings = tuning
	root.add_child(scene)
	var world: Node2D = scene.world
	var controller: Node = scene.battles
	world.smoke_mode = true
	world.new_expedition(17)
	check(world.persistent_state.starter_view().is_empty(), "New expedition does not implicitly grant a starter")
	press(world, KEY_C)
	check(controller.choosing and world.paused and world.encounter_active, "C opens an explicit choice modal with world activity guarded")
	press(world, KEY_1)
	var starter: Dictionary = world.persistent_state.starter_view()
	check(not controller.choosing and not world.paused and starter.profile.species_id == "bramblepup" and world.persistent_state.individual_view(starter.id).location == "party", "Explicit keyboard choice creates one persistent owned companion")
	check(not world.persistent_state.choose_starter(tuning.starters[1].snapshot(), 1), "A second choice cannot duplicate or replace the original starter")
	tuning.starters[0].attack += 1
	check(world.persistent_state.starter_view().profile.attack != tuning.starters[0].attack, "Later profile edits do not reroll an existing starter's saved combat stats")
	tuning.starters[0].attack -= 1
	var path := "user://first-battle-%d.json" % Time.get_ticks_usec()
	world.save_game(path)
	var initial_bytes := FileAccess.get_file_as_string(path)
	approach(world, scene)
	check(controller.session != null and controller.session.phase == "deployment" and scene.encounters.battle_running, "Battle stages an enemy while the chosen ally remains sealed until deployment")
	var state: ExpeditionState = world.persistent_state
	var active_snapshot := state.snapshot()
	var forbidden := ExpeditionSave.snapshot(17, world.cell, false, false, 5, world.terrain.climate, active_snapshot)
	check(ExpeditionSave.write(forbidden, path) == ERR_INVALID_DATA and FileAccess.get_file_as_string(path) == initial_bytes, "Low-level writer rejects active battle snapshots without touching the previous save")
	world.save_game(path)
	world.load_game(path)
	check(world.persistent_state == state and controller.session != null and FileAccess.get_file_as_string(path) == initial_bytes, "World save/load cannot bypass the active encounter guard")
	var invalid := Vector2i(9999, 9999)
	controller.select_cell(invalid)
	check(controller.session.phase == "deployment", "Invalid release cannot consume deployment or advance turns")
	press(world, KEY_ENTER)
	check(controller.session != null and controller.session.phase == "active", "Enter confirms the highlighted release through the actual world input route")
	play_to_victory(controller)
	var result := state.battle_progress()
	check(controller.session == null and result.wins == 1 and result.serial == 1 and result.last_result.outcome == "victory" and not world.encounter_active and not world.paused, "The default Bramblepup completes a real victory and resumes exploration")
	check(state.starter_view().id == starter.id and state.starter_view().hp > 0 and state.starter_view().hp <= starter.profile.max_hp, "Victory preserves starter identity and remaining health")
	check(result.defeated.size() == 1 and not state.wild_available(result.last_result.enemy_id), "The exhausted opponent becomes unavailable without deleting its individual")
	var before := state.snapshot()
	controller.attack()
	controller.wait_turn()
	controller.retreat()
	check(state.snapshot() == before and not state.complete_battle(1, 1, "victory", 3), "Repeated terminal commands and receipts cannot award the outcome again")
	world.save_game(path)
	var victory_bytes := FileAccess.get_file_as_string(path)
	world.new_expedition(42)
	world.load_game(path)
	check(world.persistent_state.snapshot() == before and world.persistent_state.starter_view().id == starter.id, "Actual reload preserves starter, health, outcome counters, and exhausted target")
	world.load_game(path)
	check(world.persistent_state.battle_progress().wins == 1 and scene.sightings.members.size() == 2, "Repeated load cannot duplicate a victory or refill the same exhausted individual")
	state = world.persistent_state
	approach(world, scene, 0)
	check(controller.session != null, "The same starter can deploy against another available individual")
	press(world, KEY_ESCAPE)
	check(controller.session == null and state.battle_progress().retreats == 1 and state.battle_progress().wins == 1, "Retreat is available even before deployment and commits once")
	var enemy_profile: BattleProfile = tuning.opponents[0]
	var old_attack := enemy_profile.attack
	enemy_profile.attack = 1000
	approach(world, scene, 0)
	controller.select_cell(controller.session.deployment_tiles()[0])
	if controller.session != null:
		controller.wait_turn()
	check(controller.session == null and state.battle_progress().losses == 1 and state.starter_view().hp == 0 and world.cell == Vector2i.ZERO, "Exhaustion returns to the refuge with the same recoverable companion, not death")
	check(state.starter_view().id == starter.id and state.counts().individuals == 4, "Defeat preserves the complete collection and starter identity")
	enemy_profile.attack = old_attack
	press(world, KEY_H)
	check(state.starter_view().hp == starter.profile.max_hp and state.battle_progress().losses == 1, "Explicit refuge recovery restores health without rewriting the saved defeat receipt")
	world.save_game(path)
	var healed := state.snapshot()
	world.load_game(path)
	check(world.persistent_state.snapshot() == healed, "Recovery and all three terminal counters survive save/load exactly")
	verify_persistence(before, victory_bytes, path)
	verify_all_starters(tuning)
	world.new_expedition(17)
	press(world, KEY_C)
	press(world, KEY_ESCAPE)
	check(world.persistent_state.starter_view().is_empty() and not world.paused and not world.encounter_active, "Cancelling the companion chooser grants nothing and releases the modal")
	approach(world, scene)
	check(controller.choosing and world.persistent_state.starter_view().is_empty(), "Battle without a companion opens explicit selection instead of granting a hidden default")
	press(world, KEY_3)
	check(controller.session != null and controller.session.ally.species_id == "rillfin", "Choosing from the encounter flow continues into deployment with that exact companion")
	controller.retreat()
	if OS.get_cmdline_user_args().has("--capture-battle") and DisplayServer.get_name() != "headless":
		world.new_expedition(17)
		press(world, KEY_C)
		await capture("starter")
		press(world, KEY_2)
		approach(world, scene)
		await capture("deployment")
		controller.select_cell(controller.session.deployment_tiles()[0])
		await capture("battle")
		controller.retreat()
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(path + suffix):
			DirAccess.remove_absolute(path + suffix)
	scene.free()
	print("FIRST PLAYABLE BATTLE: %d checks, %d failures." % [checks, failures])
	quit(0 if failures == 0 else 1)

func capture(name: String) -> void:
	DirAccess.make_dir_recursive_absolute("res://artifacts/battle")
	for frame in range(5):
		await process_frame
	await RenderingServer.frame_post_draw
	get_root().get_texture().get_image().save_png("res://artifacts/battle/%s.png" % name)

func verify_domain(tuning: BattleSettings) -> void:
	var battle := TacticalBattle.prepare(WorldTerrain.new(17), Vector2i.ZERO, Vector2i(2, 0), tuning.starters[0].snapshot(), 44, tuning.opponents[1].snapshot(), tuning)
	check(battle != null and battle.deployment_tiles().size() > 0, "Arena staging finds connected legal release cells without changing terrain")
	check(not battle.deploy(Vector2i(2, 0)) and not battle.deploy(Vector2i.ZERO), "Deployment refuses occupied enemy and trainer cells")
	check(battle.deploy(Vector2i(1, 0)) and battle.remaining == 3, "Deployment costs no tactical movement and activates speed-based initiative")
	var hp := battle.enemy_hp
	check(not battle.move_ally(Vector2i(2, 0)) and battle.remaining == 3 and battle.enemy_hp == hp, "Invalid movement consumes neither budget nor action")
	check(battle.can_attack() and TacticalBattle.damage(battle.ally, battle.enemy) == 4, "Basic targeting and source physical damage formula share the execution preview")
	check(battle.attack() and battle.enemy_hp == hp - 4 and battle.turn == "ally", "A basic attack spends the action, activates the enemy, and returns the next ally turn")
	check(battle.retreat() and not battle.retreat() and not battle.attack(), "Terminal battle domain commands are idempotent")
	battle = TacticalBattle.prepare(WorldTerrain.new(17), Vector2i.ZERO, Vector2i(2, 0), tuning.starters[0].snapshot(), 44, tuning.opponents[1].snapshot(), tuning)
	for cell in battle.cells:
		battle.cells[cell] = true # Controlled arena fixture isolates action-budget legality.
	battle.deploy(Vector2i(1, 0))
	check(battle.move_ally(Vector2i(1, -1)) and battle.move_ally(Vector2i(2, -1)) and battle.move_ally(Vector2i(3, -1)) and battle.remaining == 0, "Several accepted movement inputs spend one shared three-cell turn budget")
	check(not battle.move_ally(Vector2i(3, -2)) and battle.can_attack(), "An exhausted movement budget still permits the one basic action but no extra movement")
	battle.cells[Vector2i(1, 1)] = false
	check(not battle.in_range(Vector2i(1, 0), Vector2i(1, 2), 2), "Targeting rejects a short attack through blocked terrain")
	var faster := tuning.opponents[1].snapshot()
	faster.speed = 1000
	battle = TacticalBattle.prepare(WorldTerrain.new(17), Vector2i.ZERO, Vector2i(2, 0), tuning.starters[0].snapshot(), 44, faster, tuning)
	battle.deploy(Vector2i(1, 0))
	check(battle.ally_hp < 44 and battle.turn == "ally", "A faster enemy activates after deployment before the first player action")

func verify_all_starters(tuning: BattleSettings) -> void:
	for index in range(3):
		var state := ExpeditionState.new(19)
		check(state.choose_starter(tuning.starters[index].snapshot(), index) and state.starter_view().profile.species_id == tuning.starters[index].species_id, "Every source starter option is explicitly selectable and persistent")
		var copy := ExpeditionState.restore(JSON.parse_string(JSON.stringify(state.snapshot(), "", true, true)), 19)
		check(copy != null and copy.snapshot() == state.snapshot(), "Each chosen starter survives an exact normalized JSON round trip")

func verify_persistence(snapshot: Dictionary, original: String, path: String) -> void:
	var legacy := snapshot.duplicate(true)
	legacy.version = 5
	legacy.erase("battle")
	legacy.erase("movebooks")
	legacy.erase("affinity_tiles")
	var old := ExpeditionState.restore(legacy, 17)
	check(old != null and old.starter_view().is_empty() and old.snapshot().individuals == legacy.individuals, "Old domain saves preserve owned history without inferring or rerolling a starter")
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(original)
	file.close()
	var malformed: Array[Dictionary] = []
	for field in ["hp", "serial", "profile", "defeated"]:
		var data := snapshot.duplicate(true)
		data.battle[field] = true
		malformed.append(data)
	var data := snapshot.duplicate(true)
	data.battle.active = true
	malformed.append(data)
	data = snapshot.duplicate(true)
	data.battle.wins += 1
	malformed.append(data)
	data = snapshot.duplicate(true)
	data.battle.profile.class_id = "wrong"
	malformed.append(data)
	for bad in malformed:
		check(ExpeditionState.restore(bad, 17) == null, "Malformed, active, or inconsistent starter/result records reject before restore")
		var save: Dictionary = JSON.parse_string(original)
		save.world_state = bad
		check(ExpeditionSave.write(save, path) == ERR_INVALID_DATA and FileAccess.get_file_as_string(path) == original, "Invalid outgoing battle progress preserves the previous valid slot")
