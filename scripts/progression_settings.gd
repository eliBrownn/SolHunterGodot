class_name ProgressionSettings
extends Resource
## Source-derived base progression; no IV/EV system or evolution is inferred.
## Cumulative XP threshold is this factor times current level squared.
@export_range(1, 100) var threshold_factor := 10
## Fixed XP added to the defeated opponent's level contribution after participating victory.
@export_range(0, 100) var victory_base := 4
## XP per opponent level, added to Victory Base.
@export_range(0, 100) var xp_per_enemy_level := 3
## Lower bound on the participating victory reward, in XP.
@export_range(0, 100) var minimum_xp := 5
## Maximum future level. Lowering this never downgrades an existing individual.
@export_range(1, 55) var level_cap := 55
## Resolved base-stat growth per level; existing genetic modifiers are not invented.
@export_range(0, 10) var hp_growth := 2
@export_range(0, 10) var stat_growth := 1
## Owner-approved provisional milestones for additional prototype species moves.
@export var unlock_levels := PackedInt32Array([4, 8, 14])

func parameters() -> Dictionary:
	return {"threshold_factor": threshold_factor, "victory_base": victory_base, "xp_per_enemy_level": xp_per_enemy_level, "minimum_xp": minimum_xp, "level_cap": level_cap, "hp_growth": hp_growth, "stat_growth": stat_growth, "unlock_levels": Array(unlock_levels)}

func valid() -> bool:
	if hp_growth > 10 or stat_growth > 10:
		return false
	for value in [threshold_factor, victory_base, xp_per_enemy_level, minimum_xp, hp_growth, stat_growth]:
		if value < 0 or value > 100:
			return false
	return threshold_factor > 0 and level_cap >= 1 and level_cap <= 55 and unlock_levels.size() == 3 and unlock_levels[0] >= 1 and unlock_levels[0] < unlock_levels[1] and unlock_levels[1] < unlock_levels[2] and unlock_levels[2] <= 55
