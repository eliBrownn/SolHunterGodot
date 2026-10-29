extends SceneTree

var checks := 0
var failures := 0
var events := 0

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func _initialize() -> void:
	create_timer(120).timeout.connect(func() -> void: quit(1))
	run.call_deferred()

func press(world: Node2D, key: Key, echo: bool = false) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = key
	event.pressed = true
	event.echo = echo
	world.handle_input(event)

func run() -> void:
	var scene: Node3D = (load("res://scenes/world_3d.tscn") as PackedScene).instantiate()
	scene.sighting_settings = SightingSettings.new()
	root.add_child(scene)
	var world: Node2D = scene.world
	world.smoke_mode = true
	var sightings: Node3D = scene.sightings
	var member: Dictionary = sightings.members[0]
	var state: ExpeditionState = world.persistent_state
	state.discovery_recorded.connect(func(_identity: String) -> void: events += 1)
	var before := state.snapshot()
	world.observe_requested.emit()
	check(state.snapshot() == before and world.journal_notes.text.contains("Right-click a Sol"), "Out-of-range observation does not invent a journal discovery")
	world.cell = member.home + Vector2i(-1, 0)
	world.explorer.position = world.center(world.cell)
	world.camera.position = world.explorer.position
	world.paused = true
	world.observe_requested.emit()
	check(state.discovery_entries().is_empty(), "Paused input cannot create an observation")
	world.paused = false
	world.moving = true
	world.observe_requested.emit()
	check(state.discovery_entries().is_empty(), "Observation requires a settled player cell")
	world.moving = false
	press(world, KEY_F, true)
	check(state.discovery_entries().is_empty(), "Key auto-repeat does not create a new discovery")
	world.observe_requested.emit()
	check(state.discovery_entries().size() == 1 and events == 1 and state.has_discovery(member.id), "Observation records one stable-identity journal event")
	var first := state.discovery_entries()[0]
	check(first.key == member.id and first.title == "Seedmote" and first.first_seen == [member.home.x, member.home.y], "First observation retains the individual's identity and target coordinates")
	check(state.relationship_view(member.id) == null and state.individual_view(member.id).location == "wild", "Observing grants neither trust nor ownership")
	check(world.journal_notes.text.contains("Seedmote") and world.journal_notes.text.contains("First seen"), "Successful observation immediately appears in the Sightings tab")
	before = state.snapshot()
	world.cell += Vector2i(0, 1)
	world.observe_requested.emit()
	check(state.snapshot() == before and events == 1, "Re-observation preserves the first entry without duplicate history or events")
	var detached := state.discovery_entries()
	detached[0].first_seen[0] = 999
	check(state.discovery_entries()[0].first_seen[0] == member.home.x, "Journal reads cannot mutate saved coordinates")
	press(world, KEY_J)
	check(world.menu.opened and world.menu.selected == "guide" and state.snapshot() == before, "Opening Field Guide is read-only")
	press(world, KEY_J)
	var path := "user://sol-observation-%d.json" % Time.get_ticks_usec()
	world.save_game(path)
	var original := FileAccess.get_file_as_string(path)
	world.new_expedition(42)
	check(world.persistent_state.discovery_entries().is_empty(), "A new expedition has no fabricated prior observations")
	world.load_game(path)
	state = world.persistent_state
	check(state.snapshot() == before and world.journal_notes.text.contains("Seedmote"), "Actual load restores the same discovery and refreshes the journal projection")
	world.rebuild_world()
	check(state.snapshot() == before, "Render reconstruction cannot replay a discovery")
	state.acquire(member.id, "party")
	check(state.has_discovery(member.id) and state.discovery_entries().size() == 1, "Later ownership retains the original sighting")
	check(not state.record_sol_discovery(member.id, "Seedmote", "A second entry.", Vector2i.ZERO), "Owned/repeated individuals cannot be recorded through the wild observation boundary")
	verify_schema(before, original, path)
	verify_retention()
	if OS.get_cmdline_user_args().has("--capture-journal") and DisplayServer.get_name() != "headless":
		world.load_game(path)
		world.menu.open("guide")
		world.cell = scene.sightings.members[0].home + Vector2i(-1, 0)
		world.rebuild_world()
		DirAccess.make_dir_recursive_absolute("res://artifacts/observation")
		for frame in range(5):
			await process_frame
		await RenderingServer.frame_post_draw
		get_root().get_texture().get_image().save_png("res://artifacts/observation/journal.png")
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(path + suffix):
			DirAccess.remove_absolute(path + suffix)
	scene.free()
	print("SOL OBSERVATION: %d checks, %d failures." % [checks, failures])
	quit(0 if failures == 0 else 1)

func verify_schema(snapshot: Dictionary, original: String, path: String) -> void:
	var seed_value := int(JSON.parse_string(original).seed)
	for version in [1, 2, 3]:
		var legacy := snapshot.duplicate(true)
		legacy.version = version
		check(ExpeditionState.restore(legacy, seed_value) == null, "Incompatible development discovery state is rejected")
	var malformed: Array[Dictionary] = []
	var bad := snapshot.duplicate(true)
	bad.discoveries.append(bad.discoveries[0].duplicate(true))
	malformed.append(bad)
	for field in ["first_seen", "details", "title", "key"]:
		bad = snapshot.duplicate(true)
		bad.discoveries[0][field] = true
		malformed.append(bad)
	bad = snapshot.duplicate(true)
	bad.discoveries[0].key = "missing-individual"
	malformed.append(bad)
	bad = snapshot.duplicate(true)
	bad.discoveries[0].first_seen = [INF, 0]
	malformed.append(bad)
	bad = snapshot.duplicate(true)
	bad.discoveries[0].description = "x".repeat(401)
	malformed.append(bad)
	for data in malformed:
		check(ExpeditionState.restore(data, seed_value) == null, "Malformed, duplicate, or orphan discovery entries reject before state replacement")
		var save: Dictionary = JSON.parse_string(original)
		save.world_state = data
		check(ExpeditionSave.write(save, path) == ERR_INVALID_DATA and FileAccess.get_file_as_string(path) == original, "Invalid outgoing journal cannot overwrite a valid save")

func verify_retention() -> void:
	var state := ExpeditionState.new(17)
	var definition := SolSpeciesDefinition.new()
	definition.species_id = "fixture_observation"
	definition.lineage_id = "fixture_line"
	definition.class_id = "fixture_class"
	var first := ""
	var last := ""
	for index in range(ExpeditionState.MAX_DISCOVERIES + 1):
		last = state.register_individual(definition, Vector2i(index, 0), "fixture_affinity")
		if index == 0:
			first = last
		state.record_sol_discovery(last, "Fixture", "A bounded retained discovery.", Vector2i(index, 0))
	check(state.discovery_entries().size() == 120 and not state.has_discovery(first) and state.has_discovery(last), "Source journal retention keeps the latest 120 distinct observations")
	check(state.counts().individuals == 121 and not state.individual_view(first).is_empty(), "Retiring an old journal row never removes its individual")
	var before := state.snapshot()
	check(not state.record_sol_discovery(last, "Fixture", "Different text.", Vector2i.ZERO) and state.snapshot() == before, "Repeated retained discoveries do not evict older rows or rewrite first-seen metadata")
