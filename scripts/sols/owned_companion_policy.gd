class_name OwnedCompanionPolicy
extends RefCounted
## Pure bounded follow navigation. The edge callable owns capability and clearance.
## No home leash, state writes, or blocker bypass.

static func next_step(position: Vector2i, player: Vector2i, occupied: Dictionary, can_step: Callable, settings: OwnedCompanionSettings) -> Vector2i:
	if position == player:
		for direction in SolLocalNavigation.DIRECTIONS:
			var candidate: Vector2i = position + direction
			if not occupied.has(candidate) and can_step.call(position, candidate):
				return candidate
		return position
	if SolRoamingPolicy.distance(position, player) <= settings.stop_distance:
		return position
	var queue: Array[Vector2i] = [position]
	var first := {position: position}
	var best := position
	var cursor := 0
	while cursor < queue.size():
		var current := queue[cursor]
		cursor += 1
		if SolRoamingPolicy.distance(current, player) <= settings.stop_distance:
			return first[current]
		for direction in SolLocalNavigation.DIRECTIONS:
			var candidate: Vector2i = current + direction
			if first.has(candidate) or candidate == player or occupied.has(candidate) or SolRoamingPolicy.distance(candidate, position) > settings.search_radius or first.size() >= settings.search_cells or not can_step.call(current, candidate):
				continue
			first[candidate] = candidate if current == position else first[current]
			queue.append(candidate)
			if SolRoamingPolicy.distance(candidate, player) < SolRoamingPolicy.distance(best, player):
				best = candidate
	return first[best] # A cornered companion waits; it never relocates through blockers.
