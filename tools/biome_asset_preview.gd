extends Node3D
## Development contact sheet with supplied-kit references. No world or save writes.

const NatureArt = preload("res://scripts/scenery/nature_art.gd")
const STUDIES := ["broadleaf_tree", "conifer", "dry_tree", "snow_conifer", "palm", "cactus", "reeds", "rock_cluster",
	"birch_tree", "willow_tree", "dead_snag", "stump", "fallen_log", "bush", "grass_tuft", "flower_patch",
	"mangrove_tree", "fern", "mushroom_cluster", "lily_pad", "boulder", "stone_spire", "ice_cluster", "rush_cluster"]
var shelf := Node3D.new()

func _ready() -> void:
	var capture := OS.get_cmdline_user_args().has("--capture-biomes")
	if capture:
		get_window().mode = Window.MODE_WINDOWED
		get_window().size = Vector2i(1440, 960)
		get_window().unfocusable = true
		get_window().position = Vector2i(-32000, -32000)
	var camera := Camera3D.new()
	add_child(camera)
	camera.position = Vector3(9, 16, 25)
	camera.look_at(Vector3(0, 0.8, 0))
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 22
	camera.current = true
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("a8bcc7")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("cbd4ce")
	environment.environment.ambient_light_energy = 0.45
	add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-50, -35, 0)
	light.light_energy = 0.9
	light.shadow_enabled = true
	add_child(light)
	add_child(shelf)
	show_page(0)
	var references := ["CommonTree_1", "Pine_1", "Rock_Medium_1"]
	for index in range(references.size()):
		var source: PackedScene = load("res://assets/nature/" + references[index] + ".gltf")
		var model: Dictionary = NatureArt.parts(source)
		var instance: Node3D = source.instantiate()
		var bounds: AABB = model.bounds
		var scale_factor := (3.5 if index < 2 else 1.0) / bounds.size.y
		instance.scale = Vector3.ONE * scale_factor
		var point := Vector3((index - 1) * 7, 0, -8.5)
		instance.position = point - Vector3(bounds.get_center().x, bounds.position.y, bounds.get_center().z) * scale_factor
		add_child(instance)
		pad(point, Color("526854"))
		label("Reference: " + references[index].replace("_", " "), point + Vector3(0, 0.05, 2))
	var layer := CanvasLayer.new()
	add_child(layer)
	var panel := PanelContainer.new()
	panel.position = Vector2(20, 18)
	layer.add_child(panel)
	var column := VBoxContainer.new()
	panel.add_child(column)
	var text := Label.new()
	text.text = "  BIOME PLACEHOLDERS  /  24 assets  \n  Supplied nature kit references behind each page of scenery studies  "
	text.add_theme_font_size_override("font_size", 21)
	column.add_child(text)
	var row := HBoxContainer.new()
	column.add_child(row)
	for index in range(3):
		var button := Button.new()
		button.text = ["Core silhouettes", "Woodland details", "Wetland & stone"][index]
		button.pressed.connect(show_page.bind(index))
		row.add_child(button)
	if capture:
		capture_sheet.call_deferred()

func show_page(page: int) -> void:
	for child in shelf.get_children():
		child.free()
	for index in range(8):
		var name: String = STUDIES[clampi(page, 0, 2) * 8 + index]
		var point := Vector3((index % 4 - 1.5) * 5.5, 0, -2.5 if index < 4 else 3.2)
		var instance: Node3D = load("res://assets/biome_placeholders/" + name + ".tscn").instantiate()
		instance.position = point
		shelf.add_child(instance)
		pad(point, Color("798b71") if index < 4 else Color("9b997e"), shelf)
		label(name.replace("_", " ").capitalize(), point + Vector3(0, 0.05, 2), shelf)

func pad(point: Vector3, color: Color, parent: Node3D = null) -> void:
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(5, 0.12, 4.6)
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1.0
	mesh.material = material
	node.mesh = mesh
	node.position = point + Vector3(0, -0.07, 0)
	(parent if parent != null else self).add_child(node)

func label(text: String, point: Vector3, parent: Node3D = null) -> void:
	var node := Label3D.new()
	node.text = text
	node.font_size = 26
	node.pixel_size = 0.012
	node.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	node.position = point
	node.no_depth_test = true
	(parent if parent != null else self).add_child(node)

func capture_sheet() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Biome contact sheet needs a real renderer")
		get_tree().quit(1)
		return
	DirAccess.make_dir_recursive_absolute("res://artifacts/biome_placeholders")
	for page in range(3):
		show_page(page)
		for frame in range(10):
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var name: String = ["preview", "woodland_details", "wetland_stone"][page]
		var error := get_viewport().get_texture().get_image().save_png("res://artifacts/biome_placeholders/" + name + ".png")
		if error != OK:
			get_tree().quit(1)
			return
	print("BIOME PREVIEW: 24 placeholders and supplied reference models rendered across three pages.")
	get_tree().quit()
