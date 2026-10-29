class_name TacticalBattle
extends RefCounted
signal presentation_event(event: Dictionary)
signal resolution_event(event: Dictionary)
## Two-unit deterministic battle domain. Rendering, input and persistent outcomes live outside it.

var phase := "deployment"
var cells: Dictionary = {}
var bounds := Rect2i()
var trainer := Vector2i.ZERO
var ally_cell := Vector2i.ZERO
var enemy_cell := Vector2i.ZERO
var ally: Dictionary
var enemy: Dictionary
var ally_hp := 0
var enemy_hp := 0
var movement := 3
var remaining := 3
var action_points := 6
var actions_remaining := 6
var speed_per_movement_point := 10
var release_range := 3
var turn := "ally"
var round_number := 1
var queue: Array[String] = []
var log: Array[String] = []
var ally_moves: Array[Dictionary] = []
var enemy_moves: Array[Dictionary] = []
var fields: Dictionary = {}
var activity: Dictionary = {}
var last_activity: Array[String] = []
var affected: Dictionary = {}
var protected_cells: Dictionary = {}
var phasing := {"ally": false, "enemy": false}
var links: Dictionary = {}
var anchored := {"ally": 0, "enemy": 0}
var recovery_interval := 8
var field_damage := 2
var rough_cost := 2
var assisted_cost := 0
var resisted_cost := 2
var disrupted := {"ally": false, "enemy": false}
var quantum_mode := "position"
var participated := false
var capture_attempts := 0
var capture_seed := 0
var seal_power := 10
var seal_action_points := 4
var fallback_action_points := 4
var fallback_damage_percent := 40
var fallback_reach := 1
var ai_hazard_weight := 2.0
var ai_heal_weight := 0.25
var ai_field_weight := 2.0
var tile_affinities: Dictionary = {}
var tile_concentrations: Dictionary = {}
var tile_overloads: Dictionary = {}
var vastra_overloads: Dictionary = {}
var vastra_settings: VastraSettings = preload("res://resources/vastra_settings.tres")
var support_units: Array[Dictionary] = []
var statuses := {"ally": {}, "enemy": {}}
## Consumed charges are keyed by move identity, never by an interchangeable slot.
var move_uses := {"ally": {}, "enemy": {}}
var moved_this_turn := {"ally": false, "enemy": false}
var passive_guard := {"ally": false, "enemy": false}
var contributed := false
var passives: BattleClassPassives
## Live coordination advances one enemy activation after the preceding records are presented.
var automatic_enemies := true
var resolution_serial := 0
var action_serial := 0
var commander_route: Array[Vector2i] = []
const VIEW_PROPERTIES := ["phase", "cells", "bounds", "trainer", "ally_cell", "enemy_cell", "ally", "enemy", "ally_hp", "enemy_hp", "movement", "remaining", "release_range", "turn", "round_number", "log", "ally_moves", "enemy_moves", "fields", "activity", "last_activity", "statuses", "tile_affinities", "seal_power", "anchored", "phasing", "links", "disrupted"]

func view_snapshot() -> Dictionary:
	var result := {}
	for property in VIEW_PROPERTIES + ["fallback_action_points", "fallback_damage_percent", "fallback_reach", "move_uses", "moved_this_turn", "passive_guard", "action_points", "actions_remaining", "seal_action_points", "speed_per_movement_point", "tile_concentrations", "tile_overloads", "vastra_overloads", "vastra_settings"]:
		var value: Variant = get(property)
		result[property] = value.duplicate(true) if value is Dictionary or value is Array else value
	result.log = log.slice(maxi(0, log.size() - 30))
	result.passive_units = passives.units.duplicate(true)
	return result

func view_from(snapshot: Dictionary) -> TacticalBattle:
	var view := TacticalBattle.new()
	for property in VIEW_PROPERTIES + ["fallback_action_points", "fallback_damage_percent", "fallback_reach", "move_uses", "moved_this_turn", "passive_guard", "action_points", "actions_remaining", "seal_action_points", "speed_per_movement_point", "tile_concentrations", "tile_overloads", "vastra_overloads", "vastra_settings"]:
		var value: Variant = snapshot[property]
		view.set(property, value.duplicate(true) if value is Dictionary or value is Array else value)
	view.passives = BattleClassPassives.new(view, passives.settings)
	view.passives.units = snapshot.passive_units.duplicate(true)
	return view

func resolution(kind: String, side: String, caption: String, route: Array = [], cue: Dictionary = {}, snapshot: Dictionary = {}, actor_override: String = "@default", cause: String = "", affected_cells: Array = []) -> void:
	if not resolution_event.has_connections():
		return
	resolution_serial += 1
	resolution_event.emit({"sequence": resolution_serial, "action": action_serial, "kind": kind,
		"side": side, "actor": (turn if kind == "effect" else side) if actor_override == "@default" else actor_override,
		"caption": caption, "cause": cause, "affected_cells": affected_cells.duplicate(), "route": route.duplicate(), "cue": cue.duplicate(true),
		"snapshot": view_snapshot() if snapshot.is_empty() else snapshot.duplicate(true)})

func consequence(side: String, caption: String, cause: String, affected_cells: Array = [], actor_side: String = "") -> void:
	resolution("consequence", side, caption, [], {}, {}, actor_side, cause, affected_cells)

func outcome_record() -> void:
	if phase in ["victory", "exhaustion", "captured"]:
		var captions := {"victory": "%s is exhausted · Victory" % str(enemy.display_name),
			"exhaustion": "%s is exhausted · Return to refuge" % str(ally.display_name),
			"captured": "%s was sealed" % str(enemy.display_name)}
		resolution("outcome", "", captions[phase], [], {}, {}, "", phase)

func announce(side: String, caption: String) -> void:
	action_serial += 1
	resolution("action", side, caption)

func movement_records(side: String, route: Array) -> void:
	if not resolution_event.has_connections():
		return
	for at: Vector2i in route:
		var snapshot := view_snapshot()
		snapshot[side + "_cell"] = at
		resolution("movement", side, "%s moves" % str((ally if side == "ally" else enemy).display_name), route, {}, snapshot)

func _init() -> void:
	passives = BattleClassPassives.new(self, preload("res://resources/class_buff_settings.tres"))

func set_class_passives(hero: Dictionary, opponent: Dictionary, tuning: ClassBuffSettings) -> void:
	if phase != "deployment" or tuning == null or not tuning.valid():
		return
	passives = BattleClassPassives.new(self, tuning.duplicate(true) as ClassBuffSettings)
	passives.admit("ally", hero)
	passives.admit("enemy", opponent)



static func prepare(terrain: WorldTerrain, origin: Vector2i, target: Vector2i, hero: Dictionary, hero_hp: int, opponent: Dictionary, settings: BattleSettings, outside_commander: bool = false) -> TacticalBattle:
	if not settings.valid() or not BattleProfile.valid_snapshot(hero) or not BattleProfile.valid_snapshot(opponent) or hero_hp <= 0 or hero_hp > hero.max_hp or origin == target:
		return null
	var battle := TacticalBattle.new()
	battle.trainer = origin
	battle.enemy_cell = target
	battle.ally = BattleProfile.normalized(hero)
	battle.enemy = BattleProfile.normalized(opponent)
	battle.ally_hp = hero_hp
	battle.enemy_hp = int(opponent.max_hp)
	battle.movement = settings.movement_points
	battle.remaining = battle.movement
	battle.action_points = settings.action_points
	battle.actions_remaining = battle.action_points
	battle.speed_per_movement_point = settings.speed_per_movement_point
	battle.release_range = settings.release_range
	battle.seal_power = settings.seal_power
	battle.seal_action_points = settings.seal_action_points
	battle.fallback_action_points = settings.fallback_action_points
	battle.fallback_damage_percent = settings.fallback_damage_percent
	battle.fallback_reach = settings.fallback_reach
	battle.ai_hazard_weight = settings.ai_hazard_weight
	battle.ai_heal_weight = settings.ai_heal_weight
	battle.ai_field_weight = settings.ai_field_weight
	var radius := settings.arena_radius
	battle.bounds = Rect2i(origin - Vector2i(radius, radius), Vector2i.ONE * (2 * radius + 1))
	for y in range(battle.bounds.position.y, battle.bounds.end.y):
		for x in range(battle.bounds.position.x, battle.bounds.end.x):
			var at := Vector2i(x, y)
			battle.cells[at] = absi(at.x) <= 1000000 and absi(at.y) <= 1000000 and terrain.fits(at)
			battle.protected_cells[at] = terrain.sample(at).obstacle == 3
	if not battle.cells.get(target, false) or (not outside_commander and battle.deployment_tiles().is_empty()):
		return null
	battle.log.append("Choose a blue tile to release " + str(hero.display_name) + ".")
	return battle

static func distance(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)

func paths(start: Vector2i, budget: int, blocked: Vector2i, phase_crossing: bool = false, side: String = "", command_origin: Vector2i = Vector2i(2000000, 2000000)) -> Dictionary:
	var occupied_trainer := trainer if command_origin == Vector2i(2000000, 2000000) else command_origin
	var result := {start: []}
	var costs := {start: 0}
	var pending: Array[Vector2i] = [start]
	var cursor := 0
	while cursor < pending.size():
		var current := pending[cursor]
		cursor += 1
		for direction in [Vector2i.UP, Vector2i.LEFT, Vector2i.RIGHT, Vector2i.DOWN]:
			var next: Vector2i = current + direction
			var crossed := false
			if phase_crossing and cells.has(next) and not passable(next) and not protected_cells.get(next, false):
				next += direction
				crossed = true
			if next == occupied_trainer or next == blocked or not passable(next):
				continue
			var cost: int = int(costs[current]) + (2 if crossed else step_cost(current, next, side))
			if cost > budget or (costs.has(next) and cost >= int(costs[next])):
				continue
			var path: Array = result[current].duplicate()
			path.append(next)
			result[next] = path
			costs[next] = cost
			pending.append(next)
	return result

func step_cost(from: Vector2i, to: Vector2i, side: String = "") -> int:
	var field: Dictionary = fields.get(to, {})
	var kind: String = field.get("kind", "")
	if kind == "rough":
		return 1 if passives.has_class(side, "earthbound") else rough_cost
	if kind == "warp":
		return assisted_cost if from.x == to.x else resisted_cost
	if kind in ["wet", "wind"]:
		var direction: Vector2i = field.get("direction", Vector2i.RIGHT)
		var delta := to - from
		var dot := delta.x * direction.x + delta.y * direction.y
		return assisted_cost if dot > 0 else (resisted_cost if dot < 0 else 1)
	return 1

func route_cost(start: Vector2i, path: Array, side: String = "") -> int:
	var cost := 0
	for cell: Vector2i in path:
		cost += 2 if distance(start, cell) > 1 else step_cost(start, cell, side)
		start = cell
	return cost

func deployment_tiles() -> Array[Vector2i]:
	return deployment_from(trainer)

func deployment_from(origin: Vector2i) -> Array[Vector2i]:
	var output: Array[Vector2i] = []
	var connected := paths(enemy_cell, cells.size(), Vector2i(2000000, 2000000), false, "", origin)
	for cell: Vector2i in connected:
		if cell != enemy_cell and cell != origin and distance(cell, origin) <= release_range:
			output.append(cell)
	output.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		var da := distance(a, origin)
		var db := distance(b, origin)
		if da != db:
			return da < db
		if (a.x == origin.x) != (b.x == origin.x):
			return a.x != origin.x # Default cursor avoids hiding a short sprite behind the trainer.
		return a.y < b.y if a.y != b.y else a.x < b.x)
	return output

func deploy(cell: Vector2i) -> bool:
	if phase != "deployment" or not deployment_tiles().has(cell):
		return false
	ally_cell = cell
	phase = "active"
	announce("ally", "%s released" % str(ally.display_name))
	start_round()
	log.append(str(ally.display_name) + " released. Fastest Sol acts first.")
	auto_enemy()
	return true

func start_round() -> void:
	tick_fields()
	for side in ["ally", "enemy"]:
		if int(anchored[side]) == round_number - 1 and int(anchored[side]) > 0:
			consequence(side, "Stable Footing expired", "anchor_expiry", [unit_cell(side)])
	queue.assign(["ally", "enemy"] if effective_stat("ally", "speed") >= effective_stat("enemy", "speed") else ["enemy", "ally"])
	turn = queue[0]
	actions_remaining = action_points
	moved_this_turn[turn] = false
	remaining = movement_allowance(turn)
	disrupted[turn] = false
	passives.begin_turn(turn)
	if phase == "active":
		resolution("turn", turn, "%s's turn" % str((ally if turn == "ally" else enemy).display_name))

func finish_turn() -> void:
	tick_statuses(turn)
	passives.end_turn(turn)
	end_move_passives(turn)
	if ally_hp <= 0 or enemy_hp <= 0:
		phase = "exhaustion" if ally_hp <= 0 else "victory"
		return
	queue.pop_front()
	if queue.is_empty():
		round_number += 1
		start_round()
	else:
		turn = queue[0]
		actions_remaining = action_points
		moved_this_turn[turn] = false
		remaining = movement_allowance(turn)
		disrupted[turn] = false
		passives.begin_turn(turn)
		resolution("turn", turn, "%s's turn" % str((ally if turn == "ally" else enemy).display_name))

func reachable() -> Dictionary:
	return paths(ally_cell, remaining + actions_remaining, enemy_cell, phasing.ally or fields.get(ally_cell, {}).get("kind") == "phase", "ally") if phase == "active" and turn == "ally" else {}

func movement_allowance(side: String) -> int:
	return maxi(0, mini(movement, int(effective_stat(side, "speed") / speed_per_movement_point)) + passives.move_bonus(side) - (1 if disrupted[side] else 0))

func spend_movement(cost: int) -> void:
	var free := mini(remaining, cost)
	remaining -= free
	actions_remaining -= cost - free

func move_ally(cell: Vector2i) -> bool:
	var options := reachable()
	if not options.has(cell) or options[cell].is_empty():
		return false
	announce("ally", "%s moves" % str(ally.display_name))
	spend_movement(route_cost(ally_cell, options[cell], "ally"))
	mark_movement("ally", options[cell].size())
	phasing.ally = false
	ally_cell = cell
	participated = true
	movement_records("ally", options[cell])
	return true

func in_range(from: Vector2i, target: Vector2i, reach: int) -> bool:
	if distance(from, target) > reach:
		return false
	var steps := maxi(absi(target.x - from.x), absi(target.y - from.y))
	var previous := from
	for index in range(1, steps + 1):
		var t := float(index) / steps
		var cell := Vector2i(roundi(lerpf(from.x, target.x, t)), roundi(lerpf(from.y, target.y, t)))
		if not passable(cell) or cell == trainer:
			return false
		if cell.x != previous.x and cell.y != previous.y and (not cells.get(Vector2i(cell.x, previous.y), false) or not cells.get(Vector2i(previous.x, cell.y), false)):
			return false
		if cell != target and fields.get(cell, {}).get("kind") == "heat":
			return false # Smoke obscures shots passing through the heated area.
		previous = cell
	return true

static func damage(source: Dictionary, target: Dictionary) -> int:
	return maxi(1, int(source.attack) + int(source.move_power) - int(target.defense))

func can_attack() -> bool:
	var moves := moves_for("ally")
	for slot in range(moves.size()):
		if moves[slot].effect == "damage" and can_use(slot, enemy_cell):
			return true
	return false

func attack() -> bool:
	var moves := moves_for("ally")
	for slot in range(moves.size()):
		if moves[slot].effect == "damage" and can_use(slot, enemy_cell):
			return use_move(slot, enemy_cell)
	return false

func wait_turn() -> bool:
	if phase != "active" or turn != "ally":
		return false
	participated = true
	announce("ally", "%s holds position" % str(ally.display_name))
	log.append("You hold position and end the turn.")
	finish_turn()
	auto_enemy()
	return true

func enemy_plan() -> Vector2i:
	return plan_enemy().cell

func enemy_intent() -> String:
	if phase == "deployment":
		return "Enemy waits for deployment."
	var plan := plan_enemy()
	if int(plan.slot) < 0:
		return str(enemy.display_name) + ": seek safer attack range."
	var move: Dictionary = moves_for("enemy")[plan.slot]
	return "%s: %s%s." % [enemy.display_name, "reposition, then " if plan.cell != enemy_cell else "", move.name]

func enemy_attack_move() -> Dictionary:
	for move in moves_for("enemy"):
		if move.effect == "damage":
			return move
	return moves_for("enemy")[0]

func auto_enemy() -> void:
	if not automatic_enemies:
		return
	# At most two consecutive enemy activations across a speed-order change, with
	# one positive-cost move per point plus an explicit finish for each activation.
	for iteration in range(2 * (action_points + 1)):
		if not advance_enemy():
			return

func advance_enemy() -> bool:
	if phase != "active" or turn != "enemy":
		return false
	var plan := plan_enemy()
	if plan.cell != enemy_cell:
		# Execute the route admitted by this plan. Action presentation may ask for
		# fresh intent snapshots; do not recompute a different route after announcing.
		var route: Array = plan.route
		announce("enemy", "%s repositions" % str(enemy.display_name))
		spend_movement(route_cost(enemy_cell, route, "enemy"))
		mark_movement("enemy", int(plan.get("tiles", distance(enemy_cell, plan.cell))))
		enemy_cell = plan.cell
		phasing.enemy = false
		movement_records("enemy", route)
	if int(plan.slot) < 0 or not execute_move("enemy", int(plan.slot), plan.target):
		announce("enemy", "%s holds position" % str(enemy.display_name))
		log.append(str(enemy.display_name) + " approaches and waits.")
		finish_turn()
	return true

func moves_for(side: String) -> Array[Dictionary]:
	var moves: Array[Dictionary] = ally_moves if side == "ally" else enemy_moves
	if not moves.is_empty():
		for move in moves:
			if move.effect == "damage" and uses_left(side, move) > 0:
				return moves
		var result: Array[Dictionary] = moves.duplicate()
		result.append(last_effort())
		return result
	var profile: Dictionary = ally if side == "ally" else enemy
	var fallback: Array[Dictionary] = [{"id": "legacy_basic", "name": profile.move_name, "affinity": AffinityImprint.canonical(profile.affinity), "effect": "damage", "power": profile.move_power, "reach": profile.move_range, "duration": 1}]
	if uses_left(side, fallback[0]) <= 0:
		fallback.assign([last_effort()])
	return fallback

func last_effort() -> Dictionary:
	return {"id": "last_effort", "name": "Last Effort", "affinity": "earth", "effect": "damage", "power": 0, "reach": fallback_reach, "duration": 1, "action_points": fallback_action_points, "damage_percent": fallback_damage_percent, "vastra_powered": false,
		"description": "Weak physical fallback when no equipped damaging move has uses left. No affinity imprint; does not occupy a loadout slot."}

func uses_left(side: String, move: Dictionary) -> int:
	return 1 if move.id == "last_effort" else maxi(0, SolMove.uses(move) - int(move_uses[side].get(move.id, 0)))

func spend_use(side: String, move: Dictionary) -> void:
	if move.id != "last_effort":
		move_uses[side][move.id] = int(move_uses[side].get(move.id, 0)) + 1

func mark_movement(side: String, tiles: int) -> void:
	passives.moved(side, tiles)
	if tiles > 0:
		moved_this_turn[side] = true
		passive_guard[side] = false

func guard_slot(side: String) -> int:
	if not passive_guard[side]:
		return -1
	var moves: Array[Dictionary] = ally_moves if side == "ally" else enemy_moves
	for slot in range(moves.size()):
		var move: Dictionary = moves[slot]
		if move.effect == "passive" and move.get("passive_kind") == "guard" and uses_left(side, move) > 0:
			return slot
	return -1

func end_move_passives(side: String) -> void:
	if unit_hp(side) <= 0 or moved_this_turn[side]:
		return
	var moves: Array[Dictionary] = ally_moves if side == "ally" else enemy_moves
	for move in moves:
		if move.effect != "passive" or uses_left(side, move) <= 0:
			continue
		if move.passive_kind == "guard":
			if not passive_guard[side]:
				passive_guard[side] = true
				consequence(side, "%s · next direct hit guarded" % move.name, "equipped_passive", [unit_cell(side)], side)
		elif move.passive_kind == "renewal":
			var profile: Dictionary = ally if side == "ally" else enemy
			var amount := mini(int(move.power), int(profile.max_hp) - unit_hp(side))
			if amount > 0:
				spend_use(side, move)
				set_unit_hp(side, unit_hp(side) + amount)
				feedback("heal", unit_cell(side), amount, move.affinity, move.name, "equipped_passive", side)
				if side == "ally":
					contributed = true

func unit_cell(side: String) -> Vector2i:
	return ally_cell if side == "ally" else enemy_cell

func set_unit_cell(side: String, cell: Vector2i) -> void:
	if side == "ally":
		ally_cell = cell
	else:
		enemy_cell = cell

func unit_hp(side: String) -> int:
	return ally_hp if side == "ally" else enemy_hp

func set_unit_hp(side: String, hp: int) -> void:
	if side == "ally":
		ally_hp = hp
	else:
		enemy_hp = hp

func field_area(target: Vector2i) -> Array[Vector2i]:
	var area: Array[Vector2i] = [target]
	for direction in [Vector2i.UP, Vector2i.LEFT, Vector2i.RIGHT, Vector2i.DOWN]:
		var next: Vector2i = target + direction
		if cells.get(next, false) and next != trainer:
			area.append(next)
	return area

func hazard_cost(cell: Vector2i) -> float:
	var kind: String = fields.get(cell, {}).get("kind", "")
	if kind in ["heat", "charge"]:
		return float(field_damage) * ai_hazard_weight * (3.0 if enemy_hp <= field_damage else 1.0)
	if kind == "wet":
		for field in fields.values():
			if field.kind == "charge":
				return float(field_damage)
	return 0.0

func plan_enemy() -> Dictionary:
	var free_movement := remaining if turn == "enemy" else movement_allowance("enemy")
	var ap := actions_remaining if turn == "enemy" else action_points
	var budget := free_movement + ap
	var options := paths(enemy_cell, budget, ally_cell, phasing.enemy or fields.get(enemy_cell, {}).get("kind") == "phase", "enemy")
	var moves := moves_for("enemy")
	var best := {"cell": enemy_cell, "slot": -1, "target": ally_cell, "score": -INF, "cost": 0, "tiles": 0, "route": []}
	var positions: Array = options.keys()
	positions.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.y < b.y if a.y != b.y else a.x < b.x)
	for origin: Vector2i in positions:
		var cost := route_cost(enemy_cell, options[origin], "enemy")
		var targets: Array[Vector2i] = [ally_cell, origin]
		for direction in [Vector2i.UP, Vector2i.LEFT, Vector2i.RIGHT, Vector2i.DOWN]:
			for anchor in [ally_cell, origin]:
				var target: Vector2i = anchor + direction
				if cells.has(target) and not targets.has(target):
					targets.append(target)
		for slot in range(moves.size()):
			var move: Dictionary = moves[slot]
			if SolMove.cost(move) + maxi(0, cost - free_movement) > ap:
				continue
			for target in targets:
				if not can_use_for("enemy", slot, target, origin):
					continue
				var benefit := action_benefit(move, origin, target, options[origin].size())
				if benefit <= 0:
					continue
				var score := benefit - hazard_cost(origin)
				if score > best.score or (is_equal_approx(score, best.score) and cost < best.cost):
					best = {"cell": origin, "slot": slot, "target": target, "score": score, "cost": cost, "tiles": options[origin].size(), "route": options[origin].duplicate()}
	if best.slot >= 0:
		return best
	# Seek a legal offensive range by a complete bounded route. Manhattan descent can
	# stop forever at a wall even when a short detour exists. Unreachable foes wait.
	var approach := approach_route("enemy")
	for at: Vector2i in approach:
		if options.has(at):
			best.cell = at
			best.tiles = options[at].size()
			best.route = options[at].duplicate()
	return best

func approach_route(side: String) -> Array:
	var other := "enemy" if side == "ally" else "ally"
	var origin := unit_cell(side)
	var routes := paths(origin, cells.size() * maxi(rough_cost, resisted_cost) * 2,
		unit_cell(other), phasing[side] or fields.get(origin, {}).get("kind") == "phase", side)
	var best: Array = []
	var score := INF
	var positions: Array = routes.keys()
	positions.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.y < b.y if a.y != b.y else a.x < b.x)
	for at: Vector2i in positions:
		for slot in range(moves_for(side).size()):
			var move: Dictionary = moves_for(side)[slot]
			if move.effect not in ["damage", "poison", "debuff"] or not can_use_for(side, slot, unit_cell(other), at): continue
			var cost := float(route_cost(origin, routes[at], side))
			if side == "enemy": cost += hazard_cost(at)
			if cost < score:
				score = cost
				best = routes[at]
	return best.duplicate()

func action_benefit(move: Dictionary, origin: Vector2i, target: Vector2i, moved_tiles: int = 0) -> float:
	if move.effect == "damage":
		var amount := mini(ally_hp, damage_for("enemy", move, origin, moved_tiles))
		return float(amount) + (100.0 if amount >= ally_hp else 0.0)
	if move.effect in ["buff", "protect"]:
		return 1.0 if not statuses.enemy.has(status_key(move)) else 0.0
	if move.effect in ["debuff", "poison"]:
		return 2.0 if not statuses.ally.has(status_key(move)) else 0.0
	if move.effect == "heal":
		return mini(int(enemy.max_hp) - enemy_hp, int(move.power)) * ai_heal_weight
	if move.effect == "anchor":
		return 2.0 if fields.get(origin, {}).get("kind") == "wind" else 0.0
	if move.effect == "phase":
		return 1.0 if distance(origin, ally_cell) <= 3 else 0.0
	if move.effect == "quantum":
		return maxf(0.0, distance(origin, ally_cell) - distance(target, ally_cell) - hazard_cost(target) - 1)
	var area := field_area(target)
	var kind: String = {"fire": "heat", "water": "wet", "earth": "rough", "air": "wind", "lightning": "charge", "void": "warp", "spectral": "phase", "quantum": "entangled"}.get(move.affinity, "rough")
	var changed := false
	for at in area:
		changed = changed or fields.get(at, {}).get("kind") != kind
	if not changed or not area.has(ally_cell):
		return 0.0
	var benefit := ai_field_weight * (1.5 if kind in ["heat", "charge"] else 1.0)
	if area.has(origin) and kind in ["heat", "charge", "rough"]:
		benefit -= 4.0
	return benefit

func retreat() -> bool:
	if phase not in ["deployment", "active"]:
		return false
	phase = "retreat"
	log.append("Retreated safely.")
	resolution("outcome", "ally", "Retreated safely")
	return true

func set_movebooks(hero_book: Dictionary, foe_book: Dictionary) -> void:
	ally_moves.clear()
	enemy_moves.clear()
	for id in hero_book.equipped:
		ally_moves.append(hero_book.learned[id].duplicate(true))
	for id in foe_book.equipped:
		enemy_moves.append(foe_book.learned[id].duplicate(true))

func record_move(move: Dictionary, tiles: Array, with_feedback: bool = true) -> void:
	var affinity: String = move.affinity
	activity[affinity] = int(activity.get(affinity, 0)) + 1
	last_activity.append(affinity)
	for cell: Vector2i in tiles:
		affected[cell] = true
	var delta := VastraCombat.move_delta(move)
	var changed: Array = []
	var seen := {}
	for cell: Vector2i in tiles:
		if delta == 0 or seen.has(cell):
			continue
		seen[cell] = true
		var previous := int(tile_overloads.get(cell, 0))
		var value := clampi(previous + delta, VastraCombat.MIN_OVERLOAD, VastraCombat.MAX_OVERLOAD)
		if value != previous:
			tile_overloads[cell] = value
			vastra_overloads[AffinityImprint.key(cell)] = value
			changed.append(cell)
	if not changed.is_empty():
		consequence("", "Vastra %s · %d affected tiles" % ["restored" if delta < 0 else "overload increased", changed.size()], "vastra_restoration" if delta < 0 else "vastra_overload", changed, turn)
	if with_feedback and move.effect not in ["damage", "heal"] and not tiles.is_empty():
		feedback("field", tiles[0], 0, affinity, move.name)

func winner() -> String:
	var highest := 0
	for count in activity.values():
		highest = maxi(highest, int(count))
	for index in range(last_activity.size() - 1, -1, -1):
		if activity[last_activity[index]] == highest:
			return last_activity[index]
	return ""

func imprint() -> Dictionary:
	if activity.is_empty():
		return {}
	var tiles: Array = []
	var effects := {}
	for cell: Vector2i in affected:
		var at := AffinityImprint.key(cell)
		tiles.append(at)
		if fields.has(cell):
			var field: Dictionary = fields[cell]
			var direction: Vector2i = field.direction
			effects[at] = {"kind": field.kind, "direction": [direction.x, direction.y]}
	return {"winner": winner(), "tiles": tiles, "fields": effects, "interval": recovery_interval}

func can_use(slot: int, target: Vector2i) -> bool:
	return turn == "ally" and can_use_for("ally", slot, target, ally_cell)

func can_use_for(side: String, slot: int, target: Vector2i, origin: Vector2i) -> bool:
	# Ordinary slots need no fallback-array allocation or repeated full-loadout scan.
	var moves: Array[Dictionary] = ally_moves if side == "ally" else enemy_moves
	if moves.is_empty() or slot >= moves.size():
		moves = moves_for(side)
	if phase != "active" or slot < 0 or slot >= moves.size():
		return false
	var move: Dictionary = moves[slot]
	if move.effect == "passive" or uses_left(side, move) <= 0:
		return false
	# Off-turn intent previews use a fresh budget, never the other actor's leftovers.
	var budget := actions_remaining if turn == side else action_points
	if SolMove.cost(move) < 1 or SolMove.cost(move) > budget:
		return false
	var profile: Dictionary = ally if side == "ally" else enemy
	var other := "enemy" if side == "ally" else "ally"
	if move.effect == "heal":
		return target == origin and ((unit_hp(side) < int(profile.max_hp) and int(move.power) > 0) or (VastraCombat.move_delta(move) < 0 and int(tile_overloads.get(target, 0)) > VastraCombat.MIN_OVERLOAD) or secondary_useful(side, move))
	if move.effect in ["buff", "protect", "debuff", "poison"]:
		var recipient := side if move.effect in ["buff", "protect"] else other
		if target != (origin if recipient == side else unit_cell(other)) or int(move.power) <= 0:
			return false
		if recipient != side and not in_range(origin, target, int(move.reach)):
			return false
		var old: Dictionary = statuses[recipient].get(status_key(move), {})
		var turns := int(move.duration) + (passives.potency(side) if move.effect == "buff" and passives.has_class(side, "feyborn") else 0)
		return old.is_empty() or float(old.magnitude) < status_magnitude(recipient, move) or int(old.turns) < turns
	if move.effect == "phase":
		return target == origin and not phasing[side]
	if move.effect == "anchor":
		return target == origin and int(anchored[side]) < round_number
	if not passable(target) or target == trainer or distance(origin, target) > int(move.reach):
		return false
	if move.effect == "damage":
		return target == unit_cell(other) and in_range(origin, target, int(move.reach))
	if move.effect == "quantum":
		var mode := quantum_mode if side == "ally" else "position"
		if mode == "stabilize":
			return fields.has(target)
		return target != origin and target != unit_cell(other)
	if move.effect == "field":
		if not in_range(origin, target, int(move.reach)):
			return false
		var kind := field_kind(move)
		var tiles := field_tiles(move, origin, target)
		for at: Vector2i in tiles:
			var field := {"kind": "barrier" if kind == "rough" and at == target and at != ally_cell and at != enemy_cell else kind,
				"direction": field_direction(origin, target), "round": round_number, "expires": round_number + int(move.duration)}
			if fields.get(at) != field:
				return true
		if kind == "wind":
			for pushed_side in ["ally", "enemy"]:
				var position := unit_cell(pushed_side)
				var landing := position + field_direction(origin, target)
				if int(anchored[pushed_side]) < round_number and tiles.has(position) and passable(landing) and landing != trainer and landing != ally_cell and landing != enemy_cell:
					return true
		return false
	return in_range(origin, target, int(move.reach))

func field_kind(move: Dictionary) -> String:
	return {"fire": "heat", "water": "wet", "earth": "rough", "air": "wind", "lightning": "charge", "void": "warp", "spectral": "phase", "quantum": "entangled"}.get(move.affinity, "rough")

func field_direction(origin: Vector2i, target: Vector2i) -> Vector2i:
	var direction := target - origin
	direction = Vector2i(signi(direction.x), 0) if absi(direction.x) >= absi(direction.y) else Vector2i(0, signi(direction.y))
	return Vector2i.RIGHT if direction == Vector2i.ZERO else direction

func field_tiles(move: Dictionary, origin: Vector2i, target: Vector2i) -> Array:
	if move.affinity == "quantum":
		return [origin, target]
	var tiles: Array = [target]
	for step in [Vector2i.UP, Vector2i.LEFT, Vector2i.RIGHT, Vector2i.DOWN]:
		var at: Vector2i = target + step
		if cells.get(at, false) and at != trainer:
			tiles.append(at)
	if links.has(target) and not tiles.has(links[target]):
		tiles.append(links[target])
	return tiles

func use_move(slot: int, target: Vector2i) -> bool:
	return execute_move("ally", slot, target)

func secondary_useful(side: String, move: Dictionary) -> bool:
	if move.get("secondary_effect", "none") not in ["buff", "protect"]:
		return false
	var extra := move.duplicate()
	extra.effect = move.secondary_effect
	extra.power = move.get("secondary_power", 0)
	var previous: Dictionary = statuses[side].get(status_key(extra), {})
	var magnitude := status_magnitude(side, extra)
	var lifetime := int(move.duration) + 1 + (passives.potency(side) if extra.effect == "buff" and passives.has_class(side, "feyborn") else 0)
	return previous.is_empty() or float(previous.magnitude) < magnitude or (is_equal_approx(float(previous.magnitude), magnitude) and int(previous.turns) < lifetime)

func apply_secondary(side: String, move: Dictionary, origin: Vector2i, target: Vector2i, tiles: Array) -> void:
	var effect: String = move.get("secondary_effect", "none")
	if effect == "none":
		return
	var other := "enemy" if side == "ally" else "ally"
	if effect == "field":
		fields[target] = {"kind": field_kind(move), "direction": field_direction(origin, target), "round": round_number, "expires": round_number + int(move.duration)}
		consequence("", "%s · shared %s tile" % [move.name, field_kind(move)], "hybrid_field", [target], side)
		return
	var recipient := other if effect == "debuff" else side
	if unit_hp(recipient) <= 0:
		return
	var extra := move.duplicate()
	extra.effect = effect
	extra.power = move.get("secondary_power", 0)
	var key := status_key(extra)
	var magnitude := status_magnitude(recipient, extra)
	var turns := int(move.duration) + (passives.potency(side) if effect == "buff" and passives.has_class(side, "feyborn") else 0)
	var previous: Dictionary = statuses[recipient].get(key, {})
	var lifetime := turns + (1 if recipient == side else 0)
	if not previous.is_empty() and (float(previous.magnitude) > magnitude or (is_equal_approx(float(previous.magnitude), magnitude) and int(previous.turns) >= lifetime)):
		return
	statuses[recipient][key] = {"magnitude": magnitude, "turns": lifetime}
	var cell := unit_cell(recipient)
	if not tiles.has(cell):
		tiles.append(cell)
	consequence(recipient, "%s · %s (%dt)" % [move.name, key.replace("_", " "), turns], "hybrid_status", [cell], side)

func execute_move(side: String, slot: int, target: Vector2i) -> bool:
	var origin := unit_cell(side)
	if turn != side or not can_use_for(side, slot, target, origin):
		return false
	var move: Dictionary = moves_for(side)[slot]
	actions_remaining -= SolMove.cost(move)
	spend_use(side, move)
	announce(side, "%s uses %s" % [str((ally if side == "ally" else enemy).display_name), str(move.name)])
	var actor: Dictionary = ally if side == "ally" else enemy
	var foe: Dictionary = enemy if side == "ally" else ally
	var other := "enemy" if side == "ally" else "ally"
	var mode := quantum_mode if side == "ally" else "position"
	var tiles: Array = [target]
	var effect_announced := false
	if move.effect == "damage":
		var reasons: Array[String] = []
		var amount := mini(unit_hp(other), damage_for(side, move, origin, -1, reasons))
		var guarded := guard_slot(other)
		if guarded >= 0:
			var guard: Dictionary = moves_for(other)[guarded]
			if reasons.has(str(guard.name)):
				spend_use(other, guard)
				passive_guard[other] = false
				consequence(other, "%s cushioned the hit · %d uses left" % [guard.name, uses_left(other, guard)], "equipped_passive", [unit_cell(other)], other)
				if other == "ally":
					contributed = true
		var bonus := environmental_bonus(side, origin)
		if bonus > 0:
			feedback("vastra", origin, roundi(bonus * 100.0), AffinityImprint.canonical(actor.affinity), "+%d%% Vastra" % roundi(bonus * 100.0), "vastra_affinity")
		if side == "enemy" and (statuses.ally.has("protect") or statuses.enemy.has(("special_attack" if move.get("category", "physical") == "special" else "attack") + "_down")):
			contributed = true # Effective protection/offense suppression helped this participant survive.
		set_unit_hp(other, unit_hp(other) - amount)
		var previous_passives := passives.units.duplicate(true) if resolution_event.has_connections() else {}
		passives.landed(side)
		if side == "ally":
			contributed = true
		feedback("damage", unit_cell(other), amount, move.affinity, move.name)
		passives.present_hit(side, previous_passives)
		if not reasons.is_empty():
			consequence(other, " · ".join(reasons), "damage_modifiers", [unit_cell(other)], side)
		log.append("%s: %d damage." % [move.name, amount])
	elif move.effect == "heal":
		var amount := mini(int(actor.max_hp) - unit_hp(side), int(move.power))
		set_unit_hp(side, unit_hp(side) + amount)
		if amount > 0:
			feedback("heal", unit_cell(side), amount, move.affinity, move.name)
		elif VastraCombat.move_delta(move) < 0 and int(tile_overloads.get(origin, 0)) > VastraCombat.MIN_OVERLOAD:
			feedback("field", unit_cell(side), 0, move.affinity, move.name + " · environmental restoration", "vastra_restoration")
		if side == "ally" and amount > 0:
			contributed = true
		if amount > 0:
			log.append("%s restores %d HP." % [move.name, amount])
		elif VastraCombat.move_delta(move) < 0 and int(tile_overloads.get(origin, 0)) > VastraCombat.MIN_OVERLOAD:
			log.append("%s restores the surrounding Vastra." % move.name)
		else:
			log.append("%s prepares support." % move.name)
	elif move.effect in ["buff", "debuff", "poison", "protect"]:
		var recipient := side if move.effect in ["buff", "protect"] else other
		var turns := int(move.duration)
		if move.effect == "buff" and passives.has_class(side, "feyborn"):
			turns += passives.potency(side)
		statuses[recipient][status_key(move)] = {"magnitude": status_magnitude(recipient, move), "turns": turns + (1 if recipient == side else 0)}
		log.append("%s applies %s for %d turns." % [move.name, move.effect, turns])
		feedback("field", target, 0, move.affinity, "%s · %s applied (%dt)" % [move.name, status_key(move).replace("_", " "), turns], "status_application")
		if move.effect == "debuff" and passives.has_class(recipient, "construct"):
			consequence(recipient, "Stable Frame reduced the stat penalty", "class_passive", [target], recipient)
		if move.effect == "buff" and passives.has_class(side, "feyborn"):
			consequence(recipient, "Otherworldly Grace extended the buff", "class_passive", [target], side)
		effect_announced = true
		if side == "ally" and recipient == other:
			contributed = true
	elif move.effect == "anchor":
		anchored[side] = round_number + int(move.duration)
		log.append("Stable footing prevents wind displacement for %d rounds." % int(move.duration))
		feedback("field", target, 0, move.affinity, "%s · Stable Footing ready" % move.name, "anchor")
		effect_announced = true
	elif move.effect == "phase":
		phasing[side] = true
		log.append("Thin obstacles may be crossed on your next movement; land on open ground.")
		feedback("field", target, 0, move.affinity, "%s · thin-obstacle crossing ready" % move.name, "phase")
		effect_announced = true
	elif move.effect == "quantum" and mode == "position":
		tiles.append(origin)
		mark_movement(side, distance(origin, target))
		set_unit_cell(side, target)
		remaining = 0
		log.append("Superposition resolved at the chosen open tile; movement spent.")
		consequence(side, "%s · resolved at chosen tile" % move.name, "quantum_position", tiles, side)
		effect_announced = true
	elif move.effect == "quantum" and mode == "stabilize":
		fields.erase(target)
		log.append("Chosen field stabilized with certainty; action spent.")
		feedback("field", target, 0, move.affinity, "%s · field cleared" % move.name, "quantum_stabilize")
		effect_announced = true
	else:
		var kind := field_kind(move)
		var direction := field_direction(origin, target)
		tiles = field_tiles(move, origin, target)
		if kind == "entangled":
			links[origin] = target
			links[target] = origin
		var changed := false
		for at: Vector2i in tiles:
			var field := {"kind": kind, "direction": direction, "round": round_number, "expires": round_number + int(move.duration)}
			if kind == "rough" and at == target and at != ally_cell and at != enemy_cell:
				field.kind = "barrier"
			if fields.get(at) != field:
				changed = true
			fields[at] = field
		if changed:
			feedback("field", target, 0, move.affinity, "%s · shared terrain changed" % move.name, "field_placement")
			effect_announced = true
		if kind == "wind":
			for pushed_side in ["ally", "enemy"]:
				var position: Vector2i = ally_cell if pushed_side == "ally" else enemy_cell
				var landing := position + direction
				if int(anchored[pushed_side]) < round_number and tiles.has(position) and passable(landing) and landing != trainer and landing != ally_cell and landing != enemy_cell:
					mark_movement(pushed_side, 1)
					if pushed_side == "ally":
						ally_cell = landing
					else:
						enemy_cell = landing
					consequence(pushed_side, "%s pushed by wind" % str((ally if pushed_side == "ally" else enemy).display_name), "wind_displacement", [position, landing], side)
					changed = true # Displacement is an intended effect even when existing wind is unchanged.
			for at: Vector2i in fields.keys():
				if tiles.has(at) and fields[at].kind == "heat":
					fields.erase(at)
		if not changed:
			return false
		if side == "ally" and tiles.has(enemy_cell):
			contributed = true
		log.append("%s shapes shared terrain. Both sides are affected." % move.name)
	apply_secondary(side, move, origin, target, tiles)
	if move.id != "last_effort":
		record_move(move, tiles, not effect_announced)
	if side == "ally":
		participated = true
	if ally_hp <= 0:
		phase = "exhaustion"
	elif enemy_hp <= 0:
		phase = "victory"
	# Successful moves leave control with the same actor. Only End turn (or a
	# terminal outcome) advances statuses, initiative, and the opponent.
	return true

func tick_fields() -> void:
	var charged_hits := {}
	var expired: Array[Vector2i] = []
	var discharged := {}
	for cell in fields.keys():
		var field: Dictionary = fields[cell]
		if round_number >= int(field.expires):
			fields.erase(cell)
			expired.append(cell)
			continue
		if int(field.round) >= round_number:
			continue
		if field.kind == "heat":
			if cell == ally_cell:
				hurt("ally", field_damage, "fire", "Heat", "heat")
			if cell == enemy_cell:
				hurt("enemy", field_damage, "fire", "Heat", "heat")
		elif field.kind == "charge":
			var conductive := {cell: true}
			var pending: Array[Vector2i] = [cell]
			var cursor := 0
			while cursor < pending.size():
				var at := pending[cursor]
				cursor += 1
				for step in [Vector2i.UP, Vector2i.LEFT, Vector2i.RIGHT, Vector2i.DOWN]:
					var next: Vector2i = at + step
					if not conductive.has(next) and fields.get(next, {}).get("kind") == "wet":
						conductive[next] = true
						pending.append(next)
			if conductive.has(ally_cell) and not charged_hits.has("ally"):
				charged_hits.ally = true
				hurt("ally", field_damage, "lightning", "Lightning discharge", "lightning")
				disrupted.ally = true
			if conductive.has(enemy_cell) and not charged_hits.has("enemy"):
				charged_hits.enemy = true
				hurt("enemy", field_damage, "lightning", "Lightning discharge", "lightning")
				disrupted.enemy = true
			field.kind = "rough" # Discharged ground; no repeated burst from one charge.
			for at in conductive:
				discharged[at] = true
	if not expired.is_empty():
		consequence("", "Terrain conditions expired · %d tiles" % expired.size(), "field_expiry", expired)
	if not discharged.is_empty():
		consequence("", "Lightning discharged · %d connected tiles" % discharged.size(), "discharge", discharged.keys())
	# Heat spreads one cardinal step per round, but never past its original expiry.
	var spread := {}
	for cell: Vector2i in fields:
		var field: Dictionary = fields[cell]
		if field.kind != "heat" or int(field.round) >= round_number:
			continue
		for direction in [Vector2i.UP, Vector2i.LEFT, Vector2i.RIGHT, Vector2i.DOWN]:
			var next: Vector2i = cell + direction
			if cells.get(next, false) and next != trainer and not fields.has(next):
				spread[next] = field.duplicate(true)
				spread[next].round = round_number
	for cell in spread:
		fields[cell] = spread[cell]
		affected[cell] = true
	if not spread.is_empty():
		consequence("", "Heat spread · %d tiles" % spread.size(), "heat_spread", spread.keys())
	if phase == "active":
		if ally_hp <= 0:
			phase = "exhaustion"
		elif enemy_hp <= 0:
			phase = "victory"

func passable(cell: Vector2i) -> bool:
	return cells.get(cell, false) and fields.get(cell, {}).get("kind") != "barrier"

func feedback(kind: String, cell: Vector2i, amount: int, affinity: String, caption: String, cause: String = "", actor_override: String = "@default") -> void:
	var event := {"kind": kind, "cell": cell, "amount": amount, "affinity": affinity, "caption": caption}
	presentation_event.emit(event)
	var label := caption
	if kind in ["damage", "heal"]:
		label = "%s%s%d HP" % [(caption + " · ") if not caption.is_empty() else "", "−" if kind == "damage" else "+", amount]
	var recipient := "ally" if cell == ally_cell else ("enemy" if cell == enemy_cell else "")
	resolution("effect", recipient, label, [], event, {}, actor_override, cause, [cell])

func hurt(side: String, amount: int, affinity: String, caption: String = "", cause: String = "") -> void:
	var actual := mini(ally_hp if side == "ally" else enemy_hp, amount)
	if side == "ally":
		ally_hp -= actual
	else:
		enemy_hp -= actual
	if actual > 0:
		feedback("damage", ally_cell if side == "ally" else enemy_cell, actual, affinity, caption, cause, "")

func capture_chance() -> float:
	if phase != "active" or turn != "ally" or enemy_hp <= 0 or actions_remaining < seal_action_points:
		return 0.0
	var separation := distance(ally_cell, enemy_cell)
	if separation < 1:
		return 0.0
	var weakened := 1.0 - float(enemy_hp) / float(enemy.max_hp)
	var proximity := maxf(0.0, 0.20 - 0.025 * (separation - 1))
	return clampf(0.08 + weakened * 0.48 + float(seal_power) / 250.0 + proximity, 0.0, 0.95)

func attempt_capture(roll: float) -> bool:
	var chance := capture_chance()
	if chance <= 0 or not is_finite(roll) or roll < 0 or roll >= 1:
		return false
	capture_attempts += 1
	actions_remaining -= seal_action_points
	announce("ally", "Attempting a Seal")
	feedback("seal", enemy_cell, 0, "", "Seal")
	if roll < chance:
		phase = "captured"
		log.append(str(enemy.display_name) + " was sealed.")
	else:
		log.append("The Seal failed. The enemy acts next.")
		consequence("enemy", "Seal failed · opponent resumes", "capture_failed", [enemy_cell], "ally")
		finish_turn()
		auto_enemy()
	return true


func has_nearby_support(side: String, at: Vector2i, radius: int) -> bool:
	for support in support_units:
		if support.get("side") == side and int(support.get("hp", 0)) > 0 and support.get("cell") is Vector2i and distance(support.cell, at) <= radius:
			return true
	return false

func has_affliction(side: String) -> bool:
	for key in statuses[side]:
		if key == "poison" or str(key).ends_with("_down"):
			return true
	return false

func effective_stat(side: String, stat: String) -> float:
	var profile: Dictionary = ally if side == "ally" else enemy
	var base := float(profile.get(stat, profile.attack if stat == "special_attack" else profile.defense))
	var up := float(statuses[side].get(stat + "_up", {}).get("magnitude", 0))
	var down := float(statuses[side].get(stat + "_down", {}).get("magnitude", 0))
	return maxf(0.0, base * (1.0 + (up - down) / 100.0))

func damage_for(side: String, move: Dictionary, origin: Vector2i, moved_tiles: int = -1, reasons: Variant = null) -> int:
	var other := "enemy" if side == "ally" else "ally"
	var special: bool = move.get("category", "physical") == "special"
	var offense := effective_stat(side, "special_attack" if special else "attack")
	var defense := effective_stat(other, "special_defense" if special else "defense")
	var protection := float(statuses[other].get("protect", {}).get("magnitude", 0)) / 100.0
	var factor := passives.damage_factor(side, move, origin, moved_tiles, reasons)
	var environment_bonus := environmental_bonus(side, origin)
	factor *= 1.0 + environment_bonus
	if environment_bonus > 0 and reasons != null:
		reasons.append("Matching Vastra +%d%% damage" % roundi(environment_bonus * 100.0))
	if protection > 0 and reasons != null:
		reasons.append("Protection reduces direct damage")
	var amount := maxi(1, roundi(maxf(1.0, offense + int(move.power) - defense) * factor * (1.0 - protection) * float(move.get("damage_percent", 100)) / 100.0))
	var guarded := guard_slot(other)
	if guarded >= 0 and amount > 1:
		var guard: Dictionary = moves_for(other)[guarded]
		amount = maxi(1, amount - int(guard.power))
		if reasons != null:
			reasons.append(str(guard.name))
	return amount

func environmental_bonus(side: String, origin: Vector2i) -> float:
	var profile: Dictionary = ally if side == "ally" else enemy
	if vastra_settings == null or not vastra_settings.valid() or tile_affinities.get(origin, "") != AffinityImprint.canonical(profile.affinity):
		return 0.0
	return float(tile_concentrations.get(origin, 0)) / 100.0 * vastra_settings.affinity_damage_bonus

func status_key(move: Dictionary) -> String:
	if move.effect in ["poison", "protect"]:
		return move.effect
	return str(move.get("stat", "attack")) + ("_up" if move.effect == "buff" else "_down")

func status_magnitude(recipient: String, move: Dictionary) -> float:
	var amount := float(move.power)
	if move.effect == "debuff" and passives.has_class(recipient, "construct"):
		amount *= 1.0 - float(passives.potency(recipient)) / 100.0
	return amount

func tick_statuses(side: String) -> void:
	var effects: Dictionary = statuses[side]
	var changes: Array[String] = []
	for key in effects.keys():
		if key == "poison":
			hurt(side, int(ceil(float(effects[key].magnitude))), "earth", "Poison", "poison")
		effects[key].turns -= 1
		if effects[key].turns <= 0 or unit_hp(side) <= 0:
			effects.erase(key)
			changes.append(str(key).replace("_", " ") + (" cleared" if unit_hp(side) <= 0 else " expired"))
		else:
			changes.append("%s: %dt left" % [str(key).replace("_", " "), int(effects[key].turns)])
	if not changes.is_empty():
		consequence(side, " · ".join(changes).capitalize(), "status_duration", [unit_cell(side)])

func status_summary(side: String) -> String:
	var descriptions: Array[String] = []
	for key in statuses[side]:
		var effect: Dictionary = statuses[side][key]
		descriptions.append("%s %.1f%s (%dt)" % [str(key).replace("_", " "), float(effect.magnitude), " HP" if key == "poison" else "%", int(effect.turns)])
	if int(anchored[side]) >= round_number:
		descriptions.append("Stable Footing (through round %d)" % int(anchored[side]))
	if phasing[side]:
		descriptions.append("Thin-obstacle crossing ready")
	if links.has(unit_cell(side)):
		descriptions.append("Entangled ground")
	if disrupted[side]:
		descriptions.append("Movement disrupted next turn")
	var ready := guard_slot(side)
	if ready >= 0:
		descriptions.append(str(moves_for(side)[ready].name) + " ready")
	return ", ".join(descriptions)
