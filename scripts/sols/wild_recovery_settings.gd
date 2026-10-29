class_name WildRecoverySettings
extends Resource
## Source-derived delayed replacement of depleted authored homes; no resurrection or off-line time.
## Active exploration ticks before a successor may appear (0.75 seconds each). Zero disables new waits.
## Already saved waits keep their deadline when this setting changes.
@export_range(0, 1000000) var interval_ticks := 2400
## Only admit successors this many cells from the player; distant due homes wait for a local visit.
@export_range(4, 32) var local_radius := 14

func valid() -> bool:
	return SolSpeciesDefinition.whole(interval_ticks, 0, 1000000) and SolSpeciesDefinition.whole(local_radius, 4, 32)
