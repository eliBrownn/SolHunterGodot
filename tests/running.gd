extends SceneTree
var failures := 0
var checks := 0
func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)
func _initialize() -> void:
	run.call_deferred()
func run() -> void:
	var scene: Node3D = load("res://scenes/world_3d.tscn").instantiate()
	root.add_child(scene)
	var world: Node2D = scene.world
	world.smoke_mode = true
	world.new_expedition(17)
	var duration: float = world.expedition_parameters().move_seconds
	var multiplier: float = world.expedition_parameters().run_multiplier
	check(InputMap.action_get_events("run")[0].physical_keycode == KEY_SHIFT, "Shift is bound to running")
	world.advance_movement(duration * 0.5, Vector2.RIGHT)
	scene.player_visual.sync_art()
	check(is_equal_approx(world.progress, 0.5) and not world.explorer.running and scene.player_visual.animator.current_animation == "Walking_A", "Ordinary movement uses walking speed and animation")
	world.new_expedition(17)
	Input.action_press("run")
	world.advance_movement(duration * 0.5 / multiplier, Vector2.RIGHT)
	scene.player_visual.sync_art()
	check(is_equal_approx(world.progress, 0.5) and world.explorer.running and scene.player_visual.animator.current_animation == "Running_A", "Holding Shift accelerates actual movement and selects running")
	Input.action_release("run")
	world.advance_movement(duration * 0.25, Vector2.RIGHT)
	check(is_equal_approx(world.progress, 0.75) and not world.explorer.running, "Releasing Shift restores walking during the current step")
	world.new_expedition(17)
	Input.action_press("run")
	world.advance_movement(duration * sqrt(2.0) * 0.5 / multiplier, Vector2.ONE.normalized())
	check(is_equal_approx(world.progress, 0.5), "Running preserves diagonal distance normalization")
	world.paused = true
	var before: Vector2 = world.explorer.position
	world.advance_movement(1, Vector2.RIGHT)
	check(world.explorer.position == before and not world.explorer.running, "Pause blocks running")
	world.paused = false
	world.encounter_active = true
	world.advance_movement(1, Vector2.RIGHT)
	check(world.explorer.position == before and not world.explorer.running, "Combat blocks exploration running")
	world.encounter_active = false
	world.new_expedition(17)
	world.advance_movement(0.1, Vector2.ZERO)
	check(not world.explorer.running and not world.moving, "Shift alone does not start movement")
	Input.action_release("run")
	var tuning := ExpeditionSettings.new()
	tuning.run_multiplier = NAN
	check(not tuning.valid(), "Non-finite running speed is rejected")
	tuning.run_multiplier = 0.5
	check(not tuning.valid(), "Running multiplier cannot be slower than walking")
	scene.environment.sky = null
	scene.free()
	print("RUNNING: %d checks, %d failures." % [checks, failures])
	quit(0 if failures == 0 else 1)
