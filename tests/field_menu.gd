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

func press(world: Node2D, code: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = true
	world.host._unhandled_input(event)

func mouse_button(at: Vector2, down: bool) -> void:
	var event := InputEventMouseButton.new()
	event.position = at
	event.global_position = at
	event.button_index = MOUSE_BUTTON_LEFT
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if down else 0
	event.pressed = down
	root.push_input(event, true)

func move_pointer(at: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.position = at
	event.global_position = at
	event.button_mask = MOUSE_BUTTON_MASK_LEFT
	root.push_input(event, true)

func inside(menu: Node) -> bool:
	var bounds := Rect2(menu.frame.position, menu.frame.size * menu.frame.scale)
	var size: Vector2 = menu.frame.get_viewport_rect().size
	return bounds.position.x >= 11.9 and bounds.position.y >= 11.9 and bounds.end.x <= size.x - 11.9 and bounds.end.y <= size.y - 11.9

func run() -> void:
	root.mode = Window.MODE_WINDOWED
	var scene: Node3D = load("res://scenes/world_3d.tscn").instantiate()
	root.add_child(scene)
	var world: Node2D = scene.world
	world.smoke_mode = true
	world.new_expedition(17)
	var menu: Node = world.menu
	var prefix := "user://field-menu-%d" % Time.get_ticks_usec()
	menu.preferences_path = prefix + ".cfg"
	menu.save_path = prefix + ".json"
	menu.reset_layout()
	check(menu.settings.valid() and menu.pages.size() == 7, "One menu contains all seven connected sections")
	var before: Dictionary = world.persistent_state.snapshot()
	press(world, KEY_C)
	check(menu.opened and menu.selected == "sols" and not world.paused and not world.encounter_active, "C opens the unified Sols page without a combat lock")
	check(world.hud.get_child(world.hud.get_child_count() - 1) == menu.frame, "Menu is raised above late-built HUD labels")
	for tick in range(4):
		await process_frame
	var frame_rect: Rect2 = menu.frame.get_global_rect()
	var page_rect: Rect2 = menu.page_stack.get_global_rect()
	for nav in menu.navigation.values():
		var nav_rect: Rect2 = nav.get_global_rect()
		move_pointer(nav_rect.get_center())
		for tick in range(3):
			await process_frame
		check(menu.frame.get_global_rect() == frame_rect and menu.page_stack.get_global_rect() == page_rect and nav.get_global_rect() == nav_rect, "Hovering navigation preserves menu and content geometry")
	press(world, KEY_R)
	check(not menu.opened and not world.paused and world.persistent_state.snapshot() == before, "Canceling starter selection grants nothing and resumes safely")
	press(world, KEY_C)
	press(world, KEY_1)
	var hero: Dictionary = world.persistent_state.active_sol_view()
	check(not hero.is_empty() and not menu.opened and not world.paused, "Starter choice reuses the authoritative one-time acquisition and resumes exploration")
	press(world, KEY_R)
	before = world.persistent_state.snapshot()
	for section in menu.SECTIONS:
		menu.navigation[section[0]].pressed.emit()
		check(menu.selected == section[0] and menu.pages[section[0]].visible, "Navigation opens %s in the same menu" % section[1])
	check(world.persistent_state.snapshot() == before, "Browsing menu sections cannot mutate saved gameplay")
	menu.select_page("sols")
	check(is_instance_valid(menu.sol_screen) and not scene.battles.loadout.opened, "List/detail companion controls render inside the unified menu")
	check(menu.sol_screen.use_button.disabled and menu.sol_screen.selected_profile.display_name == hero.profile.display_name, "Active companion is clearly identified without requiring another activation")
	world.smoke_mode = false
	var tick: int = world.persistent_state.activity_tick()
	world._process(1)
	check(world.persistent_state.activity_tick() > tick, "The open menu keeps exploration and atmosphere time running")
	world.smoke_mode = true
	var camera_position: Vector3 = scene.camera.position
	press(world, KEY_HOME)
	var wheel := InputEventMouseButton.new()
	wheel.button_index = MOUSE_BUTTON_WHEEL_UP
	wheel.pressed = true
	scene._unhandled_input(wheel)
	check(scene.camera.position == camera_position, "Menu keyboard/wheel input does not leak to the camera")
	await process_frame
	await process_frame
	var initial_position: Vector2 = menu.frame.position
	var at: Vector2 = menu.header.get_global_rect().position + Vector2(40, 20)
	mouse_button(at, true)
	check(menu.dragging, "Actual GUI press on the header starts dragging")
	move_pointer(at + Vector2(60, 30))
	mouse_button(at + Vector2(60, 30), false)
	check(menu.frame.position.is_equal_approx(initial_position + Vector2(60, 30)) and not menu.dragging, "Actual GUI drag moves the menu and releases capture")
	await process_frame
	var old_size: Vector2 = menu.frame.size
	at = menu.resize_handle.get_global_rect().get_center()
	mouse_button(at, true)
	check(menu.resizing, "Actual GUI press on the resize grip starts resizing")
	move_pointer(at + Vector2(30, 10))
	mouse_button(at + Vector2(30, 10), false)
	check(menu.frame.size.x > old_size.x and menu.frame.size.y > old_size.y and inside(menu), "Actual GUI resize changes panel size while keeping it on screen")
	menu.select_page("options")
	menu.scale_slider.value = 125
	menu.opacity_slider.value = 75
	check(is_equal_approx(menu.requested_scale, 1.25) and inside(menu), "UI scale adjusts live and remains bounded")
	check(is_equal_approx(menu.frame_style.bg_color.a, 0.75) and menu.frame.modulate.a == 1, "Opacity changes the backdrop without fading text")
	menu.save_preferences()
	var saved_position: Vector2 = menu.frame.position
	var saved_size: Vector2 = menu.frame.size
	menu.requested_scale = 0.75
	menu.frame.position = Vector2.ZERO
	check(menu.load_preferences() and menu.frame.position.is_equal_approx(saved_position) and menu.frame.size.is_equal_approx(saved_size) and is_equal_approx(menu.requested_scale, 1.25), "Local menu preferences round-trip independently of expedition saves")
	var bad := ConfigFile.new()
	bad.set_value("menu", "version", 1)
	bad.set_value("menu", "position", Vector2(4, 4))
	bad.set_value("menu", "size", Vector2(900, 600))
	bad.set_value("menu", "scale", 99)
	bad.set_value("menu", "opacity", 0.8)
	bad.save(menu.preferences_path)
	check(not menu.load_preferences() and menu.frame.position.is_equal_approx(saved_position), "Corrupt preferences reject atomically")
	var viewport_size := root.size
	root.size = Vector2i(900, 600)
	await process_frame
	check(inside(menu), "Viewport resizing clamps the menu and adapts effective scale")
	root.size = viewport_size
	await process_frame
	menu.reset_layout()
	menu.select_page("save")
	press(world, KEY_F5)
	check(not ExpeditionSave.read_save(menu.save_path).is_empty(), "Menu save shortcut writes a real validated expedition")
	menu.close()
	world.advance_movement(world.expedition_parameters().move_seconds, Vector2.RIGHT)
	check(world.cell == Vector2i.RIGHT, "Fixture advances after resuming exploration")
	menu.open("save")
	press(world, KEY_F9)
	check(not menu.opened and not world.paused and world.cell == Vector2i.ZERO and world.persistent_state.active_sol_view().id == hero.id, "Menu load restores the same expedition and releases its pause lock")
	world.encounter_active = true
	menu.open("save")
	check(not menu.opened, "Menu cannot bypass an active encounter's save/load guard")
	world.encounter_active = false
	if OS.get_cmdline_user_args().has("--capture-menu") and DisplayServer.get_name() != "headless":
		menu.open("sols")
		await capture("sols")
		menu.select_page("options")
		await capture("options")
		menu.select_page("guide")
		await capture("guide")
		menu.frame.size = menu.settings.minimum_size
		menu.select_page("options")
		await capture("compact")
	menu.close()
	menu.save_timer.stop()
	for suffix in [".cfg", ".json", ".json.bak", ".json.tmp"]:
		if FileAccess.file_exists(prefix + suffix):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(prefix + suffix))
	if DisplayServer.get_name() != "headless":
		await process_frame
		await RenderingServer.frame_post_draw
	scene.environment.sky = null
	scene.free()
	if DisplayServer.get_name() != "headless":
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
	print("FIELD MENU: %d checks, %d failures." % [checks, failures])
	quit(0 if failures == 0 else 1)

func capture(name: String) -> void:
	for frame in range(4):
		await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://artifacts/menu")
	root.get_texture().get_image().save_png("res://artifacts/menu/%s.png" % name)
