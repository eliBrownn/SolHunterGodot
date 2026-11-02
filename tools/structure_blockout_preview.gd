extends Node3D
## Standalone object contact sheet, with no world or gameplay integration.
const Generator = preload("res://scripts/scenery/procedural_structure_blockout.gd")
const Definition = preload("res://scripts/scenery/structure_blockout_definition.gd")
@export_range(0, 99999) var seed_value := 42

func _ready() -> void:
	for i in range(8):
		var recipe := Definition.new()
		recipe.family = i
		recipe.seed_value = seed_value
		var object: Node3D = Generator.build(Generator.layout(recipe))
		add_child(object)
		object.position = Vector3((i % 4 - 1.5) * 5.5, 0, (i / 4) * 6.0 - 3.0)
	var camera := Camera3D.new()
	add_child(camera)
	camera.position = Vector3(12, 17, 23)
	camera.look_at(Vector3(0, 1, 0))
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 27
	camera.current = true
	var light := DirectionalLight3D.new()
	add_child(light)
	light.rotation_degrees = Vector3(-50, -35, 0)
	light.light_energy = 1.5
	var environment := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color("252a32")
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color.WHITE
	settings.ambient_light_energy = 0.55
	environment.environment = settings
	add_child(environment)
