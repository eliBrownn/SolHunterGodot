extends SceneTree
## Actual exploration scene with complete lighting/atmosphere, isolated from saves.
const DIRECTORY := "res://artifacts/vastra-lighting"

func _initialize() -> void:
	create_timer(90).timeout.connect(func() -> void: quit(1))
	run.call_deferred()

func run() -> void:
	DirAccess.make_dir_recursive_absolute(DIRECTORY)
	var scene: Node3D = load("res://scenes/world_3d.tscn").instantiate()
	scene.vastra_settings = load("res://resources/vastra_settings.tres").duplicate(true)
	scene.atmosphere_settings = scene.atmosphere_settings.duplicate(true)
	root.add_child(scene)
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1440, 900)
	var world: Node2D = scene.world
	world.smoke_mode = true
	world.new_expedition(17)
	scene.target_size = 11.0
	scene.view_elevation = 28.0
	scene.apply_camera()
	world.hud.visible = false
	# Pause only autonomous world time/movement. Presentation remains active.
	world.set_process(false)
	for frame in range(90):
		await process_frame
	for condition in [["daylight", 0.5, "clear"], ["sunset", 0.735, "clear"], ["moonlight", 0.0, "clear"], ["rain", 0.5, "rain"]]:
		scene.atmosphere_settings.cycle_enabled = false
		scene.atmosphere_settings.starting_phase = condition[1]
		scene.atmosphere_settings.weather = condition[2]
		scene.apply_atmosphere_settings()
		root.title = "Vastra in exploration: " + str(condition[0])
		for frame in range(60):
			await process_frame
		await RenderingServer.frame_post_draw
		var filename: String = DIRECTORY.path_join(str(condition[0]) + ".png")
		if root.get_texture().get_image().save_png(filename) != OK:
			push_error("Could not save lighting capture")
			quit(1)
			return
		print("Captured full world: ", condition[0], "; sun=", scene.sun.light_energy, "; moon=", scene.atmosphere_controller.moon.light_energy, "; rain=", scene.atmosphere_controller.rain_strength)
	scene.queue_free()
	await process_frame
	quit()
