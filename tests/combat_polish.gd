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

func run() -> void:
	root.mode = Window.MODE_WINDOWED
	var scene: Node3D = load("res://scenes/world_3d.tscn").instantiate()
	scene.sol_visual_settings = SolVisualSettings.new()
	root.add_child(scene)
	var world: Node2D = scene.world
	world.smoke_mode = true
	world.new_expedition(17)
	var controller: Node = scene.battles
	world.persistent_state.choose_starter(scene.battle_settings.starters[0].snapshot(), 0)
	var member: Dictionary = scene.sightings.members[0]
	world.cell = member.home + Vector2i.LEFT
	world.destination = world.cell
	world.rebuild_world()
	var objective_panel: Control = world.objective.get_parent()
	check(objective_panel.visible, "Exploration mission starts visible")
	scene.encounters.approach_nearest()
	scene.encounters.battle_button.pressed.emit()
	var battle: TacticalBattle = controller.session
	var hud: CombatHud = controller.combat_hud
	check(battle != null and hud.visible and not objective_panel.is_visible_in_tree(), "Battle HUD replaces exploration overlays without changing their saved settings")
	check(hud.cards.ally.hp.text == "%d / %d" % [battle.ally_hp, battle.ally.max_hp], "Health card reports exact current and maximum HP")
	check(controller.move_buttons[0].disabled and hud.phase_label.text == "DEPLOYMENT", "Move controls are unavailable before release")
	var release: Vector2i = battle.deployment_tiles()[0]
	for at in battle.deployment_tiles():
		if TacticalBattle.distance(at, battle.enemy_cell) < TacticalBattle.distance(release, battle.enemy_cell) and scene.pointer_cell(scene.camera.unproject_position(controller.point(at))) == at:
			release = at
	controller.cursor = release
	click_cursor(controller)
	check(battle.phase == "active" and battle.ally_cell == release, "Click releases at the selected legal deployment tile")
	# An outside command position may require one approach after the throw.
	# Use the real movement authority before testing an in-range attack preview.
	if controller.legal_targets(0).is_empty():
		var approach: Vector2i = battle.ally_cell
		var cheapest := 1000000
		var routes := battle.reachable()
		for at: Vector2i in routes:
			var cost := battle.route_cost(battle.ally_cell, routes[at], "ally")
			if cost < cheapest and battle.can_use_for("ally", 0, battle.enemy_cell, at):
				approach = at
				cheapest = cost
		controller.select_cell(approach)
		BattleTest.settle(controller)
	var before: Dictionary = world.persistent_state.snapshot()
	var simulation := [battle.ally_hp, battle.enemy_hp, battle.ally_cell, battle.remaining, battle.activity.duplicate(), battle.fields.duplicate(true)]
	controller.choose_move(0)
	check(controller.aimed_slot == 0 and controller.cursor == battle.enemy_cell, "Damage action starts on a meaningful legal enemy target")
	var predicted := mini(battle.enemy_hp, battle.damage_for("ally", battle.ally_moves[0], battle.ally_cell))
	check(hud.target_label.text.contains("%d damage" % predicted), "Damage preview shares the execution calculation")
	check(simulation == [battle.ally_hp, battle.enemy_hp, battle.ally_cell, battle.remaining, battle.activity, battle.fields] and before == world.persistent_state.snapshot(), "Arming and previewing a move consumes no action and changes no saved state")
	key(world, KEY_TAB)
	check(controller.cursor == battle.enemy_cell and controller.aimed_slot == 0, "Keyboard Tab cannot commit or change the selected target")
	key(world, KEY_ESCAPE)
	check(controller.session == battle and controller.aimed_slot == -1 and not hud.cancel_button.visible, "Escape cancels targeting before withdrawing")
	for at in battle.reachable():
		if at != battle.ally_cell:
			controller.cursor = at
			controller.update_target_preview()
			check(controller.preview_nodes.size() == battle.reachable()[at].size() and hud.target_label.text.contains("costs"), "Hover shows the authoritative path and its movement cost")
			break
	controller.choose_move(1)
	check(controller.preview_nodes.size() == battle.field_area(controller.cursor).size(), "Field preview highlights the same shared area as execution")
	controller.sightings.visual_settings.target_previews = false
	controller.update_target_preview()
	check(controller.preview_nodes.is_empty() and world.persistent_state.snapshot() == before, "Preview visibility can be disabled without changing the battle")
	controller.sightings.visual_settings.target_previews = true
	controller.cancel_targeting()
	var actual_hp := battle.ally_hp
	controller.sightings.visual_settings.health_bar_seconds = 0
	battle.ally_hp -= 1
	controller.update_view()
	check(hud.cards.ally.bar.value == battle.ally_hp and hud.cards.ally.hp.text.begins_with(str(battle.ally_hp)), "Zero-duration health animation snaps while numbers remain exact")
	battle.ally_hp = actual_hp
	controller.update_view()
	hud.toggle_log()
	check(hud.log_panel.visible and controller.log_label.text.contains("released"), "Battle log exposes actual recorded events")
	hud.toggle_log()
	var original_moves: Array[Dictionary] = battle.ally_moves.duplicate(true)
	battle.ally_moves.assign([controller.library.find("mend")])
	battle.ally_hp = int(battle.ally.max_hp)
	battle.tile_overloads[battle.ally_cell] = VastraCombat.MIN_OVERLOAD
	controller.update_view()
	check(controller.move_buttons[0].disabled and controller.move_buttons[0].tooltip_text.contains("full HP"), "Full-health healing is disabled with an explanation")
	controller.choose_move(0)
	check(controller.aimed_slot == -1, "Keyboard cannot arm a move without an effective legal target")
	battle.ally_moves = original_moves
	controller.update_view()
	check(battle.ally_moves.size() == 4 and controller.move_buttons[3].visible, "Restoring a four-move loadout restores all move cards")
	var saved: Dictionary = world.persistent_state.snapshot()
	controller.receive_feedback({"kind": "damage", "cell": battle.ally_cell, "amount": 2, "affinity": "earth", "caption": "Impact fixture"})
	world.smoke_mode = false
	controller._process(0.05)
	var reacted := false
	for node in controller.visuals.get_children():
		if node is SolOrb and node.get_meta("world_cell") == battle.ally_cell:
			reacted = node.scale != Vector3.ONE
	check(reacted and world.persistent_state.snapshot() == saved, "Impact reaction is cosmetic while exploration remains paused")
	controller._process(1.0)
	check(controller.impacts.is_empty(), "Impact reactions expire without leaving permanent scale or color state")
	controller.feedback_view.reset()
	world.smoke_mode = true
	var previous_size := root.size
	root.size = Vector2i(900, 600)
	await process_frame
	await process_frame
	var logical_size := hud.get_viewport_rect().size
	check(hud.top.size.y < 160 and hud.tray.position.x >= 0 and hud.tray.get_rect().end.x <= logical_size.x and hud.tray.get_rect().end.y <= logical_size.y, "Health cards and action tray stay within the scaled 900x600 viewport")
	if capture_enabled():
		await capture("compact")
	root.size = previous_size
	await process_frame
	await process_frame
	controller.choose_move(0)
	if capture_enabled():
		await capture("targeting")
	var actual_damage: Array[int] = []
	var enemy_position := battle.enemy_cell
	battle.presentation_event.connect(func(event: Dictionary) -> void:
		if event.kind == "damage" and event.cell == enemy_position:
			actual_damage.append(int(event.amount)))
	click_cursor(controller)
	check(not actual_damage.is_empty() and actual_damage[0] == predicted, "Click commits the aimed attack for exactly the previewed direct damage")
	controller.cancel_targeting()
	controller.retreat()
	BattleTest.settle(controller)
	check(controller.session == null and not hud.visible and objective_panel.is_visible_in_tree() and controller.hidden_exploration.is_empty(), "Battle completion restores exploration HUD visibility")
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
	print("COMBAT POLISH: %d checks, %d failures." % [checks, failures])
	quit(0 if failures == 0 else 1)

func capture_enabled() -> bool:
	return OS.get_cmdline_user_args().has("--capture-polish") and DisplayServer.get_name() != "headless"

func capture(name: String) -> void:
	DirAccess.make_dir_recursive_absolute("res://artifacts/combat-polish")
	for index in range(4):
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/combat-polish/%s.png" % name)

func click_cursor(controller: Node) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	var at: Vector2i = controller.cursor
	var point: Vector3 = controller.point(at)
	for node in controller.visuals.get_children():
		if node is SolOrb and node.get_meta("world_cell") == at:
			point = node.global_position
			break
	event.position = controller.world.host.camera.unproject_position(point)
	BattleTest.settle(controller)
	controller.world.handle_input(event)
	BattleTest.settle(controller)
