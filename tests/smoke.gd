extends SceneTree
## Integration acceptance: terrain contracts, actual movement, streaming, saves and projection.
var failures: Array[String] = []
var checks := 0

func check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures.append(description)
		push_error(description)

func _initialize() -> void:
	run.call_deferred()

func route(terrain: WorldTerrain, footprint: int) -> Array[Vector2i]:
	var grid := AStarGrid2D.new()
	grid.region = Rect2i(-8, -18, 96, 37)
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	grid.update()
	for y in range(-18, 19):
		for x in range(-8, 88):
			var at := Vector2i(x, y)
			grid.set_point_solid(at, not terrain.fits(at, footprint))
	return grid.get_id_path(Vector2i.ZERO, terrain.landmark())

func run() -> void:
	for seed_value in [1, 2601026, 88881, 2147483646]:
		var terrain := WorldTerrain.new(seed_value)
		check(terrain.chunk_of(Vector2i(-1, -17)) == Vector2i(-1, -2), "Floor division at negative chunk borders")
		var same := WorldTerrain.new(seed_value)
		for coord in [Vector2i(-2, -1), Vector2i.ZERO, Vector2i(2, 0)]:
			check(terrain.extract_chunk(coord) == same.extract_chunk(coord), "Independent deterministic chunks")
		for footprint in [1, 2, 3]:
			var path := route(terrain, footprint)
			check(not path.is_empty(), "Camp/landmark connectivity seed %d footprint %d" % [seed_value, footprint])
			for i in range(1, path.size()):
				check(terrain.can_step(path[i - 1], path[i], footprint), "Path agrees with traversal rules")
		for x in range(-128, 129):
			check(terrain.sample(Vector2i(x, terrain.trail_y(x))).walkable, "Travel spine passable")
	check(WorldTerrain.new(1).extract_chunk(Vector2i(-4, 3)) != WorldTerrain.new(2).extract_chunk(Vector2i(-4, 3)), "Different seeds change wilderness")
	var packed := load("res://scenes/world.tscn") as PackedScene
	var scene := packed.instantiate()
	root.add_child(scene)
	current_scene = scene
	var world: Node2D = scene.world
	world.smoke_mode = true
	check(world.chunks.size() < 49 and not world.pending.is_empty(), "Initial build leaves offscreen chunks for bounded streaming")
	check_visible_chunks(world)
	check(not world.explorer.body.visible, "Ground texture does not duplicate the billboard character")
	check(scene.player_billboard.billboard == BaseMaterial3D.BILLBOARD_ENABLED, "Character remains camera-facing")
	check(is_equal_approx(scene.player_billboard.pixel_size, 1.0 / 32.0), "Billboard uses the terrain pixel scale")
	await process_frame
	var path := route(world.terrain, 1)
	for i in range(1, path.size()):
		walk_to(world, path[i])
		check(world.terrain.sample(world.cell).ground != WorldTerrain.Ground.WATER, "Journey stays on dry ground")
		await process_frame
		check(world.chunks.size() <= 49, "Live chunks bounded during real movement")
	check(world.visited, "Movement triggers landmark discovery")
	path.reverse()
	for i in range(1, path.size()):
		walk_to(world, path[i])
		await process_frame
	check(world.returned, "Movement triggers return to camp")
	world.explorer.facing = Vector2.LEFT
	world.explorer._process(0.0)
	scene.player_billboard.sync_art()
	check(scene.player_billboard.flip_h, "Upright character retains left-facing art")
	check(scene.player_billboard.texture == world.explorer.body.texture, "Billboard reuses the authored directional atlas")
	check(Vector2(scene.player_billboard.position.x, scene.player_billboard.position.z).distance_to((world.explorer.position - world.camera.position) / 32.0) < 0.001, "Billboard feet track the ground shadow")
	var expected: Array = world.terrain.extract_chunk(Vector2i.ZERO)
	world.cell = Vector2i(-100, -100)
	world.plan_chunks()
	check(not world.chunks.has(Vector2i.ZERO), "Distant chunk eviction")
	world.rebuild_world()
	check_visible_chunks(world)
	world.cell = Vector2i.ZERO
	world.rebuild_world()
	check(world.chunks[Vector2i.ZERO].view.cells == expected, "Evicted defaults reconstruct exactly")
	# Isolated save path: never overwrite the player's expedition.
	var save_path := "user://smoke-expedition.json"
	world.save_game(save_path)
	var snapshot := ExpeditionSave.read_save(save_path)
	check(not snapshot.is_empty() and snapshot.returned, "Save and validate expedition")
	world.new_expedition(7)
	check_visible_chunks(world)
	world.load_game(save_path)
	check_visible_chunks(world)
	check(world.terrain.world_seed == 2601026 and world.returned and world.cell == Vector2i.ZERO, "Restore complete live state")
	world.save_game(save_path)
	check(FileAccess.file_exists(save_path + ".bak"), "Replacement preserves backup")
	var custom_climate := {"moisture_frequency": 0.025, "dry_threshold": 0.35, "wet_threshold": 0.62}
	world.terrain = WorldTerrain.new(2601026, custom_climate)
	world.rebuild_world()
	var custom_chunk: Array = world.terrain.extract_chunk(Vector2i(-2, 2))
	world.save_game(save_path)
	world.new_expedition(7)
	world.load_game(save_path)
	check(world.terrain.climate == custom_climate, "Load restores saved climate parameters")
	check(world.terrain.extract_chunk(Vector2i(-2, 2)) == custom_chunk, "Saved climate reproduces terrain after reload")
	var invalid := snapshot.duplicate(true)
	invalid.player = [0.5, 0]
	check(not ExpeditionSave.validate(invalid), "Reject fractional coordinates")
	invalid = snapshot.duplicate(true)
	invalid.generation_version = 999
	check(not ExpeditionSave.validate(invalid), "Reject incompatible generation")
	invalid = snapshot.duplicate(true)
	invalid.climate.dry_threshold = 0.9
	invalid.climate.wet_threshold = 0.1
	check(not ExpeditionSave.validate(invalid), "Reject invalid saved climate")
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	file.store_string("{broken")
	file.close()
	world.load_game(save_path)
	check(world.returned and world.terrain.world_seed == 2601026, "Bad save leaves live state intact")
	var legacy := ExpeditionSave.snapshot(1, Vector2i.ZERO, false, false, 1)
	var old_file := FileAccess.open(save_path, FileAccess.WRITE)
	old_file.store_string(JSON.stringify(legacy))
	old_file.close()
	world.load_game(save_path)
	check(world.terrain.generation_version == WorldTerrain.GENERATION_VERSION and world.terrain.world_seed == 1, "Load migrates the saved generation")
	world.save_game(save_path)
	check(ExpeditionSave.read_save(save_path).get("generation_version") == WorldTerrain.GENERATION_VERSION, "Resaving uses the current generator")
	# Projection round trip at both sides of the viewport, including negative cells.
	for zoom in [16.0, 22.0, 23.0]:
		scene.camera.size = zoom
		for plane_position in [Vector3.ZERO, Vector3(-8, 0, -5), Vector3(8, 0, 5)]:
			var screen: Vector2 = scene.camera.unproject_position(plane_position)
			var ray_origin: Vector3 = scene.camera.project_ray_origin(screen)
			var ray_direction: Vector3 = scene.camera.project_ray_normal(screen)
			var hit: Vector3 = Plane(Vector3.UP, 0).intersects_ray(ray_origin, ray_direction)
			check(hit.distance_to(plane_position) < 0.001, "3D picking round trip at zoom %.0f" % zoom)
	# Test real action events through the 3D scene's input entry point.
	var pause_event := InputEventAction.new()
	pause_event.action = "pause_expedition"
	pause_event.pressed = true
	scene._unhandled_input(pause_event)
	check(world.paused, "Pause action consumed by scene")
	scene._unhandled_input(pause_event)
	check(not world.paused, "Resume action")
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(save_path + suffix):
			DirAccess.remove_absolute(save_path + suffix)
	print("SMOKE: %d checks, %d failures. Generation max %.2f ms; publication max %.2f ms (test process)." % [checks, failures.size(), world.max_generation_ms, world.max_publish_ms])
	scene.free()
	quit(0 if failures.is_empty() else 1)

func walk_to(world: Node2D, next: Vector2i) -> void:
	var from: Vector2i = world.cell
	var change := next - from
	var seconds: float = world.MOVE_SECONDS * (sqrt(2.0) if change.x != 0 and change.y != 0 else 1.0)
	world.advance_movement(seconds, Vector2(change).normalized())
	check(world.cell == next and not world.moving, "Actual movement reaches settled destination")

func check_visible_chunks(world: Node2D) -> void:
	# Include the largest current tree canopy, whose anchor can be offscreen.
	var half_view: Vector2 = world.get_viewport_rect().size * 0.5 + Vector2(40, 120)
	for y in [-1.0, 0.0, 1.0]:
		for x in [-1.0, 0.0, 1.0]:
			var point: Vector2 = world.camera.position + half_view * Vector2(x, y)
			var cell := Vector2i(floori(point.x / 32.0), floori(point.y / 32.0))
			check(world.chunks.has(world.terrain.chunk_of(cell)), "Visible viewport covered immediately after rebuild")
