class_name SolReactionPolicy
extends RefCounted
## Pure player-response state: alert hysteresis, reposition cooldown, then settling.

static func decide(position: Vector2i, player: Vector2i, reaction: String, saved: Dictionary, tick: int, tuning: SightingSettings) -> Dictionary:
	var offset := position - player
	var separation := absi(offset.x) + absi(offset.y)
	var memory: Dictionary = saved.get("response", {}).duplicate(true)
	var engaged: bool = memory.get("mode", "") == "alert"
	if separation <= tuning.reaction_distance or (engaged and separation < tuning.reaction_release_distance):
		if not engaged:
			memory = {"mode": "alert", "until": 0, "move_after": 0, "attention_until": tick + tuning.attention_ticks, "routine_until": 0}
		elif not memory.has("attention_until"):
			memory.attention_until = tick + tuning.attention_ticks
		var in_routine: bool = tick < int(memory.get("routine_until", 0))
		if not in_routine and int(memory.attention_until) == 0:
			memory.attention_until = tick + tuning.attention_ticks
		var action := "idle"
		if reaction == "Wary":
			if separation < tuning.reaction_distance or (saved.action == "flee" and separation < tuning.flee_release_distance):
				action = "flee"
		elif reaction == "Watching":
			if not in_routine and separation <= tuning.reaction_distance and separation >= tuning.approach_resume_distance and separation > tuning.comfort_distance and tick >= int(memory.move_after):
				action = "approach"
				memory.move_after = tick + tuning.reposition_cooldown_ticks
		elif reaction == "Guarding":
			action = "guard"
		var guard_closing := reaction == "Guarding" and not in_routine and tick >= int(memory.move_after) and separation > tuning.guard_standoff_distance and separation <= tuning.reaction_distance
		if action in ["flee", "approach"] or guard_closing:
			memory.attention_until = tick + tuning.attention_ticks
			memory.routine_until = 0
		var resume := action not in ["flee", "approach"] and not guard_closing and (in_routine or tick >= int(memory.attention_until))
		if resume and not in_routine:
			memory.routine_until = tick + tuning.routine_ticks
			memory.attention_until = 0
		return {"action": action, "goal": player, "response": memory, "resume_patrol": resume, "guard_advance": guard_closing}
	if engaged:
		memory = {"mode": "settling", "until": tick + tuning.settle_ticks, "move_after": 0, "attention_until": 0, "routine_until": 0}
	if memory.get("mode", "") == "settling" and tick < int(memory.until):
		return {"action": "idle", "goal": position, "response": memory}
	return {}

static func caption(reaction: String, row: Dictionary) -> String:
	if row.get("response", {}).get("mode", "") == "settling":
		return "Settling down"
	if row.get("response", {}).get("mode", "") != "alert":
		return {"idle": reaction, "patrol": "Wandering", "return": "Returning home"}.get(row.get("action", "idle"), reaction)
	if row.get("action", "idle") == "patrol":
		return {"Wary": "Roaming cautiously", "Watching": "Exploring nearby", "Guarding": "Patrolling territory"}.get(reaction, "Wandering")
	if reaction == "Wary":
		return "Keeping distance" if row.action == "flee" else "Watching cautiously"
	if reaction == "Watching":
		return "Approaching curiously" if row.action == "approach" else "Watching you"
	return "Defending territory" if reaction == "Guarding" else "Watching surroundings"
