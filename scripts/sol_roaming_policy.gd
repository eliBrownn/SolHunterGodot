class_name SolRoamingPolicy
extends RefCounted
## Pure local decisions. The expedition owns durable memory; views never advance it.

static func distance(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)

static func roll(identity: String, leg: int, stream: String) -> int:
	return ("sol-patrol-v1:" + identity + ":" + str(leg) + ":" + stream).sha256_text().substr(0, 12).hex_to_int()

static func next_goal(identity: String, leg: int, home: Vector2i, position: Vector2i, previous: Vector2i, tuning: SightingSettings, allowed: Callable = Callable()) -> Vector2i:
	var radius := mini(tuning.wander_radius, tuning.home_radius)
	var minimum := maxi(1, ceili(radius * tuning.patrol_goal_min_fraction))
	var candidates: Array[Vector2i] = []
	for y in range(-radius, radius + 1):
		for x in range(-radius, radius + 1):
			var candidate := home + Vector2i(x, y)
			if absi(x) + absi(y) > radius or distance(candidate, position) < minimum or candidate == previous:
				continue
			if allowed.is_valid() and not allowed.call(candidate):
				continue
			candidates.append(candidate)
	return candidates[roll(identity, leg, "goal") % candidates.size()] if not candidates.is_empty() else position

static func decide(identity: String, home: Vector2i, position: Vector2i, player: Vector2i, reaction: String, saved: Dictionary, tick: int, tuning: SightingSettings, allowed: Callable = Callable()) -> Dictionary:
	var memory: Dictionary = saved.get("patrol", {}).duplicate(true)
	var result := {"action": "idle", "goal": home, "patrol": memory}
	if distance(position, home) > tuning.home_radius:
		result.action = "return"
	else:
		var response := SolReactionPolicy.decide(position, player, reaction, saved, tick, tuning)
		if not response.is_empty():
			if response.get("resume_patrol", false) and tuning.wander_enabled:
				var minimum := tuning.reaction_distance + 1 if reaction == "Wary" else tuning.guard_standoff_distance if reaction == "Guarding" else tuning.comfort_distance
				var safe_goal := func(cell: Vector2i) -> bool:
					return distance(cell, player) >= minimum and (not allowed.is_valid() or allowed.call(cell))
				var roaming := patrol(identity, home, position, tick, memory, tuning, safe_goal)
				roaming.response = response.response
				roaming.minimum_player_distance = minimum
				return roaming
			result.merge(response, true)
		elif position != home and (saved.has("response") or saved.action in ["flee", "approach", "return"] or not tuning.wander_enabled):
			result.action = "return"
		elif tuning.wander_enabled:
			return patrol(identity, home, position, tick, memory, tuning, allowed)
	result["response"] = result.get("response", {})
	# Interrupt a patrol when responding to the player; keep its next leg stable.
	if not memory.is_empty():
		memory.expires = 0
		memory.rest_until = 0
		memory.erase("blocked_since")
	return result

static func patrol(identity: String, home: Vector2i, position: Vector2i, tick: int, memory: Dictionary, tuning: SightingSettings, allowed: Callable = Callable()) -> Dictionary:
	var phase := roll(identity, 0, "initial-rest")
	if memory.is_empty():
		memory = {"goal": [home.x, home.y], "leg": 0, "expires": 0,
			"rest_until": tick + phase % (tuning.rest_max_ticks + 1)}
	var goal := Vector2i(int(memory.goal[0]), int(memory.goal[1]))
	if int(memory.expires) > 0 and (position == goal or tick >= int(memory.expires) or distance(goal, home) > tuning.home_radius or (allowed.is_valid() and not allowed.call(goal))):
		memory.expires = 0
		memory.erase("blocked_since")
		var rest := float(roll(identity, int(memory.leg), "rest-chance") % 10000) / 10000.0 < tuning.patrol_rest_chance
		memory.rest_until = tick + (tuning.rest_min_ticks + roll(identity, int(memory.leg), "rest") % (tuning.rest_max_ticks - tuning.rest_min_ticks + 1) if rest else 0)
	if tick < int(memory.rest_until):
		return {"action": "idle", "goal": position, "patrol": memory}
	if int(memory.expires) == 0:
		goal = next_goal(identity, int(memory.leg), home, position, goal, tuning, allowed)
		memory.goal = [goal.x, goal.y]
		memory.leg = (int(memory.leg) + 1) % 2147483647
		memory.expires = tick + tuning.goal_timeout_ticks
		if goal == position:
			memory.expires = 0
			memory.rest_until = tick + tuning.blocked_goal_retry_ticks
			return {"action": "idle", "goal": position, "patrol": memory}
	return {"action": "patrol", "goal": goal, "patrol": memory}
