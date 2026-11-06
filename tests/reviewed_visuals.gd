extends SceneTree
## Integration journey: admitted art, grounded cover, live Options, stable picking.
var checks := 0
var failures := 0

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)

func _initialize() -> void:
	create_timer(180).timeout.connect(func(): push_error("Reviewed visuals timed out"); quit(1))
	run.call_deferred()

func run() -> void:
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280, 800)
	var scene: Node3D = load("res://scenes/world_3d.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	var world: Node2D = scene.world
	world.smoke_mode = true
	check(scene.active_nature.valid(), "Reviewed main-game palette is admitted")
	var art = preload("res://scripts/scenery/nature_art.gd")
	for asset in scene.active_nature.rocks:
		check(art.parts(asset).supported, "Reviewed rocks retain static picking geometry")
	for biome in scene.active_nature.biomes:
		for entry in biome.details:
			check(not entry.admitted_model().is_empty(), "Reviewed plants retain existing footprint budgets")
	var chosen: Node3D
	for chunk in scene.solid_chunks.values():
		for meadow in chunk.get_children():
			if meadow is MultiMeshInstance3D and meadow.name.begins_with("nature_detail_meadow"):
				chosen = chunk
				check(meadow.multimesh.instance_count > 0 and meadow.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, "Main world publishes batched nonblocking grass")
		if chosen != null: break
	check(chosen != null, "Active view contains expansive grass")
	var probe := preload("res://scripts/presentation/solid_chunk.gd").new()
	probe.cell_origin = chosen.cell_origin if chosen != null else Vector2i.ZERO
	var meadow_art = preload("res://scripts/scenery/meadow_art.gd")
	for z in range(16):
		for x in range(16):
			var cell: Vector2i = probe.cell_origin + Vector2i(x, z)
			meadow_art.add_cell(probe, world.terrain, cell, world.terrain.sample(cell), scene.active_nature)
			if not probe.batches.is_empty(): break
		if not probe.batches.is_empty(): break
	check(not probe.batches.is_empty(), "Canonical free ground admits meadow cover")
	if not probe.batches.is_empty():
		var first: Transform3D = probe.batches.values()[0][0].transform
		var absolute := Vector2(first.origin.x + probe.cell_origin.x, first.origin.z + probe.cell_origin.y)
		var expected_y: float = world.terrain.surface_height(absolute) - meadow_art.mesh().get_aabb().position.y * first.basis.get_scale().y
		check(absf(first.origin.y - expected_y) < 0.001, "Grass roots follow the canonical terrain")
		var source_colors: Variant = meadow_art.mesh().surface_get_arrays(0)[Mesh.ARRAY_COLOR]
		check(source_colors == null or source_colors.is_empty(), "Grass mesh masks cannot multiply the habitat tint")
	probe.free()
	var before: Dictionary = world.terrain.sample(world.cell).duplicate(true)
	var pointer := Vector2(640, 400)
	var ray: Vector3 = scene.camera.project_ray_normal(pointer)
	world.menu.open("options")
	var pixels := world.menu.frame.find_child("PixelEffect", true, false) as OptionButton
	check(pixels != null, "In-game Options exposes the pixel adjustor")
	for level in [0, 2, 3, 5, 3]:
		pixels.select(level)
		pixels.item_selected.emit(level)
		check(scene.pixel_effect.level == level and scene.active_view.pixel_effect_level == level, "Options applies pixel strength immediately")
		check(scene.camera.project_ray_normal(pointer).is_equal_approx(ray), "Pixel strength preserves screen-space world picking")
	check(before == world.terrain.sample(world.cell), "Graphics controls do not mutate terrain state")
	world.menu.close()
	if "--capture-visuals" in OS.get_cmdline_user_args():
		var directory := "res://artifacts/visual_install/game"
		DirAccess.make_dir_recursive_absolute(directory)
		for level in [0, 3]:
			scene.view_settings = scene.active_view.duplicate(false)
			scene.view_settings.pixel_effect_level = level
			scene.apply_view_settings()
			for frame in range(20): await process_frame
			await RenderingServer.frame_post_draw
			check(root.get_texture().get_image().save_png(directory + "/world_%d.png" % level) == OK, "Rendered game captured")
		world.menu.open("options")
		for frame in range(3): await process_frame
		await RenderingServer.frame_post_draw
		check(root.get_texture().get_image().save_png(directory + "/options.png") == OK, "Pixel controls captured with full-resolution HUD")
		world.menu.close()
		scene.view_settings.pixel_effect_level = 0
		scene.apply_view_settings()
		scene.zoom_camera(10.0 - scene.target_size)
		for frame in range(25): await process_frame
		await RenderingServer.frame_post_draw
		check(root.get_texture().get_image().save_png(directory + "/foliage_close.png") == OK, "Foliage captured at closer gameplay zoom")
	scene.environment.sky = null
	scene.free()
	print("REVIEWED VISUALS: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
