extends RefCounted
## Development policy only. No live controller, player advice, production AI or balance changes.

static func fork(source: TacticalBattle) -> TacticalBattle:
	var copy := TacticalBattle.new()
	for property: Dictionary in source.get_property_list():
		if int(property.usage) & PROPERTY_USAGE_SCRIPT_VARIABLE and property.name != "passives":
			var value: Variant = source.get(property.name)
			copy.set(property.name, value.duplicate(true) if value is Dictionary or value is Array else value)
	copy.passives = BattleClassPassives.new(copy, source.passives.settings)
	copy.passives.units = source.passives.units.duplicate(true)
	copy.automatic_enemies = true
	return copy

static func action(command: String, target: Vector2i, slot: int = -1, reason: String = "") -> Dictionary:
	return {"command": command, "target": target, "slot": slot, "reason": reason}

static func phase_route(battle: TacticalBattle) -> Array:
	var routes := battle.paths(battle.ally_cell, battle.cells.size() * maxi(battle.rough_cost, battle.resisted_cost) * 2, battle.enemy_cell, true, "ally")
	var best: Array = []
	var cost := INF
	var positions: Array = routes.keys()
	positions.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.y < b.y if a.y != b.y else a.x < b.x)
	for at: Vector2i in positions:
		if battle.can_use_for("ally", 0, battle.enemy_cell, at):
			var candidate := battle.route_cost(battle.ally_cell, routes[at], "ally")
			if candidate < cost:
				cost = candidate
				best = routes[at]
	return best.duplicate()

static func choose(battle: TacticalBattle, tactical: bool, used: Dictionary) -> Dictionary:
	# Finish a legal lethal hit before considering healing. No simulated capture/RNG.
	for slot in range(battle.moves_for("ally").size()):
		var move: Dictionary = battle.moves_for("ally")[slot]
		if move.effect == "damage" and battle.can_use(slot, battle.enemy_cell) and battle.damage_for("ally", move, battle.ally_cell) >= battle.enemy_hp:
			return action("move_slot", battle.enemy_cell, slot, "Finish the opponent before another response")
	if tactical:
		# Prepare once during a safe approach, rather than spending a contested turn
		# blindly refreshing a weak buff. The existing enemy planner supplies the threat.
		for slot in range(battle.ally_moves.size()):
			var move: Dictionary = battle.ally_moves[slot]
			if move.effect != "buff" or used.has(move.id) or battle.can_use(0, battle.enemy_cell) or not battle.can_use(slot, battle.ally_cell): continue
			var threat := battle.plan_enemy()
			if int(threat.slot) < 0 or battle.moves_for("enemy")[threat.slot].effect != "damage":
				used[move.id] = true
				return action("move_slot", battle.ally_cell, slot, "Use a safe approach turn to prepare special offense")
		if not battle.phasing.ally:
			for slot in range(battle.ally_moves.size()):
				if battle.ally_moves[slot].effect != "phase" or not battle.can_use(slot, battle.ally_cell): continue
				var normal := battle.approach_route("ally")
				var crossing := phase_route(battle)
				if crossing.is_empty() or (not normal.is_empty() and battle.route_cost(battle.ally_cell, normal, "ally") <= battle.route_cost(battle.ally_cell, crossing, "ally") + battle.movement): continue
				var available := battle.reachable()
				var launch := battle.ally_cell
				var previous := battle.ally_cell
				for at: Vector2i in crossing:
					if TacticalBattle.distance(previous, at) > 1: break
					if available.has(at): launch = at
					previous = at
				if launch != battle.ally_cell:
					return action("move", launch, -1, "Approach a legal thin-wall crossing")
				return action("move_slot", battle.ally_cell, slot, "Spend an action to save more than one turn of detour movement")
	# A single detached rule execution evaluates actual capped healing and the full
	# automatic response, including poison/fields/passives. Net-zero healing is still
	# legal gameplay; this particular diagnostic policy chooses progress instead.
	for slot in range(battle.ally_moves.size()):
		var move: Dictionary = battle.ally_moves[slot]
		if move.effect != "heal" or battle.ally_hp > int(battle.ally.max_hp) / 3 or not battle.can_use(slot, battle.ally_cell): continue
		var preview := fork(battle)
		var healed := preview.use_move(slot, preview.ally_cell)
		if healed and preview.phase == "active":
			preview.wait_turn()
		if healed and preview.ally_hp > 0 and (preview.ally_hp > battle.ally_hp or preview.enemy_hp < battle.enemy_hp):
			return action("move_slot", battle.ally_cell, slot, "Healing improves retained HP or lets an ongoing effect progress")
		used.nonprogress_heals_skipped = int(used.get("nonprogress_heals_skipped", 0)) + 1
	for slot in range(battle.moves_for("ally").size()):
		if battle.moves_for("ally")[slot].effect == "damage" and battle.can_use(slot, battle.enemy_cell):
			return action("move_slot", battle.enemy_cell, slot, "Use a legal offensive action")
	var destination := battle.ally_cell
	var available := battle.reachable()
	for at: Vector2i in battle.approach_route("ally"):
		if available.has(at): destination = at
	return action("move", destination, -1, "Follow the legal offensive route") if destination != battle.ally_cell else action("wait", battle.ally_cell, -1, "No useful action or offensive route")
