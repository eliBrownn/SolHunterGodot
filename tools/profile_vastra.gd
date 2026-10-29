extends SceneTree
## Repeatable synthetic local-current CPU workload. Timings are evidence, not CI thresholds.
var tag := "current"

func _initialize() -> void:
	create_timer(90).timeout.connect(func() -> void: quit(1))
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--tag="):
			tag = argument.trim_prefix("--tag=").validate_filename()
	run.call_deferred()

func summary(samples: Array[float]) -> Dictionary:
	samples.sort()
	var total := 0.0
	for sample in samples:
		total += sample
	return {"mean_us": total / samples.size(), "p95_us": samples[ceili(samples.size() * 0.95) - 1], "max_us": samples.back()}

func run() -> void:
	var scene: Node3D = load("res://scenes/world_3d.tscn").instantiate()
	root.add_child(scene)
	var world: Node2D = scene.world
	world.smoke_mode = true
	world.new_expedition(17)
	var currents: Node3D
	for child in scene.get_children():
		if child.get_script() == preload("res://scripts/vastra_currents.gd"):
			currents = child
	if currents == null:
		push_error("Current renderer not found")
		quit(1)
		return
	currents.set_process(false)
	var original: Vector2i = world.cell
	var report := {"engine": Engine.get_version_info().string, "tag": tag, "seed": 17,
		"scope": "Synthetic current CPU calls; travel changes the sample center, not a navigated journey; no GPU/Thor claim"}
	for workload in ["stationary", "travel", "disturbed"]:
		world.cell = original
		if workload == "disturbed":
			for y in range(-4, 5):
				for x in range(-4, 5):
					world.persistent_state.set_environment(original + Vector2i(x, y), {"overload": 60 if x >= 0 else -40})
		var samples: Array[float] = []
		for frame in range(720):
			if workload == "travel":
				world.cell = original + Vector2i((frame / 6) % 40, (frame / 240) % 2)
			world.persistent_state.advance_time(1.0 / 60.0)
			var started := Time.get_ticks_usec()
			currents._process(1.0 / 60.0)
			var elapsed := float(Time.get_ticks_usec() - started)
			if frame >= 120:
				samples.append(elapsed)
		report[workload] = summary(samples)
	world.cell = original
	DirAccess.make_dir_recursive_absolute("res://artifacts/vastra-optimization")
	var file := FileAccess.open("res://artifacts/vastra-optimization/%s.json" % tag, FileAccess.WRITE)
	if file == null:
		push_error("Cannot write Vastra profile report")
		scene.queue_free()
		quit(1)
		return
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	print("VASTRA PROFILE: ", JSON.stringify(report))
	scene.queue_free()
	await process_frame
	quit()
