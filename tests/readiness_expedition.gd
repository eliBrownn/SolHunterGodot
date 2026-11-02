extends "res://tests/first_playable_battle.gd"
## Controlled integration fixtures exercise production readiness; normal-input
## traversal/observation is independently recorded by review_nature_alpha.gd.
func run() -> void:
	var scene: Node3D = load("res://scenes/world_3d.tscn").instantiate()
	root.add_child(scene)
	var world: Node2D = scene.world
	world.smoke_mode = true
	world.menu.choose_starter(0)
	var controller: Node = scene.battles
	approach(world, scene)
	check(controller.session != null and controller.session.phase == "deployment", "Production encounter creates a readiness battle from actual geography")
	BattleTest.settle(controller)
	var released: Vector2i = controller.session.deployment_tiles()[0]
	controller.select_cell(released)
	BattleTest.settle(controller)
	check(controller.playback.timeline != null and controller.playback.timeline.planning, "Actual battle UI enters a tactical planning pause after deployment")
	var timeline: ReadinessTimeline = controller.playback.timeline
	var tick: int = world.persistent_state.activity_tick()
	var before := timeline.clock
	world.persistent_state.advance_time(1.0)
	controller.advance_resolution(0.5)
	check(world.persistent_state.activity_tick() > tick and timeline.clock == before, "Shared world clock continues while readiness planning freezes local time")
	var hp: int = controller.session.enemy_hp
	var options: Dictionary = timeline.preview.reachable()
	var closest: Vector2i = released
	for cell: Vector2i in options:
		if TacticalBattle.distance(cell, controller.session.enemy_cell) < TacticalBattle.distance(closest, controller.session.enemy_cell): closest = cell
	if closest != released: controller.select_cell(closest)
	var targets: Array = controller.legal_targets(0)
	if not targets.is_empty():
		controller.choose_move(0)
		controller.select_cell(targets[0])
	check(controller.session.enemy_hp == hp and not timeline.steps.is_empty(), "Real UI commands stage an ordered plan without early damage")
	if DisplayServer.get_name() != "headless":
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://artifacts/nature_alpha/readiness-ui-final.png")
	controller.wait_turn()
	check(controller.playback.busy and not timeline.planning, "Commit resumes execution through the actual controller")
	BattleTest.settle(controller)
	check(controller.session != null and timeline.clock > before, "Scheduled execution returns to the next readiness gate")
	# Exhaust exposure through the real scheduler, retaining the individual's HP.
	timeline.tuning.gear_protection = 0
	timeline.exposure = timeline.tuning.blackout_seconds - 0.01
	var identity: String = world.persistent_state.active_sol_view().id
	var remaining_hp: int = controller.session.ally_hp
	var rebuilds := [0]
	world.rebuilt.connect(func() -> void: rebuilds[0] += 1)
	controller.wait_turn()
	BattleTest.settle(controller)
	check(controller.session == null and world.cell == Vector2i.ZERO and not world.encounter_active, "Blackout completes the supported prepared return and resumes exploration")
	check(rebuilds[0] == 0 and world.explorer.position == world.center(Vector2i.ZERO) and world.camera.position == world.explorer.position, "Blackout returns player and camera to camp through streaming without resetting the overworld")
	check(world.persistent_state.active_sol_view().id == identity and world.persistent_state.active_sol_view().hp == remaining_hp, "Emergency recall preserves the released individual's exact identity and HP")
	check(world.persistent_state.battle_progress().last_result.cause == "commander_blackout" and not world.persistent_state.return_prepared(), "Once-only outcome retains the actual blackout cause and used preparation")
	controller.recover()
	check(world.persistent_state.return_prepared() and world.persistent_state.active_sol_view().hp == world.persistent_state.active_sol_view().profile.max_hp, "NPC-independent camp recovery restores ordinary HP and prepares the next outing")
	# A controlled weakened-opponent fixture exercises genuine seeded Seal rolls;
	# it is not presented as an unmodified normal-input combat outing.
	approach(world, scene)
	BattleTest.settle(controller)
	controller.select_cell(controller.session.deployment_tiles()[0])
	BattleTest.settle(controller)
	var captured_id: String = controller.enemy_id
	controller.session.enemy_hp = 1
	for attempt in range(12):
		if controller.session == null: break
		controller.capture_enemy()
		controller.wait_turn()
		BattleTest.settle(controller)
	check(controller.session == null and world.persistent_state.battle_progress().last_result.outcome == "captured", "Scheduled final Seal success disperses the confrontation and completes capture")
	check(world.persistent_state.collection_view().owned.has(captured_id) and world.persistent_state.active_sol_view().id == identity, "Capture admits the actual opponent once and retains the selected companion")
	var original_starter: String = world.persistent_state.battle_progress().starter_id
	approach(world, scene, 1)
	BattleTest.settle(controller)
	var farthest: Vector2i = controller.session.deployment_tiles()[0]
	for cell in controller.session.deployment_tiles():
		if TacticalBattle.distance(cell, controller.session.enemy_cell) > TacticalBattle.distance(farthest, controller.session.enemy_cell): farthest = cell
	controller.select_cell(farthest)
	BattleTest.settle(controller)
	controller.session.ally_hp = 0
	controller.session.phase = "exhaustion"
	controller.after_command()
	check(is_instance_valid(controller.reserve_panel) and controller.reserve_panel.visible, "An exhausted deployed Sol opens the healthy-reserve buffer selection")
	for button: Node in controller.reserve_panel.get_child(0).get_children():
		if button is Button and button.text.begins_with(world.persistent_state.companion_view(captured_id).profile.display_name):
			button.pressed.emit()
			break
	check(world.persistent_state.active_sol_view().id == captured_id and world.persistent_state.companion_view(identity).hp == 0, "Reserve selection preserves both identities and commits the exhausted individual's HP")
	check(world.persistent_state.battle_progress().starter_id == original_starter and controller.playback.timeline.reserve_buffer > 0, "Reserve substitution retains original-starter identity and supplies a live protection buffer")
	# Full-readiness withdrawal fixture starts beyond the opponent's displayed reach.
	controller.retreat()
	controller.wait_turn()
	BattleTest.settle(controller)
	check(controller.session == null and world.persistent_state.battle_progress().last_result.outcome == "retreat", "Readiness withdrawal completes under its previewed range condition")
	scene.queue_free()
	await process_frame
	print("READINESS EXPEDITION: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
