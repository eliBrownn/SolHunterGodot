extends SceneTree
var failures := 0
var checks := 0
func check(ok: bool, caption: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(caption)

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	if "--hosted" in OS.get_cmdline_user_args():
		await run_hosted()
		return
	var trial = load("res://scenes/realtime_combat_trial.tscn").instantiate()
	root.add_child(trial)
	trial.set_process(false)
	check(trial.paused, "Trial waits for player to start")
	trial.paused = false
	check(trial.moves.size() == 3 and trial.hp == 44, "Fresh trial loads existing move data")
	check(not trial.cast(2) and trial.uses[2] == 3, "Full-health healing rejects without spending supply")
	check(not trial.legal(Vector2.ZERO), "Stone cover blocks creature placement")
	check(not trial.clear_line(Vector2(-2,0), Vector2(2,0)), "Cover blocks attacks")
	check(trial.clear_line(Vector2(-2,2), Vector2(2,2)), "Open sight line remains usable")
	var blocked: Vector2 = trial.move_actor(Vector2(-1,0), Vector2.RIGHT, 3, 0.05, Vector2(4,0))
	check(blocked.x < -0.9, "Creature radius prevents entering stone")
	var slow: Vector2 = trial.move_actor(Vector2(-3,2), Vector2.RIGHT, 3, 0.05, Vector2(4,0))
	check(is_equal_approx(slow.x+3, 0.075), "Slow terrain halves movement")
	trial.aim = Vector2(4,0)
	var uses: Array = trial.uses.duplicate()
	check(not trial.cast(1) and trial.uses == uses, "Rejected aim spends no uses")
	trial.ally = Vector2(-2,2)
	trial.enemy = Vector2(-0.8,2)
	trial.aim = trial.enemy
	check(trial.cast(0), "Legal attack commits")
	check(not trial.cast(0), "Windup blocks duplicate actions")
	trial.paused = true
	var before: float = trial.pending.left
	trial.tick(0.05)
	check(trial.pending.left == before and trial.elapsed == 0, "Pause freezes windup and clock")
	trial.paused = false
	for i in range(5): trial.tick(0.05)
	check(trial.enemy_hp == 38 and trial.hits == 1, "Committed hit resolves once using existing move power")
	for i in range(5): trial.tick(0.05)
	check(trial.enemy_hp == 38, "Resolved attack cannot replay")
	trial.reset_trial()
	trial.hp = 32
	check(trial.cast(2), "Healing commits")
	for i in range(10): trial.tick(0.05)
	check(trial.hp == 38 and trial.uses[2] == 2, "Heal applies once and consumes finite supply")
	trial.reset_trial()
	trial.warning = {"target": trial.ally, "left": 0.01}
	trial.tick(0.02)
	check(trial.hp == 44, "Cover blocks enemy hit")
	trial.ally = Vector2(2,2)
	trial.enemy = Vector2(3,2)
	trial.warning = {"target": Vector2(2,0), "left": 0.01}
	trial.tick(0.02)
	check(trial.hp == 44 and trial.dodges == 2, "Leaving locked warning avoids damage")
	trial.warning = {"target": trial.ally, "left": 0.01}
	trial.tick(0.02)
	check(trial.hp == 38, "Standing in warning takes one hit")
	trial.reset_trial()
	trial.command_mode = true
	trial.destination = Vector2(3.5,0)
	trial.enemy = Vector2(5,4)
	trial.enemy_delay = 999
	for i in range(200): trial.tick(0.05)
	check(trial.ally.distance_to(trial.destination) < 0.1, "Command movement routes around cover")
	trial.finish("Victory")
	before = trial.elapsed
	trial.tick(0.05, Vector2.LEFT)
	check(trial.elapsed == before and not trial.cast(0), "Terminal result freezes simulation and commands")
	trial.reset_trial()
	check(trial.outcome.is_empty() and trial.pending.is_empty() and trial.warning.is_empty() and trial.hp == 44 and trial.uses[2] == 3, "Restart clears transient state and restores uses")
	trial.update_view(0)
	if "--capture" in OS.get_cmdline_user_args():
		trial.command_mode = false
		trial.ally = Vector2(-2.5,2)
		trial.enemy = Vector2(1.8,2)
		trial.aim = trial.enemy
		trial.warning = {"target": trial.ally, "left": 0.8}
		trial.update_view(0)
		await process_frame
		await process_frame
		DirAccess.make_dir_recursive_absolute("res://artifacts/combat-trial")
		root.get_texture().get_image().save_png("res://artifacts/combat-trial/review.png")
	print("Real-time combat trial: %d checks, %d failures" % [checks, failures])
	trial.queue_free()
	await process_frame
	quit(1 if failures else 0)

func run_hosted() -> void:
	Engine.set_meta("workstation_session_path", "user://combat_trial_workstation.cfg")
	var lab = load("res://scenes/development_workstation.tscn").instantiate()
	root.add_child(lab)
	for index in range(lab.picker.item_count):
		if lab.picker.get_item_text(index) == "Combat / real-time experiment":
			lab.picker.select(index)
			lab.load_fixture()
	for frame in range(5): await process_frame
	var trial = lab.fixture
	check(trial.get_script().resource_path.ends_with("realtime_combat_trial.gd"), "Lab opens the requested trial")
	check(trial.controls.get_parent() == lab.station_box, "Trial controls dock in workstation")
	trial.set_process(false)
	trial.paused = false
	var key := InputEventKey.new()
	key.physical_keycode = KEY_SPACE
	key.pressed = true
	lab.viewport.push_input(key)
	check(trial.paused, "Viewport keyboard input pauses hosted trial")
	key = InputEventKey.new()
	key.physical_keycode = KEY_R
	key.pressed = true
	lab.viewport.push_input(key)
	check(trial.paused and trial.hp == 44, "Viewport keyboard input restarts hosted trial ready to begin")
	trial.note.grab_focus()
	await process_frame
	lab.viewport.push_input(key)
	check(trial.note.has_focus(), "Docked notes retain text focus")
	trial.note.release_focus()
	trial.command_mode = true
	var container: Control = lab.preview_stack.get_child(0)
	var local: Vector2 = trial.camera.unproject_position(Vector3(-3,0,2))
	var screen: Vector2 = container.global_position + local / Vector2(lab.viewport.size) * container.size
	var motion := InputEventMouseMotion.new()
	motion.position = screen
	root.push_input(motion, true)
	var click := InputEventMouseButton.new()
	click.position = screen
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	root.push_input(click, true)
	await process_frame
	check(trial.destination.distance_to(Vector2(-3,2)) < 0.1, "Workstation forwards click commands instead of selecting scenery")
	trial.ally = Vector2(-2.5,2)
	trial.enemy = Vector2(1.8,2)
	trial.warning = {"target": trial.ally, "left": 0.8}
	trial.update_view(0)
	for frame in range(3): await process_frame
	if "--capture" in OS.get_cmdline_user_args():
		DirAccess.make_dir_recursive_absolute("res://artifacts/combat-trial")
		root.get_texture().get_image().save_png("res://artifacts/combat-trial/hosted.png")
	# Switch away and back to exercise dock ownership and callback cleanup.
	lab.picker.select(lab.picker.item_count-2)
	lab.load_fixture()
	await process_frame
	lab.picker.select(lab.picker.item_count-1)
	lab.load_fixture()
	await process_frame
	check(is_instance_valid(lab.fixture.controls), "Switching stations recreates usable controls")
	print("Hosted combat trial: %d checks, %d failures" % [checks, failures])
	lab.queue_free()
	await process_frame
	await process_frame
	quit(1 if failures else 0)
