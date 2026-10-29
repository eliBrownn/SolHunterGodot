extends RefCounted
## Main-thread, resumable preparation. Publication is atomic; cancellation discards only visuals.
var terrain: WorldTerrain
var nature: NatureSettings
var coord: Vector2i
var cells: Array[Dictionary] = []
var chunk: Node3D
var generated := 0
var geography_prepared := 0
var built := 0
var generation_ms := 0.0
var geometry_ms := 0.0
var max_slice_ms := 0.0
var step_peaks := {"geography": 0.0, "generation": 0.0, "cell": 0.0, "upload": 0.0}

func _init(source: WorldTerrain, at: Vector2i, tuning: NatureSettings, view: Node3D = null) -> void:
	terrain = source
	coord = at
	# The host admits the palette once; do not walk every asset for each chunk.
	nature = tuning if tuning != null else preload("res://resources/nature_settings.tres")
	chunk = view if view != null else load("res://scripts/solid_chunk.gd").new()
	chunk.position = Vector3(coord.x * 16, 0, coord.y * 16)

func advance(deadline_usec: int) -> bool:
	var started := Time.get_ticks_usec()
	var ready := false
	while Time.get_ticks_usec() < deadline_usec:
		var step_start := Time.get_ticks_usec()
		var stage := "geography" if geography_prepared < 25 else "generation" if generated < 256 else "cell" if built < 256 else "upload"
		if geography_prepared < 25:
			# A cold first cell otherwise compiles 25 road regions atomically.
			# Warm exactly that same deterministic dependency set, one region at
			# a time, so the deadline can be checked between regional searches.
			var area: Vector2i = terrain.geography.region(Vector2(coord * 16) + Vector2(8, 8))
			terrain.geography.paths(terrain, area + Vector2i(geography_prepared % 5 - 2, geography_prepared / 5 - 2))
			geography_prepared += 1
			generation_ms += (Time.get_ticks_usec() - step_start) / 1000.0
		elif generated < 256:
			cells.append(terrain.sample(coord * 16 + Vector2i(generated % 16, generated / 16)))
			generated += 1
			generation_ms += (Time.get_ticks_usec() - step_start) / 1000.0
		else:
			if built < 256:
				chunk.build_cells(cells, terrain, coord, nature, built, 1)
				built += 1
			else:
				ready = chunk.finish_step()
			geometry_ms += (Time.get_ticks_usec() - step_start) / 1000.0
		step_peaks[stage] = maxf(step_peaks[stage], (Time.get_ticks_usec() - step_start) / 1000.0)
		if ready:
			break
	max_slice_ms = maxf(max_slice_ms, (Time.get_ticks_usec() - started) / 1000.0)
	return ready

func discard() -> void:
	if chunk != null:
		chunk.free()
		chunk = null
