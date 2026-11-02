extends Node3D
const Generator = preload("res://scripts/scenery/procedural_stone_obstacle.gd")
const Recipe = preload("res://scripts/scenery/stone_obstacle_definition.gd")
@export_range(0, 99999) var seed_value := 73
func _ready() -> void:
	for family in range(10):
		var recipe := Recipe.new()
		recipe.family = family
		recipe.seed_value = seed_value
		recipe.surface_style = family % 5
		var data := Generator.layout(recipe)
		var object := Generator.build(data)
		add_child(object)
		object.position = Vector3((family % 5 - 2) * 7.0, 0, floori(family / 5.0) * 9 - 4.5) - data.bounds.get_center() * Vector3(1, 0, 1)
	var camera := Camera3D.new()
	add_child(camera)
	camera.position = Vector3(10, 24, 34)
	camera.look_at(Vector3(0, 0.5, 0))
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 39
	camera.current = true
	var light := DirectionalLight3D.new()
	add_child(light)
	light.rotation_degrees = Vector3(-45, -30, 0)
	light.light_energy = 2
	var world := WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.background_mode = Environment.BG_COLOR
	world.environment.background_color = Color("353e49")
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color = Color.WHITE
	world.environment.ambient_light_energy = 0.9
	add_child(world)
