extends SceneTree
const Currents = preload("res://scripts/vastra_currents.gd")
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

func run() -> void:
	var sparse := ExpeditionState.new(17)
	for cell in [Vector2i(-14, 0), Vector2i(0, -14), Vector2i(1, 2), Vector2i(14, 0), Vector2i(15, 0)]:
		sparse.set_environment(cell, {"overload": -20})
	var dense := ExpeditionState.restore(sparse.snapshot(), 17)
	for index in range(220):
		dense.set_environment(Vector2i(100 + index, 100), {"overload": 10})
	check(sparse.vastra_changes_near(Vector2i.ZERO, 14) == dense.vastra_changes_near(Vector2i.ZERO, 14), "Sparse and dense lookup preserve identical local cells and row order")
	check(sparse.vastra_changes_near(Vector2i.ZERO, 14).size() == 4, "The radius includes boundary cells and excludes outside cells")
	check(ExpeditionState.new(17).vastra_changes_near(Vector2i.ZERO, 14).is_empty(), "An untouched world has no changed current sites")
	var scene: Node3D = load("res://scenes/world_3d.tscn").instantiate()
	scene.vastra_settings = load("res://resources/vastra_settings.tres").duplicate(true)
	scene.vastra_settings.currents_enabled = true
	scene.vastra_settings.current_limit = 24
	scene.vastra_settings.current_radius = 14
	root.add_child(scene)
	var world: Node2D = scene.world
	world.smoke_mode = true
	world.new_expedition(17)
	var currents: Node3D
	for child in scene.get_children():
		if child.get_script() == Currents:
			currents = child
	currents.set_process(false)
	currents._process(0.6)
	check(currents.get_child_count() == 1 and currents.instances.visible_instance_count == scene.vastra_settings.current_limit, "Ordinary currents share a single bounded geometry batch")
	var before: Dictionary = world.persistent_state.snapshot()
	var refreshed: int = currents.refresh_count
	var builds: int = currents.sample_builds
	for frame in range(180):
		currents._process(1.0 / 60.0)
	check(currents.refresh_count == refreshed and currents.sample_builds == builds, "Stationary unchanged frames do not rebuild readings or terrain samples")
	check(world.persistent_state.snapshot() == before, "Rendering and its cache never mutate persistent state")
	var target: Vector2i = world.cell
	world.persistent_state.set_environment(target, {"overload": 60})
	currents._process(0.6)
	check(currents.sites[0] == target and currents.refresh_count > refreshed, "An off-grid overload change invalidates readings and takes visual priority")
	var cached: int = currents.sample_builds
	world.persistent_state.set_environment(target, {"overload": -40})
	currents._process(0.6)
	check(currents.sample_builds == cached, "Signed environmental changes reuse immutable generated terrain")
	if DisplayServer.get_name() != "headless":
		var sample: Dictionary = currents.samples[target].duplicate(true)
		await process_frame
		await RenderingServer.frame_post_draw
		var custom: Color = currents.instances.get_instance_custom_data(0)
		check(is_equal_approx(custom.r, sample.phase) and custom.g == 0, "Batched data preserves each current's phase and smooth negative-overload flow")
		var transform: Transform3D = currents.instances.get_instance_transform(0)
		check(transform.origin.is_equal_approx(Vector3(target.x + 0.5, sample.height, target.y + 0.5)), "Batched currents retain their terrain anchors")
		check(currents.instances.custom_aabb.has_point(transform.origin + Vector3(1.4, 0.24, 0)), "Batch culling bounds include the animated strand displacement")
	else:
		print("VASTRA CURRENTS: 3 instance-buffer/bounds checks require a rendered run.")
	# The first displayed frame may emit the ordinary startup viewport rebuild.
	currents._process(0.6)
	refreshed = currents.refresh_count
	world.persistent_state.set_environment(target + Vector2i(100, 100), {"overload": 30})
	currents._process(0.6)
	check(currents.refresh_count == refreshed, "Distant changes do not invalidate local current readings")
	var battle := TacticalBattle.new()
	battle.action_serial = 1
	battle.vastra_overloads[AffinityImprint.key(target + Vector2i.RIGHT)] = 70
	battle.tile_overloads[target + Vector2i.RIGHT] = 70
	scene.battles.session = battle
	currents._process(0.6)
	check(currents.sites.has(target + Vector2i.RIGHT), "Uncommitted combat environmental effects remain visible")
	scene.battles.session = null
	currents._process(0.6)
	var old: ExpeditionState = world.persistent_state
	world.new_expedition(18)
	currents._process(0.6)
	check(currents.state == world.persistent_state and not old.environment_changed.is_connected(currents.on_environment), "State replacement disconnects old invalidation callbacks")
	refreshed = currents.refresh_count
	old.set_environment(target, {"overload": 90})
	currents._process(0.6)
	check(currents.refresh_count == refreshed, "A replaced state's later changes cannot refresh the live view")
	var original: Vector2i = world.cell
	for index in range(80):
		world.cell = original + Vector2i(index * 3, 0)
		currents._process(1.0 / 60.0)
	check(currents.samples.size() <= Currents.SAMPLE_CACHE_LIMIT and currents.sample_order.size() <= Currents.SAMPLE_CACHE_LIMIT, "Long travel keeps generated sample memory bounded")
	check(currents.instances.custom_aabb.position.length() < 64.0 and currents.instances.custom_aabb.size.length() < 100.0, "Travel keeps GPU instance bounds local rather than accumulating world-coordinate offsets")
	world.cell = original
	currents._process(0.6)
	cached = currents.sample_builds
	world.rebuilt.emit()
	currents._process(0.6)
	check(currents.sample_builds > cached, "Rebuilding the same terrain instance invalidates cached geometry")
	if OS.get_cmdline_user_args().has("--capture"):
		DirAccess.make_dir_recursive_absolute("res://artifacts/vastra-optimization")
		for frame in range(3):
			await process_frame
		await RenderingServer.frame_post_draw
		get_root().get_texture().get_image().save_png("res://artifacts/vastra-optimization/rendered.png")
	scene.queue_free()
	await process_frame
	print("VASTRA CURRENTS: %d checks, %d failures." % [checks, failures])
	quit(0 if failures == 0 else 1)
