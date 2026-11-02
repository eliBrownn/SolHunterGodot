extends "res://tests/first_playable_battle.gd"
## Production readiness UI: pointer access, draft replacement and arena presentation.
var mouse_entered := false
func gui_click(control: Control) -> void:
	if not mouse_entered:
		root.notify_mouse_entered()
		mouse_entered = true
	for down in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = control.get_global_rect().get_center()
		event.global_position = event.position
		event.button_index = MOUSE_BUTTON_LEFT
		event.button_mask = MOUSE_BUTTON_MASK_LEFT if down else 0
		event.pressed = down
		root.push_input(event, true)

func run() -> void:
	root.gui_embed_subwindows = true
	var scene: Node3D = load("res://scenes/world_3d.tscn").instantiate()
	root.add_child(scene)
	var world: Node2D = scene.world
	world.smoke_mode = true
	world.menu.choose_starter(0)
	approach(world, scene)
	var controller: Node = scene.battles
	BattleTest.settle(controller)
	var battle: TacticalBattle = controller.session
	var release: Vector2i = battle.deployment_tiles()[0]
	for at: Vector2i in battle.deployment_tiles():
		if TacticalBattle.distance(at, battle.enemy_cell) > TacticalBattle.distance(release, battle.enemy_cell): release = at
	controller.select_cell(release)
	BattleTest.settle(controller)
	var hud: CombatHud = controller.combat_hud
	var timeline: ReadinessTimeline = controller.playback.timeline
	var grid: MeshInstance3D = controller.storm_outline.get_node("BattleGroundGrid")
	check(grid.get_child_count() == 0, "Quiet board grid has no ember effect")
	var vertices: PackedVector3Array = grid.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var follows_ground := not vertices.is_empty()
	for vertex in vertices:
		var map_at: Vector2 = Vector2(vertex.x, vertex.z) + world.camera.position / 32.0
		if absf(vertex.y - world.host.ground_height(map_at) - 0.045) > 0.001: follows_ground = false
	check(follows_ground, "Grid vertices follow the actual terrain surface")
	var boundary_embers: MultiMeshInstance3D = controller.storm_outline.get_node("PatternEmbers")
	check(boundary_embers.multimesh.instance_count > 0 and boundary_embers.multimesh.instance_count <= 128, "Boundary emits a bounded set of pattern-rooted embers")
	check(timeline != null and timeline.withdrawal_ready(), "Fixture starts beyond opponent reach")
	for at: Vector2i in timeline.preview.reachable():
		if at != release:
			controller.select_cell(at)
			break
	check(not timeline.steps.is_empty(), "A pending draft exists before Run")
	for marker: MeshInstance3D in controller.tile_pool:
		check(marker.mesh is TorusMesh, "Arena markers use open rings instead of filled tiles")
		check(marker.has_node("PatternEmbers"), "Highlight pattern owns its rising embers")
	for frame in range(4): await process_frame
	gui_click(hud.retreat_button)
	check(controller.retreat_dialog.visible and timeline.planning, "Native Run click opens confirmation without spending readiness")
	controller.cancel_retreat()
	check(not timeline.steps.is_empty(), "Cancel Run preserves the existing draft")
	controller.open_battle_menu()
	for frame in range(4): await process_frame
	check(hud.menu_retreat_button.get_global_rect().end.y < controller.battle_menu.get_global_rect().end.y, "Menu Run button fits without scrolling")
	gui_click(hud.menu_retreat_button)
	check(controller.retreat_dialog.visible and not controller.battle_menu.visible, "Native menu Run click reaches confirmation")
	controller.cancel_retreat()
	controller.update_view()
	# Field cues remain distinguishable without painting terrain squares.
	battle.fields[release] = {"kind": "wet", "direction": Vector2i.ZERO, "round": 0, "expires": 3}
	timeline.preview.fields = battle.fields.duplicate(true)
	controller.update_view()
	var field_fx := false
	for marker: MeshInstance3D in controller.tile_pool:
		if marker.visible and marker.material_override is ShaderMaterial: field_fx = true
	check(field_fx, "Active field uses the shared Vastra shader on an open marker")
	if DisplayServer.get_name() != "headless":
		for frame in range(4): await process_frame
		await RenderingServer.frame_post_draw
		DirAccess.make_dir_recursive_absolute("res://artifacts/combat-arena")
		root.get_texture().get_image().save_png("res://artifacts/combat-arena/arena.png")
		controller.open_battle_menu()
		for frame in range(4): await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://artifacts/combat-arena/menu.png")
		controller.close_battle_menu()
	battle.fields.clear()
	timeline.preview.fields.clear()
	controller.request_retreat()
	controller.retreat_dialog.confirmed.emit()
	check(controller.playback.busy and not timeline.planning, "Confirmed Run replaces the draft and commits without a second click")
	BattleTest.settle(controller)
	check(controller.session == null and world.persistent_state.battle_progress().last_result.outcome == "retreat", "Confirmed withdrawal returns to exploration through the outcome authority")
	scene.environment.sky = null
	scene.queue_free()
	await process_frame
	print("COMBAT ARENA UI: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
