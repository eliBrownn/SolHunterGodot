extends SceneTree
const BattleTest = preload("res://tests/battle_test_support.gd")
var checks := 0
var failures := 0

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func _initialize() -> void:
	create_timer(90).timeout.connect(func() -> void: quit(1))
	run.call_deferred()

func press(world: Node2D, key: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = key
	event.pressed = true
	world.handle_input(event)

func run() -> void:
	var profiles: BattleSettings = preload("res://resources/battle_settings.tres")
	var domain := TacticalBattle.prepare(WorldTerrain.new(17), Vector2i.ZERO, Vector2i(3, 0), profiles.starters[0].snapshot(), 40, profiles.opponents[1].snapshot(), profiles)
	domain.deploy(Vector2i(1, 0))
	var library: MoveLibrary = preload("res://resources/move_library.tres")
	var healing_book := library.book("rillfin")
	healing_book.equipped = ["mend"]
	domain.set_movebooks(healing_book, library.book("seedmote"))
	var events: Array[Dictionary] = []
	domain.presentation_event.connect(func(event: Dictionary) -> void: events.append(event.duplicate(true)))
	domain.use_move(0, domain.ally_cell)
	domain.wait_turn()
	var hp_events := events.filter(func(event: Dictionary) -> bool: return event.kind in ["heal", "damage"])
	check(hp_events.size() == 2 and hp_events[0].kind == "heal" and hp_events[0].amount == 4 and hp_events[1].kind == "damage" and hp_events[1].amount == 4, "Separate HP cues report capped healing and enemy damage even when net HP change is zero")
	var scene: Node3D = (load("res://scenes/world_3d.tscn") as PackedScene).instantiate()
	BattleTest.use_turn_fixture(scene)
	var source: BattleSettings = preload("res://resources/battle_settings.tres")
	var settings := BattleSettings.new()
	for profile in source.starters:
		settings.starters.append(profile.duplicate(true))
	for profile in source.opponents:
		settings.opponents.append(profile.duplicate(true))
	scene.battle_settings = settings
	scene.sol_visual_settings = SolVisualSettings.new()
	root.add_child(scene)
	var world: Node2D = scene.world
	world.smoke_mode = true
	world.new_expedition(17)
	var controller: Node = scene.battles
	var feedback: Node3D = controller.feedback_view
	check(not feedback.result_panel.visible and feedback.cues.is_empty(), "New expedition has no stale outcome or combat cues")
	var before_preparation: Dictionary = world.persistent_state.snapshot()
	var board: Node3D = controller.get_node("PreparedBoardRendering")
	var prepared_feedback: Node3D = feedback.prepared_rendering
	controller.prepare_board_rendering()
	feedback.prepare_feedback_rendering()
	check(controller.get_node("PreparedBoardRendering") == board and feedback.prepared_rendering == prepared_feedback, "Rendering preparation is idempotent and retains its original resources")
	check(not board.visible and not prepared_feedback.visible and board.process_mode == Node.PROCESS_MODE_DISABLED and prepared_feedback.process_mode == Node.PROCESS_MODE_DISABLED, "Prepared effects stay hidden and do not run gameplay processing")
	check(board.get_node("PreparedFieldMarker").material_override is ShaderMaterial and board.get_node("PreparedBoundary").mesh is ImmediateMesh and board.get_node("PreparedGrid").mesh is ImmediateMesh, "Startup admits field, boundary and grid rendering variants")
	check(prepared_feedback.get_child_count() == 2 and feedback.cues.is_empty(), "Feedback rendering variants never enter the live cue queue")
	for particle: GPUParticles3D in prepared_feedback.find_children("*", "GPUParticles3D", true, false):
		check(not particle.emitting, "Prepared optional impact particles cannot emit")
	check(feedback.ring_texture() == feedback.ring_texture(), "Startup and live feedback share the generated ring texture")
	check(world.persistent_state.snapshot() == before_preparation and controller.session == null, "Pipeline preparation never starts combat or changes saved state")

	if OS.get_cmdline_user_args().has("--loading-smoke"):
		scene.process_mode = Node.PROCESS_MODE_DISABLED
		var menu: Node = load("res://scenes/start_menu.tscn").instantiate()
		root.add_child(menu)
		scene.reparent(menu)
		menu.move_child(scene, 0)
		menu.game = scene
		menu.loading = true
		world.startup_loading = true
		var saved: Dictionary = world.persistent_state.snapshot()
		await menu.prepare_rendering()
		await menu.prepare_rendering()
		check(menu.rendering_prepared and menu.loading and not menu.entered, "Visual preparation finishes while the loading barrier still owns admission")
		check(scene.get_node_or_null("LoadingRenderSamples") == null and feedback.cues.is_empty(), "Disposable samples leave no live cue or preparation tree")
		check(world.persistent_state.snapshot() == saved and controller.session == null, "Visible preparation leaves the authoritative snapshot and combat untouched")
		for frame in range(16): await process_frame
		print("PIPELINES AFTER VISIBLE LOADING: ", pipeline_counts())
		if DisplayServer.get_name() == "headless":
			scene.environment.sky = null
			menu.free()
			print("LOADING PREPARATION: %d checks, %d failures." % [checks, failures])
			quit(0 if failures == 0 else 1)
			return
		if DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://artifacts/vastra-loading-followup/loading.png")

		for child in menu.get_children():
			if child != scene: child.hide()
		var pipeline_before: Dictionary = pipeline_counts()
		for species in ["sol_species_0010", "sol_species_0011"]:
			var model := SolSpeciesView.create(species,"earth",scene.sol_visual_settings)
			scene.add_child(model)
			model.global_position = scene.camera.global_transform * Vector3(0,0,-4.0)
			for frame in range(16): await process_frame
			await RenderingServer.frame_post_draw
			model.free()
		var pipeline_after: Dictionary = pipeline_counts()
		print("PIPELINES AFTER CREATURE REUSE: ", pipeline_after)
		check(pipeline_after["PIPELINE_COMPILATIONS_DRAW"] == pipeline_before["PIPELINE_COMPILATIONS_DRAW"] and pipeline_after["PIPELINE_COMPILATIONS_SURFACE"] == pipeline_before["PIPELINE_COMPILATIONS_SURFACE"], "Prepared creature variants require no additional draw or surface pipelines in this check")
		await pipeline_smoke(scene, "res://artifacts/vastra-loading-followup/live-feedback.png")
		return
	if capture_enabled() or OS.get_cmdline_user_args().has("--pipeline-smoke"):
		await process_frame
		await RenderingServer.frame_post_draw
		print("PIPELINES AFTER STARTUP: ", pipeline_counts())
	if OS.get_cmdline_user_args().has("--pipeline-smoke"):
		await pipeline_smoke(scene)
		return
	press(world, KEY_C)
	press(world, KEY_1)
	var member: Dictionary = scene.sightings.members[0]
	world.cell = member.home + Vector2i.LEFT
	world.destination = world.cell
	world.rebuild_world()
	scene.encounters.approach_individual(member.id)
	scene.encounters.battle_button.pressed.emit()
	BattleTest.settle(controller)
	controller.frame_battle()
	var release: Vector2i = controller.session.deployment_tiles()[0]
	for candidate: Vector2i in controller.session.deployment_tiles():
		if scene.pointer_cell(pointer(world, candidate)) == candidate:
			release = candidate
			break
	click(world, release)
	var battle: TacticalBattle = controller.session
	check(battle.phase == "active", "Mouse deployment uses a visible legal release on actual raised terrain")
	if battle.phase != "active":
		scene.free()
		quit(1)
		return
	BattleTest.approach_attack(controller)
	var cell := battle.ally_cell
	var remaining := battle.remaining
	controller.move_buttons[1].pressed.emit()
	var field_target := cell + Vector2i.DOWN
	for candidate: Vector2i in controller.legal_targets(1):
		if scene.pointer_cell(pointer(world, candidate)) == candidate:
			field_target = candidate
			break
	point_at(world, field_target)
	check(controller.aimed_slot == 1 and controller.cursor == field_target, "Mouse moves the field targeting cursor")
	check(battle.ally_cell == cell and battle.remaining == remaining and battle.activity.is_empty(), "Aiming does not move the Sol, consume movement, or execute a move")
	if capture_enabled():
		await capture("aim")
	press(world, KEY_ESCAPE)
	check(controller.aimed_slot == -1 and controller.session == battle and world.encounter_active, "Escape cancels aiming without withdrawing from battle")
	check(battle.activity.is_empty(), "Canceling aim contributes no activity")
	controller.move_buttons[1].pressed.emit()
	click(world, field_target)
	check(battle.activity.get("fire") == 1 and controller.aimed_slot == -1, "Mouse confirms the highlighted field target through actual input routing")
	controller.wait_turn()
	BattleTest.settle(controller)
	check(not feedback.cues.is_empty(), "Accepted field and enemy actions create visible combat feedback")
	var saw_damage := false
	var saw_field := false
	for cue in feedback.cues:
		saw_damage = saw_damage or (cue.kind == "damage" and cue.amount > 0)
		saw_field = saw_field or (cue.kind == "field" and cue.label.text.contains("Heat"))
	check(saw_damage and saw_field, "Feedback distinguishes actual damage from a terrain move")
	var state_before: Dictionary = world.persistent_state.snapshot()
	var hp := battle.ally_hp
	var activity := battle.activity.duplicate()
	feedback.update_cues(0.15)
	check(world.persistent_state.snapshot() == state_before and battle.ally_hp == hp and battle.activity == activity, "Cosmetic animation cannot change damage, activity or durable state")
	if capture_enabled():
		await capture("combat")
		print("PIPELINES AFTER FIRST COMBAT: ", pipeline_counts())
	var winner := battle.winner()
	var tiles: int = battle.imprint().tiles.size()
	controller.request_retreat()
	controller.retreat_dialog.confirmed.emit()
	BattleTest.settle(controller)
	check(controller.session == null and feedback.result_panel.visible and not world.paused, "Resolved battle shows a nonmodal summary while exploration resumes")
	for child in scene.get_children():
		if child.get_script() == preload("res://scripts/presentation/affinity_ground.gd"):
			check(child.tiles.is_empty() and not world.persistent_state.affinity_tiles().is_empty(), "Default exploration hides imprint tiles while preserving committed affinity state")
	check(feedback.result_text.text.contains(winner.capitalize()) and feedback.result_text.text.contains(str(tiles) + " affected tiles"), "Recap shows the committed affinity and affected tile count")
	var leaders := activity.values().count(activity[winner])
	check(feedback.result_text.text.contains("Tie:") == (leaders > 1) and feedback.result_help.text.contains("F5"), "Recap reports an actual tie only when present and keeps manual save help visible")
	check(feedback.result_text.text.contains("HP %d/%d" % [hp, world.persistent_state.active_sol_view().profile.max_hp]), "Recap displays actual retained companion health")
	if capture_enabled():
		await capture("result")
	var result_snapshot: Dictionary = world.persistent_state.snapshot()
	var box: VBoxContainer = feedback.result_panel.get_child(0)
	var close: Button = box.get_child(box.get_child_count() - 1)
	close.pressed.emit()
	check(not feedback.result_panel.visible and world.persistent_state.snapshot() == result_snapshot, "Dismissing the recap neither commits again nor mutates the expedition")
	feedback.tuning.feedback_limit = 2
	for index in range(5):
		feedback.receive({"kind": "heal", "cell": cell, "amount": index + 1, "affinity": "water", "caption": ""})
	check(feedback.cues.size() == 2 and feedback.cues[1].amount == 5, "Inspector cue limit retires oldest cues instead of growing without bound")
	feedback.update_cues(3.0)
	check(feedback.cues.is_empty(), "Expired feedback frees its visual nodes")
	feedback.tuning.feedback_enabled = false
	feedback.receive({"kind": "heal", "cell": cell, "amount": 3, "affinity": "water", "caption": ""})
	check(feedback.cues.is_empty(), "Disabling feedback in Godot leaves combat cues off")
	feedback.tuning.feedback_enabled = true
	settings.opponents[1].attack = 1000
	scene.encounters.approach_individual(member.id)
	scene.encounters.battle_button.pressed.emit()
	check(controller.session != null and not feedback.result_panel.visible, "Starting another battle clears the previous recap")
	controller.session.enemy.attack = 1000 # Explicit battle fixture; admitted wild profiles no longer reroll.
	BattleTest.settle(controller)
	controller.frame_battle()
	release = controller.session.deployment_tiles()[0]
	for candidate: Vector2i in controller.session.deployment_tiles():
		if scene.pointer_cell(pointer(world, candidate)) == candidate:
			release = candidate
			break
	click(world, release)
	BattleTest.approach_attack(controller)
	for turn in range(40):
		if controller.session == null:
			break
		controller.wait_button.pressed.emit()
		BattleTest.settle(controller)
	check(controller.session == null and feedback.result_title.text == "EXHAUSTION" and feedback.result_text.text.contains("Recover party") and world.persistent_state.starter_view().hp == 0, "Exhaustion recap explains refuge recovery using the actual saved outcome")
	world.new_expedition(17)
	check(not feedback.result_panel.visible and feedback.cues.is_empty(), "State replacement clears transient results and feedback")
	scene.free()
	print("BATTLE FEEDBACK: %d checks, %d failures." % [checks, failures])
	quit(0 if failures == 0 else 1)

func pointer(world: Node2D, cell: Vector2i) -> Vector2:
	return BattleTest.pointer(world, cell)

func click(world: Node2D, cell: Vector2i) -> void:
	BattleTest.settle(world.host.battles)
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = pointer(world, cell)
	world.handle_input(event)
	BattleTest.settle(world.host.battles)

func point_at(world: Node2D, cell: Vector2i) -> void:
	var event := InputEventMouseMotion.new()
	event.position = pointer(world, cell)
	world.handle_input(event)

func capture_enabled() -> bool:
	return OS.get_cmdline_user_args().has("--capture-feedback") and DisplayServer.get_name() != "headless"

func pipeline_counts() -> Dictionary:
	var result := {}
	for name in ClassDB.class_get_integer_constant_list("Performance"):
		if str(name).begins_with("PIPELINE_COMPILATIONS_"):
			result[str(name)] = Performance.get_monitor(ClassDB.class_get_integer_constant("Performance", name))
	return result

func pipeline_smoke(scene: Node3D, capture_path: String = "res://artifacts/pipeline-preparation/feedback-smoke.png") -> void:
	var world: Node2D = scene.world
	var feedback: Node3D = scene.battles.feedback_view
	var before: Dictionary = world.persistent_state.snapshot()
	for kind in ["damage", "vastra"]:
		feedback.receive({"kind": kind, "caption": "Vastra", "amount": 1, "affinity": "earth", "cell": world.cell})
	feedback.set_process(false) # Keep the two samples alive through screenshot I/O.
	feedback.update_cues(0.15)
	for frame in range(3): await process_frame
	await RenderingServer.frame_post_draw
	check(feedback.cues.size() == 2 and not feedback.prepared_rendering.visible, "Live effects render separately from the hidden startup examples")
	check(world.persistent_state.snapshot() == before and scene.battles.session == null, "Rendering-only samples do not start combat or alter the expedition")
	print("PIPELINES AFTER FEEDBACK SAMPLES: ", pipeline_counts())
	DirAccess.make_dir_recursive_absolute(capture_path.get_base_dir())
	root.get_texture().get_image().save_png(capture_path)
	scene.queue_free()
	await process_frame
	print("PIPELINE RENDER SMOKE: %d checks, %d failures." % [checks, failures])
	quit(0 if failures == 0 else 1)

func capture(name: String) -> void:
	DirAccess.make_dir_recursive_absolute("res://artifacts/feedback")
	for frame in range(3):
		await process_frame
	await RenderingServer.frame_post_draw
	get_root().get_texture().get_image().save_png("res://artifacts/feedback/%s.png" % name)
