extends SceneTree
var failures := 0
var checks := 0
func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)
func _initialize() -> void:
	create_timer(120).timeout.connect(func() -> void: quit(1))
	run.call_deferred()
func run() -> void:
	var scene: Node3D = load("res://scenes/world_3d.tscn").instantiate()
	root.add_child(scene)
	var world: Node2D = scene.world
	world.smoke_mode = true
	world.new_expedition(17)
	check(scene.sightings.members.size() > 3, "Wilderness has persistent Sols beyond the trail trio")
	var before: Dictionary = world.persistent_state.snapshot()
	scene.sightings.rebuild()
	check(before == world.persistent_state.snapshot(), "Rendering cannot spawn or reroll wildlife")
	world.cell = Vector2i(180, -120)
	world.destination = world.cell
	world.explorer.position = world.center(world.cell)
	world.camera.position = world.explorer.position
	scene.sightings.admit_nearby(Vector2i.ZERO, world.cell)
	var generated: Dictionary = {}
	for member in scene.sightings.members:
		if member.entry.has("home") and Vector2(member.home - world.cell).length() <= 28:
			generated = member
			break
	check(not generated.is_empty(), "Distant wilderness admits visible legal wildlife")
	check(world.terrain.fits(generated.home) and generated.sprite.visible, "Generated Sol is visible on passable ground")
	var initial_members: Array = scene.sightings.members.duplicate()
	scene.sightings.admit_nearby(world.cell, world.cell + Vector2i.RIGHT)
	check(scene.sightings.members[0].sprite == initial_members[0].sprite, "Steps inside a sector preserve existing meshes and visual interpolation")
	var identity: String = generated.id
	world.persistent_state.acquire(identity, "party")
	scene.sightings.admit_nearby(world.cell, world.cell)
	check(not world.persistent_state.wild_available(identity), "Exploration cannot respawn a captured individual")
	var path := "user://wilderness-test-%d.json" % Time.get_ticks_usec()
	world.save_game(path)
	before = world.persistent_state.snapshot()
	world.new_expedition(42)
	world.load_game(path)
	check(world.persistent_state.snapshot() == before, "Wilderness identities and capture survive save/reload")
	DirAccess.remove_absolute(path)
	check(scene.environment.ssao_enabled == scene.active_view.ambient_occlusion and root.msaa_3d == scene.active_view.multisample_antialiasing, "Configured AO and anti-aliasing reach the viewport")
	scene.active_view = scene.active_view.duplicate()
	scene.active_view.detail_distance = 24
	scene.apply_camera()
	for chunk in scene.solid_chunks.values():
		scene.configure_asset_distances(chunk)
		for mesh in chunk.get_children():
			if mesh.name.begins_with("nature_detail_"):
				check(mesh.visibility_range_end == 24, "Foliage honors its shorter configured distance")
	world.new_expedition(17)
	var settings: BattleSettings = scene.battle_settings
	var hero := settings.starters[0].snapshot()
	var battle := TacticalBattle.prepare(world.terrain, world.cell, Vector2i(3, 0), hero, int(hero.max_hp), settings.opponents[0].snapshot(), settings, true)
	battle.commander_route = BattleCommander.plan(battle, world.cell, world.can_step)
	if not battle.commander_route.is_empty():
		battle.trainer = battle.commander_route.back()
	var player: Node3D = scene.player_visual
	var route: Array[Vector2i] = player.sideline_path(world, battle)
	check(not route.is_empty() and not battle.bounds.has_point(route[-1]), "Trainer finds a reachable sideline outside the arena")
	var previous: Vector2i = world.cell
	for at in route:
		check(world.can_step(previous, at), "Sideline walk respects terrain and barriers")
		previous = at
	before = world.persistent_state.snapshot()
	scene.battles.session = battle
	for frame in range(200):
		player._process(0.05)
	check(player.presentation_cell.is_equal_approx(Vector2(route[-1])) and player.animator.current_animation == "Idle_A", "Trainer walks outside the arena and settles")
	check(world.cell == Vector2i.ZERO and before == world.persistent_state.snapshot() and battle.trainer == route[-1], "The visual run preserves expedition state while combat owns the outside throw position")
	scene.battles.session = null
	for frame in range(200):
		player._process(0.05)
	check(not player.returning and player.presentation_cell.is_equal_approx(Vector2.ZERO), "Trainer walks back to the original spot after battle")
	scene.environment.sky = null
	scene.free()
	print("WILDERNESS PRESENTATION: %d checks, %d failures." % [checks, failures])
	quit(0 if failures == 0 else 1)

