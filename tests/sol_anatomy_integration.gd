extends SceneTree
## Real main-scene encounters, capture, active companions, previews and saved identities.
const BattleTest = preload("res://tests/battle_test_support.gd")
const IDS := ["sol_species_0004", "sol_species_0005", "sol_species_0006"]
const MOMENTS := ["ashquill_preens", "rattlehorn_footing", "rimefold_investigate"]
var checks := 0
var failures := 0

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)

func _initialize() -> void:
	create_timer(180).timeout.connect(func() -> void: quit(1))
	run.call_deferred()

func put_player(world: Node2D, at: Vector2i) -> void:
	world.cell = at
	world.destination = at
	world.moving = false
	world.explorer.position = world.center(at)
	world.camera.position = world.explorer.position

func capture(scene: Node3D, filename: String) -> void:
	if DisplayServer.get_name() == "headless" or not "--capture-sol-anatomy" in OS.get_cmdline_user_args():
		return
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png("res://artifacts/sol_anatomy_integration/" + filename + ".png") == OK, "Actual main-scene render: " + filename)

func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://artifacts/sol_anatomy_integration")
	var catalog: SolSpeciesCatalog = load("res://resources/sol_species/catalog.tres")
	check(catalog.valid(), "Expanded catalog is valid")
	var scene: Node3D = load(ProjectSettings.get_setting("application/run/main_scene")).instantiate()
	root.add_child(scene)
	var world: Node2D = scene.world
	world.smoke_mode = true
	world.new_expedition(17)
	var controller: Node = scene.battles
	scene.companion.set_process(false)
	controller.open_choice()
	controller.choose(0)
	var state: ExpeditionState = world.persistent_state
	var captured := {}
	var species_ids: Array = IDS.duplicate()
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--species="):
			species_ids = Array(argument.trim_prefix("--species=").split(","))
	for species_id in species_ids:
		var species: SolSpeciesRecord = catalog.find(species_id)
		check(species != null, "Requested integration species exists in the catalog")
		if species == null:
			continue
		var builder_name := species.resource_path.get_file().get_basename()
		var expected_moment: String = MOMENTS[IDS.find(species_id)] if species_id in IDS else builder_name + "_moment"
		var found: Array = scene.sightings.members.filter(func(member: Dictionary) -> bool: return member.entry.species == species.species_id)
		check(found.size() == 1, species.display_name + " is admitted once in the actual F5 main scene")
		if found.size() != 1:
			continue
		var member: Dictionary = found[0]
		var expected_script: Script = member.sprite.get_script()
		var identity: String = member.id
		var before: Dictionary = state.individual_view(identity)
		var stats: Dictionary = state.stat_view(identity)
		var book: Dictionary = state.movebook(identity)
		check(before.ordinary_form == 1 and before.class_id == species.class_id and before.lineage_id == species.lineage_id, "New stable identity has its approved class and first stage")
		check(expected_script.resource_path == "res://scripts/sol_%s.gd" % builder_name and is_equal_approx(member.sprite.model_scale, 0.65), "Wild view uses the actual small first-form builder")
		check(species.traversal.kind == "ground" and state.roaming_view(identity).get("traversal", {}).is_empty(), "Bird and fin anatomy grant no implicit flight/swimming")
		put_player(world, member.home + Vector2i.LEFT)
		world.rebuild_world()
		controller.feedback_view.result_panel.hide()
		await capture(scene, species.species_id + "_wild")
		scene.encounters.approach_individual(identity)
		check(world.encounter_active, "Pointed species can be engaged through the real encounter controller")
		if not world.encounter_active:
			continue
		scene.encounters.observe_target()
		check(state.has_discovery(identity), "Observe records the actual species in Field Notes")
		scene.encounters.battle_button.pressed.emit()
		check(controller.session != null and controller.enemy_id == identity, "Real encounter opens tactical combat for the same individual")
		if controller.session == null:
			continue
		BattleTest.settle(controller)
		controller.select_cell(controller.session.deployment_tiles()[0])
		BattleTest.settle(controller)
		check(controller.unit_views.enemy.sprite.get_script() == expected_script and controller.unit_views.enemy.sprite.affinity == before.affinity, "Combat uses the same authored body and individual affinity")
		controller.session.enemy_hp = 7
		check(controller.session.attempt_capture(0.0), "Existing Seal/capture rules accept the new species")
		controller.after_command()
		BattleTest.settle(controller)
		var owned := state.companion_view(identity)
		check(not owned.is_empty() and owned.hp == 7 and owned.profile.affinity == before.affinity and state.stat_view(identity).ivs == stats.ivs and state.movebook(identity) == book, "Capture preserves actual HP, affinity, potential and moves")
		if owned.is_empty():
			continue
		check(state.select_companion(identity), "Captured first form can become the active party Sol")
		for frame in range(30):
			scene.companion._process(0.0)
			if scene.companion.placed:
				break
			await process_frame
		check(scene.companion.placed and scene.companion.identity == identity and scene.companion.sprite.get_script() == expected_script, "Owned follower admits the selected individual with the same first-form body")
		var before_moment := state.snapshot()
		for frame in range(ceili(scene.companion.settings.rest_after_seconds * 10.0) + 1):
			scene.companion._process(0.1)
		check(scene.companion.selected_behavior == expected_moment and scene.companion.action == "moment" and scene.companion.sprite.action == "signature", "Species-specific companionship gesture uses the actual model")
		check(state.snapshot() == before_moment, "Companion gesture does not rewrite ownership, traits or relationship state")
		var prior_cell: Vector2i = scene.companion.cell
		for direction in [Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT]:
			var destination: Vector2i = world.cell + direction
			if not world.can_step(world.cell, destination) or SolRoamingPolicy.distance(destination, prior_cell) < 2:
				continue
			var origin: Vector2i = world.cell
			put_player(world, destination)
			world.player_step_completed.emit(origin, destination)
			break
		for frame in range(20):
			var previous: Vector2i = scene.companion.cell
			scene.companion._process(0.1)
			check(previous == scene.companion.cell or (SolRoamingPolicy.distance(previous, scene.companion.cell) == 1 and world.can_step(previous, scene.companion.cell)), "Following moves legally or waits without teleporting")
		world.menu.sol_filter = "party"
		world.menu.sol_selection = identity
		world.menu.sol_tab = "details"
		world.menu.open("sols")
		var preview: Node = world.menu.sol_screen.preview
		check(preview.model != null and preview.model.get_meta("species_id") == species.species_id and preview.model.affinity == before.affinity and is_equal_approx(preview.model.model_scale, 0.65), "Actual party menu shows the same small first form and affinity")
		await capture(scene, species.species_id + "_menu")
		world.menu.close()
		captured[identity] = state.individual_view(identity)
	var active: Dictionary = state.active_sol_view()
	var snapshot := state.snapshot()
	var save_path := "user://sol_anatomy_integration.json"
	world.save_game(save_path)
	world.new_expedition(7)
	world.load_game(save_path)
	var restored: Dictionary = world.persistent_state.snapshot()
	var preserved := true
	for group in snapshot:
		if group in ["individuals", "movebooks", "sol_stats"]:
			# Loading at a visited distant sector admits the current local wildlife window.
			# Every already-saved identity and trait must still be exactly preserved.
			for identity in snapshot[group]:
				preserved = preserved and restored[group].get(identity) == snapshot[group][identity]
		else:
			preserved = preserved and restored.get(group) == snapshot[group]
	check(preserved, "Real save/new/load preserves all saved data while allowing normal nearby-wildlife admission")
	for identity in captured:
		check(world.persistent_state.individual_view(identity) == captured[identity], "Saved ownership and first-stage identity survive load")
	scene.companion._process(0.0)
	check(scene.companion.identity == active.id and scene.companion.sprite.get_meta("species_id") == active.profile.species_id, "Load reconstructs the actual selected species follower")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	scene.environment.sky = null
	scene.queue_free()
	await process_frame
	await process_frame
	print("SOL ANATOMY INTEGRATION: %d checks, %d failures." % [checks, failures])
	quit(1 if failures else 0)
