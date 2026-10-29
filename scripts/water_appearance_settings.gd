class_name WaterAppearanceSettings
extends Resource
## Cosmetic only. Restart/rebuild the view after editing; no saved geography changes.
@export_color_no_alpha var deep_color := Color("244e60")
@export_color_no_alpha var shallow_color := Color("55978f")
@export_color_no_alpha var wet_bank_color := Color("746e52")
@export_color_no_alpha var dry_bank_color := Color("a59a73")
## Small seamless grayscale texture for irregular cosmetic flow; generated once.
@export var ripple_noise: Texture2D = preload("res://resources/water_ripples.tres")
## Height above water where the bank blends fully into grass, in metres.
@export_range(0.1, 0.8, 0.01) var bank_blend_height := 0.32
## Water depth at which the deep color is reached, in metres.
@export_range(0.1, 1.0, 0.01) var depth_color_range := 0.4
## Depth of the narrow cosmetic foam fringe, in metres.
@export_range(0.01, 0.15, 0.01) var foam_depth := 0.06
## Normal-only ripple strength; never displaces the horizontal water surface.
@export_range(0.0, 0.15, 0.001) var ripple_strength := 0.006
## Cosmetic flow clock multiplier.
@export_range(0.0, 2.0, 0.05) var ripple_speed := 0.6

func valid() -> bool:
	if ripple_noise == null:
		return false
	for value in [deep_color, shallow_color, wet_bank_color, dry_bank_color]:
		if not is_finite(value.r) or not is_finite(value.g) or not is_finite(value.b) or not is_finite(value.a):
			return false
		if minf(value.r, minf(value.g, value.b)) < 0 or maxf(value.r, maxf(value.g, value.b)) > 1:
			return false
	return is_finite(bank_blend_height) and bank_blend_height >= 0.1 and bank_blend_height <= 0.8 and is_finite(depth_color_range) and depth_color_range >= 0.1 and depth_color_range <= 1.0 and is_finite(foam_depth) and foam_depth >= 0.01 and foam_depth <= 0.15 and is_finite(ripple_strength) and ripple_strength >= 0 and ripple_strength <= 0.15 and is_finite(ripple_speed) and ripple_speed >= 0 and ripple_speed <= 2

func apply_water(material: ShaderMaterial) -> void:
	for key in ["deep_color", "shallow_color", "depth_color_range", "foam_depth", "ripple_strength", "ripple_speed", "ripple_noise"]:
		material.set_shader_parameter(key, get(key))

func apply_bank(material: ShaderMaterial) -> void:
	for key in ["wet_bank_color", "dry_bank_color", "bank_blend_height"]:
		material.set_shader_parameter(key, get(key))
