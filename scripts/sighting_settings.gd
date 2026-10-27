class_name SightingSettings
extends Resource
## Display and local behavior tuning for authored sightings; fixed home IDs stay immutable.

## Show/register the three authored trail sightings. Disabling hides them without deleting saved individuals.
@export var enabled := true
## Maximum visible distance from the player, in cells. Re-evaluated while exploring.
@export_range(4, 32) var visible_radius := 14
## Manhattan proximity for labels and local flee/approach/guard responses. Does not author combat disposition.
@export_range(1, 6) var reaction_distance := 3
## Maximum Manhattan distance for deliberate observation with F. Applies to loaded sightings without changing IDs.
@export_range(1, 6) var observation_distance := 3
@export_group("Local Movement")
## Run local movement on active exploration ticks. Turning off retains current saved positions.
@export var movement_enabled := true
## Number of 0.75-second activity ticks between decisions. Larger is slower; no offline catch-up.
@export_range(1, 8) var movement_interval_ticks := 1
## Maximum Manhattan distance from the fixed home. Reducing it causes a legal gradual return, not teleportation.
@export_range(1, 5) var home_radius := 5
## Update only Sols within this distance of the player. Distant saved positions remain intact.
@export_range(4, 16) var movement_radius := 7
## Neutral approach stops at this Manhattan distance. Does not change capture/relationship rules.
@export_range(1, 3) var comfort_distance := 2
## A fleeing Sol settles when this Manhattan separation is reached. Must be at least Reaction Distance.
@export_range(2, 8) var flee_release_distance := 5
## Visual interpolation seconds per cell; authoritative movement remains one legal cardinal cell per decision.
@export_range(0.05, 0.5, 0.01) var movement_blend_seconds := 0.2
@export_group("Idle Animation")
## Height of the subtle idle bob in original sprite pixels. Zero disables bobbing.
@export_range(0.0, 3.0, 0.25) var bob_pixels := 1.0
## Idle animation cycles per active second. Pausing freezes animation.
@export_range(0.1, 3.0, 0.1) var bob_cycles := 0.8

func valid() -> bool:
	return SolSpeciesDefinition.whole(visible_radius, 4, 32) and SolSpeciesDefinition.whole(reaction_distance, 1, 6) and SolSpeciesDefinition.whole(observation_distance, 1, 6) and SolSpeciesDefinition.whole(movement_interval_ticks, 1, 8) and SolSpeciesDefinition.whole(home_radius, 1, 5) and SolSpeciesDefinition.whole(movement_radius, 4, 16) and SolSpeciesDefinition.whole(comfort_distance, 1, 3) and SolSpeciesDefinition.whole(flee_release_distance, 2, 8) and flee_release_distance >= reaction_distance and is_finite(movement_blend_seconds) and movement_blend_seconds >= 0.05 and movement_blend_seconds <= 0.5 and is_finite(bob_pixels) and bob_pixels >= 0 and bob_pixels <= 3 and is_finite(bob_cycles) and bob_cycles >= 0.1 and bob_cycles <= 3
