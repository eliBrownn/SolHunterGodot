class_name EncounterSettings
extends Resource
## Prototype encounter entry/withdrawal tuning; no battle or capture formulas.

## Enable player-initiated encounter panels and warned hostile contact.
@export var enabled := true
## Allow the authored guarding Seedmote to confront the player after a displayed warning and later contact step.
@export var automatic_contact := true
## Manhattan range for the nonmodal hostile warning. Must cover Contact Distance.
@export_range(1, 6) var warning_distance := 3
## Maximum Manhattan distance for automatic contact on a later completed player step.
@export_range(0, 1) var contact_distance := 1
## Manhattan range for deliberate R approach; never selects owned or unavailable individuals.
@export_range(1, 6) var interaction_distance := 3
## Successful exploration steps protected from automatic contact after prototype withdrawal. Manual approach remains available.
@export_range(1, 8) var withdrawal_safe_steps := 3

func valid() -> bool:
	return SolSpeciesDefinition.whole(warning_distance, 1, 6) and SolSpeciesDefinition.whole(contact_distance, 0, 1) and warning_distance >= contact_distance and SolSpeciesDefinition.whole(interaction_distance, 1, 6) and SolSpeciesDefinition.whole(withdrawal_safe_steps, 1, 8)
