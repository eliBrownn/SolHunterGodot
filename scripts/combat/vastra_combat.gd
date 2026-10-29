class_name VastraCombat
extends RefCounted
## Owner-approved signed overload. Bounds and response curves are provisional tuning.

const MIN_OVERLOAD := -100
const MAX_OVERLOAD := 100
const MAX_BATTLE_CELLS := 169

static func move_delta(move: Dictionary) -> int:
	if not move.get("vastra_powered", true):
		return 0
	if move.effect == "heal":
		return -int(move.get("restoration_points", 4))
	if move.effect in ["damage", "debuff", "poison"] or move.get("aggressive", false):
		return int(move.get("overload_points", 2))
	return 0

static func valid_overload(value: Variant) -> bool:
	return SolSpeciesDefinition.whole(value, MIN_OVERLOAD, MAX_OVERLOAD)

static func valid_key(value: Variant) -> bool:
	if not value is String:
		return false
	var parts: PackedStringArray = value.split(":")
	return parts.size() == 2 and parts[0].is_valid_int() and parts[1].is_valid_int() and absi(int(parts[0])) <= 1000000 and absi(int(parts[1])) <= 1000000 and value == "%d:%d" % [int(parts[0]), int(parts[1])]

static func apply(candidate: Dictionary, changes: Variant, tick: int) -> bool:
	if not changes is Dictionary or changes.size() > MAX_BATTLE_CELLS:
		return false
	for key in changes:
		if not valid_key(key) or not valid_overload(changes[key]):
			return false
		if not candidate.tile_deltas.has(key):
			if candidate.tile_deltas.size() >= ExpeditionState.MAX_TILE_DELTAS:
				return false
			candidate.tile_deltas[key] = {}
			candidate.natural.order.append(key)
		var previous := int(candidate.tile_deltas[key].get("overload", 0))
		var value := int(changes[key])
		candidate.tile_deltas[key].overload = value
		if value == 0:
			candidate.natural.recovery_ticks.erase(key)
		elif previous == 0 or signi(previous) != signi(value) or not candidate.natural.recovery_ticks.has(key):
			candidate.natural.recovery_ticks[key] = tick
	return true

static func restoration_factor(overload: int, tuning: VastraSettings) -> float:
	var strength := float(maxi(0, -overload))
	return tuning.restoration_max_bonus * strength / (strength + tuning.restoration_half_strength)
