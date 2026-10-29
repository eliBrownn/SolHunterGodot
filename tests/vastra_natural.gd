extends SceneTree

var checks := 0
var failures := 0
var lookups := 0
const POLICY := {"interval": 10, "points": 1, "work_limit": 32}

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func _initialize() -> void:
	create_timer(120).timeout.connect(func() -> void: quit(1))
	run.call_deferred()

func at_tick(state: ExpeditionState, tick: int) -> ExpeditionState:
	var data := state.snapshot()
	data.activity_tick = tick
	return ExpeditionState.restore(data, 17)

func values(state: ExpeditionState, cell: Vector2i = Vector2i.ZERO) -> Dictionary:
	return state.environment_view(cell, {})

func profile(_key: String) -> Dictionary:
	lookups += 1
	return {"region": "fixture_region", "equilibrium": 50, "budget": 1}

func run() -> void:
	for concentration in [0, 50, 100]:
		var state := ExpeditionState.new(17)
		state.set_environment(Vector2i.ZERO, {"concentration": concentration, "overload": 80})
		state.advance_environment(POLICY)
		state = at_tick(state, 29)
		check(state.advance_environment(POLICY) == 1 and values(state).overload == 78 and values(state).concentration == concentration, "Natural recovery is independent of concentration and population")
		check(state.natural_view().recovery_ticks["0:0"] == 20, "Recovery retains the fractional interval instead of resetting its age")
		var before := state.snapshot()
		check(state.advance_environment(POLICY) == 0 and state.snapshot() == before, "Repeated same-tick processing cannot grant extra healing")
		state = at_tick(state, 30)
		state.advance_environment(POLICY)
		check(values(state).overload == 77, "A retained fraction completes at the next interval boundary")
		state = at_tick(state, ExpeditionState.MAX_SAFE_INTEGER)
		state.advance_environment(POLICY)
		check(values(state).overload == 0 and state.natural_view().recovery_ticks.is_empty(), "Huge elapsed debt heals in constant work without integer overflow")
	var state := ExpeditionState.new(17)
	state.set_environment(Vector2i.ZERO, {"concentration": 100, "overload": 20})
	state = at_tick(state, 10000)
	state.advance_environment(POLICY)
	check(values(state).overload == 20 and state.natural_view().recovery_ticks["0:0"] == 10000, "Unknown age starts a full interval at first processing, not an invented legacy history")
	var before := state.snapshot()
	for field in POLICY:
		for invalid in [true, -1, INF, NAN, "1", null, 1.5]:
			var bad := POLICY.duplicate()
			bad[field] = invalid
			check(state.advance_environment(bad) == -1 and state.snapshot() == before, "Invalid settings fail before scheduling or mutation")
	var disabled := {"interval": 10, "points": 0, "work_limit": 32}
	state = ExpeditionState.new(17)
	state.set_environment(Vector2i.ZERO, {"overload": 5})
	state.advance_environment(disabled)
	check(values(state).overload == 5 and state.natural_view().recovery_ticks.is_empty(), "Disabled recovery creates no speculative timestamp")
	state = at_tick(state, 1)
	state.advance_environment(POLICY)
	state = at_tick(state, 15)
	state.advance_environment(disabled)
	check(state.natural_view().recovery_ticks["0:0"] == 1, "Disabling recovery preserves known fractional debt")
	state = at_tick(state, 21)
	state.advance_environment(POLICY)
	check(values(state).overload == 3, "Re-enabling recovery applies the current policy to retained age")
	verify_replenishment()
	verify_human_continuity()
	verify_persistence()
	verify_live_scene()
	print("NATURAL VASTRA: %d checks, %d failures." % [checks, failures])
	quit(0 if failures == 0 else 1)

func verify_replenishment() -> void:
	var state := ExpeditionState.new(17)
	for index in range(3):
		state.set_environment(Vector2i(index, 0), {"concentration": 48, "overload": 0})
	lookups = 0
	check(state.advance_environment(POLICY, profile) == 1 and lookups == 2, "One regional concentration budget is shared across cells; exhausted work remains first")
	check(values(state).concentration == 49 and values(state, Vector2i(1, 0)).concentration == 48 and state.natural_view().cursor == 1, "Budget exhaustion preserves the next tile's priority")
	var before := state.snapshot()
	check(state.advance_environment(POLICY, profile) == 0 and state.snapshot() == before, "Repeated calls cannot refresh a natural regional budget")
	state = at_tick(state, 1)
	state.advance_environment(POLICY, profile)
	check(values(state, Vector2i(1, 0)).concentration == 49 and values(state).overload == 0, "Next tick services deferred concentration without creating overload")
	state = at_tick(state, 2)
	var calls := [0]
	var invalid_profile := func(_key: String) -> Variant:
		calls[0] += 1
		return {"region": "fixture_region", "equilibrium": 50, "budget": 3} if calls[0] == 1 else {"budget": true}
	before = state.snapshot()
	check(state.advance_environment(POLICY, invalid_profile) == -1 and state.snapshot() == before, "A malformed later profile cannot partially commit earlier tiles")
	var small := {"interval": 10, "points": 1, "work_limit": 1}
	lookups = 0
	check(state.advance_environment(small, profile) == 1 and lookups == 1, "Configured work cap bounds profile lookups independently of stored size")
	state = ExpeditionState.new(17)
	state.set_environment(Vector2i.ZERO, {"concentration": 52, "overload": 0})
	state.advance_environment(POLICY, profile)
	check(values(state).concentration == 51 and values(state).overload == 0, "Concentration above equilibrium balances downward without inventing overload")
	state = ExpeditionState.new(17)
	state.set_environment(Vector2i.ZERO, {"overload": 5})
	state.advance_environment(POLICY, profile)
	check(not values(state).has("concentration"), "Partial legacy deltas never acquire invented concentration defaults")

func event(sequence: int, amount: int) -> Dictionary:
	return {"actor_kind": "player", "actor_id": "fixture", "sequence": sequence, "kind": "disturbance", "cell": [0, 0], "harvest_amount": 0, "overload_delta": amount}

func verify_human_continuity() -> void:
	var state := ExpeditionState.new(17)
	state.apply_human_activity(event(1, 1), {"concentration": 50, "overload": 0})
	check(state.natural_view().recovery_ticks["0:0"] == 0, "New human damage anchors its recovery epoch atomically")
	state = at_tick(state, 5)
	state.apply_human_activity(event(2, 2))
	check(state.natural_view().recovery_ticks["0:0"] == 0, "Additional damage does not erase earned recovery progress")
	var before := state.snapshot()
	check(state.apply_human_activity(event(2, 2)).replayed and state.snapshot() == before, "Replayed disturbance cannot restart its recovery interval")
	state = at_tick(state, 30)
	state.advance_environment(POLICY)
	check(values(state).overload == 0 and state.natural_view().recovery_ticks.is_empty(), "Fully recovered damage discards its old epoch")
	state = at_tick(state, 31)
	state.apply_human_activity(event(3, 2))
	check(state.natural_view().recovery_ticks["0:0"] == 31, "Fresh damage after full healing starts a new full interval")
	state.set_environment(Vector2i.ZERO, {"overload": 0})
	check(state.natural_view().recovery_ticks.is_empty(), "Explicit clearing cannot leave a timestamp attached to healthy state")

func verify_persistence() -> void:
	var state := ExpeditionState.new(17)
	for index in range(10):
		state.set_environment(Vector2i(index, 0), {"concentration": 50, "overload": 5})
	var small := {"interval": 10, "points": 1, "work_limit": 1}
	state.advance_environment(small)
	var clone := ExpeditionState.restore(JSON.parse_string(JSON.stringify(state.snapshot(), "", true, true)), 17)
	for tick in range(1, 30):
		state = at_tick(state, tick)
		clone = at_tick(clone, tick)
		state.advance_environment(small)
		clone.advance_environment(small)
	check(state.snapshot() == clone.snapshot() and state.natural_view().cursor == 0, "Saved round-robin position and interval fractions reproduce uninterrupted scheduling")
	for index in range(10):
		check(values(state, Vector2i(index, 0)).overload < 5, "Every queued tile eventually receives service")
	var snapshot := state.snapshot()
	var detached := state.natural_view()
	detached.order.clear()
	detached.recovery_ticks.clear()
	check(state.snapshot() == snapshot, "Schedule reads cannot mutate queue or damage ages")
	for version in [1, 2]:
		var old := snapshot.duplicate(true)
		old.version = version
		old.erase("natural")
		old.erase("discoveries")
		old.erase("roaming")
		old.erase("battle")
		old.erase("movebooks")
		old.erase("affinity_tiles")
		old.erase("wild_population")
		old.erase("collection")
		old.erase("sol_stats")
		old.erase("retraining_items")
		if old.has("battle"):
			old.battle.erase("captures")
		if version == 1:
			old.erase("human_activity")
		var upgraded := ExpeditionState.restore(old, 17)
		check(upgraded != null and upgraded.natural_view().recovery_ticks.is_empty() and upgraded.snapshot().tile_deltas == old.tile_deltas, "Legacy domain envelopes preserve deltas without fabricated damage ages")
	var path := "user://natural-vastra-%d.json" % Time.get_ticks_usec()
	var save := ExpeditionSave.snapshot(17, Vector2i.ZERO, false, false, WorldTerrain.GENERATION_VERSION, {}, snapshot)
	check(ExpeditionSave.write(save, path) == OK, "Portable save accepts scheduler state without changing outer save format")
	var original := FileAccess.get_file_as_string(path)
	clone = ExpeditionState.restore(ExpeditionSave.read_save(path).world_state, 17)
	check(clone.snapshot() == snapshot and clone.advance_environment(small) == 0, "Actual file reload cannot process an already-serviced tick again")
	var malformed: Array[Dictionary] = []
	for field in ["order", "cursor", "last_tick", "recovery_ticks"]:
		var bad := snapshot.duplicate(true)
		bad.natural[field] = true
		malformed.append(bad)
	var bad := snapshot.duplicate(true)
	bad.natural.recovery_ticks["0:0"] = snapshot.activity_tick + 1
	malformed.append(bad)
	bad = snapshot.duplicate(true)
	bad.natural.order[0] = bad.natural.order[1]
	malformed.append(bad)
	bad = snapshot.duplicate(true)
	bad.natural.recovery_ticks["999:999"] = 0
	malformed.append(bad)
	bad = snapshot.duplicate(true)
	bad.tile_deltas["0:0"].overload = 0
	malformed.append(bad)
	for data in malformed:
		check(ExpeditionState.restore(data, 17) == null, "Malformed, duplicate, orphan, future, or healthy-tile timestamps reject")
		save.world_state = data
		check(ExpeditionSave.write(save, path) == ERR_INVALID_DATA and FileAccess.get_file_as_string(path) == original, "Invalid outgoing schedule cannot overwrite the previous valid save")
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(path + suffix):
			DirAccess.remove_absolute(path + suffix)

func verify_live_scene() -> void:
	var scene: Node3D = (load("res://scenes/world_3d.tscn") as PackedScene).instantiate()
	scene.sighting_settings = SightingSettings.new()
	scene.sighting_settings.enabled = false # Keep the manually replaced recovery fixture content-free.
	root.add_child(scene)
	var world: Node2D = scene.world
	world.smoke_mode = true
	world.new_expedition(17)
	var initial := ExpeditionState.new(17)
	initial.apply_human_activity(event(1, 2), {"concentration": 100, "overload": 0})
	initial = at_tick(initial, 119)
	world.replace_persistent_state(initial)
	world.paused = true
	world.smoke_mode = false
	world._process(0.75)
	check(values(world.persistent_state).overload == 2 and world.persistent_state.activity_tick() == 119, "Pause freezes live recovery and its clock")
	world.paused = false
	world._process(0.75)
	check(values(world.persistent_state).overload == 1 and values(world.persistent_state).concentration == 100, "Live activity callback heals at the source default interval without regional or population generation")
	world.smoke_mode = true
	var before: Dictionary = world.persistent_state.snapshot()
	var old: ExpeditionState = world.persistent_state
	world.replace_persistent_state(ExpeditionState.restore(before, 17))
	old.advance_time(0.75)
	check(world.persistent_state.snapshot() == before, "Replaced states cannot leave a callback subscribed to the new world")
	for coord: Vector2i in world.chunks.keys():
		world.remove_chunk(coord)
	world.rebuild_world()
	check(world.persistent_state.snapshot() == before, "Render reconstruction cannot reset the recovery queue or epochs")
	var path := "user://natural-live-%d.json" % Time.get_ticks_usec()
	world.save_game(path)
	var encoded := FileAccess.get_file_as_string(path)
	world.new_expedition(42)
	check(world.persistent_state.natural_view() == VastraNatural.empty_schedule(), "New expeditions clear the previous recovery schedule")
	world.load_game(path)
	check(world.persistent_state.snapshot() == before and world.persistent_state.apply_human_activity(event(1, 2)).replayed, "Live reload restores interval progress and human replay evidence together")
	var invalid: Dictionary = JSON.parse_string(encoded)
	invalid.world_state.natural.recovery_ticks["0:0"] = before.activity_tick + 1
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(invalid))
	file.close()
	var previous_state: ExpeditionState = world.persistent_state
	var previous_terrain: WorldTerrain = world.terrain
	world.load_game(path)
	check(world.persistent_state == previous_state and world.terrain == previous_terrain and world.persistent_state.snapshot() == before, "Future incoming recovery epochs cannot replace any part of the live world")
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(path + suffix):
			DirAccess.remove_absolute(path + suffix)
	scene.free()
