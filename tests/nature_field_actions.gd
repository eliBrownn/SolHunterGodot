extends SceneTree
var checks := 0
var failures := 0

func check(value: bool, caption: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(caption)

func _initialize() -> void:
	create_timer(120).timeout.connect(func() -> void: quit(1))
	run.call_deferred()

func position_player_nearby(scene: Node3D, species: SolSpeciesRecord, listening: bool) -> bool:
	var world: Node2D = scene.world
	# Select a legal initial player location against published body clearance.
	# Dense new plant palettes can invalidate a previously hardcoded roadside cell.
	for frame in range(180):
		await process_frame
		for x in range(0,13):
			var at := Vector2i(x,world.terrain.trail_y(x))
			if not world.terrain.fits(at): continue
			if listening:
				var nearby := false
				for member: Dictionary in scene.sightings.members:
					if member.sprite.visible and scene.sightings.current_cell(member).distance_to(at) <= 5: nearby = true
				if not nearby: continue
			else:
				var plant := false
				for dy in range(-2,3):
					for dx in range(-2,3):
						if absi(dx)+absi(dy)>2: continue
						var candidate := at+Vector2i(dx,dy)
						if not world.terrain.flora_kind(candidate,world.terrain.sample(candidate)).is_empty(): plant = true
				if not plant: continue
			var prepared: Dictionary = scene.sol_clearance_bounds(at,2)
			if not prepared.ready: continue
			var legal := false
			for offset: Vector2i in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
				var to := at+offset
				if not world.can_step(at,to) or scene.companion.occupied_cells().has(to): continue
				var a := Vector2(at)+Vector2.ONE*0.5
				var b := Vector2(to)+Vector2.ONE*0.5
				if SolTraversalPolicy.corridor(Vector3(a.x,scene.ground_height(a)+0.02,a.y),Vector3(b.x,scene.ground_height(b)+0.02,b.y),species.traversal.snapshot(),prepared.bounds): legal = true
			if not legal: continue
			world.cell = at
			world.destination = at
			world.moving = false
			world.rebuild_world()
			return true
	return false

func run() -> void:
	var scene: Node3D = load("res://scenes/world_3d.tscn").instantiate()
	root.add_child(scene)
	var world: Node2D = scene.world
	world.smoke_mode = true
	var state: ExpeditionState = world.persistent_state
	var species: SolSpeciesRecord = scene.battle_settings.species_catalog.find("sol_species_0001")
	# Real follower admission waits for streamed collision geometry, not just
	# synchronous calls to _process before any chunk can publish.
	world.cell = Vector2i(4, 0)
	world.destination = world.cell
	world.moving = false
	world.rebuild_world()
	# Prefer published clearance; the actual action assertions below require the
	# follower's authoritative admission, including later streamed geometry.
	await position_player_nearby(scene,species,true)
	check(state.choose_starter(species.battle_profile("air"), 0), "Existing Crown-Ear admits through the owned identity owner")
	var at: Vector2i = world.cell
	for frame in range(120):
		await process_frame
		scene.companion._process(0.2)
		for member: Dictionary in scene.sightings.members:
			var candidate: Vector2i = scene.sightings.current_cell(member)
			if scene.nature.action_for(candidate) == "Listen with companion":
				at = candidate
				break
		if at != world.cell: break
	check(scene.nature.action_for(at) == "Listen with companion", "Nearby visible wildlife supports Crown-Ear's authored listening action")
	var identity: String = state.active_sol_view().id
	check(scene.nature.cooperate(at), "Listening starts with the real selected individual")
	world.paused = true
	scene.nature._process(5)
	check(state.finding_entries().is_empty(), "Pause cannot finish or award a field action")
	world.paused = false
	scene.nature._process(2)
	check(state.finding_entries().any(func(row: Dictionary) -> bool: return row.key == "companion_listen") and state.active_sol_view().id == identity, "Listening retains local evidence without replacing the companion")
	var before := state.snapshot()
	check(not scene.nature.cooperate(at + Vector2i(100, 0)) and before == state.snapshot(), "Distant actions fail without side effects")
	world.new_expedition(2601026)
	state = world.persistent_state
	species = scene.battle_settings.species_catalog.find("sol_species_0003")
	world.cell = Vector2i(4, 0)
	world.destination = world.cell
	world.rebuild_world()
	await position_player_nearby(scene,species,false)
	check(state.choose_starter(species.battle_profile("fire"), 0), "Existing Bellroot admits with independently assigned affinity")
	var target: Vector2i = world.cell
	for frame in range(90):
		await process_frame
		scene.companion._process(0.2)
		if scene.companion.placed and not scene.companion.following: break
	var found := false
	for y in range(-3, 4):
		for x in range(-3, 4):
			var candidate: Vector2i = world.cell + Vector2i(x, y)
			if absi(x) + absi(y) > 3: continue
			var kind: String = world.terrain.flora_kind(candidate, world.terrain.sample(candidate))
			if kind.is_empty(): continue
			state.admit_flora([{"id": AffinityImprint.key(candidate), "cell": [candidate.x, candidate.y], "kind": kind}])
			if scene.nature.action_for(candidate) == "Inspect with companion":
				target = candidate
				found = true
	check(found, "Inspection uses an actual canonical plant reachable from the admitted follower")
	check(scene.nature.action_for(target) == "Inspect with companion", "Bellroot's field action validates the actual plant and follower")
	check(scene.nature.cooperate(target), "Plant inspection starts")
	var inspection_origin: Vector2i = world.cell
	world.moving = true
	world.cell += Vector2i.LEFT
	scene.nature._process(2)
	check(state.finding_entries().is_empty(), "Leaving interrupts inspection without awarding knowledge")
	world.cell = inspection_origin
	world.moving = false
	world.destination = world.cell
	for frame in range(15): scene.companion._process(0.2)
	check(scene.nature.cooperate(target), "Interrupted action can be attempted again at a legal location")
	var reserve: Dictionary = state.flora_reading(target)
	scene.nature._process(2)
	check(state.finding_entries().any(func(row: Dictionary) -> bool: return row.key == "companion_inspect") and state.flora_reading(target) == reserve, "Inspection reports real reserve without creating or spending energy")
	var restored := ExpeditionState.restore(JSON.parse_string(JSON.stringify(state.snapshot())), world.terrain.world_seed)
	check(restored != null and restored.finding_entries() == state.finding_entries(), "Cooperative findings survive save representation and restore")
	scene.queue_free()
	await process_frame
	print("NATURE FIELD ACTIONS: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
