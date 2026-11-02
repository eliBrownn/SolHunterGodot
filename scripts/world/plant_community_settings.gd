class_name PlantCommunitySettings
extends Resource
## Layout for new expeditions. Loaded worlds retain their captured parameters.
## Geographic patch scale in terrain cells; independent of render chunks.
@export_range(3.0,24.0,1.0) var patch_size := 10.0
## Candidate density multiplier. Zero disables community trees and understory.
@export_range(0.0,1.0,0.05) var coverage := 0.65
## Candidate footprint spacing in terrain cells; walking admission still applies.
@export_range(0.5,4.0,0.1) var spacing := 2.0
## Strength of nearby canopy suppression of visual understory, from zero to one.
@export_range(0.0,1.0,0.05) var canopy_influence := 0.65
## Blend climate moisture with existing local catchment and water-bank context.
@export_range(0.0,1.0,0.05) var drainage_influence := 0.4

func parameters() -> Dictionary:
	return {"patch_size":patch_size,"coverage":coverage,"spacing":spacing,"canopy_influence":canopy_influence,"drainage_influence":drainage_influence}

static func valid_parameters(value: Variant) -> bool:
	var limits := {"patch_size":[3.0,24.0],"coverage":[0.0,1.0],"spacing":[0.5,4.0],"canopy_influence":[0.0,1.0],"drainage_influence":[0.0,1.0]}
	if not value is Dictionary or value.size()!=limits.size(): return false
	for key in limits:
		var number: Variant = value.get(key)
		if not (number is float or number is int) or not is_finite(float(number)): return false
		if number<limits[key][0] or number>limits[key][1]: return false
	return true

func valid() -> bool:
	return valid_parameters(parameters())
