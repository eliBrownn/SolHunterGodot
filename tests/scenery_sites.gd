extends SceneTree
## Site admission and independent reconstruction; actual terrain remains authoritative.
const Template = preload("res://scripts/scenery/scenery_site_template.gd")
var checks := 0
var failures := 0

func check(value: bool, description: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(description)

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var admitted := 0
	var boundary := false
	for seed_value in [0, 1, 2, 17, 71, 2601026, 88881, 999999]:
		var terrain := WorldTerrain.new(seed_value)
		var definition := Template.new()
		var result := definition.plan(terrain)
		print("SITE %d: admitted=%s attempts=%d" % [seed_value, result.admitted, result.attempts])
		check(result.attempts <= definition.search_candidates, "Search is bounded")
		if not result.admitted:
			check(result.reason == "no_suitable_site" and not result.has("elements"), "Incomplete candidates are never published")
			continue
		admitted += 1
		check(result.elements.size() <= definition.element_budget, "Siblings share the site's module budget")
		var inputs: Dictionary = result.definition
		if seed_value == int(inputs.clearing_seed):
			for row in inputs.clearings:
				check(not result.reservation.intersects(Rect2i(int(row[0]), int(row[1]), int(row[2]), int(row[3]))), "Site cannot overlap the existing observation/encounter clearing")
		var no_detail := definition.duplicate()
		no_detail.roof_trim = false
		var plain: Dictionary = no_detail.plan(terrain)
		for key in ["id", "parent_id", "footprint", "approach", "blockers", "reservation"]:
			check(result[key] == plain[key], "Decoration preserves parent layout and identity")
		check(result.elements.slice(0, 5) == plain.elements, "Decoration preserves all required modules")
		var tight := definition.duplicate()
		tight.element_budget = 5
		check(tight.plan(terrain).elements.size() == 5, "Optional detail yields to the inherited budget")
		var recreated := definition.plan(WorldTerrain.new(seed_value, terrain.climate, terrain.relief))
		check(result == recreated, "Fresh terrain reconstructs the entire admitted result")
		var footprint: Rect2i = result.footprint
		boundary = boundary or terrain.chunk_of(footprint.position) != terrain.chunk_of(footprint.end - Vector2i.ONE)
		for element in result.elements:
			check(Rect2(result.reservation).encloses(Rect2(Vector2(element.bounds.position.x, element.bounds.position.z), Vector2(element.bounds.size.x, element.bounds.size.z))), "Every module stays in the parent reservation")
		for i in range(result.blockers.size()):
			var cell: Vector2i = result.blockers[i]
			var post: Dictionary = result.elements[i]
			check(is_equal_approx(post.bounds.position.y, terrain.surface_height(Vector2(cell) + Vector2(0.5, 0.5))), "Each support sits on the canonical terrain")
		for y in range(result.approach.position.y, result.approach.end.y):
			for x in range(result.approach.position.x, result.approach.end.x):
				check(terrain.fits(Vector2i(x, y)), "Reserved woodland approach stays traversable")
		for cell in result.blockers:
			check(not terrain.is_walkable(cell) and terrain.sample(cell).obstacle == 3, "Canonical traversal consumes admitted supports")
		var chunks: Array[Vector2i] = []
		for cell in result.blockers:
			if not terrain.chunk_of(cell) in chunks:
				chunks.append(terrain.chunk_of(cell))
		var first: Dictionary = {}
		for coord in chunks:
			first[coord] = terrain.extract_chunk(coord)
		chunks.reverse()
		for coord in chunks:
			check(first[coord] == terrain.extract_chunk(coord), "Chunk visitation order does not reapprove or relocate the site")
		var publisher := preload("res://scripts/presentation/solid_chunk.gd").new()
		publisher.add_site(result)
		check(publisher.pick_objects.size() == result.elements.size(), "Every admitted module has one pick record")
		for i in range(result.elements.size()):
			check(publisher.pick_objects[i].transform == result.elements[i].transform and publisher.pick_objects[i].site_id == result.id, "Picking and rendering consume the same resolved transform and stable site")
		publisher.free()
		var saved := ExpeditionSave.snapshot(seed_value, Vector2i.ZERO, false, false, terrain.generation_version, terrain.climate, {}, terrain.relief, terrain.scenery_parameters)
		var decoded: Dictionary = JSON.parse_string(JSON.stringify(saved))
		check(ExpeditionSave.validate(decoded), "Admitted scenery survives current-format JSON admission")
		var loaded := WorldTerrain.new(int(decoded.seed), decoded.climate, decoded.relief, decoded.scenery)
		check(loaded.scenery_site == terrain.scenery_site, "Load reconstructs the complete site from captured inputs")
		decoded.scenery.search_candidates = -1
		check(not ExpeditionSave.validate(decoded), "Malformed layout settings are rejected before reconstruction")
		decoded = saved.duplicate(true)
		decoded.generation_version -= 1
		check(not ExpeditionSave.validate(decoded), "Pre-site development generations require a new expedition")
	check(admitted >= 3, "Several distinct seeds admit a real woodland site")
	check(boundary, "At least one real admitted site spans render chunks")
	var invalid := Template.new()
	invalid.element_budget = 4
	check(not invalid.plan(WorldTerrain.new()).admitted, "Insufficient required budget rejects the entire site")
	var obstructed := Template.new()
	var blocked_inputs := obstructed.parameters()
	blocked_inputs.clearing_seed = 2601026
	blocked_inputs.clearings = [[0, -40, 100, 100]]
	check(obstructed.configure(blocked_inputs) and not obstructed.plan(WorldTerrain.new()).admitted, "Required clearing rejects every overlapping candidate without publishing geometry")
	var capture := ExpeditionSave.snapshot(2601026, Vector2i.ZERO, false, false, WorldTerrain.GENERATION_VERSION, {}, {}, {}, blocked_inputs)
	check(ExpeditionSave.validate(capture), "Captured required spaces are admitted with the saved layout")
	var captured_terrain := WorldTerrain.new(2601026, {}, {}, capture.scenery)
	check(not captured_terrain.scenery_site.admitted, "Loaded required spaces override current authoring defaults during reconstruction")
	var scene: Node3D = load("res://scenes/world_3d.tscn").instantiate()
	root.add_child(scene)
	var site: Dictionary = scene.world.terrain.scenery_site.duplicate(true)
	check(site.admitted, "Normal expedition publishes the proven woodland site")
	var entrance: Vector2i = site.footprint.position + Vector2i(2, -1)
	scene.world.cell = entrance
	scene.world.destination = entrance
	scene.world.paused = true
	scene.world.rebuild_world()
	var picks: Array = scene.place_root.pick_objects.filter(func(row: Dictionary) -> bool: return row.get("site_id", "") == site.id)
	check(picks.size() == site.elements.size(), "Live view publishes the site once across chunk boundaries")
	scene.world.rebuild_world()
	check(site == scene.world.terrain.scenery_site, "Full visual eviction/rebuild preserves admitted site")
	var path := "user://reformat-scenery-proof.json"
	scene.world.save_game(path)
	scene.world.new_expedition(7)
	scene.world.load_game(path)
	check(site == scene.world.terrain.scenery_site and scene.world.cell == entrance, "Live save/new/load restores site and entrance")
	scene.world.paused = true
	if "--capture-scenery" in OS.get_cmdline_user_args():
		for frame in range(60):
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://artifacts/reformat/woodland-site.png")
		scene.view_azimuth = 180
		scene.view_elevation = 22
		scene.apply_camera()
		for frame in range(5):
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://artifacts/reformat/woodland-site-entrance.png")
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(path + suffix):
			DirAccess.remove_absolute(path + suffix)
	scene.environment.sky = null
	scene.free()
	print("SCENERY SITES: %d checks, %d failures; %d admitted seeds." % [checks, failures, admitted])
	quit(0 if failures == 0 else 1)
