extends SceneTree
var failures := 0
var checks := 0
var settings: BattleSettings = preload("res://resources/battle_settings.tres")
var library: MoveLibrary = preload("res://resources/move_library.tres")

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	verify_potential()
	verify_persistence_and_training()
	verify_evolution_and_caps()
	verify_classes()
	await verify_live_controls()
	print("SOL STATS AND CLASSES: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)

func verify_potential() -> void:
	var first := SolStats.generate("17:0:0:bramblepup", "beast", settings.sol_stats, settings.class_buffs)
	check(first == SolStats.generate("17:0:0:bramblepup", "beast", settings.sol_stats, settings.class_buffs), "Individual rolls are reproducible")
	var center := 0
	var extremes := 0
	var totals := {}
	for index in range(600):
		var row := SolStats.generate("17:%d:0:bramblepup" % index, "beast", settings.sol_stats, settings.class_buffs)
		var total := 0
		for stat in SolStats.STATS:
			var value: int = row.ivs[stat]
			check(value >= 90 and value <= 110, "Every natural roll stays inside 90–110%")
			center += int(value >= 98 and value <= 102)
			extremes += int(value <= 92 or value >= 108)
			total += value
		totals[total] = true
	check(center > extremes * 2 and totals.size() > 10, "Potential clusters near 100% without a fixed total-strength budget")
	check(first.potency >= 5 and first.potency <= 10, "Beast rolls its saved 5–10% potency")

func verify_persistence_and_training() -> void:
	var state := ExpeditionState.new(17)
	check(state.choose_starter(settings.starters[0].snapshot(), 0), "Starter admits six IVs and class potency before use")
	var hero := state.active_sol_view()
	var traits := state.stat_view(hero.id)
	var original_ivs: Dictionary = traits.ivs.duplicate()
	check(SolStats.capacity(traits, 1) == {"stat": 50, "total": 150} and SolStats.capacity(traits, 2) == {"stat": 75, "total": 225} and SolStats.capacity(traits, 3) == {"stat": 100, "total": 300}, "Three-form training capacity is 50/75/100 percent, enough for three stats")
	traits.forms = 1
	check(SolStats.capacity(traits, 1).total == 300, "A single-form species gets full training capacity")
	check(not state.allocate_training(hero.id, "attack", 1), "Unearned training cannot be allocated")
	var definition := SolSpeciesDefinition.new()
	definition.species_id = "seedmote"
	definition.lineage_id = "family_010"
	definition.class_id = "verdant"
	for index in range(3):
		var id := state.register_individual(definition, Vector2i(100 + index, 0), "earth")
		var wild_traits := state.stat_view(id)
		check(wild_traits.earned == 0 and SolStats.spent(wild_traits) == 0, "Wild Sol has no training investment")
		var serial := state.begin_battle(id)
		check(not state.allocate_training(hero.id, "attack", 1), "Allocation is forbidden during battle")
		var enemy_level := 3 if index < 2 else 12
		check(state.complete_battle(serial, hero.hp, "victory", 0, {}, {"participated": true, "contributed": index > 0, "enemy_level": enemy_level}), "Participating result commits atomically")
		if index == 0:
			check(state.stat_view(hero.id).earned == 0, "Participation without effective contribution gives no training")
		check(not state.complete_battle(serial, hero.hp, "victory", 0), "Duplicate defeat cannot replay training rewards")
	var earned: int = state.stat_view(hero.id).earned
	check(earned > 5 and state.allocate_training(hero.id, "attack", 5), "Stronger opponents grant more training; earned points can be allocated")
	var allocated := state.active_sol_view()
	check(SolStats.bonus(state.stat_view(hero.id), "attack") == 0.5, "Training points resolve a separate bounded percentage")
	var before_reset_hp: int = allocated.hp
	var items := state.retraining_items()
	check(state.reset_training(hero.id) and state.retraining_items() == items - 1, "Redistribution consumes one limited retraining item")
	check(state.active_sol_view().hp <= before_reset_hp and state.stat_view(hero.id).earned == earned and SolStats.spent(state.stat_view(hero.id)) == 0, "Redistribution preserves earned points and cannot heal")
	check(not state.reset_training(hero.id) and state.retraining_items() == items - 1, "Empty reset consumes no item")
	check(state.stat_view(hero.id).ivs == original_ivs, "Growth, allocation, and redistribution preserve locked IVs")
	var saved := state.snapshot()
	check(ExpeditionState.valid_snapshot(saved, 17), "Resolved profiles and traits form a valid portable snapshot")
	var restored := ExpeditionState.restore(JSON.parse_string(JSON.stringify(saved)), 17)
	check(restored != null, "JSON save admits all individual traits")
	if restored != null:
		check(restored.snapshot() == saved, "Save/load exactly preserves IVs, class rolls, training and supply")
	var corrupt := saved.duplicate(true)
	corrupt.sol_stats[hero.id].ivs.attack = 111
	check(ExpeditionState.restore(corrupt, 17) == null, "Out-of-range IVs reject rather than reroll")
	corrupt = saved.duplicate(true)
	corrupt.sol_stats[hero.id].training.attack = 51
	check(ExpeditionState.restore(corrupt, 17) == null, "Over-cap training rejects")
	var legacy := saved.duplicate(true)
	legacy.version = 9
	check(ExpeditionState.restore(legacy, 17) == null, "Incompatible development stat state is rejected")
	check(ExpeditionState.restore(saved, 17).snapshot() == saved, "Current restoration preserves individual rolls without reapplying IV multipliers")

func fixture(hero_class: String, hero_potency: int, enemy_class: String = "", enemy_potency: int = 0) -> TacticalBattle:
	var battle := TacticalBattle.new()
	battle.ally = settings.starters[0].snapshot()
	battle.enemy = settings.opponents[1].snapshot()
	battle.ally.max_hp = 100
	battle.enemy.max_hp = 100
	battle.ally.attack = 40
	battle.enemy.defense = 0
	battle.ally.special_attack = 60
	battle.enemy.special_defense = 10
	battle.ally_hp = 100
	battle.enemy_hp = 100
	battle.ally_cell = Vector2i(1, 0)
	battle.enemy_cell = Vector2i(2, 0)
	battle.trainer = Vector2i(-1, -1)
	for x in range(-4, 7):
		for y in range(-4, 7):
			battle.cells[Vector2i(x, y)] = true
	battle.set_class_passives({"class_id": hero_class, "potency": hero_potency}, {"class_id": enemy_class, "potency": enemy_potency}, settings.class_buffs)
	battle.phase = "active"
	battle.queue.assign(["ally", "enemy"])
	battle.turn = "ally"
	return battle

func verify_classes() -> void:
	var move := library.find("strike")
	move.power = 0
	var battle := fixture("beast", 10)
	battle.tile_affinities[battle.ally_cell] = "earth"
	check(battle.damage_for("ally", move, battle.ally_cell) == 44, "Beast gets tile-affinity damage, independent of individual affinity")
	move.affinity = "water"
	check(battle.damage_for("ally", move, battle.ally_cell) == 40, "Beast gets no bonus for a mismatching move")
	move.affinity = "earth"
	move.category = "special"
	check(battle.damage_for("ally", move, battle.ally_cell) == 55, "Special attacks use Special Attack and Special Defense before the class bonus")
	move.category = "physical"
	battle = fixture("cinderkin", 5)
	for index in range(4):
		var expected := mini(15, (index + 1) * 5)
		check(battle.damage_for("ally", move, battle.ally_cell) == roundi(40 * (1 + expected / 100.0)), "Kindling preview uses next increment without mutation")
		battle.passives.landed("ally")
		battle.passives.end_turn("ally")
		battle.passives.begin_turn("ally")
	check(battle.passives.units.ally.kindling == 15, "Kindling retains its 15% cap")
	battle.passives.end_turn("ally")
	check(battle.passives.units.ally.kindling == 0, "A non-attacking turn resets Kindling")
	battle = fixture("stormforged", 10)
	battle.passives.moved("ally", 2)
	check(battle.damage_for("ally", move, battle.ally_cell) == 44, "Momentum rewards actual tiles traveled")
	battle = fixture("warborn", 10)
	check(battle.damage_for("ally", move, battle.ally_cell) == 44, "Warborn rewards adjacency")
	battle = fixture("wyrmkin", 10)
	check(battle.damage_for("ally", move, battle.ally_cell) == 44, "Wyrmkin rewards healthy targets")
	battle.enemy_hp = 75
	check(battle.damage_for("ally", move, battle.ally_cell) == 40, "Wyrmkin threshold is strictly above 75%")
	battle = fixture("umbral", 10)
	check(battle.damage_for("ally", move, battle.ally_cell) == 44, "Umbral rewards isolated enemies")
	battle.support_units.append({"side": "enemy", "cell": Vector2i(3, 0), "hp": 10})
	check(battle.damage_for("ally", move, battle.ally_cell) == 40, "An active nearby enemy ally disables isolation")
	battle = fixture("swarmkin", 10)
	check(battle.damage_for("ally", move, battle.ally_cell) == 40, "Party members outside the arena grant no Swarmkin bonus")
	battle.support_units.append({"side": "ally", "cell": Vector2i(3, 0), "hp": 10})
	check(battle.damage_for("ally", move, battle.ally_cell) == 44, "Swarmkin checks another active allied unit")
	battle = fixture("", 0, "mindweaver", 15)
	check(battle.damage_for("ally", move, battle.ally_cell) == 34, "Forethought protects the first damaging action")
	battle.passives.landed("ally")
	check(battle.damage_for("ally", move, battle.ally_cell) == 40, "Forethought consumes only on an executed hit")
	battle = fixture("", 0, "frostbound", 10)
	battle.enemy_hp = 50
	check(battle.damage_for("ally", move, battle.ally_cell) == 36, "Cold Resolve triggers at half HP")
	battle = fixture("", 0, "stonebound", 10)
	battle.passives.end_turn("enemy")
	check(battle.damage_for("ally", move, battle.ally_cell) == 36, "Stonebound protects after a stationary turn")
	battle.passives.moved("enemy", 1)
	check(battle.damage_for("ally", move, battle.ally_cell) == 40, "Movement removes Stonebound protection")
	battle = fixture("", 0, "wraithborn", 10)
	check(battle.damage_for("ally", move, Vector2i(-1, 0)) == 36, "Wraithborn protects against attacks at least three tiles away")
	battle = fixture("earthbound", 0)
	battle.fields[Vector2i(2, 0)] = {"kind": "rough"}
	check(battle.step_cost(Vector2i(1, 0), Vector2i(2, 0), "ally") == 1, "Earthbound pays normal rough-ground movement cost")
	battle.fields[Vector2i(2, 0)].kind = "barrier"
	check(not battle.passable(Vector2i(2, 0)), "Earthbound cannot walk through impassable ground")
	battle = fixture("skyborne", 2)
	check(battle.passives.move_bonus("ally") == 2, "Skyborne gets rolled first-turn movement")
	battle.passives.end_turn("ally")
	check(battle.passives.move_bonus("ally") == 0, "Skyborne first-turn bonus does not refresh")
	battle = fixture("verdant", 3)
	battle.ally_hp = 50
	for index in range(10):
		battle.passives.end_turn("ally")
	check(battle.ally_hp == 65, "Verdant regeneration respects the 15% per-battle ceiling")
	battle = fixture("", 0, "tideborn", 10)
	battle.passives.landed("enemy")
	check(battle.damage_for("ally", move, battle.ally_cell) == 36, "Undertow weakens the struck enemy against its Tideborn source")
	battle.passives.end_turn("ally")
	check(battle.damage_for("ally", move, battle.ally_cell) == 40, "Undertow expires at the end of the affected enemy turn")
	battle = fixture("blightborn", 10, "construct", 20)
	var debuff := library.find("rattle")
	check(battle.status_magnitude("enemy", debuff) == 8.0, "Construct reduces debuff magnitude")
	battle.statuses.enemy.defense_down = {"magnitude": 8.0, "turns": 2}
	check(battle.passives.damage_factor("ally", move, battle.ally_cell) == 1.1, "Blightborn detects stat reductions")
	battle = fixture("feyborn", 2)
	battle.ally_moves.assign([library.find("focus")])
	check(battle.execute_move("ally", 0, battle.ally_cell), "Feyborn can execute a real helpful stat buff")
	# Multi-action turns can still be open after Focus; count recipient turns only
	# after the casting turn's bookkeeping has completed.
	if battle.turn == "ally":
		battle.finish_turn()
	check(battle.statuses.ally.special_attack_up.turns == 5, "Feyborn adds rolled recipient turns without unbounded stacking")
	battle = fixture("eldritch", 0)
	check(battle.passives.damage_factor("ally", move, battle.ally_cell) == 1.0, "Unassigned Eldritch passive grants no invented damage effect")

func verify_evolution_and_caps() -> void:
	var state := ExpeditionState.new(17)
	state.choose_starter(settings.starters[0].snapshot(), 0)
	var hero := state.active_sol_view()
	state.admit_movebook(hero.id, library.book("bramblepup"))
	var fixture_save := state.snapshot()
	fixture_save.sol_stats[hero.id].earned = 150
	state = ExpeditionState.restore(fixture_save, 17)
	for stat in ["attack", "defense", "speed"]:
		check(state.allocate_training(hero.id, stat, 50), "First form can fully invest its stage allowance in three stats")
	check(not state.allocate_training(hero.id, "special_attack", 1) and not state.allocate_training(hero.id, "attack", 1), "Both total and per-stat training caps are enforced")
	var ivs: Dictionary = state.stat_view(hero.id).ivs.duplicate()
	var potency: int = state.stat_view(hero.id).potency
	var previous_book := state.movebook(hero.id)
	var evolved := SolSpeciesDefinition.new()
	evolved.species_id = "fixture_bramble_form_two"
	evolved.lineage_id = "family_001"
	evolved.class_id = "beast"
	evolved.ordinary_form = 2
	var profile := settings.starters[0].snapshot()
	profile.species_id = evolved.species_id
	profile.max_hp = 60
	check(state.evolve_companion(hero.id, evolved, profile, library.book("bramblepup")), "An explicitly authored ordinary evolution preserves stable individual identity")
	check(state.stat_view(hero.id).ivs == ivs and state.stat_view(hero.id).potency == potency and state.stat_view(hero.id).earned == 150, "Evolution preserves IVs, class potency and earned training")
	check(SolStats.capacity(state.stat_view(hero.id), 2).total == 225 and state.movebook(hero.id) == previous_book, "Evolution unlocks capacity without free points or lost remembered/equipped moves")
	check(ExpeditionState.restore(JSON.parse_string(JSON.stringify(state.snapshot())), 17) != null, "Evolved species and original birth identity survive portable saves")
	var single := ExpeditionState.new(17)
	single.choose_starter(settings.starters[0].snapshot(), 0, 1)
	var id: String = single.active_sol_view().id
	fixture_save = single.snapshot()
	fixture_save.sol_stats[id].earned = 300
	single = ExpeditionState.restore(fixture_save, 17)
	for stat in ["max_hp", "attack", "special_attack"]:
		check(single.allocate_training(id, stat, 100) and SolStats.bonus(single.stat_view(id), stat) == 10.0, "Final form allows full 10% training in exactly three concentrated stats")
	check(not single.allocate_training(id, "speed", 1), "No budget remains after three fully invested stats")
	var weak := SolSpeciesDefinition.new()
	weak.species_id = "fixture_weak"
	weak.lineage_id = "fixture_weak_line"
	weak.class_id = "beast"
	fixture_save = single.snapshot()
	fixture_save.collection.owned[id].profile = SolStats.resolve(fixture_save.sol_stats[id], 30)
	fixture_save.collection.owned[id].hp = 10
	fixture_save.battle.profile = fixture_save.collection.owned[id].profile.duplicate(true)
	fixture_save.battle.hp = 10
	fixture_save.sol_stats[id].earned = 0
	for stat in SolStats.STATS:
		fixture_save.sol_stats[id].training[stat] = 0
	fixture_save.collection.owned[id].profile = SolStats.resolve(fixture_save.sol_stats[id], 30)
	fixture_save.battle.profile = fixture_save.collection.owned[id].profile.duplicate(true)
	single = ExpeditionState.restore(fixture_save, 17)
	var opponent := single.register_individual(weak, Vector2i(200, 0), "earth")
	var serial := single.begin_battle(opponent)
	check(single.complete_battle(serial, 10, "victory", 0, {}, {"participated": true, "contributed": true, "enemy_level": 20}) and single.stat_view(id).earned == 0, "An opponent ten levels weaker awards no training")

func verify_live_controls() -> void:
	var scene: Node3D = load("res://scenes/world_3d.tscn").instantiate()
	root.add_child(scene)
	var world: Node2D = scene.world
	world.smoke_mode = true
	world.new_expedition(17)
	var state: ExpeditionState = world.persistent_state
	state.choose_starter(settings.starters[0].snapshot(), 0)
	var hero := state.active_sol_view()
	var target: String = scene.sightings.members[0].id
	var serial := state.begin_battle(target)
	check(state.complete_battle(serial, hero.hp, "victory", 0, {}, {"participated": true, "contributed": true, "enemy_level": 3}), "Live companion earns distributable training through the outcome authority")
	world.menu.open("sols")
	world.menu.sol_screen.set_tab("training")
	var rows: VBoxContainer = scene.battles.loadout.embedded_rows
	var saw_exact := false
	var attack_add: Button
	for child in rows.get_children():
		if child is HBoxContainer and child.get_child_count() == 3:
			var label: Label = child.get_child(0)
			saw_exact = saw_exact or (label.text.contains("IV ") and label.text.contains("training +"))
			if label.text.begins_with("Attack "):
				attack_add = child.get_child(1)
	check(saw_exact and attack_add != null and not attack_add.disabled, "Real companion screen shows exact potential and enables earned training allocation")
	if attack_add != null:
		attack_add.pressed.emit()
	check(state.stat_view(hero.id).training.attack == 1, "Actual training button changes the persistent allocation")
	var reset: Button
	for child in rows.get_children():
		if child is Button and child.text.begins_with("Reset training"):
			reset = child
	check(reset != null and not reset.disabled, "Real reset control displays available limited supply")
	if reset != null:
		reset.pressed.emit()
		for child in world.hud.get_children():
			if child is ConfirmationDialog and child.title == "Reset training?":
				child.confirmed.emit()
	check(state.stat_view(hero.id).training.attack == 0 and state.retraining_items() == 2, "Confirmed reset returns points and consumes exactly one item")
	if OS.get_cmdline_user_args().has("--capture-stats") and DisplayServer.get_name() != "headless":
		DirAccess.make_dir_recursive_absolute("res://artifacts/stats")
		for index in range(4):
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://artifacts/stats/individual-stats.png")
	world.menu.close()
	scene.free()
