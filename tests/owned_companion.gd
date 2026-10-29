extends SceneTree

var checks := 0
var failures := 0
var air_capture_saved := false

func check(value: bool, description: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(description)

func _initialize() -> void:
	create_timer(120).timeout.connect(func() -> void: quit(1))
	run.call_deferred()

func put_player(world: Node2D, at: Vector2i) -> void:
	world.cell = at
	world.destination = at
	world.moving = false
	world.explorer.position = world.center(at)
	world.camera.position = world.explorer.position

func spend(companion: Node3D, seconds: float) -> void:
	for index in range(ceili(seconds / 0.1)):
		companion._process(0.1)

func run() -> void:
	var tuning := OwnedCompanionSettings.new()
	check(tuning.valid(), "Default owned-companion controls validate")
	var wall := {Vector2i(1, 0): true}
	var legal := func(a: Vector2i, b: Vector2i) -> bool: return not wall.has(b) and SolRoamingPolicy.distance(a, b) == 1
	var step := OwnedCompanionPolicy.next_step(Vector2i.ZERO, Vector2i(3, 0), {}, legal, tuning)
	check(step == Vector2i.UP, "Bounded follow route can start a legal detour around a wall")
	check(OwnedCompanionPolicy.next_step(Vector2i.ZERO, Vector2i(3, 0), {}, func(_a: Vector2i, _b: Vector2i) -> bool: return false, tuning) == Vector2i.ZERO, "Fully blocked companions wait instead of teleporting")
	check(OwnedCompanionPolicy.next_step(Vector2i.ZERO, Vector2i(1, 0), {}, legal, tuning) == Vector2i.ZERO, "Following stops beside the player")
	check(OwnedCompanionPolicy.next_step(Vector2i.ZERO, Vector2i.ZERO, {}, legal, tuning) == Vector2i.UP, "A player stepping onto the companion prompts a legal step aside")
	check(OwnedCompanionPolicy.next_step(Vector2i.ZERO, Vector2i(3, 0), {Vector2i.UP: true}, legal, tuning) == Vector2i.DOWN, "Wild/reserved cells cannot be used for a follow step")
	tuning.resume_distance = tuning.stop_distance
	check(not tuning.valid(), "Invalid stop/resume hysteresis rejects")
	tuning.resume_distance = 2
	var scene: Node3D = load("res://scenes/world_3d.tscn").instantiate()
	scene.sighting_settings = scene.sighting_settings.duplicate(true)
	scene.sighting_settings.wilderness_enabled = false
	scene.companion_settings = tuning
	root.add_child(scene)
	var world: Node2D = scene.world
	world.smoke_mode = true
	world.new_expedition(17)
	var companion: Node3D = scene.companion
	companion.set_process(false)
	check(companion.identity.is_empty(), "No unowned placeholder is shown before selection")
	var species: SolSpeciesRecord = preload("res://resources/sol_species/crown_ear.tres")
	check(world.persistent_state.choose_starter(species.battle_profile("air"), 0), "Fixture selects a real owned Crown-Ear through domain admission")
	var state: ExpeditionState = world.persistent_state
	var original := state.snapshot()
	companion._process(0.1)
	check(companion.identity == state.active_sol_view().id and companion.sprite.affinity == "air" and companion.sprite.get_meta("species_id") == species.species_id, "Exploration consumes the actual selected owned identity, species and affinity")
	check(companion.placed and world.terrain.fits(companion.cell) and SolRoamingPolicy.distance(companion.cell, world.cell) == 1, "Admission chooses legal ground adjacent to the player")
	var initial: Vector2i = companion.cell
	spend(companion, 5.0)
	check(companion.action == "moment" and companion.selected_behavior == "crown_ear_listen" and companion.cell == initial, "Inherited Crown-Ear idle branch triggers its approved listening gesture without moving")
	if DisplayServer.get_name() != "headless" and OS.get_cmdline_user_args().has("--companion-capture"):
		await process_frame
		await RenderingServer.frame_post_draw
		get_root().get_texture().get_image().save_png("res://artifacts/owned_companion.png")
	check(state.snapshot() == original, "Rest/personality moments never award trust, change ownership, or write movement state")
	var frozen_time: float = companion.elapsed
	world.paused = true
	spend(companion, 1)
	check(companion.elapsed == frozen_time and companion.cell == initial, "Pause freezes both follow movement and personality time")
	world.paused = false
	var walked := 0
	for x in range(1, 8):
		var destination := Vector2i(x, world.terrain.trail_y(x))
		# Complete a short legal exploration route; no follower relocation shortcuts.
		if not world.can_step(world.cell, destination):
			continue
		var previous: Vector2i = world.cell
		put_player(world, destination)
		world.player_step_completed.emit(previous, destination)
		for frame in range(12):
			var before: Vector2i = companion.cell
			companion._process(0.1)
			if not air_capture_saved and DisplayServer.get_name() != "headless" and OS.get_cmdline_user_args().has("--owned-air-capture") and companion.travel.mode() == "air":
				await process_frame
				await RenderingServer.frame_post_draw
				get_root().get_texture().get_image().save_png("res://artifacts/owned_companion_flight.png")
				air_capture_saved = true
			if before != companion.cell:
				walked += 1
				check(SolRoamingPolicy.distance(before, companion.cell) == 1 and world.can_step(before, companion.cell), "Every committed companion move uses a legal cardinal edge")
	check(walked >= 4 and SolRoamingPolicy.distance(companion.cell, world.cell) <= 2, "Selected companion follows the refuge-to-wilderness route and catches up")
	var target: Dictionary = scene.sightings.members[0]
	scene.encounters.approach_individual(target.id)
	check(world.encounter_active, "The route reaches a real wild encounter")
	var held: Vector2i = companion.cell
	frozen_time = companion.elapsed
	spend(companion, 1)
	check(not companion.sprite.visible and companion.cell == held and companion.elapsed == frozen_time, "Encounter entry hides and freezes the same owned follower without deploying it")
	scene.encounters.withdraw()
	spend(companion, 0.5)
	check(not world.encounter_active and companion.sprite.visible and companion.identity == state.active_sol_view().id, "Withdrawal restores the same selected owned individual")
	for x in range(6, -1, -1):
		var destination := Vector2i(x, world.terrain.trail_y(x))
		if world.can_step(world.cell, destination):
			var previous: Vector2i = world.cell
			put_player(world, destination)
			world.player_step_completed.emit(previous, destination)
			spend(companion, 1.2)
	check(world.cell.x == 0 and SolRoamingPolicy.distance(companion.cell, world.cell) <= 2 and companion.identity == state.active_sol_view().id, "Companion follows the legal return route to the refuge after the encounter")
	var local_cell: Vector2i = companion.cell
	world.rebuild_world()
	companion._process(0.1)
	check(companion.cell == local_cell, "View reconstruction/culling does not relocate a present companion")
	var path := "user://owned_companion_test.json"
	world.save_game(path)
	var identity: String = companion.identity
	var record := state.individual_view(identity)
	world.load_game(path)
	companion._process(0.1)
	check(companion.identity == identity and world.persistent_state.individual_view(identity) == record and world.persistent_state.collection_view().owned.size() == 1, "Current-format real save/load retains identity/ownership with no duplicate follower individual")
	check(companion.placed and SolRoamingPolicy.distance(companion.cell, world.cell) <= 1 and world.terrain.fits(companion.cell), "Load reconstructs a legal nearby ground presentation")
	var saved_cell: Vector2i = companion.cell
	var saved_time: float = companion.elapsed
	companion.settings.visible_radius = 4
	var player_home: Vector2i = world.cell
	put_player(world, player_home + Vector2i(30, 0))
	companion.sync_view(0)
	check(not companion.sprite.visible and companion.cell == saved_cell and companion.elapsed == saved_time, "Culling hides presentation without snapping position or spending time")
	put_player(world, player_home)
	companion.sync_view(0)
	check(companion.sprite.visible and companion.cell == saved_cell, "Returning into view restores the same physical position")
	companion.settings.visible_radius = 24
	# Ground-only body clearance remains authoritative even for an air-affinity species.
	companion.prepare_clearance(companion.cell)
	var blocked := Vector2(player_home) + Vector2(0.5, 0.5)
	companion.geometry.append(AABB(Vector3(blocked.x - 0.5, -10, blocked.y - 0.5), Vector3(1, 20, 1)))
	check(not companion.ground_step(companion.cell, player_home), "Air affinity cannot bypass ground body/scenery clearance")
	var empty_before: Dictionary = world.persistent_state.snapshot()
	companion.settings.enabled = false
	companion._process(0.1)
	check(not companion.visible and world.persistent_state.snapshot() == empty_before, "Disabling companion presentation never deletes or modifies the owned individual")
	companion.settings.enabled = true
	companion._process(0.1)
	check(companion.visible and companion.identity == identity, "Re-enabling presentation retains the same selected identity")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var bell := tuning.behavior_library.select("idle", {"species": "sol_species_0003", "class": "verdant", "affinity": "fire"})
	check(bell.id == "bellroot_tend", "Bellroot's approved tending moment reuses the idle hierarchy independently of affinity")
	if DisplayServer.get_name() != "headless":
		await process_frame
		await RenderingServer.frame_post_draw
	scene.environment.sky = null
	scene.queue_free()
	await process_frame
	if DisplayServer.get_name() != "headless":
		await process_frame
		await RenderingServer.frame_post_draw
	print("OWNED COMPANION: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
