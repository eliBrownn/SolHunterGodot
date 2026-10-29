extends SceneTree
## Every legacy and unknown identity gets an articulated body in the shared factory.
var failures := 0
var checks := 0

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var models: Array = []
	var ids := ["seedmote", "bramblepup", "ashkit", "rillfin", "unknown_future_species"]
	for id in ids:
		var model: Variant = SolSpeciesView.create(id, "fire", SolVisualSettings.new())
		root.add_child(model)
		models.append(model)
		check(model.mesh == null and not model.halo.visible, id + " has no orb body or halo")
		check(model.get_meta("species_id") == id and model.affinity == "fire" and model.get_meta("provisional_creature_art"), "Fallback preserves identity and marks provisional art")
		var supports := 4 if id in ["bramblepup", "rillfin"] else 2
		check(model.rig.find_children("Contact", "Marker3D", true, false).size() == supports, "Distinct anatomy supplies its own procedural support contacts")
		var other: Variant = SolSpeciesView.create(id, "water", SolVisualSettings.new())
		check(model.body_materials[0].albedo_color == other.body_materials[0].albedo_color and model.tint != other.tint, "Species skin remains independent of individual affinity")
		other.free()
		for frame in range(90):
			model.sync_locomotion(Vector2(frame / 100.0, 0), 1.0 / 60.0, func(_at: Vector2) -> float: return 0.0)
			model.animate(frame / 60.0, 4.0, 1.0)
		check(model.ground_motion.initialized and model.position.is_finite(), "Procedural walking works on fallback models")
		model.reset_locomotion()
		for cue in ["attack", "hit", "signature"]:
			model.play_action(cue, 2.0)
			model.animate(2.2, 0.0, 0.0)
			check(model.head.transform.is_finite(), "Combat poses remain valid: " + cue)
			var enclosed := true
			for geometry in model.rig.find_children("*", "MeshInstance3D", true, false):
				var bounds: AABB = (model.global_transform.affine_inverse() * geometry.global_transform) * geometry.get_aabb()
				enclosed = enclosed and model.preview_bounds().encloses(bounds)
			check(enclosed, "Preview contains the distinct anatomy during " + cue)
	var placeholder: Variant = load("res://scenes/sol_placeholder.tscn").instantiate()
	placeholder.configure("earth", SolVisualSettings.new())
	check(placeholder.mesh == null and not placeholder.halo.visible, "Authored placeholder also uses a creature")
	placeholder.free()
	var bare_orb := SolOrb.new()
	var orb_scene := PackedScene.new()
	orb_scene.pack(bare_orb)
	bare_orb.free()
	var record: Variant = load("res://resources/sol_species/catalog.tres").entries[0].duplicate()
	record.presentation_scene = orb_scene
	check(not record.presentation_valid(), "Catalog admission rejects the retired orb-only presentation")
	if DisplayServer.get_name() != "headless":
		await capture(models, ids)
	for model in models:
		model.free()
	await process_frame
	print("SOL CREATURE FALLBACK: %d checks, %d failures." % [checks, failures])
	quit(0 if failures == 0 else 1)

func capture(models: Array, ids: Array) -> void:
	root.size = Vector2i(1280, 720)
	var studio := Node3D.new()
	root.add_child(studio)
	var camera := Camera3D.new()
	studio.add_child(camera)
	camera.position = Vector3(0, 2.0, 4.6)
	camera.look_at(Vector3(0, 0.3, 0))
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 3.4
	camera.current = true
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-40, -25, 0)
	light.light_energy = 1.5
	studio.add_child(light)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("28333c")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color.WHITE
	environment.environment.ambient_light_energy = 0.6
	studio.add_child(environment)
	for index in range(models.size()):
		var model: Variant = models[index]
		model.position.x = (index - 2) * 0.87
		model.rotation.y = -0.3
		model.animate(1.0, 0.0, 0.0)
		var label := Label3D.new()
		label.text = ids[index].replace("unknown_future_species", "Unassigned") + "\n" + ["Bloom", "Beast", "CinderKin", "Abyssal", "Provisional"][index]
		label.position = Vector3(model.position.x, -0.12, 0.2)
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.font_size = 28
		label.pixel_size = 0.002
		studio.add_child(label)
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://artifacts/sol_creature_fallback")
	check(root.get_texture().get_image().save_png("res://artifacts/sol_creature_fallback/provisional_models.png") == OK, "Provisional creature lineup rendered")
	studio.free()
