extends "res://tests/runtime_optimization.gd"
## Correctness/lifecycle regressions, without machine-dependent timing assertions.
const Ground = preload("res://scripts/presentation/streaming_ground.gd")

func brute_ray(mesh: Mesh, origin: Vector3, direction: Vector3) -> Variant:
	var closest: Variant = null
	for surface in range(mesh.get_surface_count()):
		var arrays := mesh.surface_get_arrays(surface)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		var row := {"vertices": vertices, "uv": arrays[Mesh.ARRAY_TEX_UV], "material": mesh.surface_get_material(surface)}
		var count := indices.size() if not indices.is_empty() else vertices.size()
		for offset in range(0, count - 2, 3):
			var a := indices[offset] if not indices.is_empty() else offset
			var b := indices[offset + 1] if not indices.is_empty() else offset + 1
			var c := indices[offset + 2] if not indices.is_empty() else offset + 2
			var hit: Variant = Geometry3D.ray_intersects_triangle(origin, direction, vertices[a], vertices[b], vertices[c])
			if hit != null and Picking.opaque(row, a, b, c, hit) and (closest == null or origin.distance_squared_to(hit) < origin.distance_squared_to(closest)):
				closest = hit
	return closest

func run() -> void:
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	var image := Image.create(4, 4, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	image.set_pixel(1, 1, Color.TRANSPARENT)
	image.set_pixel(2, 2, Color.TRANSPARENT)
	material.albedo_texture = ImageTexture.create_from_image(image)
	var sphere := SphereMesh.new()
	sphere.material = material
	Picking.prepare(sphere)
	for x in range(-6, 7):
		for y in range(-6, 7):
			for direction in [Vector3.FORWARD, Vector3.BACK]:
				var origin := Vector3(x * 0.1, y * 0.2, -direction.z * 3)
				var expected: Variant = brute_ray(sphere, origin, direction)
				var actual: Variant = Picking.ray(sphere, origin, direction)
				check((expected == null and actual == null) or (expected != null and actual != null and expected.is_equal_approx(actual)), "Binned picking agrees with exhaustive alpha picking")
	var scene: Node3D = load("res://scenes/world_3d.tscn").instantiate()
	root.add_child(scene)
	var world: Node2D = scene.world
	world.smoke_mode = true
	var before: Dictionary = world.persistent_state.snapshot()
	var member: Dictionary = scene.sightings.members[0]
	var original_model: Node3D = member.sprite
	var original_motion: SolMotionTrack = member.motion
	scene.sightings.elapsed = 2.0
	scene.sightings.rebuild(true)
	check(scene.sightings.members_by_id[member.id].sprite == original_model and scene.sightings.members_by_id[member.id].motion == original_motion and scene.sightings.elapsed == 2.0, "Local admission preserves existing models and animation tracks")
	var ids: Array = world.persistent_state.individual_ids()
	ids.clear()
	check(not world.persistent_state.individual_ids().is_empty(), "Membership reads cannot mutate authoritative identities")
	var coord: Vector2i = world.chunks.keys()[0]
	var original: Node3D = scene.solid_chunks[coord]
	world.remove_chunk(coord)
	check(not original.visible and scene.retained_solid[coord] == original, "Removed detailed scenery is retained hidden")
	var prepared: Variant = scene.prepare_stream_chunk(coord, Time.get_ticks_usec())
	check(prepared != null, "Retained detailed geometry is ready without rebuilding")
	world.publish_chunk(coord, prepared)
	check(scene.solid_chunks[coord] == original and original.visible, "Reversal restores the same detailed node")
	check(scene.detail_cache_reuses == 1, "Restoration uses the detailed cache")
	var ground := Ground.new()
	scene.solid_root.add_child(ground)
	var pending: Array[Vector2i] = []
	for candidate: Vector2i in scene.stream_plan():
		if scene.chunk_visible(candidate):
			pending.append(candidate)
			break
	var origin: Vector2 = world.camera.position / 32.0
	ground.sync(world.terrain, pending, scene.camera, origin, scene.height_bound(), 4, 2, Time.get_ticks_usec() - 1)
	check(ground.builds == 0, "Expired shared budget does not start temporary geometry")
	ground.sync(world.terrain, pending, scene.camera, origin, scene.height_bound(), 4, 2)
	check(ground.builds == 1, "An unchanged view resumes its unfinished temporary coverage")
	check(world.persistent_state.snapshot() == before, "Rendering caches do not change expedition state")
	ground.free()
	var settings: OwnedCompanionSettings = scene.companion.settings.duplicate(true)
	var cache := preload("res://scripts/core/runtime_validation_cache.gd").new()
	check(cache.check(settings), "Companion tuning is admitted")
	cache.check(settings)
	check(cache.validation_runs == 1, "Unchanged companion tuning skips full revalidation")
	settings.behavior_library.definitions[0].priority = 101
	check(not cache.check(settings) and cache.validation_runs == 2, "Invalid nested behavior edits invalidate companion admission")
	scene.active_view = scene.active_view.duplicate()
	scene.active_view.stream_detail_cache_chunks = 1
	var coordinates: Array = world.chunks.keys()
	world.remove_chunk(coordinates[0])
	world.remove_chunk(coordinates[1])
	check(scene.retained_solid.size() == 1, "Detailed cache capacity is bounded")
	var old: WeakRef = weakref(scene.retained_solid.values()[0])
	world.new_expedition(42)
	check(old.get_ref() == null and scene.retained_solid.is_empty(), "New worlds cannot reuse stale cached detailed scenery")
	scene.free()
	print("STUTTER REGRESSIONS: %d checks, %d failures." % [checks, failures])
	quit(0 if failures == 0 else 1)
