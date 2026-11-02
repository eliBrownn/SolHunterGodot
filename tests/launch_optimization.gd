extends SceneTree
## Launch terrain shortcuts preserve generated trails, raw vertices and save parameters.
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
	for seed_value in [17,2601026]:
		var terrain := WorldTerrain.new(seed_value)
		for y in range(-8,9):
			for x in range(-8,9):
				var cell := Vector2i(x*5,y*5)
				check(terrain.trail_visible_at(cell)==terrain.sample(cell).trail_visible,"Lightweight trail query matches full generated records")
		var field := TerrainHeightfield.new(seed_value)
		field._vertex_window = preload("res://scripts/core/derived_cache_window.gd").new(8)
		var origin := field.raw_height(Vector2.ZERO)
		var original_snapshot := field.snapshot()
		for index in range(40):
			var at := Vector2i(index-20,71-index)
			var expected := field.raw_height(Vector2(at))-origin
			check(field.vertex_height(at)==expected and field.vertex_height(at)==expected,"Cached relief vertices match uncached raw generation exactly")
			check(field._vertices.size()<=8,"Relief cache stays bounded through eviction")
		var evicted := Vector2i(-20,71)
		check(field.vertex_height(evicted)==field.raw_height(Vector2(evicted))-origin,"Evicted vertices reconstruct exactly")
		check(field.snapshot()==original_snapshot,"Derived relief cache never enters saved generation parameters")
	print("LAUNCH OPTIMIZATION: %d checks, %d failures" % [checks,failures])
	quit(0 if failures == 0 else 1)
