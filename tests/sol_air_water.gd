extends SceneTree
var Catalog: Resource
var checks := 0
var failures := 0

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)

func _initialize() -> void:
	Catalog = load("res://resources/sol_species/catalog.tres")
	create_timer(180).timeout.connect(func() -> void: quit(1))
	run.call_deferred()

func run() -> void:
	var scene = load("res://scenes/sol_traversal_pilot.tscn").instantiate()
	root.add_child(scene)
	if "--capture" in OS.get_cmdline_user_args():
		root.mode = Window.MODE_WINDOWED
		root.size = Vector2i(1280, 800)
	var world: Node2D = scene.world
	world.smoke_mode = true
	world.new_expedition(17)
	check(scene.sightings.members.size() == 6, "Traversal scenario admits three pilots without rewriting generated terrain")
	if scene.sightings.members.size() != 6:
		scene.free()
		quit(1)
		return
	var crown: Dictionary = scene.sightings.members.filter(func(row: Dictionary) -> bool: return row.entry.species == "sol_species_0001")[0]
	var reed: Dictionary = scene.sightings.members.filter(func(row: Dictionary) -> bool: return row.entry.species == "sol_species_0002")[0]
	var state: ExpeditionState = world.persistent_state
	check(state.roaming_view(crown.id).traversal.policy.kind == "flight" and state.roaming_view(reed.id).traversal.policy.kind == "swim", "Admitted capabilities come from species records")
	var old_policy: Dictionary = state.roaming_view(crown.id).traversal.policy.duplicate(true)
	var changed_policy := old_policy.duplicate(true)
	changed_policy.altitude = 1.3
	state.admit_traversal(crown.id, changed_policy)
	check(state.roaming_view(crown.id).traversal.policy == old_policy, "Authoring edits cannot rewrite an admitted individual's movement capability")
	for bad_value in [null, {}, {"kind": "water"}, old_policy.merged({"altitude": INF}, true), old_policy.merged({"radius": -1}, true)]:
		check(not SolTraversalProfile.valid_policy(bad_value), "Malformed traversal policy rejects")
	var travel: Dictionary = state.roaming_view(crown.id).traversal
	for edit in [{"mode": "swim"}, {"mode_tick": -1}, {"settle": "yes"}, {"from": [1, 2, 3]}, {"from": [INF, 0]}]:
		check(not SolTraversalProfile.valid_state(travel.merged(edit, true), 0, state.roaming_view(crown.id).cell), "Malformed or cross-capability movement state rejects")
	world.cell = crown.home + Vector2i.LEFT * 3
	world.destination = world.cell
	var at: Vector2i = crown.home
	var tuning: SightingSettings = scene.sighting_settings
	var occupied := {world.cell: true}
	for expected_mode in ["takeoff", "air"]:
		state.advance_time(0.75)
		var step := SolTraversalPolicy.advance(world, at, crown.home, "return", at + Vector2i.RIGHT, travel, occupied, [], tuning, state.activity_tick())
		travel = step.traversal
		check(step.target == at and travel.mode == expected_mode, "Flight launches vertically before horizontal travel: " + expected_mode)
		check(state.record_roaming_step(crown.id, step.target, "return", {}, {}, travel), "Takeoff state commits under the existing clock")
		verify_save(world, crown.id)
	state.advance_time(0.75)
	var flight_step := SolTraversalPolicy.advance(world, at, crown.home, "return", at + Vector2i.RIGHT, travel, occupied, [], tuning, state.activity_tick())
	check(flight_step.target == at + Vector2i.RIGHT and flight_step.traversal.mode == "air", "Air travel commits one legal cardinal cell")
	check(state.record_roaming_step(crown.id, flight_step.target, "return", {}, {}, flight_step.traversal), "Air position and mode persist together")
	at = flight_step.target
	travel = flight_step.traversal
	verify_save(world, crown.id)
	var center := Vector2(at) + Vector2(0.5, 0.5)
	var altitude: float = world.terrain.display_height(center) + travel.policy.altitude
	var wall := AABB(Vector3(center.x - 0.2, altitude - 0.1, center.y - 0.2), Vector3(0.4, 1.0, 0.4))
	check(not SolTraversalPolicy.can_step(world, at, at + Vector2i.RIGHT, travel, [wall]), "Swept body/wing volume cannot pass a wall or canopy bound")
	check(not SolTraversalPolicy.can_land(world, at, travel, {}, [wall]), "Blocked vertical corridor cannot be used for landing")
	check(not SolTraversalPolicy.can_land(world, at, travel, {at: true}, []), "Landing cannot occupy another actor's reserved cell")
	state.advance_time(0.75)
	var landing := SolTraversalPolicy.advance(world, at, crown.home, "idle", at, travel, occupied, [], tuning, state.activity_tick())
	check(landing.traversal.mode == "landing" and landing.target == at, "Idle airborne creature begins a validated landing")
	state.record_roaming_step(crown.id, at, "idle", {}, {}, landing.traversal)
	verify_save(world, crown.id)
	world.cell = at
	state.advance_time(0.75)
	var aborted := SolTraversalPolicy.advance(world, at, crown.home, "idle", at, landing.traversal, {at: true}, [], tuning, state.activity_tick())
	check(aborted.traversal.mode == "air" and aborted.target == at, "Occupied landing aborts safely to air without teleportation")
	world.cell = crown.home + Vector2i.LEFT * 3
	world.destination = world.cell
	state.record_roaming_step(crown.id, at, "idle", {}, {}, aborted.traversal)
	var bank: Vector2i = reed.home
	var wet := bank
	var swim_state: Dictionary = state.roaming_view(reed.id).traversal
	world.cell = bank + Vector2i.LEFT * 3
	world.destination = world.cell
	for direction in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		if SolTraversalPolicy.water(world.terrain, bank + direction) and SolTraversalPolicy.can_step(world, bank, bank + direction, swim_state, []):
			wet = bank + direction
			break
	check(wet != bank and world.terrain.fits(bank), "Review home is a real dry bank beside swimmable generated water")
	check(not world.can_step(bank, wet), "Player and ordinary ground movement still cannot enter that water")
	check(SolTraversalPolicy.can_step(world, bank, wet, travel, []), "Clear low-flight corridor can cross real water")
	for mode in ["swim_enter", SolTraversalPolicy.water_mode(world.terrain, wet, swim_state.policy)]:
		state.advance_time(0.75)
		var step := SolTraversalPolicy.advance(world, bank if mode == "swim_enter" else wet, bank, "return", wet, swim_state, {}, [], tuning, state.activity_tick())
		swim_state = step.traversal
		check(step.target == wet and swim_state.mode == mode, "Swimming enters the actual pond through explicit state: " + mode)
		check(state.record_roaming_step(reed.id, wet, "return", {}, {}, swim_state), "Swim mode and position commit atomically")
		verify_save(world, reed.id)
	check(not SolTraversalPolicy.can_land(world, wet, travel, {}, []), "Flight cannot land in water")
	var water_center := Vector2(wet) + Vector2(0.5, 0.5)
	var swimmer_bottom: float = world.terrain.display_height(water_center) - swim_state.policy.draft
	check(not SolTraversalPolicy.can_step(world, wet, bank, swim_state, [AABB(Vector3(water_center.x - 0.3, swimmer_bottom, water_center.y - 0.3), Vector3(0.6, 1, 0.6))]), "A blocked shore transition cannot pass scenery")
	for mode in ["swim_exit", "ground"]:
		state.advance_time(0.75)
		var step := SolTraversalPolicy.advance(world, wet if mode == "swim_exit" else bank, bank, "return", bank, swim_state, {}, [], tuning, state.activity_tick())
		swim_state = step.traversal
		check(step.target == bank and swim_state.mode == mode, "Swimming exits through a legal bank: " + mode)
		state.record_roaming_step(reed.id, bank, "return", {}, {}, swim_state)
		verify_save(world, reed.id)
	await verify_models()
	await verify_live(scene, crown, reed)
	print("SOL AIR AND WATER: %d checks, %d failures. Pond bank %s, water %s." % [checks, failures, bank, wet])
	scene.free()
	await process_frame
	quit(0 if failures == 0 else 1)

func verify_save(world: Node2D, identity: String) -> void:
	var snapshot: Dictionary = world.persistent_state.snapshot()
	var restored := ExpeditionState.restore(JSON.parse_string(JSON.stringify(snapshot)), world.terrain.world_seed)
	check(restored != null and restored.roaming_view(identity) == world.persistent_state.roaming_view(identity), "Mode and transition survive JSON save/load without rerolls")
	var envelope := ExpeditionSave.snapshot(world.terrain.world_seed, Vector2i.ZERO, false, false, WorldTerrain.GENERATION_VERSION, world.terrain.climate, snapshot, world.terrain.relief)
	check(ExpeditionSave.validate(envelope), "Actual save envelope admits valid air/water positions")
	var path := "res://artifacts/sol_air_water/mode_save.json"
	var error := ExpeditionSave.write(envelope, path)
	var disk := ExpeditionSave.read_save(path)
	var disk_state := ExpeditionState.restore(disk.world_state, world.terrain.world_seed) if not disk.is_empty() else null
	check(error == OK and disk_state != null and disk_state.roaming_view(identity) == snapshot.roaming[identity], "Movement state survives actual save-file writing and reading")
	var halfway := snapshot.duplicate(true)
	halfway.remainder_seconds = 0.375
	var resumed := ExpeditionState.restore(halfway, world.terrain.world_seed)
	var row: Dictionary = halfway.roaming[identity]
	var at := Vector2(row.cell[0], row.cell[1]) + Vector2(0.5, 0.5)
	var expected := SolTraversalPolicy.presentation(world.terrain, row, at, int(halfway.activity_tick) * 0.75 + 0.375)
	check(resumed != null and SolTraversalPolicy.presentation(world.terrain, resumed.roaming_view(identity), at, resumed.activity_seconds()) == expected, "A restored midpoint uses the same transition height and animation clock")

func flat(_at: Vector2) -> float:
	return 0.0

func verify_models() -> void:
	for index in [0, 1]:
		var model = SolSpeciesView.create(Catalog.entries[index].species_id, "fire", SolVisualSettings.new())
		root.add_child(model)
		model.sync_locomotion(Vector2.ZERO, 0.0, flat)
		var kind: String = "flight" if index == 0 else "swim"
		var height := 0.8 if index == 0 else -0.18
		model.set_traversal({"kind": kind, "mode": "air" if index == 0 else "swim", "amount": 1.0, "height": height, "clock": 1.0})
		model.animate(1.0, 0.0, 0.0)
		var joint: Node3D = model.joints.WingLeft if index == 0 else model.joints.FrontLeft
		var before: Transform3D = joint.transform
		model.set_traversal({"kind": kind, "mode": "air" if index == 0 else "swim", "amount": 1.0, "height": height, "clock": 1.1})
		model.animate(1.1, 0.0, 0.0)
		check(joint.transform != before, "Procedural wingbeat/limb stroke changes the actual rig")
		check(absf(model.position.y - height) < 0.02 and model.affinity == "fire", "Mode uses supplied waterline/altitude independently of individual affinity")
		var inside_envelope := true
		var envelope := SolTraversalPolicy.box(Vector3.ZERO, Catalog.entries[index].traversal.snapshot()).grow(0.02)
		for mesh_node in model.rig.find_children("*", "MeshInstance3D", true, false):
			var bounds: AABB = (model.global_transform.affine_inverse() * mesh_node.global_transform) * mesh_node.get_aabb()
			if mesh_node.has_meta("articulated_membrane"):
				var vertices: PackedVector3Array = mesh_node.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
				var transform: Transform3D = model.global_transform.affine_inverse() * mesh_node.global_transform
				bounds = AABB(transform * vertices[0], Vector3.ZERO)
				for vertex in vertices:
					bounds = bounds.expand(transform * vertex)
			inside_envelope = inside_envelope and envelope.encloses(bounds)
		check(inside_envelope, "Actual animated appendages fit the declared traversal clearance envelope")
		var paused: Transform3D = joint.transform
		model.animate(1.1, 0.0, 0.0)
		check(joint.transform == paused, "Replaying a frozen movement clock cannot advance free-movement poses")
		if index == 0:
			model.sync_locomotion(Vector2(0.01, 0), 1.0 / 60.0, flat)
			model.animate(1.1, 0.0, 0.0)
			var banked: Transform3D = model.body.transform
			model.sync_locomotion(Vector2(0.01, 0), 0.0, flat)
			model.animate(1.1, 0.0, 0.0)
			check(model.body.transform == banked, "Pause freezes the current flight bank instead of snapping it level")
			model.set_traversal({"kind": "flight", "mode": "air", "amount": 1.0, "height": height, "clock": 1.25})
			model.animate(1.25, 0.0, 0.0)
			var downstroke_fits := true
			for mesh_node in model.rig.find_children("*", "MeshInstance3D", true, false):
				var transform: Transform3D = model.global_transform.affine_inverse() * mesh_node.global_transform
				var vertices: PackedVector3Array = mesh_node.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
				for vertex in vertices:
					downstroke_fits = downstroke_fits and SolTraversalPolicy.box(Vector3.ZERO, Catalog.entries[index].traversal.snapshot()).grow(0.02).has_point(transform * vertex)
			check(downstroke_fits, "Clearance contains a fully banked maximum wing downstroke")
		model.free()

func verify_live(scene: Node3D, crown: Dictionary, reed: Dictionary) -> void:
	var world: Node2D = scene.world
	world.cell = crown.home + Vector2i.LEFT
	world.destination = world.cell
	var before_cell: Vector2i = scene.sightings.current_cell(crown)
	scene.encounters.open_encounter({"id": crown.id, "name": crown.entry.name, "cell": before_cell})
	check(not world.encounter_active and world.persistent_state.roaming_view(crown.id).traversal.settle, "Approaching an airborne Sol requests safe landing instead of freezing an invalid encounter")
	check(scene.sightings.current_cell(crown) == before_cell, "Requesting an encounter cannot teleport the airborne actor")
	var bounds: Dictionary = scene.sol_clearance_bounds(crown.home, 7)
	check(bounds.has("ready") and bounds.has("bounds"), "Live renderer supplies actual published mesh bounds and readiness")
	world.cell = reed.home + Vector2i.LEFT * 2
	world.destination = world.cell
	scene.sightings.rebuild()
	check(world.persistent_state.roaming_view(reed.id).traversal.mode == "ground", "View reconstruction retains the saved swim exit state")
	for member in [crown, reed]:
		world.cell = member.home + Vector2i.LEFT * 3
		for direction in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			if world.terrain.fits(member.home + direction * 3):
				world.cell = member.home + direction * 3
				break
		world.destination = world.cell
		world.rebuild_world()
		for y in range(WorldTerrain.floor_div(member.home.y - 7, 16), WorldTerrain.floor_div(member.home.y + 8, 16) + 1):
			for x in range(WorldTerrain.floor_div(member.home.x - 7, 16), WorldTerrain.floor_div(member.home.x + 8, 16) + 1):
				var coord := Vector2i(x, y)
				if not scene.solid_chunks.has(coord):
					scene.publish_solid(coord, world.terrain.extract_chunk(coord))
		var prepared: Dictionary = scene.sol_clearance_bounds(member.home, 7)
		check(prepared.ready, "Traversal waits for actual scenery publication before using a corridor")
		world.smoke_mode = false
		var modes := {}
		var captured := false
		for tick in range(128):
			world.persistent_state.advance_time(0.75)
			scene.sightings.sync_views(0.75)
			var row: Dictionary = world.persistent_state.roaming_view(member.id)
			modes[row.traversal.mode] = true
			if "--capture" in OS.get_cmdline_user_args() and not captured and row.traversal.mode == ("air" if member.id == crown.id else "swim"):
				world.smoke_mode = true
				scene.target_size = scene.active_view.minimum_distance
				var relative: Vector2 = Vector2(row.cell[0], row.cell[1]) + Vector2(0.5, 0.5) - world.camera.position / 32.0
				scene.camera_focus = Vector3(relative.x, 0, relative.y)
				scene.apply_camera()
				await process_frame
				await process_frame
				await RenderingServer.frame_post_draw
				var filename := "crown_ear_flight.png" if member.id == crown.id else "reedback_swim.png"
				check(root.get_texture().get_image().save_png("res://artifacts/sol_air_water/" + filename) == OK, "Live traversal screenshot saved")
				captured = true
				world.smoke_mode = false
		world.smoke_mode = true
		check(modes.has("air") if member.id == crown.id else modes.has("swim"), "Normal bounded AI uses its admitted flight/swimming capability against real published scenery: " + member.entry.name + " " + str(modes.keys()))
	await process_frame
