extends SceneTree
var checks := 0
var failures := 0
func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)
func _initialize() -> void:
	run.call_deferred()
func definition(at: Vector2i, kind: String) -> Dictionary:
	return {"id": AffinityImprint.key(at), "cell": [at.x, at.y], "kind": kind}
func definitions() -> Array[Dictionary]:
	return [definition(Vector2i.ZERO, "plant"), definition(Vector2i(1, 0), "tree"), definition(Vector2i(2, 0), "tree")]
func candidates(at: Vector2i, reach: float) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for row in definitions():
		if row.kind == "tree" and row.id != AffinityImprint.key(at) and at.distance_to(Vector2i(row.cell[0], row.cell[1])) <= reach: result.append(row)
	return result
func empty_candidates(_at: Vector2i, _reach: float) -> Array[Dictionary]:
	return []
func charged(energy: Dictionary, refill: float = 0.0, tree_capacity: int = 100) -> ExpeditionState:
	var state := ExpeditionState.new(17)
	var policy := VastraSettings.new().plant_parameters()
	policy.tree_capacity = tree_capacity # Explicit small-cap fixtures exercise overflow/feeding.
	policy.refill = refill
	state.configure_flora(policy)
	state.admit_flora(definitions())
	var data := state.snapshot()
	for id: String in energy:
		data.flora.nodes[id].energy = float(energy[id])
		data.flora.absorbed += float(energy[id])
	return ExpeditionState.restore(data, 17)
func environment(state: ExpeditionState) -> Callable:
	return func(at: Vector2i) -> Dictionary: return state.environment_view(at, {"concentration": 50, "overload": 0})
func step(state: ExpeditionState, resolver: Callable = candidates) -> void:
	state.advance_time(ExpeditionContract.ACTIVITY_INTERVAL)
	state.advance_flora(resolver, environment(state))
func balance(state: ExpeditionState) -> float:
	var data := state.flora_view()
	var value := float(data.spent)+float(data.exported)
	for row: Dictionary in data.nodes.values(): value += float(row.energy) + float(row.roots)
	for flight: Dictionary in data.flights: value += float(flight.amount)-float(flight.get("delivered",0.0))
	for amount in data.fed.values(): value += float(amount)
	return value - float(data.absorbed)

func cadence_contract() -> void:
	var state := ExpeditionState.new(17)
	var policy := VastraSettings.new().plant_parameters()
	policy.emission_phases = 4
	policy.tree_capacity = 100 # Keep the convergence stress fixture's explicit small cap.
	policy.refill = 0.0
	policy.ground_reach = 8.0
	var rows: Array[Dictionary] = []
	var ids: Array[String] = []
	for y in range(4):
		for x in range(4):
			var row := definition(Vector2i(x,y),"plant")
			rows.append(row)
			ids.append(row.id)
	var tree := definition(Vector2i(4,2),"tree")
	rows.append(tree)
	state.configure_flora(policy)
	state.admit_flora(rows)
	var stock := state.snapshot()
	for id in ids: stock.flora.nodes[id].energy = 100.0
	stock.flora.absorbed = 1600.0
	state = ExpeditionState.restore(stock,17)
	state.set_flora_active(ids)
	var resolver := func(_at: Vector2i,_reach: float)->Array[Dictionary]: return [tree]
	var sent_ticks := {}
	for index in range(4):
		step(state,resolver)
		for flight: Dictionary in state.flora_view().flights: sent_ticks[flight.sent] = true
		check(PlantVastra.valid(state.flora_view(),state.activity_tick()) and absf(balance(state))<0.001,"Staggered sends preserve stored plus in-flight energy")
	check(sent_ticks.size()>1 and state.flora_view().serial==16,"Identically charged grass emits in overlapping geographic slots, all within one cycle")
	var resumed := ExpeditionState.restore(JSON.parse_string(JSON.stringify(state.snapshot())),17)
	resumed.set_flora_active(ids)
	for index in range(24):
		step(state,resolver)
		step(resumed,resolver)
	check(state.snapshot()==resumed.snapshot(),"Mid-flight save/load preserves staggered sends and exact credits")
	var slow_stock: Dictionary = stock.duplicate(true)
	slow_stock.flora.policy.work_limit = 4
	var slow := ExpeditionState.restore(slow_stock,17)
	slow.set_flora_active(ids)
	for index in range(20): step(slow,resolver)
	check(slow.flora_view().serial==16 and absf(balance(slow))<0.001,"A source serviced every four ticks cannot be starved by phase aliasing")
	var ledger := state.flora_view()
	check(ledger.flights.is_empty() and ledger.nodes[tree.id].energy==100.0 and ledger.nodes[tree.id].roots==1500.0 and absf(balance(state))<0.001,"Converging packets combine exactly once; full storage safely redirects all excess")
	var legacy: Dictionary = ledger.policy.duplicate()
	legacy.erase("emission_phases")
	check(PlantVastra.valid_policy(legacy),"An existing saved circulation policy keeps immediate-send behavior")
	legacy["emission_phases"] = true
	check(not PlantVastra.valid_policy(legacy),"Cadence rejects a boolean masquerading as a slot count")

func gradual_transfer_contract() -> void:
	var state := charged({"0:0":100})
	check(state.configure_flora_pacing(0.0,10.0),"Pacing applies to an existing expedition without changing capacity")
	state.set_flora_active(["0:0"])
	var resolver := func(_at: Vector2i,_reach: float)->Array[Dictionary]: return [definitions()[1]]
	step(state,resolver)
	var flight: Dictionary = state.flora_view().flights[0]
	check(flight.has("release_ticks") and state.flora_reading(Vector2i.ZERO).energy==100.0,"Queueing reserves stock at the source without an instant displayed drain")
	check(state.flora_view().nodes["0:0"].energy==0,"Committed stock cannot also pay for another action")
	var source_previous := 100.0
	var target_previous := 0.0
	var partial_seen := false
	var resumed: ExpeditionState
	while not state.flora_view().flights.is_empty():
		step(state,resolver)
		var source: float = state.flora_reading(Vector2i.ZERO).energy
		var target: float = state.flora_reading(Vector2i(1,0)).energy
		check(source<=source_previous+0.0001 and target>=target_previous-0.0001,"The outlet drains and the intake rises monotonically on the transfer clock")
		if state.activity_tick()<=int(flight.arrival): check(target==0.0,"No destination credit precedes actual stream arrival")
		check(PlantVastra.valid(state.flora_view(),state.activity_tick()) and absf(balance(state))<0.001,"Held, traveling and partly delivered energy remain conserved and save-valid")
		if resumed!=null:
			step(resumed,resolver)
			check(resumed.snapshot()==state.snapshot(),"Mid-stream save/load preserves source drain and destination intake exactly")
		if target>0 and target<100 and not partial_seen:
			partial_seen = true
			resumed = ExpeditionState.restore(JSON.parse_string(JSON.stringify(state.snapshot())),17)
			check(resumed!=null,"A partly delivered stream survives JSON save/load")
			if resumed!=null: resumed.set_flora_active(["0:0"])
		source_previous = source
		target_previous = target
	check(partial_seen and is_equal_approx(target_previous,100.0) and source_previous==0.0,"The full amount arrives gradually, exactly once")
	var before := state.snapshot()
	state.advance_flora(resolver,environment(state))
	check(state.snapshot()==before,"Repeated same-tick service cannot credit a stream twice")
	var settings: VastraSettings = load("res://resources/vastra_settings.tres")
	check(settings.plant_refill_rate==1.0 and settings.plant_transfer_rate==8.0,"Production output is quarter speed and releases eight units per active second")
	check(not state.configure_flora_pacing(NAN,8.0),"Invalid live pacing preserves the existing policy")
	var root_state := charged({})
	var root_stock := root_state.snapshot()
	root_stock.flora.nodes["1:0"].roots = 30.0
	root_stock.flora.absorbed = 30.0
	root_state = ExpeditionState.restore(root_stock,17)
	root_state.configure_flora_pacing(0.0,2.0)
	root_state.set_flora_active(["1:0"])
	var plants := func(_at: Vector2i,_reach: float)->Array[Dictionary]: return [definitions()[0]]
	root_state.advance_time(0.75)
	root_state.advance_flora(empty_candidates,environment(root_state),plants)
	var root_flight: Dictionary = root_state.flora_view().flights[0]
	check(root_flight.root and root_flight.has("release_ticks") and root_state.flora_reading(Vector2i(1,0)).roots==30.0,"Root stock also stays at its outlet until it physically leaves")
	root_state.advance_time(0.75)
	root_state.advance_flora(empty_candidates,environment(root_state),plants)
	check(root_state.flora_view().flights.size()==1 and root_state.flora_reading(Vector2i(1,0)).roots<30.0,"A source cannot stack overlapping root releases to bypass its flow rate")
	check(PlantVastra.valid(root_state.flora_view(),root_state.activity_tick()) and absf(balance(root_state))<0.001,"Paced root release conserves its reserved and traveling stock")
	var corrupt := root_state.snapshot()
	corrupt.flora.flights[0].delivered = root_flight.amount
	check(ExpeditionState.restore(corrupt,17)==null,"A fully credited or prematurely credited pending stream is rejected")

func settle_transfer_view(currents: Node3D) -> void:
	# Presentation now publishes a complete network after bounded preparation frames.
	for frame in range(128):
		if currents.transfer_job.is_empty(): return
		currents.pump_transfer_network()
	check(false, "Bounded transfer preparation must eventually publish")

func flight_accounts_contract() -> void:
	var flights: Array = []
	for index in range(64):
		var packet := {"source": str(index % 7), "target": str(index % 5), "root": index % 3 == 0, "amount": 13.25 + index, "sent": index % 4, "delivered": float(index % 6)}
		if index % 4 != 0: packet["release_ticks"] = 1 + index % 9
		flights.append(packet)
	var original := flights.duplicate(true)
	for tick in range(20):
		var accounts := PlantVastra.flight_accounts(flights, tick)
		check(accounts.held == PlantVastra.held_reserves({"flights": flights}, tick), "Combined ordinary held sums exactly match the independent original pass")
		check(accounts.roots == PlantVastra.held_reserves({"flights": flights}, tick, true), "Combined root sums exactly match the independent original pass")
		var incoming := {}
		for flight: Dictionary in flights:
			if flight.root: incoming[flight.target] = float(incoming.get(flight.target,0.0))+float(flight.amount)-float(flight.get("delivered",0.0))
		check(accounts.incoming == incoming, "Combined incoming reservations retain exact ordered arithmetic")
	check(flights == original, "Derived flight accounts never mutate packets")
	var state := charged({"0:0": 100}, 1.0)
	step(state)
	state.refresh_flora_held()
	var builds: int = state.flora_account_builds
	for frame in range(12):
		state.flora_reading(Vector2i.ZERO)
		state.flora_reserve_fraction(Vector2i.ZERO)
		state.advance_flora_refill(environment(state))
	check(state.flora_account_builds == builds, "Refill and reserve projections share one unchanged flight snapshot")
	step(state)
	state.refresh_flora_held()
	check(state.flora_account_builds > builds, "Tick/flight commit invalidates all derived reservation accounts")

func run() -> void:
	flight_accounts_contract()
	gradual_transfer_contract()
	check(VastraSettings.new().plant_parameters().tree_capacity == 1000, "Tree capacity defaults to 1,000 independently of plant packets")
	var old_policy := VastraSettings.new().plant_parameters()
	old_policy.erase("tree_capacity")
	check(PlantVastra.capacity(old_policy, {"kind":"tree"}) == 1000 and PlantVastra.capacity(old_policy, {"kind":"plant"}) == 100, "Existing policies receive the tree limit without raising ordinary plant capacity")
	var invalid_policy := VastraSettings.new().plant_parameters()
	invalid_policy.tree_capacity = 0
	check(not PlantVastra.valid_policy(invalid_policy), "Tree capacity rejects invalid saved tuning")
	var reservoir := charged({"0:0": 100, "1:0": 950}, 0.0, 1000)
	reservoir.set_flora_active(["0:0"])
	step(reservoir, func(_at: Vector2i, _reach: float) -> Array[Dictionary]: return [definition(Vector2i(1,0), "tree")])
	reservoir.set_flora_active([])
	for tick in range(8): step(reservoir)
	check(reservoir.flora_reading(Vector2i(1,0)).capacity == 1000 and reservoir.flora_reading(Vector2i(1,0)).energy == 1000, "Tree accepts arrivals up to 1,000 and reports its real capacity")
	check(reservoir.flora_reading(Vector2i(1,0)).roots == 50 and absf(balance(reservoir)) < 0.001, "Only energy above 1,000 overflows with conservation")
	check(ExpeditionState.restore(JSON.parse_string(JSON.stringify(reservoir.snapshot())), 17) != null, "A full 1,000-unit tree survives JSON save/load")
	cadence_contract()
	var state := charged({"0:0": 99})
	state.set_flora_active(["0:0"])
	step(state)
	check(state.flora_view().flights.is_empty(), "Below 100 there is no visible-transfer event")
	state = charged({"0:0": 100})
	state.set_flora_active(["0:0"])
	step(state)
	var data := state.flora_view()
	check(data.flights.size() == 1 and data.flights[0].amount == 100 and data.nodes["0:0"].energy == 0, "A full plant debits one conserved 100-unit packet")
	var flight: Dictionary = data.flights[0]
	check(data.nodes[flight.target].energy == 0 and flight.arrival > flight.sent, "The recipient receives no energy before the head's finite arrival")
	var once := state.snapshot()
	state.advance_flora(candidates, environment(state))
	check(state.snapshot() == once, "Repeated service in the same tick cannot duplicate an emission")
	var restored := ExpeditionState.restore(JSON.parse_string(JSON.stringify(once)), 17)
	check(restored != null and restored.flora_view().flights == data.flights, "Saving mid-flight preserves the exact pending delivery")
	restored.set_flora_active(["0:0"])
	while restored.activity_tick() < int(flight.arrival): step(restored)
	check(restored.flora_view().nodes[flight.target].energy == 100 and restored.flora_view().flights.is_empty(), "Arrival credits the destination exactly once even when it is not active")
	step(restored)
	check(restored.flora_view().nodes[flight.target].energy == 100 and absf(balance(restored)) < 0.001, "Later ticks cannot repeat a completed delivery")
	restored.set_flora_active([flight.target])
	step(restored)
	check(restored.flora_view().flights.size() == 1 and restored.flora_view().flights[0].source == flight.target, "A full tree relays its reserve to another tree")
	check(absf(balance(restored)) < 0.001, "Relaying conserves stored plus in-transit energy")
	var ids: Array[String] = ["0:0", "1:0", "2:0"]
	restored.set_flora_active(ids)
	for i in range(40):
		step(restored)
		check(PlantVastra.valid(restored.flora_view(), restored.activity_tick()) and absf(balance(restored)) < 0.001, "Cycles remain finite, valid and energy-conserving")
	var source := definitions()[0]
	var trees: Array = [definitions()[1].duplicate(true), definitions()[2].duplicate(true)]
	trees[0]["energy"] = 0
	trees[1]["energy"] = 1000
	var counts := {"1:0": 0, "2:0": 0}
	for serial in range(200):
		var selected := PlantVastra.choose_target(source, trees, 17, serial)
		counts[selected.id] += 1
		var changed := trees.duplicate(true)
		changed[0].energy = 1000
		changed[1].energy = 0
		changed.reverse()
		check(PlantVastra.choose_target(source, changed, 17, serial).id == selected.id, "Need, fullness and catalogue order cannot bias the target selection")
	check(counts["1:0"] > 50 and counts["2:0"] > 50, "Both nearby trees are regularly selected, including the already-full tree")
	state = charged({"0:0": 100, "1:0": 100})
	state.set_flora_active(["0:0"])
	var already_full := func(_at: Vector2i, _reach: float) -> Array[Dictionary]: return [definition(Vector2i(1, 0), "tree")]
	step(state, already_full)
	var full_flight: Dictionary = state.flora_view().flights[0]
	while state.activity_tick() < int(full_flight.arrival): step(state, already_full)
	check(state.flora_view().nodes["1:0"].energy == 100 and state.flora_view().nodes["1:0"].roots == 100 and absf(balance(state)) < 0.001, "An already-full destination expels excess to its roots without exceeding its reserve cap or losing energy")
	state.set_flora_active(["1:0"])
	step(state)
	check(state.flora_view().nodes["1:0"].energy == 0 and state.flora_view().nodes["1:0"].roots == 100 and state.flora_view().flights.size() == 1, "A full tree can relay its own reserve while expelled root stock remains separately conserved")
	state = charged({"0:0": 100})
	state.set_flora_active(["0:0"])
	step(state, empty_candidates)
	check(state.flora_view().nodes["0:0"].energy == 100 and state.flora_view().flights.is_empty(), "A plant with no eligible tree keeps its reserve rather than losing it")
	state = charged({"1:0": 100})
	state.set_environment(Vector2i(1, 0), {"overload": 3})
	state.set_flora_active(["1:0"])
	step(state)
	check(state.flora_view().nodes["1:0"].energy == 90 and state.flora_view().spent == 10 and state.environment_view(Vector2i(1, 0), {"overload": 0}).overload == 2, "Energy pays for real local ecological-overload repair before circulation")
	check(state.flora_view().flights.is_empty() and absf(balance(state)) < 0.001, "Energy spent healing cannot also be transferred")
	state = charged({"1:0": 100})
	state.set_environment(Vector2i(1, 0), {"overload": -25})
	state.set_flora_active(["1:0"])
	step(state)
	check(state.environment_view(Vector2i(1, 0), {"overload": 0}).overload == -25 and state.flora_view().spent == 0, "Plant repair preserves beneficial negative overload")
	state = charged({}, 4.0)
	state.set_flora_active(["0:0"])
	step(state)
	check(is_equal_approx(state.flora_view().nodes["0:0"].energy, 1.5) and is_equal_approx(state.flora_view().absorbed, 1.5), "Plants absorb gradually from the separate local ambient concentration")
	var paused := state.snapshot()
	state.advance_flora(candidates, environment(state))
	check(state.snapshot() == paused, "No active-time advance means no refill or transfer")
	state.set_flora_active([])
	for i in range(20): step(state)
	state.set_flora_active(["0:0"])
	step(state)
	check(is_equal_approx(state.flora_view().nodes["0:0"].energy, 3.0), "Reactivation retains reserves without granting offline or inactive-area charge")
	var detached := state.flora_view()
	detached.nodes["0:0"].energy = 999
	check(state.flora_view().nodes["0:0"].energy < 999, "Presentation reads cannot alter stored plant reserves")
	var corrupt := state.snapshot()
	corrupt.flora.nodes["0:0"].energy += 1
	check(ExpeditionState.restore(corrupt, 17) == null, "Corrupt energy accounting is rejected before state replacement")
	corrupt = state.snapshot()
	corrupt.flora.nodes["0:0"].energy = NAN
	check(ExpeditionState.restore(corrupt, 17) == null, "Nonfinite plant energy cannot enter a save")
	corrupt = state.snapshot()
	corrupt.flora.serial += 1
	check(ExpeditionState.restore(corrupt, 17) == null, "A corrupted emission serial cannot reroll future recipients or invent transfer history")
	var world := WorldTerrain.new(17)
	var a := FloraCatalog.new(world)
	var b := FloraCatalog.new(world)
	a.request(Vector2i.ZERO, 0, 1.0)
	b.request(Vector2i.ZERO, 0, 1.0)
	check(a.trees_near(Vector2i.ZERO, 1.0) == null, "An incomplete neighborhood never supplies a biased partial target list")
	while not a.pending.is_empty(): a.advance(Time.get_ticks_usec() + 2000)
	while not b.pending.is_empty(): b.advance(Time.get_ticks_usec() + 20000)
	check(a.regions == b.regions and a.active_ids() == b.active_ids(), "Canonical flora admission is independent of render data and preparation slice size")
	check(a.trees_near(Vector2i.ZERO, 1.0) is Array, "Complete neighborhoods provide stable target candidates")
	hierarchy_checks()
	root_and_feeding_checks()
	await presentation_journey()
	print("PLANT VASTRA: %d checks, %d failures." % [checks, failures])
	quit(0 if failures == 0 else 1)

func root_and_feeding_checks() -> void:
	var state := charged({})
	var fixture := SolSpeciesDefinition.new()
	fixture.species_id = "fixture_feeder"
	fixture.lineage_id = "fixture_feeder"
	fixture.class_id = "fixture_class"
	var eater := state.register_individual(fixture, Vector2i(1, 0), "earth")
	var distant := state.register_individual(fixture, Vector2i(30, 30), "earth")
	var snapshot := state.snapshot()
	snapshot.flora.nodes["1:0"].roots = 20.0
	snapshot.flora.nodes["2:0"].roots = 20.0
	snapshot.flora.absorbed = 40.0
	state = ExpeditionState.restore(snapshot, 17)
	check(state != null, "Expelled root stock has a valid saved conservation record")
	state.set_flora_active(["1:0", "2:0"])
	step(state, empty_candidates)
	check(is_equal_approx(state.sol_vastra_food(eater), 3.0) and state.sol_vastra_food(distant) == 0, "Only nearby Sols eat root excess, with one per-Sol rate cap shared across trees")
	check(absf(balance(state)) < 0.001 and state.flora_view().nodes["1:0"].energy == 0, "Food is debited from excess rather than a tree's ordinary reserve or invented energy")
	var paused := state.snapshot()
	state.advance_flora(empty_candidates, environment(state))
	check(state.snapshot() == paused, "The same active tick cannot feed a Sol twice")
	state.set_flora_active([])
	step(state, empty_candidates)
	check(state.sol_vastra_food(eater) == 3.0, "Inactive root stocks grant no offline or inactive-area food")
	var resumed := ExpeditionState.restore(JSON.parse_string(JSON.stringify(state.snapshot())), 17)
	check(resumed != null and resumed.sol_vastra_food(eater) == 3.0 and absf(balance(resumed)) < 0.001, "Saved Sol meals and root stock survive JSON without being credited twice")
	var corrupt := state.snapshot()
	corrupt.flora.fed[eater] += 1.0
	check(ExpeditionState.restore(corrupt, 17) == null, "Manufactured food fails conservation validation")
	corrupt = state.snapshot()
	corrupt.flora.fed["unknown_sol"] = 0.0
	check(ExpeditionState.restore(corrupt, 17) == null, "A feeding record must name an admitted persistent Sol")
	corrupt = state.snapshot()
	corrupt.version = 19
	check(ExpeditionState.restore(corrupt, 17) == null, "Older development snapshots are rejected rather than silently reinterpreted")
	state = charged({"0:0": 95})
	snapshot = state.snapshot()
	snapshot.flora.nodes["1:0"].roots = 30.0
	snapshot.flora.absorbed += 30.0
	snapshot.flora.policy.refill = 100.0
	state = ExpeditionState.restore(snapshot, 17)
	state.set_flora_active(["1:0", "0:0"])
	var plants := func(_at: Vector2i, _reach: float) -> Array[Dictionary]: return [definition(Vector2i.ZERO, "plant")]
	state.advance_time(ExpeditionContract.ACTIVITY_INTERVAL)
	state.advance_flora(empty_candidates, environment(state), plants)
	var flights: Array = state.flora_view().flights
	check(flights.size() == 1 and flights[0].root and flights[0].amount == 5.0, "Root strands carry only the actual spare capacity of a nearby plant")
	if flights.is_empty(): return
	var flight: Dictionary = flights[0]
	check(state.flora_view().nodes["0:0"].energy == 95 and state.flora_view().nodes["1:0"].roots == 25, "Root energy leaves immediately but reaches its destination only on arrival")
	var loaded := ExpeditionState.restore(JSON.parse_string(JSON.stringify(state.snapshot())), 17)
	check(loaded != null and loaded.flora_view().flights == flights, "Partial root packets preserve their exact amount and destination in flight")
	corrupt = state.snapshot()
	corrupt.flora.flights[0].arrival += 1
	check(ExpeditionState.restore(corrupt, 17) == null, "A saved packet cannot silently change its physical source-to-destination timing")
	while state.activity_tick() < int(flight.arrival) - 1:
		state.advance_time(ExpeditionContract.ACTIVITY_INTERVAL)
		state.advance_flora(empty_candidates, environment(state), plants)
		check(state.flora_view().nodes["0:0"].energy == 95, "Incoming root capacity is reserved against ambient refill until the head arrives")
	state.set_flora_active([])
	step(state, empty_candidates)
	check(state.flora_view().nodes["0:0"].energy == 100 and absf(balance(state)) < 0.001, "The complete root packet reaches point B once, without disappearance or reserve overflow")
	step(state, empty_candidates)
	check(state.flora_view().nodes["0:0"].energy == 100, "A root packet cannot be delivered a second time")
	var species: Resource = load("res://resources/sol_species/crown_ear.tres")
	state = charged({})
	check(state.choose_starter(species.battle_profile("air"), 0), "Feeding admits a real selected field companion")
	snapshot = state.snapshot()
	snapshot.flora.nodes["1:0"].roots = 2.0
	snapshot.flora.absorbed = 2.0
	state = ExpeditionState.restore(snapshot, 17)
	state.set_flora_active(["1:0"])
	state.advance_time(ExpeditionContract.ACTIVITY_INTERVAL)
	state.advance_flora(empty_candidates, environment(state), Callable(), Vector2i(1, 0))
	check(state.sol_vastra_food(state.active_sol_view().id) == 2.0 and state.flora_view().nodes["1:0"].roots == 0 and absf(balance(state)) < 0.001, "The selected companion eats only available excess and cannot consume a negative balance")
	state = charged({"0:0": 100, "2:0": 100})
	state.set_flora_active(["0:0", "2:0"])
	var same_tree := func(_at: Vector2i, _reach: float) -> Array[Dictionary]: return [definition(Vector2i(1, 0), "tree")]
	step(state, same_tree)
	snapshot = state.snapshot()
	snapshot.flora.policy.work_limit = 1
	state = ExpeditionState.restore(snapshot, 17)
	state.set_flora_active([])
	var scheduled: int = state.flora_view().flights[0].arrival
	while state.activity_tick() < scheduled: step(state)
	var waiting: Array[Dictionary] = state.flora_transfers().filter(func(row: Dictionary) -> bool: return row.pending)
	check(waiting.size() == 1 and state.flora_view().nodes["1:0"].energy == 100, "An arrival-work limit retains the other real packet at its destination")
	if not waiting.is_empty():
		var waiting_id: int = waiting[0].id
		step(state)
		var completed: Array[Dictionary] = state.flora_transfers().filter(func(row: Dictionary) -> bool: return row.id == waiting_id)
		check(completed.size() == 1 and not completed[0].pending and completed[0].visual_sent + completed[0].arrival - completed[0].sent == state.activity_tick(), "A delayed packet starts its clearing tail only after the real destination credit")
		check(state.flora_view().nodes["1:0"].roots == 100 and absf(balance(state)) < 0.001, "Simultaneous packets credit once and expel the exact received excess")

## Dedicated flag avoids triggering the production scene's independent --capture runner.
func capture_scene(label: String) -> void:
	if not OS.get_cmdline_user_args().has("--capture-plants") and not OS.get_cmdline_user_args().has("--capture-trajectories"): return
	for i in range(3): await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://artifacts/plant-vastra")
	root.get_texture().get_image().save_png("res://artifacts/plant-vastra/" + label + ".png")

func presentation_journey() -> void:
	var Currents = preload("res://scripts/presentation/vastra_currents.gd")
	var scene: Node3D = load("res://scenes/world_3d.tscn").instantiate()
	root.add_child(scene)
	var world: Node2D = scene.world
	world.smoke_mode = true
	# Historical one-packet journey remains explicit; paced production is covered
	# by gradual_transfer_contract rather than silently changing its assumptions.
	world.vastra_settings = world.vastra_settings.duplicate(true)
	world.vastra_settings.plant_refill_rate = 4.0
	world.vastra_settings.plant_transfer_rate = 0.0
	world.new_expedition(17)
	scene.process_mode = Node.PROCESS_MODE_DISABLED
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280, 800)
	var currents: Node3D
	for child in scene.get_children():
		if child.get_script() == Currents: currents = child
	check(currents != null and not currents.study_mode and currents.network_edges.is_empty(), "Live play has no autonomous cosmetic transfers before plants charge")
	var plants: Array[Dictionary] = []
	var trees: Array[Dictionary] = []
	for chunk in scene.solid_chunks.values():
		for asset: Dictionary in chunk.living_sources.values():
			var at: Vector2i = asset.cell
			var kind: String = world.terrain.flora_kind(at, world.terrain.sample(at))
			if kind == "tree" and asset.kind == "tree": trees.append(asset)
			elif kind == "plant" and chunk.plant_instances.has(at) and FloraTraits.role(world.terrain.world_seed,{"id":FloraCatalog.id_for(at),"cell":[at.x,at.y],"kind":kind})=="emanator": plants.append(asset)
	plants.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return Vector2(a.cell).distance_squared_to(world.camera.position / 32.0) < Vector2(b.cell).distance_squared_to(world.camera.position / 32.0))
	var source: Dictionary = {}
	var target: Dictionary = {}
	for plant in plants:
		for tree in trees:
			if Vector2(plant.cell).distance_to(Vector2(tree.cell)) <= 3.0:
				source = plant
				target = tree
				break
		if not source.is_empty(): break
	check(not source.is_empty(), "The connected journey uses actual nearby rendered grass and tree assets")
	if source.is_empty():
		scene.free()
		return
	for i in range(10000):
		world.prepare_flora(Time.get_ticks_usec() + 2000)
		if world.flora_catalog.pending.is_empty(): break
	check(world.flora_catalog.pending.is_empty() and not world.persistent_state.flora_view().nodes.is_empty(), "The normal world controller admits canonical flora within bounded preparation slices")
	check(PlantVastra.valid(world.persistent_state.flora_view(), world.persistent_state.activity_tick()), "Canonical world admission creates a valid zero-energy ledger")
	var admitted_before: Dictionary = world.persistent_state.snapshot()
	var camera_before: Transform3D = scene.camera.transform
	scene.camera.rotate_y(0.5)
	world.prepare_flora(Time.get_ticks_usec() + 2000)
	check(world.persistent_state.snapshot() == admitted_before, "Changing the camera cannot change admitted reserves or target readiness")
	scene.camera.transform = camera_before
	var source_id := AffinityImprint.key(source.cell)
	var target_id := AffinityImprint.key(target.cell)
	var live_definitions: Array[Dictionary] = [definition(source.cell, "plant"), definition(target.cell, "tree")]
	world.persistent_state.admit_flora(live_definitions)
	var data: Dictionary = world.persistent_state.snapshot()
	data.flora.nodes[source_id].energy = 99.0
	data.flora.absorbed = 99.0
	data.flora.policy.refill = 4.0
	var state := ExpeditionState.restore(data, 17)
	world.replace_persistent_state(state)
	world.state_replaced.emit(state)
	state.activity_advanced.disconnect(world.advance_environment)
	state.set_flora_active([source_id])
	currents._process(0.6)
	settle_transfer_view(currents)
	check(currents.network_edges.is_empty(), "The preserved renderer emits nothing at reserve 99")
	world.inspected_cell = source.cell
	world.describe_cell(source.cell)
	world.inspection_card.more.button_pressed = true
	check(is_equal_approx(world.inspection_card.readings.vastra.bar.value, 99.0) and world.inspection_card.readings.vastra.label.text == "Vastra reserve", "Object Details shows stored energy rather than the fixed ambient concentration")
	await capture_scene("reserve-99")
	var target_definition := definition(target.cell, "tree")
	var resolver := func(_at: Vector2i, _reach: float) -> Array[Dictionary]: return [target_definition]
	var flights: Array = []
	for i in range(16):
		step(state, resolver)
		flights = state.flora_view().flights
		if not flights.is_empty(): break
	check(flights.size() == 1, "Ambient refill crosses 100 and creates a real packet in the live scene")
	world.inspect_mouse()
	world.inspection_card.meter_tweens.vastra.custom_step(world.inspection_card.settings.inspection_animation_seconds)
	check(is_equal_approx(world.inspection_card.readings.vastra.bar.value, state.flora_reading(source.cell).energy) and world.inspection_card.readings.vastra.bar.value < 99.0, "An open Details bar updates downward as the source emits its packet")
	if flights.is_empty():
		scene.free()
		return
	var reserve_after_send: float = world.inspection_card.readings.vastra.bar.value
	step(state, resolver)
	world.inspect_mouse()
	world.inspection_card.meter_tweens.vastra.custom_step(world.inspection_card.settings.inspection_animation_seconds)
	check(world.inspection_card.readings.vastra.bar.value > reserve_after_send and is_equal_approx(world.inspection_card.readings.vastra.bar.value, state.flora_reading(source.cell).energy), "An open Details bar rises again as the source absorbs more energy")
	currents._process(0.1)
	currents.finish_transition()
	currents.sync_wisps()
	check(currents.network_edges.size() == 1 and currents.network_edges[0].flight.id == flights[0].id, "A visible strand is tied to the conserved packet ID")
	var edge: Dictionary = currents.network_edges[0]
	check(edge.destination_asset.cell == target.cell and edge.end_phase > edge.start_phase, "The animation leads to the tree that will receive the energy")
	var target_organs: Dictionary = edge.destination_asset.get("organs",{})
	check(target_organs.has("reserve") and edge.points[-1].is_equal_approx(target_organs.reserve.position), "Plant transfers follow the recipient's authored organ route into its reserve, including buried anatomy")
	var curve_a: PackedVector3Array = currents.transfer_points(edge.points[0], edge.points[-1], 17, false)
	check(curve_a == currents.transfer_points(edge.points[0], edge.points[-1], 17, false), "Rebuilding the same transfer retains its trajectory")
	check(curve_a != currents.transfer_points(edge.points[0], edge.points[-1], 29, false), "Different transfers vary their bend rather than sharing one arch")
	check(curve_a[0] == edge.points[0] and curve_a[-1] == edge.points[-1], "Curved transfers preserve their exact source and destination attachments")
	var lateral := false
	for point: Vector3 in curve_a.slice(1, -1):
		check(point.y >= world.host.ground_height(Vector2(point.x, point.z)) + scene.vastra_settings.current_ground_clearance - 0.001, "Varied trajectories remain above terrain")
		var straight := Geometry3D.get_closest_point_to_segment(Vector3(point.x, 0, point.z), Vector3(curve_a[0].x, 0, curve_a[0].z), Vector3(curve_a[-1].x, 0, curve_a[-1].z))
		if Vector3(point.x, 0, point.z).distance_to(straight) > 0.01: lateral = true
	check(lateral, "Transfer curves also change direction horizontally")
	var flight: Dictionary = flights[0]
	var half := int((flight.sent + flight.arrival) / 2)
	while state.activity_tick() < half: step(state, resolver)
	currents._process(0.1)
	currents.finish_transition()
	currents.sync_wisps()
	var origin := Vector3(world.camera.position.x / 32.0, 0, world.camera.position.y / 32.0)
	var focus: Vector3 = edge.points[4] - origin
	var travel: Vector3 = edge.points[-1] - edge.points[0]
	var side := Vector3(-travel.z, 0, travel.x).normalized()
	scene.camera.position = focus + side * 3.0 + Vector3.UP * 1.8
	scene.camera.look_at(focus)
	if OS.get_cmdline_user_args().has("--capture-plants") or OS.get_cmdline_user_args().has("--capture-trajectories"):
		world.hud.visible = false
		scene.view_revision += 1
		world.plan_chunks()
		# Disposable close-up: fill its actual frustum synchronously before capture,
		# rather than showing unbuilt ground from the previous camera heading.
		for coord: Vector2i in world.pending.duplicate():
			world.publish_chunk(coord)
			world.pending.erase(coord)
	var before: Dictionary = state.snapshot()
	for i in range(30): currents._process(1.0 / 60.0)
	check(state.snapshot() == before, "Rendering and mote updates cannot manufacture, spend or advance energy")
	await capture_scene("packet-in-transit")
	while state.activity_tick() < int(flight.arrival): step(state, resolver)
	check(state.flora_view().nodes[target_id].energy == 100, "The real destination receives exactly 100 when its traveling head arrives")
	world.inspected_cell = target.cell
	world.describe_cell(target.cell)
	check(is_equal_approx(world.inspection_card.readings.vastra.bar.value, 100.0), "Tree Details reflects the received packet immediately")
	currents._process(0.1)
	currents.finish_transition()
	currents.sync_wisps()
	await capture_scene("packet-arrived")
	check(PlantVastra.valid(state.flora_view(), state.activity_tick()), "The full live charge/strand/arrival journey remains save-valid")
	# Exercise the actual activity callback with a complete geographic catalogue,
	# including many simultaneous plant emissions and tree relays.
	for i in range(10000):
		world.prepare_flora(Time.get_ticks_usec() + 2000)
		if world.flora_catalog.pending.is_empty(): break
	state.activity_advanced.connect(world.advance_environment)
	for i in range(120): state.advance_time(ExpeditionContract.ACTIVITY_INTERVAL)
	var live: Dictionary = state.flora_view()
	check(live.absorbed > 100 and live.serial > 1 and not live.flights.is_empty(), "Normal active-clock service refills plants and creates real circulation without rendering")
	check(PlantVastra.valid(live, state.activity_tick()) and absf(balance(state)) < 0.01, "Concurrent active-area transfers remain save-valid and conserve energy")
	check(ExpeditionState.restore(JSON.parse_string(JSON.stringify(state.snapshot())), 17) != null, "A populated running energy network survives the real JSON save boundary")
	var save: Dictionary = ExpeditionSave.snapshot(world.terrain.world_seed, world.cell, world.visited, world.returned, world.terrain.generation_version, world.terrain.climate, state.snapshot(), world.terrain.relief, world.terrain.scenery_parameters)
	check(ExpeditionSave.validate(save), "Populated energy-network saves are validated against the authoritative flora admission rule")
	currents._process(0.6)
	settle_transfer_view(currents)
	currents.finish_transition()
	currents.sync_wisps()
	await capture_scene("varied-circulation")
	# A conserved root packet uses the same renderer and follows the ground outward.
	data = state.snapshot()
	# Start this controlled packet with an unreserved recipient. The preceding
	# live network can already have root deliveries reserving all of its capacity.
	var root_policy: Dictionary = data.flora.policy.duplicate(true)
	var ambient_policy: Variant = data.ambient.policy
	data.flora = PlantVastra.empty()
	data.flora.policy = root_policy
	for entry: Dictionary in live_definitions:
		var row := entry.duplicate(true)
		row.merge({"energy":0.0,"roots":30.0 if row.id == target_id else 0.0,"since":state.activity_tick(),"emissions":0})
		data.flora.nodes[row.id] = row
	data.flora.absorbed = 30.0
	data.ambient = AmbientVastra.empty()
	data.ambient.policy = ambient_policy
	data.ecology = VesselEcology.empty()
	state = ExpeditionState.restore(data, 17)
	check(state != null,"The isolated root-packet fixture is a valid expedition")
	if state == null:
		scene.free()
		return
	world.replace_persistent_state(state)
	world.state_replaced.emit(state)
	state.activity_advanced.disconnect(world.advance_environment)
	state.set_flora_active([target_id])
	var nearby_plants := func(_at: Vector2i, _reach: float) -> Array[Dictionary]: return [definition(source.cell, "plant")]
	state.advance_time(ExpeditionContract.ACTIVITY_INTERVAL)
	state.advance_flora(empty_candidates, environment(state), nearby_plants)
	currents._process(0.6)
	settle_transfer_view(currents)
	currents.finish_transition()
	currents.sync_wisps()
	var root_edges: Array = currents.network_edges.filter(func(row: Dictionary) -> bool: return row.flight.root)
	check(root_edges.size() > 0, "Real expelled energy creates an outward root strand to an actual nearby plant")
	if not root_edges.is_empty():
		for point: Vector3 in root_edges[0].points.slice(1, -1):
			check(point.y - world.host.ground_height(Vector2(point.x, point.z)) < 0.1, "Root strands branch along the ground rather than from the crown")
		var root_trip: Dictionary = root_edges[-1].flight
		state.set_flora_active([])
		while state.activity_tick() < int((root_trip.sent + root_trip.arrival) / 2): step(state, empty_candidates)
		currents._process(0.6)
		settle_transfer_view(currents)
		currents.finish_transition()
		currents.sync_wisps()
		var root_focus: Vector3 = root_edges[0].points[4] - Vector3(world.camera.position.x / 32.0, 0, world.camera.position.y / 32.0)
		scene.camera.position = root_focus + Vector3(3, 1.8, 3)
		scene.camera.look_at(root_focus)
	await capture_scene("root-overflow")
	var root_save := ExpeditionSave.snapshot(world.terrain.world_seed, world.cell, world.visited, world.returned, world.terrain.generation_version, world.terrain.climate, state.snapshot(), world.terrain.relief, world.terrain.scenery_parameters)
	check(ExpeditionSave.validate(root_save), "A real root-transfer expedition passes the full canonical save envelope validation")

	scene.free()
	await process_frame

func hierarchy_checks() -> void:
	var chunk = preload("res://scripts/presentation/solid_chunk.gd").new()
	# Deliberately no botanical keyword: membership must survive renaming/replacement.
	chunk.register_living_source(Vector2i(20, 20), "detail", "asset_019.fbx", Vector3(20, 0.3, 20))
	check(chunk.living_sources.has(Vector2i(20, 20)), "Explicit living membership accepts an arbitrary asset name")
	var endpoint: Dictionary = chunk.living_sources[Vector2i(20, 20)]
	check(endpoint.flora_id == "20:20", "Visual endpoint retains the stable canonical flora identity")
	chunk.register_living_source(Vector2i(20, 20), "detail", "other_clump", Vector3(20.2, 0.2, 20.1))
	check(chunk.living_sources.size() == 1, "Multiple clumps share one cell endpoint and reserve")
	chunk.register_living_source(Vector2i(21, 20), "detail", "flower_carved_in_rock", Vector3.ZERO, Vector3.INF, false)
	check(not chunk.living_sources.has(Vector2i(21, 20)), "Explicit nonliving membership overrides misleading filenames")
	chunk.free()
	var terrain := WorldTerrain.new(2601026)
	var composition = load("res://resources/scenery/bounded_composition.tres")
	var wetland: NaturePatch = composition.patches[2]
	var definitions: Array[Dictionary] = []
	var wet_cells := 0
	for y in range(wetland.bounds.position.y, wetland.bounds.end.y):
		for x in range(wetland.bounds.position.x, wetland.bounds.end.x):
			var cell := Vector2i(x, y)
			var data := terrain.sample(cell)
			if data.ground not in [WorldTerrain.Ground.WATER, WorldTerrain.Ground.SAND]: continue
			var record: Dictionary = composition.placement_for(terrain, cell, wetland, 3, 68, 0.0, false, true, false)
			var expected := "plant" if record.get("living", false) else ""
			check(terrain.flora_kind(cell, data) == expected, "Wetland Vastra coverage matches fixed generated plants without render chunks")
			if expected.is_empty(): continue
			wet_cells += 1
			definitions.append(definition(cell, expected))
	check(wet_cells > 0, "Wetland hierarchy fixture exercises actual water/bank vegetation")
	var catalogue := FloraCatalog.new(terrain)
	var focus_cell := Vector2i(definitions[0].cell[0], definitions[0].cell[1]) if not definitions.is_empty() else Vector2i(40, 40)
	catalogue.request(focus_cell, 0, 1.0)
	while not catalogue.pending.is_empty(): catalogue.advance(Time.get_ticks_usec() + 2000)
	var catalogued := {}
	for row in catalogue.active_definitions(): catalogued[row.id] = row
	for row in definitions:
		if FloraCatalog.region(Vector2i(row.cell[0], row.cell[1])) == FloraCatalog.region(focus_cell):
			check(catalogued.has(row.id) and catalogued[row.id] == row, "Camera-free catalogue registers each wetland plant in its geographic parent")
	var state := ExpeditionState.new(2601026)
	state.configure_flora(VastraSettings.new().plant_parameters())
	check(state.admit_flora(definitions), "Generated wetland plants enter the existing saved ledger")
	var before := state.snapshot()
	check(state.admit_flora(definitions) and state.snapshot() == before, "Reconstruction cannot duplicate a generated plant reserve")
	var restored := ExpeditionState.restore(JSON.parse_string(JSON.stringify(before)), 2601026)
	check(restored != null and restored.flora_view() == state.flora_view(), "Registered wetland flora survives JSON save/load")
