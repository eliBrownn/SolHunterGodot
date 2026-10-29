extends SceneTree

class BlockedTerrain extends WorldTerrain:
	func can_step(_from: Vector2i, _to: Vector2i, _footprint: int = 1) -> bool:
		return false

var checks := 0
var failures := 0
var activity: Array = []

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func _initialize() -> void:
	create_timer(150).timeout.connect(func() -> void: quit(1))
	run.call_deferred()

func put_player(world: Node2D, cell: Vector2i) -> void:
	world.cell = cell
	world.destination = cell
	world.moving = false
	world.explorer.position = world.center(cell)
	world.camera.position = world.explorer.position

func run() -> void:
	var tuning := SightingSettings.new()
	var routine := {"mode": "alert", "until": 0, "move_after": 0, "attention_until": 0, "routine_until": 20}
	var saved := {"action": "idle", "response": routine, "patrol": {"goal": [5, 0], "leg": 1, "expires": 0, "rest_until": 0}}
	var decision := SolRoamingPolicy.decide("fixture", Vector2i(4, 0), Vector2i(4, 0), Vector2i.ZERO, "Wary", saved, 5, tuning)
	check(decision.action == "patrol" and decision.response.mode == "alert" and decision.minimum_player_distance == tuning.reaction_distance + 1, "Alertness allows safe routine movement instead of indefinite watching")
	check(SolRoamingPolicy.distance(decision.goal, Vector2i.ZERO) >= decision.minimum_player_distance, "Cautious patrol goals keep their player buffer")
	decision = SolRoamingPolicy.decide("fixture", Vector2i(4, 0), Vector2i(4, 0), Vector2i(3, 0), "Wary", saved, 6, tuning)
	check(decision.action == "flee" and decision.response.routine_until == 0, "A close approach immediately interrupts routine movement")
	var wall := func(_from: Vector2i, to: Vector2i) -> bool: return to != Vector2i(4, 1)
	var step := SolLocalNavigation.next_step(Vector2i(4, 0), Vector2i(4, 0), "patrol", Vector2i(4, 2), {}, wall, tuning, Vector2i.ZERO, 4)
	check(step != Vector2i(3, 0) and SolRoamingPolicy.distance(step, Vector2i.ZERO) >= 4, "Obstacle detours cannot cut through the player's avoidance buffer")
	var open := func(_from: Vector2i, _to: Vector2i) -> bool: return true
	step = SolLocalNavigation.next_step(Vector2i.ZERO, Vector2i.ZERO, "guard", Vector2i(-3, 0), {}, open, tuning)
	check(step == Vector2i.LEFT and SolRoamingPolicy.distance(step, Vector2i(-3, 0)) == tuning.guard_standoff_distance, "Guard visibly closes distance to its configured standoff")
	check(SolLocalNavigation.next_step(step, Vector2i.ZERO, "guard", Vector2i(-3, 0), {}, open, tuning) == step, "Guard stops at standoff instead of stepping onto the player")
	var never := func(_cell: Vector2i) -> bool: return false
	check(SolRoamingPolicy.next_goal("fixture", 0, Vector2i.ZERO, Vector2i.ZERO, Vector2i.ONE, tuning, never) == Vector2i.ZERO, "No legal patrol goals means waiting without teleporting")
	tuning.patrol_rest_chance = 0
	var memory := {"goal": [1, 0], "leg": 2, "expires": 8, "rest_until": 0}
	decision = SolRoamingPolicy.patrol("fixture", Vector2i.ZERO, Vector2i.RIGHT, 4, memory, tuning)
	check(decision.action == "patrol" and decision.goal != Vector2i.RIGHT, "Zero rest probability continues directly into the next leg")
	tuning.patrol_rest_chance = 1
	decision = SolRoamingPolicy.patrol("fixture", Vector2i.ZERO, Vector2i.RIGHT, 4, {"goal": [1, 0], "leg": 2, "expires": 8, "rest_until": 0}, tuning)
	check(decision.action == "idle" and decision.patrol.rest_until > 4, "Full rest probability remains connected to deliberate resting")
	tuning.patrol_rest_chance = NAN
	check(not tuning.valid(), "Nonfinite activity tuning rejects")
	tuning = SightingSettings.new().duplicate(true)
	tuning.wilderness_enabled = false
	var scene: Node3D = load("res://scenes/world_3d.tscn").instantiate()
	scene.sighting_settings = tuning
	scene.encounter_settings = EncounterSettings.new()
	scene.encounter_settings.automatic_contact = false
	root.add_child(scene)
	var world: Node2D = scene.world
	var sightings: Node3D = scene.sightings
	for seed_value in [17, 2601026]:
		for member_index in range(3):
			for distance in [3, 7]:
				world.new_expedition(seed_value)
				var member: Dictionary = sightings.members[member_index]
				put_player(world, member.home + Vector2i(-distance, 0))
				var moved := 0
				var visited := {}
				var still := 0
				var longest_still := 0
				var legal := true
				for tick in range(80):
					var previous: Vector2i = sightings.current_cell(member)
					world.persistent_state.advance_time(0.75)
					sightings.sync_views(0.75)
					var cell: Vector2i = sightings.current_cell(member)
					legal = legal and cell != world.cell and world.terrain.fits(cell) and sightings.manhattan(cell, member.home) <= tuning.home_radius
					visited[str(cell)] = true
					if previous != cell:
						moved += 1
						still = 0
					else:
						still += 1
						longest_still = maxi(longest_still, still)
				check(moved >= 32 and visited.size() >= 4, "Default %s explores instead of parking for a minute (seed %d, player distance %d)" % [member.entry.reaction, seed_value, distance])
				check(longest_still <= 12 and legal, "Activity remains bounded by legal terrain, player occupancy, territory, and finite stationary periods")
				activity.append({"seed": seed_value, "posture": member.entry.reaction, "distance": distance, "moves": moved, "ticks": 80, "cells": visited.size(), "longest_still_ticks": longest_still})
	world.new_expedition(17)
	var guard: Dictionary = sightings.members[2]
	put_player(world, guard.home + Vector2i(-3, 0))
	scene.encounter_settings.automatic_contact = true
	scene.encounters.refresh_warning()
	scene.encounters.mark_warning_presented()
	scene.encounters._process(scene.encounter_settings.warning_delay_seconds)
	world.persistent_state.advance_time(0.75)
	check(sightings.current_cell(guard) != guard.home and not world.encounter_active, "A guard's actual confrontation movement cannot start combat on an AI tick")
	var old_cell: Vector2i = world.cell
	world.advance_movement(float(world.expedition_parameters().move_seconds), Vector2.RIGHT)
	check(world.encounter_active and scene.encounters.active_target.id == guard.id and world.cell != old_cell, "Continuing toward the confronting guard on a later player step reaches the warned encounter")
	scene.encounters.withdraw()
	scene.encounters.safe_steps = 0
	world.new_expedition(17)
	guard = sightings.members[2]
	put_player(world, guard.home + Vector2i(-3, 0))
	scene.encounters.refresh_warning()
	scene.encounters.mark_warning_presented()
	scene.encounters._process(scene.encounter_settings.warning_delay_seconds)
	world.persistent_state.advance_time(0.75)
	old_cell = world.cell
	world.advance_movement(float(world.expedition_parameters().move_seconds), Vector2.LEFT)
	check(not world.encounter_active and world.cell != old_cell, "Backing away from a moving guard remains possible")
	scene.encounter_settings.automatic_contact = false
	world.new_expedition(17)
	var member: Dictionary = sightings.members[0]
	put_player(world, member.home + Vector2i(-3, 0))
	world.persistent_state.advance_time(0.75)
	var before: Dictionary = world.persistent_state.snapshot()
	var path := "user://sol-activity-%d.json" % Time.get_ticks_usec()
	world.save_game(path)
	world.load_game(path)
	check(world.persistent_state.snapshot() == before, "Current save/load retains attention and routine deadlines")
	for field in ["attention_until", "routine_until"]:
		var bad := before.duplicate(true)
		bad.roaming[member.id].response[field] = true
		check(ExpeditionState.restore(bad, 17) == null, "Malformed activity deadline rejects before restoration")
	var bad := before.duplicate(true)
	bad.roaming[member.id].response.routine_until = before.activity_tick + 129
	check(ExpeditionState.restore(bad, 17) == null, "Unbounded routine deadline rejects")
	world.new_expedition(17)
	member = sightings.members[0]
	put_player(world, member.home + Vector2i(-7, 0))
	world.terrain = BlockedTerrain.new(17)
	for tick in range(10):
		world.persistent_state.advance_time(0.75)
	var blocked: Dictionary = world.persistent_state.roaming_view(member.id)
	check(sightings.current_cell(member) == member.home and int(blocked.patrol.leg) >= 2, "Blocked patrols choose another goal before the long leg timeout without teleporting")
	var file := FileAccess.open("res://artifacts/sol_activity_acceptance.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(activity, "  "))
	file.close()
	if OS.get_cmdline_user_args().has("--capture-activity") and DisplayServer.get_name() != "headless":
		world.new_expedition(17)
		scene.encounter_settings.automatic_contact = true
		guard = sightings.members[2]
		put_player(world, guard.home + Vector2i(-3, 0))
		world.rebuild_world()
		world.persistent_state.advance_time(0.75)
		sightings.sync_views(0.75)
		scene.sync_ground()
		scene.encounters.refresh_warning()
		world.smoke_mode = true
		scene.encounters.set_process(false)
		DirAccess.make_dir_recursive_absolute("res://artifacts/activity")
		for frame in range(5):
			await process_frame
		await RenderingServer.frame_post_draw
		get_root().get_texture().get_image().save_png("res://artifacts/activity/confrontation.png")
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(path + suffix):
			DirAccess.remove_absolute(path + suffix)
	scene.free()
	print("SOL ACTIVITY: %d checks, %d failures." % [checks, failures])
	quit(0 if failures == 0 else 1)
