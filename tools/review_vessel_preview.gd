extends SceneTree
## Real renderer captures and batch-cost evidence; no expedition is loaded.

func _initialize() -> void:
	create_timer(45).timeout.connect(func(): push_error("Vessel review timed out"); quit(1))
	run.call_deferred()

func run() -> void:
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280, 800)
	var scene: Node3D = load("res://scenes/vessel_preview.tscn").instantiate()
	root.add_child(scene)
	var directory := "res://artifacts/vessels"
	DirAccess.make_dir_recursive_absolute(directory)
	var samples := []
	for mode in range(3):
		scene.set_view(mode)
		for frame in range(40): await process_frame
		await RenderingServer.frame_post_draw
		var error := root.get_texture().get_image().save_png(directory + "/view_%d.png" % mode)
		if error != OK:
			push_error("Vessel capture failed")
			quit(1)
			return
		var mesh: QuadMesh = scene.vessels.draw_pass_1
		var with_vessels := Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
		scene.vessels.visible = false
		for frame in range(4): await process_frame
		await RenderingServer.frame_post_draw
		var without_vessels := Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
		assert(mesh.get_surface_count() == 1)
		assert(scene.vessels.get_child_count() == 0)
		assert(scene.vessels is GPUParticles3D)
		assert(scene.vessels.draw_passes == 2)
		assert(scene.vessels.amount == scene.vessels.member_count * (scene.vessels.trail_samples + 1))
		samples.append({"members": scene.vessels.member_count,
			"particle_count": scene.vessels.amount, "triangles_per_pass": 2, "draw_passes": 2,
			"scene_draw_calls": with_vessels,
			"vessel_draw_calls": with_vessels - without_vessels,
			"vessel_nodes": 1, "surfaces": mesh.get_surface_count()})
	# Compare anger on the exact same frozen pose and camera.
	scene.set_view(0)
	scene.vessels.frozen = true
	scene.vessels.material.set_shader_parameter("animation_time", 1.25)
	scene.vessels.process_material.set_shader_parameter("animation_time", 1.25)
	var calm: Image
	for level in [0.0, 0.5, 1.0]:
		scene.vessels.anger = level
		scene.anger = level
		scene.update_caption()
		for frame in range(8): await process_frame
		await RenderingServer.frame_post_draw
		var capture := root.get_texture().get_image()
		assert(capture.save_png(directory + "/anger_%d.png" % roundi(level * 100)) == OK)
		if level == 0.0: calm = capture
		if level == 1.0:
			# Ignore the caption; require visible world pixels to change.
			var area := Rect2i(0, 320, 1280, 480)
			assert(calm.get_region(area).get_data() != capture.get_region(area).get_data())
	# Capture the full-strength lens without overlay controls obscuring its boundary.
	var control_panel: Control = scene.caption.get_parent().get_parent()
	control_panel.visible = false
	for frame in range(4): await process_frame
	await RenderingServer.frame_post_draw
	var world_image := root.get_texture().get_image()
	assert(world_image.save_png(directory + "/warp_world.png") == OK)
	# Regression: the transparent lens must not erase the luminous head.
	var bright_samples := 0
	for y in range(300, 600, 3):
		for x in range(300, 650, 3):
			var color := world_image.get_pixel(x, y)
			if color.r > 0.8 and color.g > 0.8 and color.b > 0.75: bright_samples += 1
	assert(bright_samples > 5)
	control_panel.visible = true
	# Confirm GPU movement still advances when given two different shared-clock values.
	var first_pose: Image
	for clock in [0.0, 0.7]:
		scene.vessels.process_material.set_shader_parameter("animation_time", clock)
		for frame in range(8): await process_frame
		await RenderingServer.frame_post_draw
		var capture := root.get_texture().get_image()
		assert(capture.save_png(directory + "/particle_motion_%d.png" % roundi(clock * 10)) == OK)
		if clock == 0.0: first_pose = capture
		else: assert(first_pose.get_data() != capture.get_data())
	# Exercise the UI controls and verify they drive the shader/meter and survive view switches.
	scene.aberration_slider.value = 4.0
	scene.anger_slider.value = 0.5
	assert(is_equal_approx(scene.vessels.material.get_shader_parameter("aberration_pixels"), 4.0))
	assert(is_equal_approx(scene.vessels.lens_material.get_shader_parameter("aberration_pixels"), 4.0))
	assert(is_equal_approx(scene.aberration_meter.value, 1.0))
	scene.set_view(1)
	assert(is_equal_approx(scene.vessels.aberration_pixels, 4.0))
	assert(is_equal_approx(scene.aberration_meter.value, 1.0))
	scene.anger_slider.value = 0.0
	assert(is_zero_approx(scene.aberration_meter.value))
	scene.set_view(0)
	scene.anger_slider.value = 0.75
	for frame in range(8): await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png(directory + "/aberration_controls.png") == OK)
	var report := {"renderer": RenderingServer.get_current_rendering_method(), "views": samples,
		"scope": "Standalone visual/density study. No ecology, production culling or target-device performance acceptance."}
	FileAccess.open(directory + "/review.json", FileAccess.WRITE).store_string(JSON.stringify(report, "\t"))
	print("VESSEL REVIEW: ", JSON.stringify(report))
	scene.free()
	quit()
