extends SceneTree
## Generation-cache reuse never substitutes for admission of saved state.
var checks := 0
var failures := 0
class DerivedTerrain extends WorldTerrain:
	pass

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)

func _initialize() -> void:
	create_timer(120).timeout.connect(func() -> void: quit(1))
	run.call_deferred()

func run() -> void:
	var terrain := WorldTerrain.new(17)
	var state := ExpeditionState.new(17)
	state.configure_flora(VastraSettings.new().plant_parameters())
	var specialist_percent := state.flora_specialist_percent()
	terrain.flora_specialist_percent = specialist_percent
	for y in range(8,32):
		for x in range(8,48):
			var cell := Vector2i(x,y)
			var kind := terrain.flora_kind(cell,terrain.sample(cell))
			if not kind.is_empty():
				state.admit_flora([{"id":FloraCatalog.id_for(cell),"cell":[cell.x,cell.y],"kind":kind}])
				break
		if not state.snapshot().flora.nodes.is_empty(): break
	var data := ExpeditionSave.snapshot(17,Vector2i.ZERO,false,false,terrain.generation_version,terrain.climate,state.snapshot(),terrain.relief,terrain.scenery_parameters)
	check(not data.world_state.flora.nodes.is_empty(), "Reuse fixture includes a real generated plant")
	if data.world_state.flora.nodes.is_empty():
		quit(1)
		return
	var candidate := ExpeditionSave.prepare(data,terrain)
	check(not candidate.is_empty() and candidate.terrain == terrain, "Matching generation reuses only the existing terrain owner")
	check(candidate.state != state and candidate.state.snapshot() == state.snapshot(), "Saved state is independently restored and validated")
	var fresh := ExpeditionSave.prepare(data)
	check(not fresh.is_empty() and fresh.terrain != terrain and fresh.state.snapshot() == candidate.state.snapshot(), "Unhinted reconstruction and reused generation admit identical state")
	check(fresh.terrain.extract_chunk(Vector2i.ZERO) == candidate.terrain.extract_chunk(Vector2i.ZERO), "Reused caches preserve exact generated cells")
	check(ExpeditionSave.validate(data,terrain), "Saving with a matching generation still validates the populated state")
	check(ExpeditionSave.matching_terrain(terrain,JSON.parse_string(JSON.stringify(data)),specialist_percent), "JSON numeric representations preserve exact matching generation")
	check(not ExpeditionSave._same_generation_value([true],[1.0]) and not ExpeditionSave._same_generation_value([[1,2]],[[1.0,3.0]]), "Parameter matching preserves boolean types and nested coordinate differences")
	var other := WorldTerrain.new(19)
	var fallback := ExpeditionSave.prepare(data,other)
	check(not fallback.is_empty() and fallback.terrain != other and fallback.terrain.world_seed == 17, "A different seed reconstructs independent saved generation")
	check(not ExpeditionSave.matching_terrain(DerivedTerrain.new(17),data,specialist_percent), "Subclass overrides cannot act as a validation terrain hint")
	for field in ["climate","relief","scenery","community"]:
		var changed := data.duplicate(true)
		changed[field] = {}
		check(not ExpeditionSave.matching_terrain(terrain,changed,specialist_percent), "Different captured " + field + " cannot reuse generation")
	check(not ExpeditionSave.matching_terrain(terrain,data,(specialist_percent+1)%26), "Different specialist generation settings cannot reuse terrain")
	terrain.generation_version -= 1
	check(not ExpeditionSave.matching_terrain(terrain,data,specialist_percent), "Different generator versions cannot reuse terrain")
	terrain.generation_version += 1
	var bad := data.duplicate(true)
	bad.world_state.version = -1
	check(ExpeditionSave.prepare(bad,terrain).is_empty(), "Matching terrain cannot admit an invalid state schema")
	bad = data.duplicate(true)
	var plant_id: String = bad.world_state.flora.nodes.keys()[0]
	bad.world_state.flora.nodes[plant_id].kind = "water"
	check(ExpeditionSave.prepare(bad,terrain).is_empty(), "Matching terrain cannot admit corrupt flora")
	bad = data.duplicate(true)
	bad.world_state.roaming.missing = {"cell":[0,0]}
	check(ExpeditionSave.prepare(bad,terrain).is_empty(), "Matching terrain cannot admit invalid roaming records")
	bad = data.duplicate(true)
	bad.player = [0.5,0]
	check(ExpeditionSave.prepare(bad,terrain).is_empty(), "Matching terrain cannot admit malformed player coordinates")
	var water := Vector2i.ZERO
	for y in range(24,64):
		for x in range(24,64):
			if terrain.natural_ground(Vector2i(x,y)) == WorldTerrain.Ground.WATER:
				water = Vector2i(x,y)
				break
		if water != Vector2i.ZERO: break
	check(water != Vector2i.ZERO, "Admission fixture finds actual generated water")
	bad = data.duplicate(true)
	bad.player = [water.x,water.y]
	check(ExpeditionSave.prepare(bad,terrain).is_empty(), "Reused terrain still rejects an unwalkable saved player position")
	var scene: Node3D = load("res://scenes/world_3d.tscn").instantiate()
	root.add_child(scene)
	var world: Node2D = scene.world
	world.smoke_mode = true
	world.prepare_flora(Time.get_ticks_usec()+100000)
	var generation: WorldTerrain = world.terrain
	var saved: Dictionary = world.persistent_state.snapshot()
	var old_state: ExpeditionState = world.persistent_state
	var path := "res://artifacts/bottleneck-fixes/reuse-save.json"
	DirAccess.make_dir_recursive_absolute("res://artifacts/bottleneck-fixes")
	world.save_game(path)
	world.persistent_state.set_environment(world.cell,{"overload":23})
	world.load_game(path)
	check(world.terrain == generation and world.persistent_state != old_state, "Live same-world load retains generation but replaces the state owner")
	check(world.persistent_state.snapshot() == saved, "Live same-world load restores the complete saved state")
	check(scene.solid_chunks.has(generation.chunk_of(world.cell)), "Reused generation republishes player geometry")
	world.persistent_state.set_environment(world.cell,{"overload":31})
	var live: Dictionary = world.persistent_state.snapshot()
	var invalid := FileAccess.open(path,FileAccess.WRITE)
	invalid.store_string('{"broken":true}')
	invalid.close()
	world.load_game(path)
	check(world.terrain == generation and world.persistent_state.snapshot() == live, "Invalid input preserves the current live expedition even with a terrain hint")
	scene.environment.sky = null
	scene.free()
	print("SAVE TERRAIN REUSE: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
