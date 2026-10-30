extends SceneTree
func _initialize() -> void:
	run.call_deferred()

func capture(lab: Control,path: String) -> void:
	for frame in range(5): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)

func run() -> void:
	root.size = Vector2i(1600,1000)
	var lab: Control = load("res://scenes/development_workstation.tscn").instantiate()
	root.add_child(lab)
	lab.picker.select(lab.FIXTURES.keys().find("Plants / biomes & Vastra anatomy"))
	lab.load_fixture()
	lab.notes.text = "One anatomical sample per biome x circulation role/class.\nEmanator / reservoir / unclassed receiver; Warden / Mender / Regulator receiver variants.\nOrgans and their connected paths are proposed anatomy. Static study; no ecological transactions."
	var folder := "res://artifacts/plant-anatomy"
	DirAccess.make_dir_recursive_absolute(folder)
	for biome in range(4):
		lab.fixture.biome_picker.select(biome+1)
		lab.fixture.role_picker.select(0)
		lab.fixture.refresh_view()
		await capture(lab,folder+"/biome-%d.png" % biome)
	lab.fixture.biome_picker.select(0)
	lab.fixture.refresh_view()
	await capture(lab,folder+"/all-samples.png")
	var file := FileAccess.open(folder+"/report.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(lab.report(),"  "))
	file.close()
	for pair in [Vector2i(0,0),Vector2i(1,1),Vector2i(2,3),Vector2i(3,4),Vector2i(1,5)]:
		lab.fixture.biome_picker.select(pair.x+1)
		lab.fixture.role_picker.select(pair.y+1)
		lab.fixture.refresh_view()
		var toggle: CheckButton = lab.fixture.find_child("Cutaway",true,false)
		toggle.button_pressed = false
		await capture(lab,folder+"/sample-%d-%d.png" % [pair.x,pair.y])
		toggle.button_pressed = true
		await capture(lab,folder+"/anatomy-%d-%d.png" % [pair.x,pair.y])
	print("PLANT ANATOMY REVIEW: 24 samples; biome, full grid and anatomy captures complete")
	lab.overrides["silhouette_view"] = true
	lab.load_fixture()
	lab.fixture.biome_picker.select(0)
	for role in [2,4]:
		lab.fixture.role_picker.select(role)
		lab.fixture.refresh_view()
		lab.fixture.find_child("Cutaway",true,false).button_pressed = false
		await capture(lab,folder+"/silhouette-role-%d.png"%role)
	lab.overrides["silhouette_view"] = false
	lab.load_fixture()
	if "--keep-open" in OS.get_cmdline_user_args():
		lab.fixture.biome_picker.select(1)
		lab.fixture.role_picker.select(0)
		lab.fixture.find_child("Cutaway",true,false).button_pressed = false
		lab.fixture.refresh_view()
	else:
		lab.free()
		await process_frame
		quit()
