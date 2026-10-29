extends SceneTree
## Render the artist workshop's actual models and exercises for review.

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(960, 640)
	DirAccess.make_dir_recursive_absolute("res://artifacts/sol_procedural_ground")
	for working_name in ["crown_ear", "reedback", "bellroot"]:
		for exercise in [1, 3]:
			var lab = load("res://scenes/sol_model_workshop.tscn").instantiate()
			lab.model_scene = load("res://scenes/sols/" + working_name + ".tscn")
			lab.exercise = exercise
			root.add_child(lab)
			lab.set_process(false)
			for frame in range(180):
				lab._process(1.0 / 60.0)
			await process_frame
			await process_frame
			await RenderingServer.frame_post_draw
			var path := "res://artifacts/sol_procedural_ground/%s_%s.png" % [working_name, "walk" if exercise == 1 else "slope"]
			if root.get_texture().get_image().save_png(path) != OK:
				push_error("Could not capture " + path)
				quit(1)
				return
			lab.free()
	print("SOL GROUND REVIEW: six workshop captures saved.")
	quit(0)
