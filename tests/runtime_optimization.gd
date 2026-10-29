extends SceneTree
## Equivalence and lifecycle checks for disposable caches and reused presentation.
const Chunk = preload("res://scripts/solid_chunk.gd")
const Job = preload("res://scripts/stream_chunk_job.gd")
const CacheWindow = preload("res://scripts/derived_cache_window.gd")
const Picking = preload("res://scripts/mesh_picking.gd")
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

func geometry(chunk: Node3D) -> Dictionary:
	var result := {}
	for child in chunk.get_children():
		if child is MultiMeshInstance3D:
			result[str(child.name)] = [child.multimesh.mesh, child.multimesh.buffer]
		elif child is MeshInstance3D:
			result[str(child.name)] = [child.mesh.surface_get_arrays(0), child.mesh.surface_get_material(0)]
	return result

## Reference selection deliberately retains the previous exhaustive search.
func exhaustive(scene: Node3D, pointer: Vector2, fallback: Variant, depth: float) -> Array:
	var origin: Vector3 = scene.camera.project_ray_origin(pointer)
	var direction: Vector3 = scene.camera.project_ray_normal(pointer)
	var selected: Variant = fallback
	var subject := ""
	for group in scene.solid_root.get_children():
		if group.get_script() != Chunk or not group.is_visible_in_tree():
			continue
		for object in group.pick_objects:
			if object.get("category", "") == "detail" and scene.active_view.detail_distance > 0 and group.global_position.distance_to(scene.camera.global_position) > scene.active_view.detail_distance:
				continue
			var transform: Transform3D = group.global_transform * object.transform
			var inverse := transform.affine_inverse()
			var hit: Variant = object.bounds.grow(0.02).intersects_ray(inverse * origin, inverse.basis * direction)
			if hit == null or origin.distance_to(transform * hit) >= depth:
				continue
			hit = Picking.ray(object.mesh, inverse * origin, inverse.basis * direction)
			if hit == null:
				continue
			var camera_depth: float = -scene.camera.to_local(transform * hit).z
			var distance: float = origin.distance_to(transform * hit)
			if camera_depth >= scene.camera.near and camera_depth <= scene.camera.far and distance < depth:
				depth = distance
				selected = object.cell
				subject = object.get("subject", "")
	return [selected, subject]

func run() -> void:
	var window := CacheWindow.new(4)
	var values := {}
	for index in range(7):
		window.store(values, index, index * 2)
	check(values.size() == 4 and values.keys() == [3, 4, 5, 6], "Cache rollover retains a bounded working set instead of clearing all entries")
	values.clear()
	window.store(values, -1, 17)
	check(values == {-1: 17}, "Explicit cache clearing resets eviction bookkeeping")
	var terrain := WorldTerrain.new(17)
	var nature: NatureSettings = load("res://resources/nature_settings.tres")
	for coord in [Vector2i.ZERO, Vector2i(-2, -1), Vector2i(3, 3)]:
		var job := Job.new(terrain, coord, nature)
		check(not job.advance(Time.get_ticks_usec()) and job.cells.is_empty(), "An exhausted deadline defers work")
		var finished := false
		for step in range(20000):
			if job.advance(Time.get_ticks_usec() + 50):
				finished = true
				break
		check(finished and job.chunk.get_parent() == null, "Preparation completes without publishing partial nodes")
		var cells := terrain.extract_chunk(coord)
		check(job.cells == cells, "Sliced generation exactly matches synchronous cells, including negative coordinates")
		var direct := Chunk.new()
		direct.build(cells, terrain, coord, nature)
		check(geometry(direct) == geometry(job.chunk), "Sliced vertices, normals, UVs, colors and scenery transforms match synchronous geometry")
		check(direct.pick_objects == job.chunk.pick_objects and direct.pick_bounds == job.chunk.pick_bounds, "Picking index agrees for synchronous and sliced builds")
		direct.free()
		job.discard()
	var first_height := terrain.vertex_height(Vector2i(-17, -16))
	for index in range(65550):
		terrain.vertex_height(Vector2i(index, 260))
	check(terrain._height_cache.size() == 65536, "Long-distance cache turnover preserves the memory ceiling")
	check(terrain.vertex_height(Vector2i(-17, -16)) == first_height, "Evicted heights regenerate exactly")
	var scene: Node3D = load("res://scenes/world_3d.tscn").instantiate()
	root.add_child(scene)
	var world: Node2D = scene.world
	world.smoke_mode = true
	world.new_expedition(17)
	var state: Dictionary = world.persistent_state.snapshot()
	for azimuth in [0.0, 90.0]:
		scene.view_azimuth = azimuth
		scene.apply_camera()
		for y in [0.25, 0.5, 0.75]:
			for x in [0.15, 0.35, 0.5, 0.65, 0.85]:
				var pointer := root.get_visible_rect().size * Vector2(x, y)
				scene.solid_root.hide()
				var fallback: Variant = scene.pointer_cell(pointer)
				var depth: float = scene.pointer_actor_depth
				scene.solid_root.show()
				var expected := exhaustive(scene, pointer, fallback, depth)
				var actual: Variant = scene.pointer_object_cell(pointer, fallback)
				check([actual, scene.pointer_subject] == expected, "Chunk bounds and cached inverses preserve exhaustive nearest opaque selection")
	check(world.persistent_state.snapshot() == state, "Picking never mutates the expedition")
	var coord: Vector2i = world.pending[0]
	scene.prepare_stream_chunk(coord, Time.get_ticks_usec() + 1)
	check(scene.stream_job != null and not world.chunks.has(coord), "A partial stream job remains unpublished")
	# Use an admitted expedition to exercise cancellation (seed 19's bank-grade
	# regression is covered separately by terrain_geography/world_generation).
	world.new_expedition(42)
	check(world.terrain.world_seed == 42 and scene.stream_job == null, "A valid new expedition cancels stale prepared terrain")
	var card: PanelContainer = world.inspection_card
	var reading: Dictionary = world.persistent_state.environment_view(world.cell, world.terrain.sample(world.cell))
	card.update_reading(world.cell, "Refuge", "Meadow", reading, "")
	var card_size: Vector2 = card.size
	card.hide()
	card.update_reading(world.cell, "Refuge", "Meadow", reading, "")
	check(card.visible and card.size == card_size, "Unchanged inspection readings reopen without layout churn")
	reading.conditions = {"barrier": {"level": 1}}
	card.update_reading(world.cell, "Refuge", "Meadow", reading, "")
	check(card.access.text == "Blocked", "In-place condition edits invalidate cached inspection content")
	world.new_expedition(17)
	world.persistent_state.choose_starter(scene.battle_settings.starters[0].snapshot(), 0)
	var member: Dictionary = scene.sightings.members[0]
	world.cell = member.home + Vector2i.LEFT
	world.destination = world.cell
	world.rebuild_world()
	scene.encounters.approach_nearest()
	scene.encounters.battle_button.pressed.emit()
	var controller: Node = scene.battles
	check(controller.session != null, "Reuse test enters a real battle")
	var battle_state: Dictionary = controller.session.view_snapshot()
	var enemy: SolOrb = controller.unit_views.enemy.sprite
	var tile_id: int = controller.tile_pool[0].get_instance_id()
	controller.cursor = controller.session.deployment_tiles().back()
	controller.update_view()
	check(controller.unit_views.enemy.sprite == enemy and controller.tile_pool[0].get_instance_id() == tile_id, "Changed battle layouts retain models and tile nodes")
	check(controller.session.view_snapshot() == battle_state, "Visual reuse leaves authoritative battle state unchanged")
	for index in range(3):
		controller.clear_target_preview()
		controller.preview_tile(world.cell, Color.WHITE, index == 0)
	check(controller.preview_pool.size() == 1 and controller.preview_nodes.size() == 1 and controller.preview_nodes[0].scale == Vector3.ONE, "Preview pool stays bounded and resets scale between uses")
	world.frame_times.clear()
	world.frame_time_cursor = 0
	for index in range(3605):
		# Exercise the real diagnostics path without advancing simulation or streaming.
		world.pending.clear()
		world._process(0)
	check(world.frame_times.size() == 3600 and world.frame_time_cursor == 5, "Frame history wraps without growing or shifting")
	scene.free()
	print("RUNTIME OPTIMIZATION: %d checks, %d failures." % [checks, failures])
	quit(0 if failures == 0 else 1)
