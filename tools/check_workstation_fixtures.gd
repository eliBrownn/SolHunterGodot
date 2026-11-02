extends SceneTree
func _initialize() -> void:
 run.call_deferred()
func run() -> void:
 var lab: Control = load("res://scenes/development_workstation.tscn").instantiate()
 root.add_child(lab)
 for index in range(lab.picker.item_count):
  lab.picker.select(index)
  lab.overrides.clear()
  lab.load_fixture()
  for frame in range(3): await process_frame
  var snapshot: Dictionary = lab.report()
  print("FIXTURE OK: ", snapshot.fixture)
  if lab.fixture.get("world") is Node:
   var world: Node = lab.fixture.get("world")
   assert(world.in_development_workstation())
   world.save_game("user://workstation-must-not-save.json")
   assert(not FileAccess.file_exists("user://workstation-must-not-save.json"))
 lab.queue_free()
 for frame in range(3): await process_frame
 quit()
