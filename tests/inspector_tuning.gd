extends SceneTree

var checks := 0
var failures := 0

func check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(description)

func _initialize() -> void:
	create_timer(120).timeout.connect(func() -> void: quit(1))
	run.call_deferred()

func run() -> void:
	var scene: Node3D = (load("res://scenes/world_3d.tscn") as PackedScene).instantiate()
	var expedition := ExpeditionSettings.new()
	expedition.initial_seed = 17
	expedition.move_seconds = 0.27
	expedition.territory_size = 64
	expedition.population_cache_territories = 2
	var climate := ClimateSettings.new()
	climate.moisture_frequency = 0.025
	climate.dry_threshold = 0.35
	climate.wet_threshold = 0.65
	var vastra := VastraSettings.new()
	vastra.recovery_interval_ticks = 2
	vastra.recovery_points = 2
	vastra.tiles_per_tick = 1
	scene.expedition_settings = expedition
	scene.climate_settings = climate
	scene.vastra_settings = vastra
	root.add_child(scene)
	var world: Node2D = scene.world
	world.smoke_mode = true
	check(world.expedition_settings == expedition and world.climate_settings == climate and world.vastra_settings == vastra, "Root Inspector resources reach the actual runtime simulation")
	check(world.terrain.world_seed == 17 and world.terrain.climate == climate.parameters(), "Starting seed and climate overrides affect the actual generated expedition")
	check(world.persistent_state.territory_id(Vector2i(63, 63)) == "17:territory:64:0:0", "Territory tuning reaches persistent identity construction")
	world.advance_movement(0.135, Vector2.RIGHT)
	check(world.cell == Vector2i.ZERO and world.moving and is_equal_approx(world.progress, 0.5), "Movement tuning changes real travel duration rather than an unused display value")
	world.advance_movement(0.135, Vector2.RIGHT)
	check(world.cell == Vector2i(1, 0) and not world.moving, "A tuned cardinal step finishes at its configured duration")
	var state: ExpeditionState = world.persistent_state
	for x in [0, 64, 128]:
		state.remember_population_territory(Vector2i(x, 0), [])
	check(state.population_summary(Vector2i.ZERO).is_empty() and not state.population_summary(Vector2i(64, 0)).is_empty(), "Inspector cache capacity controls real bounded eviction")
	var event := {"actor_kind": "player", "actor_id": "fixture", "sequence": 1, "kind": "disturbance", "cell": [0, 0], "harvest_amount": 0, "overload_delta": 4}
	state.apply_human_activity(event, {"concentration": 50, "overload": 0})
	state.advance_time(1.5)
	check(state.environment_view(Vector2i.ZERO, {}).overload == 2, "Assigned recovery interval/strength reach the live clock callback")
	var saved_climate: Dictionary = world.terrain.climate.duplicate(true)
	var path := "user://inspector-tuning-%d.json" % Time.get_ticks_usec()
	world.save_game(path)
	expedition.territory_size = 32
	climate.moisture_frequency = 0.05
	world.new_expedition(42)
	check(world.persistent_state.territory_id(Vector2i(31, 31)) == "42:territory:32:0:0" and world.terrain.climate.moisture_frequency == 0.05, "Changed generation/territory defaults apply to the next expedition")
	world.load_game(path)
	check(world.persistent_state.territory_id(Vector2i(63, 63)) == "17:territory:64:0:0" and world.terrain.climate == saved_climate, "Loaded saves preserve territory identity and climate despite later Inspector defaults")
	var fallback := ExpeditionSettings.new().parameters()
	expedition.move_seconds = 0.0
	check(world.expedition_parameters() == fallback, "Invalid Inspector tuning safely falls back rather than allowing zero-duration movement")
	expedition.move_seconds = NAN
	check(world.expedition_parameters() == fallback, "Nonfinite programmatic tuning cannot reach movement arithmetic")
	world.expedition_settings = null
	check(world.expedition_parameters() == fallback, "Missing resource assignment has a valid fallback")
	var fixture := "user://inspector-expedition-fixture-%d.tres" % Time.get_ticks_usec()
	check(ResourceSaver.save(ExpeditionSettings.new(), fixture) == OK, "Typed settings serialize as an editable Godot resource")
	var loaded := ResourceLoader.load(fixture, "", ResourceLoader.CACHE_MODE_IGNORE) as ExpeditionSettings
	check(loaded != null and loaded.valid() and loaded.parameters() == fallback, "Saved resource reload preserves valid tuning properties")
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(path + suffix):
			DirAccess.remove_absolute(path + suffix)
	DirAccess.remove_absolute(fixture)
	scene.free()
	print("INSPECTOR TUNING: %d checks, %d failures." % [checks, failures])
	quit(0 if failures == 0 else 1)
