class_name ReadinessTimeline
extends RefCounted
## Deterministic battle-local time. No animation callback mutates this scheduler.
var battle: TacticalBattle
var tuning: ReadinessSettings
var planning := true
var clock := 0.0
var exposure := 0.0
var serial := 0
var events: Array[Dictionary] = []
var steps: Array[Dictionary] = []
var preview: TacticalBattle
var budgets := {"ally": {}, "enemy": {}}
var completed := {"ally": 0, "enemy": 0}
var blackout := false
var reserve_buffer := 0.0

func bind(source: TacticalBattle, settings: ReadinessSettings) -> void:
	battle = source
	tuning = settings.duplicate() if settings != null and settings.valid() else ReadinessSettings.new()
	battle.automatic_enemies = false
	begin_planning()
	push(0.0, "enemy", "ready")

func reset_budget(side: String) -> void:
	battle.turn = side
	battle.actions_remaining = battle.action_points
	battle.remaining = battle.movement_allowance(side)
	battle.disrupted[side] = false
	battle.moved_this_turn[side] = false
	battle.passives.begin_turn(side)
	budgets[side] = {"ap": battle.actions_remaining, "movement": battle.remaining}

func begin_planning() -> void:
	planning = true
	steps.clear()
	reset_budget("ally")
	preview = battle.view_from(battle.view_snapshot())
	preview.automatic_enemies = false

func stage(command: String, target: Vector2i, slot: int = -1, roll: float = 0.0, mode_override: String = "") -> bool:
	if not planning or battle.phase != "active" or steps.size() >= 12: return false
	if steps.any(func(step: Dictionary) -> bool: return step.command == "retreat"): return false
	var accepted := false
	var route: Array = []
	var origin := preview.ally_cell
	var phase: bool = preview.phasing.ally or preview.fields.get(origin, {}).get("kind") == "phase"
	var mode := battle.quantum_mode if mode_override.is_empty() else mode_override
	if mode not in ["position", "stabilize", "entangle"]: return false
	preview.quantum_mode = mode
	match command:
		"move":
			route = preview.reachable().get(target, []).duplicate()
			accepted = preview.move_ally(target)
		"move_slot": accepted = preview.use_move(slot, target)
		"capture":
			accepted = preview.capture_chance() > 0 and preview.actions_remaining >= preview.seal_action_points
			if accepted: preview.actions_remaining -= preview.seal_action_points
		"retreat": accepted = steps.is_empty()
	if not accepted: return false
	if command == "capture":
		var attempts := battle.capture_attempts
		for prior in steps:
			if prior.command == "capture": attempts += 1
		var random := RandomNumberGenerator.new()
		random.seed = battle.capture_seed + attempts * 104729
		roll = random.randf()
	steps.append({"command": command, "target": target, "slot": slot, "route": route, "roll": roll, "mode": mode, "origin": origin, "phase": phase})
	# Preview predicts nominal legality/resources; it never changes authoritative HP.
	preview.phase = "active"
	return true

func clear() -> void:
	if planning:
		# Rebuild the preview without retriggering passives on authoritative state.
		steps.clear()
		preview = battle.view_from(battle.view_snapshot())

func push(at: float, side: String, kind: String, payload: Dictionary = {}) -> void:
	serial += 1
	events.append({"at": at, "side": side, "kind": kind, "serial": serial, "payload": payload.duplicate(true)})
	events.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.serial < b.serial if a.at == b.at else a.at < b.at)

func edit(index: int, offset: int = 0, remove: bool = false) -> bool:
	if not planning or index < 0 or index >= steps.size(): return false
	var proposed := steps.duplicate(true)
	var moved: Dictionary = proposed.pop_at(index)
	if not remove: proposed.insert(clampi(index + offset, 0, proposed.size()), moved)
	var previous := steps.duplicate(true)
	clear()
	for step: Dictionary in proposed:
		if not stage(step.command, step.target, step.slot, float(step.get("roll", 0.0)), str(step.get("mode", "position"))):
			clear()
			for old: Dictionary in previous: stage(old.command, old.target, old.slot, float(old.get("roll", 0.0)), str(old.get("mode", "position")))
			return false
	return true

func schedule(side: String, plan: Array) -> void:
	var at := clock
	for step: Dictionary in plan:
		if step.command == "move":
			var previous: Vector2i = step.get("origin", battle.unit_cell(side))
			for index in range(step.route.size()):
				var cell: Vector2i = step.route[index]
				at += tuning.movement_seconds * maxi(1, TacticalBattle.distance(previous, cell))
				push(at, side, "move", {"target": cell, "phase": step.get("phase", false), "last": index == step.route.size() - 1})
				previous = cell
		else:
			at += tuning.preparation_seconds
			push(at, side, "impact", step)
	push(at + recovery_for(side), side, "ready")

func recovery_for(side: String) -> float:
	return maxf(0.05, tuning.recovery_seconds * 10.0 / maxf(1.0, battle.effective_stat(side, "speed")))

func step_seconds(step: Dictionary) -> float:
	if step.command != "move": return tuning.preparation_seconds
	var distance := 0
	var previous: Vector2i = step.origin
	for cell: Vector2i in step.route:
		distance += maxi(1, TacticalBattle.distance(previous, cell))
		previous = cell
	return tuning.movement_seconds * distance

func commit() -> bool:
	if not planning or battle.phase != "active": return false
	planning = false
	schedule("ally", steps)
	return true

func replace_ally() -> void:
	events = events.filter(func(event: Dictionary) -> bool: return event.side != "ally")
	battle.phase = "active"
	reserve_buffer = tuning.reserve_buffer_seconds
	begin_planning()

func enemy_plan() -> void:
	reset_budget("enemy")
	var choice := battle.plan_enemy()
	var plan: Array[Dictionary] = []
	if not choice.route.is_empty(): plan.append({"command": "move", "route": choice.route, "origin": battle.enemy_cell, "phase": battle.phasing.enemy or battle.fields.get(battle.enemy_cell, {}).get("kind") == "phase"})
	if int(choice.slot) >= 0: plan.append({"command": "move_slot", "slot": int(choice.slot), "target": choice.target})
	schedule("enemy", plan)

func advance(delta: float) -> void:
	if planning or battle.phase != "active" or not is_finite(delta) or delta <= 0: return
	var until := minf(clock + delta, clock + reserve_buffer + maxf(0.0, tuning.blackout_seconds - exposure) / (1.0 - tuning.gear_protection))
	while not events.is_empty() and float(events[0].at) <= until + 0.000000001:
		var event: Dictionary = events.pop_front()
		advance_exposure(maxf(0.0, float(event.at) - clock))
		clock = float(event.at)
		if check_blackout(): return
		resolve(event)
		if planning or battle.phase != "active": return
	advance_exposure(until - clock)
	clock = until
	check_blackout()

func advance_exposure(seconds: float) -> void:
	var protected_time := minf(reserve_buffer, seconds)
	reserve_buffer -= protected_time
	exposure += (seconds - protected_time) * (1.0 - tuning.gear_protection)

func exposure_stage() -> String:
	if blackout: return "Blackout · companions recalled"
	var fraction := exposure / tuning.blackout_seconds
	if fraction >= tuning.severe_fraction: return "Severe exposure · withdraw or prepare a reserve"
	if fraction >= tuning.warning_fraction: return "Exposure warning · consider withdrawing"
	return "Protected" if reserve_buffer > 0 else "Stable"

func withdrawal_ready() -> bool:
	var reach := 1
	for move in battle.moves_for("enemy"): reach = maxi(reach, int(move.reach))
	return TacticalBattle.distance(battle.ally_cell, battle.enemy_cell) > reach

func check_blackout() -> bool:
	if tuning.blackout_seconds - exposure > 0.000000001: return false
	exposure = tuning.blackout_seconds
	blackout = true
	battle.phase = "exhaustion"
	battle.log.append("Commander blackout: emergency Seal recall secures the released companion without healing it.")
	events.clear()
	return true

func resolve(event: Dictionary) -> void:
	var side: String = event.side
	if event.kind == "ready":
		if not budgets[side].is_empty():
			battle.tick_statuses(side)
			battle.passives.end_turn(side)
			battle.end_move_passives(side)
			completed[side] += 1
			if mini(completed.ally, completed.enemy) >= battle.round_number:
				battle.round_number += 1
				battle.tick_fields()
				for participant in ["ally", "enemy"]:
					if int(battle.anchored[participant]) == battle.round_number - 1 and int(battle.anchored[participant]) > 0:
						battle.consequence(participant, "Stable Footing expired", "anchor_expiry", [battle.unit_cell(participant)])
		if battle.ally_hp <= 0 or battle.enemy_hp <= 0:
			battle.phase = "exhaustion" if battle.ally_hp <= 0 else "victory"
			return
		if side == "ally": begin_planning()
		else: enemy_plan()
		return
	battle.turn = side
	battle.actions_remaining = budgets[side].ap
	battle.remaining = budgets[side].movement
	var at: Vector2i = event.payload.target
	if event.kind == "move":
		var origin := battle.unit_cell(side)
		var route: Array[Vector2i] = [at]
		var cost := battle.route_cost(origin, route, side)
		var distance := TacticalBattle.distance(origin, at)
		if event.payload.get("phase", false) and battle.fields.get(origin, {}).get("kind") == "phase": battle.phasing[side] = true
		var middle := origin + Vector2i(signi(at.x - origin.x), signi(at.y - origin.y))
		var phase_hop: bool = distance == 2 and (at.x == origin.x or at.y == origin.y) and event.payload.get("phase", false) and battle.phasing[side] and not battle.passable(middle) and not battle.protected_cells.get(middle, false)
		if (distance == 1 or phase_hop) and battle.can_occupy(side, at) and cost <= battle.actions_remaining + battle.remaining:
			battle.spend_movement(cost)
			battle.mark_movement(side, 1)
			if side == "ally": battle.ally_cell = at
			else: battle.enemy_cell = at
			battle.movement_records(side, route)
		else: battle.log.append("Committed movement blocked; later steps retain their original aim.")
		if event.payload.get("last", false): battle.phasing[side] = false
	elif event.payload.command == "move_slot":
		var slot: int = event.payload.slot
		if side == "ally": battle.quantum_mode = event.payload.get("mode", "position")
		if not battle.execute_move(side, slot, at):
			var move: Dictionary = battle.moves_for(side)[slot]
			if battle.actions_remaining >= SolMove.cost(move) and battle.uses_left(side, move) > 0:
				battle.actions_remaining -= SolMove.cost(move)
				battle.spend_use(side, move)
			battle.log.append("%s: committed aim missed or was blocked." % str(move.name))
	elif side == "ally" and event.payload.command == "capture": battle.attempt_capture(float(event.payload.roll), true)
	elif side == "ally" and event.payload.command == "retreat":
		# Provisional deterministic exit: ready actor must be outside enemy reach.
		if withdrawal_ready(): battle.retreat()
		else: battle.log.append("Withdrawal blocked: move beyond the opponent's reach before committing.")
	budgets[side] = {"ap": battle.actions_remaining, "movement": battle.remaining}
