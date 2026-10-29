extends SceneTree

var checks := 0
var failures := 0
var region_queries: Array[Vector2i] = []

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func _initialize() -> void:
	create_timer(120).timeout.connect(func() -> void: quit(1))
	run.call_deferred()

func species() -> SolSpeciesDefinition:
	var definition := SolSpeciesDefinition.new()
	definition.species_id = "fixture_population"
	definition.lineage_id = "fixture_lineage"
	definition.class_id = "fixture_class"
	return definition

func region(origin: Vector2i) -> String:
	region_queries.append(origin)
	return "fixture_west" if origin.x < 8 else "fixture_east"

func run() -> void:
	var state := ExpeditionState.new(17)
	var before := state.snapshot()
	check(state.population_summary(Vector2i.ZERO).is_empty() and state.snapshot() == before, "Unknown summary reads do not populate or mutate state")
	check(state.observe_territory(Vector2i.ZERO) and state.population_summary(Vector2i.ZERO).is_empty(), "A visited territory is not automatically a known population census")
	var first := state.register_individual(species(), Vector2i(1, 1), "fixture_amber")
	var second := state.register_individual(species(), Vector2i(14, 14), "fixture_blue")
	check(state.population_summary(Vector2i.ZERO).is_empty(), "Sparse individual registration alone cannot pretend to be complete territory knowledge")
	before = state.snapshot()
	var homes := [first, second]
	check(state.remember_population_territory(Vector2i.ZERO, homes), "Explicit producer can publish complete registered home definitions")
	homes.clear()
	var summary := state.population_summary(Vector2i(15, 15))
	check(summary.home_slots == 2 and summary.available == 2 and summary.territory_id == "17:territory:16:0:0", "Whole-cell projection includes homes beyond the queried position")
	check(summary.carrying_capacity == null and summary.effective_population == null, "Missing ecological capacity remains unknown rather than a spawn limit")
	check(state.population_summary(Vector2i(1, 1)) == summary and state.snapshot() == before, "Publication and reads do not alter save output or partition by visibility")
	summary.available = 0
	check(state.population_summary(Vector2i.ZERO).available == 2, "Returned summaries cannot mutate the population authority")
	state.acquire(first, "party")
	check(state.population_summary(Vector2i.ZERO).available == 1, "Ownership immediately excludes a captured individual without refill")
	state.relocate_owned(first, "storage")
	check(state.population_summary(Vector2i.ZERO).available == 1, "Party/storage movement does not create a wild copy")
	var replacement := state.register_individual(species(), Vector2i(1, 1), "fixture_amber", 1)
	check(not replacement.is_empty() and state.population_summary(Vector2i.ZERO).available == 2, "An explicitly registered replacement is distinct from the owned original")
	state.acquire(replacement)
	check(state.population_summary(Vector2i.ZERO).available == 1 and state.population_summary(Vector2i.ZERO).home_slots == 2, "Owning a replacement excludes its availability while retaining the complete home definition")
	region_queries.clear()
	var capacities := {"fixture_west": 0, "fixture_east": 99}
	summary = state.population_summary(Vector2i(15, 15), capacities, region)
	check(summary.carrying_capacity == 0 and summary.effective_population == 0 and region_queries == [Vector2i.ZERO], "Capacity resolves at the fixed territory origin, not the query location")
	capacities.fixture_west = 1
	check(state.population_summary(Vector2i.ZERO, capacities, region).effective_population == 1, "Current authored carrying capacity clamps assistance input")
	state.acquire(second)
	check(state.population_summary(Vector2i.ZERO).available == 0 and not state.population_summary(Vector2i.ZERO).is_empty(), "A known depleted territory remains distinct from an unknown territory")
	check(state.remember_population_territory(Vector2i(16, 0), []) and state.population_summary(Vector2i(16, 0)).home_slots == 0, "An explicit complete empty publication establishes known zero without spawning")
	before = state.snapshot()
	for invalid in [true, -1, 257, 1.5, "1", INF, NAN]:
		check(state.population_summary(Vector2i.ZERO, {"fixture_west": invalid}, region).is_empty() and state.snapshot() == before, "Malformed capacity values reject without changing persistent state")
	for invalid in [true, 0, 1025, 1.5, "1", null]:
		check(not state.set_population_cache_limit(invalid) and state.population_summary(Vector2i.ZERO).available == 0, "Invalid cache settings preserve known definitions")
	for invalid in [[first, first], [replacement], ["18:1:1:fixture_population"], ["17:2:2:unknown"], [true]]:
		check(not state.remember_population_territory(Vector2i.ZERO, invalid) and state.population_summary(Vector2i.ZERO).home_slots == 2, "Duplicate, replacement, cross-seed, absent or malformed home definitions fail before replacing the cache")
	check(not state.remember_population_territory(Vector2i(16, 0), [first]), "A home cannot be published into another territory")
	check(state.population_summary(Vector2i(1000001, 0)).is_empty() and not state.remember_population_territory(Vector2i(1000001, 0), []), "Out-of-world population accesses fail without allocation")
	check(state.invalidate_population_territory(Vector2i.ZERO) and state.population_summary(Vector2i.ZERO).is_empty() and not state.invalidate_population_territory(Vector2i.ZERO), "Explicit invalidation returns knowledge to unknown without touching individuals")
	check(state.snapshot() == before, "Cache settings and invalidation never change persistent authority")
	verify_cache_bounds()
	verify_dense_and_negative()
	verify_persistence()
	print("POPULATION SUMMARY: %d checks, %d failures." % [checks, failures])
	quit(0 if failures == 0 else 1)

func verify_cache_bounds() -> void:
	var state := ExpeditionState.new(17)
	state.set_population_cache_limit(2)
	state.remember_population_territory(Vector2i.ZERO, [])
	state.remember_population_territory(Vector2i(16, 0), [])
	state.population_summary(Vector2i.ZERO)
	state.remember_population_territory(Vector2i(32, 0), [])
	check(state.population_summary(Vector2i.ZERO).is_empty() and not state.population_summary(Vector2i(16, 0)).is_empty(), "Bounded publication eviction is not affected by reads")
	check(state.set_population_cache_limit(1) and state.population_summary(Vector2i(32, 0)).is_empty(), "Changing the cache budget invalidates prior definitions")
	state.remember_population_territory(Vector2i.ZERO, [])
	state.remember_population_territory(Vector2i.ZERO, [])
	check(not state.population_summary(Vector2i.ZERO).is_empty(), "Republishing a territory does not duplicate its cache slot")

func verify_dense_and_negative() -> void:
	var state := ExpeditionState.new(17, 64)
	var home := state.register_individual(species(), Vector2i(-1, -65), "fixture_amber")
	check(state.remember_population_territory(Vector2i(-64, -128), [home]), "Negative homes use floor-based territory membership")
	region_queries.clear()
	var summary := state.population_summary(Vector2i(-1, -65), {"fixture_west": 3}, region)
	check(summary.territory_id == "17:territory:64:-1:-2" and region_queries == [Vector2i(-64, -128)], "Territory size stays independent of render chunks and negative capacity lookup uses its origin")
	state = ExpeditionState.new(17)
	var homes: Array[String] = []
	for row in range(16):
		for col in range(16):
			homes.append(state.register_individual(species(), Vector2i(col, row), "fixture_amber"))
	check(state.remember_population_territory(Vector2i.ZERO, homes), "The technical 256-home boundary accepts a complete dense fixture")
	summary = state.population_summary(Vector2i.ZERO, {"fixture_west": 2}, region)
	check(summary.home_slots == 256 and summary.available == 256 and summary.effective_population == 2, "Ecological capacity does not delete or cap real availability")
	var before := state.snapshot()
	var all_valid := true
	for index in range(240):
		all_valid = all_valid and state.population_summary(Vector2i(15, 15)).available == 256
	check(all_valid and state.snapshot() == before, "Repeated complete-cell reads preserve all persistent data without generating individuals")
	homes.append(homes[0])
	check(not state.remember_population_territory(Vector2i.ZERO, homes) and state.population_summary(Vector2i.ZERO).home_slots == 256, "Overlarge definition publication preserves the prior complete cell")

func verify_persistence() -> void:
	var scene: Node3D = (load("res://scenes/world_3d.tscn") as PackedScene).instantiate()
	scene.sighting_settings = SightingSettings.new()
	scene.sighting_settings.enabled = false # This suite publishes only its explicit home fixture.
	root.add_child(scene)
	var world: Node2D = scene.world
	world.smoke_mode = true
	world.new_expedition(17)
	var state: ExpeditionState = world.persistent_state
	var home := state.register_individual(species(), Vector2i(1, 1), "fixture_amber")
	var before := state.snapshot()
	state.remember_population_territory(Vector2i.ZERO, [home])
	check(state.snapshot() == before, "Runtime publication introduces no save fields or copied counts")
	for coord: Vector2i in world.chunks.keys():
		world.remove_chunk(coord)
	world.rebuild_world()
	check(state.population_summary(Vector2i.ZERO).available == 1, "Render chunk eviction does not own the independent population index")
	var path := "user://population-summary-%d.json" % Time.get_ticks_usec()
	world.save_game(path)
	world.load_game(path)
	state = world.persistent_state
	check(state.population_summary(Vector2i.ZERO).is_empty() and state.individual_view(home).location == "wild", "Actual reload discards runtime summaries while preserving the same individual")
	state.remember_population_territory(Vector2i.ZERO, [home])
	check(state.population_summary(Vector2i.ZERO).available == 1 and state.acquire(home), "Rebuilt derived indexes project restored wild authority")
	world.save_game(path)
	world.load_game(path)
	state = world.persistent_state
	state.remember_population_territory(Vector2i.ZERO, [home])
	check(state.population_summary(Vector2i.ZERO).available == 0 and state.individual_view(home).location == "sealed", "Restored ownership cannot refill a home through cache publication")
	world.new_expedition(42)
	check(world.persistent_state.population_summary(Vector2i.ZERO).is_empty() and world.persistent_state.counts().individuals == 0, "New seed carries over neither runtime definitions nor individuals")
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(path + suffix):
			DirAccess.remove_absolute(path + suffix)
	scene.free()
