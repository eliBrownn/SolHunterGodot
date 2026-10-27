class_name VastraSettings
extends Resource
## Source development defaults, provisional tuning rather than canon.

@export_range(1, 1000000) var recovery_interval_ticks := 120
@export_range(0, 100) var recovery_points := 1
@export_range(1, 1024) var tiles_per_tick := 32

func parameters() -> Dictionary:
	return {"interval": recovery_interval_ticks, "points": recovery_points, "work_limit": tiles_per_tick}
