extends SceneTree
## Derived caches and smaller streaming/render batches must preserve world output.
var checks := 0
var failures := 0

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	for seed_value in [17, 2601026]:
		var direct := WorldTerrain.new(seed_value)
		var sliced := WorldTerrain.new(seed_value)
		for area in [Vector2i(3, 2), Vector2i(-3, -2), Vector2i(0, 1)]:
			var was_ready: bool = sliced.geography.admitted_roads.has(area)
			var expected: Array = direct.geography.paths(direct, area).duplicate(true)
			var steps := 0
			while not sliced.geography.prepare_paths(sliced, area): steps += 1
			check(sliced.geography.paths(sliced, area) == expected, "Sliced road admission preserves exact ordered paths at %s" % area)
			check(was_ready or steps > 0, "A cold road district yields before publication")
	var terrain := WorldTerrain.new(17)
	var ground := preload("res://scripts/presentation/streaming_ground.gd").new()
	var roads_before: int = terrain.geography.admitted_roads.size()
	check(not ground.prepare_geography(terrain, Vector2i(40, -40), Time.get_ticks_usec()) and terrain.geography.admitted_roads.size() == roads_before, "Expired temporary-ground budget cannot start cold geography")
	var ground_ready := false
	for step in range(20000):
		if ground.prepare_geography(terrain, Vector2i(40, -40), Time.get_ticks_usec() + 500):
			ground_ready = true
			break
	check(ground_ready, "Temporary-ground preparation resumes and completes with small slices")
	ground.free()
	var catalog := FloraCatalog.new(terrain)
	# Complete neighborhoods remain a hard requirement, even with cached queries.
	for y in range(-1, 2):
		for x in range(-1, 2): catalog.regions[Vector2i(x, y)] = []
	catalog.regions[Vector2i.ZERO] = [{"id": "1:0", "cell": [1, 0], "kind": "tree"}, {"id": "2:0", "cell": [2, 0], "kind": "plant"}]
	var trees: Array = catalog.trees_near(Vector2i.ZERO, 3.0)
	check(trees.size() == 1 and trees[0].id == "1:0", "Kind index excludes plants from tree routing")
	trees[0].cell[0] = 999
	trees.clear()
	check(catalog.trees_near(Vector2i.ZERO, 3.0)[0].cell == [1, 0], "Callers cannot mutate cached neighbor definitions")
	check(catalog.plants_near(Vector2i.ZERO, 1.9).is_empty() and catalog.plants_near(Vector2i.ZERO, 2.0).size() == 1, "Cached queries preserve exact reach boundaries")
	catalog.regions.erase(Vector2i(-1, -1))
	catalog.invalidate_queries()
	check(catalog.trees_near(Vector2i.ZERO, 3.0) == null, "Invalidation cannot return cached results from an incomplete neighborhood")
	catalog.regions[Vector2i(-1, -1)] = []
	catalog.invalidate_queries()
	check(catalog.trees_near(Vector2i.ZERO, 3.0).size() == 1, "Completed neighborhoods can be queried again")
	var ids := catalog.active_ids()
	ids.clear()
	check(catalog.active_ids().size() == 2, "Active IDs remain immutable to callers")
	for x in range(600): catalog.trees_near(Vector2i(x % 10, 0), float(x) / 100.0)
	check(catalog.neighbor_cache.size() <= 512, "Neighbor cache remains bounded")
	var settings: NatureSettings = load("res://resources/nature_biomes.tres").duplicate(true)
	var lod_count := 0
	var art = preload("res://scripts/scenery/nature_art.gd")
	for rock: PackedScene in settings.rocks:
		for piece: Dictionary in art.compact_parts(rock).pieces:
			lod_count += int(piece.mesh.get_meta("generated_lod_count", 0))
	check(lod_count > 0, "Static scenery retains native distant-detail levels")
	var meadow = preload("res://scripts/scenery/meadow_art.gd")
	var whole := preload("res://scripts/presentation/solid_chunk.gd").new()
	var split := preload("res://scripts/presentation/solid_chunk.gd").new()
	for y in range(16):
		for x in range(16):
			var cell := Vector2i(x, y)
			var data := terrain.sample(cell)
			settings.meadow_batch_cells = 16
			meadow.add_cell(whole, terrain, cell, data, settings)
			settings.meadow_batch_cells = 8
			meadow.add_cell(split, terrain, cell, data, settings)
	var expected_entries: Array = []
	for entries: Array in whole.batches.values(): expected_entries.append_array(entries.duplicate(true))
	var split_entries: Array = []
	for entries: Array in split.batches.values(): split_entries.append_array(entries)
	check(not expected_entries.is_empty(), "Grass batching fixture contains actual generated cover")
	check(expected_entries.size() == split_entries.size(), "Smaller grass batches preserve every clump")
	for entry: Dictionary in expected_entries: check(split_entries.has(entry), "Batching preserves grass transform and tint")
	check(whole.living_sources == split.living_sources, "Grass batching preserves ecological endpoints")
	check(split.batches.size() > whole.batches.size() and split.batches.size() <= whole.batches.size() * 4, "Eight-cell grass sections bound draw calls to four per habitat per chunk")
	var dense := preload("res://scripts/presentation/solid_chunk.gd").new()
	settings.meadow_divisions = 16
	for y in range(16):
		for x in range(16):
			var cell := Vector2i(x,y)
			meadow.add_cell(dense,terrain,cell,terrain.sample(cell),settings)
	check(dense.living_sources == split.living_sources,"Changing blade density preserves canonical Vastra endpoints")
	var ignored := preload("res://scripts/presentation/solid_chunk.gd").new()
	ignored.add_nature(preload("res://assets/nature/Grass_Common_Short.gltf"),Vector3.ZERO,0.5,0.0,"detail")
	check(ignored.batches.is_empty() and ignored.pick_objects.is_empty(),"Old fallback clumps are retired from live rendering")
	ignored.free()
	dense.free()
	whole.free()
	split.free()
	var scene: Node3D = load("res://scenes/world_3d.tscn").instantiate()
	root.add_child(scene)
	var currents: Node3D
	for child in scene.get_children():
		if child.get_script() == preload("res://scripts/presentation/vastra_currents.gd"): currents = child
	var start := Vector3(3.5, 1.0, 3.5)
	var finish := Vector3(8.5, 1.0, 8.5)
	var first: PackedVector3Array = currents.transfer_points(start, finish, 71, false)
	var builds: int = currents.transfer_curve_builds
	check(first == currents.transfer_points(start, finish, 71, false) and builds == currents.transfer_curve_builds, "Repeated transfer geometry reuses its stable curve")
	first[1] = Vector3(999, 999, 999)
	check(currents.transfer_points(start, finish, 71, false)[1] != first[1], "Packed curve writes cannot corrupt cached paths")
	var original: float = currents.tuning.current_path_variation
	currents.tuning.current_path_variation = 0.0 if original != 0.0 else 1.0
	currents.transfer_points(start, finish, 71, false)
	check(currents.transfer_curve_builds == builds + 1, "Path tuning selects new curve geometry")
	currents.tuning.current_path_variation = original
	for i in range(300): currents.transfer_points(start, finish, i, false)
	check(currents.transfer_curve_cache.size() <= 256, "Transfer curve cache is bounded")
	currents.on_rebuilt()
	check(currents.transfer_curve_cache.is_empty() and currents.transfer_curve_terrain == null, "World rebuild releases cached curves and their previous terrain owner")
	scene.free()
	print("WORLD OPTIMIZATION: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
