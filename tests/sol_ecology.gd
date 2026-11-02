extends SceneTree

var checks := 0
var failures := 0

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func _initialize() -> void:
	create_timer(120).timeout.connect(func() -> void: quit(1))
	run.call_deferred()

func put_player(world: Node2D, at: Vector2i) -> void:
	world.cell = at
	world.destination = at
	world.moving = false
	world.explorer.position = world.center(at)
	world.camera.position = world.explorer.position

func run() -> void:
	var settings := SightingSettings.new().duplicate(true) as SightingSettings
	var entry := {"species": "seedmote", "reaction": "Wary", "affinity": "earth", "class": "verdant"}
	var seed_profile: SolEcologyProfile = settings.ecology_profiles[0]
	check(settings.valid(), "Default editable species resources pass runtime validation")
	check(absf(SolEcology.sample("golden-sol", "caution") - 0.437602065960133) < 0.00000000000001, "Versioned SHA identity stream retains its golden sample")
	var invalid := seed_profile.duplicate(true) as SolEcologyProfile
	for actions in [PackedStringArray(), PackedStringArray(["patrol", "flee"]), PackedStringArray(["idle", "idle"]), PackedStringArray(["idle", "guard"]), PackedStringArray(["idle", "chase"]), PackedStringArray(["idle", "patrol", "flee", "approach"])]:
		invalid.behaviors = actions
		check(not invalid.valid(), "Empty, missing fallback, duplicate, contradictory, unsupported, or oversized behavior sets reject")
	invalid = seed_profile.duplicate(true)
	invalid.activity_variation = NAN
	check(not invalid.valid(), "Nonfinite variation rejects")
	settings.ecology_profiles.append(seed_profile.duplicate(true))
	check(not settings.valid(), "Duplicate profile keys/default species reject")
	settings.ecology_profiles.pop_back()
	var caution_values := {}
	var spacing_values := {}
	var rest_values := {}
	var wary_actions := {}
	var neutral_actions := {}
	for index in range(60):
		var traits := SolEcology.resolve("individual-%d" % index, entry, settings)
		var tuning: SightingSettings = traits.tuning
		caution_values[tuning.reaction_distance] = true
		spacing_values[tuning.comfort_distance] = true
		rest_values[tuning.rest_max_ticks] = true
		var wary := SolEcology.decide("individual-%d" % index, Vector2i.ZERO, Vector2i.ZERO, Vector2i(3, 0), {"action": "idle"}, 1, traits)
		wary_actions[wary.action] = true
		var curious := SolEcology.resolve("individual-%d" % index, {"species": "bramblepup", "reaction": "Watching"}, settings)
		var neutral := SolEcology.decide("individual-%d" % index, Vector2i.ZERO, Vector2i.ZERO, Vector2i(2, 0), {"action": "idle"}, 1, curious)
		neutral_actions[neutral.action] = true
		check(tuning.valid() and absi(tuning.reaction_distance - settings.reaction_distance) <= seed_profile.caution_variation_cells and absi(tuning.comfort_distance - settings.comfort_distance) <= seed_profile.spacing_variation_cells, "Every resolved individual stays inside authored variation and valid tuning bounds")
	check(caution_values.size() > 1 and spacing_values.size() > 1 and rest_values.size() > 1, "Individuals differ in actual caution, spacing, and rest values")
	check(wary_actions.has("flee") and wary_actions.has("idle") and neutral_actions.has("approach") and neutral_actions.has("idle"), "Individual variation changes real flight/observation and approach/comfort decisions at the same distances")
	var traits := SolEcology.resolve("repeatable", entry, settings)
	var repeat := SolEcology.resolve("repeatable", entry, settings)
	check(traits.samples == repeat.samples and traits.tuning.reaction_distance == repeat.tuning.reaction_distance and traits.tuning.rest_max_ticks == repeat.tuning.rest_max_ticks, "Resolving the same identity retains the same traits")
	var changed := entry.duplicate()
	changed.affinity = "fire"
	changed["class"] = "beast"
	check(SolEcology.resolve("repeatable", changed, settings).samples == traits.samples, "Affinity and class cannot reroll ecological traits")
	seed(1234)
	var expected_random := randf()
	seed(1234)
	SolEcology.resolve("repeatable", entry, settings)
	check(randf() == expected_random, "Ecology resolution never consumes global gameplay RNG")
	var pup_entry := {"species": "bramblepup", "reaction": "Watching"}
	var pup := SolEcology.resolve("repeatable", pup_entry, settings)
	check(traits.tuning.wander_radius < pup.tuning.wander_radius and traits.tuning.rest_max_ticks > pup.tuning.rest_max_ticks, "Authored species have distinct patrol ranges and rest rhythms")
	var guard_entry := entry.duplicate()
	guard_entry.behavior_profile = "trail_guard"
	var guard := SolEcology.resolve("repeatable", guard_entry, settings)
	check(guard.temperament == "assertive" and guard.reaction == "Guarding" and traits.reaction == "Wary", "Explicit trail-guard override preserves its behavior without changing all Seedmotes")
	guard_entry.behavior_profile = "missing_override"
	guard_entry.reaction = "Guarding"
	check(SolEcology.resolve("repeatable", guard_entry, settings).reaction == "Guarding", "A missing named override preserves authored posture instead of adopting a conflicting species response")
	seed_profile.caution_variation_cells = 0
	seed_profile.spacing_variation_cells = 0
	seed_profile.activity_variation = 0
	traits = SolEcology.resolve("repeatable", entry, settings)
	check(traits.tuning.reaction_distance == settings.reaction_distance and traits.tuning.comfort_distance == settings.comfort_distance, "Zero variation disables individual threshold offsets")
	seed_profile.behaviors = PackedStringArray(["idle"])
	traits = SolEcology.resolve("repeatable", entry, settings)
	var decision := SolEcology.decide("repeatable", Vector2i.ZERO, Vector2i.ZERO, Vector2i(7, 0), {"action": "idle"}, 1, traits)
	check(decision.action == "idle" and not traits.tuning.wander_enabled, "Behavior whitelist disables autonomous patrol in the actual policy")
	decision = SolEcology.decide("repeatable", Vector2i.ZERO, Vector2i.ZERO, Vector2i(1, 0), {"action": "idle"}, 2, traits)
	check(decision.action == "idle" and SolReactionPolicy.caption(traits.reaction, decision) == "Watching surroundings", "Idle-only species watches without a hidden flee/approach/guard response")
	settings.species_profiles_enabled = false
	check(SolEcology.resolve("repeatable", entry, settings).tuning == settings, "Inspector master switch restores the connected global policy")
	settings = SightingSettings.new().duplicate(true)
	settings.wilderness_enabled = false
	var scene: Node3D = (load("res://scenes/world_3d.tscn") as PackedScene).instantiate()
	scene.sighting_settings = settings
	scene.encounter_settings = EncounterSettings.new()
	scene.encounter_settings.automatic_contact = false
	root.add_child(scene)
	var world: Node2D = scene.world
	var sightings: Node3D = scene.sightings
	world.new_expedition(17)
	var member: Dictionary = sightings.members[0]
	put_player(world, member.home + Vector2i(-7, 0))
	world.rebuild_world()
	sightings.sync_views()
	var original: Dictionary = world.persistent_state.snapshot()
	var original_traits: Dictionary = sightings.ecology_for(sightings.members[0])
	sightings.rebuild()
	check(world.persistent_state.snapshot() == original and sightings.ecology_for(sightings.members[0]).samples == original_traits.samples, "View reconstruction neither changes domain state nor individual traits")
	var path := "user://sol-ecology-%d.json" % Time.get_ticks_usec()
	world.save_game(path)
	world.new_expedition(42)
	world.load_game(path)
	member = sightings.members[0]
	check(world.persistent_state.snapshot() == original and sightings.ecology_for(member).samples == original_traits.samples, "Actual save/load restores the same identities and derives the same individual traits")
	var profile: SolEcologyProfile = settings.ecology_profiles[0]
	profile.behaviors = PackedStringArray(["idle"])
	sightings.sync_views()
	check(not sightings.ecology_for(member).tuning.wander_enabled, "Live profile edits invalidate cached decisions")
	for index in range(5):
		world.persistent_state.advance_time(0.75)
	check(sightings.current_cell(member) == member.home and world.persistent_state.roaming_view(member.id).action == "idle", "Idle-only Inspector profile stops real world roaming")
	profile.behaviors = PackedStringArray(["idle", "patrol", "flee"])
	sightings.sync_views()
	var moved := false
	for index in range(35):
		world.persistent_state.advance_time(0.75)
		moved = moved or sightings.current_cell(member) != member.home
	check(moved, "Re-enabling patrol resumes real autonomous movement")
	var individual: Dictionary = world.persistent_state.individual_view(member.id)
	check(individual == original.individuals[member.id] and world.persistent_state.stat_view(member.id) == original.sol_stats[member.id], "Ecology activity does not change affinity, species/class identity, ownership, or combat stats")
	profile.spacing_variation_cells = 2
	var before: Dictionary = world.persistent_state.snapshot()
	world.persistent_state.advance_time(0.75)
	check(world.persistent_state.snapshot().roaming == before.roaming, "Invalid live profile safely suspends movement")
	profile.spacing_variation_cells = 1
	if OS.get_cmdline_user_args().has("--capture-ecology") and DisplayServer.get_name() != "headless":
		world.smoke_mode = true
		put_player(world, member.home + Vector2i(-3, 0))
		world.rebuild_world()
		sightings.sync_views(1.0)
		scene.sync_ground()
		DirAccess.make_dir_recursive_absolute("res://artifacts/ecology")
		for frame in range(5):
			await process_frame
		await RenderingServer.frame_post_draw
		get_root().get_texture().get_image().save_png("res://artifacts/ecology/species.png")
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(path + suffix):
			DirAccess.remove_absolute(path + suffix)
	scene.free()
	print("SOL ECOLOGY: %d checks, %d failures." % [checks, failures])
	quit(0 if failures == 0 else 1)
