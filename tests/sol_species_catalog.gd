extends SceneTree

const BattleTest = preload("res://tests/battle_test_support.gd")
const Preview = preload("res://scripts/sol_model_preview.gd")
const Catalog = preload("res://resources/sol_species/catalog.tres")
const Library = preload("res://resources/move_library.tres")
var checks := 0
var failures := 0

func check(value: bool, description: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(description)

func _initialize() -> void:
	create_timer(180).timeout.connect(func() -> void: quit(1))
	run.call_deferred()

func run() -> void:
	verify_content()
	verify_rejection()
	verify_capacity()
	await verify_journey()
	print("SOL SPECIES CATALOG: %d checks, %d failures." % [checks, failures])
	quit(0 if failures == 0 else 1)

func isolated_catalog() -> SolSpeciesCatalog:
	# External .tres records are intentionally shared by Resource.duplicate(true).
	# Copy each editable record/profile explicitly; keep the immutable packed presentation scene shared.
	var result := SolSpeciesCatalog.new()
	for entry in Catalog.entries:
		var copy := entry.duplicate(true) as SolSpeciesRecord
		copy.ecology = entry.ecology.duplicate(true)
		result.entries.append(copy)
	return result

func verify_content() -> void:
	check(Catalog.valid() and not Catalog.entries.is_empty() and Library.valid(), "Authored catalog and shared moves validate before admission")
	var settings: BattleSettings = preload("res://resources/battle_settings.tres")
	var ecology: SightingSettings = preload("res://resources/sighting_settings.tres")
	check(settings.species_catalog == Catalog and ecology.species_catalog == Catalog and Library.species_catalog == Catalog, "Configured services reference one shared resource")
	check(SolSpeciesCatalog.class_display_name("tideborn") == "Abyssal" and SolSpeciesCatalog.class_display_name("verdant") == "Bloom" and SolSpeciesCatalog.class_display_name("skyborne") == "Zephyr", "Display names change without rewriting class IDs")
	check(SolSpeciesCatalog.class_display_name("stonebound") != "Eldritch", "Legacy Stonebound is not silently turned into Eldritch")
	for entry in Catalog.entries:
		check(not entry.get_property_list().any(func(row: Dictionary) -> bool: return row.name == "affinity"), "Species definition has no individual-affinity property")
		var water := entry.battle_profile("water")
		var fire := entry.battle_profile("fire")
		check(BattleProfile.valid_snapshot(water) and water.affinity == "water" and fire.affinity == "fire" and water.class_id == fire.class_id, "Different individual affinities share the same authored species")
		check(entry.battle_profile("invalid").is_empty() and settings.opponent(entry.species_id).is_empty(), "New species require an explicit valid individual affinity")
		check(settings.opponent(entry.species_id, "water") == water and settings.evolution_forms_for(entry.species_id) == 3, "Battle lookup resolves species content and lineage capacity")
		var book := Library.book(entry.species_id)
		check(MoveLibrary.valid_book(book) and book.pool == Array(entry.learnable_moves) and book.equipped.size() == 4 and book.learned.size() > book.equipped.size(), "Authored early move pool admits four equipped moves plus remembered alternatives")
		var gates := Library.levels_for(entry.species_id, [4, 8, 14])
		check(gates[entry.learnable_moves[4]] == 4 and gates[entry.learnable_moves[5]] == 8 and gates[entry.learnable_moves[6]] == 14, "Catalog moves use existing learning milestones")
		var sight := {"species": entry.species_id, "class": entry.class_id, "affinity": "water", "reaction": "Observing"}
		var resolved := SolEcology.resolve("catalog:fixture", sight, ecology)
		check(resolved.profile_id == entry.ecology.profile_id and resolved.behaviors.has("idle"), "Ecology resolves the catalog default through existing behavior branches")
		sight.behavior_profile = "missing_override"
		check(SolEcology.profile_for(sight, ecology) == null, "Missing named override never silently becomes a species default")
		var view := SolSpeciesView.create(entry.species_id, "water", SolVisualSettings.new(), 0.0, Catalog)
		check(view != null and view.get_meta("species_id") == entry.species_id and view.affinity == "water", "Presentation scene lookup receives the individual's actual affinity")
		if view != null:
			view.free()
	var legacy := SolSpeciesView.create("seedmote", "earth", SolVisualSettings.new())
	check(legacy != null and legacy.affinity == "earth" and legacy.mesh == null and not legacy.halo.visible and legacy.has_method("sync_locomotion"), "Existing saved species use a creature fallback with their original affinity")
	legacy.free()
	var before := SolEcology.configuration(ecology)
	var isolated := ecology.duplicate(true) as SightingSettings
	var isolated_source := isolated_catalog()
	isolated.species_catalog = isolated_source
	isolated.species_catalog.entries[0].ecology.rest_duration_scale = 1.5
	check(SolEcology.configuration(isolated) != before and SolEcology.configuration(ecology) == before, "Nested catalog ecology edits invalidate configuration without mutating another resource")

func verify_rejection() -> void:
	var invalid := isolated_catalog()
	invalid.entries.append(invalid.entries[0])
	check(not invalid.valid(), "Duplicate stable species IDs reject")
	invalid = isolated_catalog()
	invalid.entries[1].display_name = invalid.entries[0].display_name.to_upper()
	check(not invalid.valid(), "Case-insensitive duplicate working names reject")
	invalid = isolated_catalog()
	invalid.entries[1].lineage_id = invalid.entries[0].lineage_id
	check(not invalid.valid(), "A lineage cannot silently change primary class")
	invalid = isolated_catalog()
	invalid.entries[0].max_hp = 0
	check(not invalid.valid(), "Invalid species reference stats reject")
	invalid = isolated_catalog()
	invalid.entries[0].class_id = "unassigned_class"
	check(not invalid.valid(), "Unknown classes cannot enter the runtime catalog")
	invalid = isolated_catalog()
	invalid.entries[0].ecology.species_id = "other_species"
	check(not invalid.valid(), "Mismatched ecology references reject")
	invalid = isolated_catalog()
	invalid.entries[0].starting_moves.append("unknown_move")
	check(not invalid.valid(), "Starting moves must be eligible species moves")
	invalid = isolated_catalog()
	invalid.entries[0].learnable_moves.append("unknown_move")
	var library := Library.duplicate(true) as MoveLibrary
	library.species_catalog = invalid
	check(not library.valid() and library.book(invalid.entries[0].species_id).is_empty(), "Unknown move references cannot enter a movebook")
	library = Library.duplicate(true)
	library.species_pools[Catalog.entries[0].species_id] = PackedStringArray(["strike"])
	check(not library.valid(), "Competing catalog and legacy species pools reject")
	invalid = isolated_catalog()
	invalid.entries[0].presentation_scene = null
	check(not invalid.valid(), "Missing presentation scenes reject")
	var wrong_scene := PackedScene.new()
	var wrong_root := Node3D.new()
	wrong_scene.pack(wrong_root)
	wrong_root.free()
	invalid = isolated_catalog()
	invalid.entries[0].presentation_scene = wrong_scene
	check(not invalid.valid(), "An incompatible presentation root rejects without instantiating live animations")
	var sightings := preload("res://resources/sol_pilot_sightings.tres").duplicate(true) as SightingSettings
	sightings.catalog_sightings[1].trail_x = sightings.catalog_sightings[0].trail_x
	check(not sightings.valid(), "Two explicit catalog sightings cannot occupy the same trail home")
	sightings = preload("res://resources/sol_pilot_sightings.tres").duplicate(true)
	sightings.catalog_sightings[0].species_id = "missing_species"
	check(not sightings.valid(), "Explicit placements require a registered catalog species")
	var wrong_catalog := Resource.new()
	sightings.species_catalog = wrong_catalog
	check(not sightings.valid(), "Generic export boundary still rejects a resource with the wrong catalog script")
	sightings = preload("res://resources/sol_pilot_sightings.tres").duplicate(true)
	sightings.catalog_sightings.append(Resource.new())
	check(not sightings.valid(), "Generic placement array validates every concrete sighting resource before admission")
	sightings = SightingSettings.new()
	sightings.species_catalog_path = "res://resources/missing_species_catalog.tres"
	check(not sightings.valid(), "Missing catalog path rejects without attempting a failing resource load")
	sightings = preload("res://resources/sol_pilot_sightings.tres").duplicate(true)
	sightings.catalog_sightings[0].trail_x = 8
	var actors := preload("res://scripts/sols/presentation/authored_sightings.gd").new()
	actors.settings = sightings
	check(actors.local_entries().is_empty(), "A catalog placement colliding with an established trail home rejects the complete layout")
	actors.free()

func verify_capacity() -> void:
	var expanded := SolSpeciesCatalog.new()
	for index in range(65):
		var entry := Catalog.entries[0].duplicate(true) as SolSpeciesRecord
		entry.ecology = Catalog.entries[0].ecology.duplicate(true)
		entry.species_id = "capacity_species_%d" % index
		entry.lineage_id = "capacity_family_%d" % index
		entry.display_name = "Capacity %d" % index
		entry.ecology.species_id = entry.species_id
		entry.ecology.profile_id = entry.species_id + "_default"
		expanded.entries.append(entry)
	var library := Library.duplicate(true) as MoveLibrary
	library.species_catalog = expanded
	check(expanded.valid() and library.valid() and not library.book("capacity_species_64").is_empty(), "A bounded catalog beyond 64 species supports the release roster target")
	expanded.entries.resize(SolSpeciesCatalog.MAX_SPECIES + 1)
	check(not expanded.valid(), "A finite content-admission ceiling remains enforced")

func verify_journey() -> void:
	var scene: Node3D = load("res://scenes/sol_species_pilot.tscn").instantiate()
	root.add_child(scene)
	var world: Node2D = scene.world
	world.smoke_mode = true
	world.new_expedition(17)
	var controller: Node = scene.battles
	check(scene.sightings.members.size() == 6, "Pilot scene adds three catalog sightings beside the original three")
	controller.open_choice()
	controller.choose(0)
	var state: ExpeditionState = world.persistent_state
	var pilot_ids: Array[String] = []
	for placement in scene.sighting_settings.catalog_sightings:
		var entry: SolSpeciesRecord = Catalog.find(placement.species_id)
		var found: Array = scene.sightings.members.filter(func(row: Dictionary) -> bool: return row.entry.species == entry.species_id)
		check(found.size() == 1, "Exactly one explicit pilot individual is admitted")
		if found.size() != 1:
			continue
		var member: Dictionary = found[0]
		var identity: String = member.id
		pilot_ids.append(identity)
		var record := state.individual_view(identity)
		var traits := state.stat_view(identity)
		var book := state.movebook(identity)
		check(record.class_id == entry.class_id and record.ordinary_form == 1 and traits.forms == 3, "Taxonomy and training capacity come from catalog admission")
		check(not state.wild_profile(identity).is_empty() and state.wild_profile(identity).affinity == record.affinity and MoveLibrary.valid_book(book), "Live admission supplies a saved reference profile and complete movebook")
		check(member.sprite.get_meta("species_id") == entry.species_id and member.sprite.affinity == record.affinity, "Exploration presentation uses catalog species and individual affinity")
		var snapshot := state.snapshot()
		var old_hp := entry.max_hp
		entry.max_hp += 5
		controller.ensure_movebooks()
		entry.max_hp = old_hp
		check(state.snapshot() == snapshot, "Editing authored species stats never rerolls or overwrites an admitted individual")
		var old_affinity: String = placement.affinity
		placement.affinity = "quantum" if old_affinity != "quantum" else "earth"
		scene.sightings.rebuild()
		var rebuilt: Array = scene.sightings.members.filter(func(row: Dictionary) -> bool: return row.id == identity)
		check(rebuilt.size() == 1 and rebuilt[0].entry.affinity == record.affinity and rebuilt[0].sprite.affinity == record.affinity and state.individual_view(identity) == record, "Authored affinity edits cannot rewrite saved traits, presentation, or behavior filters")
		placement.affinity = old_affinity
		world.cell = member.home + Vector2i.LEFT
		world.destination = world.cell
		world.moving = false
		world.rebuild_world()
		scene.encounters.approach_nearest()
		scene.encounters.battle_button.pressed.emit()
		check(controller.session != null and controller.enemy_id == identity, "Real encounter admits the catalog opponent into tactical combat")
		if controller.session == null:
			continue
		BattleTest.settle(controller)
		controller.select_cell(controller.session.deployment_tiles()[0])
		BattleTest.settle(controller)
		var creature_view: Node3D = controller.unit_views.enemy.sprite
		var before_cues := state.snapshot()
		var original_cell: Vector2i = controller.session.enemy_cell
		var test_cell := original_cell
		for direction in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			if controller.session.passable(original_cell + direction):
				test_cell = original_cell + direction
				break
		controller.playback.busy = true
		controller.playback.current = {"kind": "movement"}
		controller.unit(test_cell, controller.session.enemy, "enemy")
		var unit_row: Dictionary = controller.unit_views.enemy
		controller.sync_unit_motion(unit_row, controller.playback.duration("movement") * 0.5)
		check(unit_row.motion.position.distance_to(Vector2(original_cell)) > 0.0 and unit_row.motion.position.distance_to(Vector2(test_cell)) > 0.0 and creature_view.ground_motion.speed > 0.0, "Battle movement record drives an intermediate creature pose rather than snapping")
		var frozen_position: Vector2 = unit_row.motion.position
		controller.sync_unit_motion(unit_row, 0.0)
		check(unit_row.motion.position == frozen_position and controller.session.enemy_cell == original_cell, "Frozen battle presentation cannot move the rule-owned tactical cell")
		controller.playback.busy = false
		controller.playback.current.clear()
		controller.unit(original_cell, controller.session.enemy, "enemy")
		controller.show_resolution({"kind": "effect", "actor": "enemy", "cue": {"kind": "damage", "cell": controller.session.ally_cell, "amount": 1, "affinity": record.affinity, "caption": "Model pose check"}})
		check(creature_view.get("action") == "attack", "Actual playback presentation routes acting pilot to its attack pose")
		controller.receive_feedback({"kind": "damage", "cell": controller.session.enemy_cell, "amount": 1, "affinity": record.affinity, "caption": "Model pose check"})
		check(creature_view.get("action") == "hit", "Actual battle feedback routes recipient pilot to its hit/recovery pose")
		check(state.snapshot() == before_cues, "Cosmetic attack/hit cues cannot change persistent individual or battle results")
		controller.session.enemy_hp = 7
		check(controller.session.attempt_capture(0.0), "Existing deterministic capture action accepts the pilot individual")
		controller.after_command()
		BattleTest.settle(controller)
		var owned := state.companion_view(identity)
		check(not owned.is_empty() and owned.hp == 7 and owned.profile.affinity == record.affinity and state.movebook(identity) == book and state.stat_view(identity).ivs == traits.ivs, "Capture preserves actual HP, affinity, moves and natural potential")
		if owned.is_empty():
			continue
		check(state.select_companion(identity), "Captured pilot can be selected through existing party ownership")
		var preview := Preview.new()
		preview.size = Vector2(400, 200)
		root.add_child(preview)
		var before_preview := state.snapshot()
		preview.show_profile(owned.profile, scene.sol_visual_settings, world.menu.settings, Catalog)
		check(preview.model.get_meta("species_id") == entry.species_id and preview.model.affinity == record.affinity and state.snapshot() == before_preview, "Owned menu preview uses the same presentation lookup without state writes")
		preview.free()
		var dossier := preload("res://scripts/sol_details.gd").sections(state, identity, controller)
		check(dossier.Identity.contains(entry.display_name) and dossier.Identity.contains(SolSpeciesCatalog.class_display_name(entry.class_id)), "Dossier displays authored species and approved class names rather than internal IDs")
	var before_save := state.snapshot()
	var save_path := "res://artifacts/sol_species_integration/pilot_save.json"
	DirAccess.make_dir_recursive_absolute("res://artifacts/sol_species_integration")
	world.save_game(save_path)
	world.new_expedition(7)
	world.load_game(save_path)
	check(world.persistent_state.snapshot() == before_save and world.terrain.world_seed == 17, "Full pilot collection survives actual save/new/load without rerolls")
	for identity in pilot_ids:
		check(not world.persistent_state.companion_view(identity).is_empty(), "Each acquired pilot remains owned after reload")
	if OS.get_cmdline_user_args().has("--capture") and DisplayServer.get_name() != "headless":
		await capture_pilots(world, pilot_ids)
	await process_frame
	scene.free()

func capture_pilots(world: Node2D, pilot_ids: Array[String]) -> void:
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280, 800)
	world.menu.settings.remember_layout = false
	world.menu.reset_layout()
	for identity in pilot_ids:
		world.menu.close()
		world.menu.sol_filter = "party"
		world.menu.sol_selection = identity
		world.menu.sol_tab = "details"
		world.menu.open("sols")
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		var species_id: String = world.persistent_state.individual_view(identity).species_id
		var error := root.get_texture().get_image().save_png("res://artifacts/sol_species_integration/" + species_id + ".png")
		check(error == OK, "Rendered pilot dossier capture succeeds")
	world.menu.close()
