extends SceneTree
## D1 invariants, detached reads, atomic persistence and incompatible-save rejection.

var checks := 0
var failures := 0

func check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(description)

func _initialize() -> void:
	create_timer(120).timeout.connect(func() -> void: quit(1))
	run.call_deferred()

func species(name: String = "fixture_sprout", lineage: String = "fixture_line", primary: String = "fixture_class") -> SolSpeciesDefinition:
	var definition := SolSpeciesDefinition.new()
	definition.species_id = name
	definition.lineage_id = lineage
	definition.class_id = primary
	return definition

func run() -> void:
	var state := ExpeditionState.new(17, 64)
	check(state.territory_id(Vector2i(-1, -65)) == "17:territory:64:-1:-2", "Territories use absolute floor coordinates at negative positions")
	check(state.territory_id(Vector2i(0, 0)) == state.territory_id(Vector2i(16, 16)), "Territory identity is independent of render chunk boundaries")
	var before := state.snapshot()
	check(state.territory_view(Vector2i.ZERO).is_empty() and state.individual_view("missing").is_empty(), "Unknown reads remain unknown")
	check(state.snapshot() == before, "Reads do not allocate state or generate terrain")
	check(state.observe_territory(Vector2i(-1, -65)), "Explicit observation persists a territory")
	check(not state.observe_territory(Vector2i(-1, -65)), "Repeated observation in the same tick is idempotent")
	var territory := state.territory_view(Vector2i(-1, -65))
	check(territory.population == null and territory.capacity == null, "Observation never invents zero population or ecological capacity")
	territory.observed_tick = 999
	check(state.territory_view(Vector2i(-1, -65)).observed_tick == 0, "Territory reads are detached")
	check(state.advance_time(0.375) == 0 and state.advance_time(0.375) == 1, "Activity uses the source 0.75-second interval")
	check(state.advance_time(1000.0) == 2 and state.activity_tick() == 3, "Long-stall catch-up is capped at two ticks")
	before = state.snapshot()
	check(state.advance_time(-1) == 0 and state.advance_time(NAN) == 0 and state.advance_time(INF) == 0 and state.snapshot() == before, "Invalid elapsed time leaves clock state intact")
	var definition := species()
	var identity := state.register_individual(definition, Vector2i(-3, 4), "fixture_amber")
	check(identity == "17:-3:4:fixture_sprout", "Initial identity matches the established source home format")
	check(SolIdentityContract.parse(identity).home == [-3, 4], "Individual identity parses back to its stable home")
	check(SolIdentityContract.parse("17:-03:4:fixture_sprout").is_empty() and SolIdentityContract.parse("sol2:17:-3:4:0:fixture_sprout").is_empty(), "Noncanonical numeric aliases cannot create a second identity")
	check(state.register_individual(definition, Vector2i(-3, 4), "fixture_amber").is_empty(), "Duplicate registration cannot reroll or clone an individual")
	check(state.register_individual(definition, Vector2i(-3, 4), "fixture_blue", 1).is_empty(), "A home cannot have two active wild generations")
	check(state.relationship_view(identity) == null, "Missing relationship is unknown, not zero trust")
	check(state.acquire(identity) and not state.acquire(identity), "Acquisition commits once under the same individual ID")
	check(state.relationship_view(identity) == null, "Sealing does not manufacture affection or memories")
	var replacement := state.register_individual(definition, Vector2i(-3, 4), "fixture_blue", 1)
	check(replacement == "sol2:17:-3:4:1:fixture_sprout" and replacement != identity, "Replacement generation has a distinct identity without losing the acquired original")
	check(state.individual_view(identity).affinity != state.individual_view(replacement).affinity, "Individual affinity stays separate from species class")
	check(state.relocate_owned(identity, "party") and state.relocate_owned(identity, "storage"), "Party/storage references preserve the single owned record")
	check(not state.relocate_owned(identity, "wild"), "Unresolved release/cross-holder behavior is not silently implemented")
	var evidence := {"version": 1, "trust": null, "memories": [{"event_id": "fixture:first-care", "kind": "fixture_care", "tick": 1, "note": "Explicit fixture evidence."}]}
	check(state.record_relationship(identity, evidence), "Explicit relationship evidence attaches to the existing held individual")
	check(not state.record_relationship(identity, evidence), "Replayed evidence is idempotent")
	var readback: Dictionary = state.relationship_view(identity)
	readback.memories[0].note = "external mutation"
	check(state.relationship_view(identity).memories[0].note == "Explicit fixture evidence.", "Nested memory reads are detached")
	check(not state.record_relationship(identity, {"version": 1, "trust": null, "memories": []}), "Recording cannot evict existing history")
	var bad := evidence.duplicate(true)
	bad.memories.append(bad.memories[0].duplicate(true))
	check(not state.record_relationship(identity, bad), "Duplicate memory event IDs reject atomically")
	bad = evidence.duplicate(true)
	bad.memories[0].tick = 999
	check(not state.record_relationship(identity, bad), "Future-dated memories reject")
	check(not state.record_relationship(replacement, evidence), "Wild creatures do not inherit current-holder relationship evidence")
	var full_history := evidence.duplicate(true)
	for index in range(31):
		full_history.memories.append({"event_id": "fixture:%d" % index, "kind": "fixture", "tick": 1, "note": " Recorded evidence retains whitespace. "})
	check(state.record_relationship(identity, full_history), "Bounded ordered history admits all 32 explicit memories")
	full_history.memories.append({"event_id": "fixture:overflow", "kind": "fixture", "tick": 1, "note": "Overflow"})
	check(not state.record_relationship(identity, full_history) and state.relationship_view(identity).memories.size() == 32, "History overflow rejects without truncation or eviction")
	var incompatible := species("fixture_other", "fixture_line", "different_class")
	check(state.register_individual(incompatible, Vector2i(4, 4), "fixture_amber").is_empty(), "Ordinary lineage class remains fixed")
	definition.class_id = "mutated_resource"
	check(state.individual_view(identity).class_id == "fixture_class", "Later resource edits cannot mutate an existing individual")
	var record := state.individual_view(identity)
	record.affinity = "external mutation"
	check(state.individual_view(identity).affinity == "fixture_amber", "Individual reads are detached")
	var event_counts := [0]
	state.environment_changed.connect(func(_cell: Vector2i) -> void: event_counts[0] += 1)
	check(state.set_environment(Vector2i(-17, 33), {"concentration": 90}), "Sparse concentration override can be recorded")
	check(state.set_environment(Vector2i(-17, 33), {"overload": 0}), "Overload is stored independently of high concentration")
	check(not state.set_environment(Vector2i(-17, 33), {"overload": 0}) and event_counts[0] == 2, "Absolute delta replay does not apply a second event")
	check(not state.set_environment(Vector2i(-17, 33), {"overload": 101, "concentration": 1}), "Invalid delta does not partially mutate state")
	var generated := {"concentration": 12, "overload": 9, "walkable": true}
	var effective := state.environment_view(Vector2i(-17, 33), generated)
	check(effective.concentration == 90 and effective.overload == 0 and generated.concentration == 12, "Detached overlay preserves generated defaults and independent scales")
	var snapshot := state.snapshot()
	var restored := ExpeditionState.restore(JSON.parse_string(JSON.stringify(snapshot)), 17)
	check(restored != null and restored.snapshot() == snapshot, "JSON round trip preserves clock, territories, individuals, histories and deltas")
	if restored != null:
		check(restored.individual_view(identity).location == "storage" and restored.relationship_view(identity) == state.relationship_view(identity), "Individual location and memory continuity survive restoration")
	check(ExpeditionState.restore(snapshot, 18) == null, "Cross-seed state cannot be attached to another world")
	for altered in malformed_states(snapshot, identity):
		check(not ExpeditionState.valid_snapshot(altered, 17) and ExpeditionState.restore(altered, 17) == null, "Malformed or future persistent state rejects before mutation")
	var full := ExpeditionState.new(17).snapshot()
	for index in range(ExpeditionState.MAX_TERRITORIES):
		full.territories["17:territory:16:%d:0" % index] = {"observed_tick": 0}
	var bounded := ExpeditionState.restore(full, 17)
	check(bounded != null and not bounded.observe_territory(Vector2i(-16, 0)) and bounded.counts().territories == ExpeditionState.MAX_TERRITORIES, "Admission limits reject without evicting recorded territories")
	var oversized := ExpeditionState.new(17).snapshot()
	for index in range(ExpeditionContract.MAX_TILE_DELTAS + 1):
		oversized.tile_deltas["%d:0" % index] = {"overload": 0}
	check(not ExpeditionState.valid_snapshot(oversized, 17), "Oversized sparse state rejects rather than silently discarding deltas")
	await verify_live_persistence()
	print("D1 FOUNDATION: %d checks, %d failures." % [checks, failures])
	quit(0 if failures == 0 else 1)

func malformed_states(source: Dictionary, identity: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for field in ["activity_tick", "territory_size", "version"]:
		var bad := source.duplicate(true)
		bad[field] = true
		result.append(bad)
	for value in [-1, 2, INF, NAN]:
		var bad := source.duplicate(true)
		bad.remainder_seconds = value
		result.append(bad)
	var bad := source.duplicate(true)
	bad.version = 99
	result.append(bad)
	bad = source.duplicate(true)
	bad.individuals[identity].home = [1, 2]
	result.append(bad)
	bad = source.duplicate(true)
	bad.individuals[identity].sol_relationship.trust = true
	result.append(bad)
	bad = source.duplicate(true)
	bad.individuals[identity].sol_relationship.memories[0].extra = "unknown field"
	result.append(bad)
	bad = source.duplicate(true)
	bad.tile_deltas["-17:33"].walkable = false
	result.append(bad)
	bad = source.duplicate(true)
	bad.territories["17:territory:64:999999:0"] = {"observed_tick": 0}
	result.append(bad)
	bad = source.duplicate(true)
	bad.individuals[identity].generation = true
	result.append(bad)
	return result

func verify_live_persistence() -> void:
	var scene: Node3D = (load("res://scenes/world_3d.tscn") as PackedScene).instantiate()
	scene.sighting_settings = SightingSettings.new()
	scene.sighting_settings.enabled = false # Isolate the legacy empty-domain fixture.
	root.add_child(scene)
	var world: Node2D = scene.world
	world.smoke_mode = true
	var state: ExpeditionState = world.persistent_state
	var identity := state.register_individual(species(), Vector2i(2, -3), "fixture_amber")
	state.acquire(identity, "party")
	state.advance_time(1.5)
	state.record_relationship(identity, {"version": 1, "trust": 0, "memories": []})
	state.set_environment(Vector2i.ZERO, {"concentration": 99, "overload": 1})
	var before := state.snapshot()
	for coord: Vector2i in world.chunks.keys():
		world.remove_chunk(coord)
	world.rebuild_world()
	check(state.snapshot() == before and state.individual_view(identity).id == identity, "Render eviction/reconstruction cannot erase or duplicate persistent identity")
	var path := "user://d1-foundation-%d.json" % Time.get_ticks_usec()
	world.save_game(path)
	var encoded := FileAccess.get_file_as_string(path)
	check(not encoded.is_empty() and ExpeditionSave.read_save(path).save_version == ExpeditionSave.FORMAT_VERSION, "Live save writes the current versioned persistent envelope")
	world.new_expedition(7)
	check(world.persistent_state.counts().individuals == 0 and world.persistent_state.activity_tick() == 0, "New expedition resets its own state without retaining prior individuals")
	world.load_game(path)
	check(world.persistent_state.snapshot() == before and world.persistent_state.relationship_view(identity).trust == 0, "Live reload restores identical data and explicit zero trust")
	check(not world.persistent_state.acquire(identity), "Repeated load/acquire cannot duplicate an owned individual")
	for cycle in range(3):
		world.load_game(path)
		check(world.persistent_state.snapshot() == before and world.persistent_state.counts().individuals == 1, "Repeated live reload preserves exactly one individual without replaying outcomes")
	var live_state: ExpeditionState = world.persistent_state
	var live_terrain: WorldTerrain = world.terrain
	var malformed: Dictionary = JSON.parse_string(encoded)
	malformed.world_state.individuals[identity].id = "wrong-id"
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(malformed))
	file.close()
	world.load_game(path)
	check(world.persistent_state == live_state and world.terrain == live_terrain and world.persistent_state.snapshot() == before, "Malformed incoming state leaves the entire live world untouched")
	file = FileAccess.open(path, FileAccess.WRITE)
	file.seek(ExpeditionSave.MAX_SAVE_BYTES)
	file.store_8(0)
	file.close()
	var oversized_file := FileAccess.open(path, FileAccess.READ)
	check(oversized_file.get_length() > ExpeditionSave.MAX_SAVE_BYTES, "Oversized-file fixture actually crosses the codec admission bound")
	oversized_file.close()
	world.load_game(path)
	check(world.persistent_state == live_state and world.terrain == live_terrain, "Oversized file rejects before parsing or replacing the live world")
	file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(encoded)
	file.close()
	var outgoing := ExpeditionSave.snapshot(world.terrain.world_seed, world.cell, world.visited, world.returned, world.terrain.generation_version, world.terrain.climate, malformed.world_state)
	check(ExpeditionSave.write(outgoing, path) == ERR_INVALID_DATA and FileAccess.get_file_as_string(path) == encoded, "Malformed outgoing state leaves the previous valid slot byte-for-byte intact")
	var legacy: Dictionary = JSON.parse_string(encoded)
	legacy.save_version = 1
	legacy.erase("world_state")
	var legacy_bytes := JSON.stringify(legacy)
	file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(legacy_bytes)
	file.close()
	check(ExpeditionSave.read_save(path).is_empty(), "Obsolete save format is rejected during solo development")
	world.load_game(path)
	check(world.persistent_state == live_state and world.terrain == live_terrain, "Rejected legacy load preserves the running expedition")
	check(FileAccess.get_file_as_string(path) == legacy_bytes, "Rejection does not rewrite the old file")
	world.new_expedition(int(legacy.seed))
	world.smoke_mode = false
	world.paused = true
	var paused: Dictionary = world.persistent_state.snapshot()
	world._process(1.5)
	check(world.persistent_state.snapshot() == paused, "Pause freezes activity time")
	world.paused = false
	world._process(0.75)
	check(world.persistent_state.activity_tick() == 1, "Unpaused live processing advances the source activity clock")
	world.smoke_mode = true
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(path + suffix):
			DirAccess.remove_absolute(path + suffix)
	scene.free()
