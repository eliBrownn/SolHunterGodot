extends SceneTree
const Library = preload("res://scripts/scenery/plant_library.gd")
func _initialize() -> void: run.call_deferred()
func run() -> void:
	root.size=Vector2i(1600,1000)
	var stage := Node3D.new()
	root.add_child(stage)
	var environment := WorldEnvironment.new()
	environment.environment=Environment.new()
	environment.environment.background_mode=Environment.BG_COLOR
	environment.environment.background_color=Color("293d46")
	environment.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color=Color("d4e5e2")
	environment.environment.ambient_light_energy=0.7
	stage.add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees=Vector3(-55,-25,0)
	light.light_energy=1.4
	stage.add_child(light)
	var camera := Camera3D.new()
	stage.add_child(camera)
	camera.position=Vector3(15,17,30)
	camera.look_at(Vector3(15,1.0,4.5))
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	camera.size=23
	for biome in range(4):
		for row in range(4):
			var traits := {"role":"reservoir" if row==0 else "receiver","class":"" if row==0 else ["warden","mender","regulator"][row-1]}
			var item: Resource=Library.procedural_definition(biome,traits,1)
			var instance: Node3D=item.scene.instantiate()
			stage.add_child(instance)
			var box: AABB=Library.model(item).bounds
			var dimensions: Resource=item.duplicate()
			dimensions.world_height=5.0 if row==0 else 1.0
			dimensions.world_width=7.0 if row==0 else 1.5
			instance.scale=dimensions.scale_for(box)
			instance.position=Vector3(biome*10,0,0 if row==0 else 5+row*2.5)
			var label := Label3D.new()
			label.text=["MEADOW","WOODLAND","HEATH","MARSH"][biome]+" / "+["Tree","Warden","Mender","Regulator"][row]
			label.position=instance.position+Vector3(0,-0.3,1)
			label.font_size=36
			label.pixel_size=0.009
			stage.add_child(label)
	for frame in range(12): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/plant-diversity-palette.png")
	stage.free()
	Engine.set_meta("workstation_session_path","res://artifacts/plant-organic-review.cfg")
	var lab: Control=load("res://scenes/development_workstation.tscn").instantiate()
	root.add_child(lab)
	lab.picker.select(lab.FIXTURES.keys().find("Plants / maker & library"))
	lab.load_fixture()
	for item: Resource in Library.all():
		if item.resource_path.begins_with("res://resources/plants/"):
			lab.fixture.load_definition(item)
			break
	for frame in range(12): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/plant-organic-maker.png")
	lab.free()
	quit()
