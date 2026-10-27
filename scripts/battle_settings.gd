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
## Basic Seal power used by the source capture formula. Supply is unlimited in this owner-selected test slice.
@export_range(1, 100) var seal_power := 10
## Enemy penalty per point of expected field damage. Applied to both sides' shared terrain.
@export_range(0.0, 10.0, 0.25) var ai_hazard_weight := 2.0
## Enemy healing benefit relative to one point of damage; source aggressive policy is one quarter.
@export_range(0.0, 2.0, 0.05) var ai_heal_weight := 0.25
## Provisional benefit for imposing a useful shared field on the opponent.
@export_range(0.0, 10.0, 0.25) var ai_field_weight := 2.0

func valid() -> bool:
	if not is_finite(ai_hazard_weight) or ai_hazard_weight < 0 or ai_hazard_weight > 10 or not is_finite(ai_heal_weight) or ai_heal_weight < 0 or ai_heal_weight > 2 or not is_finite(ai_field_weight) or ai_field_weight < 0 or ai_field_weight > 10:
		return false
	if not SolSpeciesDefinition.whole(seal_power, 1, 100):
		return false
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
