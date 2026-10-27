extends SceneTree
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
	check(events.size() == 2 and events[0].kind == "heal" and events[0].amount == 4 and events[1].kind == "damage" and events[1].amount == 4, "Separate cues report capped healing and enemy damage even when net HP change is zero")
	var scene: Node3D = (load("res://scenes/world_3d.tscn") as PackedScene).instantiate()
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
	press(world, KEY_C)
	press(world, KEY_1)
	var member: Dictionary = scene.sightings.members[0]
	world.cell = member.home + Vector2i.LEFT
	world.destination = world.cell
	world.rebuild_world()
	press(world, KEY_R)
	scene.encounters.battle_button.pressed.emit()
	press(world, KEY_ENTER)
	var battle: TacticalBattle = controller.session
	var cell := battle.ally_cell
	var remaining := battle.remaining
	press(world, KEY_2)
	press(world, KEY_DOWN)
	check(controller.aimed_slot == 1 and controller.cursor == cell + Vector2i.DOWN, "Arrows move the field targeting cursor")
	check(battle.ally_cell == cell and battle.remaining == remaining and battle.activity.is_empty(), "Aiming does not move the Sol, consume movement, or execute a move")
	if capture_enabled():
		await capture("aim")
	press(world, KEY_ESCAPE)
	check(controller.aimed_slot == -1 and controller.session == battle and world.encounter_active, "Escape cancels aiming without withdrawing from battle")
	check(battle.activity.is_empty(), "Canceling aim contributes no activity")
	press(world, KEY_2)
	press(world, KEY_DOWN)
	press(world, KEY_ENTER)
	check(battle.activity.get("fire") == 1 and controller.aimed_slot == -1, "Enter confirms the highlighted field target through actual input routing")
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
	var winner := battle.winner()
	var tiles: int = battle.imprint().tiles.size()
	press(world, KEY_ESCAPE)
	check(controller.session == null and feedback.result_panel.visible and not world.paused, "Resolved battle shows a nonmodal summary while exploration resumes")
	check(feedback.result_text.text.contains(winner.capitalize()) and feedback.result_text.text.contains(str(tiles) + " affected tiles"), "Recap shows the committed affinity and affected tile count")
	check(feedback.result_text.text.contains("Tie:") and feedback.result_help.text.contains("F5"), "Recap explains the tied leader and keeps manual save help visible")
	check(feedback.result_text.text.contains("HP %d/44" % hp), "Recap displays actual retained companion health")
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
	press(world, KEY_R)
	scene.encounters.battle_button.pressed.emit()
	check(controller.session != null and not feedback.result_panel.visible, "Starting another battle clears the previous recap")
	press(world, KEY_ENTER)
	if controller.session != null:
		press(world, KEY_ENTER)
	check(controller.session == null and feedback.result_title.text == "EXHAUSTION" and feedback.result_text.text.contains("Press H") and world.persistent_state.starter_view().hp == 0, "Exhaustion recap explains refuge recovery using the actual saved outcome")
	world.new_expedition(17)
	check(not feedback.result_panel.visible and feedback.cues.is_empty(), "State replacement clears transient results and feedback")
	scene.free()
	print("BATTLE FEEDBACK: %d checks, %d failures." % [checks, failures])
	quit(0 if failures == 0 else 1)

func capture_enabled() -> bool:
	return OS.get_cmdline_user_args().has("--capture-feedback") and DisplayServer.get_name() != "headless"

func capture(name: String) -> void:
	DirAccess.make_dir_recursive_absolute("res://artifacts/feedback")
	for frame in range(3):
		await process_frame
	await RenderingServer.frame_post_draw
	get_root().get_texture().get_image().save_png("res://artifacts/feedback/%s.png" % name)
