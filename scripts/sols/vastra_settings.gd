class_name VastraSettings
extends Resource
const SOURCE_REGION_SIZE := FloraCatalog.REGION_SIZE
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
## Diagnostic ground overlay: actual concentration or concentration revealed by nature and cleared by Sols. Live within 0.5 seconds; not saved.
@export_enum("Normal", "Concentration heatmap", "Revealed field heatmap") var current_debug_view := 0
## Cosmetic connected current web. Restart to enable/disable; never generates ecological state.
@export var currents_enabled := true
## Maximum total web junctions, independent of world size. Live when initially enabled.
@export_range(0, 64) var current_limit := 24
## Maximum rendered geographic groups. Per-group node budget is fixed independently of visible group count.
@export_range(1, 8) var current_region_limit := 4
## Nearest living groups linked per group, in addition to the connected backbone. No cages within groves.
@export_range(1, 3) var current_web_links := 2
## Visibility carried through links between living regions; zero leaves only local nature support.
@export_range(0.0, 1.0, 0.05) var current_connection_visibility := 0.35
## Affinity-tinted translucent astral haze around the fine strands. Live within 0.5 seconds.
@export_range(0.0, 1.0, 0.05) var current_haze_strength := 0.4
## Ordinary current opacity. Rich and disturbed tiles strengthen it. Zero hides the web.
@export_range(0.0, 1.0, 0.01) var current_opacity := 0.25
## Screen-space refraction strength. Zero disables distortion while retaining luminous strands.
@export_range(0.0, 0.02, 0.001) var current_distortion := 0.003

## Reference size for shared-region padding and fine branch separation, in cells. Live edits rebuild within 0.5 seconds.
@export_range(2.0, 8.0, 0.25) var current_spacing := 3.5
## Wisp path envelope and relative bridge width, in terrain cells. Live within 0.5 seconds.
@export_range(0.1, 4.0, 0.05) var current_width := 2.4

## Typical vertical scale of shared living regions, in cells. Live geometry rebuild.
@export_range(0.2, 4.0, 0.1) var current_hover_height := 1.4
## Maximum source-to-source distance for joining nearby life into a shared visual region, in cells. Does not alter ecological concentration.
@export_range(1.0, 6.0, 0.25) var current_life_radius := 3.0
## Residual optical visibility with no nearby living source; fraction of ordinary strength.
@export_range(0.0, 0.2, 0.01) var current_empty_visibility := 0.03
## Gentle traveling pulse modulation; zero disables the pulse without disabling flow.
@export_range(0.0, 0.5, 0.05) var current_pulse_strength := 0.1
## Active seconds per gentle pulse cycle. Pause/offline time do not advance it.
@export_range(2.0, 20.0, 0.5) var current_pulse_seconds := 6.0

## Prevailing airflow vector in world X/Y/Z, relative speed units, magnitude at most 4. Live; gentle Y drift avoids a flat ground effect.
@export var current_wind_velocity := Vector3(0.7, 0.12, 0.25)
## Optical transport speed contribution. Concentration supplies inward direction; zero retains wind.
@export_range(0.0, 2.0, 0.05) var current_attraction := 0.8

## Smooth visual clearing around Sol bodies, in cells. This never consumes saved environmental concentration.
@export_range(0.5, 4.0, 0.1) var current_sol_dissipation_radius := 1.6

@export_group("Vastra Optical Surfaces (Provisional)")
## Fine web detail within broad folds; 0 is broad refraction only, 1 adds fine internal streaks. Live within 0.5 seconds.
@export_range(0.0, 1.0, 0.05) var current_fine_detail := 0.9
## Optical phase units per active second. Zero freezes evolution and transport. Live within 0.5 seconds.
@export_range(0.0, 2.0, 0.05) var current_flow_speed := 0.75
## Separation of the complementary color fringes, as a fraction of refraction strength. Zero disables chromatic separation.
@export_range(0.0, 1.0, 0.05) var current_aberration := 0.65
## Strength of sun-dependent highlights and sparse astral pinpoints on wisps. Zero disables glints. Live within 0.5 seconds.
@export_range(0.0, 1.0, 0.05) var current_glints := 0.15

@export_group("Current Motion and Particles")
## HDR brightness of strands and motes. Zero removes emission; live every frame.
@export_range(0.0, 8.0, 0.1) var current_emission_energy := 0.0
## Maximum pooled, shadowless lights following visible motes; zero disables scenery lighting. Live, capped at eight.
@export_range(0, 8, 1) var current_light_limit := 0
## Local scenery light energy before mote visibility and transition fades. Live every frame.
@export_range(0.0, 8.0, 0.1) var current_light_energy := 2.0
## Local scenery light radius in terrain cells. Live every frame; short ranges limit light leakage through scenery.
@export_range(0.25, 6.0, 0.25) var current_light_range := 2.5
## Irregular sideways wiggle amplitude as a fraction of ribbon width. Live within 0.5 seconds; zero retains the quiet base flow.
@export_range(0.0, 0.3, 0.01) var current_strand_shake := 0.18
## Maximum visible peak-following motes across the entire field. Zero disables the particle layer. Live, cosmetic only.
@export_range(0, 128, 1) var current_particle_limit := 0
## Typical luminous mote diameter in world cells. Live; motes fade at scenery intersections and around Sols.
@export_range(0.02, 0.2, 0.01) var current_particle_size := 0.09

## Maximum short grass-to-grass reach in cells. Rebuilds live; smaller strands follow the terrain with almost no arch.
@export_range(1.0, 5.0, 0.25) var current_ground_reach := 3.0
## Minimum ground clearance of small currents, in cells. Live geometry rebuild.
@export_range(0.03, 0.2, 0.01) var current_ground_clearance := 0.06
## Maximum rare treetop-to-treetop links in the entire visible field. Zero removes canopy arcs. Live geometry rebuild.
@export_range(0, 4, 1) var current_canopy_links := 2
## Canopy rise above the endpoint line as a fraction of travel distance; capped at six cells. Live rebuild.
@export_range(0.0, 0.4, 0.01) var current_canopy_arc := 0.18
## Stable per-transfer variation of tree contact height, sideways bend and arc shape. Zero restores ground/crown paths. Live within 0.5 seconds; cosmetic only.
@export_range(0.0, 1.0, 0.05) var current_path_variation := 1.0
## Growth of stream width and irregular wiggle amplitude with distance traveled. Zero keeps the original tight flow. Live within 0.5 seconds; cosmetic only.
@export_range(0.0, 2.0, 0.05) var current_flow_spread := 0.6
## Narrowing of visible filaments per ground-reach distance traveled. Longer paths taper more; zero disables distance taper. Live within 0.5 seconds.
@export_range(0.0, 4.0, 0.1) var current_distance_taper := 1.5

## Maximum reach multiplier at the canopy reference height. Live rebuild; 5 means top currents can reach roughly five times as far as grass currents.
@export_range(1.0, 8.0, 0.25) var current_height_range_multiplier := 5.0
## Height above local ground giving the full reach multiplier, in cells. Live rebuild; terrain elevation alone does not increase reach.
@export_range(1.0, 6.0, 0.25) var current_range_height := 3.0

@export_group("Plant Energy Circulation (Provisional)")
## Full reserve that emits one conserved packet. Captured per expedition; does not change ambient concentration or overload.
@export_range(1, 1000, 1) var plant_threshold := 100
## Units absorbed per active second at ambient concentration 100. Captured for new expeditions; balance remains provisional.
@export_range(0.0, 100.0, 0.25) var plant_refill_rate := 4.0
## Energy spent repairing one positive ecological-overload point locally. Negative restorative overload is retained.
@export_range(1.0, 1000.0, 1.0) var plant_repair_cost := 10.0
## Maximum overload points repaired per serviced plant per activity tick. Zero disables plant-assisted repair.
@export_range(0, 10, 1) var plant_repair_points := 1
## Packet travel speed in cells per active second, captured with the simulation policy. Camera/visual budgets never change arrival time.
@export_range(0.05, 4.0, 0.05) var plant_transfer_speed := 0.35
## Maximum source visits and arrivals per active tick; round-robin source service remains fair.
@export_range(1, 256, 1) var plant_work_limit := 64
## Geographic simulation radius around the player, in 12-cell regions. Independent of camera, zoom, foliage quality and visible strand count.
@export_range(0, 1, 1) var plant_active_radius := 1
## Maximum expelled root-stock units sent to nearby plants per active second. Saved for new expeditions.
@export_range(0.0, 100.0, 0.5) var plant_root_rate := 8.0
## Maximum excess Vastra eaten by each nearby field Sol per active second. Saved for new expeditions; no HP/XP bonus.
@export_range(0.0, 100.0, 0.5) var sol_feeding_rate := 4.0
## Root-stock feeding distance in terrain cells. Saved for new expeditions; independent of visibility.
@export_range(0.25, 8.0, 0.25) var sol_feeding_radius := 3.0

func plant_parameters() -> Dictionary:
	return {"threshold": plant_threshold, "refill": plant_refill_rate, "repair_cost": plant_repair_cost, "repair_points": plant_repair_points, "speed": plant_transfer_speed, "work_limit": plant_work_limit, "active_radius": plant_active_radius, "ground_reach": current_ground_reach, "tree_reach": current_ground_reach * current_height_range_multiplier, "root_rate": plant_root_rate, "feeding_rate": sol_feeding_rate, "feeding_radius": sol_feeding_radius}

func valid() -> bool:
	if not is_finite(current_distance_taper) or current_distance_taper < 0 or current_distance_taper > 4: return false
	if not is_finite(current_flow_spread) or current_flow_spread < 0.0 or current_flow_spread > 2.0:
		return false
	if not is_finite(current_path_variation) or current_path_variation < 0.0 or current_path_variation > 1.0:
		return false
	if not is_finite(current_emission_energy) or current_emission_energy < 0.0 or current_emission_energy > 8.0 or not SolSpeciesDefinition.whole(current_light_limit, 0, 8):
		return false
	if not is_finite(current_light_energy) or current_light_energy < 0.0 or current_light_energy > 8.0 or not is_finite(current_light_range) or current_light_range < 0.25 or current_light_range > 6.0:
		return false
	if not PlantVastra.valid_policy(plant_parameters()): return false
	if not is_finite(current_height_range_multiplier) or current_height_range_multiplier < 1 or current_height_range_multiplier > 8 or not is_finite(current_range_height) or current_range_height < 1 or current_range_height > 6:
		return false
	if not is_finite(current_ground_reach) or current_ground_reach < 1 or current_ground_reach > 5 or not is_finite(current_ground_clearance) or current_ground_clearance < 0.03 or current_ground_clearance > 0.2:
		return false
	if not SolSpeciesDefinition.whole(current_canopy_links, 0, 4) or not is_finite(current_canopy_arc) or current_canopy_arc < 0 or current_canopy_arc > 0.4:
		return false
	if not is_finite(current_strand_shake) or current_strand_shake < 0 or current_strand_shake > 0.3:
		return false
	if not SolSpeciesDefinition.whole(current_particle_limit, 0, 128) or not is_finite(current_particle_size) or current_particle_size < 0.02 or current_particle_size > 0.2:
		return false
	if not SolSpeciesDefinition.whole(current_web_links, 1, 3) or not is_finite(current_connection_visibility) or current_connection_visibility < 0 or current_connection_visibility > 1 or not is_finite(current_haze_strength) or current_haze_strength < 0 or current_haze_strength > 1:
		return false
	if not SolSpeciesDefinition.whole(current_debug_view, 0, 2):
		return false
	if not is_finite(current_sol_dissipation_radius) or current_sol_dissipation_radius < 0.5 or current_sol_dissipation_radius > 4:
		return false
	if not current_wind_velocity.is_finite() or current_wind_velocity.length() > 4 or not is_finite(current_attraction) or current_attraction < 0 or current_attraction > 2:
		return false
	if not is_finite(current_life_radius) or current_life_radius < 1 or current_life_radius > 6 or not is_finite(current_empty_visibility) or current_empty_visibility < 0 or current_empty_visibility > 0.2:
		return false
	if not is_finite(current_hover_height) or current_hover_height < 0.2 or current_hover_height > 4 or not is_finite(current_pulse_strength) or current_pulse_strength < 0 or current_pulse_strength > 0.5 or not is_finite(current_pulse_seconds) or current_pulse_seconds < 2 or current_pulse_seconds > 20:
		return false
	for value in [current_fine_detail, current_aberration, current_glints]:
		if not is_finite(value) or value < 0 or value > 1:
			return false
	if not is_finite(current_flow_speed) or current_flow_speed < 0 or current_flow_speed > 2:
		return false
	return is_finite(current_spacing) and current_spacing >= 2 and current_spacing <= 8 and is_finite(current_width) and current_width >= 0.1 and current_width <= 4.0 and VastraNatural.valid_policy(parameters()) and is_finite(restoration_max_bonus) and restoration_max_bonus >= 0 and restoration_max_bonus <= 4 and is_finite(restoration_half_strength) and restoration_half_strength >= 1 and restoration_half_strength <= 100 and is_finite(affinity_damage_bonus) and affinity_damage_bonus >= 0 and affinity_damage_bonus <= 0.99 and SolSpeciesDefinition.whole(current_limit, 0, 64) and SolSpeciesDefinition.whole(current_region_limit, 1, 8) and is_finite(current_opacity) and current_opacity >= 0 and current_opacity <= 1.0 and is_finite(current_distortion) and current_distortion >= 0 and current_distortion <= 0.02

func parameters() -> Dictionary:
	return {"interval": recovery_interval_ticks, "points": recovery_points, "work_limit": tiles_per_tick}
