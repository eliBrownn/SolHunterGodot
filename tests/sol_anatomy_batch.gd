extends SceneTree
## New body plans: biped supports, three-foot gesture and independent soft fins.
const SPECIES := ["ashquill", "rattlehorn", "rimefold"]
var checks := 0
var failures := 0
var models: Array = []

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)

func _initialize() -> void:
	run.call_deferred()

func surface(at: Vector2) -> float:
	return at.x * 0.1 + at.y * 0.05

func enclosed(model: Node3D) -> bool:
	# Bounds are intrinsic to the creature: remove route heading, retain art scale.
	for geometry in model.rig.find_children("*", "MeshInstance3D", true, false):
		var pose: Transform3D = Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * model.model_scale), Vector3.ZERO) * model.rig.global_transform.affine_inverse() * geometry.global_transform
		if not model.preview_bounds().encloses(pose * geometry.get_aabb()):
			return false
	return true

func run() -> void:
	for index in range(SPECIES.size()):
		var scene: PackedScene = load("res://scenes/sols/%s.tscn" % SPECIES[index])
		var record := SolSpeciesRecord.new()
		record.presentation_scene = scene
		check(record.presentation_valid(), SPECIES[index] + " admits through workshop presentation validation")
		for scale_factor in [0.5, 0.65, 1.0, 1.5]:
			var model: Variant = scene.instantiate()
			model.model_scale = scale_factor
			model.configure("fire", SolVisualSettings.new())
			root.add_child(model)
			check(model.mesh == null and not model.halo.visible, "New model retains no-orb contract")
			check(model.ground_motion.chains.size() == (2 if index == 0 else 4), "Anatomy registers its actual support count")
			check(model.rig.find_children("*", "MeshInstance3D", true, false).size() < 64, "Blockout stays below 64 mesh instances")
			var other: Variant = scene.instantiate()
			other.configure("water", SolVisualSettings.new())
			check(model.body_materials[0].albedo_color == other.body_materials[0].albedo_color and model.tint != other.tint, "Species skin and individual affinity remain separate")
			other.free()
			model.idle_strength = 0.0
			model.set_stance("alert")
			for fps in [30, 60, 144]:
				for speed in [0.3, 1.0 / 0.75]:
					model.reset_locomotion()
					model.ground_motion.heading = 0.0
					var at := Vector2.ZERO
					model.position = Vector3.ZERO
					model.sync_locomotion(at, 0.0, surface)
					var max_error := 0.0
					var finite := true
					var fits := true
					for frame in range(fps * 2):
						at += Vector2(0, speed / fps)
						model.position = Vector3(at.x, surface(at), at.y)
						model.sync_locomotion(at, 1.0 / fps, surface)
						model.animate(float(frame) / fps, 0.0, 0.0)
						fits = fits and enclosed(model)
						for chain in model.ground_motion.chains:
							finite = finite and chain.foot.global_transform.is_finite()
							if chain.progress == 1.0:
								max_error = maxf(max_error, chain.error)
					check(finite and model.ground_motion.steps_started > 2, "New anatomy walks on slope at %d FPS" % fps)
					check(max_error < 0.025, "%s scale %.1f speed %.2f planted error %.4f" % [SPECIES[index], scale_factor, speed, max_error])
					check(fits, SPECIES[index] + " walking envelope contains all geometry")
				# Route turns and pause must preserve the separate simulation transform.
				var at := Vector2(0.03, 2.0)
				model.sync_locomotion(at, 1.0 / fps, surface)
				model.animate(3.0, 0.0, 0.0)
				var pose: Transform3D = model.joints.FrontLeft.transform
				model.sync_locomotion(at, 0.0, surface)
				model.animate(3.0, 0.0, 0.0)
				check(model.joints.FrontLeft.transform.is_equal_approx(pose) and enclosed(model), "Turn and paused replay remain finite, framed and stable")
			model.reset_locomotion()
			model.ground_motion.heading = 0.0
			model.ground_y = 0.0
			model.position = Vector3.ZERO
			model.sync_locomotion(Vector2.ZERO, 0.0, func(_at: Vector2) -> float: return 0.0)
			model.idle_strength = 1.0
			model.idle_rate = 0.0
			model.phase = 0.0
			for stance in ["rest", "alert"]:
				model.set_stance(stance)
				model.animate(0.0, 0.0, 0.0)
				check(enclosed(model), "Rest/alert pose stays inside its envelope")
			for cue in ["signature", "attack", "hit"]:
				model.play_action(cue, 10.0)
				var fits := true
				for frame in range(25):
					model.animate(10.0 + model.action_seconds * frame / 24.0, 0.0, 0.0)
					fits = fits and enclosed(model)
				check(fits, "Entire " + cue + " and recovery envelope is enclosed")
				model.animate(12.0, 0.0, 0.0)
				check(model.body.transform.is_finite() and enclosed(model), "Action recovery stays finite and framed")
			model.play_action("signature", 20.0)
			model.animate(20.0 + model.action_seconds * 0.5, 0.0, 0.0)
			if index == 0:
				check(model.joints.WingLeft.rotation.z > 0.2 and model.head.rotation.y > 0.5, "Bird preens without treating wings or tail as feet")
			elif index == 1:
				check(model.released_support(1.0) == "FrontLeft" and model.released_support(0.0) == "", "Foot-testing gesture releases exactly one support and recovers")
				check(model.joints.FrontLeftFoot.global_position.y > 0.025 * scale_factor, "Testing forefoot actually clears the surface")
				check(model.ground_motion.chains.filter(func(chain: Dictionary) -> bool: return chain.hip.name != "FrontLeft").all(func(chain: Dictionary) -> bool: return chain.error < 0.025), "Three other supports stay planted during test-foot gesture")
			else:
				check(model.joints.FinLeft0.rotation.y > 0.3, "Leading fleshy lobe reaches independently")
				check(model.ground_motion.chains.all(func(chain: Dictionary) -> bool: return chain.error < 0.025), "Fin investigation leaves all four supports planted")
			if scale_factor == 1.0:
				models.append(model)
			else:
				model.free()
	if "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless":
		await capture()
	for model in models:
		model.free()
	await process_frame
	print("SOL ANATOMY BATCH: %d checks, %d failures." % [checks, failures])
	quit(0 if failures == 0 else 1)

func capture() -> void:
	root.size = Vector2i(1440, 900)
	var studio := Node3D.new()
	root.add_child(studio)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 2.8
	camera.position = Vector3(1.4, 1.4, 4.0)
	studio.add_child(camera)
	camera.look_at(Vector3(0, 0.3, 0))
	camera.current = true
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-40, -30, 0)
	light.light_energy = 1.6
	studio.add_child(light)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("29353f")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color.WHITE
	environment.environment.ambient_light_energy = 0.65
	studio.add_child(environment)
	for index in range(models.size()):
		# Render the authored small first form, not the unit-scale test fixture.
		models[index].free()
		var model: Variant = load("res://scenes/sols/%s.tscn" % SPECIES[index]).instantiate()
		model.configure("fire", SolVisualSettings.new())
		root.add_child(model)
		models[index] = model
		model.reset_locomotion()
		model.position = Vector3((index - 1) * 0.85, 0, 0)
		model.rotation.y = -0.5
		var label := Label3D.new()
		label.text = ["Ashquill · CinderKin", "Rattlehorn · Stormforged", "Rimefold · Frostbound"][index]
		label.position = Vector3(model.position.x, -0.13, 0.35)
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.font_size = 25
		label.pixel_size = 0.002
		studio.add_child(label)
	var layer := CanvasLayer.new()
	studio.add_child(layer)
	var title := Label.new()
	title.text = "Small first-form blockouts · B directions · provisional art"
	title.position = Vector2(24, 24)
	title.add_theme_font_size_override("font_size", 26)
	layer.add_child(title)
	DirAccess.make_dir_recursive_absolute("res://artifacts/sol_anatomy_batch")
	for cue in ["rest", "alert", "signature", "attack", "hit", "recovery", "side", "front"]:
		for model in models:
			model.rotation.y = PI * 0.5 if cue == "side" else 0.0 if cue == "front" else -0.5
			model.set_stance("alert" if cue == "alert" else "rest")
			model.play_action(cue if cue in ["signature", "attack", "hit"] else "hit", 30.0)
			model.animate(30.0 + (model.action_seconds * 0.5 if cue in ["signature", "attack", "hit"] else 2.0), 0.0, 0.0)
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		check(root.get_texture().get_image().save_png("res://artifacts/sol_anatomy_batch/%s.png" % cue) == OK, "Rendered " + cue + " review")
	studio.free()
