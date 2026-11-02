extends SceneTree
## Repeatable CPU comparisons. Run separately before/after; no FPS/device claim.
var tag := "current"

func _initialize() -> void:
	create_timer(120).timeout.connect(func(): quit(1))
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--tag="): tag = arg.trim_prefix("--tag=").validate_filename()
	run.call_deferred()

func run() -> void:
	var report := {"tag": tag, "engine": Engine.get_version_info().string}
	var terrain := WorldTerrain.new(2601026)
	var scenery: NatureSettings = load("res://resources/nature_biomes.tres")
	var started := Time.get_ticks_usec()
	# Match production scene-load prewarming, outside traversal timing.
	var art = preload("res://scripts/scenery/nature_art.gd")
	preload("res://scripts/scenery/meadow_art.gd").mesh()
	var vegetation: VegetationAppearance = load("res://resources/vegetation_appearance.tres")
	for category: String in FloraTraits.CLASSES: vegetation.parts_for(category)
	if scenery.composition != null:
		for patch: NaturePatch in scenery.composition.patches:
			for entry: NatureAssetEntry in patch.entries: entry.admitted_model()
	for biome: NatureBiomePalette in scenery.biomes:
		for tree: PackedScene in biome.trees: art.tint_parts(art.compact_parts(tree), biome.tree_tint)
		for entry: NatureAssetEntry in biome.details: art.tint_parts(entry.admitted_model(), biome.detail_tint)
	for palette: Array in [scenery.common_trees, scenery.hardy_trees, scenery.rocks, scenery.undergrowth]:
		for asset: PackedScene in palette: art.compact_parts(asset)
	report["asset_prewarm_ms"] = (Time.get_ticks_usec() - started) / 1000.0
	started = Time.get_ticks_usec()
	var peak := 0.0
	var checksum := 0
	var step_peaks := {}
	for coord in [Vector2i(3, 3), Vector2i(8, 5), Vector2i(-9, 8)]:
		var job = preload("res://scripts/presentation/stream_chunk_job.gd").new(terrain, coord, scenery)
		while not job.advance(Time.get_ticks_usec() + 1000): pass
		peak = maxf(peak, job.max_slice_ms)
		for stage: String in job.step_peaks: step_peaks[stage] = maxf(step_peaks.get(stage, 0.0), job.step_peaks[stage])
		checksum = hash([checksum, job.cells])
		job.discard()
	report["stream_total_ms"] = (Time.get_ticks_usec() - started) / 1000.0
	report["stream_max_slice_ms"] = peak
	report["stream_step_peaks_ms"] = step_peaks
	report["terrain_checksum"] = checksum
	var catalog := FloraCatalog.new(terrain)
	catalog.request(Vector2i(56, 56), 1, 12.0)
	while not catalog.pending.is_empty(): catalog.advance(Time.get_ticks_usec() + 1000)
	started = Time.get_ticks_usec()
	var neighbors := 0
	for repeat in range(30):
		for offset in range(32):
			var result: Variant = catalog.trees_near(Vector2i(48 + offset % 8, 48 + offset / 8), 10.0)
			if result != null: neighbors += result.size()
		catalog.active_ids()
	report["flora_queries_ms"] = (Time.get_ticks_usec() - started) / 1000.0
	report["neighbor_count"] = neighbors
	var scene: Node3D = load("res://scenes/world_3d.tscn").instantiate()
	root.add_child(scene)
	scene.set_process(false)
	scene.world.set_process(false)
	var currents: Node3D
	for child in scene.get_children():
		if child.get_script() == preload("res://scripts/presentation/vastra_currents.gd"): currents = child
	currents.set_process(false)
	var a := Vector3(3.5, scene.ground_height(Vector2(3.5, 3.5)) + 0.1, 3.5)
	var b := Vector3(10.5, scene.ground_height(Vector2(10.5, 6.5)) + 0.1, 6.5)
	started = Time.get_ticks_usec()
	var curve_checksum := 0
	for repeat in range(400):
		curve_checksum = hash([curve_checksum, currents.transfer_points(a, b, repeat % 16, false)])
	report["transfer_curves_ms"] = (Time.get_ticks_usec() - started) / 1000.0
	report["curve_checksum"] = curve_checksum
	DirAccess.make_dir_recursive_absolute("res://artifacts/world-optimization")
	var file := FileAccess.open("res://artifacts/world-optimization/%s.json" % tag, FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	print("WORLD OPTIMIZATION PROFILE: ", JSON.stringify(report))
	scene.free()
	quit()
