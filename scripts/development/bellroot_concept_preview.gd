extends Node3D
## Sol Lab hosted prototype; controls affect this preview only.
const Creature = preload("res://scripts/sols/presentation/bellroot_concept.gd")
var model: Node3D
var elapsed := 0.0
var walking := false
var running := true
var camera: Camera3D
var yaw := 0.35

func _ready() -> void:
	model = Creature.new()
	model.configure("water", SolVisualSettings.new())
	add_child(model)
	camera = Camera3D.new()
	camera.position = Vector3(1.2, 0.95, 2.0)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 1.8
	add_child(camera)
	camera.look_at(Vector3(0, 0.42, 0))
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45, -35, 0)
	add_child(sun)
	var sky := WorldEnvironment.new()
	sky.environment = Environment.new()
	sky.environment.background_mode = Environment.BG_COLOR
	sky.environment.background_color = Color("c5c4b9")
	sky.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	sky.environment.ambient_light_color = Color.WHITE
	sky.environment.ambient_light_energy = 0.7
	add_child(sky)
	var floor_mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(10, 10)
	floor_mesh.mesh = plane
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("aaa99b")
	floor_mesh.material_override = mat
	add_child(floor_mesh)
	var layer := CanvasLayer.new()
	add_child(layer)
	var panel := VBoxContainer.new()
	panel.position = Vector2(16, 16)
	panel.custom_minimum_size.x = 260
	layer.add_child(panel)
	var title := Label.new()
	title.text = "Bellroot / first-form test"
	panel.add_child(title)
	slider(panel, "Core diameter", 0.25, 0.55, 0.4, func(value: float):
		model.core_size = value
		model.visual_core.configure(value, {"wisp_spread": 0.04, "wisp_length": 0.3, "core_tint": "fff0d5"})
		model.update_core())
	slider(panel, "Core clearance", 0.08, 0.25, 0.12, func(value: float): model.core_gap = value; model.update_core())
	slider(panel, "Leaf droop", -0.25, 0.45, 0.0, func(value: float): model.leaf_droop = value)
	slider(panel, "View angle", -PI, PI, yaw, func(value: float): yaw = value)
	var walk := CheckButton.new()
	walk.text = "Walk in place"
	panel.add_child(walk)
	walk.toggled.connect(func(on: bool): walking = on; model.reset_locomotion())
	var pause := CheckButton.new()
	pause.text = "Pause pose"
	panel.add_child(pause)
	pause.toggled.connect(func(on: bool): running = not on)
	var gesture := Button.new()
	gesture.text = "Tend / inspect"
	panel.add_child(gesture)
	gesture.pressed.connect(func(): model.play_action("signature", elapsed))

func slider(parent: Node, title: String, minimum: float, maximum: float, initial: float, action: Callable) -> void:
	var label := Label.new()
	label.text = "%s: %.2f" % [title, initial]
	parent.add_child(label)
	var control := HSlider.new()
	control.min_value = minimum
	control.max_value = maximum
	control.step = 0.01
	control.value = initial
	parent.add_child(control)
	control.value_changed.connect(func(value: float): label.text = "%s: %.2f" % [title, value]; action.call(value))

func _process(delta: float) -> void:
	camera.position = Vector3(sin(yaw) * 2.3, 1.05, cos(yaw) * 2.3)
	camera.look_at(Vector3(0, 0.42, 0))
	if not running: return
	elapsed += delta
	if walking: model.sync_locomotion(Vector2(0, elapsed * 0.3), delta, func(_at: Vector2): return 0.0)
	model.animate(elapsed, 0.0, 0.0)
