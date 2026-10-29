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
	update()

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
	var elevation := settings.sun_elevation * altitude
	host.sun.rotation_degrees = Vector3(-elevation, settings.sun_azimuth, 0)
	host.sun.light_color = Color("ffb87e").lerp(settings.sun_color, smoothstep(0, 0.5, altitude))
	host.sun.light_energy = settings.sun_energy * smoothstep(-0.04, 0.2, altitude) * weather.y
	host.sun.shadow_enabled = host.sun.light_energy > 0.01
	moon.rotation_degrees = Vector3(elevation, settings.sun_azimuth + 180, 0)
	moon.light_color = settings.moon_color
	moon.light_energy = settings.moon_energy * (1.0 - smoothstep(-0.12, 0.08, altitude)) * weather.y
	moon.shadow_enabled = moon.light_energy > 0.01
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
	var material: ShaderMaterial = host.environment.sky.sky_material
	material.set_shader_parameter("sky_day", sky_color)
	material.set_shader_parameter("horizon_day", horizon)
	material.set_shader_parameter("sky_time", seconds)
	material.set_shader_parameter("daylight", light)
	material.set_shader_parameter("sun_direction", host.sun.global_basis.z)
	material.set_shader_parameter("sun_color", host.sun.light_color)
	material.set_shader_parameter("moon_color", settings.moon_color)
	material.set_shader_parameter("cloud_density", weather.x)
	material.set_shader_parameter("horizon_curve", settings.horizon_curve)
	material.set_shader_parameter("cloud_scale", settings.cloud_scale)
	material.set_shader_parameter("cloud_softness", settings.cloud_softness)
	material.set_shader_parameter("cloud_color", Color("344b65").lerp(Color("f9faf5"), light))
	material.set_shader_parameter("cloud_shadow", Color("182a42").lerp(Color("a6bdd3"), light))
	host.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	host.environment.ambient_light_color = settings.night_ambient_color.lerp(settings.day_ambient_color, light)
	host.environment.ambient_light_energy = lerpf(settings.night_ambient, settings.day_ambient, light)
	host.environment.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	host.environment.tonemap_exposure = settings.exposure
	host.environment.fog_light_color = horizon
	host.environment.fog_depth_begin = host.environment.fog_depth_end * host.active_view.fog_start_fraction * lerpf(1, settings.rain_fog_fraction, rain_strength)
	rain.position = host.player_visual.position + Vector3(0, 8, 0)
	rain.direction = Vector3(host.active_view.cloud_wind.x * 0.6, -1, host.active_view.cloud_wind.y * 0.6).normalized()
	rain_material.albedo_color = Color(Color("7498c7").lerp(Color("c4dded"), light), rain_strength * 0.35)
	var was_emitting := rain.emitting
	rain.visible = settings.rain_particles > 0 and rain_strength > 0.01
	rain.emitting = rain.visible
	if rain.visible and not was_emitting:
		rain.restart()
	rain.speed_scale = 0 if host.world.paused and not host.world.encounter_active else 1
	var minutes := floori(phase * 1440)
	var weather_text: String = previous.capitalize() + " → " + weather_name.capitalize() if previous != weather_name and blend < 1 else weather_name.capitalize()
	status.text = "%02d:%02d · %s" % [minutes / 60, minutes % 60, weather_text]
