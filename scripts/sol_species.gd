class_name SolSpeciesDefinition
extends Resource
## Authored taxonomy, separate from an individual's independent affinity.

@export var species_id := ""
@export var lineage_id := ""
@export var class_id := ""
@export_range(1, 3) var ordinary_form := 1
@export_range(1, 3) var footprint := 1

func snapshot() -> Dictionary:
	return {"species_id": species_id, "lineage_id": lineage_id, "class_id": class_id,
		"ordinary_form": ordinary_form, "footprint": footprint}

func valid() -> bool:
	return valid_record(snapshot())

static func text(value: Variant, limit: int = 128) -> bool:
	return value is String and not value.strip_edges().is_empty() and value.length() <= limit

static func whole(value: Variant, low: int, high: int) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) == floor(float(value)) and value >= low and value <= high

static func valid_record(data: Dictionary) -> bool:
	return text(data.get("species_id")) and text(data.get("lineage_id")) and text(data.get("class_id")) and whole(data.get("ordinary_form"), 1, 3) and whole(data.get("footprint"), 1, 3)
