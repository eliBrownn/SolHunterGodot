extends SceneTree
func _initialize() -> void: run.call_deferred()
func run() -> void:
	root.size=Vector2i(1600,1000)
	Engine.set_meta("workstation_session_path","res://artifacts/plant-event-review.cfg")
	var lab: Control=load("res://scenes/development_workstation.tscn").instantiate()
	root.add_child(lab)
	lab.picker.select(lab.FIXTURES.keys().find("Plants / maker & library"))
	lab.load_fixture()
	for item: Resource in preload("res://scripts/scenery/plant_library.gd").all():
		if item.resource_path.begins_with("res://resources/plants/"):
			lab.fixture.load_definition(item)
			break
	for frame in range(5): await process_frame
	lab.fixture.process_mode=Node.PROCESS_MODE_DISABLED
	for event_index in range(6):
		lab.fixture.preview_event=event_index
		lab.fixture.preview_animation_strength=2.0
		lab.fixture.elapsed=0.6
		lab.fixture._process(0.0)
		for frame in range(3): await process_frame
		await RenderingServer.frame_post_draw
		var kind: String=preload("res://scripts/presentation/plant_animation.gd").KINDS[event_index]
		root.get_texture().get_image().save_png("res://artifacts/plant-event-"+kind+".png")
	lab.free()
	quit()
