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

func key(world: Node2D, code: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = true
	world.handle_input(event)

func button_event(code: MouseButton, position: Vector2, pressed: bool = true) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = code
	event.position = position
	event.pressed = pressed
	return event

func pixel(scene: Node3D, cell: Vector2i) -> Vector2:
	var relative: Vector2 = (scene.world.center(cell) - scene.world.camera.position) / 32.0
	return scene.camera.unproject_position(Vector3(relative.x, scene.ground_height(Vector2(cell) + Vector2(0.5, 0.5)), relative.y))

func run() -> void:
	for path in ["res://scenes/world_3d.tscn", "res://scenes/world.tscn"]:
		var scene: Node3D = load(path).instantiate()
		root.add_child(scene)
		var world: Node2D = scene.world
		world.smoke_mode = true
		world.new_expedition(17)
		var initial: Vector3 = scene.camera.position
		scene._unhandled_input(button_event(MOUSE_BUTTON_MIDDLE, Vector2(640, 400)))
		var drag := InputEventMouseMotion.new()
		drag.relative = Vector2(150, 50)
		scene._unhandled_input(drag)
		check(scene.camera.position != initial and scene.view_azimuth != scene.camera_azimuth, "Middle-drag rotates and tilts the camera")
		scene._input(button_event(MOUSE_BUTTON_MIDDLE, Vector2.ZERO, false))
		check(not scene.camera_dragging, "Middle release clears drag even when handled over UI")
		var at := Vector2i(2, 1)
		check(scene.pointer_cell(pixel(scene, at)) == at, "Ground picking follows the adjusted camera")
		var original_size: float = scene.camera.size
		scene._unhandled_input(button_event(MOUSE_BUTTON_WHEEL_UP, Vector2.ZERO))
		check(scene.camera.size < original_size, "Wheel zoom remains adjustable")
		var home := InputEventKey.new()
		home.physical_keycode = KEY_HOME
		home.pressed = true
		scene._unhandled_input(home)
		check(scene.camera.position.is_equal_approx(initial) and scene.camera.size == 22, "Home restores authored camera angles and zoom")
		var before: Dictionary = world.persistent_state.snapshot()
		world.handle_input(button_event(MOUSE_BUTTON_RIGHT, pixel(scene, at)))
		check(world.observation_menu.visible and world.observation_cell == at, "Right click opens Observe for the pointed world tile")
		world.observation_menu.id_pressed.emit(0)
		world.observation_menu.hide()
		check(world.inspected_cell == at and not world.inspection.text.is_empty() and world.persistent_state.snapshot() == before, "Observing terrain displays details without mutating state")
		var member: Dictionary = scene.sightings.members[0]
		world.cell = member.home + Vector2i.LEFT
		world.destination = world.cell
		world.rebuild_world()
		member = scene.sightings.members[0]
		var sol_pixel: Vector2 = scene.camera.unproject_position(member.sprite.global_position)
		check(scene.pointer_cell(sol_pixel) == member.home, "Raised Sol image picks its logical cell")
		world.handle_input(button_event(MOUSE_BUTTON_RIGHT, sol_pixel))
		world.observation_menu.id_pressed.emit(0)
		world.observation_menu.hide()
		check(world.persistent_state.has_discovery(member.id), "Right-click Observe records the selected nearby Sol")
		key(world, KEY_C)
		key(world, KEY_1)
		scene.encounters.approach_individual(member.id)
		scene.encounters.battle_button.pressed.emit()
		var controller: Node = scene.battles
		var battle: TacticalBattle = controller.session
		BattleTest.settle(controller)
		var release: Vector2i = battle.deployment_tiles()[0]
		# The polished HUD disables attacks without a legal target. Release near
		# the opponent on a pickable tile before testing the armed-attack flow.
		for target in battle.deployment_tiles():
			if TacticalBattle.distance(target, battle.enemy_cell) < TacticalBattle.distance(release, battle.enemy_cell) and scene.pointer_cell(pixel(scene, target)) == target:
				release = target
		key(world, KEY_D)
		check(battle.phase == "deployment", "WASD cannot release a combat Sol")
		world.handle_input(button_event(MOUSE_BUTTON_LEFT, pixel(scene, release)))
		check(battle.phase == "active", "Left click deploys the Sol")
		BattleTest.settle(controller)
		# Outside command positions may require a legal approach after the throw.
		if controller.legal_targets(0).is_empty():
			var approach: Vector2i = battle.ally_cell
			var cheapest := 1000000
			var routes := battle.reachable()
			for target: Vector2i in routes:
				var cost := battle.route_cost(battle.ally_cell, routes[target], "ally")
				if cost < cheapest and battle.can_use_for("ally", 0, battle.enemy_cell, target) and scene.pointer_cell(pixel(scene, target)) == target:
					approach = target
					cheapest = cost
			world.handle_input(button_event(MOUSE_BUTTON_LEFT, pixel(scene, approach)))
			BattleTest.settle(controller)
		var ally_cell := battle.ally_cell
		var remaining := battle.remaining
		var action_points := battle.actions_remaining
		key(world, KEY_D)
		check(battle.ally_cell == ally_cell and battle.remaining == remaining and battle.actions_remaining == action_points, "WASD never moves the battle Sol or spends either budget")
		var hp := battle.enemy_hp
		controller.attack_button.pressed.emit()
		check(controller.aimed_slot == 0 and battle.enemy_hp == hp, "Clicking a damage move arms aiming without executing it")
		world.handle_input(button_event(MOUSE_BUTTON_RIGHT, pixel(scene, battle.enemy_cell)))
		world.observation_menu.id_pressed.emit(0)
		world.observation_menu.hide()
		check(battle.enemy_hp == hp and controller.aimed_slot == 0 and world.inspection.text.contains("HP"), "Right-click observation during combat preserves the pending move")
		key(world, KEY_ESCAPE)
		check(controller.session == battle and controller.aimed_slot == -1, "Escape cancels aim before retreat")
		var moved := false
		if not battle.reachable().is_empty():
			for target: Vector2i in battle.reachable():
				if target != ally_cell and scene.pointer_cell(pixel(scene, target)) == target:
					world.handle_input(button_event(MOUSE_BUTTON_LEFT, pixel(scene, target)))
					check(battle.ally_cell == target and battle.remaining + battle.actions_remaining < remaining + action_points, "Click moves the battle Sol using free movement then shared AP")
					moved = true
					break
		check(moved, "A reachable ground tile can be selected outside the raised Sol image")
		world.rebuild_world()
		check(world.inspected_cell == null and not world.observation_menu.visible, "World rebuild clears stale observation UI")
		if OS.get_cmdline_user_args().has("--capture-controls") and DisplayServer.get_name() != "headless":
			scene.view_azimuth = 25
			scene.view_elevation = 50
			scene.apply_camera()
			for frame in range(3):
				await process_frame
			await RenderingServer.frame_post_draw
			DirAccess.make_dir_recursive_absolute("res://artifacts/controls")
			root.get_texture().get_image().save_png("res://artifacts/controls/%s.png" % path.get_file().get_basename())
		scene.free()
	print("MOUSE CONTROLS: %d checks, %d failures." % [checks, failures])
	quit(0 if failures == 0 else 1)
