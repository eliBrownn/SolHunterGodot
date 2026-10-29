class_name AtmosphereSettings
extends Resource
## Presentation only. Cycle/weather derive from the saved active exploration clock.

@export_group("Day and Night")
## Disable to preview Starting Phase without advancing the sky. Does not change saved time.
@export var cycle_enabled := true
## Active exploration seconds per complete day. Pause/battle do not advance this clock.
@export_range(120.0, 7200.0, 60.0) var day_seconds := 1200.0
## 0 midnight, 0.25 sunrise, 0.5 noon, 0.75 sunset. Offset applied to saved active time.
@export_range(0.0, 1.0, 0.01) var starting_phase := 0.38
## Highest sun elevation, in degrees; moon travels opposite the sun.
@export_range(25.0, 80.0, 1.0) var sun_elevation := 55.0
## World azimuth of the sun's arc. Independent of camera rotation.
@export_range(-180.0, 180.0, 1.0) var sun_azimuth := -30.0
@export_range(0.0, 3.0, 0.05) var sun_energy := 1.25
@export var sun_color := Color("fff1d9")
@export_range(0.0, 0.8, 0.02) var moon_energy := 0.32
@export var moon_color := Color("a7c9f0")
@export_range(0.0, 2.0, 0.05) var day_ambient := 0.6
@export_range(0.0, 0.6, 0.02) var night_ambient := 0.28
@export var day_ambient_color := Color("c6dbed")
@export var night_ambient_color := Color("7894b6")
## Linear scene exposure. Applies to the world, not HUD text.
@export_range(0.5, 1.5, 0.05) var exposure := 1.05
## Shadow opacity and PCF blur; low normal bias keeps small props grounded.
@export_range(0.0, 1.0, 0.05) var shadow_opacity := 0.8
@export_range(0.5, 3.0, 0.1) var shadow_blur := 1.5
@export_group("Sky")
@export var night_sky := Color("07162e")
@export var night_horizon := Color("263c59")
@export var sunset_horizon := Color("efaa7e")
## Gradient height curve. Lower values reveal blue sky closer to the horizon.
@export_range(0.2, 1.2, 0.05) var horizon_curve := 0.4
## Cloud projection scale and edge softness, using the supplied noise presets.
@export_range(0.05, 0.5, 0.01) var cloud_scale := 0.16
@export_range(0.04, 0.3, 0.01) var cloud_softness := 0.12
@export_group("Weather")
## Automatic weather is deterministic for expedition seed and saved active-time interval.
@export_enum("auto", "clear", "cloudy", "rain") var weather := "auto"
## Active exploration seconds per weather interval; blends at the start of each interval.
@export_range(60.0, 1800.0, 30.0) var weather_seconds := 300.0
@export_range(1.0, 60.0, 1.0) var transition_seconds := 20.0
## Rain starts depth fog this fraction earlier, without changing terrain clipping or simulation.
@export_range(0.4, 1.0, 0.05) var rain_fog_fraction := 0.75
## Relative automatic-weather weights. At least one must be positive.
@export_range(0.0, 1.0, 0.05) var clear_weight := 0.5
@export_range(0.0, 1.0, 0.05) var cloudy_weight := 0.3
@export_range(0.0, 1.0, 0.05) var rain_weight := 0.2
## Bounded nearby rain particles. Zero keeps rain lighting/fog but disables streaks.
@export_range(0, 1200, 50) var rain_particles := 500

func valid() -> bool:
	var ranges := [[day_seconds, 120, 7200], [starting_phase, 0, 1], [sun_elevation, 25, 80], [sun_azimuth, -180, 180], [sun_energy, 0, 3], [moon_energy, 0, 0.8], [day_ambient, 0, 2], [night_ambient, 0, 0.6], [exposure, 0.5, 1.5], [shadow_opacity, 0, 1], [shadow_blur, 0.5, 3], [horizon_curve, 0.2, 1.2], [cloud_scale, 0.05, 0.5], [cloud_softness, 0.04, 0.3], [weather_seconds, 60, 1800], [transition_seconds, 1, 60], [clear_weight, 0, 1], [cloudy_weight, 0, 1], [rain_weight, 0, 1]]
	for row in ranges:
		if not is_finite(row[0]) or row[0] < row[1] or row[0] > row[2]:
			return false
	for color in [sun_color, moon_color, day_ambient_color, night_ambient_color, night_sky, night_horizon, sunset_horizon]:
		if not is_finite(color.r) or not is_finite(color.g) or not is_finite(color.b) or color.r < 0 or color.r > 1 or color.g < 0 or color.g > 1 or color.b < 0 or color.b > 1 or color.a != 1:
			return false
	return is_finite(rain_fog_fraction) and rain_fog_fraction >= 0.4 and rain_fog_fraction <= 1 and weather in ["auto", "clear", "cloudy", "rain"] and clear_weight + cloudy_weight + rain_weight > 0 and transition_seconds <= weather_seconds and rain_particles >= 0 and rain_particles <= 1200
