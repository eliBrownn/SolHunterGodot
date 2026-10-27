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

func position(world: Node2D, cell: Vector2i) -> void:
	world.cell = cell
	world.destination = cell
	world.moving = false
	world.progress = 0.0
	world.rebuild_world()

func walk(world: Node2D, direction: Vector2) -> void:
	world.advance_movement(float(world.expedition_parameters().move_seconds), direction)

func run() -> void:
	var scene: Node3D = (load("res://scenes/world_3d.tscn") as PackedScene).instantiate()
	scene.encounter_settings = EncounterSettings.new()
	scene.sighting_settings = SightingSettings.new()
	scene.sighting_settings.movement_enabled = false
	root.add_child(scene)
	var world: Node2D = scene.world
	var encounters: Node = scene.encounters
	world.new_expedition(17)
	var guard: Dictionary = scene.sightings.members[2]
	position(world, guard.home + Vector2i(-4, 0))
	var start: Vector2i = world.cell
	world.advance_movement(float(world.expedition_parameters().move_seconds) * 1.5, Vector2.RIGHT)
	check(world.cell == start + Vector2i.RIGHT and world.moving and is_equal_approx(world.progress, 0.5), "Entering warning range preserves the held direction and partial next stride")
	check(encounters.warning_id == guard.id and not encounters.warning_presented and not world.paused, "First hostile warning is nonmodal and initially unacknowledged")
	encounters.mark_warning_presented()
	check(encounters.warning_presented, "Visible uncovered warning acknowledgement arms later-contact eligibility")
	world.advance_movement(float(world.expedition_parameters().move_seconds) * 0.5, Vector2.RIGHT)
	check(not world.encounter_active and world.cell == guard.home + Vector2i(-2, 0), "A later noncontact step continues exploration")
	walk(world, Vector2.RIGHT)
	check(world.encounter_active and world.paused and encounters.active_target.id == guard.id and encounters.encounter_panel.visible, "A later completed contact step opens the same warned guard's encounter panel")
	var before: Dictionary = world.persistent_state.snapshot()
	world._process(1.5)
	check(world.persistent_state.snapshot() == before, "Encounter preview freezes activity and ecology")
	var path := "user://encounter-entry-%d.json" % Time.get_ticks_usec()
	var baseline := ExpeditionSave.snapshot(world.terrain.world_seed, world.cell, world.visited, world.returned, world.terrain.generation_version, world.terrain.climate, before)
	check(ExpeditionSave.write(baseline, path) == OK, "Test creates an independent pre-encounter exploration slot")
	var bytes := FileAccess.get_file_as_string(path)
	var state: ExpeditionState = world.persistent_state
	var terrain: WorldTerrain = world.terrain
	world.ask_new()
	check(not world.confirmation.visible and world.encounter_active, "The new-expedition confirmation cannot bypass the active preview guard")
	world.save_game(path)
	world.load_game(path)
	world.new_expedition(42)
	check(world.persistent_state == state and world.terrain == terrain and state.snapshot() == before and FileAccess.get_file_as_string(path) == bytes, "Active preview blocks world save/load/new-seed entry points before slot or state changes")
	check(not FileAccess.file_exists(path + ".tmp") and not FileAccess.file_exists(path + ".bak"), "Rejected preview persistence does not stage temporary data or rotate backups")
	encounters.observe_button.pressed.emit()
	encounters.observe_button.pressed.emit()
	check(state.discovery_entries().size() == 1 and state.relationship_view(guard.id) == null and state.individual_view(guard.id).location == "wild", "Encounter observation records once without trust, ownership, or battle outcomes")
	press(world, KEY_ESCAPE)
	check(not world.encounter_active and not world.paused and encounters.safe_steps == 3, "Escape withdraws safely and starts the configured successful-step protection")
	var remaining: int = encounters.safe_steps
	encounters.refresh_warning()
	check(encounters.warning_id.is_empty() and encounters.safe_steps == remaining, "Time/read refreshes do not spend withdrawal protection")
	walk(world, Vector2.LEFT)
	check(encounters.safe_steps == remaining - 1 and not world.encounter_active, "Only completed exploration steps spend withdrawal protection")
	position(world, guard.home + Vector2i(-1, 0))
	press(world, KEY_R)
	check(world.encounter_active and encounters.active_target.id == guard.id, "Deliberate R approach remains available during automatic-contact protection")
	encounters.withdraw_button.pressed.emit()
	encounters.safe_steps = 0
	world.new_expedition(17)
	guard = scene.sightings.members[2]
	position(world, guard.home + Vector2i(-2, 0))
	encounters.refresh_warning()
	world.journal_panel.show()
	encounters.mark_warning_presented()
	check(not encounters.warning_presented, "A covered journal state cannot acknowledge the warning")
	world.journal_panel.hide()
	walk(world, Vector2.RIGHT)
	check(not world.encounter_active, "Contact before warning presentation never forces an encounter")
	encounters.mark_warning_presented()
	encounters._process(0.0)
	check(not world.encounter_active, "Idle refresh after presentation cannot trigger contact")
	walk(world, Vector2.LEFT)
	check(not world.encounter_active, "A presented warning still permits retreat")
	position(world, guard.home + Vector2i(-4, 0))
	encounters.refresh_warning()
	check(encounters.warning_id.is_empty() and not encounters.warning_presented, "Leaving warning range clears target-specific presentation")
	world.new_expedition(17)
	var neutral: Dictionary = scene.sightings.members[1]
	position(world, neutral.home + Vector2i.LEFT)
	encounters.refresh_warning()
	check(encounters.warning_id.is_empty(), "The neutral authored Sol is not silently made hostile")
	press(world, KEY_R)
	check(world.encounter_active and encounters.active_target.id == neutral.id, "Player-initiated approach selects the current nearby neutral identity")
	encounters.withdraw()
	state = world.persistent_state
	state.acquire(neutral.id, "party")
	press(world, KEY_R)
	check(not world.encounter_active and state.individual_view(neutral.id).location == "party", "Owned individuals cannot be reselected or rerolled for an encounter")
	world.new_expedition(17)
	guard = scene.sightings.members[2]
	position(world, guard.home + Vector2i(-3, 0))
	encounters.refresh_warning()
	encounters.mark_warning_presented()
	world.save_game(path)
	world.load_game(path)
	encounters.refresh_warning()
	check(not encounters.warning_presented and not world.encounter_active, "Loading resets warning presentation instead of resuming an armed encounter")
	scene.encounter_settings.automatic_contact = false
	encounters.refresh_warning()
	check(encounters.warning_id.is_empty(), "Inspector automatic-contact switch disables hostile entry and warnings")
	scene.encounter_settings.enabled = false
	press(world, KEY_R)
	check(not world.encounter_active, "Inspector encounter switch disables deliberate entry")
	if OS.get_cmdline_user_args().has("--capture-encounter") and DisplayServer.get_name() != "headless":
		scene.encounter_settings.enabled = true
		scene.encounter_settings.automatic_contact = true
		world.new_expedition(17)
		guard = scene.sightings.members[2]
		position(world, guard.home + Vector2i(-3, 0))
		encounters.refresh_warning()
		DirAccess.make_dir_recursive_absolute("res://artifacts/encounter")
		for frame in range(5):
			await process_frame
		await RenderingServer.frame_post_draw
		get_root().get_texture().get_image().save_png("res://artifacts/encounter/warning.png")
		position(world, guard.home + Vector2i.LEFT)
		press(world, KEY_R)
		for frame in range(5):
			await process_frame
		await RenderingServer.frame_post_draw
		get_root().get_texture().get_image().save_png("res://artifacts/encounter/panel.png")
		encounters.withdraw()
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(path + suffix):
			DirAccess.remove_absolute(path + suffix)
	scene.free()
	print("ENCOUNTER INITIATION: %d checks, %d failures." % [checks, failures])
	quit(0 if failures == 0 else 1)
