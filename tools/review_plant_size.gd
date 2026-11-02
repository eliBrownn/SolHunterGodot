extends SceneTree
func _initialize() -> void:
	run.call_deferred()
func run() -> void:
	root.size=Vector2i(1600,1000)
	Engine.set_meta("workstation_session_path","res://artifacts/plant-size/color-review-%d.cfg"%Time.get_ticks_usec())
	var lab: Control=load("res://scenes/development_workstation.tscn").instantiate()
	root.add_child(lab)
	lab.picker.select(lab.FIXTURES.keys().find("Plants / maker & library"))
	lab.load_fixture()
	var maker: Node3D=lab.fixture
	var settings := {"world_height":7.0,"world_width":6.5,"preserve_proportions":true,"preview_event":0,"foliage_palette":1,"bark_palette":1,"flower_palette":3,"color_gradient":0.6,"branch_reach":1.4,"branch_arch":0.9,"anatomy_labels":false}
	for key in settings:
		maker.set(key,settings[key])
		maker.remember(key,settings[key])
	maker.selected_biome=1
	maker.selected_role=2
	maker.biome_picker.select(1)
	maker.role_picker.select(2)
	for child in maker.samples.get_children(): child.free()
	maker.beds.clear()
	maker.specimens.clear()
	maker.build_bed(0)
	maker.refresh_view()
	for frame in range(12): await process_frame
	lab.fixture.refit_after_rebuild()
	await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://artifacts/plant-size")
	root.get_texture().get_image().save_png("res://artifacts/plant-size/natural-scale-maker.png")
	print("PLANT SIZE REVIEW: 7-unit reservoir, 6.5-unit spread, natural proportions, no plant assets saved")
	if "--keep-open" not in OS.get_cmdline_user_args():
		lab.free()
		await process_frame
		quit()
