class_name ClassBuffSettings
extends Resource
const IDS := ["beast", "cinderkin", "tideborn", "verdant", "stormforged", "frostbound", "warborn", "blightborn", "earthbound", "skyborne", "mindweaver", "swarmkin", "stonebound", "wraithborn", "wyrmkin", "umbral", "construct", "feyborn", "eldritch"]
## Range edits apply only to new individuals. Battle constants below apply to the next battle.
@export var definitions: Array[ClassBuffDefinition] = []
## Maximum accumulated Kindling damage bonus, in percentage points.
@export_range(0, 100) var kindling_cap := 15
## Maximum Rooted Renewal healing over a battle, as a percentage of maximum HP.
@export_range(0, 100) var verdant_healing_cap := 15
## Tiles traveled before a Momentum damage bonus becomes active this turn.
@export_range(1, 8) var momentum_tiles := 2
## Cold Resolve is active at or below this percentage of maximum HP.
@export_range(1, 100) var low_health_percent := 50
## Ancient Might is active against targets strictly above this percentage of HP.
@export_range(1, 100) var wyrm_health_percent := 75
## Minimum Manhattan attack distance for Unworldly Form damage reduction.
@export_range(1, 8) var wraith_distance := 3
## Enemy-allied support within this Manhattan radius prevents Isolate Prey.
@export_range(1, 8) var isolation_distance := 2

func definition(id: String) -> ClassBuffDefinition:
	for row in definitions:
		if row.class_id == id:
			return row
	return null

func valid() -> bool:
	var seen := {}
	for row in definitions:
		if row == null or not row.valid() or row.class_id not in IDS or seen.has(row.class_id):
			return false
		if row.class_id == "eldritch" and (row.minimum != 0 or row.maximum != 0):
			return false # No Eldritch passive is authored; this is not a balance slider yet.
		seen[row.class_id] = true
	return definitions.size() == IDS.size() and kindling_cap >= 0 and kindling_cap <= 100 and verdant_healing_cap >= 0 and verdant_healing_cap <= 100 and momentum_tiles >= 1 and momentum_tiles <= 8 and low_health_percent >= 1 and low_health_percent <= 100 and wyrm_health_percent >= 1 and wyrm_health_percent <= 100 and wraith_distance >= 1 and wraith_distance <= 8 and isolation_distance >= 1 and isolation_distance <= 8
