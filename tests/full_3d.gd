extends SceneTree

var checks := 0
var failures := 0
const Chunk = preload("res://scripts/presentation/solid_chunk.gd")

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)

func _initialize() -> void:
	create_timer(90).timeout.connect(func() -> void: quit(1))
	run.call_deferred()

func run() -> void:
	var scene: Node3D = load("res://scenes/world_3d.tscn").instantiate()
	root.add_child(scene)
	var world: Node2D = scene.world
	world.smoke_mode = true
	world.new_expedition(17)
	var player: Node3D = scene.player_visual
	var before: Dictionary = world.persistent_state.snapshot()
	var supplied_pieces: Array[Node] = player.model.find_children("*", "MeshInstance3D", true, false)
	check(not supplied_pieces.is_empty() and player.meshes.size() == supplied_pieces.size() and player.skeleton.get_bone_count() >= 20, "Supplied player retains all meshes and its compatible skeleton")
	check(player.meshes[0].get_active_material(0).albedo_color == player.model.skin_color, "The supplied human base receives its configured skin material")
	check(player.animator.has_animation("Idle_A") and player.animator.has_animation("Running_A") and player.animator.has_animation("Walking_A"), "Player adapter exposes idle, running and walking clips")
	world.explorer.walking = true
	player.sync_art()
	check(player.animator.current_animation == "Walking_A", "Normal movement selects the walking clip")
	world.explorer.running = true
	player.sync_art()
	check(player.animator.current_animation == "Running_A", "Actual movement selects the supplied running clip")
	player.animator.advance(0.02)
	var bone: int = player.skeleton.find_bone("shin.L")
	check(bone >= 0, "The supplied human rig retains its animated calf bone")
	if bone >= 0:
		var pose: Transform3D = player.skeleton.get_bone_pose(bone)
		player.animator.advance(0.15)
		check(not player.skeleton.get_bone_pose(bone).is_equal_approx(pose), "Adapted animation tracks actually move player bones")
	world.explorer.walking = false
	world.explorer.running = false
	player.sync_art()
	check(player.animator.current_animation == "Idle_A", "Stopping returns the player to idle")
	world.paused = true
	player.sync_art()
	check(player.animator.speed_scale == 0, "Exploration pause freezes visual idle animation")
	world.paused = false
	player.sync_art()
	check(world.persistent_state.snapshot() == before, "Animation and visual scaling never mutate persistent simulation")
	scene.zoom_camera(-100.0)
	check(is_equal_approx(scene.target_size,2.5),"Close zoom extends to a third-person distance")
	check(scene.camera.position.y>scene.player_height and scene.camera.position.length()>2.0,"Close camera stays outside and above the player")
	check(-scene.camera.rotation_degrees.x<20.0,"Close zoom lowers the viewing angle toward the character perspective")
	scene.reset_camera()
	var tuning := NatureSettings.new()
	check(tuning.valid(), "Connected nature settings resolve to valid resources")
	var cells: Array[Dictionary] = []
	for index in range(256):
		cells.append({"ground": WorldTerrain.Ground.MEADOW, "variation": 3, "obstacle": 0, "trail_visible": false})
	cells[0].obstacle = 1
	cells[1].obstacle = 2
	var chunk := Chunk.new()
	chunk.build(cells, null, Vector2i.ZERO, tuning)
	check(chunk.obstacle_count == 2 and not chunk.pick_objects.is_empty() and chunk.pick_objects.all(func(item: Dictionary) -> bool: return item.category == "rock"), "Retired tree bodies stay absent while rock picking and canonical obstacle counts remain intact")
	var first: Dictionary = chunk.pick_objects[0]
	var bounds: AABB = first.transform * first.bounds
	check(absf(bounds.size.y - tuning.rock_height * 1.02) < 0.01 and absf(bounds.position.y) < 0.01, "Rock normalization uses the connected world-height setting and plants its base")
	check(chunk.find_children("sprite_*", "", false, false).is_empty(), "Default scenery has no billboard tree or rock meshes")
	chunk.free()
	tuning.tree_height = 5
	tuning.rock_height = 1.0
	cells[0].ground = WorldTerrain.Ground.HEATH
	chunk = Chunk.new()
	chunk.build(cells, null, Vector2i.ZERO, tuning)
	first = chunk.pick_objects[0]
	bounds = first.transform * first.bounds
	check(absf(bounds.size.y - tuning.rock_height * 1.02) < 0.01 and chunk.find_children("nature_tree_*", "", false, false).is_empty(), "Connected rock height reaches geometry without reviving the retired heath tree palette")
	check(cells[0].obstacle == 1 and cells[1].obstacle == 2, "Nature art leaves generated source cells intact")
	chunk.free()
	check(scene.place_root.find_children("asset_*", "", false, false).is_empty(), "Authored world props have real volume instead of sprite cutouts")
	for member in scene.sightings.members:
		check(member.sprite.mesh == null and member.sprite.has_method("sync_locomotion") and not member.sprite.halo.visible, "Each wild Sol has a procedural 3D creature body")
	if OS.get_cmdline_user_args().has("--capture-3d") and DisplayServer.get_name() != "headless":
		scene.view_elevation = 40
		scene.view_azimuth = 20
		scene.apply_camera()
		await capture("camp", scene)
		scene.zoom_camera(-100.0)
		await capture("close_camera", scene)
		scene.reset_camera()
		var member: Dictionary = scene.sightings.members[0]
		world.cell = member.home + Vector2i.LEFT
		world.destination = world.cell
		world.rebuild_world()
		player.sync_art()
		world.observation_cell = scene.sightings.current_cell(scene.sightings.members[0])
		world.observation_subject = "Seedmote"
		world.observe_cell()
		await capture("observation", scene)
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
	print("FULL 3D: %d checks, %d failures." % [checks, failures])
	quit(0 if failures == 0 else 1)

func capture(name: String, scene: Node3D) -> void:
	DirAccess.make_dir_recursive_absolute("res://artifacts/full3d")
	for frame in range(300):
		if scene.world.pending.is_empty():
			break
		await process_frame
	scene.update_horizon(1.0)
	for frame in range(4):
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/full3d/%s.png" % name)
