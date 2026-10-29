extends SceneTree

var checks := 0
var failures := 0

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func _initialize() -> void:
	create_timer(120).timeout.connect(func() -> void: quit(1))
	run.call_deferred()

func run() -> void:
	var scene: Node3D = (load("res://scenes/world_3d.tscn") as PackedScene).instantiate()
	scene.sighting_settings = SightingSettings.new()
	scene.sighting_settings = scene.sighting_settings.duplicate(true)
	scene.sighting_settings.wilderness_enabled = false
	root.add_child(scene)
	var world: Node2D = scene.world
	world.smoke_mode = true
	var sightings: Node3D = scene.sightings
	check(sightings.members.size() == 3 and world.persistent_state.counts().individuals == 3, "The isolated legacy sighting preset contains exactly three authored persistent individuals")
	var identities: Array[String] = []
	for member in sightings.members:
		identities.append(member.id)
		check(world.terrain.fits(member.home) and member.home.y == world.terrain.trail_y(member.home.x), "Authored sightings use existing clear dry trail cells without terrain edits")
		check(member.sprite.mesh == null and not member.sprite.halo.visible and member.sprite.has_method("sync_locomotion"), "Authored Sols use procedural creature bodies without orb fallbacks")
	var first: Dictionary = sightings.members[0]
	world.cell = first.home + Vector2i(0, -1)
	world.explorer.position = world.center(world.cell)
	world.camera.position = world.explorer.position
	sightings.sync_views()
	var caption := SolReactionPolicy.caption(first.entry.reaction, world.persistent_state.roaming_view(first.id))
	check(first.sprite.visible and first.label.visible and first.label.text.contains(first.entry.name) and first.label.text.contains(caption), "Approaching a sighting reveals its name and current saved reaction caption")
	var before: Dictionary = world.persistent_state.snapshot()
	world.rebuild_world()
	check(world.persistent_state.snapshot() == before and sightings.members.size() == 3, "Render rebuild retains the same individuals rather than generating copies")
	for index in range(3):
		check(sightings.members[index].id == identities[index], "Stable home identity survives view reconstruction")
	world.paused = true
	var phase: float = sightings.elapsed
	sightings._process(2.0)
	check(sightings.elapsed == phase, "Pause freezes sighting animation")
	world.paused = false
	world.smoke_mode = false
	sightings._process(0.25)
	check(is_equal_approx(sightings.elapsed, phase + 0.25), "Active exploration advances animation without ecological mutation")
	world.smoke_mode = true
	world.cell = Vector2i(-100, -100)
	sightings.sync_views()
	check(not sightings.members[0].sprite.visible, "Inspector visibility range bounds distant display independently of saved records")
	world.cell = sightings.members[0].home + Vector2i(0, -1)
	world.camera.position = world.center(world.cell)
	sightings.sync_views()
	world.persistent_state.acquire(identities[0], "party")
	sightings.sync_views()
	check(not sightings.members[0].sprite.visible, "An acquired individual immediately disappears from the wild presentation")
	var path := "user://authored-sightings-%d.json" % Time.get_ticks_usec()
	world.save_game(path)
	before = world.persistent_state.snapshot()
	world.new_expedition(42)
	world.load_game(path)
	check(world.persistent_state.snapshot() == before and sightings.members.size() == 2, "Live reload preserves ownership and does not refill the acquired authored home")
	check(world.persistent_state.individual_view(identities[0]).location == "party" and world.persistent_state.counts().individuals == 3, "Loading retains exactly one copy of every authored individual")
	for seed_value in [1, 17, 88881, 2147483646]:
		world.new_expedition(seed_value)
		check(sightings.members.size() == 3, "Authored route-margin placement remains legal across representative seeds")
		for member in sightings.members:
			check(world.terrain.fits(member.home), "Authored homes never occupy blocked terrain")
	scene.sighting_settings.enabled = false
	sightings.rebuild()
	check(sightings.members.is_empty() and world.persistent_state.counts().individuals == 3, "Disabling the prototype hides views without deleting saved Sols")
	scene.sighting_settings.enabled = true
	sightings.rebuild()
	check(sightings.members.size() == 3 and world.persistent_state.counts().individuals == 3, "Re-enabling the view cannot reroll or duplicate identities")
	if OS.get_cmdline_user_args().has("--capture-sightings") and DisplayServer.get_name() != "headless":
		world.new_expedition(17)
		world.cell = sightings.members[0].home + Vector2i(-2, -1)
		world.rebuild_world()
		sightings.sync_views()
		DirAccess.make_dir_recursive_absolute("res://artifacts/sightings")
		for frame in range(5):
			await process_frame
		await RenderingServer.frame_post_draw
		get_root().get_texture().get_image().save_png("res://artifacts/sightings/seedmote.png")
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(path + suffix):
			DirAccess.remove_absolute(path + suffix)
	scene.free()
	print("AUTHORED SIGHTINGS: %d checks, %d failures." % [checks, failures])
	quit(0 if failures == 0 else 1)
