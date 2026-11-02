extends Resource
## Presentation palette; consumes a situation chosen by an existing owner.
## It does not infer danger, alter biomes or recolor individual affinities.

const COLORS = [&"leaf_shadow", &"leaf_light", &"leaf_tint", &"sun_tint", &"ambient_tint", &"fog_tint"]
const NUMBERS = [&"saturation", &"light_scale", &"fill_scale", &"exposure_scale", &"fog_density", &"fog_start_scale"]

@export var key: StringName = &"neutral"
@export_group("Foliage")
@export var leaf_shadow := Color.WHITE
@export var leaf_light := Color.WHITE
@export var leaf_tint := Color.WHITE
@export_range(0.0, 1.5, 0.05) var saturation := 1.0
@export_group("Atmosphere multipliers")
@export var sun_tint := Color.WHITE
@export var ambient_tint := Color.WHITE
@export var fog_tint := Color.WHITE
@export_range(0.25, 1.5, 0.05) var light_scale := 1.0
@export_range(0.25, 1.5, 0.05) var fill_scale := 1.0
@export_range(0.5, 1.5, 0.05) var exposure_scale := 1.0
## Main-game depth-fog onset multiplier. One preserves clear visibility; lower values bring haze closer.
@export_range(0.4, 1.0, 0.05) var fog_start_scale := 1.0
## Study-only non-volumetric fog density, inverse world meters.
@export_range(0.0, 0.02, 0.001) var fog_density := 0.008

func valid() -> bool:
	if key == &"": return false
	for field in COLORS:
		var color: Color = get(field)
		for value in [color.r, color.g, color.b, color.a]:
			if not is_finite(value) or value < 0 or value > 1: return false
	for spec in [[&"saturation", 0.0, 1.5], [&"light_scale", 0.25, 1.5], [&"fill_scale", 0.25, 1.5], [&"exposure_scale", 0.5, 1.5], [&"fog_density", 0.0, 0.02], [&"fog_start_scale", 0.4, 1.0]]:
		var value: float = get(spec[0])
		if not is_finite(value) or value < spec[1] or value > spec[2]: return false
	return true

func values() -> Dictionary:
	var result := {}
	for field in COLORS + NUMBERS: result[field] = get(field)
	return result

static func blend(from: Dictionary, to: Dictionary, weight: float) -> Dictionary:
	var result := {}
	for field in COLORS:
		var a: Color = from[field]
		var b: Color = to[field]
		result[field] = a.srgb_to_linear().lerp(b.srgb_to_linear(), weight).linear_to_srgb()
	for field in NUMBERS: result[field] = lerpf(from[field], to[field], weight)
	return result
