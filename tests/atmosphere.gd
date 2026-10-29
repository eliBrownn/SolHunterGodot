extends SceneTree

var checks := 0
var failures := 0

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)

func _initialize() -> void:
	create_timer(120).timeout.connect(func() -> void: quit(1))
	run.call_deferred()

func run() -> void:
	var scene: Node3D = load("res://scenes/world_3d.tscn").instantiate()
	root.add_child(scene)
	var world: Node2D = scene.world
	world.smoke_mode = true
	world.new_expedition(17)
	var controller: Node = scene.atmosphere_controller
	var settings: AtmosphereSettings = scene.atmosphere_settings.duplicate(false)
	scene.atmosphere_settings = settings
	settings.cycle_enabled = false
	settings.weather = "clear"
	settings.starting_phase = 0.5
	scene.apply_atmosphere_settings()
	check(scene.sun.light_energy > 1 and controller.moon.light_energy == 0, "Noon enables daylight and disables below-horizon moonlight")
	check(is_equal_approx(scene.environment.ambient_light_energy, settings.day_ambient), "Day ambient tuning is connected to the actual environment")
	var shader: ShaderMaterial = scene.environment.sky.sky_material
	check(shader.get_shader_parameter("sun_direction").is_equal_approx(scene.sun.global_basis.z), "Visible sun matches the light casting world shadows")
	var day_ambient: float = scene.environment.ambient_light_energy
	settings.starting_phase = 0
	scene.apply_atmosphere_settings()
	check(scene.sun.light_energy == 0 and controller.moon.light_energy > 0, "Midnight uses moonlight rather than illuminating from below terrain")
	check(scene.environment.ambient_light_energy < day_ambient and shader.get_shader_parameter("daylight") == 0, "Night uses distinct sky/stars and lower ambient illumination")
	check(scene.environment.fog_light_color == settings.night_horizon, "Night fog matches the night horizon")
	settings.starting_phase = 0.25
	scene.apply_atmosphere_settings()
	check(scene.environment.fog_light_color.r > scene.environment.fog_light_color.b, "Sunrise introduces a warm horizon")
	settings.starting_phase = 0.5
	settings.weather = "cloudy"
	scene.apply_atmosphere_settings()
	var cloudy_energy: float = scene.sun.light_energy
	check(cloudy_energy < settings.sun_energy and not controller.rain.visible, "Cloudy weather softens sunlight without emitting rain")
	settings.weather = "rain"
	scene.apply_atmosphere_settings()
	check(controller.rain_strength == 1 and controller.rain.visible and controller.rain.emitting, "Rain connects sky coverage, wet-weather lighting and visible particles")
	check(scene.sun.light_energy < cloudy_energy and controller.rain.amount == settings.rain_particles, "Rain reduces direct sun and uses the bounded Inspector particle budget")
	settings.rain_particles = 0
	scene.apply_atmosphere_settings()
	check(not controller.rain.visible and not controller.rain.emitting and controller.rain_strength == 1, "Zero particles disables streaks without turning off rain atmosphere")
	var before: Dictionary = world.persistent_state.snapshot()
	controller.update()
	controller.update()
	check(world.persistent_state.snapshot() == before, "Lighting/weather rendering never mutates terrain, ecology, individuals or saves")
	settings.cycle_enabled = true
	settings.starting_phase = 0.38
	settings.day_seconds = 120
	settings.weather = "auto"
	settings.weather_seconds = 60
	settings.transition_seconds = 15
	scene.apply_atmosphere_settings()
	world.persistent_state.advance_time(0.3)
	controller.update()
	check(is_equal_approx(controller.phase, 0.3825), "Sub-tick saved active time advances the cycle smoothly")
	var phase: float = controller.phase
	world.paused = true
	world.smoke_mode = false
	world._process(1)
	controller.update()
	check(controller.phase == phase and controller.rain.speed_scale == 0, "Pause freezes the saved-clock cycle and rain animation")
	world.paused = false
	world.smoke_mode = true
	for step in range(40):
		world.persistent_state.advance_time(1.5)
	for step in range(10):
		world.persistent_state.advance_time(0.75)
	controller.update()
	phase = controller.phase
	var weather: String = controller.weather_name
	var strength: float = controller.rain_strength
	var path := "user://atmosphere-%d.json" % Time.get_ticks_usec()
	world.save_game(path)
	world.new_expedition(17)
	world.load_game(path)
	controller.update()
	check(is_equal_approx(controller.phase, phase) and controller.weather_name == weather and is_equal_approx(controller.rain_strength, strength), "Reload preserves cycle phase and the exact deterministic weather transition")
	for slot in range(16):
		var first: String = controller.weather_at(slot)
		check(first in ["clear", "cloudy", "rain"] and controller.weather_at(slot) == first, "Automatic weather is stable for a seed/time interval")
	var material: StandardMaterial3D = preload("res://scripts/presentation/solid_chunk.gd").mesh_for("grass_3").surface_get_material(0)
	check(material.shading_mode == BaseMaterial3D.SHADING_MODE_PER_PIXEL, "Retained terrain textures now receive daylight, moonlight and scenery shadows")
	if OS.get_cmdline_user_args().has("--capture-atmosphere") and DisplayServer.get_name() != "headless":
		settings.cycle_enabled = false
		settings.rain_particles = 500
		var day_ground := 0.0
		for sample in [["day", 0.5, "clear"], ["sunset", 0.74, "clear"], ["night", 0.0, "clear"], ["rain", 0.5, "rain"]]:
			settings.starting_phase = sample[1]
			settings.weather = sample[2]
			scene.apply_atmosphere_settings()
			await capture(scene, sample[0], false)
			if sample[0] == "day":
				day_ground = ground_light(root.get_texture().get_image())
			if sample[0] == "night":
				var night_ground := ground_light(root.get_texture().get_image())
				check(day_ground > night_ground * 2.5, "Rendered retained terrain is substantially brighter in sunlight than at night")
				check(night_ground > 0.003, "Rendered moonlit ground remains visible at night")
			if sample[0] in ["day", "night"]:
				await capture(scene, sample[0] + "_sky", true)
	settings.day_seconds = NAN
	scene.apply_atmosphere_settings()
	check(controller.settings.valid() and controller.settings.day_seconds == 1200, "Invalid atmosphere policy falls back before reaching lights or shaders")
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(path + suffix):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path + suffix))
	if DisplayServer.get_name() != "headless":
		await process_frame
		await RenderingServer.frame_post_draw
	scene.environment.sky = null
	scene.free()
	if DisplayServer.get_name() != "headless":
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
	print("ATMOSPHERE: %d checks, %d failures." % [checks, failures])
	quit(0 if failures == 0 else 1)

func capture(scene: Node3D, name: String, sky_only: bool) -> void:
	scene.view_azimuth = 25
	scene.view_elevation = 16
	scene.target_size = 19
	scene.apply_camera()
	for frame in range(300):
		if scene.world.pending.is_empty():
			break
		await process_frame
	scene.update_horizon(1)
	if sky_only:
		scene.camera.position = Vector3(0, 3, 0)
		var direction: Vector3 = scene.sun.global_basis.z if scene.atmosphere_controller.phase > 0.25 and scene.atmosphere_controller.phase < 0.75 else scene.atmosphere_controller.moon.global_basis.z
		scene.camera.look_at(scene.camera.position + direction)
	for frame in range(8):
		await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://artifacts/atmosphere")
	root.get_texture().get_image().save_png("res://artifacts/atmosphere/%s.png" % name)

func ground_light(image: Image) -> float:
	var total := 0.0
	var count := 0
	for y in range(430, 550, 4):
		for x in range(80, 300, 4):
			total += image.get_pixel(x, y).get_luminance()
			count += 1
	return total / count
