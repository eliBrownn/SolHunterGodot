class_name SolMove
extends Resource
## Provisional authored move; individual affinity never changes this affinity.
@export var move_id := ""
@export var display_name := ""
@export_enum("fire", "water", "earth", "air", "lightning", "void", "spectral", "quantum") var affinity := "earth"
@export_enum("damage", "heal", "field", "phase", "quantum", "anchor") var effect := "damage"
## Physical damage power or self-healing amount. Field moves use zero.
@export_range(0, 100) var power := 6
## Manhattan range in cells; terrain and actor occupancy still apply.
@export_range(1, 6) var reach := 2
## Tactical field/footing lifetime in rounds. World recovery uses the library's saved stage interval.
@export_range(1, 1000) var duration := 8

func snapshot() -> Dictionary:
	return {"id": move_id, "name": display_name, "affinity": affinity, "effect": effect, "power": power, "reach": reach, "duration": duration}

static func valid(data: Variant) -> bool:
	return data is Dictionary and ExpeditionState.keys_match(data, ["id", "name", "affinity", "effect", "power", "reach", "duration"]) and SolSpeciesDefinition.text(data.id, 80) and SolSpeciesDefinition.text(data.name, 80) and data.affinity in AffinityImprint.IDS and data.effect in ["damage", "heal", "field", "phase", "quantum", "anchor"] and SolSpeciesDefinition.whole(data.power, 0, 100) and SolSpeciesDefinition.whole(data.reach, 1, 6) and SolSpeciesDefinition.whole(data.duration, 1, 1000)

static func normalized(data: Dictionary) -> Dictionary:
	var result := data.duplicate(true)
	for field in ["power", "reach", "duration"]:
		result[field] = int(result[field])
	return result
