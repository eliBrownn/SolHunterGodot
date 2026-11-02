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
	var preview_snapshot: Dictionary = world.persistent_state.snapshot()
	controller.preview_phase = 0.5
	controller.update()
	controller.day_night_toggle.pressed.emit()
	check(is_zero_approx(controller.phase) and controller.moon.light_energy > 0, "HUD toggle previews night")
	controller.day_night_toggle.pressed.emit()
	check(is_equal_approx(controller.phase, 0.5) and scene.sun.light_energy > 0, "HUD toggle previews day")
	controller.resume_cycle.pressed.emit()
	check(controller.preview_phase < 0 and not controller.resume_cycle.visible, "Resume returns to the saved-clock cycle")
	check(world.persistent_state.snapshot() == preview_snapshot, "Day/night previews never alter expedition time or saves")
	var settings: AtmosphereSettings = scene.atmosphere_settings.duplicate(false)
	scene.atmosphere_settings = settings
	check(settings.mood_enabled and is_equal_approx(settings.mood_strength, 0.65 * 1.10), "Main game enables the approved pre-test mood strength")
	check(scene.environment.tonemap_mode == Environment.TONE_MAPPER_FILMIC and scene.environment.ambient_light_source == Environment.AMBIENT_SOURCE_SKY, "Main game uses painterly highlights and sky ambient")
	settings.mood_enabled = false
	settings.cycle_enabled = false
	settings.weather = "clear"
	settings.starting_phase = 0.5
	scene.apply_atmosphere_settings()
	check(scene.sun.light_energy > 1 and controller.moon.light_energy == 0, "Noon enables daylight and disables below-horizon moonlight")
	check(is_equal_approx(scene.environment.ambient_light_energy, settings.day_ambient), "Day ambient tuning is connected to the actual environment")
	var shader: ShaderMaterial = scene.environment.sky.sky_material
	check(shader.get_shader_parameter("sun_direction").is_equal_approx(scene.sun.global_basis.z), "Visible sun matches the light casting world shadows")
	var live_curve: float = controller.settings.horizon_curve
	controller.settings.horizon_curve = 0.7
	controller.settings.shadow_opacity = 0.55
	controller.update()
	check(is_equal_approx(shader.get_shader_parameter("horizon_curve"), 0.7) and is_equal_approx(scene.sun.shadow_opacity, 0.55), "Direct sky/shadow edits invalidate stable material and light settings")
	controller.settings.horizon_curve = live_curve
	controller.update()
	check(is_equal_approx(shader.get_shader_parameter("horizon_curve"), live_curve), "Returning to earlier tuning restores the actual sky material")
	var origin_material := ShaderMaterial.new()
	origin_material.shader = preload("res://shaders/shore_ground.gdshader")
	scene.sync_material_origin(origin_material, Vector2(12, -3))
	origin_material.set_shader_parameter("world_origin", Vector2.ZERO)
	scene.sync_material_origin(origin_material, Vector2(12, -3))
	check(origin_material.get_shader_parameter("world_origin") == Vector2(12,-3), "Shared origin binding recovers another consumer's write instead of trusting stale private state")
	world.hover_outline.show()
	world.hover_outline.position = Vector2(32,64)
	scene.sync_ground()
	var selection_before: Transform3D = scene.selection.transform
	scene.sync_ground()
	check(scene.selection.transform == selection_before, "Unchanged hovered terrain retains its highlight geometry")
	world.hover_outline.position += Vector2(32,0)
	scene.sync_ground()
	check(scene.selection.position.x == 2.5 and scene.selection.position.z == 2.5, "A changed hover target immediately realigns the highlight")
	world.hover_outline.hide()
	var clear_fog: float = scene.environment.fog_depth_begin
	check(is_equal_approx(clear_fog, scene.environment.fog_depth_end * scene.active_view.fog_start_fraction), "Clear weather uses the approved view fog fraction")
	var original_mood: Resource = settings.lighting_mood
	settings.mood_enabled = true
	settings.lighting_mood = load("res://resources/moods/mysterious.tres")
	scene.apply_atmosphere_settings()
	check(scene.environment.fog_depth_begin < clear_fog, "Mysterious mood brings fog closer on the same clear day")
	settings.mood_strength = 0.0
	scene.apply_atmosphere_settings()
	check(is_equal_approx(scene.environment.fog_depth_begin, clear_fog), "Zero mood strength restores clear visibility")
	settings.mood_enabled = false
	settings.lighting_mood = original_mood
	settings.mood_strength = 0.715
	var day_ambient: float = scene.environment.ambient_light_energy
	settings.starting_phase = 0
	scene.apply_atmosphere_settings()
	check(scene.sun.light_energy == 0 and controller.moon.light_energy > 0, "Midnight uses moonlight rather than illuminating from below terrain")
	check(scene.environment.ambient_light_energy < day_ambient and shader.get_shader_parameter("daylight") == 0, "Night uses distinct sky/stars and lower ambient illumination")
	check(scene.environment.fog_light_color == settings.night_horizon, "Night fog matches the night horizon")
	settings.starting_phase = 0.25
	scene.apply_atmosphere_settings()
	check(scene.environment.fog_light_color.r > scene.environment.fog_light_color.b, "Sunrise introduces a warm horizon")
	settings.filmic_tonemapping = false
	settings.sky_ambient_enabled = false
	scene.apply_atmosphere_settings()
	check(scene.environment.tonemap_mode == Environment.TONE_MAPPER_LINEAR and scene.environment.ambient_light_source == Environment.AMBIENT_SOURCE_COLOR, "Inspector toggles restore linear and color-only lighting")
	settings.filmic_tonemapping = true
	settings.sky_ambient_enabled = true
	settings.starting_phase = 0.5
	settings.weather = "cloudy"
	scene.apply_atmosphere_settings()
	var cloudy_fog: float = scene.environment.fog_depth_begin
	check(cloudy_fog < clear_fog, "Cloud cover brings fog closer than clear weather")
	var cloudy_energy: float = scene.sun.light_energy
	check(cloudy_energy < settings.sun_energy and not controller.rain.visible, "Cloudy weather softens sunlight without emitting rain")
	settings.weather = "rain"
	scene.apply_atmosphere_settings()
	check(scene.environment.fog_depth_begin < cloudy_fog, "Rain brings fog closer than cloud cover")
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
	var material: Material = preload("res://scripts/presentation/solid_chunk.gd").mesh_for("grass_3").surface_get_material(0)
	var lit: bool = material is StandardMaterial3D and material.shading_mode == BaseMaterial3D.SHADING_MODE_PER_PIXEL
	if material is ShaderMaterial:
		lit = material.shader != null and material.shader.get_mode() == Shader.MODE_SPATIAL and not material.shader.code.contains("unshaded")
	check(lit, "Retained terrain uses a lit material, including the shoreline shader")
	if OS.get_cmdline_user_args().has("--capture-atmosphere") and DisplayServer.get_name() != "headless":
		settings.mood_enabled = true
		settings.cycle_enabled = false
		settings.rain_particles = 500
		var day_ground := 0.0
		for sample in [["day", 0.5, "clear"], ["sunset", 0.74, "clear"], ["night", 0.0, "clear"], ["rain", 0.5, "rain"]]:
			settings.starting_phase = sample[1]
			settings.weather = sample[2]
			scene.apply_atmosphere_settings()
			await capture(scene, sample[0], false)
			if sample[0] == "day":
				day_ground = ground_light(root.get_texture().get_image(), scene)
			if sample[0] == "night":
				var night_ground := ground_light(root.get_texture().get_image(), scene)
				print("ATMOSPHERE GROUND: day %.5f night %.5f" % [day_ground, night_ground])
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

func ground_light(image: Image, scene: Node3D) -> float:
	# Compare the same protected camp ground under each lighting condition.
	# Project world samples; fixed screen pixels can hit trees/sky after resizing.
	var values: Array[float] = []
	for y in range(-3, 4):
		for x in range(-3, 4):
			var at := Vector2(x + 0.5, y + 0.5)
			if at.length() < 2.0 or at.length() > 4.0:
				continue
			var pixel: Vector2 = scene.camera.unproject_position(Vector3(at.x, scene.world.terrain.surface_height(at) + 0.01, at.y))
			if Rect2(Vector2.ZERO, Vector2(image.get_size())).has_point(pixel):
				values.append(image.get_pixelv(Vector2i(pixel)).get_luminance())
	values.sort()
	check(not values.is_empty(), "Lighting comparison contains projected camp-ground samples")
	return values[values.size() / 2] if not values.is_empty() else 0.0
