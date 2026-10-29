class_name BattleProgress
extends RefCounted

static func empty() -> Dictionary:
	return {"starter_id": "", "profile": {}, "hp": 0, "serial": 0, "wins": 0,
		"losses": 0, "retreats": 0, "captures": 0, "last_result": {}, "defeated": {}, "grace_steps": 0, "active": false}

static func valid(data: Variant, individuals: Dictionary) -> bool:
	var fields := empty().keys()
	if data is Dictionary and not data.has("captures"):
		fields.erase("captures")
	if not data is Dictionary or not RecordShape.keys_match(data, fields) or not data.active is bool or data.active:
		return false # Active battle snapshots are deliberately not portable saves.
	if not SolSpeciesDefinition.whole(data.get("captures", 0), 0, ExpeditionContract.MAX_SAFE_INTEGER):
		return false
	for key in ["serial", "wins", "losses", "retreats"]:
		if not SolSpeciesDefinition.whole(data[key], 0, ExpeditionContract.MAX_SAFE_INTEGER):
			return false
	if data.wins + data.losses + data.retreats + data.get("captures", 0) != data.serial or not SolSpeciesDefinition.whole(data.grace_steps, 0, 8) or not data.defeated is Dictionary or data.defeated.size() != data.wins or not data.last_result is Dictionary:
		return false
	for identity in data.defeated:
		if not identity is String or not individuals.has(identity) or individuals[identity].get("location") != "wild" or data.defeated[identity] != true or not data.defeated[identity] is bool:
			return false
	if not data.starter_id is String:
		return false
	if data.starter_id.is_empty():
		return data.profile is Dictionary and data.profile.is_empty() and SolSpeciesDefinition.whole(data.hp, 0, 0) and data.serial == 0 and data.last_result.is_empty() and data.grace_steps == 0
	if not individuals.has(data.starter_id) or individuals[data.starter_id].get("location") not in ExpeditionContract.OWNED_LOCATIONS or not BattleProfile.valid_snapshot(data.profile) or not SolSpeciesDefinition.whole(data.hp, 0, int(data.profile.max_hp)):
		return false
	for key in ["species_id", "lineage_id", "class_id", "affinity"]:
		if individuals[data.starter_id].get(key) != data.profile[key]:
			return false
	if data.serial == 0:
		return data.last_result.is_empty()
	return RecordShape.keys_match(data.last_result, ["serial", "enemy_id", "outcome"]) and data.last_result.serial == data.serial and SolSpeciesDefinition.whole(data.last_result.serial, 1, ExpeditionContract.MAX_SAFE_INTEGER) and data.last_result.enemy_id is String and individuals.has(data.last_result.enemy_id) and data.last_result.outcome in ["victory", "exhaustion", "retreat", "captured"]

static func normalized(data: Dictionary) -> Dictionary:
	var copy := data.duplicate(true)
	copy.captures = int(copy.get("captures", 0))
	for key in ["hp", "serial", "wins", "losses", "retreats", "grace_steps"]:
		copy[key] = int(copy[key])
	if not copy.profile.is_empty():
		copy.profile = BattleProfile.normalized(copy.profile)
	if not copy.last_result.is_empty():
		copy.last_result.serial = int(copy.last_result.serial)
	return copy
