extends "res://tests/runtime_optimization.gd"
## Optional paired CPU study; timing is evidence, never a machine-independent test.

func legacy_fields(resource: Resource, excluded: Array = []) -> Array:
	var result: Array = []
	for property in resource.get_property_list():
		if int(property.usage) & PROPERTY_USAGE_STORAGE and property.name != "script" and property.name not in excluded:
			var value: Variant = resource.get(property.name)
			result.append(value.duplicate() if value is PackedStringArray else value)
	return result

func legacy_configuration(settings: SightingSettings) -> Array:
	var result := legacy_fields(settings, ["ecology_profiles", "behavior_library", "species_catalog", "catalog_sightings"])
	result.append(settings.species_catalog.ecology_configuration() if settings.species_catalog != null else [])
	var library: Array = []
	if settings.behavior_library != null:
		for definition in settings.behavior_library.definitions:
			library.append(legacy_fields(definition) if definition != null else [])
	result.append(library)
	for profile in settings.ecology_profiles:
		result.append(legacy_fields(profile) if profile != null else [])
	return result

func run() -> void:
	var report := {"engine": Engine.get_version_info().string, "scope": "Paired CPU work on one process; no GPU or handheld acceptance", "failures": 0}
	var scene: Node3D = load("res://scenes/world_3d.tscn").instantiate()
	root.add_child(scene)
	var world: Node2D = scene.world
	world.smoke_mode = true
	world.new_expedition(17)
	# Warm shared resources equally before comparing the two selection paths.
	var samples: Array = []
	for y in [0.25, 0.5, 0.75]:
		for x in [0.15, 0.35, 0.5, 0.65, 0.85]:
			var pointer := root.get_visible_rect().size * Vector2(x, y)
			scene.solid_root.hide()
			var fallback: Variant = scene.pointer_cell(pointer)
			var depth: float = scene.pointer_actor_depth
			scene.solid_root.show()
			var expected := exhaustive(scene, pointer, fallback, depth)
			var actual: Variant = scene.pointer_object_cell(pointer, fallback)
			check([actual, scene.pointer_subject] == expected, "Paired picking results agree")
			samples.append([pointer, fallback, depth])
	var started := Time.get_ticks_usec()
	for repetition in range(20):
		for sample in samples:
			exhaustive(scene, sample[0], sample[1], sample[2])
	report.picking_legacy_ms = (Time.get_ticks_usec() - started) / 1000.0
	started = Time.get_ticks_usec()
	for repetition in range(20):
		for sample in samples:
			scene.pointer_actor_depth = sample[2]
			scene.pointer_object_cell(sample[0], sample[1])
	report.picking_indexed_ms = (Time.get_ticks_usec() - started) / 1000.0
	report.picking_calls_per_path = samples.size() * 20
	check(legacy_configuration(scene.sightings.settings) == SolEcology.configuration(scene.sightings.settings), "Cached property names preserve live configuration values")
	started = Time.get_ticks_usec()
	for repetition in range(250):
		legacy_configuration(scene.sightings.settings)
	report.configuration_legacy_ms = (Time.get_ticks_usec() - started) / 1000.0
	started = Time.get_ticks_usec()
	for repetition in range(250):
		SolEcology.configuration(scene.sightings.settings)
	report.configuration_cached_fields_ms = (Time.get_ticks_usec() - started) / 1000.0
	report.configuration_calls_per_path = 250
	var synchronous_max := 0.0
	var slice_max := 0.0
	var sliced_total := 0.0
	var synchronous_total := 0.0
	for coord in [Vector2i(-3, 0), Vector2i(3, 3), Vector2i(6, -2), Vector2i(8, 4)]:
		var direct_terrain := WorldTerrain.new(17)
		started = Time.get_ticks_usec()
		var cells := direct_terrain.extract_chunk(coord)
		var direct := Chunk.new()
		direct.build(cells, direct_terrain, coord, scene.active_nature)
		var duration := (Time.get_ticks_usec() - started) / 1000.0
		synchronous_max = maxf(synchronous_max, duration)
		synchronous_total += duration
		var job := Job.new(WorldTerrain.new(17), coord, scene.active_nature)
		started = Time.get_ticks_usec()
		while not job.advance(Time.get_ticks_usec() + 4000):
			pass
		sliced_total += (Time.get_ticks_usec() - started) / 1000.0
		slice_max = maxf(slice_max, job.max_slice_ms)
		check(geometry(direct) == geometry(job.chunk), "Measured chunk geometry remains equal")
		direct.free()
		job.discard()
	report.synchronous_chunk_max_ms = synchronous_max
	report.preparation_slice_max_ms = slice_max
	report.synchronous_chunks_total_ms = synchronous_total
	report.sliced_chunks_total_ms = sliced_total
	report.chunk_count = 4
	report.failures = failures
	DirAccess.make_dir_recursive_absolute("res://artifacts/optimization")
	var file := FileAccess.open("res://artifacts/optimization/paired_cpu.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	scene.free()
	print("PAIRED CPU STUDY: ", JSON.stringify(report))
	quit(0 if failures == 0 else 1)
