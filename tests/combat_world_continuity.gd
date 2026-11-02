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

func capture(label: String) -> void:
	if not OS.get_cmdline_user_args().has("--capture-world"):
		return
	for frame in range(3): await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://artifacts/combat-world")
	root.get_texture().get_image().save_png("res://artifacts/combat-world/" + label + ".png")

func run() -> void:
	var scene: Node3D = load("res://scenes/world_3d.tscn").instantiate()
	BattleTest.use_turn_fixture(scene)
	scene.sighting_settings = SightingSettings.new()
	scene.sighting_settings.wilderness_enabled = false
	scene.sighting_settings.species_profiles_enabled = false
	scene.sighting_settings.movement_enabled = false
	scene.encounter_settings = EncounterSettings.new()
	scene.encounter_settings.automatic_contact = false
	scene.wild_recovery_settings = WildRecoverySettings.new()
	scene.wild_recovery_settings.interval_ticks = 3
	scene.wild_recovery_settings.local_radius = 32
	scene.vastra_settings = load("res://resources/vastra_settings.tres").duplicate(true)
	scene.vastra_settings.recovery_interval_ticks = 2
	root.add_child(scene)
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(960, 600)
	var world: Node2D = scene.world
	world.smoke_mode = false
	world.new_expedition(17)
	# Explicit clock steps isolate world activity from render timing.
	scene.process_mode = Node.PROCESS_MODE_DISABLED
	var state: ExpeditionState = world.persistent_state
	var sightings: Node3D = scene.sightings
	var controller: Node = scene.battles
	check(state.choose_starter(scene.battle_settings.starters[0].snapshot(), 0), "Create a companion through the persistent owner")
	var opponent: Dictionary = sightings.members[0]
	var depleted: Dictionary = sightings.members[1]
	var observer: Dictionary = sightings.members[2]
	# A second, unrelated home is already awaiting recovery when battle starts.
	var serial := state.begin_battle(depleted.id)
	check(serial > 0 and state.complete_battle(serial, int(state.active_sol_view().hp), "victory", 0), "Schedule an unrelated depleted home")
	sightings.rebuild()
	world.cell = opponent.home + Vector2i.LEFT
	world.destination = world.cell
	world.moving = false
	world.explorer.position = world.center(world.cell)
	world.camera.position = world.explorer.position
	world.rebuild_world()
	var at: Vector2i = opponent.home
	state.set_environment(at, {"overload": 20})
	scene.encounters.approach_individual(opponent.id)
	check(world.paused and world.encounter_active, "Encounter preview retains its existing explicit modal pause")
	scene.encounters.battle_button.pressed.emit()
	check(controller.session != null and not world.paused and world.encounter_active, "Combat takes input ownership without setting world pause")
	if controller.session == null:
		quit(1)
		return
	var battle: TacticalBattle = controller.session
	var player_cell: Vector2i = world.cell
	var opponent_row := state.roaming_view(opponent.id)
	var initial_seconds := state.activity_seconds()
	var initial_round: int = battle.round_number
	var observer_before := state.roaming_view(observer.id)
	scene.atmosphere_controller.update()
	var initial_phase: float = scene.atmosphere_controller.phase
	await capture("battle-start")
	# Keep the existing local working set; distant individuals remain bounded.
	scene.sighting_settings.movement_enabled = true
	var environment_before := int(state.environment_view(at, {}).overload)
	for step in range(12):
		world._process(ExpeditionContract.ACTIVITY_INTERVAL)
		sightings._process(ExpeditionContract.ACTIVITY_INTERVAL)
		scene.atmosphere_controller.update()
	check(is_equal_approx(state.activity_seconds() - initial_seconds, 9.0), "World clock advances once while waiting for battle commands")
	check(scene.atmosphere_controller.phase != initial_phase, "Day/weather presentation consumes the continuing world clock")
	check(int(state.environment_view(at, {}).overload) < environment_before, "Natural Vastra repair continues during battle")
	check(world.cell == player_cell and not world.moving, "Player stays under combat input ownership")
	world.advance_movement(1.0, Vector2.RIGHT)
	check(world.cell == player_cell and not world.moving, "Exploration movement cannot bypass active combat")
	check(battle.round_number == initial_round and battle.phase == "deployment", "Real world time does not spend tactical turns or deploy the ally")
	check(state.roaming_view(opponent.id) == opponent_row and state.wild_in_battle(opponent.id), "The actual opponent remains reserved from ordinary roaming")
	check(not state.record_roaming_step(opponent.id, at + Vector2i.RIGHT, "patrol"), "Persistent owner rejects a roaming write to the battler")
	var successor: String = state.home_occupant(depleted.id)
	check(not successor.is_empty() and successor != depleted.id, "An unrelated due wildlife home recovers during combat")
	check(not ExpeditionState.valid_snapshot(state.snapshot(), 17), "Background birth cannot make an active battle snapshot saveable")
	check(state.roaming_view(observer.id) == observer_before, "Out-of-range wildlife keeps its bounded activity behavior")
	check(scene.encounters.active_target.id == opponent.id and controller.session == battle, "Background activity cannot replace the active encounter")
	await capture("battle-world-advanced")
	# Complete a battle contribution against the environment's current reading.
	var key := AffinityImprint.key(at)
	battle.vastra_overloads[key] = int(controller.overload_baseline[key]) + 4
	var live_overload := int(state.environment_view(at, {}).overload)
	var player_chunk: Vector2i = world.terrain.chunk_of(world.cell)
	var terrain_view: Node2D = world.chunks[player_chunk].view
	var solid_view: Node3D = scene.solid_chunks[player_chunk]
	var rebuilds := [0]
	world.rebuilt.connect(func() -> void: rebuilds[0] += 1)
	controller.retreat()
	BattleTest.settle(controller)
	check(rebuilds[0] == 0, "Battle exit does not rebuild the overworld")
	check(is_instance_valid(terrain_view) and world.chunks[player_chunk].view == terrain_view, "Battle exit retains the actual loaded terrain chunk")
	check(is_instance_valid(solid_view) and scene.solid_chunks[player_chunk] == solid_view, "Battle exit retains the actual loaded scenery chunk")
	check(controller.session == null and int(state.environment_view(at, {}).overload) == live_overload + 4, "Completion adds combat overload without undoing concurrent natural repair")
	check(not world.paused and not world.encounter_active and controller.activity_reservations().is_empty(), "Battle exit clears input and cell reservations")
	# Battle near the middle home so the original first Sol is a local bystander.
	var successor_member: Dictionary = sightings.members_by_id.get(successor, {})
	if successor_member.is_empty():
		quit(1)
		return
	world.cell = sightings.current_cell(successor_member) + Vector2i.LEFT
	world.destination = world.cell
	world.explorer.position = world.center(world.cell)
	world.camera.position = world.explorer.position
	world.rebuild_world()
	scene.encounters.approach_individual(successor)
	scene.encounters.battle_button.pressed.emit()
	check(controller.session != null, "Recovered wildlife can enter the next normal battle")
	var bystander_before := state.roaming_view(opponent.id)
	var moved := false
	for step in range(16):
		world._process(ExpeditionContract.ACTIVITY_INTERVAL)
		sightings._process(ExpeditionContract.ACTIVITY_INTERVAL)
		var row := state.roaming_view(opponent.id)
		moved = moved or row.get("cell") != bystander_before.get("cell")
	check(moved and int(state.roaming_view(opponent.id).tick) > int(bystander_before.tick), "Unrelated local wildlife makes real movement decisions during combat")
	var member: Dictionary = sightings.members_by_id[opponent.id]
	check(member.motion.position != Vector2(bystander_before.cell[0], bystander_before.cell[1]), "Visible wildlife interpolation continues as well as its saved decisions")
	controller.retreat()
	BattleTest.settle(controller)
	world.toggle_pause()
	var frozen := state.snapshot()
	world._process(1.5)
	sightings._process(1.5)
	check(world.paused and state.snapshot() == frozen, "The explicit pause screen still freezes the world")
	world.toggle_pause()
	check(ExpeditionState.valid_snapshot(state.snapshot(), 17), "Continuing-world outcomes retain a valid persistent state")
	scene.queue_free()
	await process_frame
	print("COMBAT WORLD CONTINUITY: ", checks, " checks; ", failures, " failures")
	quit(0 if failures == 0 else 1)
