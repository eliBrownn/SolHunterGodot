class_name HumanVastraActivity
extends RefCounted
## Pure transaction preparation. ExpeditionState owns the committed ledger and tiles.

const MAX_PRODUCERS := 1024
const MAX_REGIONS := 128
const MAX_COUNTER := 9007199254740991 # Exact JSON range, shared with the domain clock.

static func empty_ledger() -> Dictionary:
	return {"tick": 0, "spent": {}, "events": {}}

static func valid_event(event: Variant) -> bool:
	if not event is Dictionary or not ExpeditionState.keys_match(event, ["actor_kind", "actor_id", "sequence", "kind", "cell", "harvest_amount", "overload_delta"]):
		return false
	if event.actor_kind not in ["player", "npc", "infrastructure"] or not SolSpeciesDefinition.text(event.actor_id) or not SolSpeciesDefinition.whole(event.sequence, 1, MAX_COUNTER) or event.kind not in ["harvest", "disturbance"]:
		return false
	if not event.cell is Array or event.cell.size() != 2 or not SolSpeciesDefinition.whole(event.cell[0], -1000000, 1000000) or not SolSpeciesDefinition.whole(event.cell[1], -1000000, 1000000):
		return false
	if not SolSpeciesDefinition.whole(event.harvest_amount, 0, 100) or not SolSpeciesDefinition.whole(event.overload_delta, 0, 100):
		return false
	return event.harvest_amount > 0 if event.kind == "harvest" else event.harvest_amount == 0 and event.overload_delta > 0

static func normalized_event(event: Dictionary) -> Dictionary:
	var result := event.duplicate(true)
	result.cell = [int(event.cell[0]), int(event.cell[1])]
	for field in ["sequence", "harvest_amount", "overload_delta"]:
		result[field] = int(result[field])
	return result

static func producer(event: Dictionary) -> String:
	return event.actor_kind + ":" + event.actor_id

static func valid_ledger(data: Variant, tick: int) -> bool:
	if not data is Dictionary or not ExpeditionState.keys_match(data, ["tick", "spent", "events"]) or not SolSpeciesDefinition.whole(data.tick, 0, tick):
		return false
	if not data.spent is Dictionary or data.spent.size() > MAX_REGIONS or not data.events is Dictionary or data.events.size() > MAX_PRODUCERS:
		return false
	for region in data.spent:
		if not SolSpeciesDefinition.text(region) or not SolSpeciesDefinition.whole(data.spent[region], 0, MAX_COUNTER):
			return false
	for key in data.events:
		var receipt: Variant = data.events[key]
		if not receipt is Dictionary or not ExpeditionState.keys_match(receipt, ["event", "effect"]) or not valid_event(receipt.event) or key != producer(receipt.event):
			return false
		var effect: Variant = receipt.effect
		if not effect is Dictionary or not ExpeditionState.keys_match(effect, ["concentration", "overload", "excess"]):
			return false
		for field in ["concentration", "overload", "excess"]:
			if not SolSpeciesDefinition.whole(effect[field], VastraCombat.MIN_OVERLOAD if field == "overload" else 0, 100):
				return false
		var event: Dictionary = receipt.event
		if effect.excess > event.harvest_amount or effect.overload < VastraCombat.MIN_OVERLOAD + event.overload_delta:
			return false
		if event.kind == "disturbance" and effect.excess != 0:
			return false
		if event.kind == "harvest" and (effect.concentration > 100 - event.harvest_amount or (effect.excess > 0) != (event.overload_delta > 0)):
			return false
	return true

static func normalized_ledger(data: Dictionary) -> Dictionary:
	var result := data.duplicate(true)
	result.tick = int(result.tick)
	for region in result.spent:
		result.spent[region] = int(result.spent[region])
	for key in result.events:
		result.events[key].event = normalized_event(result.events[key].event)
		for field in result.events[key].effect:
			result.events[key].effect[field] = int(result.events[key].effect[field])
	return result

static func prepare(ledger: Dictionary, event: Variant, tick: int, tile: Dictionary, region: String, budget: Variant) -> Dictionary:
	if not valid_event(event) or not valid_ledger(ledger, tick):
		return {}
	var command := normalized_event(event)
	var key := producer(command)
	if ledger.events.has(key):
		var previous: Dictionary = ledger.events[key]
		if command.sequence == previous.event.sequence:
			if command != previous.event:
				return {}
			var replay: Dictionary = previous.effect.duplicate(true)
			replay.replayed = true
			return {"effect": replay}
		if command.sequence != previous.event.sequence + 1:
			return {}
	elif command.sequence != 1 or ledger.events.size() >= MAX_PRODUCERS:
		return {}
	if not SolSpeciesDefinition.whole(tile.get("concentration"), 0, 100) or not VastraCombat.valid_overload(tile.get("overload")):
		return {}
	var spent: Dictionary = ledger.spent.duplicate(true) if tick == ledger.tick else {}
	var excess := 0
	if command.kind == "harvest":
		if not SolSpeciesDefinition.text(region) or not SolSpeciesDefinition.whole(budget, 0, 100) or command.harvest_amount > tile.concentration:
			return {}
		var used := int(spent.get(region, 0))
		excess = maxi(0, command.harvest_amount - maxi(0, int(budget) - used))
		if (excess > 0) != (command.overload_delta > 0) or used > MAX_COUNTER - command.harvest_amount:
			return {}
		if not spent.has(region) and spent.size() >= MAX_REGIONS:
			return {}
		spent[region] = used + command.harvest_amount
	var effect := {"concentration": int(tile.concentration) - command.harvest_amount,
		"overload": mini(100, int(tile.overload) + command.overload_delta), "excess": excess}
	var prepared := {"tick": tick, "spent": spent, "events": ledger.events.duplicate(true)}
	prepared.events[key] = {"event": command, "effect": effect.duplicate(true)}
	effect.replayed = false
	return {"ledger": prepared, "effect": effect}
