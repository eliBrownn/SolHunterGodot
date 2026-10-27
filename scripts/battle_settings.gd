class_name BattleSettings
extends Resource

## Enable the explicit starter-selection and tactical battle slice.
@export var enabled := true
## Three provisional source starter options. Existing chosen starters retain their saved profiles.
@export var starters: Array[BattleProfile] = []
## Profiles for the current authored wild species. New battles snapshot current values.
@export var opponents: Array[BattleProfile] = []
## Arena half-width/height, in cells. Four produces the source wild 9x9 arena.
@export_range(3, 6) var arena_radius := 4
## Cardinal cells available per unit turn. Movement may be split before the basic attack/end-turn action.
@export_range(1, 8) var movement_points := 3
## Maximum Manhattan release distance from the trainer. Deployment costs no movement points.
@export_range(1, 4) var release_range := 3

func valid() -> bool:
	if starters.size() != 3 or opponents.is_empty() or opponents.size() > 16 or not SolSpeciesDefinition.whole(arena_radius, 3, 6) or not SolSpeciesDefinition.whole(movement_points, 1, 8) or not SolSpeciesDefinition.whole(release_range, 1, 4):
		return false
	for group in [starters, opponents]:
		var ids: Dictionary = {}
		for profile in group:
			if profile == null or not profile.valid() or ids.has(profile.species_id):
				return false
			ids[profile.species_id] = true
	return true

func opponent(species: String) -> Dictionary:
	for profile in opponents:
		if profile.species_id == species:
			return profile.snapshot()
	return {}
