class_name SolEcologyProfile
extends Resource
## Provisional authored overworld behavior; never a combat, affinity, or ownership definition.

## Stable authoring key. Named individual overrides refer to this key.
@export var profile_id := ""
## Existing species identifier; this resource does not register a new species.
@export var species_id := ""
## Use as the default for this species. Only one default per species is allowed.
@export var species_default := true
## Canonical broad temperament. Responses must agree with this category.
@export_enum("avoidant", "neutral", "assertive") var temperament := "neutral"
## One to three behavior-library branch IDs. Idle is required; at most one response primitive. Matching children inherit the base mechanics. Chase/social behavior is not implemented.
@export var behaviors: PackedStringArray = ["patrol", "idle", "approach"]
## Symmetric maximum individual offset to detection/flight thresholds in Manhattan cells. Clamped to valid global ranges.
@export_range(0, 2) var caution_variation_cells := 1
## Symmetric maximum individual offset to comfort/resumption distances in Manhattan cells.
@export_range(0, 1) var spacing_variation_cells := 1
## Stable per-individual fractional variation of rest durations; 0 disables activity variation.
@export_range(0.0, 0.75, 0.05) var activity_variation := 0.25
## Multiplier for the global patrol radius, clamped to 1–5 cells and Home Radius.
@export_range(0.25, 2.0, 0.05) var patrol_radius_scale := 1.0
## Multiplier for the global rest range, clamped to 1–64 active ticks.
@export_range(0.25, 4.0, 0.05) var rest_duration_scale := 1.0

func valid(library: SolBehaviorLibrary = null) -> bool:
	if not profile_id.is_valid_identifier() or profile_id.length() > 80 or not species_id.is_valid_identifier() or species_id.length() > 80 or temperament not in ["avoidant", "neutral", "assertive"]:
		return false
	if behaviors.size() < 1 or behaviors.size() > 3:
		return false
	var seen := {}
	var responses := 0
	var has_idle := false
	var allowed: Array = {"avoidant": ["flee"], "neutral": ["approach", "guard"], "assertive": ["guard"]}[temperament]
	for id in behaviors:
		var action: String = library.action_for(id) if library != null else id
		if seen.has(action) or (action not in ["patrol", "idle"] and action not in allowed):
			return false
		seen[action] = true
		has_idle = has_idle or action == "idle"
		if action not in ["patrol", "idle"]:
			responses += 1
	return has_idle and responses <= 1 and SolSpeciesDefinition.whole(caution_variation_cells, 0, 2) and SolSpeciesDefinition.whole(spacing_variation_cells, 0, 1) and is_finite(activity_variation) and activity_variation >= 0 and activity_variation <= 0.75 and is_finite(patrol_radius_scale) and patrol_radius_scale >= 0.25 and patrol_radius_scale <= 2 and is_finite(rest_duration_scale) and rest_duration_scale >= 0.25 and rest_duration_scale <= 4

