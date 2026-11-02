extends SceneTree
## Actual rendered live-palette review, using definition sizes and shared geometry.
const Library=preload("res://scripts/scenery/plant_library.gd")
func _initialize() -> void: run.call_deferred()
func run() -> void:
	root.size=Vector2i(1400,1000)
	DirAccess.make_dir_recursive_absolute("res://artifacts/plant-presentation")
	for biome in range(4):
		var stage := Node3D.new()
		root.add_child(stage)
		var environment := WorldEnvironment.new()
		environment.environment=Environment.new()
		environment.environment.background_mode=Environment.BG_COLOR
		environment.environment.background_color=Color("a9bec2")
		environment.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
		environment.environment.ambient_light_color=Color("d6e1da")
		environment.environment.ambient_light_energy=0.55
		stage.add_child(environment)
		var light := DirectionalLight3D.new()
		light.rotation_degrees=Vector3(-48,-35,0)
		light.light_energy=1.25
		light.shadow_enabled=true
		stage.add_child(light)
		var soil := MeshInstance3D.new()
		soil.mesh=PlaneMesh.new()
		soil.mesh.size=Vector2(18,18)
		var soil_material := StandardMaterial3D.new()
		soil_material.albedo_color=Color("697657")
		soil_material.roughness=1.0
		soil.material_override=soil_material
		stage.add_child(soil)
		var review_bounds := AABB()
		for slot in range(4):
			var traits := {"role":"reservoir" if slot==0 else "receiver","class":"" if slot==0 else FloraTraits.CLASSES[slot-1]}
			var item: Resource=Library.procedural_definition(biome,traits,1 if slot==0 else 2)
			var parts: Dictionary=Library.model(item)
			var instance: Node3D=item.scene.instantiate()
			stage.add_child(instance)
			instance.scale=item.scale_for(parts.bounds)
			instance.position=Vector3(0,0,0) if slot==0 else Vector3((slot-2)*2.4,0,3)
			instance.position-=instance.basis*Vector3(parts.bounds.get_center().x,parts.bounds.position.y,parts.bounds.get_center().z)
			var bounds: AABB=instance.transform*parts.bounds
			review_bounds=bounds if slot==0 else review_bounds.merge(bounds)
		var camera := Camera3D.new()
		stage.add_child(camera)
		var focus := review_bounds.get_center()
		camera.position=focus+Vector3(9,7,13).normalized()*25.0
		camera.look_at(focus)
		camera.projection=Camera3D.PROJECTION_ORTHOGONAL
		camera.size=review_bounds.size.length()*1.25
		var caption := Label.new()
		caption.text=["MEADOW","WOODLAND","HEATH","MARSH"][biome]+" — reservoir / Warden / Mender / Regulator"
		caption.position=Vector2(35,30)
		caption.add_theme_font_size_override("font_size",27)
		root.add_child(caption)
		Library.set_weather(Vector2.RIGHT,0,0)
		for frame in range(8): await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://artifacts/plant-presentation/biome-%d.png"%biome)
		caption.free()
		stage.free()
	quit()
