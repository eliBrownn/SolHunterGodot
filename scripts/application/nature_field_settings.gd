class_name NatureFieldSettings
extends Resource
## Alpha field interactions; no trust, energy or automatic capture rewards.
@export var enabled := false
@export_range(1, 6, 1) var observation_distance := 3
## Sensitive listening reads visible posture without requiring a close approach.
@export_range(3, 8, 1) var listening_distance := 6
@export_range(0.25, 5.0, 0.05) var cooperation_seconds := 1.0
## Authored first capabilities. Individual affinity never selects these abilities.
@export var listening_species := PackedStringArray(["sol_species_0001"])
@export var inspection_species := PackedStringArray(["sol_species_0003"])
## Authored first-area lead positions, admitted against actual generated geography.
@export var sample_seed := 2601026
@export var sample_generation := 16
@export var grove_cell := Vector2i(0, 10)
@export var bank_cell := Vector2i(19, 30)

func valid() -> bool:
	return observation_distance >= 1 and observation_distance <= 6 and listening_distance >= 3 and listening_distance <= 8 and is_finite(cooperation_seconds) and cooperation_seconds >= 0.25 and cooperation_seconds <= 5.0 and sample_seed >= 0 and sample_seed <= 2147483646 and sample_generation >= 1 and absi(grove_cell.x) <= 1000000 and absi(grove_cell.y) <= 1000000 and absi(bank_cell.x) <= 1000000 and absi(bank_cell.y) <= 1000000
