extends Resource
## Authored lab operation policy; no production reward or ecological permission.
@export var purpose_id := ""
@export var display_name := ""
@export_enum("clue", "transfer", "layout") var output_kind := "clue"
@export_range(1.0, 100.0, 1.0) var energy_cost := 12.0

func valid() -> bool:
	return not purpose_id.is_empty() and not display_name.is_empty() and output_kind in ["clue", "transfer", "layout"] and is_finite(energy_cost) and energy_cost > 0 and energy_cost <= 100
