extends "res://tools/profile_current_expedition.gd"
## Deliberate guard approach with live AI; separate from the travel baseline.

func run() -> void:
	output_directory = "res://artifacts/current_expedition/contact"
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--output="):
			output_directory = argument.trim_prefix("--output=")
	DirAccess.make_dir_recursive_absolute(output_directory)
	Engine.max_fps = 60
	scene = (load("res://scenes/world_3d.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	current_scene = scene
	world = scene.world
	check(not world.smoke_mode, "Contact study retains normal AI")
	await settle(120)
	report["approach"] = await traverse(Vector2i(46, world.terrain.trail_y(46)))
	await settle(90)
	var guard: Dictionary = {}
	for member in scene.sightings.members:
		if member.entry.get("hostile", false):
			guard = member
	check(not guard.is_empty(), "Existing authored guard is present")
	if not guard.is_empty():
		var at: Vector2i = scene.sightings.current_cell(guard)
		report["guard_approach"] = await traverse(at)
		await settle(30)
		# The route controller records/withdraws any automatic contacts it meets.
		# Also exercise the normal explicit Engage action on that same identity.
		scene.encounters.approach_individual(guard.id)
		check(world.encounter_active, "Explicit guard approach opens face-to-face encounter")
		if world.encounter_active:
			await capture("face_to_face")
			var save_path := output_directory + "/blocked_save.json"
			world.save_game(save_path)
			check(not FileAccess.file_exists(save_path), "Encounter prevents expedition save")
			scene.encounters.observe_target()
			check(world.persistent_state.has_discovery(guard.id), "Observation records the actual guard identity")
			scene.encounters.withdraw()
			check(not world.encounter_active and not world.paused, "Withdraw restores exploration")
			var snapshot_path := output_directory + "/contact_save.json"
			world.save_game(snapshot_path)
			var before: Dictionary = world.persistent_state.snapshot()
			world.load_game(snapshot_path)
			check(world.persistent_state.has_discovery(guard.id), "Guard discovery survives save/load")
			check(JSON.stringify(before, "", true) == JSON.stringify(world.persistent_state.snapshot(), "", true), "Encounter snapshot reconstructs exactly")
	report["return"] = await traverse(Vector2i.ZERO)
	report["automatic_contacts"] = contacts
	report["warnings_seen"] = warnings_seen.keys()
	report["failures"] = failures
	report["engine_static_memory_peak_bytes"] = static_memory_peak
	report["method"] = "Live-AI walk to existing guard; wait for warning, walk toward current position, explicit Engage, Observe, Withdraw, save/load and return. No forced identities/positions or combat."
	var output := FileAccess.open(output_directory + "/profile.json", FileAccess.WRITE)
	output.store_string(JSON.stringify(report, "\t"))
	output.close()
	print("CONTACT STUDY: %d failures; %d automatic contacts" % [failures.size(), contacts.size()])
	scene.free()
	quit(0 if failures.is_empty() else 1)
