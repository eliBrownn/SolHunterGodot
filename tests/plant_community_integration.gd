extends SceneTree
## Production layout, canonical registration and captured-generation admission.
var checks := 0
var failures := 0

func check(ok: bool, description: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(description)

func _initialize() -> void:
	create_timer(180).timeout.connect(func() -> void: quit(1))
	run.call_deferred()

func run() -> void:
	var parameters := WorldTerrain.default_community()
	parameters.coverage = 0.9
	parameters.spacing = 1.0
	var terrain := WorldTerrain.new(17, {}, {}, {}, parameters)
	var trees := 0
	var cells: Array[Vector2i] = []
	for y in range(24, 40):
		for x in range(24, 56): cells.append(Vector2i(x,y))
	var results := {}
	var state := ExpeditionState.new(17)
	state.configure_flora(VastraSettings.new().plant_parameters())
	terrain.flora_specialist_percent = state.flora_specialist_percent()
	for cell in cells:
		var data := terrain.sample(cell)
		results[cell] = data
		var kind := terrain.flora_kind(cell,data)
		if not kind.is_empty():
			state.admit_flora([{"id":FloraCatalog.id_for(cell),"cell":[cell.x,cell.y],"kind":kind}])
		if data.obstacle == 1:
			trees += 1
			check(kind == "tree" and terrain.route_axes(cell,2) == 0 and terrain.slope_fits(cell), "Community trees keep canonical identity and walking clearance")
		var moisture := terrain.community_drainage(cell)
		check(is_finite(moisture) and moisture >= 0.0 and moisture <= 1.0, "Drainage context stays bounded")
	check(trees > 0, "Production fixture includes community trees")
	terrain.community_layout.clear_cache()
	terrain._community_sites.clear()
	terrain._community_trees.clear()
	cells.reverse()
	for cell in cells:
		check(terrain.sample(cell) == results[cell], "Cache reconstruction and reversed queries preserve exact cells")
	var data := ExpeditionSave.snapshot(17,Vector2i.ZERO,false,false,terrain.generation_version,terrain.climate,state.snapshot(),terrain.relief,terrain.scenery_parameters,parameters)
	var restored := ExpeditionSave.prepare(JSON.parse_string(JSON.stringify(data)),terrain)
	check(not restored.is_empty() and restored.terrain == terrain and restored.state.snapshot() == state.snapshot(), "Populated community saves independently restore state and reuse matching generation")
	var other := WorldTerrain.new(17)
	check(not ExpeditionSave.matching_terrain(other,data,terrain.flora_specialist_percent), "Different community settings cannot reuse a terrain hint")
	var rebuilt := ExpeditionSave.prepare(data,other)
	check(not rebuilt.is_empty() and rebuilt.terrain != other and rebuilt.terrain.community_parameters == parameters, "Load reconstructs captured community settings")
	for invalid in [{}, {"coverage":0.5}, null]:
		var broken := data.duplicate(true)
		broken.community = invalid
		check(ExpeditionSave.prepare(broken,terrain).is_empty(), "Missing or malformed community settings are rejected")
	parameters.coverage = 0.0
	var empty := WorldTerrain.new(17, {}, {}, {}, parameters)
	for cell in cells:
		check(not empty.community_tree(cell), "Zero coverage removes community trees")
	check(terrain.essential_route_clear() and empty.essential_route_clear(), "Community tuning preserves the essential route")
	print("PLANT COMMUNITY INTEGRATION: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
