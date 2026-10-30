extends SceneTree
## Focused lab-only journey. No world/expedition initialization or full suite.
var checks := 0
var failures := 0

func _initialize() -> void:
	run.call_deferred()
	create_timer(45).timeout.connect(func(): quit(1))

func check(ok: bool, message: String) -> void:
	checks+=1
	if not ok:
		failures+=1
		push_error(message)

func run() -> void:
	root.size=Vector2i(1440,960)
	var lab: Node3D=load("res://scenes/vastra_particle_lab.tscn").instantiate()
	root.add_child(lab)
	lab.set_process(false)
	var nodes: Node3D=lab.plant_nodes
	check(nodes.rows.size()==5,"Five visible plant/tree nodes exist")
	for state in range(6):
		lab.apply_preset(state)
		check(is_equal_approx(lab.particles.amount_ratio,float(lab.VALUES[state][0])/100.0),"Ambient state applies independently")
	lab.apply_preset(1)
	lab.particles.hide()
	# Keep transaction fixtures independent of the owner art baseline.
	nodes.controls["Transfer energy"].value=40.0
	nodes.controls["Travel speed"].value=1.2
	for scenario in range(5):
		nodes.scenario.select(scenario)
		nodes.configure_scenario(scenario)
		var total: float=nodes.total
		nodes.play_scenario()
		check(not nodes.flights.is_empty(),"Interaction %d emits a packet" % scenario)
		var target: int=nodes.flights[0].target
		var before: float=nodes.rows[target].energy
		nodes.advance(0.01)
		check(is_equal_approx(nodes.rows[target].energy,before),"Receiver is not credited before arrival")
		var steps := 0
		while (not nodes.flights.is_empty() or nodes.relay_pending) and steps<400:
			nodes.advance(0.1)
			check(absf(nodes.stored_total()-total)<0.001,"Stored + in-flight energy is conserved")
			steps+=1
		check(steps<400,"Interaction settles with no lingering packet")
		check(nodes.received== (2 if scenario in [1,2] else 1),"Expected arrivals occur")
		if scenario==3: check(nodes.rows[2].roots==40.0,"Full receiving tree retains overflow in roots")
		if scenario==4: check(nodes.rows[2].roots==40.0,"Root return debits the root reserve")
	# Full plants reject additional root energy without deleting it.
	nodes.scenario.select(4)
	nodes.configure_scenario(4)
	nodes.rows[4].energy=100.0
	nodes.total=nodes.stored_total()
	nodes.play_scenario()
	for step in range(120): nodes.advance(0.1)
	check(nodes.flights.is_empty() and nodes.rows[2].roots==80.0,"Full ground plant accepts no root return until it has room")
	nodes.scenario.select(0)
	nodes.configure_scenario(0)
	nodes.play_scenario()
	lab.frozen=true
	var clock: float=nodes.flights[0].clock
	lab._process(1.0)
	check(nodes.flights[0].clock==clock,"Lab pause freezes transfers")
	lab.frozen=false
	lab.reset_motion()
	check(nodes.flights.is_empty() and not nodes.relay_pending,"Reset clears packets and pending relay")
	# Useful real-scene render: plants, node readings and a packet halfway across.
	nodes.scenario.select(2)
	nodes.configure_scenario(2)
	nodes.play_scenario()
	nodes.advance(1.2)
	for frame in range(12): await process_frame
	if "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		DirAccess.make_dir_recursive_absolute("res://artifacts/vastra-particle-lab")
		root.get_texture().get_image().save_png("res://artifacts/vastra-particle-lab/plant-transfers.png")
	print("VASTRA LAB: %d checks, %d failures" % [checks,failures])
	lab.queue_free()
	await process_frame
	quit(1 if failures else 0)
