extends SceneTree
func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	root.size = Vector2i(1600,1000)
	Engine.set_meta("workstation_session_path","res://artifacts/plant-communities/review.cfg")
	var lab: Control = load("res://scenes/development_workstation.tscn").instantiate()
	root.add_child(lab)
	lab.picker.select(lab.FIXTURES.keys().find("Plants / communities"))
	lab.load_fixture()
	for node: Node in lab.descendants(lab):
		if node is Button and "Try a test" in node.text:
			node.pressed.emit()
			break
	for frame in range(15): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/plant-communities/lab.png")
	print("COMMUNITY READINGS: ",lab.fixture.workstation_readings())
	lab.queue_free()
	for frame in range(3): await process_frame
	quit()
