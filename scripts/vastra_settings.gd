class_name VastraSettings
extends Resource
## Source development defaults, provisional tuning rather than canon.

## Active exploration ticks per overload-healing interval. One tick is 0.75 active seconds; pause/offline time does not count.
@export_range(1, 1000000) var recovery_interval_ticks := 120
## Signed overload points returned toward zero per interval. Zero disables relaxation; retained debt survives. Applies to loaded worlds.
@export_range(0, 100) var recovery_points := 1
## Maximum explicit changed cells serviced per tick. Larger values reduce queue delay but cost more CPU. Also affects loaded worlds.
@export_range(1, 1024) var tiles_per_tick := 32
@export_group("Restorative Conditions (Provisional)")
## Maximum additional recovery rate for damaged habitat conditions and vacant Sol homes. Zero disables assistance.
@export_range(0.0, 4.0, 0.05) var restoration_max_bonus := 1.0
## Negative-overload magnitude giving half the maximum recovery bonus. Diminishing returns; points.
@export_range(1.0, 100.0, 1.0) var restoration_half_strength := 25.0
@export_group("Environmental Combat (Provisional)")
## Maximum outgoing damage bonus at concentration 100 on matching individual-affinity ground. Never changes permanent stats.
@export_range(0.0, 0.99, 0.01) var affinity_damage_bonus := 0.5
@export_group("Visible Currents")
## Cosmetic local current ribbons. Restart to change the pool; never generates ecological state.
@export var currents_enabled := true
## Maximum local ribbons. Bounded independently of world size; restart to apply.
@export_range(0, 64) var current_limit := 24
## Visibility radius in terrain cells. In-place edits apply within 0.5 seconds.
@export_range(4, 24) var current_radius := 14
## Ordinary current opacity. Rich and disturbed tiles strengthen it. Zero hides ribbons.
@export_range(0.0, 0.3, 0.01) var current_opacity := 0.07
## Screen-space refraction strength. Zero disables distortion while retaining luminous strands.
@export_range(0.0, 0.02, 0.001) var current_distortion := 0.003

func valid() -> bool:
	return VastraNatural.valid_policy(parameters()) and is_finite(restoration_max_bonus) and restoration_max_bonus >= 0 and restoration_max_bonus <= 4 and is_finite(restoration_half_strength) and restoration_half_strength >= 1 and restoration_half_strength <= 100 and is_finite(affinity_damage_bonus) and affinity_damage_bonus >= 0 and affinity_damage_bonus <= 0.99 and SolSpeciesDefinition.whole(current_limit, 0, 64) and SolSpeciesDefinition.whole(current_radius, 4, 24) and is_finite(current_opacity) and current_opacity >= 0 and current_opacity <= 0.3 and is_finite(current_distortion) and current_distortion >= 0 and current_distortion <= 0.02

func parameters() -> Dictionary:
	return {"interval": recovery_interval_ticks, "points": recovery_points, "work_limit": tiles_per_tick}
