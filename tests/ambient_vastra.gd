extends SceneTree
var checks := 0
var failures := 0

func check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(label)

func _initialize() -> void:
	create_timer(60).timeout.connect(func() -> void: push_error("Ambient contract timed out"); quit(1))
	run.call_deferred()

func charged(conversion: float = 1.0) -> ExpeditionState:
	var state := ExpeditionState.new(17)
	var tuning := VastraSettings.new()
	tuning.plant_refill_rate = 0
	tuning.ambient_concentration_per_unit = conversion
	state.configure_flora(tuning.plant_parameters())
	state.configure_ambient(tuning.ambient_parameters())
	state.admit_flora([{"id": "0:0", "cell": [0,0], "kind": "plant"}])
	var data := state.snapshot()
	data.flora.nodes["0:0"].energy = 100.0
	data.flora.absorbed = 100.0
	state = ExpeditionState.restore(data,17)
	state.set_flora_active(["0:0"])
	return state

func step(state: ExpeditionState, base: int = 50, incomplete: bool = false) -> void:
	state.advance_time(ExpeditionContract.ACTIVITY_INTERVAL)
	state.advance_flora(func(_at: Vector2i,_reach: float) -> Variant: return null if incomplete else [],func(at: Vector2i) -> Dictionary: return state.environment_view(at,{"concentration": base,"overload": 0}))

func stable(state: ExpeditionState) -> Dictionary:
	return JSON.parse_string(JSON.stringify(state.snapshot(),"",true,true))

func run() -> void:
	var state := charged()
	var notifications := {"count":0}
	state.flora_changed.connect(func() -> void: notifications.count += 1)
	step(state,50,true)
	check(state.flora_reading(Vector2i.ZERO).energy == 100 and state.ambient_transfers().is_empty(),"Incomplete geographic discovery cannot invent an isolated source")
	step(state)
	check(notifications.count == 1,"An ambient-only emission invalidates the live transfer renderer")
	check(state.flora_reading(Vector2i.ZERO).energy == 0 and state.ambient_transfers().size() == 4,"Isolated full plant emits four conserved outward packets")
	check(state.flora_view().exported == 100 and state.ambient_view().received == 100,"Cross-owner export and receipt agree")
	check(state.ambient_view().credited == 0 and state.environment_view(Vector2i.UP,{"concentration":50}).concentration == 50,"Finite flight cannot credit concentration early")
	var before := stable(state)
	state.advance_flora(func(_at: Vector2i,_reach: float) -> Array: return [],func(at: Vector2i) -> Dictionary: return state.environment_view(at,{"concentration":50,"overload":0}))
	check(stable(state) == before,"Duplicate same-tick service cannot repeat debit or delivery")
	check(notifications.count == 1,"Duplicate service cannot publish another transfer notification")
	var restored := ExpeditionState.restore(before,17)
	check(restored != null,"Midflight JSON snapshot restores")
	restored.set_flora_active(["0:0"])
	for index in range(12):
		step(state)
		step(restored)
	check(stable(state) == stable(restored),"Midflight save/load continues identically")
	check(state.ambient_view().credited == 100 and state.ambient_view().flights.is_empty(),"Four arrivals credit exactly 100 units once")
	for offset: Vector2i in AmbientVastra.DIRECTIONS:
		check(state.environment_view(offset,{"concentration":50,"overload":0}).concentration == 75,"Default one-to-one conversion credits 25 concentration points")
	check(ExpeditionState.valid_snapshot(state.snapshot(),17),"Conserved committed expedition passes strict snapshot validation")
	var corrupt := state.snapshot()
	corrupt.ambient.credited += 1
	check(ExpeditionState.restore(corrupt,17) == null,"Forged ambient credit is rejected")
	corrupt = state.snapshot()
	corrupt.flora.exported -= 1
	check(ExpeditionState.restore(corrupt,17) == null,"Cross-ledger mismatch is rejected")
	var converted := charged(0.5)
	for index in range(12): step(converted)
	check(converted.ambient_view().credited == 96 and converted.ambient_view().pending.size() == 4,"Fractional conversion retains undelivered residue rather than rounding it away")
	check(ExpeditionState.valid_snapshot(converted.snapshot(),17),"Fractional residual survives validation")
	# Saturated neighbors route toward additional cells at finite speed. A rotor
	# advances fairly instead of repeatedly choosing a preferred direction.
	state = charged()
	for offset: Vector2i in AmbientVastra.DIRECTIONS: state.set_environment(offset,{"concentration":100})
	for index in range(80): step(state)
	check(state.ambient_view().credited == 100,"Overflow traverses saturated neighbors until other tiles accept it")
	check(ExpeditionState.valid_snapshot(state.snapshot(),17),"Saturated relay preserves every transferred unit")
	check(state.environment_view(Vector2i.UP,{"concentration":50,"overload":0}).overload == 0,"Ordinary overflow creates no ecological overload")
	# Pure routing contract: a blocked destination freezes its real flight clock.
	var ledger := AmbientVastra.empty()
	ledger.policy = VastraSettings.new().ambient_parameters()
	AmbientVastra.offer(ledger,Vector2i.ZERO,"plant",100,0)
	var locked := func(at: Vector2i) -> bool: return at == Vector2i.UP
	var credit := func(_at: Vector2i,amount: float,_rate: float) -> Dictionary: return {"units":amount,"full":false}
	for tick in range(1,15): AmbientVastra.advance(ledger,tick,locked,credit)
	check(ledger.credited == 75 and ledger.flights.size() == 1,"Local combat ownership freezes only the reserved path")
	check(ledger.flights[0].sent == 14 and AmbientVastra.valid(ledger,14),"Frozen clock shifts remain valid and conserved")
	for tick in range(15,25): AmbientVastra.advance(ledger,tick,func(_at: Vector2i) -> bool: return false,credit)
	check(ledger.credited == 100,"Released combat path resumes and credits once")
	# Explicit work budget and technical backpressure without discarding a source.
	ledger = AmbientVastra.empty()
	ledger.policy = VastraSettings.new().ambient_parameters()
	ledger.policy.work_limit = 1
	var untouched := ledger.duplicate(true)
	check(not AmbientVastra.offer(ledger,Vector2i.ZERO,"plant",NAN,0) and not AmbientVastra.offer(ledger,Vector2i.ZERO,"tile",100,0) and ledger == untouched,"Invalid offers cannot poison the conserved ledger")
	for index in range(AmbientVastra.MAX_FLIGHTS/4):
		AmbientVastra.offer(ledger,Vector2i.ZERO,"plant",4,0)
	var full := ledger.duplicate(true)
	check(not AmbientVastra.offer(ledger,Vector2i.ZERO,"plant",100,0) and ledger == full,"Flight-cap backpressure leaves source offer untouched")
	AmbientVastra.advance(ledger,10,func(_at: Vector2i) -> bool: return false,credit)
	check(ledger.flights.size() == AmbientVastra.MAX_FLIGHTS-1 and ledger.credited == 1,"One-visit budget bounds both arrival and relay processing")
	check(AmbientVastra.valid(ledger,10),"Backlogged capacity remains conserved")
	var whole := charged()
	var divided := charged()
	for owner: ExpeditionState in [whole,divided]:
		owner.activity_advanced.connect(func(_tick: int) -> void:
			owner.advance_flora(func(_at: Vector2i,_reach: float) -> Array: return [],func(at: Vector2i) -> Dictionary: return owner.environment_view(at,{"concentration":50,"overload":0})))
	for index in range(24):
		whole.advance_time(0.75)
		divided.advance_time(0.375)
		divided.advance_time(0.375)
	check(stable(whole) == stable(divided),"Frame partitioning retains identical ambient accounting and arrivals")
	for owner: ExpeditionState in [whole,divided]:
		for connection: Dictionary in owner.activity_advanced.get_connections(): owner.activity_advanced.disconnect(connection.callable)
	print("AMBIENT VASTRA: %d checks, %d failures" % [checks,failures])
	quit(0 if failures == 0 else 1)
