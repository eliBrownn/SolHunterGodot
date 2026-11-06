extends SceneTree
## Real movement/collision and procedural foot placement on production relief.

var failures := 0
var checks := 0
var solved_frames := 0
var max_foot_error := 0.0
var settled_foot_error := 0.0
var review_cliff := Vector2i.ZERO

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	Engine.max_fps = 60
	var scene: Node3D = load("res://scenes/world_3d.tscn").instantiate()
	# This fixture exercises the optional mannequin's procedural feet, not the
	# production rogue's authored animation packs.
	scene.player_model_scene = load("res://scenes/basic_man.tscn")
	root.add_child(scene)
	var world: Node2D = scene.world
	world.smoke_mode = true
	world.new_expedition(17)
	var wall: Vector2i = world.terrain.cabin_footprint.position + Vector2i(-1, 1)
	world.cell = wall
	world.destination = wall
	world.rebuild_world()
	check(not world.can_step(wall, wall + Vector2i.ONE), "Cabin blocks diagonal corner entry")
	check(world.traversal_step(Vector2.ONE.normalized()) == Vector2i.DOWN, "Diagonal wall input slides along the clear direction")
	world.advance_movement(world.expedition_parameters().move_seconds, Vector2.ONE.normalized())
	check(world.cell == wall + Vector2i.DOWN, "Actual movement completes the legal slide")
	check(world.traversal_step(Vector2.RIGHT) == Vector2i.ZERO, "Cardinal wall input still stops at solid geometry")
	# Continuous motion must preserve sub-tile positions and respond immediately.
	world.new_expedition(17)
	var start: Vector2 = world.explorer.position
	var duration: float = world.expedition_parameters().move_seconds
	world.advance_movement(duration * 0.2, Vector2.RIGHT)
	check(world.explorer.position.distance_to(start + Vector2.RIGHT * WorldTerrain.CELL_SIZE * 0.2) < 0.001, "Player moves freely inside a tile")
	var partial: Vector2 = world.explorer.position
	world.advance_movement(duration, Vector2.ZERO)
	check(world.explorer.position == partial and not world.moving, "Releasing input stops immediately without finishing a tile")
	world.advance_movement(duration * 0.1, Vector2.LEFT)
	check(world.explorer.position.x < partial.x, "Reversal takes effect within the same tile")
	partial = world.explorer.position
	world.advance_movement(duration * 0.1, Vector2(0.6, 0.8))
	var displacement: Vector2 = world.explorer.position - partial
	check(displacement.normalized().distance_to(Vector2(0.6, 0.8)) < 0.001, "Analog direction is preserved without eight-way snapping")
	check(world.cell == Vector2i((world.explorer.position / WorldTerrain.CELL_SIZE).floor()), "Continuous position resolves to the occupied terrain tile")
	world.cell = wall
	world.destination = wall
	world.rebuild_world()
	world.advance_movement(duration * 4.0, Vector2.ONE.normalized())
	check(not world.terrain.cabin_footprint.has_point(world.cell), "Large movement intervals cannot tunnel into the cabin")
	world.new_expedition(17)
	var player: Node3D = scene.player_visual
	var gait: Node3D = player.locomotion
	player.sync_art(0.016)
	var initial: Vector3 = gait.feet[0].planted
	world.advance_movement(0.005, Vector2.RIGHT)
	player.sync_art(0.005)
	check(gait.feet[0].planted.is_equal_approx(initial), "Stance foot stays planted while body and camera move")
	var origin: Vector2 = world.camera.position / WorldTerrain.CELL_SIZE
	check(gait.feet[0].target.global_position.is_equal_approx(initial - Vector3(origin.x, 0, origin.y)), "Foot target compensates for camera rebasing")
	var saw_swing := false
	var saw_lift := false
	var finite_targets := true
	var step_starts := 0
	var previous_swing := -1
	for frame in range(100):
		world.advance_movement(0.01, Vector2.RIGHT)
		player.sync_art(0.01)
		if gait.swinging != -1:
			if gait.swinging != previous_swing:
				step_starts += 1
			saw_swing = true
			var foot: Vector3 = gait.feet[gait.swinging].planted
			saw_lift = saw_lift or foot.y > gait.ground_point(Vector2(foot.x, foot.z)).y + 0.001
		for entry in gait.feet:
			finite_targets = finite_targets and entry.target.global_position.is_finite()
		previous_swing = gait.swinging
	check(step_starts >= 2 and step_starts <= 4, "One second of travel uses a calm alternating cadence instead of rapid shuffling")
	check(player.animator.speed_scale <= 0.75, "Underlying locomotion animation also stays slow")
	check(finite_targets, "Procedural targets stay finite during traversal")
	check(saw_swing and saw_lift, "Real travel drives alternating raised steps")
	var frozen: Vector3 = gait.feet[0].planted
	var phase: float = gait.swing_progress
	world.paused = true
	player.sync_art(0.5)
	check(gait.feet[0].planted == frozen and gait.swing_progress == phase, "Pause freezes procedural feet and stride phase")
	world.paused = false
	scene.player_procedural_movement = false
	player.sync_art(0.016)
	check(not gait.solver.active and player.model.rotation == Vector3.ZERO, "Disabling procedural movement restores authored animation")
	scene.player_procedural_movement = true
	world.new_expedition(71)
	player.sync_art(0.016)
	check(gait.solver.active and gait.swinging == -1, "Reconstruction resets foot anchors instead of sweeping old steps")
	check_slope_presentation(scene)
	if DisplayServer.get_name() != "headless":
		scene.target_size = 5.0
		scene.view_elevation = 25.0
		scene.apply_camera()
		gait.solver.modification_processed.connect(func() -> void:
			solved_frames += 1
			for index in range(2):
				var bone: int = gait.solver.get_end_bone(index)
				var foot: Vector3 = player.skeleton.to_global(player.skeleton.get_bone_global_pose(bone).origin)
				var error: float = foot.distance_to(gait.feet[index].target.global_position)
				max_foot_error = maxf(max_foot_error, error)
				if solved_frames > 90:
					settled_foot_error = maxf(settled_foot_error, error))
		for frame in range(40):
			world.advance_movement(1.0 / 60.0, Vector2.RIGHT)
			await process_frame
		# Allow both slower feet to finish their final settling steps.
		for frame in range(60):
			await process_frame
		check(solved_frames > 0, "Leg solver applies procedural targets to the live skeleton")
		check(max_foot_error < player.model_height * 0.1, "Moving feet stay within rig reach without large solver gaps")
		check(settled_foot_error < 0.005, "Settled ankles reach their planted terrain targets")
		print("PROCEDURAL IK: %d frames, moving/settled ankle error %.4f / %.4f cells" % [solved_frames, max_foot_error, settled_foot_error])
		await RenderingServer.frame_post_draw
		DirAccess.make_dir_recursive_absolute("res://artifacts/player_traversal")
		root.get_texture().get_image().save_png("res://artifacts/player_traversal/player.png")
		if OS.get_cmdline_user_args().has("--capture-slopes"):
			world.new_expedition(71)
			world.cell = review_cliff
			world.destination = world.cell
			world.rebuild_world()
			world.paused = true
			scene.target_size = 10.0
			scene.view_elevation = 50.0
			scene.apply_camera()
			for frame in range(45):
				await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://artifacts/player_traversal/slopes.png")
	scene.environment.sky = null
	scene.free()
	print("PLAYER TRAVERSAL: %d checks, %d failures." % [checks, failures])
	quit(0 if failures == 0 else 1)

func check_slope_presentation(scene: Node3D) -> void:
	var world: Node2D = scene.world
	var terrain: WorldTerrain = world.terrain
	var cliff := Vector2i.ZERO
	var found := false
	for y in range(-48, 49):
		for x in range(-48, 49):
			var at := Vector2i(x, y)
			if not terrain.slope_fits(at) and terrain.natural_ground(at) != WorldTerrain.Ground.WATER:
				cliff = at
				found = true
				break
		if found: break
	check(found, "Production relief supplies an unscalable slope for the review")
	if found:
		review_cliff = cliff
		print("SLOPE REVIEW: seed %d, blocked cell %s" % [terrain.world_seed, cliff])
		var chunk := preload("res://scripts/presentation/solid_chunk.gd").new()
		var coord := Vector2i(floori(cliff.x / 16.0), floori(cliff.y / 16.0))
		var local := cliff - coord * 16
		chunk.add_terrain_tile("grass_0", terrain, coord, local.y * 16 + local.x, Color.WHITE, 0.002)
		var uv2: PackedVector2Array = chunk.terrain_surfaces.grass_0[Mesh.ARRAY_TEX_UV2]
		check(uv2.size() == 4 and uv2[0].y >= 2.0 and uv2[3].y == uv2[0].y, "Whole blocked cell carries exposed-rock metadata, including both triangles")
		check(is_equal_approx(fmod(uv2[0].y, 2.0), 1.0 if terrain.lake_distance(cliff) < 2.8 else 0.0), "Cliff classification preserves independent shoreline metadata")
		preload("res://scripts/scenery/meadow_art.gd").add_cell(chunk, terrain, cliff, terrain.sample(cliff), scene.active_nature)
		check(chunk.batches.is_empty(), "Blocked slope has no dense grass hiding the access boundary")
		check(not terrain.fits(cliff), "Rock presentation agrees with the existing traversal owner")
		chunk.free()
	var player: Node3D = scene.player_visual
	player.sync_art(0.0)
	var target: float = scene.ground_height(world.explorer.position / WorldTerrain.CELL_SIZE)
	player.visual_ground_height = target - player.model_height * 0.05
	player.sync_art(0.016)
	check(player.visual_ground_height > target - player.model_height * 0.05 and player.visual_ground_height < target, "Body height softens a terrain-height discontinuity")
	check(absf(player.visual_ground_height - target) <= player.model_height * 0.06, "Height lag stays within knee reach")
	world.paused = true
	var frozen_height: float = player.visual_ground_height
	player.sync_art(0.5)
	check(player.visual_ground_height == frozen_height, "Pause freezes body-height smoothing")
	world.paused = false
	scene.player_height_smoothing = 0.0
	player.sync_art(0.016)
	check(is_equal_approx(player.visual_ground_height, target), "Zero smoothing restores exact body-height following")
	scene.player_height_smoothing = 0.06
	scene.update_camera_pose()
	var camera_target: float = terrain.surface_height(world.camera.position / 32.0)
	scene.camera_ground_y = camera_target - 0.2
	scene.update_camera_pose(0.016)
	var one_frame: float = scene.camera_ground_y
	check(one_frame > camera_target - 0.2 and one_frame < camera_target, "Camera softens vertical changes")
	scene.camera_ground_y = camera_target - 0.2
	scene.update_camera_pose(0.008)
	scene.update_camera_pose(0.008)
	check(is_equal_approx(scene.camera_ground_y, one_frame), "Camera height response is independent of frame partition")
	scene.reset_camera()
	check(is_equal_approx(scene.camera_ground_y, camera_target), "Home immediately resets camera height")
	var invalid := View3DSettings.new()
	invalid.height_smoothing_seconds = NAN
	check(not invalid.valid(), "Nonfinite camera smoothing is rejected")
