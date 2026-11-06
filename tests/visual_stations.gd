extends SceneTree
var failures := 0
func check(ok: bool, text: String) -> void:
 if not ok:
  failures += 1
  push_error(text)
func _initialize() -> void:
 run.call_deferred()
func run() -> void:
 var lab: Control = load("res://scenes/development_workstation.tscn").instantiate()
 root.add_child(lab)
 for index in range(14, lab.picker.item_count):
  lab.picker.select(index)
  lab.load_fixture()
  await process_frame
  var node: Node = lab.fixture
  var readings: Dictionary = lab.report().readings
  check(not readings.is_empty(), "Station contributes report readings")
  check(lab.viewport.get_camera_3d() != null, "Station has a camera")
  if node.get("station") != null:
   var mode: int = node.station
   if mode == 0:
    node.controls.get_node("sun_energy").value = 2.0
    check(is_equal_approx(node.sun.light_energy, 2.0), "Lighting slider updates rendered light")
   if mode == 1:
    var spheres := 0
    for child in node.samples.get_children():
     if child is MeshInstance3D and child.mesh is SphereMesh: spheres += 1
    check(spheres == 15, "Material matrix has fifteen samples")
   if mode == 2:
    node.controls.get_node("foam_depth").value = 0.1
    check(is_equal_approx(node.water.get_shader_parameter("foam_depth"), 0.1), "Water slider updates actual game shader")
   if mode == 3:
    node.controls.get_node("occluder_height").value = 3
    check(is_equal_approx(node.blocker.scale.y, 3), "Readability slider changes occluder")
   if mode == 4:
    node.controls.get_node("active_particles").value = 4096
    check(is_equal_approx(node.particles.amount_ratio, 0.5), "Particle count scales actual emitter")
    lab.set_paused(true)
    check(node.particles.speed_scale == 0, "Shared pause freezes density fixture")
    lab.set_paused(false)
  else:
   check(node.model != null, "Animation station has an actual Sol model")
   node.model.call("play_action", "attack", node.elapsed)
   node.update_model(0.1)
   check(readings.exercise in [3, 4, 5], "Animation route matches station")
  print("VISUAL STATION OK: ", lab.picker.get_item_text(index))
 lab.queue_free()
 for frame in range(3): await process_frame
 print("VISUAL STATIONS: %d failures" % failures)
 quit(1 if failures else 0)
