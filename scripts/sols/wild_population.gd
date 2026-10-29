class_name WildPopulation
extends RefCounted
## Saved home deadlines and generation authority. Views never activate an individual.

static func deplete(records: Dictionary, identity: String, tick: int, delay: int) -> Dictionary:
	var result := records.duplicate(true)
	var origin := SolIdentityContract.parse(identity)
	if delay <= 0 or origin.is_empty() or origin.generation >= 2147483647 or tick > ExpeditionContract.MAX_SAFE_INTEGER - delay:
		return result
	var home := SolIdentityContract.make(origin.seed, Vector2i(origin.home[0], origin.home[1]), origin.species_id)
	var previous: Dictionary = records.get(home, {})
	if not previous.is_empty() and (not previous.active or int(previous.generation) != int(origin.generation) or int(previous.ready_at) > tick):
		return result
	result[home] = {"generation": int(origin.generation) + 1, "ready_at": tick + delay, "active": false}
	return result

static func valid(records: Variant, seed_value: int, tick: int, individuals: Dictionary, defeated: Dictionary) -> bool:
	if not records is Dictionary or records.size() > ExpeditionContract.MAX_INDIVIDUALS:
		return false
	for home in records:
		var origin := SolIdentityContract.parse(home)
		var row: Variant = records[home]
		if origin.is_empty() or origin.seed != seed_value or origin.generation != 0 or not row is Dictionary or not RecordShape.keys_match(row, ["generation", "ready_at", "active"]) or not row.active is bool or not SolSpeciesDefinition.whole(row.generation, 1, 2147483647) or not SolSpeciesDefinition.whole(row.ready_at, 0, ExpeditionContract.MAX_SAFE_INTEGER):
			return false
		var cell := Vector2i(origin.home[0], origin.home[1])
		var previous := SolIdentityContract.make(seed_value, cell, origin.species_id, int(row.generation) - 1)
		var candidate := SolIdentityContract.make(seed_value, cell, origin.species_id, int(row.generation))
		if not individuals.has(previous) or (individuals[previous].location == "wild" and not defeated.has(previous)):
			return false
		if row.active:
			if int(row.ready_at) > tick or not individuals.has(candidate):
				return false
		elif individuals.has(candidate):
			return false
	return true

static func normalized(records: Dictionary) -> Dictionary:
	var result := records.duplicate(true)
	for row in result.values():
		row.generation = int(row.generation)
		row.ready_at = int(row.ready_at)
	return result
