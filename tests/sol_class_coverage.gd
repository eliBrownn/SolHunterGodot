extends SceneTree
## One focused body-plan/registry check and optional single rendered class board.
const Catalog = preload("res://resources/sol_species/catalog.tres")
const Supports := {"browguard": 2, "bitterfrill": 4, "knucklemole": 4, "sailcrest": 2, "glass_throat": 3, "claspback": 6,
	"foldling": 3, "mournveil": 2, "pebblewyrm": 4, "shadepelt": 4, "kilnling": 2, "thimblehart": 4}
var checks := 0
var failures := 0

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)

func _initialize() -> void:
	create_timer(90).timeout.connect(func() -> void: quit(1))
	run.call_deferred()

func surface(at: Vector2) -> float:
	return at.x * 0.05 + at.y * 0.04

func fits(model: Node3D) -> bool:
	for geometry in model.rig.find_children("*", "MeshInstance3D", true, false):
		var pose: Transform3D = Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * model.model_scale), Vector3.ZERO) * model.rig.global_transform.affine_inverse() * geometry.global_transform
		if not model.preview_bounds().encloses(pose * geometry.get_aabb()):
			return false
	return true

func run() -> void:
	check(Catalog.valid() and preload("res://resources/move_library.tres").valid(), "Expanded content and existing move pools validate")
	var classes := {}
	for species in Catalog.entries:
		check(not classes.has(species.class_id), "Each playable class has exactly one first-form representative")
		classes[species.class_id] = species.species_id
		check(species.ordinary_form == 1, "Class representatives are first forms")
	check(classes.size() == 18 and not classes.has("stonebound"), "All eighteen current classes are covered without repurposing legacy Stonebound")
	for class_id in SolSpeciesCatalog.CLASS_NAMES:
		if class_id != "stonebound":
			check(classes.has(class_id), "Playable coverage for " + SolSpeciesCatalog.class_display_name(class_id))
	var buffs: ClassBuffSettings = load("res://resources/class_buff_settings.tres")
	check(buffs.valid() and buffs.definition("eldritch").minimum == 0 and buffs.definition("eldritch").maximum == 0, "Eldritch has no invented class effect")
	check(buffs.definition("stonebound") != null and buffs.definition("stonebound") != buffs.definition("eldritch"), "Legacy Stonebound keeps a separate definition")
	var invalid := buffs.duplicate() as ClassBuffSettings
	invalid.definitions = []
	for definition in buffs.definitions:
		invalid.definitions.append(definition.duplicate())
	invalid.definition("eldritch").maximum = 1
	check(not invalid.valid(), "Unassigned Eldritch potency cannot become an inert tuning slider")
	for species in Catalog.entries:
		var name_key := species.resource_path.get_file().get_basename()
		if not Supports.has(name_key):
			continue
		var model: Variant = SolSpeciesView.create(species.species_id, "fire", SolVisualSettings.new())
		root.add_child(model)
		check(model.mesh == null and not model.halo.visible and is_equal_approx(model.model_scale, 0.65), "Small first-form body has no orb: " + name_key)
		check(model.ground_motion.chains.size() == Supports[name_key], "Authored support anatomy: " + name_key)
		check(model.rig.find_children("*", "MeshInstance3D", true, false).size() < 64, "Bounded blockout geometry: " + name_key)
		var other: Variant = SolSpeciesView.create(species.species_id, "water", SolVisualSettings.new())
		check(other.body_materials[0].albedo_color == model.body_materials[0].albedo_color and other.tint != model.tint, "Body colors are independent of affinity")
		other.free()
		model.idle_strength = 0.0
		model.set_stance("alert")
		for speed in [0.3, 1.0 / 0.75]:
			model.reset_locomotion()
			model.ground_motion.heading = 0.0
			model.position = Vector3.ZERO
			model.sync_locomotion(Vector2.ZERO, 0.0, surface)
			var error := 0.0
			var finite := true
			for frame in range(120):
				var at := Vector2(0, frame * speed / 60.0)
				model.position = Vector3(at.x, surface(at), at.y)
				model.sync_locomotion(at, 1.0 / 60.0, surface)
				model.animate(frame / 60.0, 0.0, 0.0)
				for chain in model.ground_motion.chains:
					finite = finite and chain.foot.global_transform.is_finite()
					if chain.progress == 1.0:
						error = maxf(error, chain.error)
			check(finite and model.ground_motion.steps_started > 2 and error < 0.025, "%s walk %.2f m/s contact error %.4f" % [name_key, speed, error])
		model.reset_locomotion()
		model.ground_motion.heading = 0.0
		model.position = Vector3.ZERO
		model.ground_y = 0.0
		model.sync_locomotion(Vector2.ZERO, 0.0, surface)
		model.idle_rate = 0.0
		model.idle_strength = 1.0
		model.phase = 0.0
		for cue in ["signature", "attack", "hit"]:
			model.play_action(cue, 10.0)
			var enclosed := true
			for frame in range(13):
				model.animate(10.0 + model.action_seconds * frame / 12.0, 0.0, 0.0)
				enclosed = enclosed and fits(model)
			check(enclosed, name_key + " full " + cue + " envelope")
			model.animate(12.0, 0.0, 0.0)
			check(fits(model), name_key + " recovery envelope")
		model.free()
	if DisplayServer.get_name() != "headless" and "--class-board" in OS.get_cmdline_user_args():
		await board()
	await process_frame
	print("SOL CLASS COVERAGE: %d checks, %d failures." % [checks, failures])
	quit(1 if failures else 0)

func board() -> void:
	root.size = Vector2i(2048, 1280)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.content_scale_size = Vector2i.ZERO
	root.content_scale_factor = 1.0
	var canvas := Control.new()
	root.add_child(canvas)
	var background := ColorRect.new()
	background.color = Color("26343b")
	background.size = Vector2(2048, 1280)
	canvas.add_child(background)
	var title := Label.new()
	title.text = "SOLHUNTER · 18 CLASSES · SMALL FIRST-FORM BLOCKOUTS"
	title.position = Vector2(32, 16)
	title.add_theme_font_size_override("font_size", 30)
	canvas.add_child(title)
	for index in range(Catalog.entries.size()):
		var species := Catalog.entries[index]
		var origin := Vector2(24 + (index % 6) * 337, 75 + (index / 6) * 392)
		var label := Label.new()
		label.text = SolSpeciesCatalog.class_display_name(species.class_id) + "\n" + species.display_name
		label.position = origin
		label.add_theme_font_size_override("font_size", 22)
		canvas.add_child(label)
		var container := SubViewportContainer.new()
		container.position = origin + Vector2(0, 58)
		container.size = Vector2(320, 310)
		container.stretch = true
		canvas.add_child(container)
		var viewport := SubViewport.new()
		viewport.size = Vector2i(320, 310)
		viewport.own_world_3d = true
		viewport.transparent_bg = true
		container.add_child(viewport)
		var model: SolOrb = SolSpeciesView.create(species.species_id, "earth", SolVisualSettings.new())
		viewport.add_child(model)
		model.animate(0.0, 0.0, 0.0)
		for mote in model.motes:
			mote.hide() # Body comparison only; live game retains individual affinity effects.
		var camera := Camera3D.new()
		camera.projection = Camera3D.PROJECTION_ORTHOGONAL
		camera.size = 0.95
		camera.position = Vector3(0.8, 0.65, 1.8)
		viewport.add_child(camera)
		camera.look_at(Vector3(0, 0.2, -0.04))
		camera.current = true
		var environment := WorldEnvironment.new()
		environment.environment = Environment.new()
		environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		environment.environment.ambient_light_color = Color.WHITE
		environment.environment.ambient_light_energy = 0.75
		viewport.add_child(environment)
		var light := DirectionalLight3D.new()
		light.rotation_degrees = Vector3(-45, -25, 0)
		light.light_energy = 1.3
		viewport.add_child(light)
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://artifacts/sol_class_coverage")
	check(root.get_texture().get_image().save_png("res://artifacts/sol_class_coverage/class_board.png") == OK, "Rendered one class-coverage board")
	canvas.queue_free()
	await process_frame
