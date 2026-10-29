extends SceneTree
const Catalog = preload("res://resources/sol_species/catalog.tres")
var checks := 0
var failures := 0

func check(value: bool, description: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(description)

func _initialize() -> void:
	run.call_deferred()

func flat(_at: Vector2) -> float:
	return 0.0

func slope(at: Vector2) -> float:
	return at.x * 0.1 + at.y * 0.05

func pose(model: Node3D) -> Array:
	var result: Array = []
	for chain in model.ground_motion.chains:
		result.append([chain.hip.transform, chain.knee.transform, chain.foot.transform, chain.progress])
	return result

func run() -> void:
	# This suite's wrist/plate/root fixtures describe the original three pilot rigs.
	# New body plans and scales have their own sol_anatomy_batch movement coverage.
	for species_id in ["sol_species_0001", "sol_species_0002", "sol_species_0003"]:
		var entry: SolSpeciesRecord = Catalog.find(species_id)
		for sample in [Vector2(30, 0.3), Vector2(60, 0.3), Vector2(144, 0.3), Vector2(30, 1.0 / 0.75), Vector2(60, 1.0 / 0.75), Vector2(144, 1.0 / 0.75)]:
			var fps := int(sample.x)
			var travel_speed := float(sample.y)
			var model: Variant = SolSpeciesView.create(entry.species_id, "water", SolVisualSettings.new())
			root.add_child(model)
			model.set_stance("alert")
			model.idle_strength = 0.0
			model.sync_locomotion(Vector2.ZERO, 0.0, flat)
			model.animate(0.0, 0.0, 0.0)
			check(model.ground_motion.chains.size() == 4, "All pilot supports are registered")
			var finite := true
			var on_ground := true
			for chain in model.ground_motion.chains:
				finite = finite and chain.foot.global_position.is_finite()
				on_ground = on_ground and absf(chain.foot.global_position.y - 0.008) < 0.025
			check(finite and on_ground, "Resting contacts solve to actual flat ground for " + entry.display_name)
			var planted := pose(model)
			for frame in range(fps):
				model.sync_locomotion(Vector2.ZERO, 1.0 / fps, flat)
				model.animate(float(frame) / fps, 0.0, 0.0)
			check(model.ground_motion.steps_started == 0 and pose(model) == planted, "Stationary model neither steps nor accumulates transform drift")
			var at := Vector2.ZERO
			var swing_seen := false
			var max_plant_error := 0.0
			for frame in range(fps * 3):
				at += Vector2(0, travel_speed / fps)
				model.position.z = at.y
				model.sync_locomotion(at, 1.0 / fps, flat)
				model.animate(1.0 + float(frame) / fps, 0.0, 0.0)
				for chain in model.ground_motion.chains:
					swing_seen = swing_seen or (chain.progress < 1.0 and chain.display.y > 0.015)
					finite = finite and chain.foot.global_position.is_finite() and chain.hip.global_basis.is_finite()
					if chain.progress == 1.0:
						max_plant_error = maxf(max_plant_error, chain.error)
			check(model.ground_motion.steps_started > 4 and swing_seen and finite, "Committed displacement drives repeated finite strides and foot lift at %d FPS" % fps)
			check(max_plant_error < 0.025, "Planted supports stay within 2.5 cm of their world anchor: %s, %d FPS, %.2f m/s, error %.4f" % [entry.display_name, fps, travel_speed, max_plant_error])
			var before_pause := pose(model)
			model.sync_locomotion(at, 0.0, flat)
			model.animate(4.0 - 1.0 / fps, 0.0, 0.0)
			check(pose(model) == before_pause, "Zero delta freezes support phase and joint pose")
			for frame in range(fps):
				model.sync_locomotion(at, 1.0 / fps, flat)
				model.animate(5.0, 0.0, 0.0)
			var steps_after_stop: int = model.ground_motion.steps_started
			check(model.ground_motion.chains.all(func(chain: Dictionary) -> bool: return chain.progress == 1.0), "A stopped actor finishes its swing and plants")
			var anchors: Array = model.ground_motion.chains.map(func(chain: Dictionary) -> Vector3: return chain.planted)
			for frame in range(fps):
				model.position.x += 0.1 # Simulate camera rebasing while absolute creature position stays put.
				model.sync_locomotion(at, 1.0 / fps, flat)
				model.animate(5.0, 0.0, 0.0)
			check(model.ground_motion.steps_started == steps_after_stop and model.ground_motion.chains.map(func(chain: Dictionary) -> Vector3: return chain.planted) == anchors, "Camera rebasing cannot generate footsteps or move absolute plant anchors")
			var heading_before: float = model.ground_motion.heading
			at.x += 0.01
			model.sync_locomotion(at, 1.0 / fps, flat)
			model.animate(5.1, 0.0, 0.0)
			check(model.ground_motion.heading > heading_before and model.ground_motion.heading < PI * 0.5, "Visual heading turns smoothly toward committed travel")
			model.reset_locomotion()
			model.position.x = 0
			model.position.z = 0
			model.sync_locomotion(Vector2(100, 100), 0.0, slope)
			model.animate(6.0, 0.0, 0.0)
			check(is_equal_approx(model.position.y, slope(Vector2(100, 100))), "Body support samples the actual terrain surface")
			var terrain_contacts := true
			for chain in model.ground_motion.chains:
				terrain_contacts = terrain_contacts and is_equal_approx(chain.planted.y, slope(Vector2(chain.planted.x, chain.planted.z)) + 0.008) and chain.error < 0.025
			check(terrain_contacts, "Each contact samples its own terrain height")
			model.sync_locomotion(Vector2(500, 500), 0.0, slope)
			model.animate(7.0, 0.0, 0.0)
			check(model.ground_motion.speed == 0.0 and model.ground_motion.chains.all(func(chain: Dictionary) -> bool: return chain.progress == 1.0), "Relocation/reload resets support without inventing a travel route")
			model.free()
	await verify_live_world()
	print("SOL PROCEDURAL GROUND: %d checks, %d failures." % [checks, failures])
	quit(0 if failures == 0 else 1)

func verify_live_world() -> void:
	var scene := preload("res://scenes/sol_species_pilot.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	var world: Node2D = scene.world
	world.smoke_mode = true
	world.new_expedition(17)
	var member: Dictionary = scene.sightings.members.filter(func(row: Dictionary) -> bool: return row.entry.species == "sol_species_0001")[0]
	world.cell = member.home + Vector2i.LEFT
	world.destination = world.cell
	scene.sightings.sync_views()
	var before: Dictionary = world.persistent_state.snapshot()
	var model: Node3D = member.sprite
	check(model.ground_motion.initialized, "Live pilot sighting connects the support driver")
	var track: SolMotionTrack = member.motion
	track.append(track.target + Vector2i.RIGHT, 1.0)
	world.paused = true
	var frozen := pose(model)
	scene.sightings.sync_views(0.2)
	check(pose(model) == frozen and track.position == Vector2(member.home), "Pause freezes actual live route and gait together")
	world.paused = false
	scene.sightings.sync_views(0.2)
	check(model.ground_motion.speed > 0 and track.position != Vector2(member.home), "Actual replay movement drives the creature gait")
	world.encounter_active = true
	var encounter_pose := pose(model)
	scene.sightings.sync_views(0.2)
	check(pose(model) == encounter_pose, "Encounter entry freezes locomotion presentation")
	world.encounter_active = false
	check(world.persistent_state.snapshot() == before, "Procedural presentation never writes persistent state or chooses a route")
	world.cell = member.home + Vector2i(100, 0)
	scene.sightings.sync_views()
	check(not model.ground_motion.initialized, "Culling clears the procedural support history")
	scene.free()
