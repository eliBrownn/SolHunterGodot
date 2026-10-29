class_name TerrainReliefSettings
extends Resource
## Generation tuning. New expeditions copy these settings; loaded saves retain theirs.

## Human-readable comparison name, shown in the preview and capture report.
@export var title := "Rolling"
## Broad noise sampling scale in world cells. Rebuild the preview to apply.
@export_range(64.0, 256.0, 1.0) var broad_scale := 144.0
## Broad landform amplitude in world cells; this is not measured peak-to-trough relief.
@export_range(0.0, 8.0, 0.1) var broad_amplitude := 3.2
## Secondary hill/valley sampling scale in cells.
@export_range(16.0, 96.0, 1.0) var detail_scale := 48.0
## Secondary landform amplitude in world cells.
@export_range(0.0, 2.0, 0.05) var detail_amplitude := 0.55
## Small surface variation amplitude in cells; its sampling scale is eight cells.
@export_range(0.0, 0.15, 0.01) var micro_amplitude := 0.06
## Maximum broad-channel domain displacement in cells. Zero disables domain warp.
@export_range(0.0, 16.0, 0.5) var warp_amplitude := 8.0
## Maximum slope of either ground triangle for a walkable cell, in degrees.
@export_range(15.0, 35.0, 1.0) var walkable_slope_degrees := 25.0
## Lateral bend multiplier for new expedition district approaches (not the safe anchors).
@export_range(0.5, 1.5, 0.1) var route_bend := 1.0
## Uniform pond radius multiplier. New expeditions only; saved with generation settings.
@export_range(0.6, 1.2, 0.1) var pond_scale := 1.0
## Maximum candidate ponds per 128-cell geographic region; conflicts can omit them.
@export_range(1, 3, 1) var pond_candidates := 3

func parameters() -> Dictionary:
	return {"broad_scale": broad_scale, "broad_amplitude": broad_amplitude,
		"detail_scale": detail_scale, "detail_amplitude": detail_amplitude,
		"micro_amplitude": micro_amplitude, "warp_amplitude": warp_amplitude,
		"walkable_slope_degrees": walkable_slope_degrees,
		"route_bend": route_bend, "pond_scale": pond_scale, "pond_candidates": float(pond_candidates)}

static func valid_parameters(value: Variant) -> bool:
	if not value is Dictionary:
		return false
	var limits := {"broad_scale": [64.0, 256.0], "broad_amplitude": [0.0, 8.0],
		"detail_scale": [16.0, 96.0], "detail_amplitude": [0.0, 2.0],
		"micro_amplitude": [0.0, 0.15], "warp_amplitude": [0.0, 16.0],
		"walkable_slope_degrees": [15.0, 35.0], "route_bend": [0.5, 1.5],
		"pond_scale": [0.6, 1.2], "pond_candidates": [1, 3]}
	if value.size() != limits.size():
		return false
	for key in limits:
		var number: Variant = value.get(key)
		if not (number is int or number is float) or not is_finite(float(number)):
			return false
		if number < limits[key][0] or number > limits[key][1]:
			return false
	return float(value.pond_candidates) == floor(float(value.pond_candidates))

func valid() -> bool:
	return not title.strip_edges().is_empty() and valid_parameters(parameters())
