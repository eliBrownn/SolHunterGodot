extends SceneTree
const Validation = preload("res://scripts/runtime_validation_cache.gd")
const Ground = preload("res://scripts/streaming_ground.gd")
const Streaming = preload("res://scripts/view_streaming.gd")
const Overlay = preload("res://scripts/affinity_ground.gd")
var checks := 0
var failures := 0

class CountingState extends ExpeditionState:
	var roaming_reads := 0
	func _init() -> void:
		super(17)
	func roaming_view(identity: String) -> Dictionary:
		roaming_reads += 1
		return super.roaming_view(identity)

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)

func _initialize() -> void:
	create_timer(150).timeout.connect(func() -> void: quit(1))
	run.call_deferred()

func settle() -> void:
	for frame in range(12):
		await process_frame

func temporary_validation_resource(cache: RefCounted) -> WeakRef:
	# Check after this scope returns so VM call-argument temporaries are gone.
	var tuning := ExpeditionSettings.new()
	var reference: WeakRef = weakref(tuning)
	cache.check(tuning)
	return reference

func legacy_visible(camera: Camera3D, relative: Vector2, height: float, margin: float, minimum: float) -> bool:
	var center := Vector3(relative.x + 8, (height + minimum) * 0.5, relative.y + 8)
	var extent := Vector3(8 + margin, (height - minimum) * 0.5 + 0.5, 8 + margin)
	for plane in camera.get_frustum():
		if plane.distance_to(center) > plane.normal.abs().dot(extent):
			return false
	return true

func run() -> void:
	var cache := Validation.new()
	var library: MoveLibrary = load("res://resources/move_library.tres").duplicate(true)
	var dependencies: Array = [preload("res://resources/sol_ecology/behavior_library.tres")]
	check(cache.check(library, dependencies) and library.valid(), "Initial validation agrees with the full validator")
	for repetition in range(20):
		cache.check(library, dependencies)
	check(cache.validation_runs == 1, "Unchanged nested resources do not repeat full validation")
	var power: int = library.moves[0].power
	library.moves[0].power = -1
	check(not cache.check(library, dependencies) and cache.validation_runs == 2, "Direct nested edits invalidate a formerly valid result")
	library.moves[0].power = power
	check(cache.check(library, dependencies), "Repairing an invalid nested value is recognized immediately")
	library.moves.append(null)
	check(not cache.check(library, dependencies), "In-place resource-array edits invalidate the result")
	library.moves.pop_back()
	check(cache.check(library, dependencies), "Restoring an edited resource array restores validity")
	if not library.species_pools.is_empty():
		var species: String = library.species_pools.keys()[0]
		var original_pool: PackedStringArray = library.species_pools[species].duplicate()
		var changed_pool := original_pool.duplicate()
		changed_pool.append("unknown_hot_path_test_move")
		library.species_pools[species] = changed_pool
		check(not cache.check(library, dependencies), "Packed-array changes inside a dictionary invalidate validation")
		library.species_pools[species] = original_pool
		check(cache.check(library, dependencies), "Restoring packed-array content restores validity")
	var dependency: SolBehaviorDefinition = dependencies[0].definitions[0]
	var old_priority: int = dependency.priority
	var old_runs: int = cache.validation_runs
	dependency.priority += 1
	check(cache.check(library, dependencies) == library.valid() and cache.validation_runs == old_runs + 1, "External validator dependencies trigger a full recheck")
	dependency.priority = old_priority
	check(cache.check(library, dependencies), "External dependencies restore without a stale validation result")
	if not library.species_catalog.entries.is_empty():
		var entry: SolSpeciesRecord = library.species_catalog.entries[0]
		var original: PackedScene = entry.presentation_scene
		var packed := PackedScene.new()
		var invalid_root := Node3D.new()
		packed.pack(invalid_root)
		invalid_root.free()
		entry.presentation_scene = packed
		check(not cache.check(library, dependencies), "Replacing a packed presentation root invalidates validation")
		var good_root: Variant = load("res://scenes/sols/crown_ear.tscn").instantiate()
		packed.pack(good_root)
		good_root.free()
		check(cache.check(library, dependencies), "Repacking the same PackedScene with a valid root is detected")
		entry.presentation_scene = original
		check(cache.check(library, dependencies), "Original catalog presentation remains valid")
	var disposable := Validation.new()
	var weak_tuning := temporary_validation_resource(disposable)
	check(weak_tuning.get_ref() == null, "Validation memo does not retain its resource graph")
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280, 800)
	var scene: Node3D = load("res://scenes/world_3d.tscn").instantiate()
	root.add_child(scene)
	var world: Node2D = scene.world
	world.smoke_mode = true
	world.new_expedition(17)
	var before: Dictionary = world.persistent_state.snapshot()
	var local_settings: SightingSettings = scene.sightings.settings.duplicate(true)
	scene.sightings.settings = local_settings
	check(scene.sightings.settings_valid(), "Live sighting tuning starts valid")
	local_settings.visible_radius = 0
	check(not scene.sightings.settings_valid(), "Invalid direct Inspector-style edits reject cached sighting tuning")
	local_settings.visible_radius = 28
	check(scene.sightings.settings_valid(), "Valid live sighting tuning is restored without restart")
	local_settings.species_catalog_path = ""
	local_settings.species_catalog = null
	check(not scene.sightings.settings_valid(), "An explicit expired/null catalog override cannot reuse a valid cached result")
	scene.sightings.settings = scene.sighting_settings
	check(scene.sightings.settings_valid(), "Replacing the sighting settings resource refreshes validation")
	for azimuth in [0.0, 90.0, -90.0]:
		scene.view_azimuth = azimuth
		scene.apply_camera()
		var planes: Array[Plane] = scene.camera.get_frustum()
		for y in range(-3, 4):
			for x in range(-3, 4):
				var relative: Vector2 = Vector2(x * 16, y * 16) - world.camera.position / 32.0
				check(Streaming.visible_with_planes(planes, relative, 7, 8, -5) == legacy_visible(scene.camera, relative, 7, 8, -5), "Shared frustum planes preserve conservative visibility")
	scene.reset_camera()
	var ground := Ground.new()
	scene.solid_root.add_child(ground)
	var pending: Array[Vector2i] = []
	for coord: Vector2i in scene.stream_plan():
		if Streaming.visible(scene.camera, Vector2(coord * 16) - world.camera.position / 32.0, scene.height_bound(), 0, -scene.height_bound()):
			pending.append(coord)
			break
	var origin: Vector2 = world.camera.position / 32.0
	ground.sync(world.terrain, pending, scene.camera, origin, scene.height_bound(), 4, 2)
	check(ground.chunks.size() == 1, "Visible pending terrain has immediate temporary coverage")
	var coord: Vector2i = pending[0]
	var original_ground: WeakRef = weakref(ground.chunks[coord])
	var count: int = ground.builds
	var passes: int = ground.visibility_passes
	ground.sync(world.terrain, pending, scene.camera, origin, scene.height_bound(), 4, 2)
	check(ground.visibility_passes == passes, "Unchanged views skip repeated temporary visibility passes")
	ground.sync(world.terrain, [], scene.camera, origin, scene.height_bound(), 4, 2)
	check(ground.chunks.is_empty() and ground.retained.size() == 1 and not original_ground.get_ref().visible, "Retained temporary terrain is hidden after detailed publication")
	ground.sync(world.terrain, pending, scene.camera, origin, scene.height_bound(), 4, 2)
	check(ground.chunks[coord] == original_ground.get_ref() and ground.builds == count and ground.reuses == 1, "Camera reversal reuses the same temporary mesh")
	ground.sync(WorldTerrain.new(42), pending, scene.camera, origin, scene.height_bound(), 4, 2)
	check(original_ground.get_ref() == null and ground.source.world_seed == 42, "A new terrain source cannot reuse stale temporary geometry")
	ground.sync(ground.source, [], scene.camera, origin, scene.height_bound(), 8, 0)
	check(ground.retained.is_empty() and ground.chunks.is_empty(), "Resolution changes and zero cache capacity release retained geometry")
	var many: Array[Vector2i] = []
	for candidate: Vector2i in scene.stream_plan():
		if Streaming.visible(scene.camera, Vector2(candidate * 16) - origin, scene.height_bound(), 0, -scene.height_bound()):
			many.append(candidate)
			if many.size() == 4:
				break
	ground.sync(world.terrain, many, scene.camera, origin, scene.height_bound(), 4, 2)
	ground.sync(world.terrain, [], scene.camera, origin, scene.height_bound(), 4, 2)
	check(ground.retained.size() == 2, "Camera-cache eviction enforces the configured capacity")
	ground.free()
	check(world.persistent_state.snapshot() == before, "Frustum and temporary terrain changes preserve persistent simulation")
	var counting := CountingState.new()
	world.replace_persistent_state(counting)
	world.state_replaced.emit(counting)
	world.rebuild_world()
	counting.roaming_reads = 0
	before = counting.snapshot()
	scene.sightings.sync_views(0)
	check(counting.roaming_reads == scene.sightings.members.size(), "Sol views fetch one isolated roaming snapshot per member")
	check(counting.snapshot() == before, "Reusing a roaming read does not mutate simulation")
	var overlay: Node3D
	for node in scene.get_children():
		if node.get_script() == Overlay:
			overlay = node
	var report := {"winner": "earth", "tiles": ["0:0", "1:0", "100:100"], "fields": {}, "interval": 8}
	# Exercise the enabled overlay regardless of the production visibility default.
	overlay.palette = overlay.palette.duplicate()
	overlay.palette.imprint_opacity = 0.2
	counting._affinity_tiles = AffinityImprint.apply({}, report, counting.activity_tick(), ExpeditionState.MAX_TILE_DELTAS)
	overlay.refresh()
	check(overlay.tiles.size() == 2, "Only nearby imprints receive overlay geometry")
	var first: MeshInstance3D = overlay.tiles[Vector2i.ZERO]
	var first_id := first.get_instance_id()
	var first_material: Material = first.material_override
	var first_mesh: Mesh = first.mesh
	overlay.refresh()
	check(overlay.tiles[Vector2i.ZERO].get_instance_id() == first_id and first.mesh == first_mesh, "Unchanged ticks retain overlay nodes and ground meshes")
	counting._affinity_tiles["0:0"].affinity = "fire"
	overlay.refresh()
	check(first.material_override == first_material and first.material_override.albedo_color == Color(overlay.palette.color_for("fire"), overlay.palette.imprint_opacity), "Changed affinities recolor an existing material")
	var absolute: Vector3 = first.global_position
	world.camera.position += Vector2(64, -32)
	overlay._process(0)
	check(first.global_position.is_equal_approx(absolute + Vector3(-2, 0, 1)), "One root transform preserves camera-relative overlay grounding")
	world.camera.position -= Vector2(64, -32)
	overlay._process(0)
	var dense := ExpeditionState.new(17)
	for y in range(-16, 16):
		for x in range(-16, 16):
			dense._affinity_tiles[AffinityImprint.key(Vector2i(x, y))] = {"affinity": "earth", "conditions": {}}
	var expected := {}
	for at: String in dense.affinity_tiles():
		var parts := at.split(":")
		var cell := Vector2i(int(parts[0]), int(parts[1]))
		if (cell - Vector2i(-3, 2)).length_squared() <= 196:
			expected[cell] = "earth"
	var nearby := dense.affinity_colors_near(Vector2i(-3, 2), 14)
	check(nearby == expected, "Bounded spatial imprint reads match exhaustive filtering")
	nearby.clear()
	check(dense.affinity_tiles().size() == 1024, "Presentation snapshots cannot mutate stored imprints")
	world.persistent_state.choose_starter(scene.battle_settings.starters[0].snapshot(), 0)
	var member: Dictionary = scene.sightings.members[0]
	world.cell = member.home + Vector2i.LEFT
	world.destination = world.cell
	world.rebuild_world()
	scene.encounters.approach_nearest()
	scene.encounters.battle_button.pressed.emit()
	var hud: CombatHud = scene.battles.combat_hud
	await settle()
	var layouts := hud.layout_updates
	for frame in range(30):
		hud._process(0)
	check(hud.layout_updates == layouts, "Settled combat UI does not rewrite layout each frame")
	hud.target_label.text = "Long wrapped target information requiring a new content height. ".repeat(20)
	await settle()
	check(hud.layout_updates > layouts, "Content minimum-size changes request a deferred layout correction")
	var previous_width: float = hud.tray.size.x
	world.menu.settings.text_scale = 1.4
	hud._process(0)
	check(hud.tray.size.x > previous_width, "Direct text-scale edits invalidate cached layout inputs")
	root.size = Vector2i(800, 600)
	await settle()
	check(hud.tray.position.x >= 0 and hud.tray.get_rect().end.x <= root.get_visible_rect().size.x + 1, "Resized and wrapped combat UI remains within viewport bounds")
	if OS.get_cmdline_user_args().has("--capture-hot-paths") and DisplayServer.get_name() != "headless":
		DirAccess.make_dir_recursive_absolute("res://artifacts/optimization_pass2")
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://artifacts/optimization_pass2/combat-layout.png")
	scene.free()
	print("RUNTIME HOT PATHS: %d checks, %d failures." % [checks, failures])
	quit(0 if failures == 0 else 1)
