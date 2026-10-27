class_name SightingSettings
extends Resource
## Presentation tuning for the provisional authored sightings; never changes home IDs.

## Show/register the three authored trail sightings. Disabling hides them without deleting saved individuals.
@export var enabled := true
## Maximum visible distance from the player, in cells. Re-evaluated while exploring.
@export_range(4, 32) var visible_radius := 14
## Manhattan distance at which a Sol visibly reacts. This changes posture labels, not aggression or combat rules.
@export_range(1, 6) var reaction_distance := 3
## Height of the subtle idle bob in original sprite pixels. Zero disables bobbing.
@export_range(0.0, 3.0, 0.25) var bob_pixels := 1.0
## Idle animation cycles per active second. Pausing freezes animation.
@export_range(0.1, 3.0, 0.1) var bob_cycles := 0.8

func valid() -> bool:
	return SolSpeciesDefinition.whole(visible_radius, 4, 32) and SolSpeciesDefinition.whole(reaction_distance, 1, 6) and is_finite(bob_pixels) and bob_pixels >= 0 and bob_pixels <= 3 and is_finite(bob_cycles) and bob_cycles >= 0.1 and bob_cycles <= 3
