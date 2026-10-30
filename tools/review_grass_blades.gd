extends SceneTree
func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	root.size = Vector2i(1600,1000)
	var lab: Control = load("res://scenes/development_workstation.tscn").instantiate()
	root.add_child(lab)
	lab.picker.select(lab.FIXTURES.keys().find("Grass / single blades"))
	lab.overrides.clear()
	lab.load_fixture()
	lab.notes.text = "Functional Vastra: grass cells → tree reserves; tree roots → grass cells.\nLabels show cell IDs and live reserves. All packets follow real ledger transfers.\nIsolated test state with seeded reserves; no expedition saves changed."
	for frame in range(120): await process_frame
	await create_timer(2.0).timeout
	await RenderingServer.frame_post_draw
	var folder := "res://artifacts/grass-prototype"
	DirAccess.make_dir_recursive_absolute(folder)
	root.get_texture().get_image().save_png(folder + "/development-lab.png")
	var report := FileAccess.open(folder + "/report.json",FileAccess.WRITE)
	report.store_string(JSON.stringify(lab.report(),"  "))
	report.close()
	print("GRASS PROTOTYPE: ",lab.fixture.workstation_readings())
	if "--keep-open" not in OS.get_cmdline_user_args():
		lab.free()
		quit()
