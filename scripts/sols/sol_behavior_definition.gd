class_name SolBehaviorDefinition
extends Resource
## One inherited overworld behavior. Children reuse the parent's movement primitive.

## Unique authoring key; never an individual/species identity.
@export var behavior_id := ""
## Empty for a root. Children inherit all ancestor filters and tuning.
@export var parent_id := ""
## Implemented primitive, required on roots; children must select inherit.
@export_enum("inherit", "idle", "patrol", "flee", "approach", "guard") var action := "inherit"
## Empty lists match all. Nonempty lists match the individual's existing identity fields.
@export var species_ids: PackedStringArray = []
@export var class_ids: PackedStringArray = []
@export var affinity_ids: PackedStringArray = []
## Higher wins, then more filters, then deeper inheritance, then alphabetical ID.
@export_range(-100, 100) var priority := 0
@export_group("Response Overrides")
## -1 inherits. Manhattan cells; clamped with individual variation and release ordering.
@export_range(-1, 6) var reaction_distance := -1
@export_range(-1, 8) var flee_release_distance := -1
@export_range(-1, 12) var reaction_release_distance := -1
@export_range(-1, 3) var comfort_distance := -1
@export_range(-1, 6) var approach_resume_distance := -1
@export_range(-1, 3) var guard_standoff_distance := -1
## -1 inherits. Active 0.75-second exploration ticks.
@export_range(-1, 16) var attention_ticks := -1
@export_range(-1, 16) var routine_ticks := -1
@export_range(-1, 16) var reposition_cooldown_ticks := -1

const LIMITS := {"reaction_distance": [1, 6], "flee_release_distance": [2, 8], "reaction_release_distance": [2, 12], "comfort_distance": [1, 3], "approach_resume_distance": [2, 6], "guard_standoff_distance": [1, 3], "attention_ticks": [0, 16], "routine_ticks": [1, 16], "reposition_cooldown_ticks": [1, 16]}

func valid() -> bool:
	if not behavior_id.is_valid_identifier() or behavior_id.length() > 80 or (not parent_id.is_empty() and not parent_id.is_valid_identifier()) or not SolSpeciesDefinition.whole(priority, -100, 100):
		return false
	if (parent_id.is_empty() and action not in ["idle", "patrol", "flee", "approach", "guard"]) or (not parent_id.is_empty() and action != "inherit"):
		return false
	for filters in [species_ids, class_ids, affinity_ids]:
		var seen := {}
		for id in filters:
			if not id.is_valid_identifier() or id.length() > 80 or seen.has(id):
				return false
			seen[id] = true
	for field in LIMITS:
		var value: int = get(field)
		if value != -1 and not SolSpeciesDefinition.whole(value, LIMITS[field][0], LIMITS[field][1]):
			return false
	return true

func matches(entry: Dictionary) -> bool:
	return (species_ids.is_empty() or species_ids.has(entry.get("species", ""))) and (class_ids.is_empty() or class_ids.has(entry.get("class", ""))) and (affinity_ids.is_empty() or affinity_ids.has(entry.get("affinity", "")))
