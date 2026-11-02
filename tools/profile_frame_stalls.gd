extends "res://tools/review_connected_expedition.gd"
## Repeatable normal-input workload. Diagnostics never change production settings.
const Probe = preload("res://tools/stall_probe.gd")
var diagnostic := false
var frame_callback: Callable
var render_started := 0
var render_begin_callback: Callable
var render_end_callback: Callable

func _initialize() -> void:
	root.gui_embed_subwindows = true
	if root.get_property_list().any(func(row: Dictionary) -> bool: return row.name == "unfocusable"):
		root.set("unfocusable", true)
	create_timer(420).timeout.connect(func() -> void:
		push_error("Frame-stall profile timed out")
		quit(2))
	run.call_deferred()

func record(value: bool, description: String) -> void:
	check(value, description)
	print("CHECK: ", value, " ", description)

func capture(_name: String) -> void:
	pass # Explicit captures happen outside sampled windows below.

func observe() -> void:
	# Parent connected-review hooks intentionally excluded; travel driver is reused.
	live_chunk_peak = maxi(live_chunk_peak, world.chunks.size())

func handle_route_contact() -> void:
	if world.encounter_active:
		release_movement()
		contacts.append({"cell": str(world.cell), "tick": world.persistent_state.activity_tick()})
		scene.encounters.observe_target()
		scene.encounters.withdraw()

func traverse(target: Vector2i) -> Dictionary:
	var travel_phase := Probe.phase
	Probe.set_phase("route_planning")
	# Existing driver plans synchronously before its first await; the boundary
	# frame is excluded from travel metrics by the independent frame collector.
	var result: Dictionary = await super.traverse(target)
	release_movement()
	await process_frame # Let normal movement settle before a manual encounter.
	Probe.set_phase(travel_phase)
	return result

func route(target: Vector2i) -> Array[Vector2i]:
	var result := super.route(target)
	Probe.set_phase(str(report.get("requested_phase", "travel")))
	return result

func window(label: String, count: int) -> void:
	Probe.set_phase(label)
	for index in range(count): await process_frame

func travel(label: String, target: Vector2i) -> void:
	report["requested_phase"] = label
	Probe.set_phase(label)
	report[label] = await traverse(target)
	check(world.cell == target, label + " reached destination")

func screenshot(name: String) -> void:
	Probe.set_phase("capture")
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(output_directory + "/" + name + ".png") == OK, "Capture " + name)
	# Preserve partial evidence on an external close. Serialization is outside
	# the measured workload; a progress file is never a completed profile.
	var progress := FileAccess.open(output_directory + "/progress.json", FileAccess.WRITE)
	progress.store_string(JSON.stringify({"completed": false, "checkpoint": name, "frames": Probe.frames, "report": report}))
	progress.close()
	await process_frame

func begin(member: Dictionary) -> bool:
	# A moving opponent can invalidate the first outside-command position.
	# Retry through normal walking/contact/UI commands, preserving rejection rules.
	for attempt in range(6):
		if not await approach(member): continue
		scene.encounters.observe_target()
		scene.encounters.battle_button.pressed.emit()
		await ready()
		if scene.battles.session != null:
			var tiles: Array[Vector2i] = scene.battles.session.deployment_tiles()
			tiles.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return scene.battles.session.distance(a, scene.battles.session.enemy_cell) < scene.battles.session.distance(b, scene.battles.session.enemy_cell))
			scene.battles.select_cell(tiles[0])
			await ready()
			return scene.battles.session != null and scene.battles.session.phase == "active"
		if not report.has("combat_admission_rejections"): report["combat_admission_rejections"] = []
		report.combat_admission_rejections.append({"reason": world.toast.text, "cell": str(world.cell)})
		scene.encounters.withdraw()
		var target: Vector2i = scene.sightings.current_cell(member)
		var offsets := [Vector2i(2,0),Vector2i(0,2),Vector2i(-2,0),Vector2i(0,-2),Vector2i(1,1),Vector2i(-1,-1)]
		for index in range(offsets.size()):
			var at: Vector2i = target + offsets[(attempt+index)%offsets.size()]
			if at != world.cell and world.terrain.fits(at):
				await travel("combat_reposition", at)
				break
	return false

func combat_window() -> void:
	Probe.set_phase("combat_approach")
	report["requested_phase"] = "combat_approach"
	var candidates: Array[Dictionary] = []
	for candidate: Dictionary in scene.sightings.members:
		var saved: Dictionary = world.persistent_state.roaming_view(candidate.id)
		var mode: String = saved.get("traversal", {}).get("mode", "ground")
		# Use the authored opponent from the successful reference journeys;
		# a nearer habitat spawn can lack an admissible command position.
		if mode == "ground" and candidate.id == "2601026:6:4:sol_species_0018" and world.persistent_state.wild_available(candidate.id): candidates.append(candidate)
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return scene.sightings.current_cell(a).distance_squared_to(world.cell) < scene.sightings.current_cell(b).distance_squared_to(world.cell))
	check(not candidates.is_empty(), "Grounded encounter candidate available")
	if candidates.is_empty(): return
	var member: Dictionary = candidates[0]
	report["combat_candidate"] = {"identity": member.id, "entry": member.entry, "cell": str(scene.sightings.current_cell(member))}
	var entered := await begin(member)
	check(entered, "Normal encounter and deployment enter readiness combat")
	if not entered: return
	report["combat_identity"] = member.id
	check(scene.battles.playback.timeline != null, "Production readiness timeline enabled")
	await window("combat_planning", 120)
	await screenshot("combat-planning")
	Probe.set_phase("combat_execution")
	# Commit legal movement and a legal move when available, then wait through
	# the actual readiness timeline. No stats, rolls, clocks or speed are edited.
	await move_closer()
	await use_move(0, true)
	scene.battles.wait_turn()
	await ready()
	check(scene.battles.session != null, "Combat execution returns to a live readiness gate")
	await window("combat_after_execution", 90)
	report["combat_clock"] = scene.battles.playback.timeline.clock if scene.battles.playback.timeline != null else -1.0

func run() -> void:
	output_directory = "res://artifacts/frame-stalls"
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--output="): output_directory = argument.trim_prefix("--output=")
		if argument == "--diagnostic": diagnostic = true
	DirAccess.make_dir_recursive_absolute(output_directory)
	Engine.max_fps = 60
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	root.set_title("SolHunter performance measurement")
	var started := Time.get_ticks_usec()
	scene = load("res://scenes/world_3d.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	world = scene.world
	report = {"engine": Engine.get_version_info(), "driver": RenderingServer.get_current_rendering_driver_name(),
		"adapter": RenderingServer.get_video_adapter_name(), "viewport": [root.size.x, root.size.y],
		"cap": 60, "vsync": DisplayServer.window_get_vsync_mode(), "seed": world.terrain.world_seed,
		"generation": world.terrain.generation_version, "diagnostic": diagnostic,
		"startup_ms": (Time.get_ticks_usec() - started) / 1000.0,
		"view": resource_values(scene.active_view), "nature": resource_values(scene.active_nature),
		"method": "Fresh process, fixed seed and default settings; normal input-action waypoint travel and live simulation. OS/driver caches retained. Route planning, screenshots and phase boundary frames excluded from sampled workload summaries. Scope timings inclusive; wall time also includes engine/render/OS waits."}
	check(not world.smoke_mode and not world.paused, "Normal simulation enabled")
	check(world.terrain.world_seed == 2601026, "Fixed baseline seed")
	var library := preload("res://scripts/scenery/plant_library.gd")
	library.baked_definition("procedural_0_1_0")
	check(library.palette_current, "Prepared plant palette is current")
	world.menu.preferences_path = output_directory + "/menu.cfg"
	scene.gamepad.preferences_path = output_directory + "/controller.cfg"
	world.menu.choose_starter(0)
	check(not world.persistent_state.active_sol_view().is_empty(), "Choose actual starter through menu owner")
	Probe.enabled = diagnostic
	if diagnostic:
		render_begin_callback = func() -> void: render_started = Time.get_ticks_usec()
		render_end_callback = func() -> void:
			if render_started > 0: Probe.leave("engine.render_signal_interval", render_started)
		RenderingServer.frame_pre_draw.connect(render_begin_callback)
		RenderingServer.frame_post_draw.connect(render_end_callback)
	frame_callback = func() -> void: Probe.frame(world, scene)
	process_frame.connect(frame_callback)
	await window("warmup", 180)
	await window("idle", 180)
	await screenshot("idle")
	await travel("outbound", world.terrain.landmark())
	await screenshot("outbound")
	await travel("return", Vector2i.ZERO)
	Input.action_press("run")
	await travel("negative_sprint", Vector2i(-20, world.terrain.trail_y(-20)))
	Input.action_release("run")
	await travel("negative_return", Vector2i.ZERO)
	Probe.set_phase("camera_orbit")
	for angle in [90.0, 180.0, -90.0, 0.0]:
		scene.view_azimuth = angle
		scene.view_changed()
		for frame in range(60): await process_frame
	Probe.set_phase("inspection")
	world.inspected_cell = world.cell
	for frame in range(180): await process_frame
	check(world.inspection_card.visible, "Inspection window displays actual current-cell readings")
	await screenshot("inspection")
	world.inspected_cell = null
	world.inspection_panel.hide()
	world.menu.open("sols")
	await window("live_menu", 120)
	world.menu.close()
	await combat_window()
	await screenshot("combat-final")
	Probe.set_phase("finish")
	await process_frame
	process_frame.disconnect(frame_callback)
	if diagnostic:
		RenderingServer.frame_pre_draw.disconnect(render_begin_callback)
		RenderingServer.frame_post_draw.disconnect(render_end_callback)
	report["frames"] = Probe.frames
	report["scope_calls"] = Probe.all_scope_calls
	report["failures"] = failures
	report["contacts"] = contacts
	report["peak_live_chunks"] = live_chunk_peak
	var file := FileAccess.open(output_directory + "/profile.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report))
	file.close()
	print("FRAME STALL PROFILE: ", failures.size(), " failures; ", Probe.frames.size(), " frames")
	Probe.enabled = false
	scene.environment.sky = null
	scene.free()
	quit(0 if failures.is_empty() else 1)
