class_name PlantVastra
extends RefCounted
## Pure bounded energy transactions. ExpeditionState owns the ledger and commits.
const VERSION := 3
const MAX_NODES := 32768
const MAX_FLIGHTS := 1024
const MAX_ENERGY := 1000000000.0

static func empty() -> Dictionary:
	return {"version": VERSION, "policy": null, "nodes": {}, "flights": [], "fed": {}, "cursor": 0, "last_tick": -1, "serial": 0, "absorbed": 0.0, "spent": 0.0, "exported": 0.0}

static func capacity(policy: Dictionary, row: Dictionary) -> float:
	return float(policy.get("tree_capacity", 1000)) if row.kind == "tree" else float(policy.threshold)

## Undispatched stock stays physically at its source, but is committed to a
## conserved transfer. Other actions cannot spend that reserved stock again.
static func held_reserves(data: Dictionary, tick: int, roots: bool = false) -> Dictionary:
	var held := {}
	for flight: Dictionary in data.flights:
		if flight.root != roots or not flight.has("release_ticks"): continue
		var fraction := clampf(float(tick-int(flight.sent))/float(flight.release_ticks),0.0,1.0)
		held[flight.source] = float(held.get(flight.source,0.0))+float(flight.amount)*(1.0-fraction)
	return held

## One pure flight pass; each sum retains the original per-account flight order.
static func flight_accounts(flights: Array, tick: int, include_incoming: bool = true) -> Dictionary:
	var held := {}
	var roots := {}
	var incoming := {}
	for flight: Dictionary in flights:
		if flight.has("release_ticks"):
			var account: Dictionary = roots if flight.root else held
			var fraction := clampf(float(tick-int(flight.sent))/float(flight.release_ticks),0.0,1.0)
			account[flight.source] = float(account.get(flight.source,0.0))+float(flight.amount)*(1.0-fraction)
		if include_incoming and flight.root:
			incoming[flight.target] = float(incoming.get(flight.target,0.0))+float(flight.amount)-float(flight.get("delivered",0.0))
	return {"held": held, "roots": roots, "incoming": incoming}

static func pace_flight(flight: Dictionary, policy: Dictionary) -> void:
	var rate := float(policy.get("transfer_rate",0.0))
	if rate <= 0.0: return # Explicit legacy/instant-reserve fixture, still finite travel.
	flight["release_ticks"] = maxi(1,ceili(float(flight.amount)/rate/ExpeditionContract.ACTIVITY_INTERVAL))
	flight["delivered"] = 0.0

static func valid_policy(p: Variant) -> bool:
	if not p is Dictionary: return false
	var expected := ["threshold", "refill", "repair_cost", "repair_points", "speed", "work_limit", "active_radius", "ground_reach", "tree_reach", "root_rate", "feeding_rate", "feeding_radius"]
	if p.has("emission_phases"): expected.append("emission_phases")
	if p.has("transfer_rate"):
		expected.append("transfer_rate")
		if not (p.transfer_rate is float or p.transfer_rate is int) or not is_finite(float(p.transfer_rate)) or p.transfer_rate < 0 or p.transfer_rate > 100: return false
		if p.transfer_rate > 0 and p.transfer_rate < 0.01: return false
	if p.has("tree_capacity"):
		expected.append("tree_capacity")
		if not SolSpeciesDefinition.whole(p.tree_capacity, 1, 1000): return false
	if not RecordShape.keys_match(p, expected) or not SolSpeciesDefinition.whole(p.get("emission_phases",1),1,8): return false
	for key in ["refill", "repair_cost", "speed", "ground_reach", "tree_reach", "root_rate", "feeding_rate", "feeding_radius"]:
		if not (p[key] is int or p[key] is float) or not is_finite(float(p[key])): return false
	if p.root_rate < 0 or p.root_rate > 100 or p.feeding_rate < 0 or p.feeding_rate > 100 or p.feeding_radius < 0.25 or p.feeding_radius > 8: return false
	return SolSpeciesDefinition.whole(p.threshold, 1, 1000) and p.refill >= 0 and p.refill <= 100 and p.repair_cost >= 1 and p.repair_cost <= 1000 and SolSpeciesDefinition.whole(p.repair_points, 0, 10) and p.speed >= 0.05 and p.speed <= 4 and SolSpeciesDefinition.whole(p.work_limit, 1, 256) and SolSpeciesDefinition.whole(p.active_radius, 0, 1) and p.ground_reach >= 1 and p.ground_reach <= 8 and p.tree_reach >= p.ground_reach and p.tree_reach <= 32

static func valid_definition(row: Variant) -> bool:
	return row is Dictionary and RecordShape.keys_match(row, ["id", "cell", "kind"]) and row.kind in ["plant", "tree"] and row.cell is Array and row.cell.size() == 2 and SolSpeciesDefinition.whole(row.cell[0], -1000000, 1000000) and SolSpeciesDefinition.whole(row.cell[1], -1000000, 1000000) and row.id == AffinityImprint.key(Vector2i(int(row.cell[0]), int(row.cell[1])))

static func valid(data: Variant, tick: int) -> bool:
	if not data is Dictionary or not RecordShape.keys_match(data, ["version", "policy", "nodes", "flights", "fed", "cursor", "last_tick", "serial", "absorbed", "spent", "exported"]): return false
	if not data.fed is Dictionary or data.fed.size() > ExpeditionContract.MAX_INDIVIDUALS: return false
	for id in data.fed:
		if not id is String or not (data.fed[id] is float or data.fed[id] is int) or not is_finite(float(data.fed[id])) or data.fed[id] < 0 or data.fed[id] > ExpeditionContract.MAX_SAFE_INTEGER: return false
	if not SolSpeciesDefinition.whole(data.version, VERSION, VERSION) or (data.policy != null and not valid_policy(data.policy)) or not data.nodes is Dictionary or data.nodes.size() > MAX_NODES or not data.flights is Array or data.flights.size() > MAX_FLIGHTS or not SolSpeciesDefinition.whole(data.cursor, 0, MAX_NODES) or not SolSpeciesDefinition.whole(data.last_tick, -1, tick) or not SolSpeciesDefinition.whole(data.serial, 0, ExpeditionContract.MAX_SAFE_INTEGER): return false
	for key in ["absorbed", "spent", "exported"]:
		if not (data[key] is float or data[key] is int) or not is_finite(float(data[key])) or data[key] < 0 or data[key] > ExpeditionContract.MAX_SAFE_INTEGER: return false
	var emission_count := 0
	for id in data.nodes:
		var row: Variant = data.nodes[id]
		if not row is Dictionary: return false
		var node_keys := ["id", "cell", "kind", "energy", "roots", "since", "emissions"]
		if row.has("refill_since"):
			node_keys.append("refill_since")
			if not (row.refill_since is float or row.refill_since is int) or not is_finite(float(row.refill_since)) or row.refill_since < 0 or row.refill_since >= float(tick+1)*ExpeditionContract.ACTIVITY_INTERVAL: return false
		if not RecordShape.keys_match(row,node_keys): return false
		if not (row.roots is float or row.roots is int) or not is_finite(float(row.roots)) or row.roots < 0 or row.roots > MAX_ENERGY or (row.kind != "tree" and row.roots != 0): return false
		if not valid_definition({"id": row.id, "cell": row.cell, "kind": row.kind}) or id != row.id or not (row.energy is float or row.energy is int) or not is_finite(float(row.energy)) or row.energy < 0 or row.energy > MAX_ENERGY or not SolSpeciesDefinition.whole(row.since, 0, tick) or not SolSpeciesDefinition.whole(row.emissions, 0, ExpeditionContract.MAX_SAFE_INTEGER): return false
		if data.policy == null or row.energy > capacity(data.policy, row): return false
		emission_count += int(row.emissions)
		if emission_count > int(data.serial): return false
	if emission_count != int(data.serial): return false
	var seen := {}
	var reserved := {}
	for flight in data.flights:
		if not flight is Dictionary: return false
		var flight_keys := ["id", "source", "target", "amount", "sent", "arrival", "distance", "root"]
		if flight.has("release_ticks"):
			flight_keys.append_array(["release_ticks","delivered"])
			if not SolSpeciesDefinition.whole(flight.release_ticks,1,1000000) or not (flight.get("delivered") is float or flight.get("delivered") is int) or not is_finite(float(flight.delivered)): return false
		if not RecordShape.keys_match(flight,flight_keys): return false
		if not flight.root is bool or not (flight.amount is int or flight.amount is float) or not is_finite(float(flight.amount)) or flight.amount <= 0 or flight.amount > 1000: return false
		if not SolSpeciesDefinition.whole(flight.id, 1, data.serial) or seen.has(flight.id) or not data.nodes.has(flight.source) or not data.nodes.has(flight.target) or flight.source == flight.target or not SolSpeciesDefinition.whole(flight.sent, 0, tick) or not SolSpeciesDefinition.whole(flight.arrival, int(flight.sent) + 1, ExpeditionContract.MAX_SAFE_INTEGER) or not (flight.distance is float or flight.distance is int) or not is_finite(float(flight.distance)) or flight.distance <= 0 or flight.distance > 64: return false
		if data.policy == null: return false
		if flight.has("release_ticks"):
			if flight.delivered < 0 or flight.delivered >= flight.amount: return false
			var arrived_fraction := clampf(float(tick-int(flight.arrival))/float(flight.release_ticks),0.0,1.0)
			if float(flight.delivered) > float(flight.amount)*arrived_fraction+0.0001: return false
		var origin: Array = data.nodes[flight.source].cell
		var destination: Array = data.nodes[flight.target].cell
		var actual_distance := Vector2(origin[0], origin[1]).distance_to(Vector2(destination[0], destination[1]))
		if absf(float(flight.distance) - actual_distance) > 0.0001 or int(flight.arrival) != int(flight.sent) + maxi(1, ceili(actual_distance / float(data.policy.speed) / ExpeditionContract.ACTIVITY_INTERVAL)): return false
		if flight.root:
			if data.nodes[flight.source].kind != "tree" or data.nodes[flight.target].kind != "plant" or flight.amount > data.policy.threshold or flight.distance > data.policy.ground_reach: return false
			reserved[flight.target] = float(reserved.get(flight.target, 0.0)) + float(flight.amount)-float(flight.get("delivered",0.0))
		elif data.nodes[flight.target].kind != "tree" or flight.amount != data.policy.threshold: return false
		seen[flight.id] = true
	var accounts := flight_accounts(data.flights,tick,false)
	var held: Dictionary = accounts.held
	var held_roots: Dictionary = accounts.roots
	for id in data.nodes:
		if float(data.nodes[id].energy)+float(held.get(id,0.0))+float(reserved.get(id,0.0)) > capacity(data.policy,data.nodes[id])+0.0001: return false
		if float(data.nodes[id].roots)+float(held_roots.get(id,0.0))>MAX_ENERGY: return false
	var accounted := float(data.spent) + float(data.exported)
	for row: Dictionary in data.nodes.values(): accounted += float(row.energy) + float(row.roots)
	for flight: Dictionary in data.flights: accounted += float(flight.amount)-float(flight.get("delivered",0.0))
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
static func prepare(data: Dictionary, tick: int, seed: int, active: Array[String], resolver: Callable, environment: Callable, plants: Callable = Callable(), feeders: Array[Dictionary] = [], classified: bool = false, specialist_percent: int = FloraTraits.DEFAULT_SPECIALIST_PERCENT) -> Dictionary:
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
	var accounts := flight_accounts(data.flights,tick,false)
	var held: Dictionary = accounts.held
	var held_roots: Dictionary = accounts.roots
	var incoming := {}
	var serviced_packets := 0
	for feeder in feeders: feeding_left[feeder.id] = float(policy.feeding_rate) * ExpeditionContract.ACTIVITY_INTERVAL
	for flight: Dictionary in data.flights:
		if flight.arrival > tick or serviced_packets >= int(policy.work_limit):
			retain_flight(remaining, incoming, flight)
			continue
		var credit := float(flight.amount)
		if flight.has("release_ticks"):
			credit = float(flight.amount)*clampf(float(tick-int(flight.arrival))/float(flight.release_ticks),0.0,1.0)-float(flight.delivered)
		if credit <= 0.0000001:
			retain_flight(remaining, incoming, flight)
			continue
		var target: Dictionary = changes.get(flight.target, data.nodes[flight.target]).duplicate(true)
		var available_capacity := capacity(policy,target)-float(held.get(flight.target,0.0))
		var overflow := maxf(0.0, float(target.energy) + credit - available_capacity)
		if (target.kind != "tree" and overflow > 0.0001) or target.roots + float(held_roots.get(flight.target,0.0)) + overflow > MAX_ENERGY:
			retain_flight(remaining, incoming, flight) # Technical safety bound defers credit without losing energy.
			continue
		serviced_packets += 1
		target.energy += credit
		if target.kind == "tree":
			target.roots += overflow
			target.energy = minf(target.energy, available_capacity)
		else:
			target.energy = minf(target.energy, policy.threshold) # Clamp only floating-point roundoff after reserved arrivals.
		changes[flight.target] = target
		if flight.has("release_ticks") and float(flight.delivered)+credit < float(flight.amount)-0.0000001:
			var partial := flight.duplicate(true)
			partial.delivered += credit
			retain_flight(remaining, incoming, partial)
		else: arrivals.append(flight)
	var cursor := int(data.cursor) % maxi(1, active.size())
	for index in range(mini(int(policy.work_limit), active.size())):
		var id: String = active[cursor]
		cursor = (cursor + 1) % active.size()
		if not data.nodes.has(id): continue
		var row: Dictionary = changes.get(id, data.nodes[id]).duplicate(true)
		var cell := Vector2i(int(row.cell[0]), int(row.cell[1]))
		var conditions: Dictionary = environment.call(cell)
		# Admission/reactivation stamps since=current tick: no invented offline charge.
		var previous_tick := int(row.since)
		var refill_clock := float(row.get("refill_since",float(previous_tick)*ExpeditionContract.ACTIVITY_INTERVAL))
		var elapsed := maxf(0.0,float(tick)*ExpeditionContract.ACTIVITY_INTERVAL-refill_clock)
		var gain := minf(maxf(0.0, capacity(policy, row) - float(row.energy) - float(held.get(id,0.0)) - float(incoming.get(id, 0.0))), elapsed * float(policy.refill) * float(conditions.concentration) / 100.0)
		# In classified worlds, only grass emanates; receivers and reservoirs need arrivals.
		if classified and FloraTraits.role(seed, row,specialist_percent) != "emanator": gain = 0.0
		row.energy += gain
		if row.has("refill_since"): row.refill_since = maxf(refill_clock,float(tick)*ExpeditionContract.ACTIVITY_INTERVAL)
		absorbed += gain
		row.since = tick
		var damage := maxi(0, int(conditions.overload) - int(repairs.get(id, 0)))
		var healed := mini(damage, mini(int(policy.repair_points), floori(float(row.energy) / float(policy.repair_cost))))
		if healed > 0:
			row.energy -= healed * float(policy.repair_cost)
			spent += healed * float(policy.repair_cost)
			repairs[id] = healed
		# Geographic phases stagger real sends, never just their visual start times.
		# A full source keeps its reserve until its slot; no catch-up/offline energy.
		var phases := int(policy.get("emission_phases",1))
		var phase := posmod(hash("vastra-cadence:%d:%s" % [seed,id]),phases)
		# Admit a slot crossed since the previous visit, so round-robin work limits
		# cannot permanently alias a source away from its own geographic phase.
		var emission_ready := WorldTerrain.floor_div(tick-phase,phases) > WorldTerrain.floor_div(previous_tick-phase,phases)
		if row.energy >= policy.threshold and emission_ready and float(held.get(id,0.0)) < 0.0000001 and remaining.size() < MAX_FLIGHTS and serial < ExpeditionContract.MAX_SAFE_INTEGER:
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
						pace_flight(flight,policy)
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
			if row.roots > 0 and float(held_roots.get(id,0.0)) < 0.0000001 and plants.is_valid() and remaining.size() < MAX_FLIGHTS and serial < ExpeditionContract.MAX_SAFE_INTEGER:
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
							pace_flight(flight,policy)
							remaining.append(flight)
							emissions.append(flight)
							incoming[chosen.id] = float(incoming.get(chosen.id, 0.0)) + amount
							row.roots -= amount
							row.emissions += 1
		changes[id] = row
	return {"changes": changes, "flights": remaining, "arrivals": arrivals, "emissions": emissions, "repairs": repairs, "absorbed": absorbed, "spent": spent, "fed": fed, "cursor": cursor, "serial": serial}

static func retain_flight(remaining: Array, incoming: Dictionary, flight: Dictionary) -> void:
	remaining.append(flight)
	if flight.root:
		incoming[flight.target] = float(incoming.get(flight.target, 0.0)) + float(flight.amount)-float(flight.get("delivered",0.0))

static func normalized(data: Dictionary) -> Dictionary:
	var result := data.duplicate(true)
	for key in ["version", "cursor", "last_tick", "serial"]: result[key] = int(result[key])
	for key in ["absorbed", "spent", "exported"]: result[key] = float(result[key])
	if result.policy != null:
		if result.policy.has("tree_capacity"): result.policy.tree_capacity = int(result.policy.tree_capacity)
		if result.policy.has("transfer_rate"): result.policy.transfer_rate = float(result.policy.transfer_rate)
		if result.policy.has("emission_phases"): result.policy.emission_phases = int(result.policy.emission_phases)
		for key in ["threshold", "repair_points", "work_limit", "active_radius"]: result.policy[key] = int(result.policy[key])
		for key in ["refill", "repair_cost", "speed", "ground_reach", "tree_reach", "root_rate", "feeding_rate", "feeding_radius"]: result.policy[key] = float(result.policy[key])
	for row: Dictionary in result.nodes.values():
		if row.has("refill_since"): row.refill_since = float(row.refill_since)
		row.cell = [int(row.cell[0]), int(row.cell[1])]
		row.energy = float(row.energy)
		row.roots = float(row.roots)
		row.since = int(row.since)
		row.emissions = int(row.emissions)
	for flight: Dictionary in result.flights:
		if flight.has("release_ticks"):
			flight.release_ticks = int(flight.release_ticks)
			flight.delivered = float(flight.delivered)
		for key in ["id", "sent", "arrival"]: flight[key] = int(flight[key])
		flight.amount = float(flight.amount) if flight.root else int(flight.amount)
		flight.distance = float(flight.distance)
	for id in result.fed: result.fed[id] = float(result.fed[id])
	return result
