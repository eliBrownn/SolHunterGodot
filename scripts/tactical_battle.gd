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
	log.append("You hold position and end the turn.")
	finish_turn()
	auto_enemy()
	return true

func enemy_plan() -> Vector2i:
	var chosen := enemy_attack_move()
	var options := paths(enemy_cell, movement, ally_cell)
	var best := enemy_cell
	var best_score := 2147483647
	for cell: Vector2i in options:
		var able := in_range(cell, ally_cell, int(chosen.reach))
		var score: int = options[cell].size() if able else 1000 + distance(cell, ally_cell) * 100 + options[cell].size()
		if score < best_score or (score == best_score and (cell.y < best.y or (cell.y == best.y and cell.x < best.x))):
			best_score = score
			best = cell
	return best


func enemy_intent() -> String:
	if phase == "deployment":
		return "Enemy waits for deployment."
	var chosen := enemy_attack_move()
	var target := enemy_plan()
	var amount := maxi(1, int(enemy.attack) + int(chosen.power) - int(ally.defense))
	return "%s: approach, then %s (%d damage)." % [enemy.display_name, chosen.name, amount] if chosen.effect == "damage" and in_range(target, ally_cell, int(chosen.reach)) else str(enemy.display_name) + ": approach or recover."

func enemy_attack_move() -> Dictionary:
	for move in enemy_moves:
		if move.effect == "damage":
			return move
	if not enemy_moves.is_empty():
		return enemy_moves[0]
	return {"name": enemy.move_name, "effect": "damage", "power": enemy.move_power, "reach": enemy.move_range}

func auto_enemy() -> void:
	# Two participants: a bounded loop also handles an enemy-first initial deployment.
	for iteration in range(2):
		if phase != "active" or turn != "enemy":
			return
		enemy_cell = enemy_plan()
		var chosen := enemy_attack_move()
		var healed := false
		for move in enemy_moves:
			if move.effect == "heal" and enemy_hp < int(enemy.max_hp) / 2 and not in_range(enemy_cell, ally_cell, int(chosen.reach)):
				var amount := mini(int(move.power), int(enemy.max_hp) - enemy_hp)
				if amount > 0:
					enemy_hp += amount
					feedback("heal", enemy_cell, amount, move.affinity, move.name)
					record_move(move, [enemy_cell])
					log.append("%s restores %d HP." % [enemy.display_name, amount])
					healed = true
					break
		if not healed and chosen.effect == "damage" and in_range(enemy_cell, ally_cell, int(chosen.reach)):
			var amount := mini(ally_hp, maxi(1, int(enemy.attack) + int(chosen.power) - int(ally.defense)))
			ally_hp -= amount
			feedback("damage", ally_cell, amount, chosen.get("affinity", enemy.affinity), chosen.name)
			if not enemy_moves.is_empty():
				record_move(chosen, [ally_cell])
			log.append("%s uses %s: %d damage." % [enemy.display_name, chosen.name, amount])
		elif not healed:
			log.append(str(enemy.display_name) + " approaches and waits.")
		if ally_hp == 0:
			phase = "exhaustion"
			return
		finish_turn()

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
	if phase != "active" or turn != "ally" or slot < 0 or slot >= ally_moves.size():
		return false
	var move: Dictionary = ally_moves[slot]
	if move.effect == "heal":
		return target == ally_cell and ally_hp < int(ally.max_hp)
	if move.effect == "phase":
		return target == ally_cell and not phasing.ally
	if move.effect == "anchor":
		return target == ally_cell and int(anchored.ally) < round_number
	if not passable(target) or target == trainer or distance(ally_cell, target) > int(move.reach):
		return false
	if move.effect == "damage":
		return target == enemy_cell and in_range(ally_cell, target, int(move.reach))
	if move.effect == "quantum":
		if quantum_mode == "stabilize":
			return fields.has(target)
		return target != ally_cell and target != enemy_cell
	return in_range(ally_cell, target, int(move.reach))

func use_move(slot: int, target: Vector2i) -> bool:
	if not can_use(slot, target):
		return false
	var move: Dictionary = ally_moves[slot]
	var tiles: Array = [target]
	if move.effect == "damage":
		var amount := mini(enemy_hp, maxi(1, int(ally.attack) + int(move.power) - int(enemy.defense)))
		enemy_hp -= amount
		feedback("damage", enemy_cell, amount, move.affinity, move.name)
		log.append("%s: %d damage." % [move.name, amount])
	elif move.effect == "heal":
		var amount := mini(int(ally.max_hp) - ally_hp, int(move.power))
		if amount <= 0:
			return false
		ally_hp += amount
		feedback("heal", ally_cell, amount, move.affinity, move.name)
		log.append("%s restores %d HP." % [move.name, amount])
	elif move.effect == "anchor":
		anchored.ally = round_number + int(move.duration)
		log.append("Stable footing prevents wind displacement for %d rounds." % int(move.duration))
	elif move.effect == "phase":
		phasing.ally = true
		log.append("Thin obstacles may be crossed on your next movement; land on open ground.")
	elif move.effect == "quantum" and quantum_mode == "position":
		tiles.append(ally_cell)
		ally_cell = target
		remaining = 0
		log.append("Superposition resolved at the chosen open tile; movement spent.")
	elif move.effect == "quantum" and quantum_mode == "stabilize":
		fields.erase(target)
		log.append("Chosen field stabilized with certainty; action spent.")
	else:
		var kind: String = {"fire": "heat", "water": "wet", "earth": "rough", "air": "wind", "lightning": "charge", "void": "warp", "spectral": "phase", "quantum": "entangled"}.get(move.affinity, "rough")
		var direction := target - ally_cell
		direction = Vector2i(signi(direction.x), 0) if absi(direction.x) >= absi(direction.y) else Vector2i(0, signi(direction.y))
		if direction == Vector2i.ZERO:
			direction = Vector2i.RIGHT
		for step in [Vector2i.UP, Vector2i.LEFT, Vector2i.RIGHT, Vector2i.DOWN]:
			var at: Vector2i = target + step
			if cells.get(at, false) and at != trainer:
				tiles.append(at)
		if kind == "entangled":
			tiles = [ally_cell, target]
			links[ally_cell] = target
			links[target] = ally_cell
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
			for side in ["ally", "enemy"]:
				var position: Vector2i = ally_cell if side == "ally" else enemy_cell
				var landing := position + direction
				if int(anchored[side]) < round_number and tiles.has(position) and passable(landing) and landing != trainer and landing != ally_cell and landing != enemy_cell:
					if side == "ally":
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
	if enemy_hp <= 0:
		phase = "victory"
	else:
		finish_turn()
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
