extends SceneTree
var checks := 0
var failures := 0

class EmptyComposition extends Resource:
	var queries := 0
	func patch_at(_terrain: WorldTerrain, _cell: Vector2i) -> Variant:
		queries += 1
		return null

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var terrain := WorldTerrain.new(17)
	var probe := EmptyComposition.new()
	terrain._wetland_composition = probe
	terrain._aquatic_flora_window = preload("res://scripts/core/derived_cache_window.gd").new(8)
	for index in range(24):
		var cell := Vector2i(index - 12, -30)
		check(terrain.authored_wetland_flora(cell) == "", "An empty patch still has no generated living plant")
		var calls: int = probe.queries
		check(terrain.authored_wetland_flora(cell) == "" and probe.queries == calls, "Repeated empty cells reuse the cached generation result")
		check(terrain._aquatic_flora_cache.size() <= 8, "Negative-result cache remains bounded")
	var calls: int = probe.queries
	check(terrain.authored_wetland_flora(Vector2i(-12,-30)) == "" and probe.queries == calls + 1, "Evicted negative results reconstruct identically")
	var definition = load("res://resources/scenery/bounded_composition.tres")
	for seed_value in [17,2601026]:
		terrain = WorldTerrain.new(seed_value)
		var before: Dictionary = terrain.relief.duplicate(true)
		for y in range(16,65,4):
			for x in range(8,65,4):
				var cell := Vector2i(x,y)
				var patch = definition.patch_at(terrain,cell)
				var record: Dictionary = {} if patch == null else definition.placement_for(terrain,cell,patch,3,68,0.0,false,true,false)
				var expected := "plant" if record.get("living",false) else ""
				check(terrain.authored_wetland_flora(cell) == expected, "Retained definition matches the previous exact admission query")
		check(terrain._wetland_composition == definition, "Terrain retains the shared resource instead of reloading it per cell")
		check(terrain.relief == before, "Wetland query caches never modify saved generation parameters")
	print("WETLAND QUERY CACHE: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
