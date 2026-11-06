class_name SightingSettings
extends Resource

## Shared species definitions used for taxonomy, ecology and presentation of catalog sightings.
@export_file("*.tres") var species_catalog_path := ""
const MAX_CATALOG_SIGHTINGS := 512 # Explicit placement ceiling, not a population/balance control.
var _catalog_override: WeakRef
var _catalog_override_set := false
# A lazy reference avoids embedding the registry in every duplicated movement-tuning resource.
var species_catalog: Resource:
	get:
		if _catalog_override_set:
			return _catalog_override.get_ref() if _catalog_override != null else null
		return load(species_catalog_path) if not species_catalog_path.is_empty() and ResourceLoader.exists(species_catalog_path) else null
	set(value):
		_catalog_override_set = true
		_catalog_override = weakref(value) if value != null else null
## Additional explicit test/story sightings. Empty preserves the established expedition roster.
@export var catalog_sightings: Array[Resource] = []
## First-form wildlife pools for NEW expeditions. Captured into expedition state before admission.
## Empty preserves the prototype pool for isolated scenarios. Loaded expeditions retain saved pools.
@export var habitat_encounters: Array[HabitatEncounterPool] = []
## Display and local behavior tuning for trail/wilderness sightings; saved home IDs stay immutable.

## Show/register trail and wilderness sightings. Disabling hides them without deleting saved individuals.
@export var enabled := true
## Admit persistent prototype wildlife near explored cells, beyond the fixed trail trio. Applies on load/steps.
@export var wilderness_enabled := true
@export_group("Species Behavior")
## Apply species ecology profiles and deterministic individual variation. Off restores the original authored postures.
@export var species_profiles_enabled := true
## Shared behavior roots and inherited species/class/affinity specializations. Live on the next decision.
@export var behavior_library: SolBehaviorLibrary = preload("res://resources/sol_ecology/behavior_library.tres")
## Editable species defaults and explicit individual overrides. Live tuning; never rerolls identity or affinity.
@export var ecology_profiles: Array[SolEcologyProfile] = [preload("res://resources/sol_ecology/seedmote.tres"), preload("res://resources/sol_ecology/bramblepup.tres"), preload("res://resources/sol_ecology/trail_guard.tres")]
@export_group("Visibility")
## Maximum visible distance from the player, in cells. Re-evaluated while exploring.
@export_range(4, 32) var visible_radius := 28
## Manhattan proximity for labels and local flee/approach/guard responses. Does not author combat disposition.
@export_range(1, 6) var reaction_distance := 3
## Maximum Manhattan distance for deliberate observation with F. Applies to loaded sightings without changing IDs.
@export_range(1, 6) var observation_distance := 3
@export_group("Local Movement")
## Run local movement on active world ticks, including combat bystanders. Turning off retains saved positions.
@export var movement_enabled := true
## Number of 0.75-second activity ticks between decisions. Larger is slower; no offline catch-up.
@export_range(1, 8) var movement_interval_ticks := 1
## Maximum Manhattan distance from the fixed home. Reducing it causes a legal gradual return, not teleportation.
@export_range(1, 5) var home_radius := 5
## Update only Sols within this distance of the player. Distant saved positions remain intact.
@export_range(4, 32) var movement_radius := 28
## Neutral approach stops at this Manhattan distance. Does not change capture/relationship rules.
@export_range(1, 3) var comfort_distance := 2
## A fleeing Sol settles when this Manhattan separation is reached. Must be at least Reaction Distance.
@export_range(2, 8) var flee_release_distance := 5
## Fraction of each decision interval spent travelling. 1 fills the interval continuously; lower values add a pause between steps. Queued steps retain their duration.
@export_range(0.25, 1.0, 0.05) var movement_travel_fraction := 1.0
@export_group("Player Reactions")
## Manhattan distance at which an alert Sol disengages. Must exceed Reaction Distance and cover Flee Release Distance.
@export_range(2, 12) var reaction_release_distance := 6
## Neutral Sols resume approaching at this distance, stopping at Comfort Distance. Applies on the next decision.
@export_range(2, 6) var approach_resume_distance := 3
## Active 0.75-second ticks between neutral repositioning steps. Fleeing is never delayed.
@export_range(1, 16) var reposition_cooldown_ticks := 2
## Active ticks watching after disengagement before returning home and resuming patrol. Existing deadlines finish first.
@export_range(0, 32) var settle_ticks := 3
## Active ticks spent watching after noticing or repositioning before resuming safe local activity. Danger still interrupts immediately.
@export_range(0, 16) var attention_ticks := 2
## Active ticks of uninterrupted safe local activity between attention pauses. Urgent flight and encounter rules still interrupt.
@export_range(1, 16) var routine_ticks := 6
## Guard approaches an intruder to this Manhattan distance, then patrols while maintaining that spacing. Does not trigger combat by itself.
@export_range(1, 3) var guard_standoff_distance := 2
@export_group("Wandering")
## Autonomous patrol/rest cycles outside reaction range. Applies immediately to loaded worlds.
@export var wander_enabled := true
## Patrol goal distance in Manhattan cells, capped by Home Radius. Provisional balance.
@export_range(1, 5) var wander_radius := 3
## Minimum distance from the current cell for the next patrol goal, as a fraction of patrol radius. Applies to new goals.
@export_range(0.2, 1.0, 0.05) var patrol_goal_min_fraction := 0.5
## Minimum active 0.75-second ticks resting after arrival or goal expiry.
@export_range(1, 64) var rest_min_ticks := 1
## Maximum active ticks resting; must be at least Rest Min Ticks. Existing rests finish first.
@export_range(1, 64) var rest_max_ticks := 3
## Probability of resting at a reached goal. Other arrivals continue into another leg. Deterministic per saved leg.
@export_range(0.0, 1.0, 0.05) var patrol_rest_chance := 0.35
## Active blocked ticks before abandoning a patrol goal and choosing another. Cornered Sols still wait.
@export_range(1, 8) var blocked_goal_retry_ticks := 2
## Active ticks before an unreachable patrol goal expires. Existing deadlines finish first.
@export_range(1, 64) var goal_timeout_ticks := 12
## Maximum visited cells per path decision. Smaller budgets may defer obstacle detours.
@export_range(4, 128) var path_search_cells := 64
@export_group("Idle Animation")
## Height of the subtle idle bob in original sprite pixels. Zero disables bobbing.
@export_range(0.0, 3.0, 0.25) var bob_pixels := 1.0
## Idle animation cycles per active second. Pausing freezes animation.
@export_range(0.1, 3.0, 0.1) var bob_cycles := 0.8

# Keep the export boundary generic to avoid a SightingSettings/catalog script-type cycle.
# Runtime validation retains the concrete resource contract before any content is admitted.
static func script_matches(value: Resource, expected_path: String) -> bool:
	if value == null:
		return false
	var source: Script = value.get_script()
	while source != null:
		if source.resource_path == expected_path:
			return true
		source = source.get_base_script()
	return false

func catalog_record(species_id: String) -> Resource:
	return species_catalog.call("find", species_id) if species_catalog != null else null

func valid() -> bool:
	var habitat_policy: Array = []
	for pool in habitat_encounters:
		if pool == null or not pool.valid(species_catalog):
			return false
		habitat_policy.append(pool.snapshot())
	if not HabitatEncounterPool.valid_policy(habitat_policy):
		return false
	if catalog_sightings.size() > MAX_CATALOG_SIGHTINGS or (species_catalog == null and (not catalog_sightings.is_empty() or not species_catalog_path.is_empty() or _catalog_override_set)):
		return false
	if species_catalog != null and (not script_matches(species_catalog, "res://scripts/sols/sol_species_catalog.gd") or not species_catalog.call("valid")):
		return false
	var placement_cells := {}
	for placement in catalog_sightings:
		if not script_matches(placement, "res://scripts/sols/sol_catalog_sighting.gd") or not placement.call("valid", species_catalog) or placement_cells.has(placement.get("trail_x")):
			return false
		placement_cells[placement.get("trail_x")] = true
	if species_catalog != null:
		for entry in species_catalog.get("entries"):
			if not entry.ecology.valid(behavior_library):
				return false
	if behavior_library == null or not behavior_library.valid():
		return false
	if not SolSpeciesDefinition.whole(attention_ticks, 0, 16) or not SolSpeciesDefinition.whole(routine_ticks, 1, 16) or not SolSpeciesDefinition.whole(guard_standoff_distance, 1, 3) or not SolSpeciesDefinition.whole(blocked_goal_retry_ticks, 1, 8) or not is_finite(patrol_rest_chance) or patrol_rest_chance < 0 or patrol_rest_chance > 1:
		return false
	if not is_finite(movement_travel_fraction) or movement_travel_fraction < 0.25 or movement_travel_fraction > 1 or not is_finite(patrol_goal_min_fraction) or patrol_goal_min_fraction < 0.2 or patrol_goal_min_fraction > 1:
		return false
	var profile_ids := {}
	var defaults := {}
	for profile in ecology_profiles:
		if profile == null or not profile.valid(behavior_library) or profile_ids.has(profile.profile_id) or (profile.species_default and defaults.has(profile.species_id)):
			return false
		profile_ids[profile.profile_id] = true
		if profile.species_default:
			defaults[profile.species_id] = true
	if species_catalog != null:
		for entry in species_catalog.get("entries"):
			if profile_ids.has(entry.ecology.profile_id) or defaults.has(entry.species_id):
				return false # A catalog species has one authoritative default profile.
	if not SolSpeciesDefinition.whole(reaction_release_distance, 2, 12) or reaction_release_distance <= reaction_distance or reaction_release_distance < flee_release_distance or not SolSpeciesDefinition.whole(approach_resume_distance, 2, 6) or approach_resume_distance <= comfort_distance or not SolSpeciesDefinition.whole(reposition_cooldown_ticks, 1, 16) or not SolSpeciesDefinition.whole(settle_ticks, 0, 32):
		return false
	if not SolSpeciesDefinition.whole(wander_radius, 1, 5) or not SolSpeciesDefinition.whole(rest_min_ticks, 1, 64) or not SolSpeciesDefinition.whole(rest_max_ticks, rest_min_ticks, 64) or not SolSpeciesDefinition.whole(goal_timeout_ticks, 1, 64) or not SolSpeciesDefinition.whole(path_search_cells, 4, 128):
		return false
	return SolSpeciesDefinition.whole(visible_radius, 4, 32) and SolSpeciesDefinition.whole(reaction_distance, 1, 6) and SolSpeciesDefinition.whole(observation_distance, 1, 6) and SolSpeciesDefinition.whole(movement_interval_ticks, 1, 8) and SolSpeciesDefinition.whole(home_radius, 1, 5) and SolSpeciesDefinition.whole(movement_radius, 4, 32) and SolSpeciesDefinition.whole(comfort_distance, 1, 3) and SolSpeciesDefinition.whole(flee_release_distance, 2, 8) and flee_release_distance >= reaction_distance and is_finite(bob_pixels) and bob_pixels >= 0 and bob_pixels <= 3 and is_finite(bob_cycles) and bob_cycles >= 0.1 and bob_cycles <= 3
