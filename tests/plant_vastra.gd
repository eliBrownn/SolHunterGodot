extends SceneTree
var checks := 0
var failures := 0
func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)
func _initialize() -> void:
	run.call_deferred()
func definition(at: Vector2i, kind: String) -> Dictionary:
	return {"id": AffinityImprint.key(at), "cell": [at.x, at.y], "kind": kind}
func definitions() -> Array[Dictionary]:
	return [definition(Vector2i.ZERO, "plant"), definition(Vector2i(1, 0), "tree"), definition(Vector2i(2, 0), "tree")]
func candidates(at: Vector2i, reach: float) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for row in definitions():
		if row.kind == "tree" and row.id != AffinityImprint.key(at) and at.distance_to(Vector2i(row.cell[0], row.cell[1])) <= reach: result.append(row)
	return result
func empty_candidates(_at: Vector2i, _reach: float) -> Array[Dictionary]:
	return []
func charged(energy: Dictionary, refill: float = 0.0) -> ExpeditionState:
	var state := ExpeditionState.new(17)
	var policy := VastraSettings.new().plant_parameters()
	policy.refill = refill
	state.configure_flora(policy)
	state.admit_flora(definitions())
	var data := state.snapshot()
	for id: String in energy:
		data.flora.nodes[id].energy = float(energy[id])
		data.flora.absorbed += float(energy[id])
	return ExpeditionState.restore(data, 17)
func environment(state: ExpeditionState) -> Callable:
	return func(at: Vector2i) -> Dictionary: return state.environment_view(at, {"concentration": 50, "overload": 0})
func step(state: ExpeditionState, resolver: Callable = candidates) -> void:
	state.advance_time(ExpeditionContract.ACTIVITY_INTERVAL)
	state.advance_flora(resolver, environment(state))
func balance(state: ExpeditionState) -> float:
	var data := state.flora_view()
	var value := float(data.spent)
	for row: Dictionary in data.nodes.values(): value += float(row.energy) + float(row.roots)
	for flight: Dictionary in data.flights: value += float(flight.amount)
	for amount in data.fed.values(): value += float(amount)
	return value - float(data.absorbed)
func run() -> void:
	var state := charged({"0:0": 99})
	state.set_flora_active(["0:0"])
	step(state)
	check(state.flora_view().flights.is_empty(), "Below 100 there is no visible-transfer event")
	state = charged({"0:0": 100})
	state.set_flora_active(["0:0"])
	step(state)
	var data := state.flora_view()
	check(data.flights.size() == 1 and data.flights[0].amount == 100 and data.nodes["0:0"].energy == 0, "A full plant debits one conserved 100-unit packet")
	var flight: Dictionary = data.flights[0]
	check(data.nodes[flight.target].energy == 0 and flight.arrival > flight.sent, "The recipient receives no energy before the head's finite arrival")
	var once := state.snapshot()
	state.advance_flora(candidates, environment(state))
	check(state.snapshot() == once, "Repeated service in the same tick cannot duplicate an emission")
	var restored := ExpeditionState.restore(JSON.parse_string(JSON.stringify(once)), 17)
	check(restored != null and restored.flora_view().flights == data.flights, "Saving mid-flight preserves the exact pending delivery")
	restored.set_flora_active(["0:0"])
	while restored.activity_tick() < int(flight.arrival): step(restored)
	check(restored.flora_view().nodes[flight.target].energy == 100 and restored.flora_view().flights.is_empty(), "Arrival credits the destination exactly once even when it is not active")
	step(restored)
	check(restored.flora_view().nodes[flight.target].energy == 100 and absf(balance(restored)) < 0.001, "Later ticks cannot repeat a completed delivery")
	restored.set_flora_active([flight.target])
	step(restored)
	check(restored.flora_view().flights.size() == 1 and restored.flora_view().flights[0].source == flight.target, "A full tree relays its reserve to another tree")
	check(absf(balance(restored)) < 0.001, "Relaying conserves stored plus in-transit energy")
	var ids: Array[String] = ["0:0", "1:0", "2:0"]
	restored.set_flora_active(ids)
	for i in range(40):
		step(restored)
		check(PlantVastra.valid(restored.flora_view(), restored.activity_tick()) and absf(balance(restored)) < 0.001, "Cycles remain finite, valid and energy-conserving")
	var source := definitions()[0]
	var trees: Array = [definitions()[1].duplicate(true), definitions()[2].duplicate(true)]
	trees[0]["energy"] = 0
	trees[1]["energy"] = 1000
	var counts := {"1:0": 0, "2:0": 0}
	for serial in range(200):
		var selected := PlantVastra.choose_target(source, trees, 17, serial)
		counts[selected.id] += 1
		var changed := trees.duplicate(true)
		changed[0].energy = 1000
		changed[1].energy = 0
		changed.reverse()
		check(PlantVastra.choose_target(source, changed, 17, serial).id == selected.id, "Need, fullness and catalogue order cannot bias the target selection")
	check(counts["1:0"] > 50 and counts["2:0"] > 50, "Both nearby trees are regularly selected, including the already-full tree")
	state = charged({"0:0": 100, "1:0": 100})
	state.set_flora_active(["0:0"])
	var already_full := func(_at: Vector2i, _reach: float) -> Array[Dictionary]: return [definition(Vector2i(1, 0), "tree")]
	step(state, already_full)
	var full_flight: Dictionary = state.flora_view().flights[0]
	while state.activity_tick() < int(full_flight.arrival): step(state, already_full)
	check(state.flora_view().nodes["1:0"].energy == 100 and state.flora_view().nodes["1:0"].roots == 100 and absf(balance(state)) < 0.001, "An already-full destination expels excess to its roots without exceeding its reserve cap or losing energy")
	state.set_flora_active(["1:0"])
	step(state)
	check(state.flora_view().nodes["1:0"].energy == 0 and state.flora_view().nodes["1:0"].roots == 100 and state.flora_view().flights.size() == 1, "A full tree can relay its own reserve while expelled root stock remains separately conserved")
	state = charged({"0:0": 100})
	state.set_flora_active(["0:0"])
	step(state, empty_candidates)
	check(state.flora_view().nodes["0:0"].energy == 100 and state.flora_view().flights.is_empty(), "A plant with no eligible tree keeps its reserve rather than losing it")
	state = charged({"1:0": 100})
	state.set_environment(Vector2i(1, 0), {"overload": 3})
	state.set_flora_active(["1:0"])
	step(state)
	check(state.flora_view().nodes["1:0"].energy == 90 and state.flora_view().spent == 10 and state.environment_view(Vector2i(1, 0), {"overload": 0}).overload == 2, "Energy pays for real local ecological-overload repair before circulation")
	check(state.flora_view().flights.is_empty() and absf(balance(state)) < 0.001, "Energy spent healing cannot also be transferred")
	state = charged({"1:0": 100})
	state.set_environment(Vector2i(1, 0), {"overload": -25})
	state.set_flora_active(["1:0"])
	step(state)
	check(state.environment_view(Vector2i(1, 0), {"overload": 0}).overload == -25 and state.flora_view().spent == 0, "Plant repair preserves beneficial negative overload")
	state = charged({}, 4.0)
	state.set_flora_active(["0:0"])
	step(state)
	check(is_equal_approx(state.flora_view().nodes["0:0"].energy, 1.5) and is_equal_approx(state.flora_view().absorbed, 1.5), "Plants absorb gradually from the separate local ambient concentration")
	var paused := state.snapshot()
	state.advance_flora(candidates, environment(state))
	check(state.snapshot() == paused, "No active-time advance means no refill or transfer")
	state.set_flora_active([])
	for i in range(20): step(state)
	state.set_flora_active(["0:0"])
	step(state)
	check(is_equal_approx(state.flora_view().nodes["0:0"].energy, 3.0), "Reactivation retains reserves without granting offline or inactive-area charge")
	var detached := state.flora_view()
	detached.nodes["0:0"].energy = 999
	check(state.flora_view().nodes["0:0"].energy < 999, "Presentation reads cannot alter stored plant reserves")
	var corrupt := state.snapshot()
	corrupt.flora.nodes["0:0"].energy += 1
	check(ExpeditionState.restore(corrupt, 17) == null, "Corrupt energy accounting is rejected before state replacement")
	corrupt = state.snapshot()
	corrupt.flora.nodes["0:0"].energy = NAN
	check(ExpeditionState.restore(corrupt, 17) == null, "Nonfinite plant energy cannot enter a save")
	corrupt = state.snapshot()
	corrupt.flora.serial += 1
	check(ExpeditionState.restore(corrupt, 17) == null, "A corrupted emission serial cannot reroll future recipients or invent transfer history")
	var world := WorldTerrain.new(17)
	var a := FloraCatalog.new(world)
	var b := FloraCatalog.new(world)
	a.request(Vector2i.ZERO, 0, 1.0)
	b.request(Vector2i.ZERO, 0, 1.0)
	check(a.trees_near(Vector2i.ZERO, 1.0) == null, "An incomplete neighborhood never supplies a biased partial target list")
	while not a.pending.is_empty(): a.advance(Time.get_ticks_usec() + 2000)
	while not b.pending.is_empty(): b.advance(Time.get_ticks_usec() + 20000)
	check(a.regions == b.regions and a.active_ids() == b.active_ids(), "Canonical flora admission is independent of render data and preparation slice size")
	check(a.trees_near(Vector2i.ZERO, 1.0) is Array, "Complete neighborhoods provide stable target candidates")
	root_and_feeding_checks()
	await presentation_journey()
	print("PLANT VASTRA: %d checks, %d failures." % [checks, failures])
	quit(0 if failures == 0 else 1)

func root_and_feeding_checks() -> void:
	var state := charged({})
	var fixture := SolSpeciesDefinition.new()
	fixture.species_id = "fixture_feeder"
	fixture.lineage_id = "fixture_feeder"
	fixture.class_id = "fixture_class"
	var eater := state.register_individual(fixture, Vector2i(1, 0), "earth")
	var distant := state.register_individual(fixture, Vector2i(30, 30), "earth")
	var snapshot := state.snapshot()
	snapshot.flora.nodes["1:0"].roots = 20.0
	snapshot.flora.nodes["2:0"].roots = 20.0
	snapshot.flora.absorbed = 40.0
	state = ExpeditionState.restore(snapshot, 17)
	check(state != null, "Expelled root stock has a valid saved conservation record")
	state.set_flora_active(["1:0", "2:0"])
	step(state, empty_candidates)
	check(is_equal_approx(state.sol_vastra_food(eater), 3.0) and state.sol_vastra_food(distant) == 0, "Only nearby Sols eat root excess, with one per-Sol rate cap shared across trees")
	check(absf(balance(state)) < 0.001 and state.flora_view().nodes["1:0"].energy == 0, "Food is debited from excess rather than a tree's ordinary reserve or invented energy")
	var paused := state.snapshot()
	state.advance_flora(empty_candidates, environment(state))
	check(state.snapshot() == paused, "The same active tick cannot feed a Sol twice")
	state.set_flora_active([])
	step(state, empty_candidates)
	check(state.sol_vastra_food(eater) == 3.0, "Inactive root stocks grant no offline or inactive-area food")
	var resumed := ExpeditionState.restore(JSON.parse_string(JSON.stringify(state.snapshot())), 17)
	check(resumed != null and resumed.sol_vastra_food(eater) == 3.0 and absf(balance(resumed)) < 0.001, "Saved Sol meals and root stock survive JSON without being credited twice")
	var corrupt := state.snapshot()
	corrupt.flora.fed[eater] += 1.0
	check(ExpeditionState.restore(corrupt, 17) == null, "Manufactured food fails conservation validation")
	corrupt = state.snapshot()
	corrupt.flora.fed["unknown_sol"] = 0.0
	check(ExpeditionState.restore(corrupt, 17) == null, "A feeding record must name an admitted persistent Sol")
	corrupt = state.snapshot()
	corrupt.version = 19
	check(ExpeditionState.restore(corrupt, 17) == null, "Older development snapshots are rejected rather than silently reinterpreted")
	state = charged({"0:0": 95})
	snapshot = state.snapshot()
	snapshot.flora.nodes["1:0"].roots = 30.0
	snapshot.flora.absorbed += 30.0
	snapshot.flora.policy.refill = 100.0
	state = ExpeditionState.restore(snapshot, 17)
	state.set_flora_active(["1:0", "0:0"])
	var plants := func(_at: Vector2i, _reach: float) -> Array[Dictionary]: return [definition(Vector2i.ZERO, "plant")]
	state.advance_time(ExpeditionContract.ACTIVITY_INTERVAL)
	state.advance_flora(empty_candidates, environment(state), plants)
	var flights: Array = state.flora_view().flights
	check(flights.size() == 1 and flights[0].root and flights[0].amount == 5.0, "Root strands carry only the actual spare capacity of a nearby plant")
	if flights.is_empty(): return
	var flight: Dictionary = flights[0]
	check(state.flora_view().nodes["0:0"].energy == 95 and state.flora_view().nodes["1:0"].roots == 25, "Root energy leaves immediately but reaches its destination only on arrival")
	var loaded := ExpeditionState.restore(JSON.parse_string(JSON.stringify(state.snapshot())), 17)
	check(loaded != null and loaded.flora_view().flights == flights, "Partial root packets preserve their exact amount and destination in flight")
	corrupt = state.snapshot()
	corrupt.flora.flights[0].arrival += 1
	check(ExpeditionState.restore(corrupt, 17) == null, "A saved packet cannot silently change its physical source-to-destination timing")
	while state.activity_tick() < int(flight.arrival) - 1:
		state.advance_time(ExpeditionContract.ACTIVITY_INTERVAL)
		state.advance_flora(empty_candidates, environment(state), plants)
		check(state.flora_view().nodes["0:0"].energy == 95, "Incoming root capacity is reserved against ambient refill until the head arrives")
	state.set_flora_active([])
	step(state, empty_candidates)
	check(state.flora_view().nodes["0:0"].energy == 100 and absf(balance(state)) < 0.001, "The complete root packet reaches point B once, without disappearance or reserve overflow")
	step(state, empty_candidates)
	check(state.flora_view().nodes["0:0"].energy == 100, "A root packet cannot be delivered a second time")
	var species: Resource = load("res://resources/sol_species/crown_ear.tres")
	state = charged({})
	check(state.choose_starter(species.battle_profile("air"), 0), "Feeding admits a real selected field companion")
	snapshot = state.snapshot()
	snapshot.flora.nodes["1:0"].roots = 2.0
	snapshot.flora.absorbed = 2.0
	state = ExpeditionState.restore(snapshot, 17)
	state.set_flora_active(["1:0"])
	state.advance_time(ExpeditionContract.ACTIVITY_INTERVAL)
	state.advance_flora(empty_candidates, environment(state), Callable(), Vector2i(1, 0))
	check(state.sol_vastra_food(state.active_sol_view().id) == 2.0 and state.flora_view().nodes["1:0"].roots == 0 and absf(balance(state)) < 0.001, "The selected companion eats only available excess and cannot consume a negative balance")
	state = charged({"0:0": 100, "2:0": 100})
	state.set_flora_active(["0:0", "2:0"])
	var same_tree := func(_at: Vector2i, _reach: float) -> Array[Dictionary]: return [definition(Vector2i(1, 0), "tree")]
	step(state, same_tree)
	snapshot = state.snapshot()
	snapshot.flora.policy.work_limit = 1
	state = ExpeditionState.restore(snapshot, 17)
	state.set_flora_active([])
	var scheduled: int = state.flora_view().flights[0].arrival
	while state.activity_tick() < scheduled: step(state)
	var waiting: Array[Dictionary] = state.flora_transfers().filter(func(row: Dictionary) -> bool: return row.pending)
	check(waiting.size() == 1 and state.flora_view().nodes["1:0"].energy == 100, "An arrival-work limit retains the other real packet at its destination")
	if not waiting.is_empty():
		var waiting_id: int = waiting[0].id
		step(state)
		var completed: Array[Dictionary] = state.flora_transfers().filter(func(row: Dictionary) -> bool: return row.id == waiting_id)
		check(completed.size() == 1 and not completed[0].pending and completed[0].visual_sent + completed[0].arrival - completed[0].sent == state.activity_tick(), "A delayed packet starts its clearing tail only after the real destination credit")
		check(state.flora_view().nodes["1:0"].roots == 100 and absf(balance(state)) < 0.001, "Simultaneous packets credit once and expel the exact received excess")

func capture_scene(label: String) -> void:
	if not OS.get_cmdline_user_args().has("--capture") and not OS.get_cmdline_user_args().has("--capture-trajectories"): return
	for i in range(3): await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://artifacts/plant-vastra")
	root.get_texture().get_image().save_png("res://artifacts/plant-vastra/" + label + ".png")

func presentation_journey() -> void:
	var Currents = preload("res://scripts/presentation/vastra_currents.gd")
	var scene: Node3D = load("res://scenes/world_3d.tscn").instantiate()
	root.add_child(scene)
	var world: Node2D = scene.world
	world.smoke_mode = true
	world.new_expedition(17)
	scene.process_mode = Node.PROCESS_MODE_DISABLED
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280, 800)
	var currents: Node3D
	for child in scene.get_children():
		if child.get_script() == Currents: currents = child
	check(currents != null and not currents.study_mode and currents.network_edges.is_empty(), "Live play has no autonomous cosmetic transfers before plants charge")
	var plants: Array[Dictionary] = []
	var trees: Array[Dictionary] = []
	for chunk in scene.solid_chunks.values():
		for asset: Dictionary in chunk.living_sources.values():
			var at: Vector2i = asset.cell
			var kind: String = world.terrain.flora_kind(at, world.terrain.sample(at))
			if kind == "tree" and asset.kind == "tree": trees.append(asset)
			elif kind == "plant" and "grass" in asset.id: plants.append(asset)
	plants.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return Vector2(a.cell).distance_squared_to(world.camera.position / 32.0) < Vector2(b.cell).distance_squared_to(world.camera.position / 32.0))
	var source: Dictionary = {}
	var target: Dictionary = {}
	for plant in plants:
		for tree in trees:
			if Vector2(plant.cell).distance_to(Vector2(tree.cell)) <= 3.0:
				source = plant
				target = tree
				break
		if not source.is_empty(): break
	check(not source.is_empty(), "The connected journey uses actual nearby rendered grass and tree assets")
	if source.is_empty():
		scene.free()
		return
	for i in range(10000):
		world.prepare_flora(Time.get_ticks_usec() + 2000)
		if world.flora_catalog.pending.is_empty(): break
	check(world.flora_catalog.pending.is_empty() and not world.persistent_state.flora_view().nodes.is_empty(), "The normal world controller admits canonical flora within bounded preparation slices")
	check(PlantVastra.valid(world.persistent_state.flora_view(), world.persistent_state.activity_tick()), "Canonical world admission creates a valid zero-energy ledger")
	var admitted_before: Dictionary = world.persistent_state.snapshot()
	var camera_before: Transform3D = scene.camera.transform
	scene.camera.rotate_y(0.5)
	world.prepare_flora(Time.get_ticks_usec() + 2000)
	check(world.persistent_state.snapshot() == admitted_before, "Changing the camera cannot change admitted reserves or target readiness")
	scene.camera.transform = camera_before
	var source_id := AffinityImprint.key(source.cell)
	var target_id := AffinityImprint.key(target.cell)
	var live_definitions: Array[Dictionary] = [definition(source.cell, "plant"), definition(target.cell, "tree")]
	world.persistent_state.admit_flora(live_definitions)
	var data: Dictionary = world.persistent_state.snapshot()
	data.flora.nodes[source_id].energy = 99.0
	data.flora.absorbed = 99.0
	data.flora.policy.refill = 4.0
	var state := ExpeditionState.restore(data, 17)
	world.replace_persistent_state(state)
	world.state_replaced.emit(state)
	state.activity_advanced.disconnect(world.advance_environment)
	state.set_flora_active([source_id])
	currents._process(0.6)
	check(currents.network_edges.is_empty(), "The preserved renderer emits nothing at reserve 99")
	world.inspected_cell = source.cell
	world.describe_cell(source.cell)
	world.inspection_card.more.button_pressed = true
	check(is_equal_approx(world.inspection_card.readings.vastra.bar.value, 99.0) and world.inspection_card.readings.vastra.label.text == "Vastra reserve", "Object Details shows stored energy rather than the fixed ambient concentration")
	await capture_scene("reserve-99")
	var target_definition := definition(target.cell, "tree")
	var resolver := func(_at: Vector2i, _reach: float) -> Array[Dictionary]: return [target_definition]
	var flights: Array = []
	for i in range(16):
		step(state, resolver)
		flights = state.flora_view().flights
		if not flights.is_empty(): break
	check(flights.size() == 1, "Ambient refill crosses 100 and creates a real packet in the live scene")
	world.inspect_mouse()
	check(is_equal_approx(world.inspection_card.readings.vastra.bar.value, state.flora_reading(source.cell).energy) and world.inspection_card.readings.vastra.bar.value < 99.0, "An open Details bar updates downward as the source emits its packet")
	if flights.is_empty():
		scene.free()
		return
	var reserve_after_send: float = world.inspection_card.readings.vastra.bar.value
	step(state, resolver)
	world.inspect_mouse()
	check(world.inspection_card.readings.vastra.bar.value > reserve_after_send and is_equal_approx(world.inspection_card.readings.vastra.bar.value, state.flora_reading(source.cell).energy), "An open Details bar rises again as the source absorbs more energy")
	currents._process(0.1)
	currents.finish_transition()
	currents.sync_wisps()
	check(currents.network_edges.size() == 1 and currents.network_edges[0].flight.id == flights[0].id, "A visible strand is tied to the conserved packet ID")
	if currents.tuning.particle_filaments!=null and currents.tuning.particle_filaments.enabled:
		var renderer: Node3D=currents.filament_renderer
		check(renderer.layers.size()==1,"Game uses one GPU layer for the actual conserved transfer")
		check(not currents.batch.visible and not currents.wisp_batch.visible,"Particle mode replaces the legacy carrier without double rendering")
		var layer: Dictionary=renderer.layers.values()[0]
		var prior: Dictionary=state.snapshot()
		var allocations: int=renderer.created
		var at: float=layer.motion.get_shader_parameter("elapsed")
		for i in range(5): renderer.sync(currents)
		check(renderer.created==allocations,"Repeated synchronization retains the same GPU pool")
		check(layer.motion.get_shader_parameter("elapsed")==at,"No active-clock advance freezes packet travel")
		check(state.snapshot()==prior,"GPU rendering cannot alter the ecological ledger")
		var normal: float=currents.tuning.particle_filaments.visibility
		currents.tuning.particle_filaments.visibility=0
		renderer.sync(currents)
		check(not layer.node.visible,"Zero particle visibility fully hides refraction and geometry")
		currents.tuning.particle_filaments.visibility=normal
		currents.tuning.particle_filaments.enabled=false
		currents.refresh()
		check(currents.batch.visible and not layer.node.visible,"Disabling particle mode restores the legacy comparison")
		currents.tuning.particle_filaments.enabled=true
		currents.refresh()
	var edge: Dictionary = currents.network_edges[0]
	check(edge.destination_asset.cell == target.cell and edge.end_phase > edge.start_phase, "The animation leads to the tree that will receive the energy")
	check(edge.points[-1].y > world.host.ground_height(Vector2(edge.points[-1].x, edge.points[-1].z)) + 0.1 and edge.points[-1].y < target.high_anchor.y, "Plant transfers can rise into intermediate tree heights instead of staying on the floor")
	var curve_a: PackedVector3Array = currents.transfer_points(edge.points[0], edge.points[-1], 17, false)
	check(curve_a == currents.transfer_points(edge.points[0], edge.points[-1], 17, false), "Rebuilding the same transfer retains its trajectory")
	check(curve_a != currents.transfer_points(edge.points[0], edge.points[-1], 29, false), "Different transfers vary their bend rather than sharing one arch")
	check(curve_a[0] == edge.points[0] and curve_a[-1] == edge.points[-1], "Curved transfers preserve their exact source and destination attachments")
	var lateral := false
	for point: Vector3 in curve_a.slice(1, -1):
		check(point.y >= world.host.ground_height(Vector2(point.x, point.z)) + scene.vastra_settings.current_ground_clearance - 0.001, "Varied trajectories remain above terrain")
		var straight := Geometry3D.get_closest_point_to_segment(Vector3(point.x, 0, point.z), Vector3(curve_a[0].x, 0, curve_a[0].z), Vector3(curve_a[-1].x, 0, curve_a[-1].z))
		if Vector3(point.x, 0, point.z).distance_to(straight) > 0.01: lateral = true
	check(lateral, "Transfer curves also change direction horizontally")
	var flight: Dictionary = flights[0]
	var half := int((flight.sent + flight.arrival) / 2)
	while state.activity_tick() < half: step(state, resolver)
	currents._process(0.1)
	currents.finish_transition()
	currents.sync_wisps()
	var origin := Vector3(world.camera.position.x / 32.0, 0, world.camera.position.y / 32.0)
	var focus: Vector3 = edge.points[4] - origin
	var travel: Vector3 = edge.points[-1] - edge.points[0]
	var side := Vector3(-travel.z, 0, travel.x).normalized()
	scene.camera.position = focus + side * 3.0 + Vector3.UP * 1.8
	scene.camera.look_at(focus)
	if OS.get_cmdline_user_args().has("--capture") or OS.get_cmdline_user_args().has("--capture-trajectories"):
		world.hud.visible = false
		scene.view_revision += 1
		world.plan_chunks()
		# Disposable close-up: fill its actual frustum synchronously before capture,
		# rather than showing unbuilt ground from the previous camera heading.
		for coord: Vector2i in world.pending.duplicate():
			world.publish_chunk(coord)
			world.pending.erase(coord)
	var before: Dictionary = state.snapshot()
	for i in range(30): currents._process(1.0 / 60.0)
	check(state.snapshot() == before, "Rendering and mote updates cannot manufacture, spend or advance energy")
	await capture_scene("packet-in-transit")
	while state.activity_tick() < int(flight.arrival): step(state, resolver)
	check(state.flora_view().nodes[target_id].energy == 100, "The real destination receives exactly 100 when its traveling head arrives")
	world.inspected_cell = target.cell
	world.describe_cell(target.cell)
	check(is_equal_approx(world.inspection_card.readings.vastra.bar.value, 100.0), "Tree Details reflects the received packet immediately")
	currents._process(0.1)
	currents.finish_transition()
	currents.sync_wisps()
	await capture_scene("packet-arrived")
	check(PlantVastra.valid(state.flora_view(), state.activity_tick()), "The full live charge/strand/arrival journey remains save-valid")
	# Exercise the actual activity callback with a complete geographic catalogue,
	# including many simultaneous plant emissions and tree relays.
	for i in range(10000):
		world.prepare_flora(Time.get_ticks_usec() + 2000)
		if world.flora_catalog.pending.is_empty(): break
	state.activity_advanced.connect(world.advance_environment)
	for i in range(120): state.advance_time(ExpeditionContract.ACTIVITY_INTERVAL)
	var live: Dictionary = state.flora_view()
	check(live.absorbed > 100 and live.serial > 1 and not live.flights.is_empty(), "Normal active-clock service refills plants and creates real circulation without rendering")
	check(PlantVastra.valid(live, state.activity_tick()) and absf(balance(state)) < 0.01, "Concurrent active-area transfers remain save-valid and conserve energy")
	check(ExpeditionState.restore(JSON.parse_string(JSON.stringify(state.snapshot())), 17) != null, "A populated running energy network survives the real JSON save boundary")
	var save: Dictionary = ExpeditionSave.snapshot(world.terrain.world_seed, world.cell, world.visited, world.returned, world.terrain.generation_version, world.terrain.climate, state.snapshot(), world.terrain.relief, world.terrain.scenery_parameters)
	check(ExpeditionSave.validate(save), "Populated energy-network saves are validated against the authoritative flora admission rule")
	currents._process(0.6)
	currents.finish_transition()
	currents.sync_wisps()
	await capture_scene("varied-circulation")
	# A conserved root packet uses the same renderer and follows the ground outward.
	data = state.snapshot()
	data.flora.nodes[target_id].roots += 30.0
	data.flora.absorbed += 30.0 - float(data.flora.nodes[source_id].energy)
	data.flora.nodes[source_id].energy = 0.0
	state = ExpeditionState.restore(data, 17)
	world.replace_persistent_state(state)
	world.state_replaced.emit(state)
	state.activity_advanced.disconnect(world.advance_environment)
	state.set_flora_active([target_id])
	var nearby_plants := func(_at: Vector2i, _reach: float) -> Array[Dictionary]: return [definition(source.cell, "plant")]
	state.advance_time(ExpeditionContract.ACTIVITY_INTERVAL)
	state.advance_flora(empty_candidates, environment(state), nearby_plants)
	currents._process(0.6)
	currents.finish_transition()
	currents.sync_wisps()
	var root_edges: Array = currents.network_edges.filter(func(row: Dictionary) -> bool: return row.flight.root)
	check(root_edges.size() > 0, "Real expelled energy creates an outward root strand to an actual nearby plant")
	if not root_edges.is_empty():
		for point: Vector3 in root_edges[0].points.slice(1, -1):
			check(point.y - world.host.ground_height(Vector2(point.x, point.z)) < 0.1, "Root strands branch along the ground rather than from the crown")
		var root_trip: Dictionary = root_edges[-1].flight
		state.set_flora_active([])
		while state.activity_tick() < int((root_trip.sent + root_trip.arrival) / 2): step(state, empty_candidates)
		currents._process(0.6)
		currents.finish_transition()
		currents.sync_wisps()
		var root_focus: Vector3 = root_edges[0].points[4] - Vector3(world.camera.position.x / 32.0, 0, world.camera.position.y / 32.0)
		scene.camera.position = root_focus + Vector3(3, 1.8, 3)
		scene.camera.look_at(root_focus)
	await capture_scene("root-overflow")
	var root_save := ExpeditionSave.snapshot(world.terrain.world_seed, world.cell, world.visited, world.returned, world.terrain.generation_version, world.terrain.climate, state.snapshot(), world.terrain.relief, world.terrain.scenery_parameters)
	check(ExpeditionSave.validate(root_save), "A real root-transfer expedition passes the full canonical save envelope validation")

	scene.free()
	await process_frame
