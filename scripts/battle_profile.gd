class_name BattleProfile
extends Resource
## Authored prototype profile, snapshotted when a starter is chosen or a battle begins.

@export_group("Identity")
@export var species_id := ""
@export var display_name := ""
@export var lineage_id := ""
@export var class_id := ""
## Individual starter affinity. Basic attacks in this slice are neutral physical moves.
@export var affinity := "grove"
@export_range(1, 55) var level := 3
@export_group("Combat")
## Authored resolved stats; no hidden IV/trait roll or automatic growth is applied in this slice.
@export_range(1, 1000) var max_hp := 44
@export_range(0, 1000) var attack := 19
@export_range(0, 1000) var defense := 19
@export_range(0, 1000) var speed := 18
@export var move_name := "Strike"
@export_range(1, 100) var move_power := 6
## Manhattan targeting range. No elemental/type multiplier is inferred.
@export_range(1, 6) var move_range := 2

func snapshot() -> Dictionary:
	return {"species_id": species_id, "display_name": display_name, "lineage_id": lineage_id,
		"class_id": class_id, "affinity": affinity, "level": level, "max_hp": max_hp,
		"attack": attack, "defense": defense, "speed": speed, "move_name": move_name,
		"move_power": move_power, "move_range": move_range}

func valid() -> bool:
	return valid_snapshot(snapshot())

static func valid_snapshot(data: Variant) -> bool:
	if not data is Dictionary or not ExpeditionState.keys_match(data, ["species_id", "display_name", "lineage_id", "class_id", "affinity", "level", "max_hp", "attack", "defense", "speed", "move_name", "move_power", "move_range"]):
		return false
	for field in ["species_id", "display_name", "lineage_id", "class_id", "affinity", "move_name"]:
		if not SolSpeciesDefinition.text(data[field], 80):
			return false
	for field in ["attack", "defense", "speed"]:
		if not SolSpeciesDefinition.whole(data[field], 0, 1000):
			return false
	return SolSpeciesDefinition.whole(data.level, 1, 55) and SolSpeciesDefinition.whole(data.max_hp, 1, 1000) and SolSpeciesDefinition.whole(data.move_power, 1, 100) and SolSpeciesDefinition.whole(data.move_range, 1, 6)

static func normalized(data: Dictionary) -> Dictionary:
	var result := data.duplicate(true)
	for field in ["level", "max_hp", "attack", "defense", "speed", "move_power", "move_range"]:
		result[field] = int(result[field])
	return result
