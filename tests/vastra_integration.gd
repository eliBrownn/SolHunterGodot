extends SceneTree
const BattleTest = preload("res://tests/battle_test_support.gd")
var checks := 0
var failures := 0
var library: MoveLibrary = preload("res://resources/move_library.tres")
var settings: BattleSettings = preload("res://resources/battle_settings.tres")

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)

func _initialize() -> void:
	run.call_deferred()

func fixture() -> TacticalBattle:
	var battle := TacticalBattle.prepare(WorldTerrain.new(17), Vector2i.ZERO, Vector2i(3, 0), settings.starters[0].snapshot(), 44, settings.opponents[1].snapshot(), settings)
	for cell in battle.cells:
		battle.cells[cell] = true
		battle.protected_cells[cell] = false
	battle.deploy(Vector2i(1, 0))
	battle.automatic_enemies = false
	return battle

func run() -> void:
	var state := ExpeditionState.new(17)
	check(state.set_environment(Vector2i.ZERO, {"overload": -20, "concentration": 80}), "Negative restorative overload is admitted independently of concentration")
	var restored := ExpeditionState.restore(JSON.parse_string(JSON.stringify(state.snapshot())), 17)
	check(restored != null and restored.environment_view(Vector2i.ZERO, {}).overload == -20, "Signed overload survives a JSON save round trip")
	for invalid in [-101, 101, true, NAN, -0.5]:
		check(not state.set_environment(Vector2i.ZERO, {"overload": invalid}), "Invalid signed overload rejects atomically")
	var policy := {"interval": 2, "points": 3, "work_limit": 1}
	state.advance_environment(policy)
	for index in range(2):
		state.advance_time(0.75)
	state.advance_environment(policy)
	check(state.environment_view(Vector2i.ZERO, {}).overload == -17 and state.environment_view(Vector2i.ZERO, {}).concentration == 80, "Negative overload moves toward zero without draining concentration")
	var before := state.snapshot()
	check(state.advance_environment(policy) == 0 and state.snapshot() == before, "Recovery cannot repeat in the same activity tick")
	var command := {"actor_kind": "player", "actor_id": "test", "sequence": 1, "kind": "disturbance", "cell": [0, 0], "harvest_amount": 0, "overload_delta": 4}
	var receipt := state.apply_human_activity(command)
	check(not receipt.is_empty() and receipt.overload == -13, "Human disturbance can consume restorative conditions without forcing overload positive")
	before = state.snapshot()
	check(state.apply_human_activity(command).replayed and state.snapshot() == before, "Human receipt replay remains safe with negative values")
	var battle := fixture()
	battle.ally_moves = [library.find("mend")]
	var hp := battle.ally_hp
	check(battle.use_move(0, battle.ally_cell) and battle.ally_hp == hp and battle.tile_overloads[battle.ally_cell] < 0, "Full-health healing changes only the affected environment")
	check(battle.vastra_overloads.size() == 1 and not battle.vastra_overloads.has(AffinityImprint.key(battle.enemy_cell)), "Self restoration does not affect distant cells")
	battle = fixture()
	battle.ally_moves = [library.find("strike")]
	check(battle.use_move(0, battle.enemy_cell) and battle.tile_overloads[battle.enemy_cell] > 0 and not battle.tile_overloads.has(battle.ally_cell), "Aggressive Vastra damage overloads its actual target, not the caster")
	battle = fixture()
	var physical := library.find("strike")
	physical.vastra_powered = false
	battle.ally_moves = [physical]
	check(battle.use_move(0, battle.enemy_cell) and battle.vastra_overloads.is_empty(), "Explicitly non-Vastra physical attacks leave environmental overload unchanged")
	battle = fixture()
	var field := library.find("heat")
	field.aggressive = true
	battle.ally_moves = [field]
	check(battle.use_move(0, Vector2i(2, 1)), "Aggressive area ability executes")
	check(battle.vastra_overloads.size() == battle.field_area(Vector2i(2, 1)).size(), "Area overload covers exactly the ability's affected tiles")
	var moves := battle.activity.duplicate()
	var signed_before := battle.vastra_overloads.duplicate()
	check(not battle.use_move(0, Vector2i(900, 900)) and battle.vastra_overloads == signed_before and battle.activity == moves, "Illegal ability does not leave environmental effects")
	battle = fixture()
	var move := library.find("strike")
	var base := battle.damage_for("ally", move, battle.ally_cell)
	battle.tile_affinities[battle.ally_cell] = AffinityImprint.canonical(battle.ally.affinity)
	battle.tile_concentrations[battle.ally_cell] = 100
	check(battle.environmental_bonus("ally", battle.ally_cell) > 0 and battle.damage_for("ally", move, battle.ally_cell) > base, "Individual-affinity terrain matching scales outgoing damage with concentration")
	battle.tile_concentrations[battle.ally_cell] = 0
	check(battle.environmental_bonus("ally", battle.ally_cell) == 0, "Matching depleted terrain grants no environmental bonus")
	var tuning := VastraSettings.new()
	var low := VastraCombat.restoration_factor(-25, tuning)
	var high := VastraCombat.restoration_factor(-50, tuning)
	check(low > 0 and high > low and high < low * 2 and high < tuning.restoration_max_bonus, "Restorative recovery benefits have diminishing returns and remain bounded")
	check(VastraCombat.restoration_factor(50, tuning) == 0, "Positive overload cannot grant a restoration benefit")
	var snapshot := state.snapshot()
	snapshot.version = 15
	check(ExpeditionState.restore(snapshot, 17) == null, "Old schema cannot masquerade as signed overload state")
	battle = fixture()
	battle.ally_moves = [library.find("mend")]
	battle.tile_overloads[battle.ally_cell] = VastraCombat.MIN_OVERLOAD
	check(not battle.use_move(0, battle.ally_cell), "Full HP and saturated restoration reject a no-effect heal")
	battle.ally_hp -= 1
	check(battle.use_move(0, battle.ally_cell), "An injured target can still heal on saturated restorative ground")
	battle = fixture()
	battle.ally_moves = [library.find("strike")]
	battle.tile_overloads[battle.enemy_cell] = 99
	check(battle.use_move(0, battle.enemy_cell) and battle.tile_overloads[battle.enemy_cell] == 100, "Each aggressive application saturates safely at the upper bound")
	await verify_live()
	print("VASTRA INTEGRATION: %d checks, %d failures." % [checks, failures])
	quit(0 if failures == 0 else 1)

func verify_live() -> void:
	var scene: Node3D = load("res://scenes/world_3d.tscn").instantiate()
	root.add_child(scene)
	var world: Node2D = scene.world
	world.smoke_mode = true
	world.new_expedition(17)
	var controller: Node = scene.battles
	controller.open_choice()
	controller.choose(0)
	var state: ExpeditionState = world.persistent_state
	var member: Dictionary = scene.sightings.members[0]
	var serial := state.begin_battle(member.id)
	var hero := state.active_sol_view()
	var details := {"vastra_overloads": {"1:0": -40, "3:0": 6}}
	var bad := {"vastra_overloads": {"1:0": -40, "3:0": -101}}
	var before := state.snapshot()
	check(serial > 0 and not state.complete_battle(serial, hero.hp, "retreat", 3, {}, bad) and state.snapshot() == before, "Invalid combat environmental result rolls back the entire outcome")
	check(state.complete_battle(serial, hero.hp, "retreat", 3, {}, details), "Combat environmental result commits with the outcome")
	before = state.snapshot()
	check(not state.complete_battle(serial, hero.hp, "retreat", 3, {}, details) and state.snapshot() == before, "Completed combat cannot replay environmental effects")
	check(state.environment_view(Vector2i(1, 0), {}).overload == -40 and state.environment_view(Vector2i(3, 0), {}).overload == 6, "Both signed combat effects reach the exploration state")
	var path := "user://vastra-integration-%d.json" % Time.get_ticks_usec()
	var save := ExpeditionSave.snapshot(17, world.cell, false, false, world.terrain.generation_version, world.terrain.climate, state.snapshot(), world.terrain.relief)
	check(ExpeditionSave.write(save, path) == OK, "Signed environmental effects save to disk")
	var loaded := ExpeditionSave.read_save(path)
	check(not loaded.is_empty() and loaded.world_state.tile_deltas["1:0"].overload == -40, "Signed environmental effects load from disk")
	world.inspection_card.update_reading(Vector2i(1, 0), "Vastra", "Meadow", state.environment_view(Vector2i(1, 0), world.terrain.sample(Vector2i(1, 0))), "")
	check(world.inspection_card.readings.overload.bar.value == -40 and world.inspection_card.details_label.text.contains("Restorative"), "Inspection displays negative values and restorative meaning")
	serial = state.begin_battle(member.id)
	var home_key := AffinityImprint.key(member.home)
	var restoration := {"vastra_overloads": {home_key: -50}}
	check(state.complete_battle(serial, hero.hp, "victory", 3, {}, restoration), "Defeated wildlife can leave a restorative home")
	var data := state.snapshot()
	var home_id := SolIdentityContract.make(17, member.home, state.individual_view(member.id).species_id)
	var deadline := int(data.wild_population[home_id].ready_at)
	data.activity_tick = 8
	data.affinity_tiles[home_key] = {"affinity": "water", "conditions": {"wet": {"level": 3, "since": 0, "interval": 12, "direction": [1, 0]}}}
	var copy := ExpeditionState.restore(data, 17)
	var tuning := VastraSettings.new()
	check(copy != null, "Restorative habitat fixture validates")
	if copy != null:
		copy.advance_environment(tuning.parameters(), Callable(), tuning)
		check(copy.wild_population_view()[home_id].ready_at < deadline, "Negative overload accelerates existing wildlife recovery deadlines")
		var assisted := copy.snapshot()
		copy.advance_environment(tuning.parameters(), Callable(), tuning)
		check(copy.snapshot() == assisted, "Wildlife restoration assistance cannot repeat in the same tick")
		copy.recover_affinity_conditions(tuning)
		check(copy.affinity_tiles()[home_key].conditions.wet.level < 3, "Restorative habitat advances terrain-condition recovery")
	scene.queue_free()
	await process_frame
