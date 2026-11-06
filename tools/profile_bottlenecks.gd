extends SceneTree
## Paired derived-art/streaming CPU probe; never opens a player's save.
const Library = preload("res://scripts/scenery/plant_library.gd")
const Chunk = preload("res://scripts/presentation/solid_chunk.gd")
const Job = preload("res://scripts/presentation/stream_chunk_job.gd")
var reference: Script = Chunk
var current_script: Script = Chunk
var previous: Array = []
var report := {"engine":Engine.get_version_info().string,"scope":"Paired CPU streaming, retained OS caches; not whole-game FPS","equivalent":true,"runs":[]}

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--reference="): reference = load(arg.trim_prefix("--reference="))
		if arg.begins_with("--current="): current_script = load(arg.trim_prefix("--current="))
	run.call_deferred()

func sample(baked: bool) -> Dictionary:
	Library.use_baked_palette = baked
	Library.refresh()
	var began := Time.get_ticks_usec()
	var terrain := WorldTerrain.new(2601026)
	var result := {"baked":baked,"terrain_ms":(Time.get_ticks_usec()-began)/1000.0,"generation_ms":0.0,"geometry_ms":0.0,"max_slice_ms":0.0,"material_batches":0,"stages":{"cell":0.0,"upload":0.0,"geography":0.0,"generation":0.0}}
	var snapshots: Array = []
	result["work"] = []
	began = Time.get_ticks_usec()
	for coord: Vector2i in [Vector2i.ZERO,Vector2i(1,0),Vector2i(0,1),Vector2i(1,1),Vector2i(-1,0),Vector2i(-1,-1),Vector2i(2,1),Vector2i(1,2)]:
		var view: Node3D = current_script.new() if baked else reference.new()
		var job := Job.new(terrain,coord,load("res://resources/nature_settings.tres"),view)
		while not job.advance(Time.get_ticks_usec()+4000): pass
		result.generation_ms += job.generation_ms
		result.geometry_ms += job.geometry_ms
		result.max_slice_ms = maxf(result.max_slice_ms,job.max_slice_ms)
		for stage in result.stages: result.stages[stage]=maxf(result.stages[stage],job.step_peaks[stage])
		for child in view.get_children():
			if child is MultiMeshInstance3D: result.material_batches += child.multimesh.mesh.get_surface_count()
			elif child is MeshInstance3D: result.material_batches += child.mesh.get_surface_count()
		snapshots.append([job.cells,view.living_sources,view.cosmetic_records])
		if view.get("work") != null: result.work.append(view.work)
		view.free()
	result.total_ms=(Time.get_ticks_usec()-began)/1000.0
	result["palette_current"] = Library.palette_current
	result["baked_models"] = 0
	for item: Resource in Library.procedural_entries.values() + Library.foliage_entries.values():
		if item.get_meta("runtime_palette",false): result.baked_models += 1
	if baked:
		report.equivalent = snapshots == previous
	else:
		previous = snapshots
	return result

func run() -> void:
	report.runs.append(sample(false))
	report.runs.append(sample(true))
	DirAccess.make_dir_recursive_absolute("res://artifacts/bottleneck-fixes")
	var file := FileAccess.open("res://artifacts/bottleneck-fixes/streaming-pair.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	file.close()
	print("BOTTLENECK PROFILE ",JSON.stringify(report))
	if not report.equivalent: push_error("Streaming changed cells, living sources or cosmetic placement")
	quit(0 if report.equivalent else 1)
