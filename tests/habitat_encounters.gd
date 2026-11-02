extends SceneTree
## Real generated habitats, authored behavior, policy continuity and current save/load.
var checks := 0
var failures := 0

func check(value: bool, description: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(description)

func _initialize() -> void:
	create_timer(180).timeout.connect(func() -> void: quit(1))
	run.call_deferred()

func legal_anchor(world: Node2D, target: Vector2i) -> Vector2i:
	for radius in range(33):
		for y in range(-radius, radius + 1):
			for x in range(-radius, radius + 1):
				if maxi(absi(x), absi(y)) != radius:
					continue
				var at := target + Vector2i(x, y)
				if world.terrain.fits(at):
					return at
	check(false, "Review fixture has a legal standing position")
	return world.cell

func run() -> void:
	var scene: Node3D = load("res://scenes/world_3d.tscn").instantiate()
	root.add_child(scene)
	var world: Node2D = scene.world
	world.smoke_mode = true
	var sightings: Node3D = scene.sightings
	var seen := {}
	var reactions := {}
	for seed_value in [2601026, 7, 19]:
		world.new_expedition(seed_value)
		var saved_policy: Array = world.persistent_state.habitat_encounters()
		check(saved_policy.size() == 4, "Normal expedition captures the four habitat pools before admission")
		check(not world.persistent_state.capture_habitat_encounters([]), "An admitted expedition cannot replace its habitat policy")
		for at in [Vector2i(-64,-64),Vector2i(0,-64),Vector2i(64,-64),Vector2i(-64,32),Vector2i(0,32),Vector2i(64,32)]:
			var previous: Vector2i = world.cell
			world.cell = legal_anchor(world, at)
			world.destination = world.cell
			sightings.admit_nearby(previous, world.cell)
			for member in sightings.members:
				if not member.entry.get("habitat_spawn", false):
					continue
				var habitat: int = world.terrain.natural_ground(member.home)
				var selected := HabitatEncounterPool.select_species(saved_policy, habitat, world.terrain.roll(member.home, 1803))
				check(member.entry.species == selected and not selected.is_empty(), "Admitted ambient species matches its actual generated habitat and saved selection")
				var ecology: Dictionary = sightings.ecology_for(member)
				var species: Resource = sightings.settings.catalog_record(selected)
				check(not ecology.profile_id.is_empty() and ecology.temperament == species.ecology.temperament, "Habitat wildlife consumes the species behavior profile")
				reactions[ecology.reaction] = true
				seen[habitat] = true
			var before: Dictionary = world.persistent_state.snapshot()
			sightings.rebuild()
			check(before == world.persistent_state.snapshot(), "Render rebuild does not admit or reroll habitat wildlife")
		var before: Dictionary = world.persistent_state.snapshot()
		var path := "res://artifacts/world_exploration/habitat-test-%d.json" % seed_value
		var payload := ExpeditionSave.snapshot(world.terrain.world_seed, world.cell, world.visited, world.returned, world.terrain.generation_version, world.terrain.climate, before, world.terrain.relief, world.terrain.scenery_parameters)
		if not ExpeditionSave.validate(payload):
			print("SAVE DIAGNOSTIC seed=", seed_value, " state=", ExpeditionState.valid_snapshot(before,seed_value), " player=",world.cell," fits=",world.terrain.fits(world.cell))
			var reconstructed := WorldTerrain.new(world.terrain.world_seed, world.terrain.climate, world.terrain.relief, world.terrain.scenery_parameters)
			for id in before.roaming:
				var row: Dictionary = before.roaming[id]
				var at := Vector2i(row.cell[0],row.cell[1])
				var legal: bool = SolTraversalPolicy.cell_valid(reconstructed,at,row.traversal) if row.has("traversal") else reconstructed.fits(at,int(before.individuals[id].footprint))
				if not legal:
					print("INVALID ROAMING ",id," ",at," original fits=",world.terrain.fits(at)," reconstructed fits=",reconstructed.fits(at))
		world.save_game(path)
		check(not ExpeditionSave.read_save(path).is_empty(), "Fixture saves from legal terrain and passes current-format read validation")
		world.new_expedition(seed_value + 1)
		world.load_game(path)
		if before != world.persistent_state.snapshot():
			FileAccess.open(path + ".before.json", FileAccess.WRITE).store_string(JSON.stringify(before))
			FileAccess.open(path + ".after.json", FileAccess.WRITE).store_string(JSON.stringify(world.persistent_state.snapshot()))
		check(before == world.persistent_state.snapshot(), "Real save/new/load retains pools, individual affinities and roaming state")
		var invalid := before.duplicate(true)
		var first_key: String = invalid.habitat_encounters[0].species_weights.keys()[0]
		invalid.habitat_encounters[0].species_weights[first_key] = -1
		check(not ExpeditionState.valid_snapshot(invalid, seed_value), "Corrupt saved selection weights are rejected")
		invalid = before.duplicate(true)
		invalid.version = ExpeditionState.VERSION - 1
		check(not ExpeditionState.valid_snapshot(invalid, seed_value), "Previous development state version is explicitly rejected")
	var original_policy: Array = world.persistent_state.habitat_encounters()
	var settings: SightingSettings = sightings.settings.duplicate(true)
	settings.habitat_encounters[0].species_weights.clear()
	settings.habitat_encounters[0].species_weights["sol_species_0018"] = 1
	sightings.settings = settings
	sightings.initialize_individuals(world.persistent_state)
	check(original_policy == world.persistent_state.habitat_encounters(), "Live authoring edits cannot alter a loaded expedition's saved pools")
	for habitat in [0,1,2,3]:
		check(seen.has(habitat), "Covered generated habitats include all four pools")
	check(reactions.size() > 1, "Habitat residents expose different existing response behaviors")
	scene.environment.sky = null
	scene.free()
	print("HABITAT ENCOUNTERS: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
