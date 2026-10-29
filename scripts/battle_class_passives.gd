class_name BattleClassPassives
extends RefCounted
## Battle-local counters. Individual rolls are supplied by ExpeditionState, never generated here.
var _battle: WeakRef
var battle: TacticalBattle:
	get:
		return _battle.get_ref() as TacticalBattle
var settings: ClassBuffSettings
var units: Dictionary = {}

func _init(owner_battle: TacticalBattle, tuning: ClassBuffSettings) -> void:
	_battle = weakref(owner_battle)
	settings = tuning

func admit(side: String, traits: Dictionary) -> void:
	if traits.is_empty():
		return
	units[side] = {"class": traits.class_id, "potency": int(traits.potency), "kindling": 0,
		"moved": 0, "attacked": false, "first_turn": true, "first_hit": true,
		"root_healing": 0.0, "root_credit": 0.0, "stone": false, "undertow": false}

func has_class(side: String, id: String) -> bool:
	return units.get(side, {}).get("class", "") == id

func potency(side: String) -> int:
	return int(units.get(side, {}).get("potency", 0))

func describe(side: String, caption: String) -> void:
	battle.consequence(side, caption, "class_passive", [battle.unit_cell(side)], side)

func reason(side: String, reasons: Variant) -> void:
	if reasons == null:
		return
	var definition := settings.definition(str(units.get(side, {}).get("class", "")))
	if definition != null:
		reasons.append(definition.display_name)

func present_hit(side: String, previous: Dictionary) -> void:
	if previous.is_empty():
		return
	if has_class(side, "cinderkin") and int(units[side].kindling) != int(previous[side].kindling):
		describe(side, "Kindling · %d%% accumulated" % int(units[side].kindling))
	if has_class(side, "tideborn") and not previous[side].undertow:
		describe(side, "Undertow · return-hit protection ready")
	var other := "enemy" if side == "ally" else "ally"
	if has_class(other, "mindweaver") and previous[other].first_hit:
		describe(other, "Forethought used on the first hit")

func move_bonus(side: String) -> int:
	return potency(side) if has_class(side, "skyborne") and units[side].first_turn else 0

func moved(side: String, tiles: int) -> void:
	if units.has(side) and tiles > 0:
		var was_stone: bool = units[side].stone
		units[side].moved += tiles
		units[side].stone = false
		if was_stone:
			describe(side, "Set Like Stone ends after movement")

func begin_turn(side: String) -> void:
	if units.has(side):
		units[side].moved = 0
		units[side].attacked = false

func end_turn(side: String) -> void:
	if units.has(side):
		var unit: Dictionary = units[side]
		if has_class(side, "cinderkin") and not unit.attacked:
			var previous: int = unit.kindling
			unit.kindling = 0
			if previous > 0:
				describe(side, "Kindling reset · no attack this turn")
		if has_class(side, "verdant") and unit.moved == 0 and battle.unit_hp(side) > 0:
			var profile: Dictionary = battle.ally if side == "ally" else battle.enemy
			var limit := float(profile.max_hp) * settings.verdant_healing_cap / 100.0
			var available := maxf(0.0, limit - float(unit.root_healing))
			unit.root_credit = minf(available, float(unit.root_credit) + float(profile.max_hp) * potency(side) / 100.0)
			var amount := mini(int(floor(unit.root_credit)), int(profile.max_hp) - battle.unit_hp(side))
			if amount > 0:
				battle.set_unit_hp(side, battle.unit_hp(side) + amount)
				unit.root_credit -= amount
				unit.root_healing += amount
				battle.feedback("heal", battle.unit_cell(side), amount, profile.affinity, "Rooted Renewal", "class_passive", side)
			# Carry only sub-HP rounding, never bank unused healing while at full health.
			unit.root_credit = fmod(float(unit.root_credit), 1.0)
		if has_class(side, "stonebound") and unit.moved == 0:
			var was_stone: bool = unit.stone
			unit.stone = true
			if not was_stone:
				describe(side, "Set Like Stone · defense ready")
		unit.first_turn = false
	var other := "enemy" if side == "ally" else "ally"
	if units.has(other):
		var was_undertow: bool = units[other].undertow
		units[other].undertow = false
		if was_undertow:
			describe(other, "Undertow expired")

func damage_factor(side: String, move: Dictionary, origin: Vector2i, moved_tiles: int = -1, reasons: Variant = null) -> float:
	var other := "enemy" if side == "ally" else "ally"
	var target: Dictionary = battle.enemy if side == "ally" else battle.ally
	var range_to_target := TacticalBattle.distance(origin, battle.unit_cell(other))
	var factor := 1.0
	var rate := float(potency(side)) / 100.0
	var walked := int(units.get(side, {}).get("moved", 0)) if moved_tiles < 0 else moved_tiles
	if has_class(side, "beast") and battle.tile_affinities.get(origin, "") == move.affinity:
		factor *= 1.0 + rate
		reason(side, reasons)
	if has_class(side, "cinderkin"):
		factor *= 1.0 + minf(settings.kindling_cap, float(units[side].kindling) + potency(side)) / 100.0
		reason(side, reasons)
	if has_class(side, "stormforged") and walked >= settings.momentum_tiles:
		factor *= 1.0 + rate
		reason(side, reasons)
	if has_class(side, "warborn") and range_to_target == 1:
		factor *= 1.0 + rate
		reason(side, reasons)
	if has_class(side, "blightborn") and battle.has_affliction(other):
		factor *= 1.0 + rate
		reason(side, reasons)
	if has_class(side, "wyrmkin") and battle.unit_hp(other) * 100 > int(target.max_hp) * settings.wyrm_health_percent:
		factor *= 1.0 + rate
		reason(side, reasons)
	# Additional allies are explicit tactical context, never inferred from party/storage membership.
	if has_class(side, "swarmkin") and battle.has_nearby_support(side, battle.unit_cell(other), 1):
		factor *= 1.0 + rate
		reason(side, reasons)
	if has_class(side, "umbral") and not battle.has_nearby_support(other, battle.unit_cell(other), settings.isolation_distance):
		factor *= 1.0 + rate
		reason(side, reasons)
	var reduction := float(potency(other)) / 100.0
	if has_class(other, "tideborn") and units[other].undertow:
		factor *= 1.0 - reduction
		reason(other, reasons)
	if has_class(other, "frostbound") and battle.unit_hp(other) * 100 <= int(target.max_hp) * settings.low_health_percent:
		factor *= 1.0 - reduction
		reason(other, reasons)
	if has_class(other, "mindweaver") and units[other].first_hit:
		factor *= 1.0 - reduction
		reason(other, reasons)
	if has_class(other, "stonebound") and units[other].stone:
		factor *= 1.0 - reduction
		reason(other, reasons)
	if has_class(other, "wraithborn") and range_to_target >= settings.wraith_distance:
		factor *= 1.0 - reduction
		reason(other, reasons)
	return factor

func landed(side: String) -> void:
	var other := "enemy" if side == "ally" else "ally"
	if units.has(side):
		units[side].attacked = true
		if has_class(side, "cinderkin"):
			units[side].kindling = mini(settings.kindling_cap, int(units[side].kindling) + potency(side))
		if has_class(side, "tideborn"):
			units[side].undertow = true
	if units.has(other):
		units[other].first_hit = false
