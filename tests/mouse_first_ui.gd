extends SceneTree
const BattleTest = preload("res://tests/battle_test_support.gd")
var checks := 0
var failures := 0
func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)
func _initialize() -> void:
	create_timer(90).timeout.connect(func() -> void: quit(1))
	run.call_deferred()
func key(world: Node2D, code: Key, echo: bool = false) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = true
	event.echo = echo
	world.handle_input(event)
func pointer(scene: Node3D, at: Vector2i) -> Vector2:
	var relative: Vector2 = (scene.world.center(at) - scene.world.camera.position) / 32.0
	return scene.camera.unproject_position(Vector3(relative.x, 0.1, relative.y))
func click(world: Node2D, position: Vector2, code: MouseButton = MOUSE_BUTTON_LEFT, double: bool = false) -> void:
	var event := InputEventMouseButton.new()
	event.position = position
	event.button_index = code
	event.pressed = true
	event.double_click = double
	BattleTest.settle(world.host.battles)
	world.handle_input(event)
	BattleTest.settle(world.host.battles)
func gui_click(at: Vector2) -> void:
	for down in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = at
		event.global_position = at
		event.button_index = MOUSE_BUTTON_LEFT
		event.button_mask = MOUSE_BUTTON_MASK_LEFT if down else 0
		event.pressed = down
		root.push_input(event, true)

func run() -> void:
	root.gui_embed_subwindows = true
	var scene: Node3D = load("res://scenes/world_3d.tscn").instantiate()
	scene.sighting_settings = SightingSettings.new()
	scene.sighting_settings.wilderness_enabled = false
	scene.sighting_settings.movement_enabled = false
	root.add_child(scene)
	var world: Node2D = scene.world
	world.smoke_mode = true
	world.new_expedition(17)
	var member: Dictionary = scene.sightings.members[0]
	world.cell = member.home + Vector2i.LEFT
	world.destination = world.cell
	world.rebuild_world()
	member = scene.sightings.members[0]
	var snapshot: Dictionary = world.persistent_state.snapshot()
	key(world, KEY_R)
	check(world.menu.opened and not world.paused, "R opens the live personal menu")
	key(world, KEY_R)
	key(world, KEY_F)
	check(not world.encounter_active and snapshot == world.persistent_state.snapshot(), "Keyboard world-target shortcuts cannot engage or record a nearby Sol")
	var motion := InputEventMouseMotion.new()
	motion.position = scene.camera.unproject_position(member.sprite.global_position)
	world.handle_input(motion)
	world._process(0) # Coalesced hover resolves once at the next frame boundary.
	check(world.interaction_hint.text.contains("Seedmote") and world.interaction_hint.text.contains("Right-click"), "Hover identifies the pointed Sol and offers mouse actions")
	check(world.persistent_state.snapshot() == snapshot, "Hover is read-only")
	click(world, motion.position)
	check(world.encounter_active and scene.encounters.active_target.id == member.id, "Exploration left-click invokes the first right-click action for the pointed Sol")
	scene.encounters.withdraw()
	click(world, motion.position, MOUSE_BUTTON_RIGHT)
	check(world.observation_menu.visible, "Right-click opens the target menu")
	key(world, KEY_ESCAPE)
	check(not world.observation_menu.visible and not world.paused, "First Escape dismisses the context menu only")
	world.persistent_state.choose_starter(scene.battle_settings.starters[0].snapshot(), 0)
	click(world, motion.position, MOUSE_BUTTON_RIGHT)
	world.observation_menu.id_pressed.emit(1)
	scene.encounters.battle_button.pressed.emit()
	var controller: Node = scene.battles
	var battle: TacticalBattle = controller.session
	check(battle != null, "Mouse context action enters the clicked encounter")
	var release: Vector2i = battle.deployment_tiles()[0]
	for at in battle.deployment_tiles():
		if TacticalBattle.distance(at, battle.enemy_cell) < TacticalBattle.distance(release, battle.enemy_cell) and scene.pointer_cell(pointer(scene, at)) == at:
			release = at
	key(world, KEY_ENTER)
	check(battle.phase == "deployment", "Enter cannot deploy a Sol")
	click(world, pointer(scene, release))
	check(battle.phase == "active", "Pointer click deploys on a legal tile")
	var runtime := [battle.ally_cell, battle.remaining, battle.enemy_hp, battle.ally_hp, battle.round_number]
	for code in [KEY_1, KEY_2, KEY_Q, KEY_SPACE, KEY_ENTER, KEY_TAB, KEY_RIGHT]:
		key(world, code)
	check(runtime == [battle.ally_cell, battle.remaining, battle.enemy_hp, battle.ally_hp, battle.round_number] and controller.aimed_slot == -1, "Keyboard cannot issue tactical actions or move the targeting cursor")
	BattleTest.approach_attack(controller)
	runtime = [battle.ally_cell, battle.remaining, battle.enemy_hp, battle.ally_hp, battle.round_number]
	for frame in range(4):
		await process_frame
	gui_click(controller.move_buttons[0].get_global_rect().get_center())
	check(controller.aimed_slot == 0 and battle.enemy_hp == runtime[2] and battle.ally_cell == runtime[0], "Native GUI move-card click arms targeting without passing through to the world")
	key(world, KEY_ESCAPE)
	check(controller.aimed_slot == -1 and controller.session == battle, "Escape cancels targeting without retreat")
	key(world, KEY_ESCAPE)
	check(controller.battle_menu.visible and controller.session == battle, "Second Escape opens the battle menu without retreat")
	gui_click(controller.move_buttons[0].get_global_rect().get_center())
	check(controller.aimed_slot == -1 and controller.battle_shield.visible, "Battle modal shield blocks the underlying action tray")
	var azimuth: float = scene.view_azimuth
	scene._unhandled_input(motion)
	click(world, pointer(scene, battle.enemy_cell))
	check(scene.view_azimuth == azimuth and runtime == [battle.ally_cell, battle.remaining, battle.enemy_hp, battle.ally_hp, battle.round_number], "Battle menu blocks world commands")
	key(world, KEY_ESCAPE)
	check(not controller.battle_menu.visible, "Escape closes the battle menu")
	key(world, KEY_ESCAPE, true)
	check(not controller.battle_menu.visible, "Held Escape cannot cascade through layers")
	var durable: Dictionary = world.persistent_state.snapshot()
	var framing_cell := battle.ally_cell
	controller.frame_battle()
	check(world.persistent_state.snapshot() == durable and battle.ally_cell == framing_cell, "Explicit framing changes only the camera")
	var focus: Vector3 = scene.camera_focus
	scene.zoom_camera(-1)
	check(scene.camera_focus == focus, "Camera zoom preserves explicit battle framing")
	controller.request_retreat()
	check(controller.retreat_dialog.visible and controller.session == battle, "Requesting retreat does not execute it")
	var enter := InputEventKey.new()
	enter.physical_keycode = KEY_ENTER
	enter.pressed = true
	controller.retreat_dialog.push_input(enter, true)
	check(controller.session == battle and controller.retreat_dialog.visible, "Enter cannot accept a consequential mouse confirmation")
	key(world, KEY_ESCAPE)
	check(not controller.retreat_dialog.visible and controller.session == battle, "Escape cancels retreat confirmation")
	controller.move_buttons[0].pressed.emit()
	var enemy_pointer: Vector2 = Vector2.ZERO
	for node in controller.visuals.get_children():
		if node is SolOrb and node.get_meta("world_cell") == battle.enemy_cell:
			enemy_pointer = scene.camera.unproject_position(node.global_position)
	var hp := battle.enemy_hp
	click(world, enemy_pointer, MOUSE_BUTTON_RIGHT)
	world.observation_menu.id_pressed.emit(0)
	check(battle.enemy_hp == hp and controller.aimed_slot == 0, "Right-click inspection preserves the pending move")
	click(world, enemy_pointer, MOUSE_BUTTON_LEFT, true)
	check(battle.enemy_hp == hp, "Double-click repeat cannot execute an additional command")
	click(world, enemy_pointer)
	check(battle.enemy_hp < hp and controller.aimed_slot == -1, "Left-click commits the previewed attack")
	controller.request_retreat()
	controller.retreat_dialog.confirmed.emit()
	BattleTest.settle(controller)
	check(controller.session == null and world.persistent_state.battle_progress().retreats == 1, "Confirmed retreat commits once through existing outcome authority")
	controller.retreat_dialog.confirmed.emit()
	BattleTest.settle(controller)
	check(world.persistent_state.battle_progress().retreats == 1, "Repeated confirmation cannot replay the result")
	world.new_expedition(17)
	controller.retreat_dialog.confirmed.emit()
	BattleTest.settle(controller)
	check(world.persistent_state.battle_progress().retreats == 0, "State replacement invalidates a stale retreat confirmation")
	if OS.get_cmdline_user_args().has("--capture-ui") and DisplayServer.get_name() != "headless":
		world.cell = scene.sightings.members[0].home + Vector2i.LEFT
		world.destination = world.cell
		world.rebuild_world()
		member = scene.sightings.members[0]
		world.update_pointer_hint(scene.camera.unproject_position(member.sprite.global_position))
		await capture("exploration")
		world.persistent_state.choose_starter(scene.battle_settings.starters[0].snapshot(), 0)
		scene.encounters.approach_individual(member.id)
		scene.encounters.battle_button.pressed.emit()
		await capture("deployment")
		controller.open_battle_menu()
		await capture("battle-menu")
		controller.request_retreat()
		await capture("retreat")
	scene.free()
	print("MOUSE FIRST UI: %d checks, %d failures." % [checks, failures])
	quit(0 if failures == 0 else 1)

func capture(name: String) -> void:
	DirAccess.make_dir_recursive_absolute("res://artifacts/mouse-first-ui")
	for frame in range(4):
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/mouse-first-ui/" + name + ".png")
