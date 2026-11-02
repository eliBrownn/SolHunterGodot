extends SceneTree
## Focused transition checks and matched mood renders, with pixelation absent.
var failures := 0

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)

func _initialize() -> void:
	create_timer(90).timeout.connect(func(): push_error("Mood review timed out"); quit(1))
	run.call_deferred()

func run() -> void:
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280, 800)
	var scene: Node = load("res://scenes/forest_style_preview.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	scene.set_process(false)
	scene.freeze_wind(true)
	check(is_equal_approx(scene.mood_strength, 0.65 * 1.10), "Test mood strength is 10 percent above preferred")
	check(scene.set_mood(&"welcoming", 0.0), "Welcoming palette is available")
	var start: Dictionary = scene.mood_values.duplicate()
	check(scene.set_mood(&"mysterious", 2.0), "Situation can request a mood")
	check(scene.mood_values == start, "Transition starts without a color jump")
	scene._process(1.0)
	check(scene.mood_values != start and scene.mood_values != scene.mood_target, "Halfway blend lies between palettes")
	var midway: Dictionary = scene.mood_values.duplicate()
	check(scene.set_mood(&"wondrous", 2.0), "A transition can be interrupted")
	check(scene.mood_values == midway, "Interrupted transition preserves displayed color")
	scene._process(2.0)
	check(is_equal_approx(scene.mood_values.saturation, scene.mood_target.saturation), "Transition reaches its target")
	check(not scene.set_mood(&"missing"), "Unknown palette is rejected")
	scene.mood_enabled = false
	scene.apply_mood()
	check(is_equal_approx(scene.sun.light_energy, scene.base_lighting.sun_energy), "Disabling mood restores time-of-day lighting")
	check(scene.surfaces[0].styled.get_shader_parameter("mood_tint").is_equal_approx(Color.WHITE), "Disabling mood neutralizes shader tint")
	scene.mood_enabled = true
	# Even an authored bright palette cannot turn night into day via mood alone.
	scene.condition = 2
	scene.apply_style()
	scene.mood_values.light_scale = 1.5
	scene.mood_values.fill_scale = 1.5
	scene.mood_values.exposure_scale = 1.5
	scene.apply_mood()
	check(scene.sun.light_energy <= scene.base_lighting.sun_energy, "Mood cannot increase night direct light")
	check(scene.environment.ambient_light_energy <= scene.base_lighting.ambient_energy, "Mood cannot increase night fill")
	check(scene.environment.tonemap_exposure <= scene.base_lighting.exposure, "Mood cannot increase night exposure")
	var directory := "res://artifacts/forest_style/moods"
	DirAccess.make_dir_recursive_absolute(directory)
	for condition in [0, 2]:
		scene.condition = condition
		for key in [&"neutral", &"welcoming", &"wondrous", &"mysterious"]:
			scene.set_mood(key, 0.0)
			for frame in range(20): await process_frame
			await RenderingServer.frame_post_draw
			var name: String = ("noon_" if condition == 0 else "night_") + String(key)
			check(root.get_texture().get_image().save_png(directory + "/" + name + ".png") == OK, "Save mood view")
			if condition == 2:
				check(scene.sun.light_energy <= 0.32, "Mood retains low night illumination")
	print("FOREST MOOD REVIEW: 8 views; transitions, interruption and disable checked; %d failures" % failures)
	scene.free()
	quit(0 if failures == 0 else 1)
