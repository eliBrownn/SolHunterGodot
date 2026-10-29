extends SceneTree
const Catalog = preload("res://resources/sol_species/catalog.tres")
var checks := 0
var failures := 0
# Exercise the packed scene through its presentation interface. A concrete
# SolCreature type here creates a preload/type dependency cycle in Godot 4.7.2.
var models: Array = []

func check(value: bool, description: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(description)

func _initialize() -> void:
	run.call_deferred()

func geometry_bounds(model: Node3D) -> AABB:
	var result := AABB()
	var first := true
	for node in model.rig.find_children("*", "MeshInstance3D", true, false):
		var geometry := node as MeshInstance3D
		var box: AABB = (model.global_transform.affine_inverse() * geometry.global_transform) * geometry.get_aabb()
		if geometry.has_meta("articulated_membrane"):
			# A triangle's transformed bounding rectangle includes a nonexistent fourth corner.
			var vertices: PackedVector3Array = geometry.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
			var transform := model.global_transform.affine_inverse() * geometry.global_transform
			box = AABB(transform * vertices[0], Vector3.ZERO)
			for vertex in vertices:
				box = box.expand(transform * vertex)
		result = box if first else result.merge(box)
		first = false
	return result

func run() -> void:
	check(Catalog.valid(), "Articulated scenes preserve catalog validation")
	for invalid_setting in [["body_plan", 3], ["model_scale", INF], ["idle_strength", -1.0], ["idle_rate", 3.0], ["action_seconds", 0.0], ["step_distance", 0.0], ["step_lift", INF], ["turn_response", 0.0]]:
		var malformed := Catalog.entries[0].presentation_scene.instantiate()
		malformed.set(invalid_setting[0], invalid_setting[1])
		var packed := PackedScene.new()
		packed.pack(malformed)
		var record := Catalog.entries[0].duplicate() as SolSpeciesRecord
		record.presentation_scene = packed
		check(not record.presentation_valid(), "Malformed creature setting rejects: " + str(invalid_setting[0]))
		malformed.free()
	for index in range(3):
		var entry := Catalog.entries[index]
		var model: Variant = SolSpeciesView.create(entry.species_id, "fire", SolVisualSettings.new())
		check(model != null, "Catalog routes each pilot to an articulated creature")
		if model == null:
			continue
		root.add_child(model)
		models.append(model)
		check(model.mesh == null and not model.halo.visible, "Creature presentation hides the temporary affinity sphere")
		check(model.affinity == "fire" and model.motes.size() == model.tuning.effect_count, "Individual-affinity effects remain connected")
		check(model.rig.find_children("Contact", "Marker3D", true, false).size() == 4, "Four named contact markers are available to locomotion")
		check(model.rig.find_children("*", "MeshInstance3D", true, false).size() < 64, "Blockout geometry stays bounded per creature")
		check(model.joints.has("Head") and model.joints.has("Body"), "Head and body have independent articulation")
		for seconds in [0.0, 0.4, 1.0, 2.4]:
			model.animate(seconds, 4.0, 1.0)
			check(is_equal_approx(model.position.y, model.ground_y), "Grounded blockout ignores legacy hovering bob")
			check(model.preview_bounds().grow(0.01).encloses(geometry_bounds(model)), "Preview envelope contains every articulated mesh at idle")
		model.animate(1.0, 0.0, 0.0)
		var pose: Transform3D = model.head.transform
		model.animate(1.0, 0.0, 0.0)
		check(model.head.transform == pose, "Replaying an idle timestamp causes no transform drift")
		model.animate(2.0, 0.0, 0.0)
		check(model.head.transform != pose, "Idle animation articulates the model")
		model.idle_strength = 0.0
		model.animate(0.0, 0.0, 0.0)
		var neutral: Transform3D = model.head.transform
		model.animate(5.0, 0.0, 0.0)
		check(model.head.transform == neutral, "Zero idle strength holds the neutral pose")
		model.idle_strength = 1.0
		model.set_stance("alert")
		model.animate(10.0, 0.0, 0.0)
		var ready_pose: Transform3D = model.body.transform
		for cue in ["attack", "hit", "signature"]:
			model.play_action(cue, 10.0)
			model.animate(10.0 + model.action_seconds * 0.5, 0.0, 0.0)
			check(model.preview_bounds().encloses(geometry_bounds(model)), "Preview includes the essential pose: " + cue)
			var posed: Transform3D = model.body.transform if cue != "signature" else (model.joints.EarLeft.transform if index == 0 else model.joints.Plate0.transform if index == 1 else model.joints.Leaf0.transform)
			model.animate(10.0 + model.action_seconds * 2.0, 0.0, 0.0)
			var recovered: Transform3D = model.body.transform if cue != "signature" else (model.joints.EarLeft.transform if index == 0 else model.joints.Plate0.transform if index == 1 else model.joints.Leaf0.transform)
			check(posed != recovered, "Essential pose articulates and recovers: " + cue)
		model.apply_impact(Color.WHITE, 0.7)
		check(model.body_materials.all(func(material: StandardMaterial3D) -> bool: return material.emission_enabled), "Combat flash reaches creature materials")
		model.apply_impact(Color.WHITE, 0.0)
		check(model.body_materials.all(func(material: StandardMaterial3D) -> bool: return not material.emission_enabled), "Impact reset removes emission")
		model.set_stance("rest")
		model.animate(10.0, 0.0, 0.0)
		check(model.body.transform != ready_pose, "Rest and alert have distinct supported poses")
		var other: Variant = SolSpeciesView.create(entry.species_id, "water", SolVisualSettings.new())
		check(other != null and other.body_materials[0].albedo_color == model.body_materials[0].albedo_color and other.tint != model.tint, "Species skin stays constant across different individual affinities")
		other.free()
	check(models[0].joints.has("EarLeft") and models[0].joints.has("WristRight") and models[0].joints.has("WingTipLeft"), "Crown-Ear has ears and articulated wing/contact chains")
	check(models[1].joints.has("TailTip") and models[1].joints.has("Plate2") and models[1].joints.has("Reed2"), "Reedback has tail, plate and reed controls")
	check(models[2].joints.has("Canopy") and models[2].joints.has("LeafTip5"), "Bellroot has layered canopy controls")
	if "--capture" in OS.get_cmdline_user_args():
		await capture()
	for model in models:
		model.free()
	await process_frame
	print("SOL CREATURE MODELS: %d checks, %d failures." % [checks, failures])
	quit(0 if failures == 0 else 1)

func capture() -> void:
	root.size = Vector2i(1440, 800)
	var studio := Node3D.new()
	root.add_child(studio)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 2.1
	camera.position = Vector3(1.1, 1.8, 4.0)
	studio.add_child(camera)
	camera.look_at(Vector3(0, 0.25, 0))
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("243630")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("e1e7ed")
	environment.environment.ambient_light_energy = 0.7
	studio.add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-40, -35, 0)
	light.shadow_enabled = true
	studio.add_child(light)
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(20, 20)
	ground.mesh = plane
	var floor_material := StandardMaterial3D.new()
	floor_material.albedo_color = Color("36434b")
	floor_material.roughness = 1.0
	ground.material_override = floor_material
	studio.add_child(ground)
	for index in range(models.size()):
		models[index].position.x = (index - 1) * 1.15
		models[index].rotation.y = -0.2
		models[index].animate(1.0, 0.0, 0.0)
		var label := Label3D.new()
		label.text = Catalog.entries[index].display_name
		label.position = Vector3((index - 1) * 1.15, 0.85, 0)
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.font_size = 42
		label.pixel_size = 0.003
		studio.add_child(label)
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://artifacts/sol_creature_models")
	check(root.get_texture().get_image().save_png("res://artifacts/sol_creature_models/pilot_models.png") == OK, "Rendered three-species model review saved")
	studio.free()
