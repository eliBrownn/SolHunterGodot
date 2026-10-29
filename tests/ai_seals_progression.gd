extends SceneTree
const BattleTest = preload("res://tests/battle_test_support.gd")
var checks := 0
var failures := 0
var library: MoveLibrary = preload("res://resources/move_library.tres")
var settings: BattleSettings = preload("res://resources/battle_settings.tres")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func _initialize() -> void:
	create_timer(120).timeout.connect(func() -> void: quit(1))
	run.call_deferred()

func fixture() -> TacticalBattle:
	var battle := TacticalBattle.prepare(WorldTerrain.new(17), Vector2i.ZERO, Vector2i(3, 0), settings.starters[0].snapshot(), 44, settings.opponents[1].snapshot(), settings)
	for at in battle.cells:
		battle.cells[at] = true
		battle.protected_cells[at] = false
	battle.deploy(Vector2i(1, 0))
	battle.set_movebooks(library.book("bramblepup"), library.book("seedmote"))
	return battle

func run() -> void:
	var battle := fixture()
	var before := [battle.fields.duplicate(true), battle.activity.duplicate(), battle.ally_hp, battle.enemy_hp, battle.enemy_cell, battle.remaining]
	var plan := battle.plan_enemy()
	for repeat in range(4):
		check(battle.plan_enemy() == plan, "Enemy plans have stable ties")
	check(before == [battle.fields, battle.activity, battle.ally_hp, battle.enemy_hp, battle.enemy_cell, battle.remaining], "Intent planning is read-only")
	check(battle.can_use_for("enemy", plan.slot, plan.target, plan.cell), "Planned move passes shared legality")
	check(plan.cell == battle.enemy_cell, "Equal useful attacks prefer no movement")
	battle.fields[battle.enemy_cell] = {"kind": "heat", "direction": Vector2i.RIGHT, "round": 0, "expires": 8}
	check(battle.plan_enemy().cell != battle.enemy_cell, "Enemy leaves damaging terrain when a safe equally useful attack exists")
	battle = fixture()
	battle.enemy_moves = [library.find("heat")]
	plan = battle.plan_enemy()
	check(plan.slot == 0 and battle.enemy_intent().contains("Heat"), "Field-only enemy previews its actual equipped terrain move")
	battle.turn = "enemy"
	battle.queue.assign(["enemy", "ally"])
	battle.remaining = battle.movement_allowance("enemy")
	battle.actions_remaining = battle.action_points
	battle.auto_enemy()
	var terrain_uses := battle.log.filter(func(line: String) -> bool: return line.contains("shapes shared terrain")).size()
	check(terrain_uses > 0 and terrain_uses <= 3 and battle.activity.get("fire") == terrain_uses and not battle.fields.is_empty(), "Enemy records each affordable terrain move exactly once within the shared budget")
	battle = fixture()
	battle.enemy_moves = [library.find("mend")]
	var healthy_plan := battle.plan_enemy()
	check(healthy_plan.slot == -1 or battle.moves_for("enemy")[healthy_plan.slot].effect != "heal", "Full-health healing cannot cause buff camping; a weak fallback remains available")
	battle.enemy_hp -= 6
	check(battle.plan_enemy().slot == 0, "Wounded enemy can choose an effective heal")
	battle = fixture()
	check(is_equal_approx(battle.capture_chance(), 0.295), "Basic Seal preview uses source full-health distance-two chance")
	var full_chance := battle.capture_chance()
	battle.enemy_hp = 1
	check(battle.capture_chance() > full_chance, "Weakening the target raises capture odds")
	check(not battle.attempt_capture(NAN) and battle.capture_attempts == 0, "Invalid capture roll does not spend an action")
	check(battle.attempt_capture(0.0) and battle.phase == "captured" and battle.capture_attempts == 1, "Successful Seal resolves the battle")
	check(battle.activity.is_empty() and not battle.participated, "Seal is not an affinity move or XP participation action")
	check(not battle.attempt_capture(0.0) and battle.capture_attempts == 1, "Terminal capture cannot replay")
	battle = fixture()
	check(battle.attempt_capture(0.999) and battle.capture_attempts == 1 and not battle.activity.is_empty(), "Failed Seal grants the enemy an activation")
	battle = fixture()
	battle.phase = "deployment"
	check(battle.capture_chance() == 0 and not battle.attempt_capture(0), "Cannot capture before release")
	verify_growth()
	await verify_live()
	print("AI SEALS PROGRESSION: %d checks, %d failures." % [checks, failures])
	quit(0 if failures == 0 else 1)

func verify_growth() -> void:
	var policy := ProgressionSettings.new()
	check(policy.valid(), "Default Inspector progression policy validates")
	var row := CollectionProgress.entry(settings.starters[0].snapshot(), 20)
	var original := row.duplicate(true)
	row = CollectionProgress.grow(row, 89, policy.parameters())
	check(row.profile.level == 3 and row.xp == 89, "Level-three cumulative threshold requires ninety XP")
	row = CollectionProgress.grow(row, 1, policy.parameters())
	check(row.profile.level == 4 and row.xp == 90, "Threshold advances exactly once without spending cumulative XP")
	check(row.profile.max_hp == original.profile.max_hp + 2 and row.hp == 22 and row.profile.attack == original.profile.attack + 1, "Level-up applies source base stat and health growth")
	var gates := library.levels_for("bramblepup", [4, 8, 14])
	check(gates.anchor == 4 and gates.wind == 8 and gates.charge == 14 and gates.strike == 1, "Owner milestones gate species moves without changing affinity eligibility")
	var book := library.book("bramblepup")
	var equipped: Array = book.equipped.duplicate()
	row.unlocks = gates
	var state := ExpeditionState.new(17)
	state.learn_earned_moves(row, book, library.definitions())
	check(book.learned.has("anchor") and not book.learned.has("wind") and book.equipped == equipped, "Level-up remembers an unlocked move without replacing four equipped moves")
	book.equipped.pop_back()
	row.profile.level = 8
	state.learn_earned_moves(row, book, library.definitions())
	check(book.learned.has("wind") and book.equipped.has("wind") and book.equipped.size() == 4, "New unlock fills a vacancy and may differ from the Sol affinity")
	policy.level_cap = 4
	row = CollectionProgress.grow(row, 1000, policy.parameters())
	check(row.profile.level == 8 and row.xp == 90, "Lowered runtime cap cannot downgrade an existing Sol or discard XP")
	policy.unlock_levels = PackedInt32Array([8, 4, 14])
	check(not policy.valid(), "Invalid Inspector unlock ordering rejects")

func approach(scene: Node3D, member: Dictionary) -> void:
	var world: Node2D = scene.world
	world.cell = member.home + Vector2i.LEFT
	world.destination = world.cell
	world.moving = false
	world.rebuild_world()
	scene.encounters.approach_nearest()
	scene.encounters.battle_button.pressed.emit()

func verify_live() -> void:
	var scene: Node3D = (load("res://scenes/world_3d.tscn") as PackedScene).instantiate()
	scene.sighting_settings = SightingSettings.new()
	scene.sighting_settings.movement_enabled = false
	root.add_child(scene)
	var world: Node2D = scene.world
	world.smoke_mode = true
	world.new_expedition(17)
	var controller: Node = scene.battles
	controller.open_choice()
	controller.choose(0)
	var state: ExpeditionState = world.persistent_state
	var starter := state.active_sol_view()
	check(not state.transfer_companion(starter.id, "storage"), "Cannot store the only party companion")
	check(not state.relocate_owned(starter.id, "storage"), "Legacy relocation API cannot bypass the last-party safeguard")
	check(not state.learn_move(starter.id, library.find("anchor")), "Future move cannot be learned by bypassing UI")
	var member: Dictionary = scene.sightings.members[0].duplicate(true)
	var prior_record := state.individual_view(member.id)
	var prior_book := state.movebook(member.id)
	approach(scene, member)
	check(controller.session != null, "Real encounter starts for capture")
	var serial: int = controller.serial
	BattleTest.settle(controller)
	controller.select_cell(controller.session.deployment_tiles()[0])
	BattleTest.settle(controller)
	controller.session.enemy_hp = 7
	controller.update_view()
	check(controller.capture_button.text.contains("%") and controller.capture_button.tooltip_text.to_lower().contains("unlimited") and not controller.capture_button.disabled, "Seal chance stays visible while testing supply is explained on hover")
	if screenshots():
		await capture("seal-preview")
	var invalid := {"capture": {"profile": {}, "hp": 7, "unlocks": {}}}
	var active_before := state.snapshot()
	check(not state.complete_battle(serial, starter.hp, "captured", 3, {}, invalid) and state.snapshot() == active_before, "Malformed capture packet is rejected atomically")
	check(controller.session.attempt_capture(0), "Deterministic accepted roll exercises real capture commit")
	controller.after_command()
	var owned := state.companion_view(member.id)
	check(controller.session == null and state.battle_progress().captures == 1 and not owned.is_empty(), "Successful result adds one companion and one receipt")
	check(owned.hp == 7 and owned.profile.affinity == prior_record.affinity and state.movebook(member.id) == prior_book, "Capture preserves profile affinity, remaining health and exact movebook")
	check(state.individual_view(member.id).home == prior_record.home and state.individual_view(member.id).generation == prior_record.generation, "Captured individual retains home identity and generation")
	check(state.relationship_view(member.id).trust == null and not state.wild_available(member.id), "Sealing grants ownership without inventing trust or leaving a wild duplicate")
	check(state.companion_view(starter.id).xp == 0 and owned.xp == 0, "Capture gives neither participant nor captured target battle XP")
	check(state.wild_population_view().has(member.id), "Captured home enters normal saved replacement wait")
	check(not state.complete_battle(serial, starter.hp, "captured", 3), "Capture receipt cannot replay")
	if screenshots():
		await capture("seal-result")
	check(state.select_companion(member.id) and state.active_sol_view().id == member.id, "Captured individual can be chosen for deployment")
	check(state.transfer_companion(starter.id, "storage") and not state.select_companion(starter.id), "Stored companion stays remembered but cannot deploy")
	check(not state.transfer_companion(member.id, "storage"), "Selected last party companion cannot be stored")
	controller.open_choice()
	check(controller.loadout.opened and controller.loadout.identity == member.id, "Companions panel opens on selected captured individual")
	if screenshots():
		await capture("companions")
	controller.loadout.close()
	var path := "user://ai-seals-progression-%d.json" % Time.get_ticks_usec()
	world.save_game(path)
	var saved := state.snapshot()
	world.new_expedition(99)
	world.load_game(path)
	state = world.persistent_state
	check(state.snapshot() == saved and state.active_sol_view().id == member.id, "Actual save/reload preserves collection, selected identity, health, gates and movebooks")
	var malformed := saved.duplicate(true)
	malformed.collection.selected = starter.id
	check(ExpeditionState.restore(malformed, 17) == null, "Stored active identity is rejected during save admission")
	malformed = saved.duplicate(true)
	malformed.collection.owned[member.id].hp = 1001
	check(ExpeditionState.restore(malformed, 17) == null, "Corrupt captured HP rejects during save admission")
	var legacy := saved.duplicate(true)
	legacy.version = 8
	check(ExpeditionState.restore(legacy, 17) == null, "Incompatible development collection state is rejected")
	check(ExpeditionState.restore(saved, 17).snapshot() == saved, "Current collection preserves captured identity, storage, health and progression exactly")
	var next: Dictionary = scene.sightings.members[0].duplicate(true)
	approach(scene, next)
	check(controller.session != null and controller.session.ally == owned.profile and controller.session.ally_hp == 7, "Next battle deploys captured stats and health rather than regenerating a starter")
	controller.retreat()
	BattleTest.settle(controller)
	check(state.companion_view(member.id).xp == 0, "Retreat cannot award XP")
	verify_rewards_and_capacity(state, controller)
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(path + suffix):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path + suffix))
	scene.free()

func verify_rewards_and_capacity(state: ExpeditionState, controller: Node) -> void:
	var hero := state.active_sol_view()
	var policy := ProgressionSettings.new()
	policy.threshold_factor = 1
	check(state.configure_progression(policy), "Changed Inspector XP curve connects to durable victory growth")
	var equipped: Array = state.movebook(hero.id).equipped.duplicate()
	var species := SolSpeciesDefinition.new()
	species.species_id = "seedmote"
	species.lineage_id = "family_010"
	species.class_id = "verdant"
	for index in range(8):
		var id := state.register_individual(species, Vector2i(100 + index, 0), "earth")
		state.admit_movebook(id, library.book("seedmote"))
		var serial := state.begin_battle(id)
		if index < 6:
			var packet := {"profile": settings.opponents[1].snapshot(), "hp": 10, "unlocks": library.levels_for("seedmote", [4, 8, 14])}
			check(state.complete_battle(serial, hero.hp, "captured", 0, {}, {"capture": packet}), "Repeated capture admits a new identity")
			check(state.individual_view(id).location == ("party" if index < 5 else "storage"), "Six-member party overflow goes to storage")
		else:
			check(state.complete_battle(serial, hero.hp, "victory", 0, {}, {"participated": index == 7, "enemy_level": 3, "move_definitions": library.definitions()}), "Victory result commits with explicit participation evidence")
			check(state.active_sol_view().xp == (13 if index == 7 else 0), "Only participating victory grants source four plus three times enemy level XP")
	check(not state.transfer_companion(state.starter_view().id, "party"), "Party cannot exceed six through storage transfer")
	check(state.active_sol_view().profile.level == 4 and state.active_sol_view().hp == hero.hp + state.active_sol_view().profile.max_hp - hero.profile.max_hp, "Real participating victory advances multiple levels and retains bounded health growth")
	check(state.movebook(hero.id).learned.has("anchor") and state.movebook(hero.id).equipped == equipped, "Atomic victory learns earned species move while retaining the full equipped four")
	check(state.companion_view(state.starter_view().id).xp == 0, "Inactive stored starter receives no shared XP")
	check(ExpeditionState.valid_snapshot(state.snapshot(), 17), "Capture, storage, growth and receipt state remains portable")
	check(ExpeditionState.restore(JSON.parse_string(JSON.stringify(state.snapshot())), 17).snapshot() == state.snapshot(), "XP, growth and learned unlock normalize through JSON exactly")
	var too_many := state.snapshot()
	too_many.individuals[state.starter_view().id].location = "party"
	check(ExpeditionState.restore(too_many, 17) == null, "Seven-member party is rejected on save admission")
	controller.refresh_companion()

func screenshots() -> bool:
	return OS.get_cmdline_user_args().has("--capture-progression") and DisplayServer.get_name() != "headless"

func capture(name: String) -> void:
	DirAccess.make_dir_recursive_absolute("res://artifacts/progression")
	for frame in range(4):
		await process_frame
	await RenderingServer.frame_post_draw
	get_root().get_texture().get_image().save_png("res://artifacts/progression/%s.png" % name)
