extends "res://scripts/development/sol_model_workshop.gd"
## Clickable action controls over the game's existing model workshop contract.
func _ready() -> void:
 super._ready()
 var layer := CanvasLayer.new()
 add_child(layer)
 var panel := PanelContainer.new()
 var resize := func(): panel.position = Vector2(maxf(12, get_viewport().get_visible_rect().size.x - 242), 145)
 get_viewport().size_changed.connect(resize)
 resize.call()
 layer.add_child(panel)
 var box := VBoxContainer.new()
 panel.add_child(box)
 var modes := OptionButton.new()
 for text in ["Rest", "Walk", "Turns", "Slope", "Flight", "Swimming"]: modes.add_item(text)
 modes.select(exercise)
 modes.item_selected.connect(func(index: int): exercise = index; reset_view())
 box.add_child(modes)
 for action in ["signature", "attack", "hit"]:
  var button := Button.new()
  button.text = "Play " + action
  button.pressed.connect(func(): model.call("play_action", action, elapsed))
  box.add_child(button)
 var speed := HSlider.new()
 speed.min_value = 0.1
 speed.max_value = 2
 speed.step = 0.05
 speed.value = walk_speed
 speed.custom_minimum_size.x = 230
 var label := Label.new()
 label.text = "Route speed: %.2f m/s" % walk_speed
 box.add_child(label)
 box.add_child(speed)
 speed.value_changed.connect(func(value: float): walk_speed = value; label.text = "Route speed: %.2f m/s" % value)

func workstation_readings() -> Dictionary:
 return {"exercise": exercise, "speed_m_per_second": walk_speed, "model": model_scene.resource_path, "affinity": affinity, "elapsed": elapsed}
