extends SceneTree
const Art = preload("res://scripts/scenery/nature_art.gd")

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://artifacts/vessel-response")
	var class_mode := "--classes" in OS.get_cmdline_user_args()
	root.size = Vector2i(900, 420) if class_mode else Vector2i(1280, 960)
	var stage := Node3D.new()
	root.add_child(stage)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("243035")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color.WHITE
	environment.environment.ambient_light_energy = 0.7
	stage.add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-50, -25, 0)
	light.light_energy = 1.3
	stage.add_child(light)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 3.8 if class_mode else 16.0
	camera.position = Vector3(0, 4, 6) if class_mode else Vector3(0, 15, 15)
	stage.add_child(camera)
	camera.look_at(Vector3.ZERO)
	camera.current = true
	var summary := []
	var palette := StandardMaterial3D.new()
	palette.albedo_texture = load("res://assets/local/tropical_plants/Textures/T_Tropical_plants.png")
	palette.roughness = 1.0
	palette.cull_mode = BaseMaterial3D.CULL_DISABLED
	var indices: Array = [19, 15, 17] if class_mode else range(1, 21)
	for slot in range(indices.size()):
		var index := int(indices[slot])
		var path := "res://assets/local/tropical_plants/Fbx/Tropical_plant_%03d.fbx" % index
		var scene := load(path) as PackedScene
		if scene == null:
			push_error("Missing placeholder " + path)
			quit(1)
			return
		var parts: Dictionary = Art.parts(scene)
		if not parts.supported:
			push_error("Unsupported placeholder " + path)
			quit(1)
			return
		var model := Node3D.new()
		for part: Dictionary in parts.pieces:
			var piece := MeshInstance3D.new()
			piece.mesh = part.mesh
			piece.transform = part.transform
			piece.material_override = palette
			model.add_child(piece)
		stage.add_child(model)
		var bounds: AABB = parts.bounds
		var factor := minf(1.25 / bounds.size.y, 2.0 / maxf(bounds.size.x, bounds.size.z))
		model.scale = Vector3.ONE * factor
		var grid := Vector3(float((index - 1) % 5) * 2.7 - 5.4, 0, float((index - 1) / 5) * 3.0 - 4.5)
		if class_mode: grid = Vector3(float(slot - 1) * 2.2, 0, 0)
		model.position = grid - Vector3(bounds.get_center().x, bounds.position.y, bounds.get_center().z) * factor
		var label := Label3D.new()
		label.text = ["Warden", "Mender", "Regulator"][slot] if class_mode else "%03d" % index
		label.font_size = 48
		label.pixel_size = 0.008
		label.position = grid + Vector3(0, 0.05, 0.9)
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		stage.add_child(label)
		summary.append({"index": index, "triangles": parts.triangles, "surfaces": parts.surfaces, "bounds": str(bounds)})
	for i in range(5): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/vessel-response/" + ("class-placeholders.png" if class_mode else "tropical-contact-sheet.png"))
	var file := FileAccess.open("res://artifacts/vessel-response/tropical-models.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(summary, "\t"))
	print("TROPICAL PLACEHOLDERS: %d supported models; contact sheet recorded." % indices.size())
	stage.free()
	quit()
