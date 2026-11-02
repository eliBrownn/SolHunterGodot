extends SceneTree
## Read-only generated-biome coverage; simulation uses fresh isolated expeditions.
const Chunk = preload("res://scripts/presentation/solid_chunk.gd")
var terrain: WorldTerrain
var nature: NatureSettings
var policy: Dictionary
var vessel_policy: Dictionary
var ambient_policy: Dictionary
var report := {"cases": [], "scope": "Representative generated areas in every terrestrial biome, plus admitted pond/shore plants; no live save or generation changes."}

func _initialize() -> void:
	create_timer(300).timeout.connect(func() -> void: push_error("Biome Vastra audit timed out"); quit(1))
	run.call_deferred()

func run() -> void:
	var template: Node3D = load("res://scenes/world_3d.tscn").instantiate()
	terrain = WorldTerrain.new(template.expedition_settings.initial_seed, template.climate_settings.parameters(), template.terrain_settings.parameters(), template.scenery_settings.parameters(), template.community_settings.parameters())
	terrain.flora_specialist_percent = template.expedition_settings.flora_specialist_percent
	nature = template.nature_settings
	policy = template.vastra_settings.plant_parameters()
	vessel_policy = template.vessel_settings.parameters()
	ambient_policy = template.vastra_settings.ambient_parameters()
	template.free()
	report.seed = terrain.world_seed
	report.generation = terrain.generation_version
	var centers := {}
	for y in range(-512, 513, 16):
		for x in range(-512, 513, 16):
			var cell := Vector2i(x,y)
			var ground := terrain.natural_ground(cell)
			if centers.has(ground) or ground > 3: continue
			if terrain.flora_kind(cell,terrain.sample(cell)) == "plant": centers[ground] = cell
		if centers.size() == 4: break
	# Existing authored pond: only actual generated living cells count.
	for y in range(8,57):
		for x in range(8,57):
			var cell := Vector2i(x,y)
			var ground := terrain.natural_ground(cell)
			if ground not in [WorldTerrain.Ground.WATER,WorldTerrain.Ground.SAND] or centers.has(ground): continue
			if not terrain.flora_kind(cell,terrain.sample(cell)).is_empty(): centers[ground] = cell
	for ground in range(6):
		if not centers.has(ground):
			report.cases.append({"biome":ground,"status":"No generated living placement found in the sampled area; no synthetic plant added."})
			continue
		print("VASTRA BIOME AUDIT: %d at %s" % [ground,centers[ground]])
		report.cases.append(await audit_area(ground,centers[ground]))
	DirAccess.make_dir_recursive_absolute("res://artifacts/nature_alpha")
	var output := FileAccess.open("res://artifacts/nature_alpha/vastra-biomes.json",FileAccess.WRITE)
	output.store_string(JSON.stringify(report,"\t"))
	output.close()
	print("VASTRA BIOME AUDIT COMPLETE: " + JSON.stringify(report.cases))
	quit()

func audit_area(ground: int, center: Vector2i) -> Dictionary:
	var catalog := FloraCatalog.new(terrain)
	catalog.request(center,int(policy.active_radius),float(policy.tree_reach))
	var state := ExpeditionState.new(terrain.world_seed,ExpeditionState.TERRITORY_SIZE,terrain.flora_specialist_percent)
	state.configure_flora(policy)
	state.configure_ambient(ambient_policy)
	state.configure_ecology(vessel_policy)
	while not catalog.pending.is_empty():
		var admitted := catalog.advance(Time.get_ticks_usec()+20000)
		if not admitted.is_empty(): state.admit_flora(admitted)
		await process_frame
	state.admit_flora(catalog.active_definitions())
	state.set_flora_active(catalog.active_ids())
	var chunk := Chunk.new()
	var coord := terrain.chunk_of(center)
	var cells := terrain.extract_chunk(coord)
	chunk.build(cells,terrain,coord,nature)
	var result := {"biome":ground,"center":[center.x,center.y],"canonical":0,"registered":0,"presentation_anchors":0,"rendered_bodies":0,"missing_endpoints":[],"active":catalog.active_ids().size(),"sent":0,"received":0,"plant_emissions":0,"energy":0.0,"roots":0.0}
	for i in range(cells.size()):
		var cell := coord*16+Vector2i(i%16,i/16)
		if terrain.natural_ground(cell) != ground or terrain.flora_kind(cell,cells[i]).is_empty(): continue
		result.canonical += 1
		if not state.flora_reading(cell).is_empty(): result.registered += 1
		if chunk.plant_instances.has(cell) and not chunk.plant_instances[cell].is_empty(): result.rendered_bodies += 1
		if chunk.living_sources.has(cell): result.presentation_anchors += 1
		elif result.missing_endpoints.size()<16: result.missing_endpoints.append([cell.x,cell.y])
	var seen := {}
	for tick in range(240):
		state.advance_time(ExpeditionContract.ACTIVITY_INTERVAL)
		state.advance_flora(catalog.trees_near,func(at: Vector2i) -> Dictionary: return state.environment_view(at,{"concentration":terrain.concentration_at(at),"overload":0}),catalog.plants_near)
		for flight in state.flora_transfers()+state.ambient_transfers():
			if seen.has(flight.id): continue
			seen[flight.id] = true
			if terrain.natural_ground(Vector2i(flight.source_node.cell[0],flight.source_node.cell[1])) == ground:
				result.sent += 1
				if flight.source_node.kind == "plant": result.plant_emissions += 1
			if terrain.natural_ground(Vector2i(flight.target_node.cell[0],flight.target_node.cell[1])) == ground: result.received += 1
		if tick%16 == 0: await process_frame
	for row in state.flora_view().nodes.values():
		if terrain.natural_ground(Vector2i(row.cell[0],row.cell[1])) == ground:
			result.energy += row.energy
			result.roots += row.roots
	chunk.free()
	result.ambient_exported = state.flora_view().exported
	result.ambient_credited = state.ambient_view().credited
	result.valid_snapshot = ExpeditionState.valid_snapshot(state.snapshot(),terrain.world_seed)
	return result
