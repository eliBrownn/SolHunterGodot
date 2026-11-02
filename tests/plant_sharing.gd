extends SceneTree
class Reference extends ExpeditionState:
	func advance_flora(resolver: Callable, environment: Callable, plants: Callable = Callable(), companion_cell: Variant = null, protected: Callable = Callable(), storm_allowed: bool = false) -> int:
		if _flora.policy == null: return 0
		var feeders: Array[Dictionary] = []
		var identities := individual_ids()
		identities.sort()
		for identity: String in identities:
			if not wild_available(identity) or wild_in_battle(identity): continue
			var row := roaming_view(identity)
			feeders.append({"id": identity, "cell": row.cell})
		if companion_cell is Vector2i and not _battle.active:
			var companion := active_sol_view()
			if not companion.is_empty() and companion.hp > 0 and _individuals.get(companion.id, {}).get("location") == "party":
				feeders.append({"id": companion.id, "cell": [companion_cell.x, companion_cell.y]})
		var local_environment := func(at: Vector2i) -> Dictionary:
			var row: Dictionary = environment.call(at).duplicate(true)
			# Flora continues circulation but cannot pay to repair a combat-owned tile.
			if combat_owns(at): row.overload = 0
			return row
		var prepared := PlantVastra.prepare(_flora, _tick, _seed, _flora_active, resolver, local_environment, plants, feeders, _ecology.policy != null and _ecology.policy.enabled,_flora_specialist_percent)
		if prepared.is_empty(): return -1
		if prepared.has("noop"): return 0
		var had_ambient_flights: bool = not _ambient.flights.is_empty()
		advance_ambient(environment)
		for id in prepared.changes: _flora.nodes[id] = prepared.changes[id]
		_flora.flights = prepared.flights
		_flora_held_tick = -1
		_flora.cursor = prepared.cursor
		_flora.serial = prepared.serial
		_flora.absorbed += prepared.absorbed
		_flora.spent += prepared.spent
		var food_changed: bool = _flora.fed != prepared.fed
		_flora.fed = prepared.fed
		_flora.last_tick = _tick
		for id: String in prepared.repairs:
			var row: Dictionary = _flora.nodes[id]
			var cell := Vector2i(int(row.cell[0]), int(row.cell[1]))
			var key := AffinityImprint.key(cell)
			var overload: int = int(_tile_deltas.get(key, {}).get("overload", 0))
			if overload > 0: set_environment(cell, {"overload": maxi(0, overload - int(prepared.repairs[id]))})
		for arrival: Dictionary in prepared.arrivals:
			var completed := arrival.duplicate(true)
			completed["credited_tick"] = _tick
			_flora_recent.append(completed)
		while _flora_recent.size() > 128: _flora_recent.pop_front()
		advance_vessels(prepared.arrivals, local_environment, protected, storm_allowed)
		export_ambient(prepared.changes,resolver)
		if not prepared.emissions.is_empty() or not prepared.arrivals.is_empty() or food_changed or had_ambient_flights or not _ambient.flights.is_empty(): flora_changed.emit()
		return prepared.changes.size()

	## Small real generation credits between ecology ticks, at the unchanged units/second.
	## Tick servicing credits only the remaining elapsed time, so neither path double counts.

var checks := 0
var failures := 0
var definitions: Array[Dictionary] = []
func check(ok: bool, text: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(text)
func _initialize() -> void: run.call_deferred()
func env(at: Vector2i) -> Dictionary:
	return {"concentration": 40 + posmod(at.x * 17 + at.y * 11, 61), "overload": 2 if at.x == 0 else 0}
func trees(at: Vector2i, reach: float) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for row in definitions:
		if row.kind == "tree" and Vector2i(row.cell[0],row.cell[1]).distance_to(at) <= reach: rows.append(row)
	return rows
func plants(at: Vector2i, reach: float) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for row in definitions:
		if row.kind == "plant" and Vector2i(row.cell[0],row.cell[1]).distance_to(at) <= reach: rows.append(row)
	return rows
func run() -> void:
	for y in range(-3,4):
		for x in range(-3,4):
			definitions.append({"id": "%d:%d" % [x,y], "cell": [x,y], "kind": "tree" if posmod(x+y,4)==0 else "plant"})
	var current := ExpeditionState.new(17)
	var reference := Reference.new(17)
	for state in [current,reference]:
		state.configure_flora(load("res://resources/vastra_settings.tres").plant_parameters())
		state.configure_ecology(VesselSettings.new().parameters())
		state.admit_flora(definitions)
		var ids: Array[String] = []
		for row in definitions:
			ids.append(row.id)
			state._flora.nodes[row.id].energy = 90.0
		state.set_flora_active(ids)
	for frame in range(180):
		for state in [reference,current]:
			state.advance_time(0.125)
			state.advance_flora(trees,env,plants)
			state.advance_flora_refill(env)
		check(current.snapshot() == reference.snapshot(), "Exact ledger/state match at fine step %d" % frame)
	print("PLANT SHARING EQUIVALENCE: ",checks," checks, ",failures," failures")
	quit(0 if failures==0 else 1)
