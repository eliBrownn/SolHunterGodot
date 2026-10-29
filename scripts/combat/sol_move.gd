class_name SolMove
extends Resource
## Provisional authored move; individual affinity never changes this affinity.
@export var move_id := ""
@export var display_name := ""
@export_enum("fire", "water", "earth", "air", "lightning", "void", "spectral", "quantum") var affinity := "earth"
@export_enum("damage", "heal", "field", "phase", "quantum", "anchor", "buff", "debuff", "poison", "protect", "passive") var effect := "damage"
## Damage uses physical or special offense/protection independently of affinity.
@export_enum("physical", "special") var category := "physical"
## Stat affected by a buff or debuff; power is its percentage magnitude.
@export_enum("attack", "defense", "special_attack", "special_defense", "speed") var stat := "attack"
## Damage power, healing/poison HP, or buff/debuff/protection percentage. Field moves use zero.
@export_range(0, 100) var power := 6
## Manhattan range in cells; terrain and actor occupancy still apply.
@export_range(1, 6) var reach := 2
## Tactical field/footing lifetime in rounds. World recovery uses the library's saved stage interval.
@export_range(1, 1000) var duration := 8
## Shared action points spent on a successful use. New movebook entries snapshot this cost.
@export_range(0, 12) var action_points := 4
## Successful uses per encounter. Resets at battle entry, not at turn boundaries.
@export_range(1, 40) var max_uses := 16
## Direct-damage multiplier. Light multi-action moves use less of the same shared damage calculation.
@export_range(25, 125) var damage_percent := 100
## A hybrid adds this smaller effect once after its primary effect. Field hybrids affect one shared tile.
@export_enum("none", "field", "buff", "debuff", "protect") var secondary_effect := "none"
## Percentage magnitude for a hybrid buff/debuff/protection; field hybrids use zero.
@export_range(0, 20) var secondary_power := 0
## Passive moves occupy an equipped slot; guard triggers on a prepared incoming hit, renewal at stationary turn end.
@export_enum("none", "guard", "renewal") var passive_kind := "none"
## Concise authored purpose; displayed in loadout and battle tooltips.
@export_multiline var description := ""
@export_group("Environmental Vastra")
## Whether this ability uses Vastra. Purely physical, non-Vastra attacks do not disturb it.
@export var vastra_powered := true
## Marks offensive terrain abilities as aggressive; damage, poison and debuffs are always aggressive.
@export var aggressive := false
## Overload added per actually affected tile by an aggressive Vastra ability. Provisional points, not HP damage.
@export_range(1, 100) var overload_points := 2
## Overload removed per healing-affected tile, even at full HP. Can cross zero. Provisional points.
@export_range(1, 100) var restoration_points := 4

func snapshot() -> Dictionary:
	return {"id": move_id, "name": display_name, "affinity": affinity, "effect": effect, "power": power, "reach": reach, "duration": duration, "action_points": action_points, "max_uses": max_uses, "damage_percent": damage_percent, "secondary_effect": secondary_effect, "secondary_power": secondary_power, "passive_kind": passive_kind, "description": description, "category": category, "stat": stat, "vastra_powered": vastra_powered, "aggressive": aggressive, "overload_points": overload_points, "restoration_points": restoration_points}

static func cost(data: Dictionary) -> int:
	return int(data.get("action_points", 4 if data.effect in ["damage", "heal"] else 2))

static func uses(data: Dictionary) -> int:
	return int(data.get("max_uses", 3 if data.effect == "heal" else (16 if data.effect == "damage" else 5)))

static func secondary_summary(data: Dictionary) -> String:
	var effect: String = data.get("secondary_effect", "none")
	if effect == "none":
		return ""
	if effect == "field":
		return "shared %s tile (%d rounds)" % [str(data.affinity).capitalize(), int(data.duration)]
	if effect == "protect":
		return "self protection %d%% (%d turns)" % [int(data.secondary_power), int(data.duration)]
	return "%s %s %s%d%% (%d turns)" % ["opponent" if effect == "debuff" else "self", str(data.get("stat", "attack")).replace("_", " "), "−" if effect == "debuff" else "+", int(data.secondary_power), int(data.duration)]

static func valid(data: Variant) -> bool:
	if not data is Dictionary:
		return false
	if data.get("id", "") in ["last_effort", "legacy_basic"]:
		return false # Internal fallback actions cannot be authored as unlimited learned moves.
	var expected := ["id", "name", "affinity", "effect", "power", "reach", "duration"]
	for field in ["category", "stat", "action_points", "max_uses", "damage_percent", "secondary_effect", "secondary_power", "passive_kind", "description", "vastra_powered", "aggressive", "overload_points", "restoration_points"]:
		if data.has(field):
			expected.append(field)
	for field in ["vastra_powered", "aggressive"]:
		if data.has(field) and not data[field] is bool:
			return false
	for field in ["overload_points", "restoration_points"]:
		if data.has(field) and not SolSpeciesDefinition.whole(data[field], 1, 100):
			return false
	if data.has("action_points") and not SolSpeciesDefinition.whole(data.action_points, 0 if data.get("effect") == "passive" else 1, 0 if data.get("effect") == "passive" else 12):
		return false
	if data.has("max_uses") and not SolSpeciesDefinition.whole(data.max_uses, 1, 40):
		return false
	if data.has("damage_percent") and not SolSpeciesDefinition.whole(data.damage_percent, 25, 125):
		return false
	if data.has("description") and (not data.description is String or data.description.length() > 400):
		return false
	if data.get("secondary_effect", "none") not in ["none", "field", "buff", "debuff", "protect"] or not SolSpeciesDefinition.whole(data.get("secondary_power", 0), 0, 20):
		return false
	if data.get("passive_kind", "none") not in ["none", "guard", "renewal"]:
		return false
	if data.get("secondary_effect", "none") != "none" and data.get("effect") not in ["damage", "heal"]:
		return false
	if data.get("secondary_effect", "none") in ["buff", "debuff", "protect"] and int(data.get("secondary_power", 0)) == 0:
		return false
	if data.get("secondary_effect", "none") in ["none", "field"] and int(data.get("secondary_power", 0)) != 0:
		return false
	if data.get("effect") == "passive" and (data.get("passive_kind", "none") == "none" or cost(data) != 0 or int(data.get("power", 0)) < 1 or data.get("secondary_effect", "none") != "none"):
		return false
	if data.get("effect") != "passive" and data.get("passive_kind", "none") != "none":
		return false
	return ExpeditionState.keys_match(data, expected) and data.get("category", "physical") in ["physical", "special"] and data.get("stat", "attack") in ["attack", "defense", "special_attack", "special_defense", "speed"] and SolSpeciesDefinition.text(data.id, 80) and SolSpeciesDefinition.text(data.name, 80) and data.affinity in AffinityImprint.IDS and data.effect in ["damage", "heal", "field", "phase", "quantum", "anchor", "buff", "debuff", "poison", "protect", "passive"] and SolSpeciesDefinition.whole(data.power, 0, 100) and SolSpeciesDefinition.whole(data.reach, 1, 6) and SolSpeciesDefinition.whole(data.duration, 1, 1000)

static func normalized(data: Dictionary) -> Dictionary:
	var result := data.duplicate(true)
	for field in ["power", "reach", "duration"]:
		result[field] = int(result[field])
	for field in ["overload_points", "restoration_points", "action_points", "max_uses", "damage_percent", "secondary_power"]:
		if result.has(field):
			result[field] = int(result[field])
	return result
