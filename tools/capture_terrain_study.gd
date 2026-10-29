extends SceneTree
## Rendered review artifacts only; never calls expedition save/load.

const OUTPUT := "res://artifacts/terrain_study"
var report: Dictionary = {}

func _initialize() -> void:
	create_timer(180).timeout.connect(func() -> void:
		push_error("Terrain study capture timed out")
		quit(1))
	run.call_deferred()

func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Terrain study captures require a real renderer")
		quit(1)
		return
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280, 800)
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	report = {"engine": Engine.get_version_info().string, "renderer": RenderingServer.get_current_rendering_method(), "viewport": [1280, 800], "seed": 2601026, "presets": [], "scope": "Raw T0 landforms; no route grading, pond shaping, collision or gameplay integration"}
	await capture_baseline()
	var study: Node3D = load("res://scenes/terrain_preview.tscn").instantiate()
	root.add_child(study)
	var sheet := Image.create(1280 * 3, 800, false, Image.FORMAT_RGB8)
	for index in range(3):
		study.reset_view()
		study.select_preset(index)
		var name: String = ["very_gentle", "rolling", "upper_relief"][index]
		var walking := await capture(name + "_walking")
		sheet.blit_rect(walking, Rect2i(Vector2i.ZERO, walking.get_size()), Vector2i(index * 1280, 0))
		study.overview = true
		study.update_camera()
		await capture(name + "_overview")
		study.map_image(false).save_png(OUTPUT + "/" + name + "_height.png")
		study.map_image(true).save_png(OUTPUT + "/" + name + "_slope.png")
		report.presets.append(measure(study.field, study.terrain, study.presets[index].title))
	sheet.save_png(OUTPUT + "/comparison.png")
	var file := FileAccess.open(OUTPUT + "/report.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	study.free()
	print("TERRAIN STUDY: captured three walking/overview pairs, maps, baseline and report in " + OUTPUT)
	quit()

func measure(field: TerrainHeightfield, terrain: WorldTerrain, title: String) -> Dictionary:
	var heights: Array[float] = []
	var local_heights: Array[float] = []
	var slopes: Array[float] = []
	for z in range(-64, 64):
		for x in range(-64, 128):
			var height := field.vertex_height(Vector2i(x, z))
			heights.append(height)
			if x >= -16 and x < 48 and z >= -32 and z < 32:
				local_heights.append(height)
			slopes.append(field.slope_degrees(Vector2(x + 0.67, z + 0.33)))
			slopes.append(field.slope_degrees(Vector2(x + 0.33, z + 0.67)))
	heights.sort()
	local_heights.sort()
	slopes.sort()
	var route_grade := 0.0
	for x in range(78):
		var a := Vector2(x + 0.5, terrain.trail_y(x) + 0.5)
		var b := Vector2(x + 1.5, terrain.trail_y(x + 1) + 0.5)
		route_grade = maxf(route_grade, rad_to_deg(atan(absf(field.surface_height(b) - field.surface_height(a)) / a.distance_to(b))))
	return {"title": title, "heightfield": field.snapshot(), "minimum_height": heights.front(), "maximum_height": heights.back(), "study_relief": heights.back() - heights.front(), "local_64_cell_relief": local_heights.back() - local_heights.front(), "slope_p95_degrees": slopes[int(slopes.size() * 0.95)], "slope_max_degrees": slopes.back(), "raw_trail_centerline_max_grade_degrees": route_grade}

func capture_baseline() -> void:
	var scene: Node3D = load("res://scenes/world_3d.tscn").instantiate()
	root.add_child(scene)
	var world: Node2D = scene.world
	world.smoke_mode = true
	world.new_expedition(2601026)
	var shore := Vector2i.ZERO
	for y in range(-96, 97):
		for x in range(-96, 97):
			var cell := Vector2i(x, y)
			if world.terrain.natural_ground(cell) == WorldTerrain.Ground.SAND and world.terrain.fits(cell):
				shore = cell
				break
		if shore != Vector2i.ZERO:
			break
	var cases := {"baseline_refuge": Vector2i.ZERO, "baseline_waystone": world.terrain.landmark() + Vector2i.LEFT * 3, "baseline_shore": shore, "baseline_negative_border": Vector2i(-16, -16)}
	for name in cases:
		world.cell = cases[name]
		world.destination = world.cell
		world.rebuild_world()
		for frame in range(120):
			if world.pending.is_empty():
				break
			await process_frame
		scene.update_horizon(1.0)
		await capture(name)
	world.cell = Vector2i.ZERO
	world.destination = world.cell
	world.rebuild_world()
	scene.view_elevation = 10
	scene.target_size = scene.active_view.maximum_distance
	scene.apply_camera()
	for frame in range(120):
		if world.pending.is_empty():
			break
		await process_frame
	scene.update_horizon(1.0)
	await capture("baseline_low_camera_max_distance")
	scene.view_elevation = 80
	scene.target_size = scene.active_view.minimum_distance
	scene.apply_camera()
	await capture("baseline_high_camera_min_distance")
	scene.environment.sky = null
	scene.free()
	await process_frame

func capture(name: String) -> Image:
	for frame in range(5):
		await process_frame
	await RenderingServer.frame_post_draw
	var result := root.get_texture().get_image()
	result.convert(Image.FORMAT_RGB8)
	if result.save_png(OUTPUT + "/" + name + ".png") != OK:
		push_error("Could not write terrain capture: " + name)
	return result
