class_name BattleSettings
extends Resource

## Shared species content; newly admitted individuals snapshot stats while existing saved traits remain intact.
@export var species_catalog: SolSpeciesCatalog = SolSpeciesCatalog.new()

## Persistent individual potential, training, and limited retraining supply.
@export var sol_stats: SolStatSettings = preload("res://resources/sol_stat_settings.tres")
## Signature class ranges and tactical thresholds.
@export var class_buffs: ClassBuffSettings = preload("res://resources/class_buff_settings.tres")

## Enable the explicit starter-selection and tactical battle slice.
@export var enabled := true
## Three provisional source starter options. Existing chosen starters retain their saved profiles.
@export var starters: Array[BattleProfile] = []
## Profiles for the current authored wild species. New battles snapshot current values.
@export var opponents: Array[BattleProfile] = []
## Arena half-width/height, in cells. Four produces the source wild 9x9 arena.
@export_range(3, 6) var arena_radius := 4
## Maximum free movement points derived from Speed each turn, before class bonuses/disruption. Extra movement spends shared AP.
@export_range(1, 8) var movement_points := 3
## Effective Speed per free movement point, rounded down at turn start. Buffs do not refill points mid-turn.
@export_range(1, 100) var speed_per_movement_point := 10
## Shared points per unit turn. Setup normally costs 2; attacks/healing normally cost 4. New battles snapshot this value.
@export_range(1, 12) var action_points := 6
## Maximum Manhattan release distance from the trainer. Deployment costs no movement points.
@export_range(1, 4) var release_range := 3
## Basic Seal power used by the source capture formula. Supply is unlimited in this owner-selected test slice.
@export_range(1, 100) var seal_power := 10
## Shared action-point cost of a Seal attempt. Failure still ends the turn; success resolves capture.
@export_range(1, 12) var seal_action_points := 4
@export_group("Exhausted Move Fallback")
## AP cost of Last Effort. Must fit in the turn budget so depleted moves cannot block combat.
@export_range(1, 12) var fallback_action_points := 4
## Percent of shared direct damage for the zero-power fallback. New battles snapshot this balance value.
@export_range(25, 75) var fallback_damage_percent := 40
## Clear Manhattan range of the fallback, in cells. Default requires close positioning.
@export_range(1, 3) var fallback_reach := 1
@export_group("Enemy Planning")
## Enemy penalty per point of expected field damage. Applied to both sides' shared terrain.
@export_range(0.0, 10.0, 0.25) var ai_hazard_weight := 2.0
## Enemy healing benefit relative to one point of damage; source aggressive policy is one quarter.
@export_range(0.0, 2.0, 0.05) var ai_heal_weight := 0.25
## Provisional benefit for imposing a useful shared field on the opponent.
@export_range(0.0, 10.0, 0.25) var ai_field_weight := 2.0
@export_group("Commander")
## Trainer run speed in world cells per real second. New battles snapshot this presentation value.
@export_range(1.0, 10.0, 0.25) var commander_run_speed := 6.0

func valid() -> bool:
	if not SolSpeciesDefinition.whole(action_points, 1, 12):
		return false
	if not SolSpeciesDefinition.whole(fallback_action_points, 1, action_points) or not SolSpeciesDefinition.whole(fallback_damage_percent, 25, 75) or not SolSpeciesDefinition.whole(fallback_reach, 1, 3):
		return false
	if not SolSpeciesDefinition.whole(seal_action_points, 1, 12):
		return false
	if not SolSpeciesDefinition.whole(speed_per_movement_point, 1, 100):
		return false
	if species_catalog == null or not species_catalog.valid():
		return false
	if not is_finite(commander_run_speed) or commander_run_speed < 1 or commander_run_speed > 10:
		return false
	if sol_stats == null or not sol_stats.valid() or class_buffs == null or not class_buffs.valid():
		return false
	if not is_finite(ai_hazard_weight) or ai_hazard_weight < 0 or ai_hazard_weight > 10 or not is_finite(ai_heal_weight) or ai_heal_weight < 0 or ai_heal_weight > 2 or not is_finite(ai_field_weight) or ai_field_weight < 0 or ai_field_weight > 10:
		return false
	if not SolSpeciesDefinition.whole(seal_power, 1, 100):
		return false
	if starters.size() != 3 or opponents.is_empty() or opponents.size() + species_catalog.entries.size() > SolSpeciesCatalog.MAX_SPECIES or not SolSpeciesDefinition.whole(arena_radius, 3, 6) or not SolSpeciesDefinition.whole(movement_points, 1, 8) or not SolSpeciesDefinition.whole(release_range, 1, 4):
		return false
	for group in [starters, opponents]:
		var ids: Dictionary = {}
		for profile in group:
			if profile == null or not profile.valid() or ids.has(profile.species_id) or species_catalog.find(profile.species_id) != null:
				return false
			ids[profile.species_id] = true
	return true

func opponent(species: String, assigned_affinity: String = "") -> Dictionary:
	var authored := species_catalog.find(species) if species_catalog != null else null
	if authored != null:
		return authored.battle_profile(assigned_affinity) # New species never get an affinity from species data.
	for profile in opponents:
		if profile.species_id == species:
			var result := profile.snapshot()
			if not assigned_affinity.is_empty():
				result.affinity = AffinityImprint.canonical(assigned_affinity)
			return result
	return {}

func evolution_forms_for(species: String) -> int:
	var authored := species_catalog.find(species) if species_catalog != null else null
	if authored != null:
		return authored.evolution_forms
	for profile in opponents:
		if profile.species_id == species:
			return profile.evolution_forms
	return 3
