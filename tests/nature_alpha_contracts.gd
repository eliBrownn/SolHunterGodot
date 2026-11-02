extends SceneTree
var failures := 0
var checks := 0

class ReserveChunk extends Node3D:
	var plant_instances: Dictionary = {}
	var applied := 0
	func apply_plant_reserve(_cell: Vector2i, _fraction: float, _seconds: float = -1.0) -> void:
		applied += 1

func check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(label)

func _initialize() -> void:
	run.call_deferred()

func timeline() -> ReadinessTimeline:
	var settings: BattleSettings = load("res://resources/battle_settings.tres")
	var hero := settings.starters[0].snapshot()
	var foe := hero.duplicate(true)
	foe.speed = 5
	var battle := TacticalBattle.prepare(WorldTerrain.new(2601026), Vector2i.ZERO, Vector2i(4, 0), hero, int(hero.max_hp), foe, settings)
	battle.automatic_enemies = false
	battle.deploy(Vector2i(1, 0), true)
	var result := ReadinessTimeline.new()
	result.bind(battle, ReadinessSettings.new())
	return result

func run() -> void:
	var state := ExpeditionState.new(17)
	check(state.record_finding("plant_reserve", Vector2i(1, 2), "1:2", 25), "Actual evidence admits a finding")
	var before := state.snapshot()
	check(not state.record_finding("plant_reserve", Vector2i.ZERO, "other", 90) and state.snapshot() == before, "Repeated observation preserves first evidence")
	check(not state.record_finding("unknown", Vector2i.ZERO, "other") and state.snapshot() == before, "Unknown authored IDs roll back")
	var definition := SolSpeciesDefinition.new()
	definition.species_id = "fixture_observation"
	definition.lineage_id = "fixture_line"
	definition.class_id = "fixture_class"
	for index in range(125):
		var identity := state.register_individual(definition, Vector2i(index, 0), "fixture_affinity")
		state.record_sol_discovery(identity, "Fixture", "Observed", Vector2i(index, 0))
	check(state.discovery_entries().size() == 120 and state.finding_entries().size() == 1, "Sighting eviction cannot evict learned facts")
	var restored := ExpeditionState.restore(JSON.parse_string(JSON.stringify(state.snapshot())), 17)
	check(restored != null and restored.finding_entries() == state.finding_entries(), "Findings survive JSON restoration")
	var detached := state.finding_entries()
	detached[0].first_seen[0] = 900
	check(state.finding_entries()[0].first_seen == [1, 2], "Finding reads are detached")
	var bad := state.snapshot()
	bad.findings.plant_reserve.tick = -1
	check(ExpeditionState.restore(bad, 17) == null, "Corrupt evidence rejects the complete state")
	var sim := timeline()
	var hp := sim.battle.enemy_hp
	sim.advance(100)
	check(sim.clock == 0 and sim.exposure == 0 and sim.battle.enemy_hp == hp, "Planning freezes battle time, exposure and damage")
	check(sim.stage("move", Vector2i(2, 0)), "Legal movement stages")
	check(sim.battle.ally_cell == Vector2i(1, 0), "Plan preview cannot move authoritative body")
	check(sim.stage("move_slot", sim.battle.enemy_cell, 0), "Move after planned movement shares AP")
	check(sim.battle.enemy_hp == hp, "Choosing an attack cannot resolve damage")
	check(sim.commit(), "Ordered plan commits once")
	check(not sim.commit() and not sim.stage("move", Vector2i.ZERO), "Execution rejects replanning")
	sim.advance(0.1)
	check(sim.battle.enemy_hp == hp, "No effect before scheduled impact")
	var traces: Array = []
	for delta in [0.01, 0.05, 0.2]:
		var battle := timeline()
		battle.stage("move", Vector2i(2, 0))
		battle.stage("move_slot", battle.battle.enemy_cell, 0)
		battle.commit()
		for frame in range(1000):
			battle.advance(delta)
			if battle.planning or battle.battle.phase != "active": break
		traces.append([battle.battle.ally_hp, battle.battle.enemy_hp, battle.battle.ally_cell, battle.battle.enemy_cell, battle.battle.move_uses, snappedf(battle.clock, 0.000001)])
	check(traces[0] == traces[1] and traces[1] == traces[2], "Frame partition cannot change committed results or readiness time")
	var editable := timeline()
	editable.stage("move", Vector2i(2, 0))
	editable.stage("move_slot", editable.battle.enemy_cell, 0)
	var retained := editable.steps.duplicate(true)
	check(not editable.edit(0, 1) and editable.steps == retained, "Invalid reorder preserves the entire prior plan")
	check(editable.edit(1, 0, true) and editable.steps.size() == 1, "Remove recomputes remaining plan legality and budget")
	var missed := timeline()
	missed.stage("move", Vector2i(2, 0))
	missed.stage("move_slot", missed.battle.enemy_cell, 0)
	missed.commit()
	missed.battle.enemy_cell = Vector2i(4, 1)
	# Isolate committed aim from AI movement; this is a domain fixture, not a play journey.
	missed.events = missed.events.filter(func(event: Dictionary) -> bool: return event.side == "ally")
	var enemy_hp := missed.battle.enemy_hp
	missed.advance(2.0)
	check(missed.battle.enemy_hp == enemy_hp and missed.battle.log.any(func(line: String) -> bool: return "missed" in line), "Moved target causes a committed-aim miss without chase")
	check(missed.battle.move_uses.ally.values().reduce(func(total: int, amount: int) -> int: return total + amount, 0) == 1, "A missed committed attack consumes one finite use")
	var exhausted := timeline()
	exhausted.tuning.blackout_seconds = 10
	exhausted.tuning.gear_protection = 0
	exhausted.exposure = 9.9
	var ally_hp := exhausted.battle.ally_hp
	exhausted.commit()
	exhausted.advance(1)
	check(exhausted.blackout and exhausted.battle.ally_hp == ally_hp and is_equal_approx(exhausted.clock, 0.1), "Blackout recalls healthy companion at the exact threshold without healing/damage")
	var setup: BattleSettings = load("res://resources/battle_settings.tres")
	var owner := ExpeditionState.new(17)
	check(owner.choose_starter(setup.starters[0].snapshot(), 0), "Recovery fixture admits an existing starter")
	var species := SolSpeciesDefinition.new()
	species.species_id = "seedmote"
	species.lineage_id = "family_010"
	species.class_id = "verdant"
	var opponent := owner.register_individual(species, Vector2i(4, 0), "earth")
	var token := owner.begin_battle(opponent, {Vector2i(4, 0): true})
	check(token > 0 and owner.combat_owns(Vector2i(4, 0)), "Battle entry atomically owns its bounded tile set")
	check(not owner.set_environment(Vector2i(4, 0), {"overload": 80}), "Background writes cannot change a reserved tile")
	check(owner.set_environment(Vector2i(8, 0), {"overload": 80}), "Unrelated world tiles continue accepting transactions")
	var retained_hp := int(owner.active_sol_view().hp)
	check(owner.complete_battle(token, retained_hp, "exhaustion", 3, {}, {"emergency_recall": true}), "Healthy recall commits through the existing once-only outcome owner")
	check(owner.active_sol_view().hp == retained_hp and not owner.return_prepared() and not owner.combat_owns(Vector2i(4, 0)), "Recall retains HP, consumes preparation and releases local ownership")
	check(not owner.complete_battle(token, retained_hp, "exhaustion", 3, {}, {"emergency_recall": true}), "Retry cannot repeat an extraction/outcome")
	var recovery := ExpeditionState.restore(JSON.parse_string(JSON.stringify(owner.snapshot())), 17)
	check(recovery != null and not recovery.return_prepared() and recovery.battle_progress().last_result.cause == "commander_blackout", "Blackout cause and used preparation survive JSON load")
	owner.prepare_return()
	check(owner.return_prepared(), "Camp preparation can renew the supported return")
	reserve_projection()
	reserve_work_budget()
	local_recovery_ownership()
	print("NATURE ALPHA CONTRACTS: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)

func reserve_projection() -> void:
	var library := preload("res://scripts/scenery/plant_library.gd")
	var supported := 0
	var definitions: Array = [library.procedural_definition(0, {"role": "reservoir", "class": ""}, 0), library.foliage_definition(0, 0, "emanator")]
	for definition in definitions:
		var model: Dictionary = library.Art.parts(definition.scene)
		for piece in model.pieces:
			for surface in range(piece.mesh.get_surface_count()):
				var material: Material = piece.mesh.surface_get_material(surface)
				if material is ShaderMaterial and material.shader.resource_path in ["res://shaders/tree_leaf_cards.gdshader", "res://shaders/procedural_plant_foliage.gdshader"]: supported += 1
	check(supported > 0, "Actual enabled runtime palette retains the shared reserve-capable shader references")
	var chunk := preload("res://scripts/presentation/solid_chunk.gd").new()
	var instances := MultiMesh.new()
	instances.transform_format = MultiMesh.TRANSFORM_3D
	instances.use_custom_data = true
	instances.mesh = BoxMesh.new()
	instances.instance_count = 3
	var pose := Transform3D(Basis.IDENTITY, Vector3(2, 1, 3))
	instances.set_instance_transform(0, pose)
	chunk.plant_instances[Vector2i.ZERO] = {"fixture": {"mesh": instances, "indices": PackedInt32Array([0, 1])}}
	chunk.apply_plant_reserve(Vector2i.ZERO, 0.25)
	check(chunk.plant_instances[Vector2i.ZERO].fixture.reserve_level == 5, "Reserve projection queues one quantized value for the canonical cell")
	if DisplayServer.get_name() != "headless":
		check(is_equal_approx(instances.get_instance_custom_data(0).r, 0.25) and instances.get_instance_custom_data(0) == instances.get_instance_custom_data(1), "All leaf clumps in one canonical cell share its reserve fraction")
		check(instances.get_instance_custom_data(2).a == 0 and instances.get_instance_transform(0) == pose, "Reserve appearance cannot change another cell or overwrite event/terrain transforms")
	else: print("Reserve MultiMesh readback requires the rendered contract run")
	chunk.apply_plant_reserve(Vector2i.ZERO,0.75,10.0)
	var start: Color=chunk.plant_instances[Vector2i.ZERO].fixture.reserve_transition
	check(is_equal_approx(start.r,0.25) and is_equal_approx(start.g,0.75),"Reserve meter begins at its displayed value and carries the new target")
	chunk.apply_plant_reserve(Vector2i.ZERO,1.0,10.6)
	var retarget: Color=chunk.plant_instances[Vector2i.ZERO].fixture.reserve_transition
	check(is_equal_approx(retarget.r,0.5) and is_equal_approx(retarget.g,1.0),"Changing reserve mid-transition preserves smooth halfway progress")
	chunk.reserve_transition_seconds = 2.0
	chunk.apply_plant_reserve(Vector2i.ZERO,0.0,20.0)
	chunk.apply_plant_reserve(Vector2i.ZERO,1.0,21.0)
	var configured: Color = chunk.plant_instances[Vector2i.ZERO].fixture.reserve_transition
	check(is_equal_approx(configured.r,0.5),"Configured reserve transition duration also controls smooth CPU retargeting")
	var appearance := NatureSettings.new()
	appearance.reserve_saturation_floor = 0.4
	appearance.reserve_droop = 0.35
	appearance.reserve_transition_seconds = 2.0
	var material := ShaderMaterial.new()
	material.shader = load("res://shaders/tree_leaf_cards.gdshader")
	appearance.apply_plant_material(material)
	check(material.get_shader_parameter("reserve_transition_seconds") == 2.0 and material.get_shader_parameter("reserve_droop") == 0.35 and material.get_shader_parameter("reserve_saturation_floor") == 0.4,"Inspector appearance controls reach the actual leaf material")
	appearance.reserve_saturation_floor = NAN
	check(not appearance.valid(),"Invalid reserve pigment settings are rejected")
	preload("res://scripts/scenery/plant_library.gd").apply_gust(material,0.9,5.0,12.0)
	check(material.get_shader_parameter("wind_gust_strength") == 0.9 and material.get_shader_parameter("wind_gust_seconds") == 5.0 and material.get_shader_parameter("wind_gust_cells") == 12.0,"Weather gust controls reach the shared foliage shader")
	var weather := AtmosphereSettings.new()
	weather.foliage_gust_seconds = 0.0
	check(not weather.valid(),"Zero-period gust settings are rejected")
	chunk.free()

func local_recovery_ownership() -> void:
	var owner := ExpeditionState.new(17)
	var settings: BattleSettings = load("res://resources/battle_settings.tres")
	owner.choose_starter(settings.starters[0].snapshot(), 0)
	var species := SolSpeciesDefinition.new()
	species.species_id = "seedmote"
	species.lineage_id = "family_010"
	species.class_id = "verdant"
	var foe := owner.register_individual(species, Vector2i(4, 0), "earth")
	owner.set_environment(Vector2i(4, 0), {"overload": 80})
	owner.set_environment(Vector2i(8, 0), {"overload": 80})
	var policy := {"interval": 1, "points": 1, "work_limit": 32}
	owner.advance_environment(policy)
	var token := owner.begin_battle(foe, {Vector2i(4, 0): true})
	owner.advance_time(ExpeditionContract.ACTIVITY_INTERVAL)
	owner.advance_environment(policy)
	check(owner.environment_view(Vector2i(4, 0), {}).overload == 80 and owner.environment_view(Vector2i(8, 0), {}).overload == 79, "Local overload is frozen while unrelated natural recovery continues")
	check(owner.complete_battle(token, int(owner.active_sol_view().hp), "retreat", 3, {}, {"vastra_overloads": {"4:0": 82}, "vastra_overload_baseline": {"4:0": 80}}), "Reserved outcomes reconcile through the current expedition transaction")
	check(owner.environment_view(Vector2i(4, 0), {}).overload == 82 and owner.environment_view(Vector2i(8, 0), {}).overload == 79, "Completion applies battle contribution once without reverting unrelated repair")

func reserve_work_budget() -> void:
	var owner := ExpeditionState.new(17)
	owner.configure_flora(VastraSettings.new().plant_parameters())
	var chunk := ReserveChunk.new()
	var definitions: Array[Dictionary] = []
	for x in range(16):
		var cell := Vector2i(x, 0)
		chunk.plant_instances[cell] = {}
		definitions.append({"id": AffinityImprint.key(cell), "cell": [x, 0], "kind": "plant"})
	owner.admit_flora(definitions)
	var before := owner.snapshot()
	var view := preload("res://scripts/presentation/plant_reserve_view.gd").new()
	view.update(owner, {Vector2i.ZERO: chunk}, 3)
	check(chunk.applied == 3 and owner.snapshot() == before, "Reserve projection respects its per-frame cell budget and cannot mutate ecology")
	for frame in range(8): view.update(owner, {Vector2i.ZERO: chunk}, 3)
	check(chunk.applied == 16, "A frozen tick completes one bounded projection pass without endless repeated work")
	chunk.free()
