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
	var tuning := SightingSettings.new()
	tuning.patrol_rest_chance = 1.0 # Isolate arrival/expiry rests; normal play can continue between goals.
	var home := Vector2i.ZERO
	var saved := {"action": "idle"}
	var memory := {"goal": [3, 0], "leg": 1, "expires": 8, "rest_until": 0}
	saved.patrol = memory
	var decision := SolRoamingPolicy.decide("fixture", home, Vector2i(3, 0), Vector2i(0, 7), "Wary", saved, 4, tuning)
	check(decision.action == "idle" and decision.patrol.rest_until >= 4 + tuning.rest_min_ticks, "Arriving at a goal starts a real rest")
	decision = SolRoamingPolicy.decide("fixture", home, home, Vector2i(0, 7), "Wary", saved, 9, tuning)
	check(decision.action == "idle" and decision.patrol.expires == 0, "Blocked goals expire into rest without teleportation")
	decision = SolRoamingPolicy.decide("fixture", home, home, Vector2i(1, 0), "Wary", saved, 5, tuning)
	check(decision.action == "flee" and decision.patrol.expires == 0, "Player reactions interrupt patrol goals")
	var phases := {}
	for index in range(20):
		decision = SolRoamingPolicy.decide("individual-%d" % index, home, home, Vector2i(0, 7), "Wary", {"action": "idle"}, 1, tuning)
		phases[decision.patrol.rest_until] = true
	check(phases.size() > 1, "Stable individuals have staggered initial rest phases")
	var wall := func(_from: Vector2i, to: Vector2i) -> bool: return to != Vector2i(1, 0)
	var step := SolLocalNavigation.next_step(home, home, "patrol", Vector2i(2, 0), {}, wall, tuning)
	check(step != home and step != Vector2i(1, 0) and SolRoamingPolicy.distance(step, Vector2i(2, 0)) > 2, "Path search takes a temporarily longer legal detour")
	var occupied := {Vector2i.UP: true, Vector2i.LEFT: true, Vector2i.RIGHT: true, Vector2i.DOWN: true}
	check(SolLocalNavigation.next_step(home, home, "patrol", Vector2i(2, 0), occupied, wall, tuning) == home, "Occupied exits wait without overlap")
	check(SolLocalNavigation.next_step(home, home, "flee", Vector2i(1, 0), occupied, wall, tuning) == home, "Cornered flight waits")
	tuning.rest_max_ticks = tuning.rest_min_ticks - 1
	check(not tuning.valid(), "Inverted rest ranges reject before decisions")
	tuning.rest_max_ticks = 5
	var scene: Node3D = (load("res://scenes/world_3d.tscn") as PackedScene).instantiate()
	scene.sighting_settings = tuning
	tuning.wilderness_enabled = false
	tuning.species_profiles_enabled = false # This suite checks the global patrol contract.
	root.add_child(scene)
	var world: Node2D = scene.world
	world.new_expedition(17)
	var controller: Node3D = scene.sightings
	var member: Dictionary = controller.members[0]
	world.cell = member.home + Vector2i(0, 7)
	world.destination = world.cell
	world.explorer.position = world.center(world.cell)
	world.camera.position = world.explorer.position
	world.moving = false
	var visited := {}
	var actions := {}
	for index in range(48):
		world.persistent_state.advance_time(0.75)
		var cell: Vector2i = controller.current_cell(member)
		visited[cell] = true
		actions[world.persistent_state.roaming_view(member.id).action] = true
		check(world.terrain.fits(cell) and SolRoamingPolicy.distance(cell, member.home) <= tuning.home_radius and cell != world.cell, "Autonomous movement respects terrain, home, and player occupancy")
	check(visited.size() > 2 and actions.has("patrol") and actions.has("idle"), "Stationary player sees autonomous wandering and rests over repeated cycles")
	var before: Dictionary = world.persistent_state.snapshot()
	controller.advance_roaming(world.persistent_state.activity_tick())
	controller.rebuild()
	check(world.persistent_state.snapshot() == before, "Same tick and view rebuild cannot reroll patrol memory")
	world.paused = true
	controller.advance_roaming(world.persistent_state.activity_tick() + 1)
	check(world.persistent_state.snapshot() == before, "Pause freezes movement and patrol memory")
	world.paused = false
	world.encounter_active = true
	controller.advance_roaming(world.persistent_state.activity_tick() + 1)
	check(world.persistent_state.snapshot() == before, "Encounter ownership suspends world AI")
	world.encounter_active = false
	var path := "user://sol-wandering-%d.json" % Time.get_ticks_usec()
	world.save_game(path)
	world.load_game(path)
	check(world.persistent_state.snapshot() == before, "Actual save/load preserves goal, leg, deadlines, position, and identity")
	var seed_value: int = world.terrain.world_seed
	var restored := ExpeditionState.restore(before, seed_value)
	world.persistent_state.advance_time(0.75)
	var expected: Dictionary = world.persistent_state.snapshot()
	# Replay the next actual domain step from the detached restored save.
	var row: Dictionary = restored.roaming_view(member.id)
	restored.advance_time(0.75)
	decision = SolRoamingPolicy.decide(member.id, member.home, Vector2i(row.cell[0], row.cell[1]), world.cell, "Wary", row, restored.activity_tick(), tuning)
	step = SolLocalNavigation.next_step(Vector2i(row.cell[0], row.cell[1]), member.home, decision.action, decision.goal, {world.cell: true}, world.can_step, tuning)
	check(restored.record_roaming_step(member.id, step, decision.action, decision.patrol) and restored.roaming_view(member.id) == expected.roaming[member.id], "Restored next movement and memory match uninterrupted patrol")
	check(expected.activity_tick == before.activity_tick + 1, "Uninterrupted world advances one exploration tick")
	for field in ["goal", "leg", "expires", "rest_until"]:
		var bad := before.duplicate(true)
		bad.roaming[member.id].patrol[field] = true
		check(ExpeditionState.restore(bad, seed_value) == null, "Malformed patrol %s rejects before restore" % field)
	var old := before.duplicate(true)
	old.version = 10
	check(ExpeditionState.restore(old, seed_value) == null, "Incompatible development state requires a new expedition")
	var bad := before.duplicate(true)
	bad.roaming[member.id].patrol.goal = [member.home.x + 6, member.home.y]
	check(ExpeditionState.restore(bad, seed_value) == null, "Out-of-envelope patrol goals reject")
	bad = before.duplicate(true)
	bad.roaming[member.id].patrol.expires = before.activity_tick + 129
	check(ExpeditionState.restore(bad, seed_value) == null, "Unbounded future patrol deadlines reject")
	tuning.wander_enabled = false
	check(SolRoamingPolicy.decide(member.id, member.home, member.home, world.cell, "Wary", row, restored.activity_tick() + 1, tuning).action == "idle", "Disabling wandering reaches the real behavior policy")
	tuning.wander_enabled = true
	if OS.get_cmdline_user_args().has("--capture-wandering") and DisplayServer.get_name() != "headless":
		world.smoke_mode = true
		controller.sync_views(1.0)
		DirAccess.make_dir_recursive_absolute("res://artifacts/roaming")
		for frame in range(5):
			await process_frame
		await RenderingServer.frame_post_draw
		get_root().get_texture().get_image().save_png("res://artifacts/roaming/wandering.png")
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(path + suffix):
			DirAccess.remove_absolute(path + suffix)
	scene.free()
	print("SOL WANDERING: %d checks, %d failures." % [checks, failures])
	quit(0 if failures == 0 else 1)
