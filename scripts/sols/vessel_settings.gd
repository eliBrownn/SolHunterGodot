class_name VesselSettings
extends Resource
## Provisional, saved on first activation. Rendering never supplies ecological energy.
@export var enabled := true
@export_range(1, 16, 1) var group_limit := 9
@export_range(4, 120, 1) var signal_lifetime_ticks := 40
@export_range(1, 8, 1) var feed_per_tick := 2
@export_range(1, 8, 1) var response_cost := 1
@export_range(2, 30, 1) var response_ticks := 12
@export_range(4, 120, 1) var recovery_ticks := 30
@export_range(2, 60, 1) var blockage_ticks := 8
@export_range(100, 1000, 25) var stranded_energy := 300
@export_range(1, 10, 1) var escalation_overload := 1
@export_range(1, 100, 1) var storm_threshold := 80
## Keep production activation off while storm behavior/exposure is authored separately.
@export_range(0, 100, 1) var storm_chance_percent := 0
@export_range(2, 120, 1) var storm_ticks := 20

func parameters() -> Dictionary:
	return {"enabled": enabled, "group_limit": group_limit, "signal_lifetime_ticks": signal_lifetime_ticks,
		"feed_per_tick": feed_per_tick, "response_cost": response_cost, "response_ticks": response_ticks,
		"recovery_ticks": recovery_ticks, "blockage_ticks": blockage_ticks, "stranded_energy": stranded_energy,
		"escalation_overload": escalation_overload, "storm_threshold": storm_threshold,
		"storm_chance_percent": storm_chance_percent, "storm_ticks": storm_ticks}

static func valid_policy(p: Variant) -> bool:
	var names := ["enabled", "group_limit", "signal_lifetime_ticks", "feed_per_tick", "response_cost", "response_ticks", "recovery_ticks", "blockage_ticks", "stranded_energy", "escalation_overload", "storm_threshold", "storm_chance_percent", "storm_ticks"]
	if not p is Dictionary or not RecordShape.keys_match(p, names) or not p.enabled is bool: return false
	var limits := {"group_limit": [1, 16], "signal_lifetime_ticks": [4, 120], "feed_per_tick": [1, 8], "response_cost": [1, 8], "response_ticks": [2, 30], "recovery_ticks": [4, 120], "blockage_ticks": [2, 60], "stranded_energy": [100, 1000], "escalation_overload": [1, 10], "storm_threshold": [1, 100], "storm_chance_percent": [0, 100], "storm_ticks": [2, 120]}
	for key in limits:
		if not SolSpeciesDefinition.whole(p[key], limits[key][0], limits[key][1]): return false
	return true
