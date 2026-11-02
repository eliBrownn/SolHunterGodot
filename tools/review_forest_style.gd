extends SceneTree
## Render the same art fixture with imported and proposed materials/lighting.

func _initialize() -> void:
	create_timer(90).timeout.connect(func(): push_error("Forest review timed out"); quit(1))
	run.call_deferred()

func run() -> void:
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280, 800)
	var scene: Node = load("res://scenes/forest_style_preview.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	scene.freeze_wind(true)
	if scene.surfaces.is_empty():
		push_error("Forest fixture did not adapt any imported leaf surfaces")
		quit(1)
		return
	var directory := "res://artifacts/forest_style"
	DirAccess.make_dir_recursive_absolute(directory)
	var metrics := []
	for condition in range(3):
		for baseline in [true, false]:
			scene.condition = condition
			scene.baseline = baseline
			scene.apply_style()
			for frame in range(30): await process_frame
			await RenderingServer.frame_post_draw
			var name: String = ["noon", "sunset", "night"][condition] + ("_baseline" if baseline else "_painterly")
			var error := root.get_texture().get_image().save_png(directory + "/" + name + ".png")
			if error != OK:
				push_error("Cannot save forest review: %s" % error_string(error))
				quit(1)
				return
			var samples: Array[float] = []
			for frame in range(60):
				var start := Time.get_ticks_usec()
				await process_frame
				samples.append((Time.get_ticks_usec() - start) / 1000.0)
			samples.sort()
			metrics.append({"view": name, "frame_median_ms": samples[30], "frame_p95_ms": samples[57],
				"draw_calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
				"primitives": Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)})
	var report := {"renderer": RenderingServer.get_current_rendering_method(), "gpu": RenderingServer.get_video_adapter_name(),
		"viewport": str(root.size), "adapted_surfaces": scene.surfaces.size(), "samples": metrics,
		"scope": "Static standalone forest fixture; not streaming or target-device acceptance"}
	FileAccess.open(directory + "/" + RenderingServer.get_current_rendering_method() + "_metrics.json", FileAccess.WRITE).store_string(JSON.stringify(report, "\t"))
	print("FOREST STYLE REVIEW: 6 views; %d adapted surfaces; %s" % [scene.surfaces.size(), report.renderer])
	scene.free()
	quit()
