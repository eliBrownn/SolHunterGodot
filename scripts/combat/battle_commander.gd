class_name BattleCommander
extends RefCounted
## Read-only bounded routing. Terrain/traversal remain Godot authorities.
static func plan(battle: TacticalBattle, start: Vector2i, can_step: Callable) -> Array[Vector2i]:
	var search := battle.bounds.grow(1)
	var pending: Array[Vector2i] = [start]
	var parents := {start: start}
	var costs := {start: 0}
	var index := 0
	var best := start
	var farthest := -1
	var mid := battle.bounds.position + battle.bounds.size / 2
	var side_centers: Array[Vector2i] = [Vector2i(battle.bounds.position.x - 1, mid.y), Vector2i(battle.bounds.end.x, mid.y), Vector2i(mid.x, battle.bounds.position.y - 1), Vector2i(mid.x, battle.bounds.end.y)]
	while index < pending.size():
		var at := pending[index]
		index += 1
		if not battle.bounds.has_point(at):
			var horizontal := at.x < battle.bounds.position.x or at.x >= battle.bounds.end.x
			var vertical := at.y < battle.bounds.position.y or at.y >= battle.bounds.end.y
			var side := (0 if at.x < battle.bounds.position.x else 1) if horizontal else (2 if at.y < battle.bounds.position.y else 3)
			var separation := side_centers[side].distance_squared_to(battle.enemy_cell)
			if horizontal != vertical and (separation > farthest or (separation == farthest and int(costs[at]) < int(costs[best]))) and not battle.deployment_from(at).is_empty():
				best = at
				farthest = separation
		for direction in [Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP]:
			var next: Vector2i = at + direction
			if search.has_point(next) and absi(next.x) <= 1000000 and absi(next.y) <= 1000000 and not parents.has(next) and next != battle.enemy_cell and (not battle.bounds.has_point(next) or battle.passable(next)) and can_step.call(at, next):
				parents[next] = at
				costs[next] = int(costs[at]) + 1
				pending.append(next)
	var route: Array[Vector2i] = []
	if farthest < 0:
		return route
	while best != start:
		route.push_front(best)
		best = parents[best]
	return route
