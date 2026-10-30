class_name HabitatEncounterPool
extends Resource
## Provisional species eligibility for a generated habitat, separate from scenery and affinity.
@export_enum("Meadow", "Woodland", "Heath", "Marsh") var ground := 0
## Relative selection weights for supported first forms; not percentages or final rarity.
@export var species_weights: Dictionary[String, int] = {}

func snapshot() -> Dictionary:
	return {"ground": ground, "species_weights": species_weights.duplicate()}

func valid(catalog: Resource) -> bool:
	if catalog == null or not catalog.has_method("find") or not valid_policy([snapshot()]):
		return false
	for id in species_weights:
		var species: Resource = catalog.call("find", id)
		if species == null or species.ordinary_form != 1 or species.footprint != 1:
			return false
	return true

static func valid_policy(value: Variant) -> bool:
	if not value is Array or value.size() > 4:
		return false
	var grounds := {}
	for row in value:
		if not row is Dictionary or not RecordShape.keys_match(row, ["ground", "species_weights"]) or not SolSpeciesDefinition.whole(row.ground, 0, 3) or grounds.has(int(row.ground)):
			return false
		grounds[int(row.ground)] = true
		if not row.species_weights is Dictionary or row.species_weights.is_empty() or row.species_weights.size() > 32:
			return false
		for id in row.species_weights:
			if not id is String or not id.is_valid_identifier() or id.length() > 80 or not SolSpeciesDefinition.whole(row.species_weights[id], 1, 1000):
				return false
	return true

static func normalized(value: Array) -> Array:
	var result: Array = []
	for row in value:
		var weights := {}
		for id in row.species_weights:
			weights[id] = int(row.species_weights[id])
		result.append({"ground": int(row.ground), "species_weights": weights})
	return result

static func select_species(policy: Array, ground_id: int, roll: int) -> String:
	for row in policy:
		if int(row.ground) != ground_id:
			continue
		var ids: Array = row.species_weights.keys()
		ids.sort()
		var total := 0
		for id in ids:
			total += int(row.species_weights[id])
		var pick := posmod(roll, total)
		for id in ids:
			pick -= int(row.species_weights[id])
			if pick < 0:
				return id
	return ""
