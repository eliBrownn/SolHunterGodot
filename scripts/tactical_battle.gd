class_name TacticalBattle
extends RefCounted
signal presentation_event(event: Dictionary)
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
var ai_hazard_weight := 2.0
var ai_heal_weight := 0.25
var ai_field_weight := 2.0


static func prepare(terrain: WorldTerrain, origin: Vector2i, target: Vector2i, hero: Dictionary, hero_hp: int, opponent: Dictionary, settings: BattleSettings) -> TacticalBattle:
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
	battle.release_range = settings.release_range
	battle.seal_power = settings.seal_power
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
	if not battle.cells.get(target, false) or battle.deployment_tiles().is_empty():
		return null
	battle.log.append("Choose a blue tile to release " + str(hero.display_name) + ".")
	return battle

static func distance(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)

func paths(start: Vector2i, budget: int, blocked: Vector2i, phase_crossing: bool = false) -> Dictionary:
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
			if next == trainer or next == blocked or not passable(next):
				continue
			var cost: int = int(costs[current]) + (2 if crossed else step_cost(current, next))
			if cost > budget or (costs.has(next) and cost >= int(costs[next])):
				continue
			var path: Array = result[current].duplicate()
			path.append(next)
			result[next] = path
			costs[next] = cost
			pending.append(next)
	return result

func step_cost(from: Vector2i, to: Vector2i) -> int:
	var field: Dictionary = fields.get(to, {})
	var kind: String = field.get("kind", "")
	if kind == "rough":
		return rough_cost
	if kind == "warp":
		return assisted_cost if from.x == to.x else resisted_cost
	if kind in ["wet", "wind"]:
		var direction: Vector2i = field.get("direction", Vector2i.RIGHT)
		var delta := to - from
		var dot := delta.x * direction.x + delta.y * direction.y
		return assisted_cost if dot > 0 else (resisted_cost if dot < 0 else 1)
	return 1

func route_cost(start: Vector2i, path: Array) -> int:
	var cost := 0
	for cell: Vector2i in path:
		cost += 2 if distance(start, cell) > 1 else step_cost(start, cell)
		start = cell
	return cost

func deployment_tiles() -> Array[Vector2i]:
	var output: Array[Vector2i] = []
	var connected := paths(enemy_cell, cells.size(), Vector2i(2000000, 2000000))
	for cell: Vector2i in connected:
		if cell != enemy_cell and cell != trainer and distance(cell, trainer) <= release_range:
			output.append(cell)
	output.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		var da := distance(a, trainer)
		var db := distance(b, trainer)
		if da != db:
			return da < db
		if (a.x == trainer.x) != (b.x == trainer.x):
			return a.x != trainer.x # Default cursor avoids hiding a short sprite behind the trainer.
		return a.y < b.y if a.y != b.y else a.x < b.x)
	return output

func deploy(cell: Vector2i) -> bool:
	if phase != "deployment" or not deployment_tiles().has(cell):
		return false
	ally_cell = cell
	phase = "active"
	start_round()
	log.append(str(ally.display_name) + " released. Fastest Sol acts first.")
	auto_enemy()
	return true

func start_round() -> void:
	tick_fields()
	queue.assign(["ally", "enemy"] if int(ally.speed) >= int(enemy.speed) else ["enemy", "ally"])
	turn = queue[0]
	remaining = maxi(0, movement - (1 if disrupted[turn] else 0))
	disrupted[turn] = false

func finish_turn() -> void:
	queue.pop_front()
	if queue.is_empty():
		round_number += 1
		start_round()
	else:
		turn = queue[0]
		remaining = maxi(0, movement - (1 if disrupted[turn] else 0))
		disrupted[turn] = false

func reachable() -> Dictionary:
	return paths(ally_cell, remaining, enemy_cell, phasing.ally or fields.get(ally_cell, {}).get("kind") == "phase") if phase == "active" and turn == "ally" else {}

func move_ally(cell: Vector2i) -> bool:
	var options := reachable()
	if not options.has(cell) or options[cell].is_empty():
		return false
	remaining -= route_cost(ally_cell, options[cell])
	phasing.ally = false
	ally_cell = cell
	participated = true
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
	if not ally_moves.is_empty():
		return can_use(0, enemy_cell)
	return phase == "active" and turn == "ally" and in_range(ally_cell, enemy_cell, int(ally.move_range))

func attack() -> bool:
	if not ally_moves.is_empty():
		return use_move(0, enemy_cell)
	if not can_attack():
		return false
	var amount := mini(enemy_hp, damage(ally, enemy))
	enemy_hp -= amount
	log.append("%s: %d damage." % [ally.move_name, amount])
	if enemy_hp == 0:
		phase = "victory"
	else:
		finish_turn()
		auto_enemy()
	return true

func wait_turn() -> bool:
	if phase != "active" or turn != "ally":
		return false
	participated = true
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
	for iteration in range(2):
		if phase != "active" or turn != "enemy":
			return
		var plan := plan_enemy()
		if plan.cell != enemy_cell:
			enemy_cell = plan.cell
			phasing.enemy = false
		if int(plan.slot) >= 0 and execute_move("enemy", int(plan.slot), plan.target):
			continue
		log.append(str(enemy.display_name) + " approaches and waits.")
		finish_turn()

func moves_for(side: String) -> Array[Dictionary]:
	var moves: Array[Dictionary] = ally_moves if side == "ally" else enemy_moves
	if not moves.is_empty():
		return moves
	var profile: Dictionary = ally if side == "ally" else enemy
	var fallback: Array[Dictionary] = [{"id": "legacy_basic", "name": profile.move_name, "affinity": AffinityImprint.canonical(profile.affinity), "effect": "damage", "power": profile.move_power, "reach": profile.move_range, "duration": 1}]
	return fallback

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
	var budget := remaining if turn == "enemy" else maxi(0, movement - (1 if disrupted.enemy else 0))
	var options := paths(enemy_cell, budget, ally_cell, phasing.enemy or fields.get(enemy_cell, {}).get("kind") == "phase")
	var best := {"cell": enemy_cell, "slot": -1, "target": ally_cell, "score": -INF, "cost": 0}
	var positions: Array = options.keys()
	positions.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.y < b.y if a.y != b.y else a.x < b.x)
	for origin: Vector2i in positions:
		var cost := route_cost(enemy_cell, options[origin])
		var targets: Array[Vector2i] = [ally_cell, origin]
		for direction in [Vector2i.UP, Vector2i.LEFT, Vector2i.RIGHT, Vector2i.DOWN]:
			for anchor in [ally_cell, origin]:
				var target: Vector2i = anchor + direction
				if cells.has(target) and not targets.has(target):
					targets.append(target)
		var moves := moves_for("enemy")
		for slot in range(moves.size()):
			var move: Dictionary = moves[slot]
			for target in targets:
				if not can_use_for("enemy", slot, target, origin):
					continue
				var benefit := action_benefit(move, origin, target)
				if benefit <= 0:
					continue
				var score := benefit - hazard_cost(origin)
				if score > best.score or (is_equal_approx(score, best.score) and cost < best.cost):
					best = {"cell": origin, "slot": slot, "target": target, "score": score, "cost": cost}
	if best.slot >= 0:
		return best
	var score := INF
	for origin: Vector2i in positions:
		var candidate := distance(origin, ally_cell) * 10.0 + hazard_cost(origin) * 10.0 + route_cost(enemy_cell, options[origin]) * 0.1
		if candidate < score:
			score = candidate
			best.cell = origin
	return best

func action_benefit(move: Dictionary, origin: Vector2i, target: Vector2i) -> float:
	if move.effect == "damage":
		var amount := mini(ally_hp, maxi(1, int(enemy.attack) + int(move.power) - int(ally.defense)))
		return float(amount) + (100.0 if amount >= ally_hp else 0.0)
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
	return true

func set_movebooks(hero_book: Dictionary, foe_book: Dictionary) -> void:
	ally_moves.clear()
	enemy_moves.clear()
	for id in hero_book.equipped:
		ally_moves.append(hero_book.learned[id].duplicate(true))
	for id in foe_book.equipped:
		enemy_moves.append(foe_book.learned[id].duplicate(true))

func record_move(move: Dictionary, tiles: Array) -> void:
	var affinity: String = move.affinity
	activity[affinity] = int(activity.get(affinity, 0)) + 1
	last_activity.append(affinity)
	for cell: Vector2i in tiles:
		affected[cell] = true
	if move.effect not in ["damage", "heal"] and not tiles.is_empty():
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
	var moves := moves_for(side)
	if phase != "active" or slot < 0 or slot >= moves.size():
		return false
	var move: Dictionary = moves[slot]
	var profile: Dictionary = ally if side == "ally" else enemy
	var other := "enemy" if side == "ally" else "ally"
	if move.effect == "heal":
		return target == origin and unit_hp(side) < int(profile.max_hp) and int(move.power) > 0
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
	return in_range(origin, target, int(move.reach))

func use_move(slot: int, target: Vector2i) -> bool:
	return execute_move("ally", slot, target)

func execute_move(side: String, slot: int, target: Vector2i) -> bool:
	var origin := unit_cell(side)
	if turn != side or not can_use_for(side, slot, target, origin):
		return false
	var move: Dictionary = moves_for(side)[slot]
	var actor: Dictionary = ally if side == "ally" else enemy
	var foe: Dictionary = enemy if side == "ally" else ally
	var other := "enemy" if side == "ally" else "ally"
	var mode := quantum_mode if side == "ally" else "position"
	var tiles: Array = [target]
	if move.effect == "damage":
		var amount := mini(unit_hp(other), maxi(1, int(actor.attack) + int(move.power) - int(foe.defense)))
		set_unit_hp(other, unit_hp(other) - amount)
		feedback("damage", unit_cell(other), amount, move.affinity, move.name)
		log.append("%s: %d damage." % [move.name, amount])
	elif move.effect == "heal":
		var amount := mini(int(actor.max_hp) - unit_hp(side), int(move.power))
		if amount <= 0:
			return false
		set_unit_hp(side, unit_hp(side) + amount)
		feedback("heal", unit_cell(side), amount, move.affinity, move.name)
		log.append("%s restores %d HP." % [move.name, amount])
	elif move.effect == "anchor":
		anchored[side] = round_number + int(move.duration)
		log.append("Stable footing prevents wind displacement for %d rounds." % int(move.duration))
	elif move.effect == "phase":
		phasing[side] = true
		log.append("Thin obstacles may be crossed on your next movement; land on open ground.")
	elif move.effect == "quantum" and mode == "position":
		tiles.append(origin)
		set_unit_cell(side, target)
		remaining = 0
		log.append("Superposition resolved at the chosen open tile; movement spent.")
	elif move.effect == "quantum" and mode == "stabilize":
		fields.erase(target)
		log.append("Chosen field stabilized with certainty; action spent.")
	else:
		var kind: String = {"fire": "heat", "water": "wet", "earth": "rough", "air": "wind", "lightning": "charge", "void": "warp", "spectral": "phase", "quantum": "entangled"}.get(move.affinity, "rough")
		var direction := target - origin
		direction = Vector2i(signi(direction.x), 0) if absi(direction.x) >= absi(direction.y) else Vector2i(0, signi(direction.y))
		if direction == Vector2i.ZERO:
			direction = Vector2i.RIGHT
		for step in [Vector2i.UP, Vector2i.LEFT, Vector2i.RIGHT, Vector2i.DOWN]:
			var at: Vector2i = target + step
			if cells.get(at, false) and at != trainer:
				tiles.append(at)
		if kind == "entangled":
			tiles = [origin, target]
			links[origin] = target
			links[target] = origin
		elif links.has(target):
			tiles.append(links[target])
		var changed := false
		for at: Vector2i in tiles:
			var field := {"kind": kind, "direction": direction, "round": round_number, "expires": round_number + int(move.duration)}
			if fields.get(at) != field:
				changed = true
			if kind == "rough" and at == target and at != ally_cell and at != enemy_cell:
				field.kind = "barrier"
			fields[at] = field
		if kind == "wind":
			for pushed_side in ["ally", "enemy"]:
				var position: Vector2i = ally_cell if pushed_side == "ally" else enemy_cell
				var landing := position + direction
				if int(anchored[pushed_side]) < round_number and tiles.has(position) and passable(landing) and landing != trainer and landing != ally_cell and landing != enemy_cell:
					if pushed_side == "ally":
						ally_cell = landing
					else:
						enemy_cell = landing
			for at: Vector2i in fields.keys():
				if tiles.has(at) and fields[at].kind == "heat":
					fields.erase(at)
		if not changed:
			return false
		log.append("%s shapes shared terrain. Both sides are affected." % move.name)
	record_move(move, tiles)
	if side == "ally":
		participated = true
	if ally_hp <= 0:
		phase = "exhaustion"
	elif enemy_hp <= 0:
		phase = "victory"
	else:
		finish_turn()
		if side == "ally":
			auto_enemy()
	return true

func tick_fields() -> void:
	var charged_hits := {}
	for cell in fields.keys():
		var field: Dictionary = fields[cell]
		if round_number >= int(field.expires):
			fields.erase(cell)
			continue
		if int(field.round) >= round_number:
			continue
		if field.kind == "heat":
			if cell == ally_cell:
				hurt("ally", field_damage, "fire")
			if cell == enemy_cell:
				hurt("enemy", field_damage, "fire")
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
				hurt("ally", field_damage, "lightning")
				disrupted.ally = true
			if conductive.has(enemy_cell) and not charged_hits.has("enemy"):
				charged_hits.enemy = true
				hurt("enemy", field_damage, "lightning")
				disrupted.enemy = true
			field.kind = "rough" # Discharged ground; no repeated burst from one charge.
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
	if phase == "active":
		if ally_hp <= 0:
			phase = "exhaustion"
		elif enemy_hp <= 0:
			phase = "victory"

func passable(cell: Vector2i) -> bool:
	return cells.get(cell, false) and fields.get(cell, {}).get("kind") != "barrier"

func feedback(kind: String, cell: Vector2i, amount: int, affinity: String, caption: String) -> void:
	presentation_event.emit({"kind": kind, "cell": cell, "amount": amount, "affinity": affinity, "caption": caption})

func hurt(side: String, amount: int, affinity: String) -> void:
	var actual := mini(ally_hp if side == "ally" else enemy_hp, amount)
	if side == "ally":
		ally_hp -= actual
	else:
		enemy_hp -= actual
	if actual > 0:
		feedback("damage", ally_cell if side == "ally" else enemy_cell, actual, affinity, "")

func capture_chance() -> float:
	if phase != "active" or turn != "ally" or enemy_hp <= 0:
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
	feedback("seal", enemy_cell, 0, "", "Seal")
	if roll < chance:
		phase = "captured"
		log.append(str(enemy.display_name) + " was sealed.")
	else:
		log.append("The Seal failed. The enemy acts next.")
		finish_turn()
		auto_enemy()
	return true
