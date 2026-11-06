extends SceneTree
func _initialize() -> void:
 run.call_deferred()
func run() -> void:
 root.size = Vector2i(1600, 1000)
 var lab: Control = load("res://scenes/development_workstation.tscn").instantiate()
 root.add_child(lab)
 for index in range(14, lab.picker.item_count):
  lab.picker.select(index)
  lab.load_fixture()
  lab.notes.text = "Visual acceptance: check silhouettes, materials and controls.\nRecord expected versus observed before adjusting."
  for frame in range(25): await process_frame
  await RenderingServer.frame_post_draw
  var path := "C:/Users/elija/Documents/Codex/2026-10-29/mak/outputs/station-%s.png" % lab.FIXTURES[lab.picker.get_item_text(index)]
  root.get_texture().get_image().save_png(path)
  print("RENDERED: ", path)
 lab.queue_free()
 for frame in range(3): await process_frame
 quit()
