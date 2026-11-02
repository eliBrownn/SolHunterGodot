class_name CombatPacingFixture
extends Resource
## Development-only arena/loadout recipe. Never used by encounter generation.
class ProbeBattle extends TacticalBattle:
	# Phase-3 probes measure victory/exhaustion pacing. Synthetic opponents are not
	# persistent individuals and must not be captured into the disposable roster.
	func capture_chance() -> float:
		return 0.0

@export var fixture_id := "ordinary"
@export_range(1, 100) var fixture_version := 1
@export var hero: BattleProfile = preload("res://resources/starter_bramblepup.tres")
@export var opponent: BattleProfile = preload("res://resources/wild_seedmote.tres")
## Fixed individual class potency for repeatability; does not roll or modify owned individuals.
@export_range(1, 10) var hero_potency := 1
@export_range(1, 10) var opponent_potency := 1
@export var hero_moves := PackedStringArray(["strike", "mend"])
@export var opponent_moves := PackedStringArray(["vine_whip"])
## Offsets from the development arena origin; these are authored probe geometry, not world generation.
@export var blocked: Array[Vector2i] = []
@export var wet: Array[Vector2i] = []
@export var heat: Array[Vector2i] = []
@export var enemy_offset := Vector2i(2, 0)
@export var trainer_offset := Vector2i(-2, 0)
## Finite initial condition lifetime in tactical rounds.
@export_range(1, 20) var field_rounds := 4

func valid() -> bool:
	var library: MoveLibrary = preload("res://resources/move_library.tres")
	if hero == null or opponent == null or not hero.valid() or not opponent.valid() or fixture_id.is_empty() or fixture_version < 1 or fixture_version > 100 or field_rounds < 1 or field_rounds > 20:
		return false
	if enemy_offset == Vector2i.ZERO or absi(enemy_offset.x) > 4 or absi(enemy_offset.y) > 4 or blocked.has(enemy_offset): return false
	if trainer_offset == enemy_offset or absi(trainer_offset.x) > 4 or absi(trainer_offset.y) > 4 or blocked.has(trainer_offset): return false
	if hero_potency < 1 or hero_potency > 10 or opponent_potency < 1 or opponent_potency > 10: return false
	for group in [hero_moves, opponent_moves]:
		if group.is_empty() or group.size() > 4: return false
		for id in group:
			if library.find(id).is_empty(): return false
	for group in [blocked, wet, heat]:
		if group.size() > 81: return false
		for at: Vector2i in group:
			if absi(at.x) > 4 or absi(at.y) > 4: return false
	return true

func build(origin: Vector2i = Vector2i.ZERO) -> TacticalBattle:
	if not valid(): return null
	var settings: BattleSettings = preload("res://resources/battle_settings.tres")
	var battle := ProbeBattle.new()
	battle.bounds = Rect2i(origin - Vector2i(4, 4), Vector2i(9, 9))
	battle.ally = hero.snapshot()
	battle.enemy = opponent.snapshot()
	battle.ally_hp = hero.max_hp
	battle.enemy_hp = opponent.max_hp
	battle.enemy_cell = origin + enemy_offset
	battle.movement = settings.movement_points
	battle.remaining = battle.movement
	battle.action_points = settings.action_points
	battle.actions_remaining = battle.action_points
	battle.speed_per_movement_point = settings.speed_per_movement_point
	battle.release_range = settings.release_range
	battle.seal_action_points = settings.seal_action_points
	battle.fallback_action_points = settings.fallback_action_points
	battle.fallback_damage_percent = settings.fallback_damage_percent
	battle.fallback_reach = settings.fallback_reach
	battle.set_class_passives({"class_id": hero.class_id, "potency": hero_potency},
		{"class_id": opponent.class_id, "potency": opponent_potency}, settings.class_buffs)
	battle.ai_hazard_weight = settings.ai_hazard_weight
	battle.ai_heal_weight = settings.ai_heal_weight
	battle.ai_field_weight = settings.ai_field_weight
	var library: MoveLibrary = preload("res://resources/move_library.tres")
	battle.field_damage = library.field_damage
	battle.rough_cost = library.rough_cost
	battle.assisted_cost = library.assisted_cost
	battle.resisted_cost = library.resisted_cost
	for y in range(-4, 5):
		for x in range(-4, 5):
			var at := Vector2i(x, y)
			battle.cells[origin + at] = not blocked.has(at)
	for pair in [[wet, "wet"], [heat, "heat"]]:
		for at: Vector2i in pair[0]:
			battle.fields[origin + at] = {"kind": pair[1], "direction": Vector2i.RIGHT, "round": 0, "expires": field_rounds + 1}
	for id in hero_moves: battle.ally_moves.append(library.find(id))
	for id in opponent_moves: battle.enemy_moves.append(library.find(id))
	battle.commander_route = BattleCommander.plan(battle, origin + trainer_offset, func(_from: Vector2i, to: Vector2i) -> bool:
		return battle.bounds.grow(1).has_point(to) and (not battle.cells.has(to) or battle.passable(to)))
	if battle.commander_route.is_empty(): return null
	battle.trainer = battle.commander_route.back()
	battle.log.append("DEVELOPMENT PROBE · %s v%d · disposable expedition" % [fixture_id, fixture_version])
	return battle

func context(battle: TacticalBattle, tuning: SolVisualSettings, revision: String) -> Dictionary:
	return {"fixture": fixture_id, "fixture_version": fixture_version, "revision": revision,
		"fixture_sha256": FileAccess.get_sha256(resource_path), "seed": 17, "synthetic_geometry": true,
		"capture_enabled": false,
		"hero": battle.ally.duplicate(true), "opponent": battle.enemy.duplicate(true),
		"passive_units": battle.passives.units.duplicate(true),
		"hero_moves": battle.ally_moves.duplicate(true), "opponent_moves": battle.enemy_moves.duplicate(true),
		"blocked": blocked.map(func(at: Vector2i) -> String: return str(at)),
		"initial_fields": var_to_str(battle.fields), "trainer": str(battle.trainer),
		"trainer_start_offset": str(trainer_offset),
		"settings": {"movement": battle.movement, "release_range": battle.release_range,
			"action_points": battle.action_points, "speed_per_movement_point": battle.speed_per_movement_point,
			"field_damage": battle.field_damage, "rough_cost": battle.rough_cost,
			"assisted_cost": battle.assisted_cost, "resisted_cost": battle.resisted_cost,
			"ai_hazard_weight": battle.ai_hazard_weight, "ai_heal_weight": battle.ai_heal_weight,
			"ai_field_weight": battle.ai_field_weight, "action_seconds": tuning.action_cue_seconds,
			"consequence_seconds": tuning.consequence_seconds, "movement_seconds": tuning.movement_step_seconds,
			"handoff_seconds": tuning.turn_handoff_seconds}, "engine": Engine.get_version_info().string}
