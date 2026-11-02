extends SceneTree
## Finite catchment comparison, not a playable river renderer or global watershed proof.
func _initialize() -> void:
	create_timer(120).timeout.connect(func() -> void: quit(1))
	run.call_deferred()

func run() -> void:
	var output := "res://artifacts/world_exploration/noise-drainage"
	DirAccess.make_dir_recursive_absolute(output)
	var summary := {"seed": 2601026, "grid": [129,129], "sample_step_cells": 4,
		"origin": [-128,-128], "boundary": "All study edges are outlets; not a cross-region river contract.",
		"method": "Same landform settings and seed, two elevation noise families. Priority-Flood receiver tree and contributing-area analysis on raw pre-road/pre-pond terrain.", "cases": []}
	for family in [FastNoiseLite.TYPE_SIMPLEX_SMOOTH,FastNoiseLite.TYPE_PERLIN]:
		var settings: TerrainReliefSettings = preload("res://resources/terrain_exploration.tres").duplicate()
		settings.elevation_noise = family
		var terrain := TerrainHeightfield.new(2601026,settings)
		var heights := PackedFloat64Array()
		var low := INF
		var high := -INF
		for y in range(129):
			for x in range(129):
				var value := terrain.surface_height(Vector2(x*4-128,y*4-128))
				heights.append(value)
				low = minf(low,value)
				high = maxf(high,value)
		var flow := TerrainDrainage.analyze(heights,129,129)
		var elevation := Image.create(129,129,false,Image.FORMAT_RGB8)
		var drainage := Image.create(129,129,false,Image.FORMAT_RGB8)
		var maximum_area := 0
		var filled_cells := 0
		for y in range(129):
			for x in range(129):
				var index := y*129+x
				var value := clampf((heights[index]+8.0)/16.0,0.0,1.0)
				var color := Color("2f695d").lerp(Color("a6ae70"),value*2) if value < 0.5 else Color("a6ae70").lerp(Color("e6d3ae"),(value-0.5)*2)
				elevation.set_pixel(x,y,color)
				var area: int = flow.accumulation[index]
				maximum_area = maxi(maximum_area,area)
				if flow.filled[index]-heights[index] > 0.25:
					filled_cells += 1
					color = color.lerp(Color("5bc3c5"),0.6)
				if area >= 64:
					color = color.lerp(Color("1453a2"),clampf(log(float(area))/log(1024.0),0.35,1.0))
				drainage.set_pixel(x,y,color)
		var name := "perlin" if family == FastNoiseLite.TYPE_PERLIN else "simplex"
		elevation.resize(774,774,Image.INTERPOLATE_NEAREST)
		drainage.resize(774,774,Image.INTERPOLATE_NEAREST)
		elevation.save_png(output+"/"+name+"-elevation.png")
		drainage.save_png(output+"/"+name+"-drainage.png")
		summary.cases.append({"family": name, "parameters": settings.parameters(), "min_height_cells": low,
			"max_height_cells": high,"maximum_contributing_samples": maximum_area,"spill_filled_samples": filled_cells})
	FileAccess.open(output+"/comparison.json",FileAccess.WRITE).store_string(JSON.stringify(summary,"\t"))
	print("NOISE/DRAINAGE STUDY: two noise families, 16641 samples each; ",output)
	quit()
