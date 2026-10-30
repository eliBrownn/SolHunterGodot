class_name VesselEcology
extends RefCounted
## Bounded transaction preparation. ExpeditionState alone commits plants, signals and swarms.
const LIMIT := 128
const STATES := ["ordinary", "investigating", "responding", "escalating", "recovering"]

static func empty() -> Dictionary:
	return {"version": 1, "policy": null, "last_tick": -1, "serial": 0, "groups": {}, "signals": {}, "memories": {}, "carriers": {}, "drawn": 0.0, "spent": 0.0}

static func normalized(data: Dictionary) -> Dictionary:
	var result := data.duplicate(true)
	for key in ["version", "last_tick", "serial"]: result[key] = int(result[key])
	for key in ["drawn", "spent"]: result[key] = float(result[key])
	if result.policy != null:
		for key in result.policy:
			if key != "enabled": result.policy[key] = int(result.policy[key])
	for row: Dictionary in result.groups.values():
		row.cell = [int(row.cell[0]), int(row.cell[1])]
		row.energy = float(row.energy)
		for key in ["since", "until", "last_signal", "baseline", "blocked", "storm_until", "storm_checked"]: row[key] = int(row[key])
	for row: Dictionary in result.signals.values():
		for key in ["id", "created", "expires"]: row[key] = int(row[key])
	for name in ["memories", "carriers"]:
		for key in result[name]: result[name][key] = int(result[name][key])
	return result

static func cell(row: Dictionary) -> Vector2i:
	return Vector2i(int(row.cell[0]), int(row.cell[1]))

static func finite(value: Variant, maximum: float = ExpeditionContract.MAX_SAFE_INTEGER) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and value >= 0 and value <= maximum

static func valid(data: Variant, tick: int, flora: Dictionary) -> bool:
	if not data is Dictionary or not RecordShape.keys_match(data, ["version", "policy", "last_tick", "serial", "groups", "signals", "memories", "carriers", "drawn", "spent"]): return false
	if not SolSpeciesDefinition.whole(data.version, 1, 1) or not SolSpeciesDefinition.whole(data.last_tick, -1, tick) or not SolSpeciesDefinition.whole(data.serial, 0, ExpeditionContract.MAX_SAFE_INTEGER): return false
	if data.policy != null and not VesselSettings.valid_policy(data.policy): return false
	for name in ["groups", "signals", "memories", "carriers"]:
		if not data[name] is Dictionary or data[name].size() > (PlantVastra.MAX_FLIGHTS if name == "carriers" else LIMIT): return false
	if not finite(data.drawn) or not finite(data.spent) or data.drawn > float(flora.spent) + 0.001: return false
	if data.policy == null and (not data.groups.is_empty() or not data.signals.is_empty() or data.drawn != 0 or data.spent != 0): return false
	var accounted := float(data.spent)
	for id in data.groups:
		var row: Variant = data.groups[id]
		if not row is Dictionary or not RecordShape.keys_match(row, ["id", "home", "cell", "state", "since", "until", "energy", "last_signal", "baseline", "blocked", "storm_until", "storm_checked"]): return false
		if not id is String or row.id != id or not row.home is String or not flora.nodes.has(row.home) or row.cell != flora.nodes[row.home].cell or row.state not in STATES: return false
		var owner := FloraCatalog.region(cell(row))
		if id != "vessel:%d:%d" % [owner.x, owner.y]: return false
		if not finite(row.energy, 100) or not SolSpeciesDefinition.whole(row.since, 0, tick) or not SolSpeciesDefinition.whole(row.until, 0, ExpeditionContract.MAX_SAFE_INTEGER): return false
		if not SolSpeciesDefinition.whole(row.last_signal, 0, data.serial) or not SolSpeciesDefinition.whole(row.storm_checked, 0, data.serial): return false
		if not SolSpeciesDefinition.whole(row.baseline, 0, 100) or not SolSpeciesDefinition.whole(row.blocked, 0, 120) or not SolSpeciesDefinition.whole(row.storm_until, 0, ExpeditionContract.MAX_SAFE_INTEGER): return false
		if data.policy == null: return false
		var duration := 0
		match row.state:
			"investigating": duration = 2
			"responding", "escalating": duration = int(data.policy.response_ticks)
			"recovering": duration = int(data.policy.recovery_ticks)
		if int(row.until) != (0 if row.state == "ordinary" else int(row.since) + duration): return false
		if int(row.storm_until) > 0 and (int(row.storm_checked) == 0 or int(data.policy.storm_chance_percent) == 0 or int(row.storm_until) > tick + int(data.policy.storm_ticks)): return false
		accounted += float(row.energy)
	for id in data.signals:
		var row: Variant = data.signals[id]
		if not row is Dictionary or not RecordShape.keys_match(row, ["id", "origin", "created", "expires", "cause", "seen"]): return false
		if not SolSpeciesDefinition.whole(row.id, 1, data.serial) or str(int(row.id)) != id or not flora.nodes.has(row.origin): return false
		if not SolSpeciesDefinition.whole(row.created, 0, tick) or not SolSpeciesDefinition.whole(row.expires, int(row.created) + 1, ExpeditionContract.MAX_SAFE_INTEGER) or row.cause not in ["overload", "stranded_flow"]: return false
		if data.policy == null or int(row.expires) != int(row.created) + int(data.policy.signal_lifetime_ticks) or not row.seen is Dictionary or row.seen.size() > LIMIT: return false
		for node in row.seen:
			if not flora.nodes.has(node) or row.seen[node] != true: return false
	for node in data.memories:
		if not flora.nodes.has(node) or not SolSpeciesDefinition.whole(data.memories[node], 1, data.serial) or not data.signals.has(str(int(data.memories[node]))): return false
	var flights := {}
	for flight: Dictionary in flora.flights: flights[str(int(flight.id))] = true
	for carrier in data.carriers:
		if not flights.has(carrier) or not SolSpeciesDefinition.whole(data.carriers[carrier], 1, data.serial) or not data.signals.has(str(int(data.carriers[carrier]))): return false
	return absf(accounted - float(data.drawn)) < 0.01

static func prepare(data: Dictionary, flora: Dictionary, active: Array[String], arrivals: Array, tick: int, seed: int, environment: Callable, protected: Callable = Callable(), storm_allowed: bool = false, region_index: Dictionary = {}) -> Dictionary:
	if data.policy == null or not data.policy.enabled or data.last_tick == tick: return {}
	var next: Dictionary = data.duplicate(true)
	var policy: Dictionary = next.policy
	next.last_tick = tick
	var changes := {}
	var overloads := {}
	var activities := {}
	var plant_spent := 0.0
	# Expiry follows the shared active clock, even for groups outside service range.
	for key: String in next.signals.keys():
		if int(next.signals[key].expires) <= tick: next.signals.erase(key)
	for key in next.memories.keys():
		if not next.signals.has(str(int(next.memories[key]))): next.memories.erase(key)
	for key in next.carriers.keys():
		if not next.signals.has(str(int(next.carriers[key]))): next.carriers.erase(key)
	var active_regions := {}
	# This derived index is rebuilt by ExpeditionState only when active flora changes.
	# Direct domain callers may omit it; neither path depends on render visibility.
	var buckets: Dictionary = region_index
	if buckets.is_empty() and not active.is_empty():
		buckets = {}
		for id in active:
			var owner := FloraCatalog.region(cell(flora.nodes[id]))
			if not buckets.has(owner): buckets[owner] = []
			buckets[owner].append(id)
	for owner: Vector2i in buckets:
		var group_id := "vessel:%d:%d" % [owner.x, owner.y]
		active_regions[group_id] = true
		if next.groups.has(group_id) or next.groups.size() >= LIMIT: continue
		for id: String in buckets[owner]:
			var row: Dictionary = flora.nodes[id]
			if row.kind != "plant" or FloraTraits.role(seed, row) != "emanator": continue
			next.groups[group_id] = {"id": group_id, "home": id, "cell": row.cell.duplicate(), "state": "ordinary", "since": tick, "until": 0, "energy": 0.0, "last_signal": 0, "baseline": 0, "blocked": 0, "storm_until": 0, "storm_checked": 0}
			break
	# Real finite packet arrival is the only way a trace crosses a rooted connection.
	for flight: Dictionary in arrivals:
		var key := str(int(flight.id))
		var event_id := str(int(next.carriers.get(key, 0)))
		next.carriers.erase(key)
		if not next.signals.has(event_id): continue
		var event: Dictionary = next.signals[event_id]
		if event.seen.has(flight.target) or event.seen.size() >= LIMIT: continue
		event.seen[flight.target] = true
		if next.memories.size() < LIMIT or next.memories.has(flight.target): next.memories[flight.target] = event.id
	# A bounded local sample gives specialist plants a real, paid first function.
	for offset in range(mini(64, active.size())):
		var id: String = active[(int(flora.cursor) + offset) % active.size()]
		var row: Dictionary = flora.nodes[id]
		if FloraTraits.category(seed, row) != "mender": continue
		var at := cell(row)
		var damage := local_overload(at, overloads, environment)
		if damage <= 0 or not debit(id, 2.0, flora, changes): continue
		plant_spent += 2.0
		overloads[AffinityImprint.key(at)] = maxi(0, damage - 1)
		activities[id] = "repairing"
	var group_ids: Array = active_regions.keys()
	group_ids.sort()
	var count := 0
	for group_id: String in group_ids:
		if not next.groups.has(group_id) or count >= int(policy.group_limit): continue
		count += 1
		var group: Dictionary = next.groups[group_id]
		var at := cell(group)
		var nearby: Array[String] = []
		var peak := 0
		var backlog := 0.0
		for y in range(-1, 2):
			for x in range(-1, 2): peak = maxi(peak, local_overload(at + Vector2i(x, y), overloads, environment))
		var low := FloraCatalog.region(at - Vector2i(4, 4))
		var high := FloraCatalog.region(at + Vector2i(4, 4))
		for y in range(low.y, high.y + 1):
			for x in range(low.x, high.x + 1):
				for id: String in buckets.get(Vector2i(x, y), []):
					var row: Dictionary = changes.get(id, flora.nodes[id])
					if cell(row).distance_squared_to(at) > 16: continue
					nearby.append(id)
					backlog += float(row.roots)
		nearby.sort_custom(func(a: String, b: String) -> bool:
			var ar: float = float(changes.get(a, flora.nodes[a]).roots)
			var br: float = float(changes.get(b, flora.nodes[b]).roots)
			return a < b if ar == br else ar > br)
		# Feeding transfers accounted plant energy; it cannot fill a reserve from a signal.
		for id in nearby:
			var amount := minf(float(policy.feed_per_tick), 100.0 - float(group.energy))
			var row: Dictionary = changes.get(id, flora.nodes[id])
			# Feeding preserves a source reserve, so swarms cannot starve all grass before its first transfer.
			amount = minf(amount, float(row.roots) + maxf(0.0, float(row.energy) - 50.0))
			if amount > 0 and debit(id, amount, flora, changes):
				group.energy += amount
				next.drawn += amount
				break
		group.blocked = mini(120, int(group.blocked) + 1) if backlog >= float(policy.stranded_energy) else 0
		var stimulus: bool = peak > 0 or int(group.blocked) >= int(policy.blockage_ticks)
		var fresh: bool = peak > int(group.baseline) or int(group.blocked) == int(policy.blockage_ticks)
		if fresh and next.signals.size() < LIMIT and int(next.serial) < ExpeditionContract.MAX_SAFE_INTEGER:
			next.serial += 1
			var event_id := str(int(next.serial))
			next.signals[event_id] = {"id": next.serial, "origin": group.home, "created": tick, "expires": tick + int(policy.signal_lifetime_ticks), "cause": "overload" if peak > 0 else "stranded_flow", "seen": {group.home: true}}
			if next.memories.size() < LIMIT or next.memories.has(group.home): next.memories[group.home] = next.serial
		var heard := 0
		for id in nearby: heard = maxi(heard, int(next.memories.get(id, 0)))
		if group.state == "recovering" and tick >= int(group.until): set_state(group, "ordinary", tick, 0)
		if group.state == "ordinary" and heard > int(group.last_signal):
			group.last_signal = heard
			set_state(group, "investigating", tick, tick + 2)
		elif group.state == "investigating" and tick >= int(group.until):
			var can_respond: bool = stimulus and group.energy >= policy.response_cost
			set_state(group, "responding" if can_respond else "recovering", tick, tick + int(policy.response_ticks if can_respond else policy.recovery_ticks))
		elif group.state in ["responding", "escalating"]:
			if not stimulus or tick >= int(group.until) or group.energy < policy.response_cost:
				set_state(group, "recovering", tick, tick + int(policy.recovery_ticks))
			else:
				group.energy -= float(policy.response_cost)
				next.spent += float(policy.response_cost)
				# Ordinary defense relieves stranded stock through real consumption.
				var age := tick - int(group.since)
				if age >= 3: group.state = "escalating"
				var moderated := false
				for id in nearby:
					if FloraTraits.category(seed, flora.nodes[id]) == "regulator" and debit(id, 1.0, flora, changes):
						plant_spent += 1.0
						activities[id] = "regulating"
						moderated = true
						break
				if moderated and age >= 3: set_state(group, "recovering", tick, tick + int(policy.recovery_ticks))
				elif group.state == "escalating":
					for y in range(-1, 2):
						for x in range(-1, 2):
							var target := at + Vector2i(x, y)
							if protected.is_valid() and protected.call(target): continue
							var blocked := false
							for id in nearby:
								if cell(flora.nodes[id]).distance_squared_to(target) <= 4 and FloraTraits.category(seed, flora.nodes[id]) == "warden" and debit(id, 1.0, flora, changes):
									plant_spent += 1.0
									activities[id] = "protecting"
									blocked = true
									break
							if not blocked:
								var old := local_overload(target, overloads, environment)
								# Preserve negative restorative conditions; never flip them with a cosmetic response.
								if old >= 0: overloads[AffinityImprint.key(target)] = mini(100, old + int(policy.escalation_overload))
		# One deterministic admission attempt per response event, never per render frame.
		if storm_allowed and group.state == "escalating" and group.last_signal > group.storm_checked and storm_eligible(at, overloads, environment, protected, int(policy.storm_threshold)):
			group.storm_checked = group.last_signal
			if absi(hash("vessel-storm:%d:%s:%d" % [seed, group_id, int(group.last_signal)])) % 100 < int(policy.storm_chance_percent): group.storm_until = tick + int(policy.storm_ticks)
	# Record final conditions so the swarm's own discharge is not a fresh external alarm.
	for group_id: String in group_ids:
		if not next.groups.has(group_id): continue
		var group: Dictionary = next.groups[group_id]
		var peak := 0
		for y in range(-1, 2):
			for x in range(-1, 2): peak = maxi(peak, local_overload(cell(group) + Vector2i(x, y), overloads, environment))
		group.baseline = peak
	var pending := {}
	for flight: Dictionary in flora.flights:
		var key := str(int(flight.id))
		pending[key] = true
		if next.carriers.has(key): continue
		var event_id := str(int(next.memories.get(flight.source, 0)))
		if next.signals.has(event_id) and not next.signals[event_id].seen.has(flight.target): next.carriers[key] = int(event_id)
	for key in next.carriers.keys():
		if not pending.has(key): next.carriers.erase(key)
	return {"ecology": next, "plants": changes, "overloads": overloads, "plant_spent": plant_spent, "drawn": float(next.drawn) - float(data.drawn), "activities": activities}

static func debit(id: String, amount: float, flora: Dictionary, changes: Dictionary) -> bool:
	var row: Dictionary = changes.get(id, flora.nodes[id])
	if float(row.energy) + float(row.roots) < amount: return false
	row = row.duplicate(true)
	var root := minf(amount, float(row.roots))
	row.roots -= root
	row.energy -= amount - root
	changes[id] = row
	return true

static func local_overload(at: Vector2i, changes: Dictionary, environment: Callable) -> int:
	var key := AffinityImprint.key(at)
	return int(changes[key]) if changes.has(key) else int(environment.call(at).overload)

static func set_state(group: Dictionary, state: String, tick: int, until: int) -> void:
	group.state = state
	group.since = tick
	group.until = until

static func storm_eligible(at: Vector2i, changes: Dictionary, environment: Callable, protected: Callable, threshold: int) -> bool:
	if not protected.is_valid(): return false # Unknown access protection fails closed.
	for y in range(-1, 2):
		for x in range(-1, 2):
			var target := at + Vector2i(x, y)
			if protected.call(target) or local_overload(target, changes, environment) < threshold: return false
	return true

static func observe(group: Dictionary) -> String:
	match group.state:
		"investigating": return "Small groups keep turning toward the same patch."
		"responding": return "The swarm gathers around this patch, releasing short pulses."
		"escalating": return "Repeated discharges spread beyond the patch. The swarm shows little sign of settling."
		"recovering": return "The swarm is spreading out and settling among the leaves."
	return "A loose swarm moves between the grass and nearby roots."
