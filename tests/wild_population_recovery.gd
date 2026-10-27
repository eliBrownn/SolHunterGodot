extends SceneTree
var checks := 0
var failures := 0

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func _initialize() -> void:
	create_timer(90).timeout.connect(func() -> void: quit(1))
	run.call_deferred()

func step(state: ExpeditionState, count: int) -> void:
	for index in range(count):
		state.advance_time(0.75)

func resolve(world: Node2D, member: Dictionary, outcome: String, imprint: Dictionary = {}) -> void:
	var state: ExpeditionState = world.persistent_state
	var serial := state.begin_battle(member.id)
	check(serial > 0 and state.complete_battle(serial, 1 if outcome == "victory" else 44, outcome, 3, imprint), "An authoritative outcome resolves once before recovery runs")
	world.rebuild_world()

func run() -> void:
	var scene: Node3D = (load("res://scenes/world_3d.tscn") as PackedScene).instantiate()
	scene.wild_recovery_settings = WildRecoverySettings.new()
	scene.wild_recovery_settings.interval_ticks = 3
	scene.sighting_settings = SightingSettings.new()
	scene.sighting_settings.movement_enabled = false
	scene.encounter_settings = EncounterSettings.new()
	scene.encounter_settings.automatic_contact = false
	root.add_child(scene)
	var world: Node2D = scene.world
	world.smoke_mode = false
	world.new_expedition(17)
	var state: ExpeditionState = world.persistent_state
	var sightings: Node3D = scene.sightings
	var recovery: Node = scene.wild_recovery
	check(WildRecoverySettings.new().interval_ticks == 2400 and scene.wild_recovery_settings.valid(), "Inspector recovery policy uses the verified source default and accepts the short fixture")
	var invalid := WildRecoverySettings.new()
	invalid.interval_ticks = -1
	check(not invalid.valid(), "Invalid recovery timing is rejected")
	var first: Dictionary = sightings.members[0].duplicate()
	var original := state.individual_view(first.id)
	var base: String = first.id
	world.cell = first.home + Vector2i.LEFT
	world.destination = world.cell
	world.rebuild_world()
	scene.battles.open_choice()
	scene.battles.choose(0)
	check(state.remember_population_territory(first.home, [base]), "A complete authored home can be cached before depletion")
	state.record_sol_discovery(first.id, "Seedmote", "An earlier individual.", first.home)
	resolve(world, first, "retreat")
	check(state.wild_population_view().is_empty() and state.wild_available(first.id), "Retreat does not deplete or schedule replacement")
	var imprint := {"winner": "air", "tiles": [AffinityImprint.key(first.home)], "fields": {}, "interval": 8}
	resolve(world, first, "victory", imprint)
	var tile_history := state.affinity_tiles()
	var queued := state.wild_population_view()
	check(queued[base].generation == 1 and queued[base].ready_at == 3 and not queued[base].active, "Victory schedules one saved successor deadline")
	check(not state.wild_available(first.id) and state.individual_view(first.id) == original, "Defeated original remains intact and unavailable, not resurrected or deleted")
	check(state.population_summary(first.home).available == 0, "Population summaries exclude the exhausted individual")
	var before := state.snapshot()
	for index in range(3):
		sightings.rebuild()
		state.wild_population_view()
		state.home_occupant(base)
	check(state.snapshot() == before and sightings.members.size() == 2, "Render rebuilds and read queries cannot advance deadlines or create a successor")
	check(recovery.describe_home(first.home).contains("exploration time"), "Home inspection explains the active-time recovery wait")
	world.paused = true
	world._process(30.0)
	check(state.activity_tick() == 0 and state.wild_population_view() == queued, "Pausing cannot age the saved wildlife deadline")
	world.paused = false
	step(state, 2)
	check(state.home_occupant(base).is_empty(), "No successor appears before the full delay")
	var path := "user://wild-recovery-%d.json" % Time.get_ticks_usec()
	world.save_game(path)
	var saved := state.snapshot()
	world.load_game(path)
	state = world.persistent_state
	check(state.snapshot() == saved and state.wild_population_view()[base].ready_at == 3, "Loading preserves the exact remaining wait without adding time or resetting it")
	world.cell = first.home
	world.destination = world.cell
	step(state, 1)
	check(not state.wild_population_view()[base].active and state.home_occupant(base).is_empty(), "A player standing on the due home blocks birth")
	check(recovery.describe_home(first.home).contains("clear ground"), "A due occupied home reports that it is waiting for space")
	world.cell = first.home + Vector2i.LEFT
	world.destination = first.home
	world.moving = true
	step(state, 1)
	check(state.home_occupant(base).is_empty(), "A reserved player movement destination also blocks birth")
	world.moving = false
	world.destination = world.cell
	step(state, 1)
	var successor := state.home_occupant(base)
	check(successor == SolIdentityContract.make(17, first.home, "seedmote", 1) and successor != first.id, "An unoccupied due home admits exactly one distinct successor identity")
	check(state.individual_view(first.id) == original and state.individual_view(successor).generation == 1, "Successor admission preserves the complete original record")
	check(state.affinity_tiles() == tile_history and state.has_discovery(first.id), "Replacement does not reset battle imprints or erase the old sighting")
	check(state.movebook(successor).equipped.size() == 4, "A newborn receives its own authored movebook in the same commit")
	state.remember_population_territory(first.home, [base]) # Runtime census definitions are deliberately not saved.
	check(state.population_summary(first.home).available == 1 and sightings.members.size() == 3, "Current generation restores the population projection and world view")
	var old_target := {"id": first.id, "name": first.entry.name, "cell": first.home, "distance": 1}
	scene.encounters.open_encounter(old_target)
	scene.battles.begin_battle(old_target)
	check(scene.encounters.active_target.is_empty() and scene.battles.session == null, "Stale encounter targets cannot redirect to a successor")
	scene.encounters.approach_nearest()
	check(scene.encounters.active_target.get("id") == successor, "Manual approach selects the actual successor identity")
	scene.encounters.battle_button.pressed.emit()
	check(scene.battles.session != null and scene.battles.enemy_id == successor, "A recovered home supports a real new battle using the successor's own movebook")
	scene.battles.retreat()
	var born := state.snapshot()
	world.save_game(path)
	world.load_game(path)
	state = world.persistent_state
	check(state.snapshot() == born and state.home_occupant(base) == successor, "Reload retains the admitted generation and its moves exactly")
	step(state, 20)
	check(state.home_occupant(base) == successor and state.counts().individuals == 5, "Long elapsed time cannot accumulate extra births at an occupied home")
	check(state.record_sol_discovery(successor, "Seedmote", "A new local individual.", first.home), "A successor can receive its own saved notable sighting")
	check(state.discovery_entries().size() == 2, "Old and new individuals retain separate Field Notes")
	var next_member: Dictionary = {}
	for member in sightings.members:
		if member.id == successor:
			next_member = member
	resolve(world, next_member, "victory")
	check(state.wild_population_view()[base].generation == 2 and not state.wild_population_view()[base].active, "Defeating a successor schedules the next generation, not the original")
	step(state, 3)
	check(state.home_occupant(base) == SolIdentityContract.make(17, first.home, "seedmote", 2), "The home remains repeatable across multiple generation cycles")
	verify_legacy_and_validation(state, base)
	var guard: Dictionary = sightings.members[2].duplicate()
	world.cell = guard.home + Vector2i.LEFT
	world.destination = world.cell
	world.rebuild_world()
	scene.encounter_settings.automatic_contact = true
	for index in range(3):
		state.consume_battle_grace()
	scene.encounters.safe_steps = 0
	scene.encounters.refresh_warning()
	scene.encounters.warning_presented = true
	var blocked := {"winner": "earth", "tiles": [AffinityImprint.key(guard.home)], "fields": {AffinityImprint.key(guard.home): {"kind": "barrier", "direction": [1, 0]}}, "interval": 4}
	resolve(world, guard, "victory", blocked)
	step(state, 3)
	check(state.home_occupant(guard.id).is_empty(), "Recovering terrain barriers postpone a due local birth")
	world.cell = Vector2i(-100, -100)
	world.destination = world.cell
	step(state, 9)
	check(state.home_occupant(guard.id).is_empty() and state.environment_view(guard.home, {}).conditions.is_empty(), "Distant due homes wait for a local visit even after terrain recovers")
	var dormant := state.snapshot()
	world.save_game(path)
	world.load_game(path)
	state = world.persistent_state
	check(state.snapshot() == dormant and not state.wild_population_view()[guard.id].active, "Loading a distant matured deadline cannot activate a successor")
	world.cell = guard.home + Vector2i.LEFT
	world.destination = world.cell
	scene.encounters.warning_id = guard.id
	scene.encounters.warning_presented = true
	step(state, 1)
	var new_guard := state.home_occupant(guard.id)
	check(not new_guard.is_empty() and state.environment_view(guard.home, {}).affinity == "earth", "Birth waits for terrain recovery without undoing its permanent affinity")
	for index in range(3):
		state.consume_battle_grace()
	scene.encounters.refresh_warning()
	check(scene.encounters.warning_id == new_guard and not scene.encounters.warning_presented, "A replacement guard requires its own fresh warning instead of inheriting the old acknowledgement")
	if capture_enabled():
		world.smoke_mode = true
		world.rebuild_world()
		await capture("successor")
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(path + suffix):
			DirAccess.remove_absolute(path + suffix)
	scene.free()
	print("WILD RECOVERY: %d checks, %d failures." % [checks, failures])
	quit(0 if failures == 0 else 1)

func verify_legacy_and_validation(state: ExpeditionState, base: String) -> void:
	var snapshot := state.snapshot()
	var legacy := snapshot.duplicate(true)
	legacy.version = 7
	legacy.erase("wild_population")
	var old := ExpeditionState.restore(legacy, 17)
	check(old != null and old.wild_population_view().is_empty() and old.snapshot().individuals == snapshot.individuals, "Legacy saves preserve history without inventing depletion dates")
	var current := old.home_occupant(base)
	old.configure_wild_recovery(3)
	check(old.acquire(current, "party"), "Acquisition preserves the current successor as an owned individual")
	var owned := old.individual_view(current)
	check(not old.wild_population_view()[base].active, "Successful acquisition also schedules a delayed replacement")
	old.configure_wild_recovery(0)
	step(old, 3)
	var definition := SolSpeciesDefinition.new()
	definition.species_id = "seedmote"
	definition.lineage_id = "family_010"
	definition.class_id = "verdant"
	var library: MoveLibrary = preload("res://resources/move_library.tres")
	var next := old.activate_wild_home(base, definition, "earth", library.book("seedmote"), true)
	check(not next.is_empty() and old.individual_view(current) == owned, "Disabling new waits does not cancel an existing saved commitment or reuse an owned individual")
	old.acquire(next, "sealed")
	check(old.schedule_historical_recovery(base) == false, "Zero-delay tuning disables new historical waits")
	old.configure_wild_recovery(3)
	check(old.schedule_historical_recovery(base) and old.wild_population_view()[base].ready_at == old.activity_tick() + 3, "Re-enabling starts a full historical wait instead of guessing an old capture date")
	var pending := old.snapshot()
	check(ExpeditionState.restore(JSON.parse_string(JSON.stringify(pending)), 17).snapshot() == pending, "Pending and active generation records normalize through JSON exactly")
	for field in ["generation", "ready_at", "active"]:
		var bad := snapshot.duplicate(true)
		bad.wild_population[base][field] = "invalid"
		check(ExpeditionState.restore(bad, 17) == null, "Malformed population ledger fields reject before restore")
	var bad := snapshot.duplicate(true)
	bad.wild_population[base].ready_at = state.activity_tick() + 1
	check(ExpeditionState.restore(bad, 17) == null, "An active successor cannot have a future birth deadline")
	for field in ["generation", "ready_at"]:
		bad = snapshot.duplicate(true)
		bad.wild_population[base][field] = -1
		check(ExpeditionState.restore(bad, 17) == null, "Negative generation/deadline data cannot enter the live state")
	bad = snapshot.duplicate(true)
	bad.wild_population[base].active = false
	check(ExpeditionState.restore(bad, 17) == null, "A pending birth cannot duplicate an already existing individual")
	bad = snapshot.duplicate(true)
	bad.wild_population["999:8:0:seedmote"] = bad.wild_population[base].duplicate()
	check(ExpeditionState.restore(bad, 17) == null, "A population home must belong to the saved world seed")

func capture_enabled() -> bool:
	return OS.get_cmdline_user_args().has("--capture-recovery") and DisplayServer.get_name() != "headless"

func capture(name: String) -> void:
	DirAccess.make_dir_recursive_absolute("res://artifacts/recovery")
	for frame in range(4):
		await process_frame
	await RenderingServer.frame_post_draw
	get_root().get_texture().get_image().save_png("res://artifacts/recovery/%s.png" % name)
