class_name OwnedCompanionSettings
extends Resource
## Live presentation/follow tuning. Ownership and selected identity remain in ExpeditionState.

## Show the selected owned party Sol while exploring.
@export var enabled := true
## Vertical space above the species' visual bounds for its caption, in cells. Applies live.
@export_range(0.05, 1.0, 0.05) var caption_clearance := 0.25
## Include routine Following/Resting text. Off keeps those captions short; blocked routes and species moments always explain themselves. Applies live.
@export var routine_captions := false
## First adjacent cell tried on selection/load, in world compass directions. Blocked cells fall back to other sides.
@export_enum("west", "east", "south", "north") var admission_side := "west"
## Stop this many Manhattan cells from the player.
@export_range(1, 3) var stop_distance := 1
## Resume following at this separation; must exceed Stop Distance.
@export_range(2, 6) var resume_distance := 2
## Seconds per legal cardinal step or stationary takeoff/landing transition. No offline catch-up or teleport recovery.
@export_range(0.1, 1.0, 0.05) var step_seconds := 0.2
## Maximum visited cells in each local path search.
@export_range(16, 512) var search_cells := 128
## Maximum Manhattan search radius from the companion's current cell.
@export_range(4, 32) var search_radius := 12
## Hide the model beyond this Euclidean distance, while retaining its legal local position.
@export_range(4, 32) var visible_radius := 24
## Stationary active seconds before a species idle interaction. Walking interrupts immediately.
@export_range(1.0, 30.0, 0.5) var rest_after_seconds := 4.0
## Active seconds showing the characteristic idle interaction.
@export_range(0.5, 4.0, 0.25) var moment_seconds := 1.5
## Uses the same inherited behavior definitions as wild ecology; only idle branches belong here.
@export var behavior_library: SolBehaviorLibrary = preload("res://resources/owned_companion_behaviors.tres")

func valid() -> bool:
	if not is_finite(caption_clearance) or caption_clearance < 0.05 or caption_clearance > 1.0:
		return false
	return admission_side in ["west", "east", "south", "north"] and SolSpeciesDefinition.whole(stop_distance, 1, 3) and SolSpeciesDefinition.whole(resume_distance, stop_distance + 1, 6) and is_finite(step_seconds) and step_seconds >= 0.1 and step_seconds <= 1.0 and SolSpeciesDefinition.whole(search_cells, 16, 512) and SolSpeciesDefinition.whole(search_radius, 4, 32) and SolSpeciesDefinition.whole(visible_radius, 4, 32) and is_finite(rest_after_seconds) and rest_after_seconds >= 1 and rest_after_seconds <= 30 and is_finite(moment_seconds) and moment_seconds >= 0.5 and moment_seconds <= 4 and behavior_library != null and behavior_library.valid()
