extends SceneTree
## Rendered, real-time D0 traversal. Not a hardware-independent CI performance gate.

const OUTPUT := "res://artifacts/d0"
const FRAME_LIMIT := 60
var scene: Node3D
var world: Node2D
var failures: Array[String] = []
var report: Dictionary = {}
var live_chunk_peak := 0
var static_memory_peak := 0.0

func _initialize() -> void:
	create_timer(180).timeout.connect(func() -> void:
		push_error("D0 profile timed out")
		quit(1))
	run.call_deferred()

func check(condition: bool, description: String) -> void:
	if not condition:
		failures.append(description)
		push_error(description)

func metrics(samples: Array[float]) -> Dictionary:
	var sorted := samples.duplicate()
	sorted.sort()
	if sorted.is_empty():
		return {"frames": 0}
	return {"frames": sorted.size(), "p50_ms": sorted[int((sorted.size() - 1) * 0.50)],
		"p95_ms": sorted[int((sorted.size() - 1) * 0.95)],
		"p99_ms": sorted[int((sorted.size() - 1) * 0.99)], "max_ms": sorted.back()}

func observe() -> void:
	live_chunk_peak = maxi(live_chunk_peak, world.chunks.size())
	static_memory_peak = maxf(static_memory_peak, Performance.get_monitor(Performance.MEMORY_STATIC))
	check(world.chunks.size() <= 49, "Live render chunks remain bounded")

func settle(frame_count: int) -> Dictionary:
	var samples: Array[float] = []
	var last := Time.get_ticks_usec()
	for frame in range(frame_count):
		await process_frame
		var now := Time.get_ticks_usec()
		samples.append((now - last) / 1000.0)
		last = now
		observe()
	return metrics(samples)

func route(target: Vector2i) -> Array[Vector2i]:
	var grid := AStarGrid2D.new()
	grid.region = Rect2i(-28, -36, 144, 73)
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	grid.update()
	for y in range(grid.region.position.y, grid.region.end.y):
		for x in range(grid.region.position.x, grid.region.end.x):
			var at := Vector2i(x, y)
			grid.set_point_solid(at, not world.terrain.fits(at))
	return grid.get_id_path(world.cell, target)

func traverse(target: Vector2i) -> Dictionary:
	# Route planning is measured separately, not hidden inside steady-travel samples.
	var planning_start := Time.get_ticks_usec()
	var path := route(target)
	var planning_ms := (Time.get_ticks_usec() - planning_start) / 1000.0
	check(not path.is_empty(), "Profile route exists to %s" % target)
	var samples: Array[float] = []
	var last := Time.get_ticks_usec()
	for i in range(1, path.size()):
		while world.cell != path[i]:
			await process_frame
			var now := Time.get_ticks_usec()
			var wall_delta := (now - last) / 1000000.0
			samples.append(wall_delta * 1000.0)
			last = now
			var change: Vector2i = path[i] - world.cell
			check(absi(change.x) <= 1 and absi(change.y) <= 1, "Controller does not skip route cells")
			var duration: float = world.MOVE_SECONDS * (sqrt(2.0) if change.x != 0 and change.y != 0 else 1.0)
			# Use normal interpolated movement, limiting only to this controller's next waypoint.
			world.advance_movement(minf(wall_delta, (1.0 - world.progress) * duration if world.moving else duration), Vector2(change).normalized())
			observe()
	check(world.cell == target, "Traversal reaches %s" % target)
	var result := metrics(samples)
	result["route_planning_ms"] = planning_ms
	result["route_steps"] = maxi(0, path.size() - 1)
	return result

func capture(name: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	var error := root.get_texture().get_image().save_png(OUTPUT + "/" + name + ".png")
	check(error == OK, "Capture saved: " + name)

func run() -> void:
	Engine.max_fps = FRAME_LIMIT
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	var start := Time.get_ticks_usec()
	scene = (load("res://scenes/world.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	current_scene = scene
	world = scene.world
	world.smoke_mode = true
	var startup_ms := (Time.get_ticks_usec() - start) / 1000.0
	report = {"engine": Engine.get_version_info().string, "os": OS.get_name(),
		"renderer": RenderingServer.get_current_rendering_method(), "display": DisplayServer.get_name(),
		"adapter": RenderingServer.get_video_adapter_name(), "viewport": [root.size.x, root.size.y],
		"frame_cap": FRAME_LIMIT, "seed": world.terrain.world_seed,
		"generation_version": world.terrain.generation_version, "initial_scene_build_ms": startup_ms,
		"method": "Real-time waypoint controller, normal interpolated movement, wall-clock frame intervals; no user input or teleport during travel. Not manual acceptance or an uncapped GPU benchmark."}
	report["warmup"] = await settle(60)
	await capture("camp")
	world.max_generation_ms = 0.0
	world.max_publish_ms = 0.0
	report["outbound"] = await traverse(world.terrain.landmark())
	check(world.visited, "Outbound journey discovers landmark")
	await capture("landmark")
	report["return"] = await traverse(Vector2i.ZERO)
	check(world.returned, "Return journey completes objective")
	report["negative_coordinates"] = await traverse(Vector2i(-20, world.terrain.trail_y(-20)))
	await capture("negative")
	report["negative_return"] = await traverse(Vector2i.ZERO)
	var streaming_generation_ms: float = world.max_generation_ms
	var streaming_publication_ms: float = world.max_publish_ms
	world.toggle_pause()
	var before_pause: Vector2i = world.cell
	report["paused"] = await settle(30)
	check(world.cell == before_pause, "Paused position remains fixed")
	await capture("pause")
	world.toggle_pause()
	var save_path := "user://d0-profile-%d.json" % Time.get_ticks_usec()
	start = Time.get_ticks_usec()
	world.save_game(save_path)
	report["save_ms"] = (Time.get_ticks_usec() - start) / 1000.0
	var saved: Dictionary = ExpeditionSave.read_save(save_path)
	check(not saved.is_empty() and saved.get("returned", false), "Profile save preserves completed journey")
	start = Time.get_ticks_usec()
	world.new_expedition(7)
	report["new_seed_build_ms"] = (Time.get_ticks_usec() - start) / 1000.0
	check(not world.visited and not world.returned, "New expedition clears journey progress")
	start = Time.get_ticks_usec()
	world.load_game(save_path)
	report["load_build_ms"] = (Time.get_ticks_usec() - start) / 1000.0
	check(world.terrain.world_seed == 2601026 and world.returned, "Loading restores seed and journey")
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(save_path + suffix):
			DirAccess.remove_absolute(save_path + suffix)
	report["idle_after_load"] = await settle(60)
	report["live_chunk_peak"] = live_chunk_peak
	report["engine_static_memory_peak_bytes"] = static_memory_peak
	report["travel_chunk_generation_max_ms"] = streaming_generation_ms
	report["travel_chunk_publication_max_ms"] = streaming_publication_ms
	report["failures"] = failures
	var output := FileAccess.open(OUTPUT + "/profile.json", FileAccess.WRITE)
	if output == null:
		push_error("Cannot write D0 profile")
		quit(1)
		return
	output.store_string(JSON.stringify(report, "\t"))
	output.close()
	print("D0 PROFILE: %d failures; report at %s/profile.json" % [failures.size(), OUTPUT])
	scene.free()
	quit(0 if failures.is_empty() else 1)
