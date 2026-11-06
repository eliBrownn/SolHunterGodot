class_name SolLocalNavigation
extends RefCounted
## Bounded cardinal BFS using the world's traversal contract, never visual geometry.

const DIRECTIONS := [Vector2i.UP, Vector2i.LEFT, Vector2i.RIGHT, Vector2i.DOWN]

static func next_step(position: Vector2i, home: Vector2i, action: String, goal: Vector2i, occupied: Dictionary, can_step: Callable, tuning: SightingSettings, player: Vector2i = Vector2i.ZERO, minimum_player_distance: int = 0) -> Vector2i:
	if action not in ["patrol", "return", "approach", "flee", "guard"]:
		return position
	if action == "guard" and SolRoamingPolicy.distance(position, goal) <= tuning.guard_standoff_distance:
		return position
	var queue: Array[Vector2i] = [position]
	var first := {position: position}
	var best := position
	var cursor := 0
	while cursor < queue.size():
		var current := queue[cursor]
		cursor += 1
		if action != "flee" and current == goal:
			break
		for direction in DIRECTIONS:
			var candidate: Vector2i = current + direction
			var radius := SolRoamingPolicy.distance(candidate, home)
			if first.has(candidate) or occupied.has(candidate) or radius > ExpeditionContract.MAX_ROAMING_DISTANCE:
				continue
			var player_distance := SolRoamingPolicy.distance(candidate, player)
			if minimum_player_distance > 0 and player_distance < minimum_player_distance and player_distance <= SolRoamingPolicy.distance(current, player):
				continue
			if action == "guard" and SolRoamingPolicy.distance(candidate, goal) < tuning.guard_standoff_distance:
				continue
			if radius > tuning.home_radius and radius >= SolRoamingPolicy.distance(current, home):
				continue
			if not can_step.call(current, candidate):
				continue
			if first.size() >= tuning.path_search_cells:
				continue
			first[candidate] = candidate if current == position else first[current]
			queue.append(candidate)
			var separation := SolRoamingPolicy.distance(candidate, goal)
			if (action == "flee" and separation > SolRoamingPolicy.distance(best, goal)) or (action != "flee" and separation < SolRoamingPolicy.distance(best, goal)):
				best = candidate
		if action == "flee":
			break # Flight only takes an immediately safer step; cornered Sols wait.
	return first[best]
