extends SceneTree
## Optional art integration, actual owners and cleanup. -- --effects-capture renders the game.
var failures := 0

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	print("Starting local effects integration")
	var scene: Node3D = load("res://scenes/world_3d.tscn").instantiate()
	root.add_child(scene)
	var world: Node2D = scene.world
	world.smoke_mode = true
	world.new_expedition(17)
	var atmosphere: Node = scene.atmosphere_controller
	var installed := ResourceLoader.exists(atmosphere.LEAF_SCENE)
	check((atmosphere.wind_leaves != null) == installed, "Optional wind art follows installation availability")
	var before: Dictionary = world.persistent_state.snapshot().duplicate(true)
	if installed:
		world.paused = true
		atmosphere.update()
		for child in atmosphere.wind_leaves.get_children():
			if child is GPUParticles3D:
				check(child.amount <= 96 and child.speed_scale == 0, "Wind budget and pause apply to actual particles")
		world.paused = false
		atmosphere.update()
	var feedback: Node3D = scene.battles.feedback_view
	feedback.receive({"kind": "damage", "amount": 4, "caption": "Hit", "affinity": "fire", "cell": world.cell})
	check(feedback.cues.size() == 1, "Confirmed damage still uses shared cue owner")
	var anchor: Node3D = feedback.cues[0].node
	check((anchor.get_child_count() == 3) == ResourceLoader.exists(feedback.IMPACT_SCENE), "Optional impact attaches to damage anchor")
	if "--effects-capture" in OS.get_cmdline_user_args():
		root.mode = Window.MODE_WINDOWED
		root.size = Vector2i(960, 640)
		world.set_process(false)
		feedback.set_process(false)
		world.hud.hide()
		scene.target_size = 6.0
		scene.view_elevation = 30.0
		scene.apply_camera()
		for frame in range(45):
			await process_frame
		await create_timer(3.0).timeout
		feedback.reset()
		feedback.receive({"kind": "damage", "amount": 4, "caption": "Hit", "affinity": "fire", "cell": world.cell})
		anchor = feedback.cues[0].node
		await create_timer(0.15).timeout
		print("Capturing local effects")
		await RenderingServer.frame_post_draw
		DirAccess.make_dir_recursive_absolute("res://artifacts/local-effects")
		root.get_texture().get_image().save_png("res://artifacts/local-effects/exploration.png")
	feedback.update_cues(feedback.tuning.feedback_seconds + 0.1)
	check(feedback.cues.is_empty() and not is_instance_valid(anchor), "Cue expiry frees vendor particles with anchor")
	check(world.persistent_state.snapshot() == before, "VFX do not mutate expedition state")
	var tuning: AtmosphereSettings = scene.atmosphere_settings.duplicate()
	tuning.wind_leaf_particles = 0
	atmosphere.configure(tuning)
	check(atmosphere.wind_leaves == null, "Zero leaf budget removes effect")
	scene.free()
	print("LOCAL EFFECTS failures: ", failures, "; vendor installed: ", installed)
	quit(1 if failures else 0)
