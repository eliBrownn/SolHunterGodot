extends SceneTree
## Render-contract checks independent of GPU timing or art judgement.

const SolidChunk = preload("res://scripts/solid_chunk.gd")
var failures := 0
var checks := 0

func check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(description)

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var cells: Array[Dictionary] = []
	for index in range(256):
		cells.append({"ground": WorldTerrain.Ground.MEADOW, "variation": 3, "obstacle": 0, "trail_visible": false})
	cells[0].ground = WorldTerrain.Ground.WATER
	cells[1].obstacle = 1
	cells[2].obstacle = 2
	cells[3].trail_visible = true
	var chunk := SolidChunk.new()
	chunk.build(cells)
	check(chunk.tile_count == 256, "Every prepared cell contributes one ground or water tile")
	check(chunk.get_node("ground").multimesh.instance_count == 255, "Land is solid batched geometry")
	check(chunk.get_node("water").multimesh.instance_count == 1, "Water replaces rather than overlaps its land tile")
	check(chunk.get_node("trail_3").multimesh.instance_count == 1, "Trail mask preserves the original pixel-art paving")
	var trees := chunk.find_children("nature_tree_*", "MultiMeshInstance3D", false, false)
	var rocks := chunk.find_children("nature_rock_*", "MultiMeshInstance3D", false, false)
	check(not trees.is_empty() and trees[0].multimesh.instance_count == 1, "Tree obstacle uses a batched imported 3D mesh")
	check(not rocks.is_empty() and chunk.obstacle_count == 2, "Imported rocks preserve existing obstacle placement")
	check(chunk.get_node("grass_3").multimesh.instance_count == 255, "Original grass artwork covers every land tile")
	var tree_material: StandardMaterial3D = trees[0].multimesh.mesh.surface_get_material(0)
	check(tree_material.billboard_mode == BaseMaterial3D.BILLBOARD_DISABLED and tree_material.albedo_texture != null, "Nature kit uses textured 3D geometry without billboarding")
	# The headless dummy renderer returns identity instead of retaining GPU instance transforms.
	if DisplayServer.get_name() != "headless":
		var land: Transform3D = chunk.get_node("ground").multimesh.get_instance_transform(0)
		var water: Transform3D = chunk.get_node("water").multimesh.get_instance_transform(0)
		check(is_zero_approx(land.origin.y + land.basis.get_scale().y * 0.5), "Walkable land remains at the existing ground plane")
		check(is_equal_approx(water.origin.y + water.basis.get_scale().y * 0.5, -0.22), "Recessed water creates a visible solid bank")
	else:
		print("SOLID GEOMETRY: GPU transform readback checks require a rendered run (2 skipped).")
	check(chunk.batches.is_empty(), "Temporary build buffers are released")
	check(cells[0].ground == WorldTerrain.Ground.WATER and cells[1].obstacle == 1, "Rendering leaves generated source data unchanged")
	chunk.free()
	var scene: Node3D = (load("res://scenes/world_3d.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	var world: Node2D = scene.world
	world.smoke_mode = true
	check(not scene.surface.visible, "Solid mode removes the baked world plane")
	check(scene.solid_chunks.size() == world.chunks.size(), "Solid and simulation chunk lifetimes start aligned")
	var first_coord: Vector2i = world.chunks.keys()[0]
	var old_chunk: WeakRef = weakref(scene.solid_chunks[first_coord])
	world.remove_chunk(first_coord)
	check(not scene.solid_chunks.has(first_coord) and old_chunk.get_ref() != null and not old_chunk.get_ref().visible, "Eviction removes active geometry and hides the bounded reversal-cache entry")
	world.cell = Vector2i(-100, -100)
	world.rebuild_world()
	scene.sync_ground()
	check(scene.solid_chunks.size() == world.chunks.size() and scene.solid_chunks.size() <= scene.stream_capacity(), "Negative-coordinate rebuild retains one bounded frustum-streamed render authority")
	check(scene.solid_root.position == Vector3(-world.camera.position.x / 32.0, 0, -world.camera.position.y / 32.0), "3D ground and upright actor share the same camera-relative origin")
	var old_places: WeakRef = weakref(scene.place_root)
	world.new_expedition(7)
	check(old_places.get_ref() == null and is_instance_valid(scene.place_root), "New seed replaces decorative props without leaking old places")
	check(scene.solid_chunks.size() == world.chunks.size(), "New-seed chunk publication stays aligned")
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
	print("SOLID GEOMETRY: %d checks, %d failures." % [checks, failures])
	quit(0 if failures == 0 else 1)
