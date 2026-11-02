extends "res://tools/profile_current_expedition.gd"
## Normal-input N0/N2 journey. No teleports, speed edits or disabled AI.
var review_combat := false
func _initialize() -> void:
	create_timer(420).timeout.connect(func() -> void:
		push_error("Nature review timed out")
		quit(1))
	run.call_deferred()

func run() -> void:
	output_directory = "res://artifacts/nature_alpha/journey"
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--output="): output_directory = argument.trim_prefix("--output=")
	DirAccess.make_dir_recursive_absolute(output_directory)
	Engine.max_fps = 60
	scene = (load("res://scenes/world_3d.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	current_scene = scene
	world = scene.world
	review_combat = "--combat" in OS.get_cmdline_user_args()
	if review_combat: world.menu.choose_starter(0)
	report = {"seed": world.terrain.world_seed, "generation": world.terrain.generation_version,
		"state_version": ExpeditionState.VERSION, "journeys": [], "participants": [], "flora": [],
		"method": "Normal real-time input-action travel with live ecology/AI/contact. Scripted observation through the existing context action. No owner play acceptance implied."}
	await settle(90)
	check(not world.smoke_mode, "Normal runtime remains enabled")
	for target in [scene.nature.settings.grove_cell, Vector2i.ZERO, scene.nature.settings.bank_cell, Vector2i.ZERO, Vector2i(48, world.terrain.trail_y(48)), Vector2i.ZERO]:
		print("NATURE JOURNEY: travelling to %s" % target)
		report.journeys.append({"target": str(target), "travel": await traverse(target)})
		await settle(10)
		# Observe nearby admitted plants only; do not create synthetic participants.
		for y in range(-2, 3):
			for x in range(-2, 3):
				var at: Vector2i = world.cell + Vector2i(x, y)
				if absi(x) + absi(y) > 3: continue
				var reading: Dictionary = world.persistent_state.flora_reading(at)
				if not reading.is_empty():
					report.flora.append({"id": AffinityImprint.key(at), "reading": reading})
					world.open_observation(Vector2(100, 100), at)
					world.context_action(0)
		for member in scene.sightings.members:
			if member.sprite.visible:
				report.participants.append({"id": member.id, "cell": str(scene.sightings.current_cell(member)), "state": world.persistent_state.roaming_view(member.id)})
				var observed_at: Vector2i = scene.sightings.current_cell(member)
				if scene.sightings.manhattan(observed_at, world.cell) <= 3:
					world.open_observation(Vector2(100, 100), observed_at, member.id)
					world.context_action(0)
		if review_combat and target.x == 48:
			await review_confrontation()
		await capture("place_%d_%d" % [target.x, target.y])
	check(world.cell == Vector2i.ZERO, "The nature outing returns to camp")
	check(not world.persistent_state.finding_entries().is_empty(), "Deliberate field observation records retained knowledge")
	world.toggle_pause()
	var before: Dictionary = world.persistent_state.snapshot()
	var save_path := output_directory + "/expedition.json"
	world.save_game(save_path)
	check(not ExpeditionSave.read_save(save_path).is_empty(), "Current nature state saves through the existing owner")
	world.load_game(save_path)
	# JSON numbers do not distinguish an integral float from an integer. Compare
	# complete serialized values after the same normalization on both snapshots.
	check(JSON.parse_string(JSON.stringify(before, "", true, true)) == JSON.parse_string(JSON.stringify(world.persistent_state.snapshot(), "", true, true)), "Reload retains the complete outing, identities and findings")
	report["findings"] = world.persistent_state.finding_entries()
	report["contacts"] = contacts
	report["failures"] = failures
	var output := FileAccess.open(output_directory + "/report.json", FileAccess.WRITE)
	output.store_string(JSON.stringify(report, "\t"))
	output.close()
	print("NATURE ALPHA JOURNEY: %d findings, %d contacts, %d failures" % [report.findings.size(), contacts.size(), failures.size()])
	scene.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)

func review_confrontation() -> void:
	var encounters: Node = scene.encounters
	var candidates: Array = encounters.candidates(encounters.settings.interaction_distance)
	check(not candidates.is_empty(), "A real nearby Sol can be approached at the crossing")
	if candidates.is_empty(): return
	encounters.approach_individual(candidates[0].id)
	encounters.battle_button.pressed.emit()
	var controller: Node = scene.battles
	check(controller.session != null, "Normal encounter action admits readiness combat")
	if controller.session == null:
		if world.encounter_active: encounters.withdraw()
		return
	var deadline := Time.get_ticks_msec() + 90000
	var captured_planning := false
	var captured_commit := false
	# Explicit playtest policy: use the existing unlimited testing Seals. No
	# rolls, HP, tuning, timeline or simulation speed are altered by this review.
	while controller.session != null and Time.get_ticks_msec() < deadline:
		await process_frame
		if controller.session == null: break
		if not controller.commander_ready() or controller.playback.busy: continue
		if controller.session.phase == "deployment":
			controller.select_cell(controller.session.deployment_tiles()[0])
		elif controller.playback.timeline != null and controller.playback.timeline.planning:
			if not captured_planning:
				await capture("readiness_before_frame")
				controller.open_battle_menu()
				controller.frame_battle()
				controller.close_battle_menu()
				await process_frame
			controller.capture_enemy()
			if not captured_planning:
				await capture("readiness_plan")
				captured_planning = true
			controller.wait_turn()
			if not captured_commit:
				await capture("readiness_execution")
				captured_commit = true
	check(controller.session == null, "Live confrontation reaches its normal centralized outcome")
	report["combat_result"] = world.persistent_state.battle_progress().last_result.duplicate(true)
	if world.terrain.is_camp(world.cell): controller.recover()

func traverse(target: Vector2i) -> Dictionary:
	var start := Time.get_ticks_usec()
	var path := route(target)
	check(not path.is_empty(),"Current cardinal route exists to %s" % target)
	var planning_ms := float(Time.get_ticks_usec()-start)/1000.0
	var samples: Array[float] = []
	var last := Time.get_ticks_usec()
	for index in range(1,path.size()):
		var deadline := Time.get_ticks_msec()+12000
		while world.cell != path[index]:
			if Time.get_ticks_msec()>deadline:
				release_movement()
				check(false,"Continuous input stalled at %s toward %s" % [world.cell,path[index]])
				return {"stalled_cell":str(world.cell),"target":str(path[index]),"frames":metrics(samples)}
			if world.encounter_active: await handle_route_contact()
			var change := Vector2(path[index]-world.cell).normalized().rotated(deg_to_rad(scene.view_azimuth))
			release_movement()
			# Continuous movement requires held input while velocity is nonzero.
			if absf(change.x)>0.3: Input.action_press("east" if change.x>0 else "west")
			if absf(change.y)>0.3: Input.action_press("south" if change.y>0 else "north")
			await process_frame
			var now := Time.get_ticks_usec()
			samples.append(float(now-last)/1000.0)
			last = now
			observe()
		release_movement()
	await handle_route_contact()
	check(world.cell == target,"Normal continuous-input traversal reaches %s" % target)
	var result := metrics(samples)
	result["route_planning_ms"] = planning_ms
	result["route_steps"] = maxi(0,path.size()-1)
	return result

func route(target: Vector2i) -> Array[Vector2i]:
	# The continuous movement owner validates edges, including height and live
	# conditions. A flat AStar occupancy grid cannot certify those transitions.
	var bounds := Rect2i(-28,-36,144,101)
	var queue: Array[Vector2i] = [world.cell]
	var parents := {world.cell:world.cell}
	var cursor := 0
	while cursor<queue.size() and not parents.has(target):
		var at := queue[cursor]
		cursor += 1
		for offset: Vector2i in [Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT]:
			var next := at+offset
			if not bounds.has_point(next) or parents.has(next) or not world.can_step(at,next): continue
			parents[next] = at
			queue.append(next)
	var result: Array[Vector2i] = []
	if not parents.has(target): return result
	var at := target
	while at != world.cell:
		result.push_front(at)
		at = parents[at]
	result.push_front(world.cell)
	return result
