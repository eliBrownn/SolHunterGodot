extends Node
## Clock-derived cosmetic atmosphere; no terrain, combat, ecology or save mutation.

var host: Node3D
var settings: AtmosphereSettings
var moon := DirectionalLight3D.new()
var rain := CPUParticles3D.new()
var rain_material := StandardMaterial3D.new()
var status: Label
var phase := 0.0
var weather_name := "clear"
var rain_strength := 0.0
const LEAF_SCENE := "res://assets/local/vefects/Vefects/Wind VFX/VFX/Particles/VFX_Wind_Debris_Tree_Leaves_01_Colored_Closer.tscn"
var wind_leaves: Node3D
const MoodPalette = preload("res://scripts/presentation/world_mood_palette.gd")
var mood_values: Dictionary = MoodPalette.new().values()

func bind(scene: Node3D, tuning: AtmosphereSettings) -> void:
	host = scene
	host.add_child(moon)
	host.add_child(rain)
	rain.local_coords = true
	rain.lifetime = 1.5
	rain.preprocess = 1.5
	rain.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	rain.emission_box_extents = Vector3(13, 4, 13)
	rain.direction = Vector3(0.12, -1, 0.03)
	rain.spread = 3
	rain.gravity = Vector3(0, -12, 0)
	rain.initial_velocity_min = 9
	rain.initial_velocity_max = 13
	var drop := QuadMesh.new()
	drop.size = Vector2(0.025, 0.28)
	rain_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	rain_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	rain_material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	drop.material = rain_material
	rain.mesh = drop
	rain.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	status = host.world.label("", 14, Color("e1c791"))
	status.position = Vector2(350, 54)
	status.add_theme_color_override("font_shadow_color", Color.BLACK)
	status.add_theme_constant_override("shadow_offset_x", 1)
	status.add_theme_constant_override("shadow_offset_y", 1)
	host.world.hud.add_child(status)
	configure(tuning)

func configure(tuning: AtmosphereSettings) -> void:
	settings = tuning.duplicate(false) if tuning != null and tuning.valid() else AtmosphereSettings.new()
	if tuning == null or not tuning.valid():
		push_warning("Invalid atmosphere settings; using default daylight/weather policy.")
	rain.amount = maxi(1, settings.rain_particles)
	configure_wind_leaves()
	mood_values = MoodPalette.blend(MoodPalette.new().values(), settings.lighting_mood.values(), settings.mood_strength if settings.mood_enabled else 0.0)
	update()

func configure_wind_leaves() -> void:
	if wind_leaves != null:
		wind_leaves.free()
		wind_leaves = null
	if settings.wind_leaf_particles == 0 or not ResourceLoader.exists(LEAF_SCENE):
		return
	wind_leaves = load(LEAF_SCENE).instantiate()
	host.add_child(wind_leaves)
	for child in wind_leaves.get_children():
		if child is GPUParticles3D:
			child.amount = settings.wind_leaf_particles
			child.local_coords = true
			child.process_material = child.process_material.duplicate()
			child.process_material.set_shader_parameter("world_space", false)
			child.process_material.set_shader_parameter("shape_scale", Vector3(18, 4, 18))
			child.process_material.set_shader_parameter("shape_position", Vector3(0, 2, 0))
			child.visibility_aabb = AABB(Vector3(-24, -8, -24), Vector3(48, 24, 48))

func update_wind_leaves() -> void:
	if wind_leaves == null:
		return
	wind_leaves.position = host.player_visual.position
	var airflow: Vector2 = host.active_view.cloud_wind
	var strength := clampf(airflow.length() * 10.0, 0.0, 1.0)
	var direction := airflow.normalized()
	for child in wind_leaves.get_children():
		if child is GPUParticles3D:
			var process: ShaderMaterial = child.process_material
			process.set_shader_parameter("velocity_x", Vector4(0, direction.x * (1.0 + rain_strength), 0, 0))
			process.set_shader_parameter("velocity_y", Vector4(0, -0.15, 0, 0))
			process.set_shader_parameter("velocity_z", Vector4(0, direction.y * (1.0 + rain_strength), 0, 0))
			child.amount_ratio = strength
			child.visible = strength > 0.01
			child.emitting = child.visible
			child.speed_scale = rain.speed_scale

func weather_at(slot: int) -> String:
	if settings.weather != "auto":
		return settings.weather
	var roll: float = float(host.world.terrain.roll(Vector2i(posmod(slot, 2147483647), 0), 7193) % 10000) / 10000.0
	roll *= settings.clear_weight + settings.cloudy_weight + settings.rain_weight
	if roll < settings.clear_weight:
		return "clear"
	return "cloudy" if roll < settings.clear_weight + settings.cloudy_weight else "rain"

func weather_values(kind: String) -> Vector3:
	var base: float = host.active_view.cloud_density
	return {"clear": Vector3(base * 0.5, 1, 0), "cloudy": Vector3(minf(1, base * 1.3), 0.65, 0), "rain": Vector3(minf(1, base * 1.55), 0.4, 1)}[kind]

func weather_fog_fraction(kind: String) -> float:
	return {"clear": 1.0, "cloudy": settings.cloudy_fog_fraction, "rain": settings.rain_fog_fraction}[kind]

func update() -> void:
	if host == null or settings == null or host.environment.sky == null:
		return
	var seconds: float = host.world.persistent_state.activity_seconds()
	phase = fposmod(settings.starting_phase + (seconds / settings.day_seconds if settings.cycle_enabled else 0.0), 1.0)
	var altitude := sin((phase - 0.25) * TAU)
	var light := smoothstep(-0.2, 0.25, altitude)
	var twilight := (1.0 - smoothstep(0.0, 0.4, absf(altitude))) * light
	var slot := floori(seconds / settings.weather_seconds)
	weather_name = weather_at(slot)
	var previous := weather_at(maxi(0, slot - 1))
	var blend := smoothstep(0, settings.transition_seconds, fmod(seconds, settings.weather_seconds))
	var weather := weather_values(previous).lerp(weather_values(weather_name), blend)
	rain_strength = weather.z
	preload("res://scripts/scenery/meadow_art.gd").set_weather(host.active_view.cloud_wind, rain_strength)
	var elevation := settings.sun_elevation * altitude
	host.sun.rotation_degrees = Vector3(-elevation, settings.sun_azimuth, 0)
	host.sun.light_color = Color("ffb87e").lerp(settings.sun_color, smoothstep(0, 0.5, altitude))
	host.sun.light_energy = settings.sun_energy * smoothstep(-0.04, 0.2, altitude) * weather.y
	host.sun.shadow_enabled = host.sun.light_energy > 0.01
	moon.rotation_degrees = Vector3(elevation, settings.sun_azimuth + 180, 0)
	moon.light_color = settings.moon_color
	moon.light_energy = settings.moon_energy * (1.0 - smoothstep(-0.12, 0.08, altitude)) * weather.y
	moon.shadow_enabled = moon.light_energy > 0.01
	# Recomputed from clock/weather each update, so palette factors never compound.
	var direct_scale: float = lerpf(minf(mood_values.light_scale, 1.0), mood_values.light_scale, light)
	host.sun.light_color *= mood_values.sun_tint
	host.sun.light_energy *= direct_scale
	moon.light_color *= mood_values.ambient_tint
	moon.light_energy *= minf(mood_values.light_scale, 1.0)
	for source in [host.sun, moon]:
		source.shadow_opacity = settings.shadow_opacity
		source.shadow_blur = settings.shadow_blur
		source.shadow_bias = 0.03
		source.shadow_normal_bias = 0.6
		source.directional_shadow_blend_splits = true
		source.directional_shadow_max_distance = minf(host.active_view.shadow_distance, host.active_view.render_distance)
	var sky_color: Color = settings.night_sky.lerp(host.active_view.sky_color, light)
	var horizon: Color = settings.night_horizon.lerp(host.active_view.horizon_color, light).lerp(settings.sunset_horizon, twilight * 0.8)
	sky_color = sky_color.lerp(Color("617b91").darkened((1 - light) * 0.75), rain_strength * 0.65)
	horizon = horizon.lerp(Color("a2b7c4").darkened((1 - light) * 0.75), rain_strength * 0.6)
	sky_color *= mood_values.ambient_tint
	horizon *= mood_values.fog_tint
	var material: ShaderMaterial = host.environment.sky.sky_material
	material.set_shader_parameter("sky_day", sky_color)
	material.set_shader_parameter("horizon_day", horizon)
	material.set_shader_parameter("sky_time", seconds)
	material.set_shader_parameter("daylight", light)
	material.set_shader_parameter("sun_direction", host.sun.global_basis.z)
	material.set_shader_parameter("sun_color", host.sun.light_color)
	material.set_shader_parameter("moon_color", moon.light_color)
	material.set_shader_parameter("cloud_density", weather.x)
	material.set_shader_parameter("horizon_curve", settings.horizon_curve)
	material.set_shader_parameter("cloud_scale", settings.cloud_scale)
	material.set_shader_parameter("cloud_softness", settings.cloud_softness)
	material.set_shader_parameter("cloud_color", Color("344b65").lerp(Color("f9faf5"), light))
	material.set_shader_parameter("cloud_shadow", Color("182a42").lerp(Color("a6bdd3"), light))
	host.environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY if settings.sky_ambient_enabled else Environment.AMBIENT_SOURCE_COLOR
	host.environment.ambient_light_sky_contribution = settings.sky_ambient_contribution if settings.sky_ambient_enabled else 0.0
	host.environment.ambient_light_color = settings.night_ambient_color.lerp(settings.day_ambient_color, light) * mood_values.ambient_tint
	var fill_scale: float = lerpf(minf(mood_values.fill_scale, 1.0), mood_values.fill_scale, light)
	host.environment.ambient_light_energy = lerpf(settings.night_ambient, settings.day_ambient, light) * fill_scale
	host.environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC if settings.filmic_tonemapping else Environment.TONE_MAPPER_LINEAR
	var exposure_scale: float = lerpf(minf(mood_values.exposure_scale, 1.0), mood_values.exposure_scale, light)
	host.environment.tonemap_exposure = settings.exposure * exposure_scale
	host.environment.fog_light_color = horizon
	host.environment.fog_depth_begin = host.environment.fog_depth_end * host.active_view.fog_start_fraction * lerpf(weather_fog_fraction(previous), weather_fog_fraction(weather_name), blend) * mood_values.fog_start_scale
	rain.position = host.player_visual.position + Vector3(0, 8, 0)
	rain.direction = Vector3(host.active_view.cloud_wind.x * 0.6, -1, host.active_view.cloud_wind.y * 0.6).normalized()
	rain_material.albedo_color = Color(Color("7498c7").lerp(Color("c4dded"), light), rain_strength * 0.35)
	var was_emitting := rain.emitting
	rain.visible = settings.rain_particles > 0 and rain_strength > 0.01
	rain.emitting = rain.visible
	if rain.visible and not was_emitting:
		rain.restart()
	rain.speed_scale = 0 if host.world.paused and not host.world.encounter_active else 1
	update_wind_leaves()
	var minutes := floori(phase * 1440)
	var weather_text: String = previous.capitalize() + " → " + weather_name.capitalize() if previous != weather_name and blend < 1 else weather_name.capitalize()
	status.text = "%02d:%02d · %s" % [minutes / 60, minutes % 60, weather_text]
