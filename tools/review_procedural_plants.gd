extends SceneTree
## Render the actual workstation, paired with its settings and geometry readings.
func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	root.size = Vector2i(1600,1000)
	var lab: Control = load("res://scenes/development_workstation.tscn").instantiate()
	root.add_child(lab)
	lab.picker.select(lab.FIXTURES.keys().find("Plants / procedural forms"))
	lab.overrides.clear()
	lab.load_fixture()
	lab.notes.text = "Generated plant morphology using existing painted atlases and authored bark/ground normals.\nEight growth forms; three deterministic seed variants each.\nVastra shapes provisional. Art fixture only; production admission remains a later step."
	for frame in range(30): await process_frame
	await RenderingServer.frame_post_draw
	var folder := "res://artifacts/plant-prototype"
	DirAccess.make_dir_recursive_absolute(folder)
	root.get_texture().get_image().save_png(folder+"/development-lab.png")
	var file := FileAccess.open(folder+"/report.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(lab.report(),"  "))
	file.close()
	for family in [1,4,5,8]:
		lab.fixture.family_picker.select(family)
		lab.fixture.select_family(family)
		for frame in range(3): await process_frame
		await RenderingServer.frame_post_draw
		lab.viewport.get_texture().get_image().save_png(folder+"/form-%d.png" % family)
	print("PLANT REVIEW: captured 24 generated specimens in workstation")
	if "--keep-open" in OS.get_cmdline_user_args():
		lab.fixture.family_picker.select(0)
		lab.fixture.select_family(0)
	else:
		lab.free()
		quit()
