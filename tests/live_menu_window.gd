extends SceneTree
var checks := 0
var failures := 0
func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)
func _initialize() -> void:
	create_timer(120).timeout.connect(func() -> void: quit(1))
	run.call_deferred()
func key(world: Node2D, code: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = true
	world.host._unhandled_input(event)
func run() -> void:
	check(ProjectSettings.get_setting("display/window/size/mode") == Window.MODE_MAXIMIZED, "Game starts fitted to the available screen")
	check(ProjectSettings.get_setting("display/window/size/window_width_override", 0) == 0 and ProjectSettings.get_setting("display/window/size/window_height_override", 0) == 0, "No fixed physical startup dimensions override the player screen")
	check(ProjectSettings.get_setting("display/window/stretch/aspect") == "expand", "Game view expands with the player screen proportions")
	root.mode = Window.MODE_WINDOWED
	var scene: Node3D = load("res://scenes/world_3d.tscn").instantiate()
	root.add_child(scene)
	var world: Node2D = scene.world
	world.smoke_mode = true
	world.new_expedition(17)
	var menu: Node = world.menu
	menu.settings.remember_layout = false
	menu.requested_scale = 1.0
	menu.frame.size = menu.settings.window_size
	menu.fit_layout()
	check(not root.unresizable and ProjectSettings.get_setting("display/window/size/resizable"), "Game window explicitly supports resizing")
	check(menu.frame.scale.is_equal_approx(Vector2(0.7, 0.7)), "Default menu dimensions are scaled down by 30 percent")
	world.explorer.walking = true
	menu.open("journal")
	check(not world.paused and world.explorer.walking, "Opening the menu neither pauses nor interrupts an active walk")
	world.smoke_mode = false
	var tick: int = world.persistent_state.activity_tick()
	world._process(1.0)
	check(world.persistent_state.activity_tick() > tick and menu.opened, "Exploration clock continues with menu open")
	world.smoke_mode = true
	var origin: Vector2i = world.cell
	world.advance_movement(world.expedition_parameters().move_seconds, Vector2.RIGHT)
	check(world.cell == origin + Vector2i.RIGHT and menu.opened, "Player can continue walking while the menu is open")
	var player: Node3D = scene.player_visual
	player.sync_art(0.05)
	check(player.animator.speed_scale == 1, "Open field menu keeps the player animation running")
	key(world, KEY_R)
	check(not menu.opened and not world.paused, "R closes the menu without pausing")
	key(world, KEY_R)
	check(menu.opened and not world.paused, "R opens the live menu")
	key(world, KEY_ESCAPE)
	check(world.paused and world.pause_panel.visible and not menu.opened, "Escape replaces the live menu with a real pause screen")
	if OS.get_cmdline_user_args().has("--capture-live-menu") and DisplayServer.get_name() != "headless":
		await capture("pause")
	world.smoke_mode = false
	tick = world.persistent_state.activity_tick()
	world._process(1.0)
	check(world.persistent_state.activity_tick() == tick, "Explicit Escape pause freezes exploration time")
	world.smoke_mode = true
	key(world, KEY_R)
	check(world.paused and not menu.opened, "R cannot open a live menu over the pause screen")
	key(world, KEY_ESCAPE)
	check(not world.paused and not world.pause_panel.visible, "Escape resumes the game")
	key(world, KEY_R)
	var old_size := root.size
	for size in [Vector2i(900, 600), Vector2i(1600, 900), Vector2i(640, 400), Vector2i(1200, 500), Vector2i(700, 900)]:
		root.size = size
		await process_frame
		await process_frame
		menu.fit_layout()
		var bounds := Rect2(menu.frame.position, menu.frame.size * menu.frame.scale)
		var viewport: Vector2 = menu.frame.get_viewport_rect().size
		check(bounds.position.x >= 0 and bounds.position.y >= 0 and bounds.end.x <= viewport.x and bounds.end.y <= viewport.y, "Menu remains reachable after window resize to %s" % size)
		if OS.get_cmdline_user_args().has("--capture-live-menu") and DisplayServer.get_name() != "headless":
			await capture("menu-%dx%d" % [size.x, size.y])
	root.size = old_size
	await process_frame
	# A real encounter supersedes the non-pausing menu and owns its pause state.
	var member: Dictionary = scene.sightings.members[0]
	world.cell = member.home + Vector2i.LEFT
	world.destination = world.cell
	world.moving = false
	world.rebuild_world()
	scene.encounters.approach_individual(member.id)
	check(world.encounter_active and world.paused and not menu.opened, "Encounter entry closes the menu and retains the encounter pause")
	menu.close()
	check(world.paused, "Closing an already closed menu cannot undo an encounter pause")
	scene.encounters.withdraw()
	world.new_expedition(17)
	var before: Dictionary = world.persistent_state.snapshot()
	scene.player_turn_speed_degrees = 540
	world.explorer.facing = Vector2.RIGHT
	player.rotation.y = 0
	player.sync_art(1.0 / 60.0)
	var expected_step := deg_to_rad(9)
	check(is_equal_approx(player.rotation.y, expected_step), "First turning frame moves nine degrees instead of snapping 90 degrees")
	for frame in range(20):
		player.sync_art(1.0 / 60.0)
	check(is_equal_approx(player.rotation.y, PI / 2), "Smooth turn reaches its requested heading")
	player.rotation.y = deg_to_rad(179)
	world.explorer.facing = Vector2(sin(deg_to_rad(-179)), cos(deg_to_rad(-179)))
	player.sync_art(1.0 / 60.0)
	check(absf(angle_difference(player.rotation.y, deg_to_rad(-179))) < 0.001, "Turns cross the angle boundary along the shortest arc")
	world.explorer.facing = Vector2.RIGHT
	player.rotation.y = 0
	player.sync_art(0.05)
	var single_step: float = player.rotation.y
	player.rotation.y = 0
	for frame in range(3):
		player.sync_art(1.0 / 60.0)
	check(is_equal_approx(player.rotation.y, single_step), "Turning speed is independent of frame rate")
	scene.player_turn_speed_degrees = 90
	player.rotation.y = 0
	player.sync_art(0.1)
	check(is_equal_approx(player.rotation.y, deg_to_rad(9)), "Inspector turn-speed changes reach the actual model immediately")
	world.paused = true
	var frozen: float = player.rotation.y
	player.sync_art(0.1)
	check(player.rotation.y == frozen, "A true pause freezes cosmetic turning")
	world.paused = false
	check(world.persistent_state.snapshot() == before, "Visual turning never changes saved movement or gameplay state")
	scene.free()
	print("LIVE MENU WINDOW: %d checks, %d failures." % [checks, failures])
	quit(0 if failures == 0 else 1)
func capture(name: String) -> void:
	DirAccess.make_dir_recursive_absolute("res://artifacts/live-menu")
	for frame in range(4):
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/live-menu/" + name + ".png")
