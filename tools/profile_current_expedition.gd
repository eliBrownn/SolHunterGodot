extends "res://tests/exploration_profile.gd"
## Current combined expedition: real input actions, normal simulation and automatic contact.
## Kept outside CI. This is an automated rendered journey, not owner acceptance.

var contacts: Array = []
var warnings_seen: Dictionary = {}
var roaming_seen: Dictionary = {}
var draw_call_peak := 0.0
var primitive_peak := 0.0
var cap := 60
var last_contact := ""

func resource_values(value: Resource) -> Dictionary:
	var result := {"resource_path": value.resource_path}
	for property in value.get_property_list():
		if int(property.usage) & PROPERTY_USAGE_EDITOR and int(property.usage) & PROPERTY_USAGE_STORAGE:
			var item: Variant = value.get(property.name)
			if item is Resource:
				result[property.name] = resource_values(item)
			elif item is Array:
				var entries: Array = []
				for entry in item:
					entries.append(entry.resource_path if entry is Resource else entry)
				result[property.name] = entries
			else:
				result[property.name] = item
	return result

func observe() -> void:
	super.observe()
	draw_call_peak = maxf(draw_call_peak, Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	primitive_peak = maxf(primitive_peak, Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
	if not scene.encounters.warning_id.is_empty():
		warnings_seen[scene.encounters.warning_id] = true
	for member in scene.sightings.members:
		var at: Vector2i = scene.sightings.current_cell(member)
		var identity: String = member.id
		if not roaming_seen.has(identity):
			roaming_seen[identity] = {"first": str(at), "moved": false}
		elif roaming_seen[identity].first != str(at):
			roaming_seen[identity].moved = true

func release_movement() -> void:
	for action in ["north", "south", "west", "east"]:
		Input.action_release(action)

func handle_route_contact() -> void:
	if not world.encounter_active:
		return
	release_movement()
	var target_record: Dictionary = scene.encounters.active_target.duplicate(true)
	contacts.append({"target": target_record, "cell": str(world.cell), "tick": world.persistent_state.activity_tick()})
	await capture("contact_%d" % contacts.size())
	scene.encounters.observe_target()
	await create_timer(0.5).timeout
	scene.encounters.withdraw()
	check(not world.encounter_active and not world.paused, "Withdrawal resumes normal travel")

func traverse(target: Vector2i) -> Dictionary:
	var start := Time.get_ticks_usec()
	var path := route(target)
	var planning_ms := (Time.get_ticks_usec() - start) / 1000.0
	check(not path.is_empty(), "Current route exists to %s" % target)
	var samples: Array[float] = []
	var last := Time.get_ticks_usec()
	for i in range(1, path.size()):
		var step_start := Time.get_ticks_msec()
		while world.cell != path[i]:
			if Time.get_ticks_msec() - step_start > 12000:
				check(false, "Traversal stalled at %s toward %s" % [world.cell, path[i]])
				release_movement()
				return {"stalled_cell": str(world.cell), "target": str(path[i]), "frames": metrics(samples)}
			if world.encounter_active:
				await handle_route_contact()
			var change: Vector2 = Vector2(path[i] - world.cell).normalized().rotated(deg_to_rad(scene.view_azimuth))
			release_movement()
			# Release while interpolating so a completed step cannot begin another
			# before this controller has observed arrival at the waypoint.
			if not world.moving and absf(change.x) > 0.3:
				Input.action_press("east" if change.x > 0 else "west")
			if not world.moving and absf(change.y) > 0.3:
				Input.action_press("south" if change.y > 0 else "north")
			await process_frame
			var now := Time.get_ticks_usec()
			samples.append((now - last) / 1000.0)
			last = now
			observe()
			release_movement()
	# Arrival can open the encounter on the final step, after the while condition
	# becomes false. Record/withdraw it before a caller attempts manual Engage.
	await handle_route_contact()
	check(world.cell == target, "Normal-input traversal reaches %s" % target)
	var result := metrics(samples)
	result["route_planning_ms"] = planning_ms
	result["route_steps"] = maxi(0, path.size() - 1)
	return result

func run() -> void:
	output_directory = "res://artifacts/current_expedition/run"
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--output="):
			output_directory = argument.trim_prefix("--output=")
		if argument.begins_with("--cap="):
			cap = int(argument.trim_prefix("--cap="))
	DirAccess.make_dir_recursive_absolute(output_directory)
	Engine.max_fps = cap
	root.set_title("SolHunter — current expedition baseline")
	# Uncapped throughput explicitly disables v-sync; paced runs retain project policy.
	if cap == 0:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var start := Time.get_ticks_usec()
	scene = (load("res://scenes/world_3d.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	current_scene = scene
	world = scene.world
	report = {"timestamp_utc": Time.get_datetime_string_from_system(true),
		"engine": Engine.get_version_info(), "driver": RenderingServer.get_current_rendering_driver_name(),
		"renderer": RenderingServer.get_current_rendering_method(), "adapter": RenderingServer.get_video_adapter_name(),
		"viewport": [root.size.x, root.size.y], "window": str(DisplayServer.window_get_size()),
		"frame_cap": cap, "vsync": DisplayServer.window_get_vsync_mode(),
		"seed": world.terrain.world_seed, "generation": world.terrain.generation_version,
		"state_version": ExpeditionState.VERSION, "save_version": ExpeditionSave.FORMAT_VERSION,
		"initial_scene_build_ms": (Time.get_ticks_usec() - start) / 1000.0,
		"relief": world.terrain.relief, "climate": world.terrain.climate,
		"view": resource_values(scene.active_view), "nature": resource_values(scene.active_nature),
		"atmosphere": resource_values(scene.atmosphere_settings),
		"sightings": resource_values(scene.sightings.settings), "encounters": resource_values(scene.encounters.settings),
		"expedition": world.expedition_parameters(),
		"method": "Rendered real-time input-action waypoint journey; smoke_mode false, normal AI/clock/contact. Contact policy: record sighting then withdraw. Travel intervals include contact handling. No combat acceptance. Fresh process; OS/driver shader caches not purged. Owner manual acceptance remains open."}
	check(not world.smoke_mode, "Smoke mode remains disabled")
	check(scene.encounters.settings.enabled and scene.encounters.settings.automatic_contact, "Normal automatic contact is enabled")
	report["warmup"] = await settle(120)
	await capture("refuge")
	world.max_generation_ms = 0
	world.max_publish_ms = 0
	report["outbound"] = await traverse(world.terrain.landmark())
	check(world.visited, "Waystone discovery occurs with live AI")
	await capture("waystone")
	report["return"] = await traverse(Vector2i.ZERO)
	check(world.returned, "Return objective completes with live AI")
	report["negative"] = await traverse(Vector2i(-20, world.terrain.trail_y(-20)))
	await capture("negative")
	report["negative_return"] = await traverse(Vector2i.ZERO)
	report["generation_max_ms"] = world.max_generation_ms
	report["publication_max_ms"] = world.max_publish_ms
	world.toggle_pause()
	var paused_tick: int = world.persistent_state.activity_tick()
	report["paused"] = await settle(60)
	check(world.persistent_state.activity_tick() == paused_tick, "Pause stops the activity clock")
	var save_path := output_directory + "/expedition.json"
	var before: Dictionary = world.persistent_state.snapshot()
	var saved_cell: Vector2i = world.cell
	start = Time.get_ticks_usec()
	world.save_game(save_path)
	report["save_ms"] = (Time.get_ticks_usec() - start) / 1000.0
	var saved := ExpeditionSave.read_save(save_path)
	check(not saved.is_empty(), "Current combined save passes read validation")
	start = Time.get_ticks_usec()
	world.new_expedition(7)
	report["new_expedition_ms"] = (Time.get_ticks_usec() - start) / 1000.0
	check(world.terrain.world_seed == 7 and not world.visited and not world.returned, "New seed resets objective")
	start = Time.get_ticks_usec()
	world.load_game(save_path)
	report["load_ms"] = (Time.get_ticks_usec() - start) / 1000.0
	check(world.cell == saved_cell and world.returned, "Load restores position and journey")
	check(JSON.stringify(before, "", true) == JSON.stringify(world.persistent_state.snapshot(), "", true), "Full persistent snapshot survives save/new/load without rerolls or duplicates")
	var bad := FileAccess.open(output_directory + "/incompatible.json", FileAccess.WRITE)
	bad.store_string('{"save_version":-1}')
	bad.close()
	var live_state: ExpeditionState = world.persistent_state
	world.load_game(output_directory + "/incompatible.json")
	check(world.persistent_state == live_state and world.cell == saved_cell, "Rejected load preserves current expedition")
	report["idle_after_load"] = await settle(120)
	await capture("restored")
	report["contacts"] = contacts
	report["warnings_seen"] = warnings_seen.keys()
	report["roaming_seen"] = roaming_seen
	report["activity_tick"] = world.persistent_state.activity_tick()
	report["peak_chunks"] = live_chunk_peak
	report["engine_static_memory_peak_bytes"] = static_memory_peak
	report["draw_calls_peak"] = draw_call_peak
	report["primitives_peak"] = primitive_peak
	report["stream_prepare_slice_max_ms"] = scene.max_stream_slice_ms
	report["stream_operation_peaks_ms"] = scene.stream_step_peaks
	report["world_process_max_ms"] = world.max_process_ms
	report["simulation_tick_batch_max_ms"] = world.max_simulation_ms
	report["movement_and_admission_max_ms"] = world.max_movement_ms
	report["temporary_ground_sync_max_ms"] = scene.streaming_ground.max_prepare_ms
	report["detailed_chunk_cache_reuses"] = scene.detail_cache_reuses
	report["stream_chunk_geometry_work_max_ms"] = scene.max_stream_geometry_ms
	report["stream_timing_note"] = "Publication timing excludes resumable preparation; slice timing is per call, geometry work is accumulated CPU time per chunk. Initial visible rebuilds remain synchronous."
	report["limitations"] = ["No numeric performance budgets approved", "No GPU memory measurement", "No manual owner acceptance, export or Thor qualification", "No long-trip cache turnover or maximum-distance orbit coverage", "Warmup and post-load windows are within-process warm samples; fresh-process launches retain OS/driver caches"]
	report["failures"] = failures
	var output := FileAccess.open(output_directory + "/profile.json", FileAccess.WRITE)
	output.store_string(JSON.stringify(report, "\t"))
	output.close()
	print("CURRENT EXPEDITION: %d failures; %d contacts; report %s/profile.json" % [failures.size(), contacts.size(), output_directory])
	release_movement()
	scene.environment.sky = null
	scene.free()
	quit(0 if failures.is_empty() else 1)
