extends SceneTree
const Library = preload("res://scripts/scenery/plant_library.gd")
func _initialize() -> void: run.call_deferred()

func run() -> void:
	root.size=Vector2i(1600,1100)
	var stage := Node3D.new()
	root.add_child(stage)
	var environment := WorldEnvironment.new()
	environment.environment=Environment.new()
	environment.environment.background_mode=Environment.BG_COLOR
	environment.environment.background_color=Color("25383b")
	environment.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color=Color("e4e6ce")
	environment.environment.ambient_light_energy=0.7
	stage.add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees=Vector3(-55,-25,0)
	light.light_energy=1.2
	stage.add_child(light)
	var camera := Camera3D.new()
	stage.add_child(camera)
	camera.position=Vector3(4.4,9,13)
	camera.look_at(Vector3(4.4,0,3.2))
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	camera.size=10.0
	for biome in range(4):
		for variation in range(5):
			var item: Resource=Library.foliage_definition(biome,variation)
			var specimen: Node3D=item.scene.instantiate()
			stage.add_child(specimen)
			var model := Library.model(item)
			specimen.scale=item.scale_for(model.bounds)
			specimen.position=Vector3(variation*2.2,0,biome*2.2)
			var label := Label3D.new()
			label.text=["MEADOW","WOODLAND","HEATH","MARSH"][biome]+" / "+item.display_name
			label.position=specimen.position+Vector3(0,-0.13,0.62)
			label.font_size=26
			label.pixel_size=0.0035
			label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
			stage.add_child(label)
	for frame in range(12): await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://artifacts/generic-foliage")
	root.get_texture().get_image().save_png("res://artifacts/generic-foliage/palette.png")
	stage.free()
	Engine.set_meta("workstation_session_path","res://artifacts/generic-foliage/review_"+str(Time.get_ticks_usec())+".cfg")
	var lab: Control=load("res://scenes/development_workstation.tscn").instantiate()
	root.add_child(lab)
	lab.picker.select(lab.FIXTURES.keys().find("Plants / maker & library"))
	lab.overrides.clear()
	lab.load_fixture()
	lab.fixture.review_all_foliage()
	for frame in range(12): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/generic-foliage/lab-overview.png")
	lab.fixture.silhouette_view=true
	lab.fixture.rebuild_maker()
	for frame in range(12): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/generic-foliage/lab-silhouettes.png")
	lab.fixture.biome_picker.select(2)
	lab.fixture.refresh_view()
	lab.fixture.foliage_picker.select(3)
	lab.fixture.foliage_picker.item_selected.emit(3)
	lab.fixture.silhouette_view=false
	lab.fixture.cutaway=true
	lab.fixture.rebuild_maker()
	for frame in range(12): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/generic-foliage/lab-anatomy.png")
	lab.free()
	quit()
