extends SceneTree

var checks := 0
var failures := 0

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func _initialize() -> void:
	create_timer(150).timeout.connect(func() -> void: quit(1))
	run.call_deferred()

func run() -> void:
	var interval := ExpeditionContract.ACTIVITY_INTERVAL
	for fps in [30, 60, 144]:
		var track := SolMotionTrack.new()
		track.reset(Vector2i.ZERO)
		track.append(Vector2i.RIGHT, interval)
		for frame in range(fps):
			track.advance(interval * 0.8 / fps)
		check(track.position.is_equal_approx(Vector2(0.8, 0)) and track.segments.size() == 1, "Travel still advances at 80 percent of the decision interval at %d FPS" % fps)
		track.advance(interval * 0.2)
		track.append(Vector2i(2, 0), interval)
		check(track.advance(interval * 0.5).is_equal_approx(Vector2(1.5, 0)), "Consecutive steps travel continuously without a mid-stride wait")
	var track := SolMotionTrack.new()
	track.reset(Vector2i.ZERO)
	track.append(Vector2i.UP, interval)
	track.append(Vector2i(-1, -1), interval)
	check(track.advance(interval * 0.5).is_equal_approx(Vector2(0, -0.5)), "Two queued turns retain the first cardinal segment")
	check(track.advance(interval * 0.5).is_equal_approx(Vector2.UP), "A queued turn reaches the corner before changing axis")
	check(track.advance(interval * 0.5).is_equal_approx(Vector2(-0.5, -1)), "The second segment cannot cut diagonally across the corner")
	track.advance(10)
	check(track.position == Vector2(-1, -1) and track.segments.is_empty(), "Large elapsed time consumes the route without overshoot")
	track.reset(Vector2i(8, 5))
	track.append(Vector2i(8, 6), interval)
	track.append(Vector2i(7, 6), interval)
	var cleared_corner := true
	var radius := SolVisualSettings.new().diameter * 0.5
	for frame in range(50):
		var center := track.advance(interval * 2.0 / 50) + Vector2(0.5, 0.5)
		var closest := center.clamp(Vector2(7, 5), Vector2(8, 6))
		cleared_corner = cleared_corner and center.distance_to(closest) >= radius
	check(cleared_corner, "The audit's two skipped turns retain orb clearance around the blocked inside corner")
	for index in range(SolMotionTrack.MAX_SEGMENTS + 2):
		track.append(Vector2i(index, -1), interval)
	check(track.segments.size() <= SolMotionTrack.MAX_SEGMENTS, "Presentation backlog has a fixed recovery ceiling")
	var tuning := SightingSettings.new()
	var goals := {}
	var home_distances := {}
	var position := Vector2i.ZERO
	var previous := Vector2i.ZERO
	var mixed_axes := false
	for leg in range(48):
		var goal := SolRoamingPolicy.next_goal("natural-fixture", leg, Vector2i.ZERO, position, previous, tuning)
		goals[goal] = true
		home_distances[SolRoamingPolicy.distance(goal, Vector2i.ZERO)] = true
		mixed_axes = mixed_axes or (goal.x != 0 and goal.y != 0)
		check(SolRoamingPolicy.distance(goal, Vector2i.ZERO) <= tuning.wander_radius and SolRoamingPolicy.distance(goal, position) >= ceili(tuning.wander_radius * tuning.patrol_goal_min_fraction), "Varied goals obey home bounds and the adjustable minimum leg length")
		check(goal == SolRoamingPolicy.next_goal("natural-fixture", leg, Vector2i.ZERO, position, previous, tuning), "The same saved leg selects the same destination")
		previous = goal
		position = goal
	check(goals.size() > 8 and home_distances.size() > 1 and mixed_axes, "Patrol destinations vary in angle and distance beyond four compass points")
	tuning.patrol_goal_min_fraction = NAN
	check(not tuning.valid(), "Invalid goal tuning rejects before simulation")
	tuning.patrol_goal_min_fraction = 0.5
	tuning.movement_travel_fraction = 0
	check(not tuning.valid(), "Zero travel duration rejects before presentation")
	tuning.movement_travel_fraction = 1
	tuning.wilderness_enabled = false
	tuning.movement_enabled = false
	var scene: Node3D = (load("res://scenes/world_3d.tscn") as PackedScene).instantiate()
	scene.sighting_settings = tuning
	root.add_child(scene)
	var world: Node2D = scene.world
	var sightings: Node3D = scene.sightings
	world.smoke_mode = true
	world.new_expedition(17)
	var member: Dictionary = sightings.members[0]
	var start: Vector2i = member.home
	world.cell = start + Vector2i.LEFT * 2
	world.destination = world.cell
	member.sprite.visible = false
	sightings.sync_views()
	var corner := start
	var finish := start
	for first in [Vector2i.UP, Vector2i.DOWN]:
		for second in [Vector2i.LEFT, Vector2i.RIGHT]:
			if world.can_step(start, start + first) and world.can_step(start + first, start + first + second):
				corner = start + first
				finish = corner + second
	check(finish != start, "A real terrain fixture supports two legal cardinal turns")
	world.persistent_state.advance_time(interval)
	check(world.persistent_state.record_roaming_step(member.id, corner, "return"), "First domain step commits")
	world.persistent_state.advance_time(interval)
	check(world.persistent_state.record_roaming_step(member.id, finish, "return"), "Second domain step commits before a view update")
	sightings.sync_views(interval * 0.5)
	check(member.visual_cell.is_equal_approx(Vector2(start).lerp(Vector2(corner), 0.5)), "World presentation replays both committed steps instead of skipping the turn")
	check(absf(member.sprite.ground_y - world.terrain.surface_height(Vector2(member.visual_cell) + Vector2(0.5, 0.5)) - 0.08) < 0.0001, "Queued movement remains grounded on the displayed interpolated position")
	var visual: Vector2 = member.visual_cell
	var before: Dictionary = world.persistent_state.snapshot()
	world.paused = true
	sightings.sync_views(0.25)
	check(member.visual_cell == visual and world.persistent_state.snapshot() == before, "Pause freezes the partial movement queue and persistent state")
	world.paused = false
	world.encounter_active = true
	sightings.sync_views(0.25)
	check(member.visual_cell == visual, "Encounter entry freezes pending travel")
	world.encounter_active = false
	sightings.sync_views(interval * 0.5)
	check(member.visual_cell.is_equal_approx(Vector2(corner)), "Resume finishes the first segment at the actual corner")
	member.sprite.visible = false
	sightings.sync_views()
	check(member.visual_cell == Vector2(finish) and member.motion.segments.is_empty(), "A culled view reappears at saved position without offscreen playback")
	sightings.rebuild()
	check(world.persistent_state.snapshot() == before, "View reconstruction cannot advance AI or mutate patrol state")
	var old_state: ExpeditionState = world.persistent_state
	world.new_expedition(42)
	var new_motion: SolMotionTrack = sightings.members[0].motion
	var new_position := new_motion.position
	old_state.advance_time(interval)
	old_state.record_roaming_step(member.id, corner, "return")
	check(new_motion.position == new_position and new_motion.segments.is_empty(), "Replaced state cannot enqueue stale movement into a new expedition")
	if OS.get_cmdline_user_args().has("--capture-natural") and DisplayServer.get_name() != "headless":
		await capture_natural(scene)
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
	print("SOL NATURAL MOVEMENT: %d checks, %d failures." % [checks, failures])
	quit(0 if failures == 0 else 1)

func capture_natural(scene: Node3D) -> void:
	var world: Node2D = scene.world
	var sightings: Node3D = scene.sightings
	world.new_expedition(17)
	scene.sighting_settings.movement_enabled = true
	world.smoke_mode = false
	var home: Vector2i = sightings.members[0].home
	world.cell = home + Vector2i(-7, 0)
	world.destination = world.cell
	world.rebuild_world()
	Engine.max_fps = 60
	DirAccess.make_dir_recursive_absolute("res://artifacts/natural_movement/frames")
	for frame in range(120):
		await create_timer(0.1).timeout
		await RenderingServer.frame_post_draw
		var picture := get_root().get_texture().get_image()
		picture.resize(960, 540, Image.INTERPOLATE_LANCZOS)
		picture.save_png("res://artifacts/natural_movement/frames/%03d.png" % frame)
	get_root().get_texture().get_image().save_png("res://artifacts/natural_movement/scene.png")
