extends SceneTree
## Paired old whole-fixture apply path versus selective owner application.
var results := {}
var failures := 0

func _initialize() -> void:
	create_timer(180).timeout.connect(func(): quit(1))
	run.call_deferred()

func samples_summary(values: Array[float]) -> Dictionary:
	var ordered := values.duplicate()
	ordered.sort()
	return {"samples": values, "median_ms": ordered[ordered.size() / 2], "p95_ms": ordered[mini(ordered.size() - 1, int(ordered.size() * 0.95))]}

func measure_frames(count: int) -> Dictionary:
	var values: Array[float] = []
	var previous := Time.get_ticks_usec()
	for i in range(count):
		await process_frame
		var now := Time.get_ticks_usec()
		values.append((now - previous) / 1000.0)
		previous = now
	return samples_summary(values)

func run() -> void:
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280, 800)
	var folder := "res://artifacts/lab-phase-review"
	DirAccess.make_dir_recursive_absolute(folder)
	Engine.set_meta("workstation_session_path", folder.path_join("baseline_workspace.cfg"))
	Engine.set_meta("lab_initial_station", "plant_maker")
	var start := Time.get_ticks_usec()
	var host: Control = load("res://scenes/development_workstation.tscn").instantiate()
	root.add_child(host)
	results["cold_plant_open_ms"] = (Time.get_ticks_usec() - start) / 1000.0
	host.save_timer.stop()
	await process_frame
	var old_samples: Array[float] = []
	var new_samples: Array[float] = []
	for value in [0.3, 0.6, 0.9]:
		start = Time.get_ticks_usec()
		host.overrides["wind_strength"] = value
		host.load_fixture()
		old_samples.append((Time.get_ticks_usec() - start) / 1000.0)
		await process_frame
	for value in [0.4, 0.7, 1.0]:
		var id: int = host.fixture.get_instance_id()
		start = Time.get_ticks_usec()
		host.apply_parameter("wind_strength", value)
		new_samples.append((Time.get_ticks_usec() - start) / 1000.0)
		if host.fixture.get_instance_id() != id: failures += 1
		await process_frame
	results["full_reload_apply"] = samples_summary(old_samples)
	results["selective_apply"] = samples_summary(new_samples)
	results["animated"] = await measure_frames(120)
	host.set_paused(true)
	results["paused"] = await measure_frames(120)
	results["context"] = {"engine": Engine.get_version_info().string, "renderer": RenderingServer.get_current_rendering_method(), "driver": RenderingServer.get_current_rendering_driver_name(), "gpu": RenderingServer.get_video_adapter_name(), "cpu": OS.get_processor_name(), "viewport": str(root.size), "seed":host.fixture.generation_seed, "specimens":host.fixture.specimens.size(), "source_snapshot":host.control_revision(), "fidelity":"unchanged station renderer/material/shadow/MSAA settings", "limitation":"single desktop process, frame cap 60, no separate GPU timing"}
	var file := FileAccess.open(folder.path_join("baseline.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(results, "  "))
	file.close()
	print("LAB BASELINE: cold ", results.cold_plant_open_ms, " ms; full apply ", results.full_reload_apply.median_ms, " ms; selective ", results.selective_apply.median_ms, " ms; failures ", failures)
	host.queue_free()
	await process_frame
	quit(1 if failures else 0)
