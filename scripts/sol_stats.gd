class_name SolStats
extends RefCounted
## Saved individual potential, independent of affinity, ownership, and class potency.
const STATS := ["max_hp", "attack", "defense", "special_attack", "special_defense", "speed"]

static func random_for(identity: String, stream_name: String) -> RandomNumberGenerator:
	var random := RandomNumberGenerator.new()
	# SHA-256 namespace streams avoid engine hash()/global RNG and separate all individual rolls.
	random.seed = (identity + ":" + stream_name).sha256_text().substr(0, 15).hex_to_int()
	return random

static func generate(identity: String, class_id: String, settings: SolStatSettings, buffs: ClassBuffSettings) -> Dictionary:
	var ivs := {}
	var training := {}
	for stat in STATS:
		var random := random_for(identity, "iv-v1:" + stat)
		var total := 0
		for sample in range(settings.iv_samples):
			total += random.randi_range(settings.iv_min, settings.iv_max)
		ivs[stat] = roundi(float(total) / settings.iv_samples)
		training[stat] = 0
	var definition := buffs.definition(class_id)
	var potency := random_for(identity, "class-buff-v1").randi_range(definition.minimum, definition.maximum) if definition != null else 0
	return {"version": 1, "ivs": ivs, "class_id": class_id, "potency": potency,
		"base": {}, "training": training, "earned": 0, "forms": 3,
		"hp_growth": 2, "stat_growth": 1, "policy": settings.parameters()}

static func capacity(row: Dictionary, form: int) -> Dictionary:
	var p: Dictionary = row.policy
	var fraction := 100 if form >= int(row.forms) else (int(p.first_form_percent) if form == 1 else int(p.second_form_percent))
	var cap := int(p.points_per_stat) * fraction / 100
	return {"stat": cap, "total": cap * int(p.trained_stats)}

static func spent(row: Dictionary) -> int:
	var total := 0
	for value in row.training.values():
		total += int(value)
	return total

static func bonus(row: Dictionary, stat: String) -> float:
	return float(row.training[stat]) * float(row.policy.training_percent) / float(row.policy.points_per_stat)

static func resolve(row: Dictionary, level: int) -> Dictionary:
	if row.base.is_empty():
		return {}
	var result := BattleProfile.normalized(row.base)
	var delta := level - int(result.level)
	for stat in STATS:
		var base := float(result[stat]) + delta * int(row.hp_growth if stat == "max_hp" else row.stat_growth)
		result[stat] = clampi(roundi(base * float(row.ivs[stat]) / 100.0 * (1.0 + bonus(row, stat) / 100.0)), 1 if stat == "max_hp" else 0, 1000)
	result.level = level
	return result

static func normalized(row: Dictionary) -> Dictionary:
	var result := row.duplicate(true)
	for key in ["version", "potency", "earned", "forms", "hp_growth", "stat_growth"]:
		result[key] = int(result[key])
	for group in ["ivs", "training", "policy"]:
		for key in result[group]:
			result[group][key] = int(result[group][key])
	if not result.base.is_empty():
		result.base = BattleProfile.normalized(result.base)
	return result

static func valid(row: Variant, individual: Dictionary) -> bool:
	if not row is Dictionary or not ExpeditionState.keys_match(row, ["version", "ivs", "class_id", "potency", "base", "training", "earned", "forms", "hp_growth", "stat_growth", "policy"]) or not SolSpeciesDefinition.whole(row.version, 1, 1) or row.class_id != individual.class_id or not SolStatSettings.valid_parameters(row.policy):
		return false
	if not row.ivs is Dictionary or not ExpeditionState.keys_match(row.ivs, STATS) or not row.training is Dictionary or not ExpeditionState.keys_match(row.training, STATS) or not row.base is Dictionary:
		return false
	if not SolSpeciesDefinition.whole(row.potency, 0, 100) or not SolSpeciesDefinition.whole(row.forms, int(individual.ordinary_form), 3) or not SolSpeciesDefinition.whole(row.hp_growth, 0, 10) or not SolSpeciesDefinition.whole(row.stat_growth, 0, 10):
		return false
	var caps := capacity(row, int(individual.ordinary_form))
	if not SolSpeciesDefinition.whole(row.earned, 0, caps.total):
		return false
	for stat in STATS:
		if not SolSpeciesDefinition.whole(row.ivs[stat], int(row.policy.iv_min), int(row.policy.iv_max)) or not SolSpeciesDefinition.whole(row.training[stat], 0, caps.stat):
			return false
	if spent(row) > int(row.earned):
		return false
	if not row.base.is_empty():
		if not BattleProfile.valid_snapshot(row.base):
			return false
		for field in ["species_id", "lineage_id", "class_id", "affinity"]:
			if row.base[field] != individual[field]:
				return false
	return true

