extends SceneTree
## Cursor lifetime, operation limits and exact placement/anatomy equivalence.
const Chunk = preload("res://scripts/presentation/solid_chunk.gd")
const Job = preload("res://scripts/presentation/stream_chunk_job.gd")
const Library = preload("res://scripts/scenery/plant_library.gd")
var checks := 0
var failures := 0

class CellProbe extends Node3D:
	var calls := 0
	var last_finish_uploaded := false
	func build_cell_step(_cells: Array[Dictionary], _terrain: WorldTerrain, _coord: Vector2i, _nature: NatureSettings, _index: int) -> bool:
		calls += 1
		return calls%5 == 0

func _initialize() -> void:
	run.call_deferred()

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)

func snapshot(chunk: Node3D) -> Array:
	var surfaces := {}
	for child in chunk.get_children():
		if child is MultiMeshInstance3D:
			var arrays: Array = []
			for surface in range(child.multimesh.mesh.get_surface_count()): arrays.append(child.multimesh.mesh.surface_get_arrays(surface))
			surfaces[str(child.name)]=[arrays,child.multimesh.buffer]
		elif child is MeshInstance3D:
			surfaces[str(child.name)]=child.mesh.surface_get_arrays(0)
	var picks: Array=[]
	for record: Dictionary in chunk.pick_objects:
		var row := record.duplicate()
		var arrays: Array=[]
		for surface in range(row.mesh.get_surface_count()): arrays.append(row.mesh.surface_get_arrays(surface))
		row.mesh=arrays
		picks.append(row)
	return [surfaces,chunk.cosmetic_records.duplicate(true),chunk.living_sources.duplicate(true),picks,chunk.tile_count,chunk.obstacle_count,chunk.shoreline_edges]

func run() -> void:
	var reference: Script=Chunk
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--reference="): reference=load(arg.trim_prefix("--reference="))
	var terrain := WorldTerrain.new(2601026)
	var tuning: NatureSettings=load("res://resources/nature_biomes.tres")
	tuning=tuning.duplicate()
	tuning.meadow_enabled=true
	var expected_ms := 0.0
	var reference_cpu_ms := 0.0
	var reference_peak_ms := 0.0
	var sliced_cpu_ms := 0.0
	var largest_step_ms := 0.0
	var largest_cell_ms := 0.0
	var clumps := 0
	for coord in [Vector2i.ZERO,Vector2i(-1,-1),Vector2i(3,3)]:
		var cells := terrain.extract_chunk(coord)
		var expected: Node3D=reference.new()
		# Warm both model caches before timing the operation boundary itself.
		expected.build(cells,terrain,coord,tuning)
		var actual := Chunk.new()
		var began := Time.get_ticks_usec()
		for index in range(256): actual.build_cells(cells,terrain,coord,tuning,index,1)
		actual.free()
		expected_ms+=(Time.get_ticks_usec()-began)/1000.0
		var measured: Node3D=reference.new()
		for index in range(256):
			began=Time.get_ticks_usec()
			measured.build_cells(cells,terrain,coord,tuning,index,1)
			var elapsed := (Time.get_ticks_usec()-began)/1000.0
			reference_cpu_ms+=elapsed
			reference_peak_ms=maxf(reference_peak_ms,elapsed)
		measured.free()
		actual=Chunk.new()
		for index in range(256):
			var cell_start := Time.get_ticks_usec()
			var done := false
			while not done:
				var before: int=actual.cosmetic_records.size()
				began=Time.get_ticks_usec()
				done=actual.build_cell_step(cells,terrain,coord,tuning,index)
				var elapsed := (Time.get_ticks_usec()-began)/1000.0
				sliced_cpu_ms+=elapsed
				largest_step_ms=maxf(largest_step_ms,elapsed)
				var added: int=actual.cosmetic_records.size()-before
				check(added<=1,"A cell step submits at most one body or grass clump")
				clumps+=added
				check(actual.get_child_count()==0,"Partial cell work never publishes render nodes")
			largest_cell_ms=maxf(largest_cell_ms,(Time.get_ticks_usec()-cell_start)/1000.0)
		actual.finish()
		var left := snapshot(expected)
		var right := snapshot(actual)
		# Mesh resources are shared through the art cache in both implementations.
		check(left==right,"Sliced cells exactly preserve geometry, picking, cosmetics, anatomy and canonical endpoints at %s"%coord)
		check(actual.cell_work.is_empty(),"Completed cell releases its cursor")
		expected.free()
		actual.free()
	check(clumps>256,"Fixture exercises dense grass, not only empty terrain")
	var probe := CellProbe.new()
	var job := Job.new(terrain,Vector2i.ZERO,tuning,probe)
	job.geography_prepared=job.geography_count
	job.generated=256
	check(not job.advance(Time.get_ticks_usec()-1,4) and probe.calls==0,"Expired deadline cannot start partial cells")
	check(not job.advance(Time.get_ticks_usec()+1000000,4) and job.built==0 and probe.calls==4,"Operation cap can yield within one cell")
	check(not job.advance(Time.get_ticks_usec()+1000000,1) and job.built==1,"Only a completed cell advances the chunk cursor")
	job.discard()
	var partial := Chunk.new()
	var cells := terrain.extract_chunk(Vector2i.ZERO)
	var source_before := cells.duplicate(true)
	var found := false
	for index in range(256):
		var done := false
		while not done:
			done=partial.build_cell_step(cells,terrain,Vector2i.ZERO,tuning,index)
			var plant: Dictionary=partial.cell_work.get("plant",{})
			var grass: Dictionary=plant.get("grass",{})
			if grass.get("index",0)>0 and grass.index<grass.count and not grass.first.is_empty():
				found=true
				break
		if found: break
	check(found,"Cancellation fixture interrupts a populated grass cursor")
	while not partial.retire_step(): pass
	check(partial.cell_work.is_empty() and partial.cosmetic_records.is_empty() and partial.living_sources.is_empty(),"Retirement releases unfinished cell work and local endpoints")
	check(cells==source_before,"Cancelling partial scenery preserves canonical source cells")
	partial.free()
	print("CELL PREPARATION: %d checks, %d failures; warmed full-cell CPU %.3f ms vs sliced CPU %.3f ms; original cell peak %.3f ms vs sliced operation peak %.3f ms; accumulated sliced cell peak %.3f ms"%[checks,failures,reference_cpu_ms,sliced_cpu_ms,reference_peak_ms,largest_step_ms,largest_cell_ms])
	quit(0 if failures==0 else 1)
