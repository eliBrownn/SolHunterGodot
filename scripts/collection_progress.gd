class_name CollectionProgress
extends RefCounted
const PARTY_LIMIT := 6

static func empty() -> Dictionary:
	return {"selected": "", "owned": {}}

static func entry(profile: Dictionary, hp: int) -> Dictionary:
	return {"profile": BattleProfile.normalized(profile), "hp": hp, "xp": 0, "unlocks": {}}

static func valid(data: Variant, individuals: Dictionary, battle: Dictionary) -> bool:
	if not data is Dictionary or not ExpeditionState.keys_match(data, ["selected", "owned"]) or not data.selected is String or not data.owned is Dictionary or data.owned.size() > individuals.size():
		return false
	if data.owned.is_empty():
		return data.selected.is_empty() and battle.starter_id.is_empty()
	if not data.owned.has(data.selected) or not data.owned.has(battle.starter_id):
		return false
	if data.owned.size() < int(battle.get("captures", 0)) + 1:
		return false
	if battle.last_result.get("outcome") == "captured" and not data.owned.has(battle.last_result.enemy_id):
		return false
	var party_count := 0
	for id in data.owned:
		var row: Variant = data.owned[id]
		if not id is String or not individuals.has(id) or individuals[id].location not in ExpeditionState.OWNED_LOCATIONS or not row is Dictionary or not ExpeditionState.keys_match(row, ["profile", "hp", "xp", "unlocks"]) or not BattleProfile.valid_snapshot(row.profile) or not SolSpeciesDefinition.whole(row.hp, 0, int(row.profile.max_hp)) or not SolSpeciesDefinition.whole(row.xp, 0, ExpeditionState.MAX_SAFE_INTEGER) or not row.unlocks is Dictionary or row.unlocks.size() > 32:
			return false
		if individuals[id].location == "party":
			party_count += 1
		for field in ["species_id", "lineage_id", "class_id", "affinity"]:
			if row.profile[field] != individuals[id][field]:
				return false
		for move in row.unlocks:
			if not SolSpeciesDefinition.text(move, 80) or not SolSpeciesDefinition.whole(row.unlocks[move], 1, 55):
				return false
	var starter: Dictionary = data.owned[battle.starter_id]
	# Legacy saves can retain a stored/sealed starter and no party. C can bring it back;
	# do not silently relocate it during migration. Modern transfers never empty a party.
	return party_count <= PARTY_LIMIT and (party_count == 0 or individuals[data.selected].location == "party") and starter.profile == battle.profile and starter.hp == battle.hp

static func normalized(data: Dictionary) -> Dictionary:
	var result := data.duplicate(true)
	for row in result.owned.values():
		row.profile = BattleProfile.normalized(row.profile)
		row.hp = int(row.hp)
		row.xp = int(row.xp)
		for move in row.unlocks:
			row.unlocks[move] = int(row.unlocks[move])
	return result

static func grow(row: Dictionary, reward: int, policy: Dictionary) -> Dictionary:
	var result := row.duplicate(true)
	var profile: Dictionary = result.profile
	if int(profile.level) < int(policy.level_cap):
		var ceiling := int(policy.threshold_factor) * (int(policy.level_cap) - 1) * (int(policy.level_cap) - 1)
		result.xp = maxi(int(result.xp), mini(ceiling, int(result.xp) + reward))
	while int(profile.level) < int(policy.level_cap) and int(result.xp) >= int(policy.threshold_factor) * int(profile.level) * int(profile.level):
		profile.level += 1
		profile.max_hp = mini(1000, int(profile.max_hp) + int(policy.hp_growth))
		result.hp = mini(int(profile.max_hp), int(result.hp) + int(policy.hp_growth))
		for stat in ["attack", "defense", "speed", "special_attack", "special_defense"]:
			profile[stat] = mini(1000, int(profile[stat]) + int(policy.stat_growth))
	return result
