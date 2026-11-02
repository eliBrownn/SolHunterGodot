class_name AmbientVastra
extends RefCounted
## Conserved delivery backlog, never a second tile reserve. Only ExpeditionState
## commits concentration. Queues and rotor positions persist across save/load.
const VERSION := 1
const MAX_RELAYS := 8192
const MAX_FLIGHTS := 2048
const DIRECTIONS := [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]

static func empty() -> Dictionary:
	return {"version": VERSION, "policy": null, "relays": {}, "pending": [], "flights": [], "serial": 0, "last_tick": -1, "received": 0.0, "credited": 0.0}

static func valid_policy(p: Variant) -> bool:
	if not p is Dictionary or not RecordShape.keys_match(p, ["enabled", "concentration_per_unit", "speed", "work_limit"]): return false
	return p.enabled is bool and number(p.concentration_per_unit, 0.01, 100) and number(p.speed, 0.05, 4) and SolSpeciesDefinition.whole(p.work_limit, 1, 256)

static func number(value: Variant, low: float, high: float) -> bool:
	return (value is float or value is int) and is_finite(float(value)) and value >= low and value <= high

static func cell(value: Array) -> Vector2i:
	return Vector2i(int(value[0]), int(value[1]))

static func valid_cell(value: Variant) -> bool:
	return value is Array and value.size() == 2 and SolSpeciesDefinition.whole(value[0], -1000000, 1000000) and SolSpeciesDefinition.whole(value[1], -1000000, 1000000)

static func valid(data: Variant, tick: int) -> bool:
	if not data is Dictionary or not RecordShape.keys_match(data, ["version", "policy", "relays", "pending", "flights", "serial", "last_tick", "received", "credited"]): return false
	if not SolSpeciesDefinition.whole(data.version, VERSION, VERSION) or (data.policy != null and not valid_policy(data.policy)): return false
	if not SolSpeciesDefinition.whole(data.serial, 0, ExpeditionContract.MAX_SAFE_INTEGER) or not SolSpeciesDefinition.whole(data.last_tick, -1, tick): return false
	if not number(data.received, 0, ExpeditionContract.MAX_SAFE_INTEGER) or not number(data.credited, 0, data.received): return false
	if not data.relays is Dictionary or data.relays.size() > MAX_RELAYS or not data.pending is Array or data.pending.size() > MAX_RELAYS or not data.flights is Array or data.flights.size() > MAX_FLIGHTS: return false
	var accounted := float(data.credited)
	var positive := {}
	for key in data.relays:
		var row: Variant = data.relays[key]
		if not row is Dictionary or not RecordShape.keys_match(row, ["cell", "amount", "rotor"]) or not valid_cell(row.cell): return false
		if key != AffinityImprint.key(cell(row.cell)) or not number(row.amount, 0, PlantVastra.MAX_ENERGY) or not SolSpeciesDefinition.whole(row.rotor, 0, 3): return false
		accounted += float(row.amount)
		if row.amount > 0: positive[key] = true
	var seen := {}
	for key in data.pending:
		if not key is String or not positive.has(key) or seen.has(key): return false
		seen[key] = true
	if seen.size() != positive.size(): return false
	seen.clear()
	for row in data.flights:
		if not row is Dictionary or not RecordShape.keys_match(row, ["id", "source", "target", "kind", "amount", "sent", "arrival"]): return false
		if not valid_cell(row.source) or not valid_cell(row.target) or row.kind not in ["plant", "tree", "tile"]: return false
		if cell(row.source).distance_squared_to(cell(row.target)) != 1 or not number(row.amount, 0, PlantVastra.MAX_ENERGY) or row.amount <= 0: return false
		if not SolSpeciesDefinition.whole(row.id, 1, data.serial) or seen.has(row.id) or not SolSpeciesDefinition.whole(row.sent, 0, tick) or not SolSpeciesDefinition.whole(row.arrival, int(row.sent)+1, ExpeditionContract.MAX_SAFE_INTEGER): return false
		if data.policy == null or int(row.arrival)-int(row.sent) != travel(data.policy): return false
		seen[row.id] = true
		accounted += float(row.amount)
	if data.policy == null and (data.received != 0 or not data.relays.is_empty() or not data.flights.is_empty()): return false
	return absf(accounted-float(data.received)) <= 0.0001 * maxf(1.0, sqrt(float(data.received)))

static func travel(policy: Dictionary) -> int:
	return maxi(1, ceili(1.0 / float(policy.speed) / ExpeditionContract.ACTIVITY_INTERVAL))

static func launch(data: Dictionary, source: Vector2i, target: Vector2i, kind: String, amount: float, tick: int) -> void:
	data.serial += 1
	data.flights.append({"id": data.serial, "source": [source.x, source.y], "target": [target.x, target.y], "kind": kind, "amount": amount, "sent": tick, "arrival": tick+travel(data.policy)})

## A rejected offer leaves both owners untouched. Complete four-way emission
## prevents a preferred biome/direction, with exact residual accounting.
static func offer(data: Dictionary, source: Vector2i, kind: String, amount: float, tick: int) -> bool:
	if data.policy == null or not data.policy.enabled or kind not in ["plant","tree"] or not number(amount,0,PlantVastra.MAX_ENERGY) or amount <= 0 or tick < 0: return false
	if absi(source.x) >= 1000000 or absi(source.y) >= 1000000 or data.flights.size()+4 > MAX_FLIGHTS or data.serial > ExpeditionContract.MAX_SAFE_INTEGER-4 or tick > ExpeditionContract.MAX_SAFE_INTEGER-travel(data.policy): return false
	if data.received+amount > ExpeditionContract.MAX_SAFE_INTEGER: return false
	var remaining := amount
	for index in range(4):
		var part := amount/4.0 if index<3 else remaining
		launch(data, source, source+DIRECTIONS[index], kind, part, tick)
		remaining -= part
	data.received += amount
	return true

## Call once per active tick. Both visit budgets are bounded; blocked entries
## rotate behind others. Technical caps retain packets rather than deleting mass.
static func advance(data: Dictionary, tick: int, locked: Callable, credit: Callable) -> Array[Dictionary]:
	var arrivals: Array[Dictionary] = []
	if data.policy == null or not data.policy.enabled or data.last_tick == tick: return arrivals
	var elapsed := maxi(0, tick-maxi(0, int(data.last_tick)))
	# Freeze local combat-owned paths, including packets awaiting their queue turn.
	for packet: Dictionary in data.flights:
		if locked.call(cell(packet.source)) or locked.call(cell(packet.target)):
			if packet.arrival <= ExpeditionContract.MAX_SAFE_INTEGER-elapsed:
				packet.sent += elapsed
				packet.arrival += elapsed
	data.last_tick = tick
	for index in range(mini(int(data.policy.work_limit), data.flights.size())):
		var packet: Dictionary = data.flights.pop_front()
		var at := cell(packet.target)
		var key := AffinityImprint.key(at)
		if packet.arrival > tick or locked.call(at) or locked.call(cell(packet.source)) or (not data.relays.has(key) and data.relays.size() >= MAX_RELAYS):
			data.flights.append(packet)
			continue
		if not data.relays.has(key): data.relays[key] = {"cell": packet.target.duplicate(), "amount": 0.0, "rotor": 0}
		var relay: Dictionary = data.relays[key]
		if relay.amount+packet.amount > PlantVastra.MAX_ENERGY:
			data.flights.append(packet)
			continue
		if relay.amount == 0: data.pending.append(key)
		relay.amount += packet.amount
		arrivals.append(packet)
	for index in range(mini(int(data.policy.work_limit), data.pending.size())):
		var key: String = data.pending.pop_front()
		var row: Dictionary = data.relays[key]
		var at := cell(row.cell)
		if not locked.call(at):
			# Callback returns the actually committed units. Fractional concentration
			# remains conserved here until it can purchase a whole concentration point.
			var result: Dictionary = credit.call(at, float(row.amount), float(data.policy.concentration_per_unit))
			var used := float(result.units)
			row.amount = maxf(0.0, float(row.amount)-used)
			data.credited += used
			if result.full and row.amount > 0 and data.flights.size() < MAX_FLIGHTS and data.serial < ExpeditionContract.MAX_SAFE_INTEGER and tick <= ExpeditionContract.MAX_SAFE_INTEGER-travel(data.policy):
				var target: Vector2i = at+DIRECTIONS[int(row.rotor)]
				row.rotor = (int(row.rotor)+1)%4
				if absi(target.x) <= 1000000 and absi(target.y) <= 1000000:
					launch(data, at, target, "tile", float(row.amount), tick)
					row.amount = 0.0
		if row.amount > 0: data.pending.append(key)
	return arrivals

static func normalized(data: Dictionary) -> Dictionary:
	var result := data.duplicate(true)
	for key in ["version", "serial", "last_tick"]: result[key] = int(result[key])
	if result.policy != null: result.policy.work_limit = int(result.policy.work_limit)
	for row: Dictionary in result.relays.values():
		row.rotor = int(row.rotor)
		row.cell = [int(row.cell[0]), int(row.cell[1])]
	for row: Dictionary in result.flights:
		for key in ["id", "sent", "arrival"]: row[key] = int(row[key])
		for key in ["source", "target"]: row[key] = [int(row[key][0]), int(row[key][1])]
	return result
