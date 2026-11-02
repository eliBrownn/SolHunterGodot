extends RefCounted
## Main-thread, resumable preparation. Publication is atomic; cancellation discards only visuals.
var asset_loader: RefCounted
var asset_cell := -1
var asset_paths: Array[String] = []
var asset_wait_frames := 0
var source_content_revision := 0
var terrain: WorldTerrain
var nature: NatureSettings
var coord: Vector2i
var cells: Array[Dictionary] = []
var chunk: Node3D
var generated := 0
var geography_prepared := 0
var geography_low := Vector2i.ZERO
var geography_width := 5
var geography_count := 25
var built := 0
var generation_ms := 0.0
var geometry_ms := 0.0
var max_slice_ms := 0.0
var step_peaks := {"geography": 0.0, "generation": 0.0, "cell": 0.0, "upload": 0.0}
var last_operations := 0
var last_upload_steps := 0

func _init(source: WorldTerrain, at: Vector2i, tuning: NatureSettings, view: Node3D = null) -> void:
	terrain = source
	coord = at
	# Dressing checks the entire plant footprint, including neighboring chunks.
	# Warm those road dependencies too, so a boundary decoration cannot trigger
	# an unbudgeted regional search inside a single cell build.
	geography_low = terrain.geography.region(Vector2(coord * 16 - Vector2i(2, 2))) - Vector2i(2, 2)
	var high: Vector2i = terrain.geography.region(Vector2(coord * 16 + Vector2i(17, 17))) + Vector2i(2, 2)
	geography_width = high.x - geography_low.x + 1
	geography_count = geography_width * (high.y - geography_low.y + 1)
	# The host admits the palette once; do not walk every asset for each chunk.
	nature = tuning if tuning != null else preload("res://resources/nature_settings.tres")
	chunk = view if view != null else load("res://scripts/presentation/solid_chunk.gd").new()
	chunk.position = Vector3(coord.x * 16, 0, coord.y * 16)

func advance(deadline_usec: int, operation_limit: int = 128, upload_step_limit: int = 4) -> bool:
	var started := Time.get_ticks_usec()
	var ready := false
	last_operations = 0
	last_upload_steps = 0
	while Time.get_ticks_usec() < deadline_usec and last_operations < operation_limit:
		var step_start := Time.get_ticks_usec()
		var stage := "geography" if geography_prepared < geography_count else "generation" if generated < 256 else "cell" if built < 256 else "upload"
		if stage == "upload":
			if last_upload_steps >= upload_step_limit: break
		last_operations += 1
		if geography_prepared < geography_count:
			# Warm the complete road dependency set, yielding between candidate
			# searches and route segments so cold districts respect the deadline.
			var area := geography_low + Vector2i(geography_prepared % geography_width, geography_prepared / geography_width)
			if terrain.geography.prepare_paths(terrain, area):
				geography_prepared += 1
			generation_ms += (Time.get_ticks_usec() - step_start) / 1000.0
		elif generated < 256:
			cells.append(terrain.sample(coord * 16 + Vector2i(generated % 16, generated / 16)))
			generated += 1
			generation_ms += (Time.get_ticks_usec() - step_start) / 1000.0
		else:
			if built < 256:
				if asset_loader != null:
					if asset_cell != built:
						asset_paths = preload("res://scripts/presentation/chunk_asset_plan.gd").for_cell(terrain,coord*16+Vector2i(built%16,built/16),cells[built],nature)
						asset_cell = built
					if not asset_loader.ensure(asset_paths):
						asset_wait_frames += 1
						break
				if chunk.build_cell_step(cells, terrain, coord, nature, built):
					built += 1
			else:
				ready = chunk.finish_step()
				# CPU buffer assembly/picking can continue within the operation/time
				# budget; only actual mesh publications spend the upload allowance.
				if chunk.last_finish_uploaded: last_upload_steps += 1
			geometry_ms += (Time.get_ticks_usec() - step_start) / 1000.0
		step_peaks[stage] = maxf(step_peaks[stage], (Time.get_ticks_usec() - step_start) / 1000.0)
		if stage == "upload" and chunk.get("waiting_buffer") == true: break
		if ready:
			break
	max_slice_ms = maxf(max_slice_ms, (Time.get_ticks_usec() - started) / 1000.0)
	return ready

func discard() -> void:
	if chunk != null:
		chunk.free()
		chunk = null
