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

func position(world: Node2D, cell: Vector2i) -> void:
	world.cell = cell
	world.destination = cell
	world.moving = false
	world.explorer.position = world.center(cell)
	world.camera.position = world.explorer.position

func response(reaction: String, separation: int, row: Dictionary, tick: int, tuning: SightingSettings) -> Dictionary:
	var result := SolRoamingPolicy.decide("fixture", Vector2i.ZERO, Vector2i.ZERO, Vector2i(separation, 0), reaction, row, tick, tuning)
	return {"action": result.action, "response": result.get("response", {}), "patrol": result.patrol}

func run() -> void:
	var tuning := SightingSettings.new()
	var row := response("Wary", 2, {"action": "idle"}, 1, tuning)
	check(row.action == "flee", "Avoidant Sol flees when approached too closely")
	row = response("Wary", 4, row, 2, tuning)
	check(row.action == "flee", "Flight persists beyond entry range until safe separation")
	row = response("Wary", 5, row, 3, tuning)
	check(row.action == "idle" and row.response.mode == "alert", "Safe avoidant Sol watches rather than reversing toward the player")
	row = response("Wary", 4, row, 4, tuning)
	check(row.action != "flee" and row.response.mode == "alert", "Small boundary movement cannot restart completed flight; safe local activity may resume")
	row = response("Wary", 6, row, 5, tuning)
	check(row.response.mode == "settling" and row.response.until == 5 + tuning.settle_ticks, "Disengagement starts the configured settling period")
	row = response("Wary", 4, row, 6, tuning)
	check(row.action == "idle" and row.response.mode == "settling", "Re-entering only the release band does not restart alertness")
	row = response("Wary", 2, row, 7, tuning)
	check(row.action == "flee" and row.response.mode == "alert", "A close approach interrupts settling immediately")
	row = response("Watching", 3, {"action": "idle"}, 1, tuning)
	check(row.action == "approach", "Neutral Sol cautiously approaches inside detection range")
	row = response("Watching", 2, row, 2, tuning)
	check(row.action == "idle", "Neutral Sol stops at comfortable spacing")
	row = response("Watching", 3, row, 2, tuning)
	check(row.action == "idle", "Reposition cooldown prevents rapid approach/rest switching")
	row = response("Watching", 3, row, 3, tuning)
	check(row.action == "approach", "Repositioning resumes after its configured cooldown")
	row = response("Watching", 4, row, 4, tuning)
	check(row.action == "idle" and row.response.mode == "alert", "Neutral attention does not turn into pursuit outside detection range")
	row = response("Guarding", 3, {"action": "idle"}, 1, tuning)
	for tick in range(2, 10):
		row = response("Guarding", 3 if tick % 2 == 0 else 4, row, tick, tuning)
		check(row.action == "guard" and row.response.mode == "alert", "Territory response remains stable across the detection boundary")
	row = response("Guarding", 6, row, 10, tuning)
	row = response("Guarding", 7, row, 10 + tuning.settle_ticks, tuning)
	check(row.action in ["idle", "patrol"] and row.response.is_empty() and not row.patrol.is_empty(), "A settled guard resumes the autonomous patrol/rest routine after withdrawal")
	tuning.reaction_release_distance = tuning.reaction_distance
	check(not tuning.valid(), "Release range must exceed alert entry range")
	tuning.reaction_release_distance = 6
	tuning.approach_resume_distance = tuning.comfort_distance
	check(not tuning.valid(), "Approach resumption must leave a comfort dead band")
	tuning.approach_resume_distance = 3
	var scene: Node3D = (load("res://scenes/world_3d.tscn") as PackedScene).instantiate()
	scene.sighting_settings = tuning
	tuning.wilderness_enabled = false
	tuning.species_profiles_enabled = false # Species/individual variation has a separate integration suite.
	scene.encounter_settings = EncounterSettings.new()
	scene.encounter_settings.automatic_contact = false
	root.add_child(scene)
	var world: Node2D = scene.world
	var sightings: Node3D = scene.sightings
	var encounters: Node = scene.encounters
	world.new_expedition(17)
	var neutral: Dictionary = sightings.members[1]
	position(world, neutral.home + Vector2i(-3, 0))
	world.persistent_state.advance_time(0.75)
	check(sightings.current_cell(neutral) != neutral.home and world.persistent_state.roaming_view(neutral.id).action == "approach", "Reaction policy moves a real neutral Sol on the exploration clock")
	sightings.sync_views(1.0)
	check(neutral.label.text.contains("Approaching curiously"), "World label describes the actual neutral reaction")
	position(world, neutral.home + Vector2i(-7, 0))
	world.persistent_state.advance_time(0.75)
	sightings.sync_views(1.0)
	check(neutral.label.visible and neutral.label.text.contains("Settling down"), "Disengagement remains readable outside the initial detection band")
	var before: Dictionary = world.persistent_state.snapshot()
	var path := "user://sol-player-reactions-%d.json" % Time.get_ticks_usec()
	world.save_game(path)
	check(FileAccess.file_exists(path), "Settling state can be saved through the real world save path")
	world.load_game(path)
	check(world.persistent_state.snapshot() == before, "Real save/load retains response mode and remaining settling deadline")
	var cell: Vector2i = sightings.current_cell(sightings.members[1])
	for field in ["mode", "until", "move_after"]:
		var bad := before.duplicate(true)
		bad.roaming[neutral.id].response[field] = true
		check(ExpeditionState.restore(bad, 17) == null, "Malformed response %s rejects without restoration" % field)
	var bad := before.duplicate(true)
	bad.roaming[neutral.id].response.until = before.activity_tick + 129
	check(ExpeditionState.restore(bad, 17) == null, "Unbounded settling deadlines reject")
	world.paused = true
	world._process(1.5)
	check(world.persistent_state.snapshot() == before, "Pause freezes saved response decisions and exploration time")
	world.paused = false
	for index in range(tuning.settle_ticks - 1):
		world.persistent_state.advance_time(0.75)
	check(sightings.current_cell(sightings.members[1]) == cell, "Loading does not shorten the remaining settling period")
	world.persistent_state.advance_time(0.75)
	check(world.persistent_state.roaming_view(neutral.id).action == "return", "Settled moved Sol begins a legal home return before patrol")
	world.persistent_state.acquire(neutral.id, "party")
	check(world.persistent_state.roaming_view(neutral.id).is_empty(), "Acquisition retires response memory with the same wild individual")
	world.new_expedition(17)
	var guard: Dictionary = sightings.members[2]
	position(world, guard.home + Vector2i(-2, 0))
	scene.encounter_settings.automatic_contact = true
	encounters.refresh_warning()
	encounters._process(2.0)
	check(encounters.warning_elapsed == 0 and not world.encounter_active, "An unpresented warning never accumulates eligibility time")
	encounters.mark_warning_presented() # Headless seam for the actual post-draw acknowledgement.
	encounters._process(0.25)
	world.hud.hide()
	encounters._process(2.0)
	check(is_equal_approx(encounters.warning_elapsed, 0.25), "Covered warning time cannot satisfy the delay")
	world.hud.show()
	world.menu.open()
	encounters._process(2.0)
	check(is_equal_approx(encounters.warning_elapsed, 0.25), "A live field menu cannot spend the uncovered-warning delay")
	world.menu.close()
	position(world, guard.home + Vector2i.LEFT)
	encounters.on_player_step(guard.home + Vector2i(-2, 0), world.cell)
	check(not world.encounter_active, "Contact before the minimum displayed warning time cannot trigger an encounter")
	encounters._process(0.5)
	check(not world.encounter_active and is_equal_approx(encounters.warning_elapsed, scene.encounter_settings.warning_delay_seconds), "Finishing the warning timer while idle cannot start an encounter")
	encounters.on_player_step(guard.home + Vector2i(-2, 0), world.cell)
	check(world.encounter_active and encounters.active_target.id == guard.id, "Only a later contact step after presentation and delay starts the warned encounter")
	encounters.withdraw()
	encounters.safe_steps = 0
	encounters.refresh_warning()
	encounters.mark_warning_presented()
	encounters._process(0.25)
	encounters.warning_id = "different-individual"
	encounters.refresh_warning()
	check(encounters.warning_id == guard.id and encounters.warning_elapsed == 0 and not encounters.warning_presented, "A changed target cannot inherit another warning's time or acknowledgement")
	world.new_expedition(17)
	guard = sightings.members[2]
	position(world, guard.home + Vector2i(-3, 0))
	world.persistent_state.advance_time(0.75)
	sightings.sync_views(1.0)
	check(guard.label.text.contains("Defending territory"), "Assertive reaction is explicit in the world label")
	encounters.refresh_warning()
	if OS.get_cmdline_user_args().has("--capture-reactions") and DisplayServer.get_name() != "headless":
		world.smoke_mode = true
		encounters.set_process(false)
		world.rebuild_world()
		sightings.sync_views(1.0)
		scene.sync_ground()
		DirAccess.make_dir_recursive_absolute("res://artifacts/reactions")
		for frame in range(5):
			await process_frame
		await RenderingServer.frame_post_draw
		get_root().get_texture().get_image().save_png("res://artifacts/reactions/guard.png")
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(path + suffix):
			DirAccess.remove_absolute(path + suffix)
	scene.free()
	print("SOL PLAYER REACTIONS: %d checks, %d failures." % [checks, failures])
	quit(0 if failures == 0 else 1)
