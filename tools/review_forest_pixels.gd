extends SceneTree
## Matched camera, wind and lighting: only the selected sampling effect changes.

func _initialize() -> void:
	create_timer(90).timeout.connect(func(): push_error("Forest pixel review timed out"); quit(1))
	run.call_deferred()

func run() -> void:
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280, 800)
	var study: Control = load("res://scenes/forest_pixel_preview.tscn").instantiate()
	root.add_child(study)
	current_scene = study
	study.forest.freeze_wind(true)
	# Exercise off/on without losing the stored strength, then render each option.
	study.set_effect(2)
	study.pixel_filter_enabled = false
	study.apply_effect()
	if study.viewport.size != Vector2i(1280, 800) or study.effect_mode != 2:
		push_error("Pixel filter off must restore native resolution and retain strength")
		quit(1)
		return
	study.pixel_filter_enabled = true
	study.apply_effect()
	if study.viewport.size != Vector2i(853, 533):
		push_error("Pixel filter on must restore the stored strength")
		quit(1)
		return
	var renderer := RenderingServer.get_current_rendering_method()
	var directory := "res://artifacts/forest_style/pixels/" + renderer
	DirAccess.make_dir_recursive_absolute(directory)
	for condition in [0, 1]:
		study.forest.condition = condition
		for mode in range(study.MODE_NAMES.size()):
			study.set_effect(mode)
			for frame in range(20): await process_frame
			await RenderingServer.frame_post_draw
			var name: String = ["noon", "sunset"][condition] + "_" + ["smooth", "pixel_1_25x", "pixel_1_5x", "pixel_1_75x", "pixel_2x", "pixel_3x"][mode]
			var error := root.get_texture().get_image().save_png(directory + "/" + name + ".png")
			if error != OK:
				push_error("Cannot save pixel review: %s" % error_string(error))
				quit(1)
				return
			print("PIXEL VIEW: %s; 3D viewport %s; MSAA %d" % [name, study.viewport.size, study.viewport.msaa_3d])
	print("FOREST PIXEL REVIEW: 12 views; enable/disable retains strength; %s" % renderer)
	study.free()
	quit()
