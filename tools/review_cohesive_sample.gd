extends "res://tools/profile_current_expedition.gd"
## Matched rendered art review; explicit camera/actor fixtures plus a real-input journey.
const SampleSettings = preload("res://resources/nature_cohesive_sample.tres")
const BattleTest = preload("res://tests/battle_test_support.gd")
var baseline := false
var walk := false
var cost_only := false
var functional_only := false
var fixture_build_ms := 0.0

func _initialize() -> void:
	create_timer(420).timeout.connect(func(): push_error("Cohesive sample review timed out"); quit(1))
	run.call_deferred()

func route(target: Vector2i) -> Array[Vector2i]:
	var grid := AStarGrid2D.new()
	grid.region = Rect2i(-16,-20,144,112)
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	grid.update()
	for y in range(grid.region.position.y, grid.region.end.y):
		for x in range(grid.region.position.x, grid.region.end.x):
			var at := Vector2i(x,y)
			grid.set_point_solid(at, not world.terrain.fits(at))
			# Prefer the existing network; this is only the review controller's route choice.
			grid.set_point_weight_scale(at, 1.0 if world.terrain.is_trail(at) else 1.6)
	return grid.get_id_path(world.cell,target)

func find_ground(at: Vector2i) -> Vector2i:
	for distance in range(6):
		for y in range(-distance,distance+1):
			for x in range(-distance,distance+1):
				var cell := at + Vector2i(x,y)
				if world.terrain.fits(cell):
					return cell
	check(false, "Sample has a legal player standing position")
	return Vector2i.ZERO

func fixture(at: Vector2i) -> void:
	if scene.battles.feedback_view.result_panel.visible:
		# Accessibility may wrap the panel in scrolling containers. Locate the
		# actual action, rather than depending on its current child hierarchy.
		for button in scene.battles.feedback_view.result_panel.find_children("*", "Button", true, false):
			if button.text == "Continue exploring":
				button.pressed.emit()
				break
		check(not scene.battles.feedback_view.result_panel.visible, "Continue exploring dismisses the prior recap")
	if world.encounter_active:
		scene.encounters.withdraw()
	world.cell = find_ground(at)
	world.destination = world.cell
	world.moving = false
	world.max_generation_ms = 0
	world.max_publish_ms = 0
	var build_start := Time.get_ticks_usec()
	world.rebuild_world()
	fixture_build_ms = (Time.get_ticks_usec() - build_start) / 1000.0
	scene.sightings.admit_nearby(Vector2i.ZERO, world.cell)
	scene.reset_camera()
	for frame in range(180):
		await process_frame
		if world.pending.is_empty():
			break
	await settle(30)

func condition(kind: String) -> void:
	var settings: AtmosphereSettings = scene.atmosphere_settings.duplicate()
	settings.cycle_enabled = false
	settings.starting_phase = 0.0 if kind == "night" else 0.5
	settings.weather = "rain" if kind == "rain" else "clear"
	scene.atmosphere_controller.configure(settings)

func measured_frames(count: int) -> Dictionary:
	var samples: Array[float] = []
	var calls := 0.0
	var triangles := 0.0
	var last := Time.get_ticks_usec()
	for frame in range(count):
		await process_frame
		var now := Time.get_ticks_usec()
		samples.append((now-last)/1000.0)
		last = now
		calls = maxf(calls,Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
		triangles = maxf(triangles,Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
	var result := metrics(samples)
	result["draw_calls_peak"] = calls
	result["primitives_peak"] = triangles
	result["chunks"] = world.chunks.size()
	return result

func geometry_counts() -> Dictionary:
	var result := {"mesh_parts":0,"instances":0,"shadow_casters":0,"cosmetic_instances":0}
	for chunk in scene.solid_root.get_children():
		if chunk.get_script() == preload("res://scripts/solid_chunk.gd"):
			result.cosmetic_instances += chunk.cosmetic_records.size()
		for view in chunk.get_children():
			var amount := 0
			if view is MultiMeshInstance3D:
				amount = view.multimesh.instance_count
				result.mesh_parts += view.multimesh.mesh.get_surface_count()
			elif view is MeshInstance3D:
				amount = 1
				result.mesh_parts += view.mesh.get_surface_count()
			if view is GeometryInstance3D:
				result.instances += amount
				if view.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
					result.shadow_casters += amount
	return result

func run() -> void:
	output_directory = "res://artifacts/cohesive_sample/review"
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--output="):
			output_directory = argument.trim_prefix("--output=")
		baseline = baseline or argument == "--baseline"
		walk = walk or argument == "--walk"
		cost_only = cost_only or argument == "--cost-only"
		functional_only = functional_only or argument == "--functional-only"
	DirAccess.make_dir_recursive_absolute(output_directory)
	Engine.max_fps = 60
	var initial_start := Time.get_ticks_usec()
	scene = load("res://scenes/world_3d.tscn" if baseline else "res://scenes/cohesive_world_sample.tscn").instantiate()
	if baseline:
		# Keep an explicit existing-dressing comparison after promotion to F5.
		scene.nature_settings = preload("res://resources/nature_settings.tres")
	root.add_child(scene)
	current_scene = scene
	world = scene.world
	check(not world.smoke_mode, "Rendered review retains normal AI")
	check((scene.active_nature.composition == null) == baseline, "Cost comparison selects the intended existing or composed dressing")
	report = {"baseline":baseline, "engine":Engine.get_version_info().string,
		"initial_scene_build_ms":(Time.get_ticks_usec()-initial_start)/1000.0,
		"renderer":RenderingServer.get_current_rendering_method(), "driver":RenderingServer.get_current_rendering_driver_name(),
		"viewport":[root.size.x,root.size.y], "frame_cap":60, "seed":world.terrain.world_seed,
		"nature":resource_values(scene.active_nature), "view":resource_values(scene.active_view), "samples":{},
		"method":"Default world vs bounded composition; matched camera/weather fixtures, live AI. Each condition measures 180 paced frames after settling. Captures reposition the player explicitly; --walk separately verifies real-input connected travel. No new individuals or mechanics invented."}
	if functional_only:
		report.method = "Functional rendered review with live AI, real-input connected walk, actual pointer deployment, and explicit camera fixtures. Frame samples disabled; not a cost result."
	var initial: Dictionary = world.persistent_state.snapshot()
	world.rebuild_world()
	check(initial == world.persistent_state.snapshot(), "Art rebuild preserves complete persistent state")
	if walk:
		condition("daylight")
		report["journey"] = {}
		for point in [Vector2i(32,16),Vector2i(28,28),Vector2i(104,24),world.terrain.landmark(),Vector2i.ZERO]:
			var target := find_ground(point)
			report.journey[str(target)] = {"path":route(target),"travel":await traverse(target)}
		check(world.visited and world.returned, "Connected sample expedition discovers waystone and returns home")
	for patch in SampleSettings.composition.patches:
		var at: Vector2i = patch.clearings[0]
		if patch.patch_id == "wetland":
			at = Vector2i(28, 28)
		await fixture(at)
		# Match useful walking-height views in both runs; the pond is south of its approach.
		scene.view_azimuth = 180 if patch.patch_id == "wetland" else (-45 if patch.patch_id == "woodland" else 0)
		scene.apply_camera()
		await settle(30)
		var row := {"bounds":str(patch.bounds),"player_cell":str(world.cell),"fixture_build_ms":fixture_build_ms,"conditions":{}}
		row["geometry"] = geometry_counts()
		row["generation_max_ms"] = world.max_generation_ms
		row["publication_max_ms"] = world.max_publish_ms
		row["camera_azimuth"] = scene.view_azimuth
		for kind in ["daylight","night","rain"]:
			condition(kind)
			await settle(30)
			row.conditions[kind] = await measured_frames(0 if functional_only else 180)
			var vsync := DisplayServer.window_get_vsync_mode()
			Engine.max_fps = 0
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
			await settle(30)
			row.conditions[kind]["uncapped"] = await measured_frames(0 if functional_only else 180)
			Engine.max_fps = 60
			DisplayServer.window_set_vsync_mode(vsync)
			await settle(30)
			var visible: Array = []
			for member in scene.sightings.members:
				if member.sprite.is_visible_in_tree() and not scene.camera.is_position_behind(member.sprite.global_position):
					var pointer: Vector2 = scene.camera.unproject_position(member.sprite.global_position + Vector3(0,scene.sol_visual_settings.hover_height,0))
					if Rect2(Vector2.ZERO,Vector2(root.size)).has_point(pointer):
						visible.append(member.id)
			row.conditions[kind]["visible_sols_in_frame"] = visible
			await capture(patch.patch_id+"_"+kind)
		report.samples[patch.patch_id] = row
		var pick_start := Time.get_ticks_usec()
		for i in range(10):
			scene.pointer_cell(Vector2(root.size) * Vector2(0.35 + i * 0.03, 0.55))
		row["picking_average_ms"] = (Time.get_ticks_usec() - pick_start) / 10000.0
		if cost_only:
			continue
		# Real existing wildlife, with no fixture registration or forced affinity.
		var chosen: Dictionary = {}
		for member in scene.sightings.members:
			if patch.bounds.has_point(scene.sightings.current_cell(member)) and world.persistent_state.wild_available(member.id):
				chosen = member
				break
		if chosen.is_empty():
			row["encounter_gap"] = "No existing available Sol in sample bounds"
			continue
		row["encounter_id"] = chosen.id
		await fixture(scene.sightings.current_cell(chosen) + Vector2i.LEFT)
		if world.encounter_active:
			scene.encounters.withdraw()
		scene.encounters.approach_individual(chosen.id)
		check(world.encounter_active, "Existing sample individual admits an encounter")
		if not world.encounter_active:
			continue
		scene.encounters.observe_target()
		check(world.persistent_state.has_discovery(chosen.id), "Observation retains existing sample identity")
		for kind in ["daylight","night","rain"]:
			condition(kind)
			await settle(30)
			await capture(patch.patch_id+"_observe_"+kind)
		scene.encounters.battle_button.pressed.emit()
		if scene.battles.choosing:
			scene.battles.choose(0)
		check(scene.battles.session != null, "Existing tactical encounter admits on sample terrain")
		if scene.battles.session != null:
			# Allow the existing cosmetic commander walk before deployment.
			await settle(180)
			var clicked := false
			for tile in scene.battles.session.deployment_tiles():
				var pointer: Vector2 = scene.camera.unproject_position(scene.battles.point(tile))
				if scene.pointer_cell(pointer) != tile:
					continue
				var event := InputEventMouseButton.new()
				event.button_index = MOUSE_BUTTON_LEFT
				event.pressed = true
				event.position = pointer
				world.handle_input(event)
				clicked = true
				break
			check(clicked, "Sample has an accurately pickable deployment tile")
			await settle(120)
			check(scene.battles.session != null and scene.battles.session.phase == "active", "Companion deployment completes on the existing battlefield")
			# Orbit is part of normal play. Preserve blockers and record a second view
			# instead of hiding an obstacle when its canopy crosses a combatant.
			scene.view_azimuth = -55
			scene.apply_camera()
			await settle(30)
			row["combat_camera_azimuth"] = scene.view_azimuth
			for kind in ["daylight","night","rain"]:
				condition(kind)
				await settle(30)
				await capture(patch.patch_id+"_combat_"+kind)
			scene.battles.retreat()
			BattleTest.settle(scene.battles)
			await settle(90)
			check(scene.battles.session == null and not world.encounter_active, "Sample encounter safely returns to exploration")
	if cost_only:
		finish_review()
		return
	# Preserve the observed identities and actual battle receipts before the
	# independent fresh guard scenarios intentionally reset the expedition.
	world.paused = true
	var outcome_path := output_directory + "/sample_outcomes.json"
	world.save_game(outcome_path)
	var outcomes: Dictionary = world.persistent_state.snapshot()
	world.load_game(outcome_path)
	check(JSON.stringify(outcomes,"",true) == JSON.stringify(world.persistent_state.snapshot(),"",true), "Sample observations and battle outcomes survive save/load exactly")
	# Existing authored guard warning under each condition, without fabricating hostility.
	for kind in ["daylight","night","rain"]:
		# A fresh scenario has no prior battle-grace receipt suppressing the warning.
		world.new_expedition(2601026)
		condition(kind)
		var guard_home := Vector2i(48, world.terrain.trail_y(48))
		for member in scene.sightings.members:
			if member.entry.get("x", 0) == 48 and member.entry.get("hostile", false):
				guard_home = member.home
				break
		await fixture(guard_home + Vector2i(-2, 1))
		await settle(60)
		report["warning_"+kind] = {"visible":scene.encounters.warning_panel.visible,"identity":scene.encounters.warning_id}
		check(scene.encounters.warning_panel.visible, "Existing guard warning is rendered under " + kind)
		await capture("warning_"+kind)
	# Boundary and a chunk seam, not only sample centers.
	condition("daylight")
	await fixture(Vector2i(32,4))
	await capture("woodland_boundary_chunk_seam")
	var save_path := output_directory + "/sample_save.json"
	world.paused = true
	world.save_game(save_path)
	var saved_state: Dictionary = world.persistent_state.snapshot()
	world.load_game(save_path)
	check(JSON.stringify(saved_state,"",true) == JSON.stringify(world.persistent_state.snapshot(),"",true), "Combined review saves and restores its actual outcomes")
	finish_review()

func finish_review() -> void:
	report["failures"] = failures
	var file := FileAccess.open(output_directory+"/review.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	file.close()
	print("COHESIVE REVIEW: %d failures; %s" % [failures.size(),output_directory])
	scene.environment.sky = null
	scene.free()
	quit(0 if failures.is_empty() else 1)
