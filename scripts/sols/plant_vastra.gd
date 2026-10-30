class_name PlantVastra
extends RefCounted
## Pure bounded energy transactions. ExpeditionState owns the ledger and commits.
const VERSION := 2
const MAX_NODES := 32768
const MAX_FLIGHTS := 1024
const MAX_ENERGY := 1000000000.0

static func empty() -> Dictionary:
	return {"version": VERSION, "policy": null, "nodes": {}, "flights": [], "fed": {}, "cursor": 0, "last_tick": -1, "serial": 0, "absorbed": 0.0, "spent": 0.0}

static func valid_policy(p: Variant) -> bool:
	if not p is Dictionary or not RecordShape.keys_match(p, ["threshold", "refill", "repair_cost", "repair_points", "speed", "work_limit", "active_radius", "ground_reach", "tree_reach", "root_rate", "feeding_rate", "feeding_radius"]): return false
	for key in ["refill", "repair_cost", "speed", "ground_reach", "tree_reach", "root_rate", "feeding_rate", "feeding_radius"]:
		if not (p[key] is int or p[key] is float) or not is_finite(float(p[key])): return false
	if p.root_rate < 0 or p.root_rate > 100 or p.feeding_rate < 0 or p.feeding_rate > 100 or p.feeding_radius < 0.25 or p.feeding_radius > 8: return false
	return SolSpeciesDefinition.whole(p.threshold, 1, 1000) and p.refill >= 0 and p.refill <= 100 and p.repair_cost >= 1 and p.repair_cost <= 1000 and SolSpeciesDefinition.whole(p.repair_points, 0, 10) and p.speed >= 0.05 and p.speed <= 4 and SolSpeciesDefinition.whole(p.work_limit, 1, 256) and SolSpeciesDefinition.whole(p.active_radius, 0, 1) and p.ground_reach >= 1 and p.ground_reach <= 8 and p.tree_reach >= p.ground_reach and p.tree_reach <= 32

static func valid_definition(row: Variant) -> bool:
	return row is Dictionary and RecordShape.keys_match(row, ["id", "cell", "kind"]) and row.kind in ["plant", "tree"] and row.cell is Array and row.cell.size() == 2 and SolSpeciesDefinition.whole(row.cell[0], -1000000, 1000000) and SolSpeciesDefinition.whole(row.cell[1], -1000000, 1000000) and row.id == AffinityImprint.key(Vector2i(int(row.cell[0]), int(row.cell[1])))

static func valid(data: Variant, tick: int) -> bool:
	if not data is Dictionary or not RecordShape.keys_match(data, ["version", "policy", "nodes", "flights", "fed", "cursor", "last_tick", "serial", "absorbed", "spent"]): return false
	if not data.fed is Dictionary or data.fed.size() > ExpeditionContract.MAX_INDIVIDUALS: return false
	for id in data.fed:
		if not id is String or not (data.fed[id] is float or data.fed[id] is int) or not is_finite(float(data.fed[id])) or data.fed[id] < 0 or data.fed[id] > ExpeditionContract.MAX_SAFE_INTEGER: return false
	if not SolSpeciesDefinition.whole(data.version, VERSION, VERSION) or (data.policy != null and not valid_policy(data.policy)) or not data.nodes is Dictionary or data.nodes.size() > MAX_NODES or not data.flights is Array or data.flights.size() > MAX_FLIGHTS or not SolSpeciesDefinition.whole(data.cursor, 0, MAX_NODES) or not SolSpeciesDefinition.whole(data.last_tick, -1, tick) or not SolSpeciesDefinition.whole(data.serial, 0, ExpeditionContract.MAX_SAFE_INTEGER): return false
	for key in ["absorbed", "spent"]:
		if not (data[key] is float or data[key] is int) or not is_finite(float(data[key])) or data[key] < 0 or data[key] > ExpeditionContract.MAX_SAFE_INTEGER: return false
	var emission_count := 0
	for id in data.nodes:
		var row: Variant = data.nodes[id]
		if not row is Dictionary or not RecordShape.keys_match(row, ["id", "cell", "kind", "energy", "roots", "since", "emissions"]): return false
		if not (row.roots is float or row.roots is int) or not is_finite(float(row.roots)) or row.roots < 0 or row.roots > MAX_ENERGY or (row.kind != "tree" and row.roots != 0): return false
		if not valid_definition({"id": row.id, "cell": row.cell, "kind": row.kind}) or id != row.id or not (row.energy is float or row.energy is int) or not is_finite(float(row.energy)) or row.energy < 0 or row.energy > MAX_ENERGY or not SolSpeciesDefinition.whole(row.since, 0, tick) or not SolSpeciesDefinition.whole(row.emissions, 0, ExpeditionContract.MAX_SAFE_INTEGER): return false
		if data.policy == null or row.energy > data.policy.threshold: return false
		emission_count += int(row.emissions)
		if emission_count > int(data.serial): return false
	if emission_count != int(data.serial): return false
	var seen := {}
	var reserved := {}
	for flight in data.flights:
		if not flight is Dictionary or not RecordShape.keys_match(flight, ["id", "source", "target", "amount", "sent", "arrival", "distance", "root"]): return false
		if not flight.root is bool or not (flight.amount is int or flight.amount is float) or not is_finite(float(flight.amount)) or flight.amount <= 0 or flight.amount > 1000: return false
		if not SolSpeciesDefinition.whole(flight.id, 1, data.serial) or seen.has(flight.id) or not data.nodes.has(flight.source) or not data.nodes.has(flight.target) or flight.source == flight.target or not SolSpeciesDefinition.whole(flight.sent, 0, tick) or not SolSpeciesDefinition.whole(flight.arrival, int(flight.sent) + 1, ExpeditionContract.MAX_SAFE_INTEGER) or not (flight.distance is float or flight.distance is int) or not is_finite(float(flight.distance)) or flight.distance <= 0 or flight.distance > 64: return false
		if data.policy == null: return false
		var origin: Array = data.nodes[flight.source].cell
		var destination: Array = data.nodes[flight.target].cell
		var actual_distance := Vector2(origin[0], origin[1]).distance_to(Vector2(destination[0], destination[1]))
		if absf(float(flight.distance) - actual_distance) > 0.0001 or int(flight.arrival) != int(flight.sent) + maxi(1, ceili(actual_distance / float(data.policy.speed) / ExpeditionContract.ACTIVITY_INTERVAL)): return false
		if flight.root:
			if data.nodes[flight.source].kind != "tree" or data.nodes[flight.target].kind != "plant" or flight.amount > data.policy.threshold or flight.distance > data.policy.ground_reach: return false
			reserved[flight.target] = float(reserved.get(flight.target, 0.0)) + float(flight.amount)
		elif data.nodes[flight.target].kind != "tree" or flight.amount != data.policy.threshold: return false
		seen[flight.id] = true
	for id in reserved:
		if float(data.nodes[id].energy) + float(reserved[id]) > float(data.policy.threshold) + 0.0001: return false
	var accounted := float(data.spent)
	for row: Dictionary in data.nodes.values(): accounted += float(row.energy) + float(row.roots)
	for flight: Dictionary in data.flights: accounted += float(flight.amount)
	for amount in data.fed.values(): accounted += float(amount)
	if absf(accounted - float(data.absorbed)) > 0.1: return false
	return true

## Equal chance among all eligible trees, including already-full trees. Energy,
## overload and target health are intentionally absent from the selection inputs.
static func choose_target(source: Dictionary, trees: Array, seed: int, serial: int) -> Dictionary:
	var candidates: Array[Dictionary] = []
	for row: Dictionary in trees:
		if row.kind == "tree" and row.id != source.id: candidates.append(row)
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.id < b.id)
	if candidates.is_empty(): return {}
	var rng := RandomNumberGenerator.new()
	rng.seed = absi(hash("plant-vastra:%d:%s:%d" % [seed, source.id, serial]))
	return candidates[rng.randi_range(0, candidates.size() - 1)]

## Resolve arrivals before servicing charged sources. At most one emission per
## visited source/tick; finite travel time prevents instantaneous relay loops.
static func prepare(data: Dictionary, tick: int, seed: int, active: Array[String], resolver: Callable, environment: Callable, plants: Callable = Callable(), feeders: Array[Dictionary] = [], classified: bool = false) -> Dictionary:
	var policy: Dictionary = data.policy
	if not valid_policy(policy): return {}
	if data.last_tick == tick: return {"noop": true}
	var changes := {}
	var remaining: Array = []
	var arrivals: Array = []
	var emissions: Array = []
	var repairs := {}
	var absorbed := 0.0
	var spent := 0.0
	var serial := int(data.serial)
	var fed: Dictionary = data.fed.duplicate()
	var feeding_left := {}
	for feeder in feeders: feeding_left[feeder.id] = float(policy.feeding_rate) * ExpeditionContract.ACTIVITY_INTERVAL
	for flight: Dictionary in data.flights:
		if flight.arrival > tick or arrivals.size() >= int(policy.work_limit):
			remaining.append(flight)
			continue
		var target: Dictionary = changes.get(flight.target, data.nodes[flight.target]).duplicate(true)
		var overflow := maxf(0.0, float(target.energy) + float(flight.amount) - float(policy.threshold))
		if (target.kind != "tree" and overflow > 0.0001) or target.roots + overflow > MAX_ENERGY:
			remaining.append(flight) # Technical safety bound defers credit without losing energy.
			continue
		target.energy += flight.amount
		if target.kind == "tree":
			target.roots += overflow
			target.energy = minf(target.energy, policy.threshold)
		else:
			target.energy = minf(target.energy, policy.threshold) # Clamp only floating-point roundoff after reserved arrivals.
		changes[flight.target] = target
		arrivals.append(flight)
	var cursor := int(data.cursor) % maxi(1, active.size())
	var incoming := {}
	for flight: Dictionary in remaining:
		if flight.root: incoming[flight.target] = float(incoming.get(flight.target, 0.0)) + float(flight.amount)
	for index in range(mini(int(policy.work_limit), active.size())):
		var id: String = active[cursor]
		cursor = (cursor + 1) % active.size()
		if not data.nodes.has(id): continue
		var row: Dictionary = changes.get(id, data.nodes[id]).duplicate(true)
		var cell := Vector2i(int(row.cell[0]), int(row.cell[1]))
		var conditions: Dictionary = environment.call(cell)
		# Admission/reactivation stamps since=current tick: no invented offline charge.
		var elapsed := maxi(0, tick - int(row.since)) * ExpeditionContract.ACTIVITY_INTERVAL
		var gain := minf(maxf(0.0, policy.threshold - float(row.energy) - float(incoming.get(id, 0.0))), elapsed * float(policy.refill) * float(conditions.concentration) / 100.0)
		# In classified worlds, only grass emanates; receivers and reservoirs need arrivals.
		if classified and FloraTraits.role(seed, row) != "emanator": gain = 0.0
		row.energy += gain
		absorbed += gain
		row.since = tick
		var damage := maxi(0, int(conditions.overload) - int(repairs.get(id, 0)))
		var healed := mini(damage, mini(int(policy.repair_points), floori(float(row.energy) / float(policy.repair_cost))))
		if healed > 0:
			row.energy -= healed * float(policy.repair_cost)
			spent += healed * float(policy.repair_cost)
			repairs[id] = healed
		if row.energy >= policy.threshold and remaining.size() < MAX_FLIGHTS and serial < ExpeditionContract.MAX_SAFE_INTEGER:
			var reach: float = policy.tree_reach if row.kind == "tree" else policy.ground_reach
			var trees: Variant = resolver.call(cell, reach)
			if trees is Array:
				var chosen := choose_target(row, trees, seed, int(row.emissions))
				if not chosen.is_empty() and data.nodes.has(chosen.id):
					var distance := Vector2(cell).distance_to(Vector2(chosen.cell[0], chosen.cell[1]))
					var travel_ticks := maxi(1, ceili(distance / float(policy.speed) / ExpeditionContract.ACTIVITY_INTERVAL))
					if distance > 0 and distance <= reach and tick <= ExpeditionContract.MAX_SAFE_INTEGER - travel_ticks:
						serial += 1
						var flight := {"id": serial, "source": id, "target": chosen.id, "amount": int(policy.threshold), "sent": tick, "arrival": tick + travel_ticks, "distance": distance, "root": false}
						remaining.append(flight)
						emissions.append(flight)
						row.energy -= policy.threshold
						row.emissions += 1
		# Expelled root stock is outside the capped object reserve. Feeding is
		# a conserved food sink, not free healing, XP or a new overload producer.
		if row.kind == "tree" and row.roots > 0:
			for feeder in feeders:
				if row.roots <= 0: break
				if Vector2(cell).distance_to(Vector2(feeder.cell[0], feeder.cell[1])) > policy.feeding_radius: continue
				var meal := minf(row.roots, float(feeding_left.get(feeder.id, 0.0)))
				if float(fed.get(feeder.id, 0.0)) + meal > ExpeditionContract.MAX_SAFE_INTEGER: continue
				row.roots -= meal
				feeding_left[feeder.id] -= meal
				if meal > 0: fed[feeder.id] = float(fed.get(feeder.id, 0.0)) + meal
			if row.roots > 0 and plants.is_valid() and remaining.size() < MAX_FLIGHTS and serial < ExpeditionContract.MAX_SAFE_INTEGER:
				var nearby: Variant = plants.call(cell, float(policy.ground_reach))
				if nearby is Array:
					var eligible: Array[Dictionary] = []
					for plant: Dictionary in nearby:
						if plant.kind != "plant" or not data.nodes.has(plant.id): continue
						var recipient: Dictionary = changes.get(plant.id, data.nodes[plant.id])
						if float(recipient.energy) + float(incoming.get(plant.id, 0.0)) < policy.threshold: eligible.append(plant)
					eligible.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.id < b.id)
					if not eligible.is_empty():
						var chosen: Dictionary = eligible[int(row.emissions) % eligible.size()]
						var recipient: Dictionary = changes.get(chosen.id, data.nodes[chosen.id])
						var amount := minf(row.roots, minf(float(policy.root_rate) * ExpeditionContract.ACTIVITY_INTERVAL, float(policy.threshold) - float(recipient.energy) - float(incoming.get(chosen.id, 0.0))))
						var distance := Vector2(cell).distance_to(Vector2(chosen.cell[0], chosen.cell[1]))
						var travel := maxi(1, ceili(distance / float(policy.speed) / ExpeditionContract.ACTIVITY_INTERVAL))
						if amount > 0 and distance > 0 and distance <= policy.ground_reach and tick <= ExpeditionContract.MAX_SAFE_INTEGER - travel:
							serial += 1
							var flight := {"id": serial, "source": id, "target": chosen.id, "amount": amount, "sent": tick, "arrival": tick + travel, "distance": distance, "root": true}
							remaining.append(flight)
							emissions.append(flight)
							incoming[chosen.id] = float(incoming.get(chosen.id, 0.0)) + amount
							row.roots -= amount
							row.emissions += 1
		changes[id] = row
	return {"changes": changes, "flights": remaining, "arrivals": arrivals, "emissions": emissions, "repairs": repairs, "absorbed": absorbed, "spent": spent, "fed": fed, "cursor": cursor, "serial": serial}

static func normalized(data: Dictionary) -> Dictionary:
	var result := data.duplicate(true)
	for key in ["version", "cursor", "last_tick", "serial"]: result[key] = int(result[key])
	for key in ["absorbed", "spent"]: result[key] = float(result[key])
	if result.policy != null:
		for key in ["threshold", "repair_points", "work_limit", "active_radius"]: result.policy[key] = int(result.policy[key])
		for key in ["refill", "repair_cost", "speed", "ground_reach", "tree_reach", "root_rate", "feeding_rate", "feeding_radius"]: result.policy[key] = float(result.policy[key])
	for row: Dictionary in result.nodes.values():
		row.cell = [int(row.cell[0]), int(row.cell[1])]
		row.energy = float(row.energy)
		row.roots = float(row.roots)
		row.since = int(row.since)
		row.emissions = int(row.emissions)
	for flight: Dictionary in result.flights:
		for key in ["id", "sent", "arrival"]: flight[key] = int(flight[key])
		flight.amount = float(flight.amount) if flight.root else int(flight.amount)
		flight.distance = float(flight.distance)
	for id in result.fed: result.fed[id] = float(result.fed[id])
	return result
