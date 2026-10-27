extends SceneTree
## Shoreline continuity and rendered player-occlusion regression coverage.

const SolidChunk = preload("res://scripts/solid_chunk.gd")
var checks := 0
var failures := 0

func check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(description)

func _initialize() -> void:
	create_timer(90).timeout.connect(func() -> void: quit(1))
	run.call_deferred()

func snapshot() -> Image:
	for frame in range(3):
		await process_frame
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()

func changed_pixels(first: Image, second: Image, region: Rect2i) -> int:
	var changed := 0
	var bounds := region.intersection(Rect2i(Vector2i.ZERO, first.get_size()))
	for y in range(bounds.position.y, bounds.end.y):
		for x in range(bounds.position.x, bounds.end.x):
			var a := first.get_pixel(x, y)
			var b := second.get_pixel(x, y)
			if absf(a.r - b.r) + absf(a.g - b.g) + absf(a.b - b.b) > 0.05:
				changed += 1
	return changed

func run() -> void:
	var cells: Array[Dictionary] = []
	for index in range(256):
		cells.append({"ground": WorldTerrain.Ground.MEADOW, "variation": 3, "obstacle": 0, "trail_visible": false})
	cells[0].ground = WorldTerrain.Ground.WATER
	var chunk := SolidChunk.new()
	chunk.build(cells)
	check(chunk.shoreline_edges == 2, "Only known land-water boundaries receive banks in an isolated fixture")
	check(chunk.get_node("bank").multimesh.instance_count == 2 and chunk.get_node("shore_rim").multimesh.instance_count == 2, "Every shoreline edge receives one bank and pixel rim")
	check(chunk.get_node("water").multimesh.mesh.material is ShaderMaterial, "Water uses pixel-stepped visual shader rather than smooth material")
	check(cells[0].ground == WorldTerrain.Ground.WATER and not cells[0].has("bank"), "Shore visuals do not mutate terrain semantics")
	chunk.free()
	var terrain := WorldTerrain.new(1)
	var found := false
	for cy in range(-6, 7):
		for cx in range(-6, 7):
			var coord := Vector2i(cx, cy)
			var data: Array[Dictionary] = terrain.extract_chunk(coord)
			for index in range(data.size()):
				if data[index].ground != WorldTerrain.Ground.WATER:
					continue
				var local := Vector2i(index % 16, floori(float(index) / 16))
				for direction in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
					var next: Vector2i = local + direction
					if next.x < 0 or next.x >= 16 or next.y < 0 or next.y >= 16:
						check(SolidChunk.neighbor_is_land(data, index, direction, terrain, coord) == (terrain.natural_ground(coord * 16 + next) != WorldTerrain.Ground.WATER), "Chunk-border shoreline queries agree with the canonical neighboring cell")
						found = true
			if found:
				var expected := 0
				for index in range(data.size()):
					if data[index].ground == WorldTerrain.Ground.WATER:
						var local := Vector2i(index % 16, floori(float(index) / 16))
						for direction in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
							if terrain.natural_ground(coord * 16 + local + direction) != WorldTerrain.Ground.WATER:
								expected += 1
				var border_chunk := SolidChunk.new()
				border_chunk.build(data, terrain, coord)
				check(border_chunk.shoreline_edges == expected, "Actual bank geometry has no false seam or missing edge at a chunk border")
				border_chunk.free()
				break
		if found:
			break
	check(found, "Exercised real water on a streamed chunk border")
	var scene: Node3D = (load("res://scenes/world_3d.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	scene.world.smoke_mode = true
	scene.sync_ground()
	check(scene.visibility_aid.source == scene.player_billboard, "Visibility aid follows the real character rather than a second actor authority")
	scene.player_billboard.flip_h = true
	scene.visibility_aid.sync_source()
	check(scene.visibility_aid.indicator_material.get_shader_parameter("flip_h"), "Occluded silhouette preserves directional flipping")
	scene.player_billboard.flip_h = false
	check(SolidChunk.meshes.water.material.get_shader_parameter("world_origin") == scene.world.camera.position / 32.0, "Water pattern is rebased to absolute world coordinates")
	if DisplayServer.get_name() == "headless":
		print("PRESENTATION: depth-buffer pixel comparisons require a rendered run (5 skipped).")
	else:
		await snapshot()
		var player_center: Vector3 = scene.player_billboard.position + scene.camera.global_basis.y * 0.75
		var screen: Vector2 = scene.camera.unproject_position(player_center)
		var region := Rect2i(Vector2i(screen) - Vector2i(24, 32), Vector2i(48, 64))
		scene.visibility_aid.hide()
		var clear_without := await snapshot()
		scene.visibility_aid.show()
		var clear_with := await snapshot()
		var clear_changes := changed_pixels(clear_without, clear_with, region)
		check(clear_changes <= 4, "Unobstructed character is not tinted or revealed through depth")
		var blocker := MeshInstance3D.new()
		var plane := QuadMesh.new()
		plane.size = Vector2(2.2, 2.2)
		blocker.mesh = plane
		blocker.basis = scene.camera.global_basis
		blocker.position = player_center + scene.camera.position.normalized() * 2.0
		var material := StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.albedo_color = Color("344652")
		blocker.material_override = material
		scene.add_child(blocker)
		scene.visibility_aid.hide()
		var hidden_without := await snapshot()
		scene.visibility_aid.show()
		var hidden_with := await snapshot()
		var hidden_changes := changed_pixels(hidden_without, hidden_with, region)
		check(hidden_changes > 40, "Foreground geometry reveals a readable player-only silhouette")
		DirAccess.make_dir_recursive_absolute("res://artifacts/presentation")
		hidden_without.save_png("res://artifacts/presentation/occluded-without.png")
		hidden_with.save_png("res://artifacts/presentation/occluded-with.png")
		# Exercise the real cutout foliage material, including its transparent gaps.
		blocker.mesh = SolidChunk.mesh_for("sprite_tree_upper")
		blocker.material_override = null
		blocker.basis = Basis.IDENTITY
		blocker.position = player_center + scene.camera.position.normalized() * 2.0 - Vector3(0, 0.85, 0)
		scene.visibility_aid.hide()
		var foliage_without := await snapshot()
		scene.visibility_aid.show()
		var foliage_with := await snapshot()
		check(changed_pixels(foliage_without, foliage_with, region) > 20, "Actual sprite foliage triggers the player silhouette")
		var gap_changes := 0
		for y in range(region.position.y, region.end.y):
			for x in range(region.position.x, region.end.x):
				var clear := clear_without.get_pixel(x, y)
				var before := foliage_without.get_pixel(x, y)
				var after := foliage_with.get_pixel(x, y)
				var gap := absf(clear.r - before.r) + absf(clear.g - before.g) + absf(clear.b - before.b) < 0.02
				if gap and absf(before.r - after.r) + absf(before.g - after.g) + absf(before.b - after.b) > 0.05:
					gap_changes += 1
		check(gap_changes <= 4, "Transparent foliage gaps do not falsely tint the unobstructed player")
		foliage_with.save_png("res://artifacts/presentation/foliage-silhouette.png")
		blocker.free()
		var restored := await snapshot()
		check(changed_pixels(clear_with, restored, region) <= 4, "Silhouette disappears immediately when the obstruction is removed")
		print("OCCLUSION PIXELS: clear %d; obstructed %d" % [clear_changes, hidden_changes])
	scene.free()
	print("PRESENTATION: %d checks, %d failures." % [checks, failures])
	quit(0 if failures == 0 else 1)
