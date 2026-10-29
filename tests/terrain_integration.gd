extends SceneTree
## Production mesh, shared grounding/picking, current save contract and shaped banks.

const Chunk = preload("res://scripts/presentation/solid_chunk.gd")
const Ray = preload("res://scripts/presentation/terrain_ray.gd")
var checks := 0
var failures := 0

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)

func _initialize() -> void:
	create_timer(150).timeout.connect(func() -> void: quit(1))
	run.call_deferred()

func run() -> void:
	var tuning := TerrainReliefSettings.new()
	var parameters := tuning.parameters()
	var unknown := parameters.duplicate(true)
	unknown.script = "unexpected"
	check(not TerrainReliefSettings.valid_parameters(unknown), "Unknown saved relief properties are rejected before Resource assignment")
	var terrain := WorldTerrain.new(17, {}, parameters)
	var flat := parameters.duplicate(true)
	flat.broad_amplitude = 0
	flat.detail_amplitude = 0
	flat.micro_amplitude = 0
	var comparison := WorldTerrain.new(17, {}, flat)
	var point := Vector2(24.3, -16.7)
	check(absf(terrain.surface_height(point)) > 0.1 and is_zero_approx(comparison.surface_height(point)), "Connected relief changes actual generated elevation")
	check(terrain.sample(Vector2i(24, -17)).concentration == comparison.sample(Vector2i(24, -17)).concentration and terrain.wetness_at(Vector2i(24, -17)) == comparison.wetness_at(Vector2i(24, -17)), "Height tuning leaves independent Vastra/moisture channels unchanged")
	for cell in [Vector2i(-17, -16), Vector2i(15, 16), Vector2i(78, 2), Vector2i(1000000, -1000000)]:
		var at := Vector2(cell) + Vector2(0.3, 0.7)
		var hit: Variant = Ray.intersect(terrain, Vector3(at.x, 30, at.y), Vector3.DOWN, 60)
		check(hit != null and absf(hit.y - terrain.display_height(at)) < 0.0001, "Vertical picking matches the shared surface, including negative and distant cells")
		var normal := terrain.surface_normal(at)
		check(normal.is_finite() and normal.y > 0, "Production surface normal is finite and upward")
	var at := Vector2(14.25, 4.75)
	var destination := Vector3(at.x, terrain.surface_height(at), at.y)
	var origin := destination + Vector3(-12, 10, 8)
	var hit: Variant = Ray.intersect(terrain, origin, origin.direction_to(destination), 40)
	check(hit != null and hit.distance_to(destination) < 0.0001, "Oblique picking crosses grid boundaries to the exact triangle")
	check(Ray.intersect(terrain, origin, Vector3.UP, 20) == null, "Upward ray misses ground")
	var water := Vector2i.ZERO
	for y in range(20, 80):
		for x in range(20, 80):
			if terrain.natural_ground(Vector2i(x, y)) == WorldTerrain.Ground.WATER:
				water = Vector2i(x, y)
				break
		if water != Vector2i.ZERO:
			break
	check(water != Vector2i.ZERO, "Pond fixture exists")
	for y in range(20, 80):
		for x in range(20, 80):
			var cell := Vector2i(x, y)
			if terrain.natural_ground(cell) != WorldTerrain.Ground.WATER:
				continue
			var local_level: float = terrain.pond_at(cell).level
			check(is_finite(local_level), "Pond descriptors provide finite horizontal levels")
			for direction in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				if terrain.natural_ground(cell + direction) == WorldTerrain.Ground.WATER:
					check(terrain.pond_at(cell + direction).level == local_level, "Connected pond neighbors retain exactly one water level")
				else:
					var edge := Vector2(cell) + Vector2(0.5, 0.5) + Vector2(direction) * 0.5
					check(is_finite(terrain.surface_height(edge)), "Smooth shoreline triangles retain finite shared ground")
	var coord := Vector2i(1, -1)
	var chunk := Chunk.new()
	chunk.build(terrain.extract_chunk(coord), terrain, coord)
	var arrays: Array = chunk.get_node("ground").mesh.surface_get_arrays(0)
	check(not arrays[Mesh.ARRAY_VERTEX].is_empty(), "Production terrain publishes real curved mesh vertices")
	for vertex: Vector3 in arrays[Mesh.ARRAY_VERTEX]:
		var expected_y := terrain.vertex_height(coord * 16 + Vector2i(roundi(vertex.x), roundi(vertex.z)))
		check(absf(vertex.y - expected_y) < 0.00001, "Production mesh vertices use the canonical final height")
	for object in chunk.pick_objects:
		check(terrain.chunk_of(object.cell) == coord, "Streamed scenery picking retains absolute world coordinates")
	chunk.free()
	var scene: Node3D = load("res://scenes/world_3d.tscn").instantiate()
	scene.terrain_settings = tuning
	root.add_child(scene)
	var world: Node2D = scene.world
	world.smoke_mode = true
	world.new_expedition(17)
	world.cell = Vector2i(24, terrain.trail_y(24))
	world.destination = world.cell
	world.rebuild_world()
	scene.sightings.admit_nearby(Vector2i.ZERO, world.cell)
	scene.player_visual.sync_art()
	scene.sync_ground()
	var absolute: Vector2 = world.explorer.position / 32.0
	check(absf(scene.player_visual.position.y - world.terrain.surface_height(absolute) - 0.06) < 0.0001, "Trainer feet follow elevated ground after reconstruction")
	var target: Vector2i = world.cell + Vector2i.RIGHT
	var sample := Vector2(target) + Vector2(0.25, 0.75)
	var relative: Vector2 = sample - world.camera.position / 32.0
	var screen: Vector2 = scene.camera.unproject_position(Vector3(relative.x, world.terrain.display_height(sample), relative.y))
	var projected: Variant = scene.pointer_world(screen)
	check(projected != null and (projected / 32.0).distance_to(sample) < 0.002, "Live camera picking round trips an elevated triangle")
	var path := "user://terrain-current-%d.json" % Time.get_ticks_usec()
	var expected: Dictionary = world.terrain.relief.duplicate(true)
	var state: Dictionary = world.persistent_state.snapshot()
	world.save_game(path)
	check(not ExpeditionSave.read_save(path).is_empty(), "Elevated expedition saves successfully")
	tuning.broad_amplitude = 0
	world.new_expedition(42)
	world.load_game(path)
	check(world.terrain.relief == expected and world.persistent_state.snapshot() == state, "Current save restores height policy and individuals despite Inspector edits")
	var before: RefCounted = world.terrain
	var invalid := ExpeditionSave.read_save(path)
	invalid.generation_version = 5
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(invalid))
	file.close()
	world.load_game(path)
	check(world.terrain == before, "Incompatible development save never replaces the live terrain")
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(path + suffix):
			DirAccess.remove_absolute(path + suffix)
	if DisplayServer.get_name() != "headless":
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
	scene.environment.sky = null
	scene.free()
	if DisplayServer.get_name() != "headless":
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
	print("TERRAIN INTEGRATION: %d checks, %d failures." % [checks, failures])
	quit(0 if failures == 0 else 1)
