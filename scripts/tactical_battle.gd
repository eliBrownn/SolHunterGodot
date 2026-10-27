class_name TacticalBattle
extends RefCounted
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
			battle.cells[at] = terrain.fits(at)
	if not battle.cells.get(target, false) or battle.deployment_tiles().is_empty():
		return null
	battle.log.append("Choose a blue tile to release " + str(hero.display_name) + ".")
	return battle

static func distance(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)

func paths(start: Vector2i, budget: int, blocked: Vector2i) -> Dictionary:
	var result := {start: []}
	var pending: Array[Vector2i] = [start]
	var cursor := 0
	while cursor < pending.size():
		var current := pending[cursor]
		cursor += 1
		if result[current].size() >= budget:
			continue
		for direction in [Vector2i.UP, Vector2i.LEFT, Vector2i.RIGHT, Vector2i.DOWN]:
			var next: Vector2i = current + direction
			if next == trainer or next == blocked or not cells.get(next, false) or result.has(next):
				continue
			var path: Array = result[current].duplicate()
			path.append(next)
			result[next] = path
			pending.append(next)
	return result

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
	queue.assign(["ally", "enemy"] if int(ally.speed) >= int(enemy.speed) else ["enemy", "ally"])
	turn = queue[0]
	remaining = movement

func finish_turn() -> void:
	queue.pop_front()
	if queue.is_empty():
		round_number += 1
		start_round()
	else:
		turn = queue[0]
		remaining = movement

func reachable() -> Dictionary:
	return paths(ally_cell, remaining, enemy_cell) if phase == "active" and turn == "ally" else {}

func move_ally(cell: Vector2i) -> bool:
	var options := reachable()
	if not options.has(cell) or options[cell].is_empty():
		return false
	remaining -= options[cell].size()
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
		if not cells.get(cell, false) or cell == trainer:
			return false
		if cell.x != previous.x and cell.y != previous.y and (not cells.get(Vector2i(cell.x, previous.y), false) or not cells.get(Vector2i(previous.x, cell.y), false)):
			return false
		previous = cell
	return true

static func damage(source: Dictionary, target: Dictionary) -> int:
	return maxi(1, int(source.attack) + int(source.move_power) - int(target.defense))

func can_attack() -> bool:
	return phase == "active" and turn == "ally" and in_range(ally_cell, enemy_cell, int(ally.move_range))

func attack() -> bool:
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
	var options := paths(enemy_cell, movement, ally_cell)
	var best := enemy_cell
	var best_score := 2147483647
	for cell: Vector2i in options:
		var able := in_range(cell, ally_cell, int(enemy.move_range))
		var score: int = options[cell].size() if able else 1000 + distance(cell, ally_cell) * 100 + options[cell].size()
		if score < best_score or (score == best_score and (cell.y < best.y or (cell.y == best.y and cell.x < best.x))):
			best_score = score
			best = cell
	return best

func enemy_intent() -> String:
	if phase == "deployment":
		return "Enemy waits for deployment."
	var target := enemy_plan()
	return "%s: move if needed, then %s (%d damage)." % [enemy.display_name, enemy.move_name, damage(enemy, ally)] if in_range(target, ally_cell, int(enemy.move_range)) else str(enemy.display_name) + ": approach attack range."

func auto_enemy() -> void:
	# Two participants: a bounded loop also handles an enemy-first initial deployment.
	for iteration in range(2):
		if phase != "active" or turn != "enemy":
			return
		enemy_cell = enemy_plan()
		if in_range(enemy_cell, ally_cell, int(enemy.move_range)):
			var amount := mini(ally_hp, damage(enemy, ally))
			ally_hp -= amount
			log.append("%s uses %s: %d damage." % [enemy.display_name, enemy.move_name, amount])
		else:
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
