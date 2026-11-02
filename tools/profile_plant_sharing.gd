extends SceneTree
var report := {}
func _initialize() -> void: run.call_deferred()
func run() -> void:
	var scene = load("res://scenes/world_3d.tscn").instantiate()
	root.add_child(scene)
	scene.world.smoke_mode = true
	scene.process_mode = Node.PROCESS_MODE_DISABLED
	var world = scene.world
	# Finish canonical flora admission only; no terrain render journey.
	for iteration in range(200): world.prepare_flora(Time.get_ticks_usec()+5000)
	var state: ExpeditionState = world.persistent_state
	var focuses: Array[Vector2i] = []
	for y in range(-24,25,8):
		for x in range(-24,25,8): focuses.append(world.cell+Vector2i(x,y))
	var original: Dictionary = state.snapshot()
	var matched := true
	for at in focuses:
		for limit in [0,1,24,64]: matched = matched and original_query(state,at,limit) == state.ecology_plants(at,limit)
	var rounds: Array = []
	for run in range(4):
		var row := {}
		for optimized in ([false,true] if run % 2 == 0 else [true,false]):
			var start := Time.get_ticks_usec()
			for repeat in range(4):
				for at in focuses:
					if optimized: state.ecology_plants(at,64)
					else: original_query(state,at,64)
			row["regional_ms" if optimized else "original_ms"] = (Time.get_ticks_usec()-start)/1000.0
		rounds.append(row)
	# Same-cell reads can share an immutable result within one snapshot.
	var cells: Array[Vector2i] = []
	for id in state._flora_active: cells.append(VesselEcology.cell(state._flora.nodes[id]))
	var env_rounds: Array = []
	for run in range(4):
		var row := {}
		for optimized in ([false,true] if run % 2 == 0 else [true,false]):
			var memo := {}
			var start := Time.get_ticks_usec()
			var checksum := 0.0
			for repeat in range(3):
				for at in cells:
					var reading: Dictionary
					if optimized:
						if not memo.has(at): memo[at] = world.flora_environment(at)
						reading = memo[at]
					else: reading = world.flora_environment(at)
					checksum += float(reading.concentration)
			row["shared_ms" if optimized else "original_ms"] = (Time.get_ticks_usec()-start)/1000.0
			row["shared_sum" if optimized else "original_sum"] = checksum
		env_rounds.append(row)
	var tick_times: Array = []
	var refill_times: Array = []
	for frame in range(120):
		var start := Time.get_ticks_usec()
		state.advance_time(1.0/60.0)
		tick_times.append((Time.get_ticks_usec()-start)/1000.0)
		start = Time.get_ticks_usec()
		state.advance_flora_refill(world.flora_environment)
		refill_times.append((Time.get_ticks_usec()-start)/1000.0)
	report = {"active_plants":cells.size(),"regions":state._ecology_regions.size(),"query_matches":matched,"query_comparisons":focuses.size()*4,"query_rounds":rounds,"environment_rounds":env_rounds,"tick_call_ms":tick_times,"refill_call_ms":refill_times,"scope":"Headless CPU fixture, existing canonical admitted population; environment reuse deliberately requests each cell three times in one unchanged snapshot; not a measured production cache hit rate or FPS gain"}
	var file := FileAccess.open("res://artifacts/plant-sharing/results.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t")); file.close()
	print("PLANT SHARING active=",cells.size()," query_matches=",matched," query rounds=",rounds," environment=",env_rounds)
	scene.free()
	quit(0 if matched else 1)

func regional(state: ExpeditionState, focus: Vector2i, limit: int = 24) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if state._ecology.policy == null or not state._ecology.policy.enabled: return result
	var candidates: Array[String] = []
	var nearby: Array[String] = []
	var low := FloraCatalog.region(focus - Vector2i(12,12))
	var high := FloraCatalog.region(focus + Vector2i(12,12))
	for y in range(low.y, high.y + 1):
		for x in range(low.x, high.x + 1):
			nearby.append_array(state._ecology_regions.get(Vector2i(x,y), []))
	for id in nearby:
		var row: Dictionary = state._flora.nodes[id]
		if VesselEcology.cell(row).distance_squared_to(focus) > 144 or FloraTraits.category(state._seed, row,state._flora_specialist_percent).is_empty(): continue
		candidates.append(id)
	candidates.sort_custom(func(a: String, b: String) -> bool:
		var da := VesselEcology.cell(state._flora.nodes[a]).distance_squared_to(focus)
		var db := VesselEcology.cell(state._flora.nodes[b]).distance_squared_to(focus)
		return a < b if da == db else da < db)
	for index in range(mini(clampi(limit, 0, 64), candidates.size())):
		var row: Dictionary = state._flora.nodes[candidates[index]]
		result.append({"id": row.id, "cell": row.cell.duplicate(), "traits": FloraTraits.describe(state._seed, row,state._flora_specialist_percent), "activity": str(state._ecology_activities.get(row.id, "idle"))})
	return result

func original_query(state: ExpeditionState, focus: Vector2i, limit: int = 24) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if state._ecology.policy == null or not state._ecology.policy.enabled: return result
	var candidates: Array[String] = []
	for id in state._flora_active:
		var row: Dictionary = state._flora.nodes[id]
		if VesselEcology.cell(row).distance_squared_to(focus) > 144 or FloraTraits.category(state._seed, row,state._flora_specialist_percent).is_empty(): continue
		candidates.append(id)
	candidates.sort_custom(func(a: String, b: String) -> bool:
		var da := VesselEcology.cell(state._flora.nodes[a]).distance_squared_to(focus)
		var db := VesselEcology.cell(state._flora.nodes[b]).distance_squared_to(focus)
		return a < b if da == db else da < db)
	for index in range(mini(clampi(limit, 0, 64), candidates.size())):
		var row: Dictionary = state._flora.nodes[candidates[index]]
		result.append({"id": row.id, "cell": row.cell.duplicate(), "traits": FloraTraits.describe(state._seed, row,state._flora_specialist_percent), "activity": str(state._ecology_activities.get(row.id, "idle"))})
	return result
