class_name MeadowAppearance
extends Resource
## Shared grass shading. Changes apply on restart/rebuild; no world-state effects.
## Fade blade coverage/height toward the existing protected trail corridor.
## Cosmetic only; restart/rebuild applies. Zero width disables this taper.
@export_range(0,3,1) var trail_verge_cells := 2
@export_range(0.0,1.0,0.05) var trail_verge_density := 0.4
@export_range(0.1,1.0,0.05) var trail_verge_height := 0.7
## Shared blade dimensions; normalized height is scaled by Nature Settings.
@export_range(0.01,0.12,0.00025) var blade_width := 0.028
@export_range(0.0,0.6,0.02) var blade_curve := 0.06
## Meadow, woodland, heath, marsh. Rebuild applies; these never alter saved ecology.
@export var biome_height := Vector4(1.0,0.75,0.55,1.2)
@export var biome_width := Vector4(1.0,1.5,0.65,0.65)
@export var biome_curve := Vector4(1.0,1.4,0.9,0.3)
@export var biome_coverage := Vector4(1.0,0.75,0.45,0.8)
@export var biome_colors: Array[Color] = [Color("879e65"),Color("46764a"),Color("9a8c52"),Color("528867")]
@export_range(0.4,1.0,0.05) var root_shade := 0.9
@export_range(0.8,1.5,0.05) var tip_brightness := 1.0
@export_range(0.0,0.5,0.05) var texture_detail := 0.05
@export_range(0.0,0.3,0.01) var patch_variation := 0.03
## Upward bias retains readable terrain shadows while allowing blade form to catch light.
@export_range(0.0,1.0,0.05) var normal_up_bias := 0.85
@export_range(0.0,0.5,0.05) var backlight_strength := 0.05
@export_range(0.1,0.9,0.05) var alpha_cutoff := 0.45
## World-cell displacement before rain scaling. Roots stay fixed.
@export_range(0.0,0.3,0.005) var wind_displacement := 0.015
@export_range(0.0,3.0,0.05) var wind_speed := 0.55
## Camera distance in terrain cells where gradual grass thinning begins. Near cover stays full density.
@export_range(8.0,48.0,1.0) var density_start := 24.0
## Camera distance where the minimum visual density is reached; existing draw distance still clips grass.
@export_range(16.0,64.0,1.0) var density_end := 44.0
## Distant cosmetic clump fraction. One disables thinning. Canonical flora and reserves are unaffected.
@export_range(0.2,1.0,0.05) var distant_density := 0.4

func valid() -> bool:
	if trail_verge_cells < 0 or trail_verge_cells > 3: return false
	if not is_finite(trail_verge_density) or trail_verge_density < 0.0 or trail_verge_density > 1.0: return false
	if not is_finite(trail_verge_height) or trail_verge_height < 0.1 or trail_verge_height > 1.0: return false
	if not is_finite(blade_width) or blade_width < 0.01 or blade_width > 0.12: return false
	if not is_finite(blade_curve) or blade_curve < 0.0 or blade_curve > 0.6: return false
	if biome_colors.size() != 4: return false
	for index in range(4):
		for number in [biome_height[index],biome_width[index],biome_curve[index]]:
			if not is_finite(number) or number < 0.1 or number > 2.5: return false
		if not is_finite(biome_coverage[index]) or biome_coverage[index] < 0.0 or biome_coverage[index] > 1.0: return false
		var color := biome_colors[index]
		if not color.is_equal_approx(color.clamp()) or color.a != 1.0: return false
		for channel in [color.r,color.g,color.b]:
			if not is_finite(channel): return false
	if not is_finite(density_start) or not is_finite(density_end) or not is_finite(distant_density): return false
	if density_start < 8.0 or density_start > 48.0 or density_end < 16.0 or density_end > 64.0 or density_end <= density_start or distant_density < 0.2 or distant_density > 1.0: return false
	var limits := {"root_shade":Vector2(0.4,1.0),"tip_brightness":Vector2(0.8,1.5),"texture_detail":Vector2(0,0.5),"patch_variation":Vector2(0,0.3),"normal_up_bias":Vector2(0,1),"backlight_strength":Vector2(0,0.5),"alpha_cutoff":Vector2(0.1,0.9),"wind_displacement":Vector2(0,0.3),"wind_speed":Vector2(0,3)}
	for key in limits:
		var value: float=get(key)
		if not is_finite(value) or value<limits[key].x or value>limits[key].y: return false
	return true
