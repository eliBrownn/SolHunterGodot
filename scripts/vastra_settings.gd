class_name VastraSettings
extends Resource
## Source development defaults, provisional tuning rather than canon.

## Active exploration ticks per overload-healing interval. One tick is 0.75 active seconds; pause/offline time does not count.
@export_range(1, 1000000) var recovery_interval_ticks := 120
## Overload points healed per interval. Zero disables healing; re-enabling uses retained elapsed debt. Also affects loaded worlds.
@export_range(0, 100) var recovery_points := 1
## Maximum explicit changed cells serviced per tick. Larger values reduce queue delay but cost more CPU. Also affects loaded worlds.
@export_range(1, 1024) var tiles_per_tick := 32

func parameters() -> Dictionary:
	return {"interval": recovery_interval_ticks, "points": recovery_points, "work_limit": tiles_per_tick}
