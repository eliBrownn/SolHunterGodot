extends SceneTree
## Main-entry resource/content checks. No wildlife/AI/policy switches are disabled.

var checks := 0
var failures := 0

func check(value: bool, description: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(description)

func _initialize() -> void:
	create_timer(120).timeout.connect(func() -> void: quit(1))
	run.call_deferred()

func run() -> void:
	var entry: String = ProjectSettings.get_setting("application/run/main_scene")
	var scene: Node3D = load(entry).instantiate()
	root.add_child(scene)
	var world: Node2D = scene.world
	var sightings: Node3D = scene.sightings
	check(scene.sighting_settings.resource_path == "res://resources/sol_world_sightings.tres", "F5 main entry selects the normal-world species rollout resource")
	check(scene.sighting_settings.valid() and scene.sighting_settings.enabled and scene.sighting_settings.species_profiles_enabled and scene.sighting_settings.wilderness_enabled and scene.sighting_settings.movement_enabled and scene.sighting_settings.wander_enabled, "Normal game keeps species hierarchy, wildlife and active routines enabled")
	check(not world.smoke_mode and scene.companion.settings.enabled, "Normal entry keeps live exploration and selected-owned presence enabled")
	var catalog: SolSpeciesCatalog = load("res://resources/sol_species/catalog.tres")
	var positions := {}
	for seed_value in [scene.expedition_settings.initial_seed, 17]:
		world.new_expedition(seed_value)
		var state: ExpeditionState = world.persistent_state
		var identities := {}
		for species in catalog.entries:
			var found: Array = sightings.members.filter(func(member: Dictionary) -> bool: return member.entry.species == species.species_id)
			check(found.size() == 1, "Each delivered species is admitted once in normal exploration")
			if found.size() != 1:
				continue
			var member: Dictionary = found[0]
			var row := state.individual_view(member.id)
			identities[member.id] = row
			positions["%d:%s" % [seed_value, species.display_name]] = [member.home.x, member.home.y]
			check(world.terrain.fits(member.home) and row.location == "wild" and member.sprite.get_meta("species_id") == species.species_id and member.sprite.affinity == row.affinity, "Normal-game model, legal home and actual affinity refer to the same wild identity")
			var ecology: Dictionary = sightings.ecology_for(member)
			check(ecology.profile_id == species.ecology.profile_id and not ecology.behaviors.is_empty(), "Normal-game species resolves its own connected behavior profile")
			check(not state.wild_profile(member.id).is_empty() and not state.movebook(member.id).is_empty(), "Normal-game admission supplies the existing battle/capture and move authorities")
			if species.traversal.kind != "ground":
				check(state.roaming_view(member.id).traversal.policy.kind == species.traversal.kind, "Normal-game flight/swimming capability is admitted through the existing domain contract")
			if species.traversal.kind == "swim":
				var has_bank := false
				for direction in SolLocalNavigation.DIRECTIONS:
					if SolTraversalPolicy.water(world.terrain, member.home + direction):
						has_bank = true
				check(has_bank, "Normal-game Reedback has an actual generated bank rather than an arbitrary dry trail spawn")
		var old_record: Dictionary = state.individual_view(sightings.members[0].id)
		check(old_record.species_id == "seedmote", "Existing authored individuals retain their species and identity")
		var before := state.snapshot()
		sightings.rebuild()
		check(before == state.snapshot(), "View reconstruction never re-admits or duplicates the new roster")
		var path := "user://sol_game_rollout_%d.json" % Time.get_ticks_usec()
		world.save_game(path)
		world.new_expedition(seed_value + 1)
		world.load_game(path)
		for id in identities:
			check(world.persistent_state.individual_view(id) == identities[id], "Current-format real save/load preserves each newly available species identity")
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var starters: Array = scene.battle_settings.starters
	check(starters[0].species_id == "bramblepup" and starters[1].species_id == "ashkit" and starters[2].species_id == "rillfin", "Rollout does not silently replace starter or opening-story decisions")
	# Simulate a current-format pre-rollout expedition without changing the normal scene.
	var previous_scene: Node3D = load(entry).instantiate()
	previous_scene.sighting_settings = load("res://resources/sighting_settings.tres")
	root.add_child(previous_scene)
	previous_scene.world.new_expedition(17)
	previous_scene.battles.open_choice()
	previous_scene.battles.choose(0)
	var selected_before: Dictionary = previous_scene.world.persistent_state.active_sol_view()
	var old_individuals: Dictionary = previous_scene.world.persistent_state.snapshot().individuals
	var upgrade_path := "user://sol_rollout_upgrade_%d.json" % Time.get_ticks_usec()
	previous_scene.world.save_game(upgrade_path)
	world.load_game(upgrade_path)
	scene.companion._process(0.0)
	check(world.persistent_state.active_sol_view() == selected_before, "Rollout preserves an existing selected owned companion and its saved profile")
	check(scene.companion.identity == selected_before.id, "The normal-game follower uses that same owned individual after pre-rollout load")
	for id in old_individuals:
		check(world.persistent_state.individual_view(id) == old_individuals[id], "Loading a pre-rollout current-format save preserves every existing individual")
	for species in catalog.entries:
		check(sightings.members.any(func(member: Dictionary) -> bool: return member.entry.species == species.species_id), "A pre-rollout current-format save gains the new species through explicit load admission")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(upgrade_path))
	if DisplayServer.get_name() != "headless":
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
	previous_scene.environment.sky = null
	previous_scene.queue_free()
	if DisplayServer.get_name() != "headless":
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		scene.camera.current = true
	if DisplayServer.get_name() != "headless" and OS.get_cmdline_user_args().has("--sol-rollout-capture"):
		await create_timer(3.0).timeout
		var crown: Array = sightings.members.filter(func(member: Dictionary) -> bool: return member.entry.species == "sol_species_0001")
		if not crown.is_empty():
			scene.camera_focus = Vector3(crown[0].sprite.position.x, 0, crown[0].sprite.position.z)
			scene.target_size = 14.0
			scene.apply_camera()
		await process_frame
		await RenderingServer.frame_post_draw
		get_root().get_texture().get_image().save_png("res://artifacts/sol_game_rollout.png")
	var file := FileAccess.open("res://artifacts/sol_game_rollout_homes.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(positions, "  "))
	file.close()
	if DisplayServer.get_name() != "headless":
		await process_frame
		await RenderingServer.frame_post_draw
	scene.environment.sky = null
	scene.queue_free()
	await process_frame
	if DisplayServer.get_name() != "headless":
		await process_frame
		await RenderingServer.frame_post_draw
	print("SOL GAME ROLLOUT: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
