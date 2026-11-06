extends SceneTree

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(960, 640)
	DirAccess.make_dir_recursive_absolute("res://artifacts/sol_air_water")
	for item in [["crown_ear", 4], ["reedback", 5]]:
		var lab = load("res://scenes/sol_model_workshop.tscn").instantiate()
		lab.model_scene = load("res://scenes/sols/" + str(item[0]) + ".tscn")
		lab.exercise = item[1]
		root.add_child(lab)
		lab.set_process(false)
		for frame in range(180):
			lab._process(1.0 / 60.0)
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		if root.get_texture().get_image().save_png("res://artifacts/sol_air_water/" + str(item[0]) + "_workshop.png") != OK:
			quit(1)
			return
		lab.free()
		await process_frame
	print("SOL AIR/WATER REVIEW: two workshop captures saved.")
	quit(0)
