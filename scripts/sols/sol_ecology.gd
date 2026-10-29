class_name SolEcology
extends RefCounted
## Resolve immutable identity samples into live profile tuning. No global RNG or saved-state writes.

const SAMPLE_NAMESPACE := "sol-ecology-v1" # Identity contract; do not turn into a balance setting.

static func configuration(base: SightingSettings) -> Array:
	var values: Array = []
	for field in preload("res://scripts/core/resource_storage_fields.gd").for_resource(base):
		if field not in ["ecology_profiles", "behavior_library", "species_catalog", "catalog_sightings"]:
			values.append(base.get(field))
	values.append(base.species_catalog.call("ecology_configuration") if base.species_catalog != null else [])
	values.append(base.behavior_library.configuration() if base.behavior_library != null else [])
	for profile in base.ecology_profiles:
		var fields: Array = []
		if profile != null:
			for field in preload("res://scripts/core/resource_storage_fields.gd").for_resource(profile):
				var value: Variant = profile.get(field)
				fields.append(value.duplicate() if value is PackedStringArray else value)
		values.append(fields)
	return values

static func sample(identity: String, stream: String) -> float:
	return float((SAMPLE_NAMESPACE + ":" + stream + ":" + identity).sha256_text().substr(0, 12).hex_to_int()) / 281474976710655.0

static func profile_for(entry: Dictionary, base: SightingSettings) -> SolEcologyProfile:
	var override_id: String = entry.get("behavior_profile", "")
	for profile in base.ecology_profiles:
		if profile.species_id != entry.species:
			continue
		if (not override_id.is_empty() and profile.profile_id == override_id) or (override_id.is_empty() and profile.species_default):
			return profile
	if override_id.is_empty() and base.species_catalog != null:
		var authored: Resource = base.catalog_record(entry.species)
		if authored != null:
			return authored.ecology
	return null

static func resolve(identity: String, entry: Dictionary, base: SightingSettings) -> Dictionary:
	var fallback := {"profile_id": "", "reaction": entry.reaction, "temperament": "", "behaviors": PackedStringArray(), "tuning": base}
	if not base.species_profiles_enabled:
		return fallback
	var profile := profile_for(entry, base)
	if profile == null:
		return fallback # Unprofiled content and a missing explicit override retain their authored posture.
	var caution := roundi((sample(identity, "caution") * 2 - 1) * profile.caution_variation_cells)
	var spacing := roundi((sample(identity, "spacing") * 2 - 1) * profile.spacing_variation_cells)
	var activity := 1.0 + (sample(identity, "activity") * 2 - 1) * profile.activity_variation
	var tuning := base.duplicate(false) as SightingSettings
	var actions := PackedStringArray()
	var selected := {}
	for branch in profile.behaviors:
		var behavior := base.behavior_library.select(branch, entry)
		if behavior.is_empty():
			continue # A directly selected, identity-restricted branch can be ineligible.
		actions.append(behavior.action)
		selected[behavior.action] = behavior.id
		for field in behavior.overrides:
			tuning.set(field, behavior.overrides[field])
	tuning.reaction_distance = clampi(tuning.reaction_distance + caution, 1, 6)
	tuning.flee_release_distance = clampi(tuning.flee_release_distance + caution, maxi(2, tuning.reaction_distance), 8)
	tuning.reaction_release_distance = clampi(tuning.reaction_release_distance + caution, maxi(tuning.reaction_distance + 1, tuning.flee_release_distance), 12)
	tuning.comfort_distance = clampi(tuning.comfort_distance + spacing, 1, 3)
	tuning.approach_resume_distance = clampi(tuning.approach_resume_distance + spacing, tuning.comfort_distance + 1, 6)
	tuning.wander_enabled = base.wander_enabled and actions.has("patrol")
	tuning.wander_radius = clampi(roundi(base.wander_radius * profile.patrol_radius_scale), 1, 5)
	tuning.rest_min_ticks = clampi(roundi(base.rest_min_ticks * profile.rest_duration_scale * activity), 1, 64)
	tuning.rest_max_ticks = clampi(roundi(base.rest_max_ticks * profile.rest_duration_scale * activity), tuning.rest_min_ticks, 64)
	var reaction := "Observing"
	for action in actions:
		if action in ["flee", "approach", "guard"]:
			reaction = {"flee": "Wary", "approach": "Watching", "guard": "Guarding"}[action]
	return {"profile_id": profile.profile_id, "reaction": reaction, "temperament": profile.temperament, "behaviors": actions, "selected_behaviors": selected, "tuning": tuning,
		"samples": {"caution": sample(identity, "caution"), "spacing": sample(identity, "spacing"), "activity": sample(identity, "activity")}}

static func decide(identity: String, home: Vector2i, position: Vector2i, player: Vector2i, saved: Dictionary, tick: int, resolved: Dictionary, allowed: Callable = Callable()) -> Dictionary:
	var decision := SolRoamingPolicy.decide(identity, home, position, player, resolved.reaction, saved, tick, resolved.tuning, allowed)
	if not resolved.profile_id.is_empty() and decision.action != "return" and not resolved.behaviors.has(decision.action):
		decision.action = "idle"
		decision.goal = position
	return decision
