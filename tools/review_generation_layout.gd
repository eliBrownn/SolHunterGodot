extends SceneTree
## W2 map survey of canonical terrain, not a substitute for walking-height review.
const OUTPUT := "res://artifacts/world_generation_next/survey"
const ORIGIN := Vector2i(-48, -64)
const SIZE := Vector2i(96, 80)
const STEP := 2

func _initialize() -> void:
	create_timer(180).timeout.connect(func() -> void: quit(1))
	run.call_deferred()

func run() -> void:
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	var report := {"generation": WorldTerrain.GENERATION_VERSION,
		"origin": [ORIGIN.x, ORIGIN.y], "sample_step": STEP,
		"size": [SIZE.x, SIZE.y], "cases": [],
		"scope": "Canonical ground and final terrain heights at two-cell intervals. White marks the essential approach; gold marks refuge/waystone. Not a traversal, vegetation density or enjoyment assessment."}
	var tuning: TerrainReliefSettings = load("res://resources/terrain_exploration.tres")
	for seed_value in [2601026, 7, 19]:
		var terrain := WorldTerrain.new(seed_value, {}, tuning.parameters())
		var map := Image.create(SIZE.x, SIZE.y, false, Image.FORMAT_RGB8)
		var relief := Image.create(SIZE.x, SIZE.y, false, Image.FORMAT_RGB8)
		var counts := {}
		var route_runs: Array = []
		var minimum := INF
		var maximum := -INF
		var connections: Array = []
		for ry in range(-1, 2):
			for rx in range(-1, 2):
				for pond: Dictionary in terrain.geography.basins(terrain, Vector2i(rx, ry)):
					if pond.has("channel"):
						connections.append({"pond": str(pond.center), "channel": str(pond.channel), "level": pond.level})
		for y in range(SIZE.y):
			for x in range(SIZE.x):
				var cell := ORIGIN + Vector2i(x, y) * STEP
				var ground := terrain.natural_ground(cell)
				counts[ground] = int(counts.get(ground, 0)) + 1
				var h := terrain.vertex_height(cell)
				minimum = minf(minimum, h)
				maximum = maxf(maximum, h)
				var normal := terrain.surface_normal(Vector2(cell) + Vector2(0.5, 0.5))
				var shade := clampf(normal.dot(Vector3(-0.4, 0.8, -0.4).normalized()), 0.25, 1.0)
				var color: Color = terrain.COLORS[ground] * shade
				if absf(cell.y - terrain.trail_y(cell.x)) <= 1:
					color = Color("ddd5ba")
				if cell.length() < 3 or cell.distance_to(terrain.landmark()) < 3:
					color = Color("ffcf60")
				map.set_pixel(x, y, color)
				relief.set_pixel(x, y, Color("243f48").lerp(Color("e1c99a"), clampf((h + 10) / 20, 0, 1)) * shade)
		for x in range(terrain.LANDMARK_X + 1):
			var cell := Vector2i(x, terrain.trail_y(x))
			var ground := terrain.natural_ground(cell)
			if route_runs.is_empty() or int(route_runs[-1].ground) != ground:
				route_runs.append({"ground": ground, "start_x": x, "cells": 1})
			else:
				route_runs[-1].cells += 1
		map.resize(SIZE.x * 6, SIZE.y * 6, Image.INTERPOLATE_NEAREST)
		relief.resize(SIZE.x * 6, SIZE.y * 6, Image.INTERPOLATE_NEAREST)
		map.save_png(OUTPUT + "/%d-habitats.png" % seed_value)
		relief.save_png(OUTPUT + "/%d-relief.png" % seed_value)
		var mountains := Image.create(128, 96, false, Image.FORMAT_RGB8)
		var mountain_peak := 0.0
		for y in range(96):
			for x in range(128):
				var at := Vector2(x * 8 - 384, y * 8 - 256)
				var ridge := terrain.heightfield.mountain_height_at(at)
				mountain_peak = maxf(mountain_peak, ridge)
				mountains.set_pixel(x, y, Color("243f48").lerp(Color("e1c99a"), ridge / 24.0))
		mountains.resize(768, 576, Image.INTERPOLATE_NEAREST)
		mountains.save_png(OUTPUT + "/%d-mountains.png" % seed_value)
		report.cases.append({"seed": seed_value, "settings": tuning.parameters(),
			"sampled_ground_counts": counts, "essential_approach_habitat_runs": route_runs,
			"minimum_height": minimum, "maximum_height": maximum, "connections": connections,
			"mountain_peak": mountain_peak})
		print("GENERATION SURVEY: channels=", connections.size(), " ridge peak=", mountain_peak)
		print("GENERATION SURVEY: ", seed_value, " route habitat runs=", route_runs)
	var file := FileAccess.open(OUTPUT + "/report.json", FileAccess.WRITE)
	if file == null:
		push_error("Cannot write generation survey")
		quit(1)
		return
	file.store_string(JSON.stringify(report, "\t"))
	quit()
