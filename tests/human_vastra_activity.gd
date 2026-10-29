extends SceneTree

var checks := 0
var failures := 0
var signal_count := 0

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func _initialize() -> void:
	create_timer(120).timeout.connect(func() -> void: quit(1))
	run.call_deferred()

func command(actor: String = "fixture_player", sequence: int = 1, amount: int = 1, cell: Vector2i = Vector2i(-2, 4)) -> Dictionary:
	return {"actor_kind": "player", "actor_id": actor, "sequence": sequence, "kind": "harvest",
		"cell": [cell.x, cell.y], "harvest_amount": amount, "overload_delta": 0}

func ambient() -> Dictionary:
	return {"concentration": 50, "overload": 0}

func run() -> void:
	var state := ExpeditionState.new(17)
	state.environment_changed.connect(func(_cell: Vector2i) -> void:
		signal_count += 1
		check(state.human_activity_view().events.size() > 0, "Observers see the committed receipt alongside the tile"))
	var first := command("player", 1, 2)
	var result := state.apply_human_activity(first, ambient(), "fixture_west", 3)
	check(result == {"concentration": 48, "overload": 0, "excess": 0, "replayed": false}, "Sustainable ambient harvesting leaves overload unchanged")
	var second := command("device", 1, 1, Vector2i(16, 4))
	second.actor_kind = "infrastructure"
	check(not state.apply_human_activity(second, ambient(), "fixture_west", 3).is_empty(), "A second producer shares the same regional capacity across render chunks")
	var before := state.snapshot()
	check(state.apply_human_activity(command("third"), ambient(), "fixture_west", 3).is_empty() and state.snapshot() == before, "Splitting requests across actors cannot bypass a spent budget")
	check(not state.apply_human_activity(command("east", 1, 1, Vector2i(100, 4)), ambient(), "fixture_east", 3).is_empty(), "Different authored regions retain independent usage")
	var excessive := command("excess", 1, 8)
	before = state.snapshot()
	check(state.apply_human_activity(excessive, ambient(), "fixture_west", 3).is_empty() and state.snapshot() == before, "Excess requires an explicitly authored overload consequence")
	excessive.overload_delta = 7
	result = state.apply_human_activity(excessive, ambient(), "fixture_west", 3)
	check(result.concentration == 40 and result.overload == 7 and result.excess == 8, "Authored overload need not equal the excess amount")
	state.set_environment(Vector2i(-2, 4), {"concentration": 90, "overload": 95})
	var signals_before := signal_count
	before = state.snapshot()
	result = state.apply_human_activity(first)
	check(result.replayed and result.concentration == 48 and result.overload == 0 and state.snapshot() == before and signal_count == signals_before, "Replay returns the original receipt without conditions, new effects, usage, or signals")
	result.concentration = 0
	check(state.apply_human_activity(first).concentration == 48, "Returned receipts cannot mutate saved replay evidence")
	var view := state.human_activity_view()
	view.events.clear()
	view.spent.clear()
	check(state.snapshot() == before, "Ledger reads are detached")
	for invalid in [command("player", 3), command("player", 1, 2, Vector2i.ZERO), command("new", 2)]:
		check(state.apply_human_activity(invalid, ambient(), "fixture_west", 3).is_empty() and state.snapshot() == before, "Sequence gap, conflicting replay, or missing initial sequence rejects atomically")
	state.advance_time(0.75)
	check(not state.apply_human_activity(command("player", 2, 3), ambient(), "fixture_west", 3).is_empty(), "Only persisted activity time opens a fresh shared budget window")
	before = state.snapshot()
	check(state.apply_human_activity(first).is_empty() and state.snapshot() == before, "Older commands stay rejected after the latest receipt replaces them")
	check(state.human_activity_view().spent == {"fixture_west": 3}, "A new window discards previous window usage, not receipt history")
	var disturbance := command("builder", 1, 0)
	disturbance.kind = "disturbance"
	disturbance.overload_delta = 9
	result = state.apply_human_activity(disturbance, ambient())
	check(result.overload == 100 and result.concentration == 87 and result.excess == 0, "Human disturbance saturates overload independently of concentration")
	before = state.snapshot()
	for kind in ["sol", "natural", "weather", ""]:
		var bad := command("invalid")
		bad.actor_kind = kind
		check(state.apply_human_activity(bad, ambient(), "fixture_west", 3).is_empty() and state.snapshot() == before, "Natural/Sol provenance cannot create unnatural overload")
	for field in ["sequence", "harvest_amount", "overload_delta"]:
		for value in [true, -1, 1.5, INF, NAN, "1", null]:
			var bad := command("invalid")
			bad[field] = value
			check(state.apply_human_activity(bad, ambient(), "fixture_west", 3).is_empty() and state.snapshot() == before, "Invalid scalar effects reject without partial mutation")
	var harmless := command("harmless")
	harmless.overload_delta = 1
	check(state.apply_human_activity(harmless, ambient(), "unused", 3).is_empty(), "Sustainable harvesting cannot silently add overload")
	check(state.apply_human_activity(command("empty", 1, 1, Vector2i(101, 4)), {"concentration": 0, "overload": 0}, "unused", 3).is_empty(), "Insufficient ambient concentration rejects rather than granting a partial effect")
	check(state.apply_human_activity(command("unknown"), ambient()).is_empty(), "Unknown regional capacity rejects harvesting")
	check(state.apply_human_activity(command("zero"), ambient(), "unused", 0).is_empty(), "Zero budget grants no sustainable capacity")
	var zero_excess := command("zero")
	zero_excess.overload_delta = 2
	check(not state.apply_human_activity(zero_excess, ambient(), "unused", 0).is_empty(), "Zero capacity still permits explicitly authored excessive harvesting")
	verify_limits()
	verify_persistence(state, disturbance)
	verify_live_scene()
	print("HUMAN VASTRA: %d checks, %d failures." % [checks, failures])
	quit(0 if failures == 0 else 1)

func verify_limits() -> void:
	var baseline := ExpeditionState.new(17).snapshot()
	for index in range(HumanVastraActivity.MAX_PRODUCERS):
		var event := command("producer%d" % index)
		baseline.human_activity.events[HumanVastraActivity.producer(event)] = {"event": event, "effect": {"concentration": 49, "overload": 0, "excess": 0}}
	var state := ExpeditionState.restore(baseline, 17)
	check(state != null, "Producer-cap fixture is itself valid")
	check(state.apply_human_activity(command("new"), ambient(), "west", 3).is_empty() and state.snapshot() == baseline, "Producer capacity never evicts old replay protection")
	check(not state.apply_human_activity(command("producer0", 2), ambient(), "west", 3).is_empty(), "Existing producers can continue at the producer cap")
	baseline = ExpeditionState.new(17).snapshot()
	for index in range(HumanVastraActivity.MAX_REGIONS):
		baseline.human_activity.spent["region%d" % index] = 1
	state = ExpeditionState.restore(baseline, 17)
	check(state.apply_human_activity(command(), ambient(), "new", 3).is_empty() and state.snapshot() == baseline, "Regional usage cap rejects without consuming sequence or tile")
	state.advance_time(0.75)
	check(not state.apply_human_activity(command(), ambient(), "new", 3).is_empty(), "Fresh activity window frees old regional usage capacity")
	baseline = ExpeditionState.new(17).snapshot()
	for index in range(ExpeditionContract.MAX_TILE_DELTAS):
		baseline.tile_deltas["%d:0" % index] = {"overload": 0}
	baseline.natural.order = baseline.tile_deltas.keys()
	state = ExpeditionState.restore(baseline, 17)
	check(state.apply_human_activity(command(), ambient(), "west", 3).is_empty() and state.snapshot() == baseline, "Tile capacity failure preserves receipt, usage, and all existing tiles")

func verify_persistence(state: ExpeditionState, latest: Dictionary) -> void:
	var snapshot := state.snapshot()
	var restored := ExpeditionState.restore(JSON.parse_string(JSON.stringify(snapshot, "", true, true)), 17)
	check(restored != null and restored.snapshot() == snapshot and restored.apply_human_activity(latest).replayed, "JSON reload preserves integer-normalized budget and replay receipts")
	var legacy := snapshot.duplicate(true)
	legacy.version = 1
	check(ExpeditionState.restore(legacy, 17) == null, "Incompatible development state requires a new expedition")
	var path := "user://d2-vastra-%d.json" % Time.get_ticks_usec()
	var save := ExpeditionSave.snapshot(17, Vector2i.ZERO, false, false, WorldTerrain.GENERATION_VERSION, {}, snapshot)
	check(ExpeditionSave.write(save, path) == OK, "Portable save accepts the new domain envelope without an outer format bump")
	var original := FileAccess.get_file_as_string(path)
	var loaded := ExpeditionSave.read_save(path)
	restored = ExpeditionState.restore(loaded.world_state, 17)
	check(restored.apply_human_activity(latest).replayed and restored.snapshot() == snapshot, "Actual file load retains latest-event replay without spending again")
	check(restored.apply_human_activity(command("new"), ambient(), "unused", 0).is_empty(), "Reload does not reset the spent regional window")
	var mutations: Array[Dictionary] = []
	for field in ["tick", "spent", "events"]:
		var bad := snapshot.duplicate(true)
		bad.human_activity[field] = true
		mutations.append(bad)
	var future := snapshot.duplicate(true)
	future.human_activity.tick = snapshot.activity_tick + 1
	mutations.append(future)
	var inconsistent := snapshot.duplicate(true)
	inconsistent.human_activity.events[HumanVastraActivity.producer(latest)].effect.excess = 1
	mutations.append(inconsistent)
	for bad in mutations:
		check(ExpeditionState.restore(bad, 17) == null, "Malformed or future-window ledger rejects before state replacement")
		save.world_state = bad
		check(ExpeditionSave.write(save, path) == ERR_INVALID_DATA and FileAccess.get_file_as_string(path) == original, "Malformed outgoing receipt preserves the previous valid file bytes")
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(path + suffix):
			DirAccess.remove_absolute(path + suffix)

func verify_live_scene() -> void:
	var scene: Node3D = (load("res://scenes/world_3d.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	var world: Node2D = scene.world
	world.smoke_mode = true
	var event := command("live", 1, 1, world.cell)
	check(not world.persistent_state.apply_human_activity(event, world.terrain.sample(world.cell), "fixture_refuge", 1).is_empty(), "Live scene uses generated Godot ambient without changing generation")
	var before: Dictionary = world.persistent_state.snapshot()
	var path := "user://d2-live-%d.json" % Time.get_ticks_usec()
	world.save_game(path)
	world.new_expedition(42)
	check(world.persistent_state.human_activity_view() == HumanVastraActivity.empty_ledger(), "New seed clears prior event producers and budgets")
	world.load_game(path)
	check(world.persistent_state.snapshot() == before and world.persistent_state.apply_human_activity(event).replayed, "Live save/load restores the ledger together with its changed environment")
	for coord: Vector2i in world.chunks.keys():
		world.remove_chunk(coord)
	world.rebuild_world()
	check(world.persistent_state.snapshot() == before and world.persistent_state.apply_human_activity(event).replayed, "Render rebuild does not reset usage or apply a receipt twice")
	var invalid := ExpeditionSave.read_save(path)
	invalid.world_state.human_activity.tick = before.activity_tick + 1
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(invalid))
	file.close()
	var prior_state: ExpeditionState = world.persistent_state
	var prior_terrain: WorldTerrain = world.terrain
	world.load_game(path)
	check(world.persistent_state == prior_state and world.terrain == prior_terrain and world.persistent_state.snapshot() == before, "Malformed incoming ledger cannot partially replace the live scene")
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(path + suffix):
			DirAccess.remove_absolute(path + suffix)
	scene.free()
