class_name VastraNatural
extends RefCounted
## Bounded preparation; no terrain/population generation or ownership of live state.

static func empty_schedule() -> Dictionary:
	return {"order": [], "cursor": 0, "last_tick": -1, "recovery_ticks": {}}

static func valid_policy(policy: Dictionary) -> bool:
	return ExpeditionState.keys_match(policy, ["interval", "points", "work_limit"]) and SolSpeciesDefinition.whole(policy.interval, 1, 1000000) and SolSpeciesDefinition.whole(policy.points, 0, 100) and SolSpeciesDefinition.whole(policy.work_limit, 1, 1024)

static func valid_schedule(data: Variant, tiles: Dictionary, tick: int) -> bool:
	if not data is Dictionary or not ExpeditionState.keys_match(data, ["order", "cursor", "last_tick", "recovery_ticks"]):
		return false
	if not data.order is Array or data.order.size() != tiles.size() or not SolSpeciesDefinition.whole(data.cursor, 0, maxi(0, data.order.size() - 1)) or not SolSpeciesDefinition.whole(data.last_tick, -1, tick) or not data.recovery_ticks is Dictionary or data.recovery_ticks.size() > tiles.size():
		return false
	var seen: Dictionary = {}
	for key in data.order:
		if not key is String or not tiles.has(key) or seen.has(key):
			return false
		seen[key] = true
	for key in data.recovery_ticks:
		if not tiles.has(key) or tiles[key].get("overload", 0) <= 0 or not SolSpeciesDefinition.whole(data.recovery_ticks[key], 0, tick):
			return false
	return true

static func prepare(tiles: Dictionary, schedule: Dictionary, tick: int, policy: Dictionary, resolver: Callable) -> Dictionary:
	if not valid_policy(policy):
		return {}
	if schedule.last_tick == tick or schedule.order.is_empty():
		return {"processed": 0}
	var cursor := int(schedule.cursor)
	var changes: Dictionary = {}
	var stamps: Dictionary = {}
	var regional_spent: Dictionary = {}
	var profiles: Dictionary = {}
	var processed := 0
	for index in range(mini(int(policy.work_limit), schedule.order.size())):
		var key: String = schedule.order[cursor]
		var tile: Dictionary = tiles[key].duplicate(true)
		# An unknown profile still permits independent overload recovery.
		var profile: Variant = resolver.call(key) if resolver.is_valid() else {}
		if not profile is Dictionary:
			return {}
		if not profile.is_empty():
			if not ExpeditionState.keys_match(profile, ["region", "equilibrium", "budget"]) or not SolSpeciesDefinition.text(profile.region) or not SolSpeciesDefinition.whole(profile.equilibrium, 0, 100) or not SolSpeciesDefinition.whole(profile.budget, 0, 100):
				return {}
			if profiles.has(profile.region) and profiles[profile.region] != profile:
				return {} # One stable region cannot supply contradictory tuning in a tick.
			profiles[profile.region] = profile.duplicate(true)
			if profiles.size() > 128:
				return {}
			if tile.has("concentration"):
				var difference := int(profile.equilibrium) - int(tile.concentration)
				var used := int(regional_spent.get(profile.region, 0))
				if difference != 0 and profile.budget > 0 and used >= profile.budget:
					break # Keep this record first next tick; its elapsed recovery debt survives.
				var amount := mini(absi(difference), mini(maxi(0, int(profile.budget) - used), 1))
				tile.concentration += amount if difference > 0 else -amount
				regional_spent[profile.region] = used + amount
		var since: Variant = schedule.recovery_ticks.get(key)
		if tile.get("overload", 0) > 0 and policy.points > 0:
			if since == null:
				since = tick # Never grant an invented age to legacy damage.
			else:
				@warning_ignore("integer_division")
				var intervals: int = (tick - int(since)) / int(policy.interval)
				# Integer arithmetic remains exact even at the JSON clock ceiling.
				tile.overload = maxi(0, int(tile.overload) - mini(intervals, 100) * int(policy.points))
				since = int(since) + intervals * int(policy.interval)
		stamps[key] = since if tile.get("overload", 0) > 0 else null
		if tile != tiles[key]:
			changes[key] = tile
		cursor = (cursor + 1) % schedule.order.size()
		processed += 1
	return {"processed": processed, "cursor": cursor, "changes": changes, "stamps": stamps}
