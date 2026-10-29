extends "res://tests/runtime_hot_paths.gd"
## Paired CPU measurements only. No timing threshold is a gameplay/CI assertion.

func run() -> void:
	var report := {"engine": Engine.get_version_info().string, "scope": "Paired CPU hot paths; no GPU/handheld performance claim"}
	var library: MoveLibrary = load("res://resources/move_library.tres")
	var dependencies: Array = [preload("res://resources/sol_ecology/behavior_library.tres")]
	var cache := Validation.new()
	check(cache.check(library, dependencies) == library.valid(), "Memoized move validation agrees")
	var started := Time.get_ticks_usec()
	for repetition in range(200):
		library.valid()
	report.move_validation_full_ms = (Time.get_ticks_usec() - started) / 1000.0
	started = Time.get_ticks_usec()
	for repetition in range(200):
		cache.check(library, dependencies)
	report.move_validation_memo_ms = (Time.get_ticks_usec() - started) / 1000.0
	report.move_full_validations_after_201_checks = cache.validation_runs
	var scene: Node3D = load("res://scenes/world_3d.tscn").instantiate()
	root.add_child(scene)
	var world: Node2D = scene.world
	world.smoke_mode = true
	world.new_expedition(17)
	check(scene.sightings.settings_valid() == scene.sightings.settings.valid(), "Memoized sighting validation agrees")
	started = Time.get_ticks_usec()
	for repetition in range(200):
		scene.sightings.settings.valid()
	report.sighting_validation_full_ms = (Time.get_ticks_usec() - started) / 1000.0
	started = Time.get_ticks_usec()
	for repetition in range(200):
		scene.sightings.settings_valid()
	report.sighting_validation_memo_ms = (Time.get_ticks_usec() - started) / 1000.0
	started = Time.get_ticks_usec()
	for repetition in range(1000):
		# The previous walking path validated this library even with no conditions.
		library.valid()
		world.persistent_state.environment_view(Vector2i.RIGHT, {}).get("conditions", {})
	report.normal_walking_previous_work_ms = (Time.get_ticks_usec() - started) / 1000.0
	started = Time.get_ticks_usec()
	for repetition in range(1000):
		world.condition_move_multiplier(Vector2i.ZERO, Vector2i.RIGHT)
	report.normal_walking_fast_path_ms = (Time.get_ticks_usec() - started) / 1000.0
	var origin: Vector2 = world.camera.position / 32.0
	started = Time.get_ticks_usec()
	for repetition in range(100):
		for y in range(-6, 7):
			for x in range(-6, 7):
				legacy_visible(scene.camera, Vector2(x * 16, y * 16) - origin, 7, 8, -5)
	report.visibility_repeated_frustum_ms = (Time.get_ticks_usec() - started) / 1000.0
	started = Time.get_ticks_usec()
	for repetition in range(100):
		var planes: Array[Plane] = scene.camera.get_frustum()
		for y in range(-6, 7):
			for x in range(-6, 7):
				Streaming.visible_with_planes(planes, Vector2(x * 16, y * 16) - origin, 7, 8, -5)
	report.visibility_shared_frustum_ms = (Time.get_ticks_usec() - started) / 1000.0
	var samples: Array = []
	for azimuth in [0.0, 90.0, 0.0, -90.0, 0.0, 180.0]:
		scene.view_azimuth = azimuth
		scene.update_camera_pose()
		samples.append({"pose": scene.camera.transform, "pending": scene.stream_plan()})
	for limit in [0, 64]:
		var ground := Ground.new()
		scene.solid_root.add_child(ground)
		# Warm the same generator/asset working set before either timing.
		for sample in samples:
			scene.camera.transform = sample.pose
			ground.sync(world.terrain, sample.pending, scene.camera, origin, scene.height_bound(), 4, limit)
		ground.builds = 0
		ground.reuses = 0
		started = Time.get_ticks_usec()
		for repetition in range(3):
			for sample in samples:
				scene.camera.transform = sample.pose
				ground.sync(world.terrain, sample.pending, scene.camera, origin, scene.height_bound(), 4, limit)
		report["temporary_ground_%d_cache_ms" % limit] = (Time.get_ticks_usec() - started) / 1000.0
		report["temporary_ground_%d_builds" % limit] = ground.builds
		report["temporary_ground_%d_reuses" % limit] = ground.reuses
		check(ground.retained.size() <= limit, "Temporary cache stays bounded in the measured reversal workload")
		ground.free()
	scene.battles.combat_hud.show()
	await settle()
	var hud: CombatHud = scene.battles.combat_hud
	started = Time.get_ticks_usec()
	for repetition in range(1000):
		hud.fit_layout()
	report.hud_unconditional_layout_ms = (Time.get_ticks_usec() - started) / 1000.0
	await settle()
	var updates: int = hud.layout_updates
	started = Time.get_ticks_usec()
	for repetition in range(1000):
		hud._process(0)
	report.hud_settled_checks_ms = (Time.get_ticks_usec() - started) / 1000.0
	report.hud_settled_layout_updates = hud.layout_updates - updates
	report.failures = failures
	DirAccess.make_dir_recursive_absolute("res://artifacts/optimization_pass2")
	var file := FileAccess.open("res://artifacts/optimization_pass2/paired_cpu.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	scene.free()
	print("HOT PATH CPU STUDY: ", JSON.stringify(report))
	quit(0 if failures == 0 else 1)
