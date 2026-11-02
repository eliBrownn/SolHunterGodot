extends SceneTree
var checks := 0
var failures := 0
const SEED := 17
var source := Vector2i.ZERO
var tree := Vector2i.ZERO

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)

func _initialize() -> void:
	run.call_deferred()

func definition(at: Vector2i, kind: String = "plant") -> Dictionary:
	return {"id": AffinityImprint.key(at), "cell": [at.x, at.y], "kind": kind}

func empty_candidates(_at: Vector2i, _reach: float) -> Array[Dictionary]:
	return []

func environment(state: ExpeditionState) -> Callable:
	return func(at: Vector2i) -> Dictionary: return state.environment_view(at, {"concentration": 50, "overload": 0})

func step(state: ExpeditionState, resolver: Callable = empty_candidates, weather: bool = false, protection: bool = false) -> void:
	state.advance_time(ExpeditionContract.ACTIVITY_INTERVAL)
	state.advance_flora(resolver, environment(state), Callable(), null, func(_at: Vector2i) -> bool: return protection, weather)

func fixture(energy: float = 80.0, roots: float = 0.0) -> ExpeditionState:
	var state := ExpeditionState.new(SEED)
	var policy := VastraSettings.new().plant_parameters()
	policy.refill = 0.0
	policy.repair_points = 0
	state.configure_flora(policy)
	state.configure_ecology(VesselSettings.new().parameters())
	state.admit_flora([definition(source), definition(tree, "tree")])
	var saved := state.snapshot()
	saved.flora.nodes[AffinityImprint.key(source)].energy = energy
	saved.flora.nodes[AffinityImprint.key(tree)].roots = roots
	saved.flora.absorbed = energy + roots
	state = ExpeditionState.restore(saved, SEED)
	state.set_flora_active([AffinityImprint.key(source), AffinityImprint.key(tree)])
	return state

func group(state: ExpeditionState) -> Dictionary:
	var groups: Dictionary = state.ecology_view().groups
	return groups.values()[0] if not groups.is_empty() else {}

func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://artifacts/vessel-response")
	for y in range(1, 10):
		for x in range(1, 10):
			var at := Vector2i(x, y)
			if FloraTraits.describe(SEED, definition(at)).role == "emanator": source = at; break
		if source != Vector2i.ZERO: break
	tree = source + Vector2i.RIGHT
	check(source != Vector2i.ZERO, "Fixture uses a canonical grass identity")
	var state := fixture()
	step(state)
	check(group(state).state == "ordinary" and state.ecology_view().signals.is_empty(), "Healthy swarms do not invent alarms or overload")
	check(group(state).energy == 2.0 and state.flora_reading(source).energy == 78.0, "Feeding debits a real source and credits only the same energy")
	var before := state.snapshot()
	state.advance_flora(empty_candidates, environment(state))
	check(state.snapshot() == before, "Repeated service in one tick cannot double-feed or double-respond")
	for i in range(80): step(state)
	check(group(state).state == "ordinary" and state.ecology_view().serial == 0, "A healthy unclassed patch stays stable without Regulators")
	check(state.flora_reading(source).energy == 50.0, "Feeding preserves a source reserve instead of starving all transfers")
	check(ExpeditionState.valid_snapshot(state.snapshot(), SEED), "Two conserved ledgers reconcile in a populated world")
	var old := state.snapshot()
	old.erase("ecology")
	check(ExpeditionState.restore(old, SEED) != null, "Existing v20 snapshots remain loadable without the optional ecology extension")
	state = fixture()
	state.set_environment(source, {"overload": 12})
	step(state)
	check(group(state).state == "investigating" and state.ecology_view().serial == 1, "A real local disturbance creates one signal and investigation")
	var event: Dictionary = state.ecology_view().signals.values()[0]
	for i in range(4): step(state)
	check(group(state).state == "responding", "Investigation precedes a paid defensive response")
	check(state.ecology_view().spent > 0, "Response consumes stored swarm energy")
	var json_copy := ExpeditionState.restore(JSON.parse_string(JSON.stringify(state.snapshot())), SEED)
	check(json_copy != null, "Response, signals and energy survive JSON save/load")
	if json_copy != null:
		json_copy.set_flora_active([AffinityImprint.key(source), AffinityImprint.key(tree)])
		step(state)
		step(json_copy)
		check(state.snapshot() == json_copy.snapshot(), "Saved response resumes deterministically")
	for i in range(65): step(state)
	check(state.ecology_view().serial == 1 and state.ecology_view().signals.is_empty(), "Own discharges cannot endlessly refresh an expired alarm")
	check(group(state).state == "ordinary", "A persistent disturbance still permits a finite response and recovery")
	check(event.expires == event.created + VesselSettings.new().signal_lifetime_ticks, "Signals have an original finite expiry")
	state = fixture(80, 600)
	for i in range(7): step(state)
	check(state.ecology_view().serial == 0, "Ordinary overflow does not immediately trigger an alarm")
	step(state)
	check(state.ecology_view().signals.values()[0].cause == "stranded_flow", "Sustained stranded root stock supplies a state-backed natural trigger")
	for i in range(7): step(state)
	check(group(state).state == "escalating" and state.environment_view(source, {"overload": 0}).overload > 0, "Excessive paid defense can originate natural overload")
	check(ExpeditionState.valid_snapshot(state.snapshot(), SEED), "Natural escalation preserves canonical persistence and conservation")
	var corrupt := state.snapshot()
	corrupt.ecology.groups[group(state).id].energy += 1
	check(ExpeditionState.restore(corrupt, SEED) == null, "A duplicated swarm reserve is rejected")
	corrupt = state.snapshot()
	corrupt.ecology.signals.values()[0].expires += 1
	check(ExpeditionState.restore(corrupt, SEED) == null, "An alarm cannot acquire a renewed expiry through a malformed save")
	corrupt = state.snapshot()
	corrupt.ecology.groups[group(state).id].until += 999
	check(ExpeditionState.restore(corrupt, SEED) == null, "A malformed save cannot extend a defensive response indefinitely")
	var suspended := state.snapshot()
	state.set_flora_active([])
	for i in range(10): step(state)
	check(group(state).energy == suspended.ecology.groups[group(state).id].energy, "Inactive groups receive no invented feeding or offline energy")
	state.set_flora_active([AffinityImprint.key(source), AffinityImprint.key(tree)])
	step(state)
	check(group(state).energy <= float(suspended.ecology.groups[group(state).id].energy) + 2.0, "Reactivation does not catch up inactive feeding")
	# A trace rides the exact energy packet and is delivered only at its real arrival.
	state = fixture(100)
	state.set_environment(source, {"overload": 5})
	state.set_flora_active([AffinityImprint.key(source)])
	var recipient := definition(tree, "tree")
	var resolver := func(_at: Vector2i, _reach: float) -> Array[Dictionary]: return [recipient]
	step(state, resolver)
	var flight: Dictionary = state.flora_view().flights[0]
	check(state.ecology_view().carriers.has(str(flight.id)) and not state.ecology_view().memories.has(recipient.id), "A packet carries a signal without early remote delivery")
	json_copy = ExpeditionState.restore(JSON.parse_string(JSON.stringify(state.snapshot())), SEED)
	check(json_copy != null, "Signal carrier identities survive JSON numeric conversion")
	while state.activity_tick() < int(flight.arrival): step(state, resolver)
	check(state.ecology_view().memories.has(recipient.id) and state.ecology_view().carriers.is_empty(), "Only arrival delivers the trace, once")
	var e: Dictionary = state.ecology_view().signals.values()[0]
	check(e.expires == e.created + VesselSettings.new().signal_lifetime_ticks, "Packet delivery cannot refresh original signal age")
	# Storm admission preserves source footprint, conditions, access and probability.
	var damage := func(_at: Vector2i) -> Dictionary: return {"overload": 80}
	check(VesselEcology.storm_eligible(source, {}, damage, func(_at: Vector2i) -> bool: return false, 80), "Nine eligible local tiles permit admission")
	check(not VesselEcology.storm_eligible(source, {}, damage, Callable(), 80), "Unknown access protection rejects admission")
	check(not VesselEcology.storm_eligible(source, {}, damage, func(at: Vector2i) -> bool: return at == source, 80), "A protected cell prevents storm admission")
	var low := {AffinityImprint.key(source): 79}
	check(not VesselEcology.storm_eligible(source, low, damage, func(_at: Vector2i) -> bool: return false, 80), "A single ineligible tile prevents admission")
	state = fixture(80, 600)
	state.set_environment(source, {"overload": -10})
	for i in range(15): step(state, empty_candidates, true, true)
	check(state.environment_view(source, {"overload": 0}).overload == -10 and int(group(state).storm_until) == 0, "Protected/restorative cells cannot be overwritten by swarm discharge")
	check(VesselSettings.new().storm_chance_percent == 0, "Production storms remain disabled pending the separate storm behavior design")
	state = fixture(0)
	state.set_environment(source, {"overload": 12})
	for i in range(3): step(state)
	check(group(state).state == "recovering" and int(group(state).until) - int(group(state).since) == VesselSettings.new().recovery_ticks, "An unsupplied swarm takes the full recovery interval instead of a shortened response interval")
	await class_checks()
	performance_probe()
	await presentation_checks()
	print("VESSEL ECOLOGY: %d checks, %d failures." % [checks, failures])
	quit(1 if failures else 0)

func class_checks() -> void:
	var appearance := VegetationAppearance.new()
	for category: String in FloraTraits.CLASSES:
		var model := appearance.model_for(category)
		check(model != null and preload("res://scripts/scenery/nature_art.gd").parts(model).supported, "Each plant class has a supported supplied model or portable fallback")
	appearance.warden_model = "res://assets/local/not_installed.fbx"
	check(appearance.model_for("warden") == VegetationAppearance.FALLBACK.warden, "Absent local artwork falls back without changing the ecology")
	var classes := {}
	for y in range(-8, 9):
		for x in range(-8, 9):
			var row := definition(source + Vector2i(x, y))
			var traits := FloraTraits.describe(SEED, row)
			if not str(traits["class"]).is_empty() and (not classes.has(traits["class"]) or VesselEcology.cell(classes[traits["class"]]).distance_squared_to(source) > VesselEcology.cell(row).distance_squared_to(source)): classes[traits["class"]] = row
	check(classes.size() == 3, "All three independent plant classes are admitted deterministically")
	for category: String in classes:
		var row: Dictionary = classes[category]
		var state := fixture()
		state.admit_flora([row])
		var snapshot := state.snapshot()
		snapshot.flora.nodes[row.id].energy = 30.0
		snapshot.flora.absorbed += 30.0
		state = ExpeditionState.restore(snapshot, SEED)
		state.set_flora_active([row.id])
		state.set_environment(VesselEcology.cell(row), {"overload": 10})
		step(state)
		if category == "mender":
			check(state.environment_view(VesselEcology.cell(row), {"overload": 0}).overload == 9 and state.flora_reading(VesselEcology.cell(row)).activity == "repairing", "Mender repair is paid and reported only when active")
		check(state.flora_reading(VesselEcology.cell(row)).traits["class"] == category, "Class is independent of ambient affinity")
		check(ExpeditionState.valid_snapshot(state.snapshot(), SEED), "Class actions preserve energy accounting")
		state = fixture(80, 600)
		state.admit_flora([row])
		snapshot = state.snapshot()
		snapshot.flora.nodes[row.id].energy = 100.0
		snapshot.flora.absorbed += 100.0
		state = ExpeditionState.restore(snapshot, SEED)
		state.set_flora_active([AffinityImprint.key(source), AffinityImprint.key(tree), row.id])
		for i in range(15): step(state)
		if category == "warden": check(state.flora_reading(VesselEcology.cell(row)).activity == "protecting", "A supplied Warden pays to intercept nearby Vessel discharges")
		if category == "regulator": check(group(state).state == "recovering", "A supplied Regulator helps the response settle instead of escalating")
		check(ExpeditionState.valid_snapshot(state.snapshot(), SEED), "Specialist and swarm expenditure reconcile together")
		var traits := FloraTraits.describe(SEED, row)
		check(not FloraTraits.appearance(traits, "idle").contains("pulses") and not FloraTraits.appearance(traits, "idle").contains("Arriving energy"), "Idle Observe text does not invent active specialist effects")
	var state := fixture(0)
	var snapshot := state.snapshot()
	snapshot.flora.policy.refill = 4.0
	state = ExpeditionState.restore(snapshot, SEED)
	state.admit_flora([classes.mender])
	state.set_flora_active([AffinityImprint.key(source), AffinityImprint.key(tree), classes.mender.id])
	step(state)
	check(state.flora_reading(source).energy > 0 and state.flora_reading(tree).energy == 0 and state.flora_reading(VesselEcology.cell(classes.mender)).energy == 0, "Grass starts classified circulation; trees and specialists require supplied energy")

func performance_probe() -> void:
	var state := ExpeditionState.new(SEED)
	var policy := VastraSettings.new().plant_parameters()
	policy.repair_points = 0
	state.configure_flora(policy)
	state.configure_ecology(VesselSettings.new().parameters())
	var definitions: Array[Dictionary] = []
	var ids: Array[String] = []
	for y in range(36):
		for x in range(36):
			var row := definition(Vector2i(x, y), "tree" if x % 5 == 0 and y % 5 == 0 else "plant")
			definitions.append(row)
			ids.append(row.id)
	state.admit_flora(definitions)
	state.set_flora_active(ids)
	var samples: Array[float] = []
	for i in range(100):
		var started := Time.get_ticks_usec()
		step(state)
		samples.append(float(Time.get_ticks_usec() - started) / 1000.0)
	samples.sort()
	check(state.active_vessels().size() == 9 and ExpeditionState.valid_snapshot(state.snapshot(), SEED), "A 1,296-node, nine-swarm simulation remains bounded and save-valid")
	var file := FileAccess.open("res://artifacts/vessel-response/performance.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"nodes": 1296, "groups": 9, "ticks": 100, "p95_tick_ms": samples[94], "p99_tick_ms": samples[98], "maximum_tick_ms": samples[-1]}, "\t"))

func presentation_checks() -> void:
	var scene: Node3D = load("res://scenes/world_3d.tscn").instantiate()
	root.add_child(scene)
	var world: Node2D = scene.world
	world.smoke_mode = true
	world.new_expedition(SEED)
	scene.process_mode = Node.PROCESS_MODE_DISABLED
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280, 800)
	for i in range(10000):
		world.prepare_flora(Time.get_ticks_usec() + 2000)
		if world.flora_catalog.pending.is_empty(): break
	var state: ExpeditionState = world.persistent_state
	state.activity_advanced.disconnect(world.advance_environment)
	step(state)
	var admitted := state.active_vessels()
	check(not admitted.is_empty(), "The actual terrain catalogue admits resident swarms without scenery-based spawning")
	if admitted.is_empty():
		scene.free()
		return
	admitted.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return VesselEcology.cell(a).distance_squared_to(world.cell) < VesselEcology.cell(b).distance_squared_to(world.cell))
	var at := VesselEcology.cell(admitted[0])
	var active_ids: Array[String] = world.flora_catalog.active_ids()
	var saved := state.snapshot()
	var home: String = admitted[0].home
	saved.flora.absorbed += 80.0 - float(saved.flora.nodes[home].energy)
	saved.flora.nodes[home].energy = 80.0
	saved.flora.policy.refill = 0.0
	state = ExpeditionState.restore(saved, SEED)
	world.replace_persistent_state(state)
	state.activity_advanced.disconnect(world.advance_environment)
	state.set_flora_active(active_ids)
	state.set_environment(at, {"overload": 12}) # Declared disturbance; no user save is touched.
	world.cell = at
	step(state)
	var view: Node3D = scene.vessel_swarms
	view._process(0.0)
	check(view.batch is GPUParticles3D and view.batch.visible and view.batch.member_count == 24 and view.picks.size() >= 1, "The actual game scene renders bounded particle swarms with group targets")
	check(view.batch.external_clock and is_equal_approx(view.batch.elapsed, state.activity_seconds()), "Live particles consume the saved active clock")
	check(view.batch.draw_passes == 2 and view.batch.amount == 24 * (view.batch.trail_samples + 1), "Live orbs share the glow/trail and radial-mask particle passes")
	check(not view.plants.is_empty(), "The local ecology display retains specialist activity cues")
	var scenery_before := {}
	var living_owners := 0
	for coord: Vector2i in scene.solid_chunks:
		var chunk: Node3D = scene.solid_chunks[coord]
		scenery_before[coord] = chunk.cosmetic_records.duplicate(true)
		living_owners+=chunk.living_sources.size()
		for record: Dictionary in chunk.cosmetic_records:
			check(record.patch!="flora_specialist","Retired specialist skins are not reintroduced")
			if record.get("living",false): check(chunk.living_sources.has(record.cell),"Live plant bodies retain their canonical source before local activity")
	check(living_owners>0,"Actual chunks own plant presentation before local activity; specialist presence is not required")
	var previous_cell: Vector2i = world.cell
	world.cell += Vector2i(20, 0)
	view._process(0.0)
	var scenery_unchanged := true
	for coord: Vector2i in scenery_before:
		scenery_unchanged = scenery_unchanged and scene.solid_chunks[coord].cosmetic_records == scenery_before[coord]
	check(scenery_unchanged, "Changing the player's local activity radius cannot replace or remove streamed plant bodies")
	world.cell = previous_cell
	view._process(0.0)
	var before := state.snapshot()
	scene.camera.rotate_y(0.3)
	view._process(10.0)
	check(state.snapshot() == before, "Render frames and camera movement cannot feed or advance swarms")
	check(is_equal_approx(view.batch.elapsed, state.activity_seconds()), "Render delta cannot advance particle motion while the shared clock is held")
	world.inspected_cell = at
	world.inspected_subject = "Vessel swarm"
	world.inspected_appearance = "Observe"
	world.describe_cell(at)
	check(world.inspection_card.appearance.text == VesselEcology.observe(state.vessel_reading(at)), "Observe reads the same activity as the visible swarm")
	world.inspection_card.show_appearance("")
	world.inspection_card.more.button_pressed = true
	check(world.inspection_card.details_label.text.contains("Swarm activity: Investigating") and world.inspection_card.readings.vastra.label.text == "Swarm reserve", "Details distinguishes swarm energy and state from ambient concentration")
	var pick: Dictionary = {}
	for candidate: Dictionary in view.picks:
		if candidate.subject == "Vessel swarm" and candidate.cell == at: pick = candidate; break
	var hit: Dictionary = view.pick(pick.center + Vector3(0, 2, 0), Vector3.DOWN, 10)
	check(not hit.is_empty() and hit.subject == "Vessel swarm", "Picking targets the group without individual particle precision")
	for i in range(10): step(state)
	view._process(0)
	check(view.warning.autowrap_mode == TextServer.AUTOWRAP_OFF and view.warning.size.x > 100, "Actual discharge warning has a readable single-line width")
	world.inspected_appearance = "Observe"
	world.describe_cell(at)
	check(world.inspection_card.appearance.text == VesselEcology.observe(state.vessel_reading(at)), "An open Observe card follows response state changes")
	check(ExpeditionState.valid_snapshot(state.snapshot(), SEED), "The populated canonical terrain, signals and swarms remain save-valid")
	if "--capture" in OS.get_cmdline_user_args():
		for i in range(3): await process_frame
		var center: Vector3 = pick.center
		scene.camera.position = center + Vector3(3.5, 2.5, 3.5)
		scene.camera.look_at(center)
		for i in range(3): await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://artifacts/vessel-response/connected.png")
	scene.free()
	await process_frame
