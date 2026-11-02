extends SceneTree
func _initialize() -> void:
 run.call_deferred()

func run() -> void:
 root.size = Vector2i(1600, 1000)
 var lab: Control = load("res://scenes/development_workstation.tscn").instantiate()
 root.add_child(lab)
 for frame in range(90): await process_frame
 lab.notes.text = "Review: ambient field around plant nodes.\nExpected: readable energy transfer and clear silhouettes.\nNext: compare disturbed preset against ambient."
 await RenderingServer.frame_post_draw
 var output := "res://artifacts/development-workstation"
 DirAccess.make_dir_recursive_absolute(output)
 root.get_texture().get_image().save_png(output + "/preview.png")
 print("WORKSTATION VIEWPORT: ", lab.viewport.size)
 await lab.capture()
 print("CAPTURE: ", lab.message.text)
 lab.queue_free()
 await process_frame
 quit()
