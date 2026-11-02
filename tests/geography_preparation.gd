extends SceneTree
## Cold cooperative geography preserves canonical descriptors and admitted routes.
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
	var baseline: Script = load("res://artifacts/chunk-limits/terrain_geography_before.gd") if "--paired" in OS.get_cmdline_user_args() else null
	var previous_peak := 0.0
	var current_peak := 0.0
	var production: TerrainReliefSettings = load("res://resources/terrain_exploration.tres")
	for parameters in [TerrainReliefSettings.new().parameters(), production.parameters()]:
		for seed_value in [17,42,2601026]:
			var source := WorldTerrain.new(seed_value, {}, parameters)
			var reference_source := WorldTerrain.new(seed_value, {}, parameters)
			var reference: RefCounted = baseline.new() if baseline != null else reference_source.geography
			for area in [Vector2i.ZERO,Vector2i(-4,3),Vector2i(10,-10)]:
				var started := Time.get_ticks_usec()
				var expected: Array = reference.basins(reference_source,area)
				previous_peak = maxf(previous_peak,(Time.get_ticks_usec()-started)/1000.0)
				var done := false
				var calls := 0
				while not done and calls < 10000:
					started = Time.get_ticks_usec()
					done = source.geography.prepare_basins(source,area)
					current_peak = maxf(current_peak,(Time.get_ticks_usec()-started)/1000.0)
					calls += 1
				check(done and expected == source.geography.basins(source,area), "Yielding drainage/pond/channel preparation preserves every canonical descriptor")
				check(source.geography.basin_jobs.size() <= 128 and source.geography.drainage_jobs.size() <= 128, "Partial basin and drainage jobs remain bounded")
				expected = reference.paths(reference_source,area)
				done = false
				calls = 0
				while not done and calls < 50000:
					done = source.geography.prepare_paths(source,area)
					calls += 1
				check(done and expected == source.geography.paths(source,area), "Cooperative cold dependency warmup preserves admitted route points and order")
				check(not source.geography.path_basin_prepared.has(area), "Completed routes release warmup cursors so cache turnover will recheck dependencies")
	print("GEOGRAPHY PREPARATION: %d checks, %d failures; cold basin call previous %.3f ms, maximum cooperative step %.3f ms" % [checks,failures,previous_peak,current_peak])
	quit(0 if failures == 0 else 1)
