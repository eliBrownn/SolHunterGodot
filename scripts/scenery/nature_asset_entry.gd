class_name NatureAssetEntry
extends Resource
## Static cosmetic asset admission. Units are world cells; rebuild to apply.
enum Surface { GROUND, BANK, WATER }
@export var scene: PackedScene
## Ground/bank uses the final terrain; floating water uses the pond's level.
@export_enum("Ground", "Bank", "Water") var surface: int = Surface.GROUND
## Authored UNIFORM scale; never normalize by height (flat pads/logs remain bounded).
@export_range(0.05, 2.0, 0.05) var uniform_scale := 0.5
## Maximum transformed horizontal diameter, in cells, after uniform scale/yaw.
@export_range(0.1, 3.0, 0.05) var maximum_width := 1.5
## Maximum visual height in cells. Dressing must remain below nearby Sol labels.
@export_range(0.05, 1.5, 0.05) var maximum_height := 0.8
## Maximum ground grade in degrees; floating entries ignore this setting.
@export_range(0.0, 25.0, 1.0) var maximum_slope := 18.0
## Small static-part and submitted-triangle admission budgets, per placed asset.
@export_range(1, 16) var maximum_parts := 8
@export_range(12, 4096) var maximum_triangles := 2048
## Material surfaces also cost draw calls even when contained in one mesh part.
@export_range(1, 32) var maximum_surfaces := 16

func valid() -> bool:
	return scene != null and surface in [0, 1, 2] and is_finite(uniform_scale) and uniform_scale >= 0.05 and uniform_scale <= 2.0 and is_finite(maximum_width) and maximum_width >= 0.1 and maximum_width <= 3 and is_finite(maximum_height) and maximum_height >= 0.05 and maximum_height <= 1.5 and is_finite(maximum_slope) and maximum_slope >= 0 and maximum_slope <= 25 and maximum_parts >= 1 and maximum_parts <= 16 and maximum_triangles >= 12 and maximum_triangles <= 4096 and maximum_surfaces >= 1 and maximum_surfaces <= 32

func admitted_model() -> Dictionary:
	if not valid():
		return {}
	var model: Dictionary = preload("res://scripts/scenery/nature_art.gd").parts(scene)
	if not model.supported or model.pieces.is_empty() or model.pieces.size() > maximum_parts or model.triangles > maximum_triangles or model.surfaces > maximum_surfaces:
		return {}
	var size: Vector3 = model.bounds.size * uniform_scale
	if size.y > maximum_height or maxf(size.x, size.z) > maximum_width:
		return {}
	return preload("res://scripts/scenery/nature_art.gd").compact_parts(scene)
