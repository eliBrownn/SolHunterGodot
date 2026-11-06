extends "res://tools/review_world_exploration.gd"
## Reproducible road baseline; normal input/simulation, no normal save writes.

func route(target: Vector2i) -> Array[Vector2i]:
	if target.y != world.terrain.trail_y(target.x) or world.cell.y != world.terrain.trail_y(world.cell.x):
		return super.route(target)
	var points: Array[Vector2i] = [world.cell]
	var cursor: Vector2i = world.cell
	while cursor.x != target.x:
		cursor.x += 1 if target.x > cursor.x else -1
		cursor.y = world.terrain.trail_y(cursor.x)
		if not world.terrain.fits(cursor):
			return []
		points.append(cursor)
	return points

func quiet_spur() -> Dictionary:
	# Select by current wildlife clearance, never by changing admission or AI.
	var candidates := []
	var origin: Vector2i = world.cell
	for y in range(-12, 13, 2):
		for x in range(-12, 13, 2):
			var at := origin + Vector2i(x, y)
			if Vector2(at - origin).length() > 12 or not world.terrain.fits(at): continue
			if world.terrain.natural_ground(at) not in [0, 1]: continue
			var clearance := INF
			for member in scene.sightings.members:
				if world.persistent_state.wild_available(member.id):
					clearance = minf(clearance, Vector2(scene.sightings.current_cell(member) - at).length())
			candidates.append({"cell": at, "clearance": clearance})
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.clearance > b.clearance)
	for candidate in candidates:
		if candidate.clearance < 8.0: break
		if super.route(candidate.cell).is_empty(): continue
		var journey := await traverse(candidate.cell)
		if not failures.is_empty(): return {}
		var observation := await watch("quiet_spur", true)
		return {"road_origin": str(origin), "selected": str(candidate.cell),
			"initial_wildlife_clearance_cells": candidate.clearance, "journey": journey, "watch": observation}
	return {}

func visible_sol_ids() -> Array:
	var result := []
	for member in scene.sightings.members:
		var sprite: Node3D = member.sprite
		if sprite != null and sprite.is_visible_in_tree() and scene.camera.is_position_in_frustum(sprite.global_position):
			result.append(member.id)
	return result

func watch(name: String, require_empty: bool = false) -> Dictionary:
	release_movement()
	var original_azimuth: float = scene.view_azimuth
	var original_distance: float = scene.target_size
	var original_elevation: float = scene.view_elevation
	var framed_empty := false
	# Use only the normal camera's orbit, tilt and zoom limits. Wildlife stays live.
	for elevation in [80.0, 60.0, original_elevation, 15.0]:
		for angle in range(8):
			scene.view_azimuth = float(angle * 45)
			scene.view_elevation = elevation
			scene.target_size = scene.active_view.minimum_distance
			scene.apply_camera()
			await settle(2)
			if visible_sol_ids().is_empty():
				framed_empty = true
				break
		if framed_empty: break
	if require_empty and not framed_empty:
		scene.view_azimuth = original_azimuth
		scene.target_size = original_distance
		scene.view_elevation = original_elevation
		scene.apply_camera()
		return {"cell": str(world.cell), "empty_framing_found": false, "samples": []}
	var start_cell: Vector2i = world.cell
	var start_tick: int = world.persistent_state.activity_tick()
	var samples := []
	var empty_run := 0
	var longest_empty_run := 0
	var wall_start := Time.get_ticks_usec()
	for second in range(9):
		await handle_route_contact()
		await settle(60)
		await capture("%s_%02d" % [name, second])
		var visible_ids := visible_sol_ids()
		empty_run = empty_run + 1 if visible_ids.is_empty() else 0
		longest_empty_run = maxi(longest_empty_run, empty_run)
		samples.append({"frame_interval": second, "wall_seconds": (Time.get_ticks_usec() - wall_start) / 1000000.0,
			"activity_tick": world.persistent_state.activity_tick(), "sols_in_frustum": visible_ids})
	check(world.cell == start_cell, "Stationary observation retains player cell")
	var result := {"cell": str(world.cell), "habitat": world.HABITAT_NAMES[world.terrain.natural_ground(world.cell)],
		"start_tick": start_tick, "end_tick": world.persistent_state.activity_tick(), "samples": samples,
		"empty_framing_found": framed_empty, "longest_empty_capture_run": longest_empty_run,
		"camera_azimuth": scene.view_azimuth, "camera_distance": scene.target_size, "camera_elevation": scene.view_elevation,
		"note": "Nine captures spaced by 60 rendered frames; Sol origin tests are not silhouette or occlusion tests. Wildlife stays enabled; inspect the captures."}
	scene.view_azimuth = original_azimuth
	scene.target_size = original_distance
	scene.view_elevation = original_elevation
	scene.apply_camera()
	return result

func run() -> void:
	output_directory = "res://artifacts/world_exploration/living-road-baseline"
	var seed_value := 2601026
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--output="): output_directory = argument.trim_prefix("--output=")
		if argument.begins_with("--seed="): seed_value = int(argument.trim_prefix("--seed="))
	DirAccess.make_dir_recursive_absolute(output_directory)
	Engine.max_fps = 60
	scene = load("res://scenes/world_3d.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	world = scene.world
	world.new_expedition(seed_value)
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280, 800)
	root.title = "SolHunter living road baseline"
	check(not world.smoke_mode, "Normal simulation enabled")
	check(scene.encounters.settings.enabled and scene.encounters.settings.automatic_contact, "Automatic encounters enabled")
	var road := []
	var meadow := -1
	var woodland := -1
	for x in range(6, world.terrain.LANDMARK_X - 5):
		var at := Vector2i(x, world.terrain.trail_y(x))
		var habitat: int = world.terrain.natural_ground(at)
		road.append({"cell": str(at), "habitat": world.HABITAT_NAMES[habitat], "walkable": world.terrain.fits(at)})
		if habitat == 0 and meadow < 0 and x >= 24: meadow = x
		if habitat == 1 and woodland < 0: woodland = x
	report = {"seed": seed_value, "generation": world.terrain.generation_version,
		"engine": Engine.get_version_info(), "driver": RenderingServer.get_current_rendering_driver_name(),
		"adapter": RenderingServer.get_video_adapter_name(), "viewport": str(root.size),
		"expedition": world.expedition_parameters(), "view": resource_values(scene.active_view),
		"nature": resource_values(scene.active_nature), "atmosphere": resource_values(scene.atmosphere_settings),
		"sightings": resource_values(scene.sightings.settings), "road": road,
		"method": "Normal-input automated stone-trail outbound/return. Normal wildlife/contact/clock; no teleport, weather override, speed-up, save/load or normal save writes. Not human play acceptance.", "stops": []}
	check(meadow >= 0 and woodland >= 0, "Essential road contains meadow and woodland outside anchor clearings")
	if failures.is_empty():
		await settle(120)
		var stops := [mini(meadow, woodland), maxi(meadow, woodland)]
		for x in stops:
			var journey := await traverse(Vector2i(x, world.terrain.trail_y(x)))
			if not failures.is_empty(): break
			report.stops.append({"journey": journey, "watch": await watch("outbound_%d" % x)})
		if failures.is_empty():
			report["sol_free_search"] = []
			var sol_free := false
			for stop in report.stops:
				sol_free = sol_free or int(stop.watch.longest_empty_capture_run) >= 3
			if not sol_free:
				var spur := await quiet_spur()
				report["quiet_spur"] = spur
				if not spur.is_empty():
					sol_free = int(spur.watch.get("longest_empty_capture_run", 0)) >= 3
			report["sol_free_sequence_recorded"] = sol_free
			check(sol_free, "At least three consecutive stationary captures have no Sol origins in the frustum; visual review still required")
			report["return"] = await traverse(Vector2i(stops[0], world.terrain.trail_y(stops[0])))
			report["return_watch"] = await watch("return_%d" % stops[0])
			report["refuge_return"] = await traverse(Vector2i.ZERO)
	report["contacts"] = contacts
	report["failures"] = failures
	FileAccess.open(output_directory + "/review.json", FileAccess.WRITE).store_string(JSON.stringify(report, "\t"))
	release_movement()
	scene.environment.sky = null
	scene.free()
	print("LIVING ROAD BASELINE: %d failures; meadow x=%d woodland x=%d" % [failures.size(), meadow, woodland])
	quit(0 if failures.is_empty() else 1)
