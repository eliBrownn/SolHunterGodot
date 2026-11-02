extends Node3D
## Copied into an ignored, independent project by prepare_asset_store_review.py.
## Presentation fixture only; no expedition data or vendor demo scripts.

@export_group("Review settings (restart to apply)")
## Matching scatter positions and heights across all three alternatives.
@export var scatter_seed := 261029
@export_range(0.0, 2.0, 0.01) var grass_wind_strength := 0.14
@export_range(0.0, 2.0, 0.01) var grass_gust_strength := 0.25
## Meters between meadow clumps; smaller values fill the ground more densely.
@export_range(0.2, 0.8, 0.02) var meadow_spacing := 0.3
## Width and depth in meters. Preview only, independent of world generation.
@export var meadow_size := Vector2(40, 44)
## Typical blade height in meters; each clump varies gently around this value.
@export_range(0.15, 0.65, 0.01) var meadow_height := 0.32
## Lower-resolution 3D enlarged with nearest sampling. UI remains full resolution.
@export_enum("Native", "Light 1.5x", "Medium 1.75x", "Strong 2x") var pixel_effect := 2

var versions: Array[Node3D] = []
var camera := Camera3D.new()
var environment := Environment.new()
var sun := DirectionalLight3D.new()
var caption := Label.new()
var mode := 2
var condition := 0
var azimuth := 0.3
var elevation := 0.29
var distance := 23.0
var grass_material: ShaderMaterial
var capturing := false
var smooth_materials: Dictionary = {}
var world_viewport := SubViewport.new()
var world_display := TextureRect.new()
var pixel_buttons: Array[Button] = []
const PIXEL_DIVISORS = [1.0, 1.5, 1.75, 2.0]
const PIXEL_NAMES = ["Native", "Light pixels", "Medium pixels", "Strong pixels"]

func _ready() -> void:
	add_child(world_viewport)
	world_viewport.own_world_3d = true
	world_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_viewport().size_changed.connect(update_pixel_size)
	var world_environment := WorldEnvironment.new()
	world_environment.environment = environment
	world_viewport.add_child(world_environment)
	var sky := Sky.new()
	sky.sky_material = ProceduralSkyMaterial.new()
	environment.sky = sky
	environment.background_mode = Environment.BG_SKY
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.ambient_light_sky_contribution = 0.65
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.tonemap_exposure = 1.2
	environment.fog_enabled = true
	environment.fog_density = 0.002
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 65
	world_viewport.add_child(sun)
	world_viewport.add_child(camera)
	camera.current = true
	camera.fov = 48
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(100, 100)
	ground.mesh = plane
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("63744b")
	material.roughness = 1.0
	ground.material_override = material
	world_viewport.add_child(ground)
	grass_material = load("res://vendor/grass/Materials/EA_Grass_Green.tres").duplicate()
	grass_material.set_shader_parameter("wind_strength", grass_wind_strength)
	grass_material.set_shader_parameter("gust_strength", grass_gust_strength)
	# Broad painterly patches, matte blades and gentle motion rather than microdetail.
	grass_material.set_shader_parameter("normal_strength", 0.0)
	grass_material.set_shader_parameter("tint_quality", 0)
	grass_material.set_shader_parameter("smoothness", 0.0)
	grass_material.set_shader_parameter("base_color", Color("b4c879"))
	grass_material.set_shader_parameter("tint_color_small", Color("b6cb81"))
	grass_material.set_shader_parameter("tint_intensity_small_blob", 0.12)
	grass_material.set_shader_parameter("tint_intensity_small_stripes", 0.12)
	grass_material.set_shader_parameter("tint_color_large", Color("709155"))
	grass_material.set_shader_parameter("stripes_mode_large", false)
	grass_material.set_shader_parameter("tint_scale_large_blob", 0.06)
	grass_material.set_shader_parameter("tint_intensity_large_blob", 0.25)
	grass_material.set_shader_parameter("tint_speed_large_blob", 0.12)
	# Keep the pack's source intact; this material uses smoother alpha coverage.
	var smooth_shader := Shader.new()
	smooth_shader.code = grass_material.shader.code.replace("depth_draw_opaque,", "depth_draw_opaque, alpha_to_coverage,").replace("ALPHA_SCISSOR_THRESHOLD = alpha_cutoff;", "ALPHA_SCISSOR_THRESHOLD = alpha_cutoff;\n ALPHA_ANTIALIASING_EDGE = alpha_cutoff;\n ALPHA_TEXTURE_COORDINATE = UV * vec2(textureSize(albedo_texture, 0));")
	grass_material.shader = smooth_shader
	for index in range(3):
		var version := Node3D.new()
		world_viewport.add_child(version)
		versions.append(version)
		build_version(version, index)
	var canvas := CanvasLayer.new()
	add_child(canvas)
	canvas.add_child(world_display)
	world_display.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	world_display.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	world_display.mouse_filter = Control.MOUSE_FILTER_IGNORE
	world_display.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	world_display.texture = world_viewport.get_texture()
	var panel := PanelContainer.new()
	panel.position = Vector2(16, 16)
	canvas.add_child(panel)
	var box := VBoxContainer.new()
	panel.add_child(box)
	caption.add_theme_font_size_override("font_size", 18)
	box.add_child(caption)
	var row := HBoxContainer.new()
	box.add_child(row)
	for index in range(3):
		var button := Button.new()
		button.text = ["1 Current assets", "2 Hand-painted samples", "3 Stylized meadow"][index]
		button.pressed.connect(select_mode.bind(index))
		row.add_child(button)
	var light_button := Button.new()
	light_button.text = "N Change lighting"
	light_button.pressed.connect(cycle_light)
	row.add_child(light_button)
	var pixel_row := HBoxContainer.new()
	box.add_child(pixel_row)
	for index in range(PIXEL_NAMES.size()):
		var button := Button.new()
		button.text = str(index + 4) + " " + PIXEL_NAMES[index]
		button.pressed.connect(set_pixel_effect.bind(index))
		pixel_row.add_child(button)
		pixel_buttons.append(button)
	set_pixel_effect(pixel_effect)
	refresh()
	if "--capture-review" in OS.get_cmdline_user_args():
		capture.call_deferred()

func build_version(parent: Node3D, index: int) -> void:
	var tree := "res://baseline/CommonTree_1.gltf" if index == 0 else "res://vendor/foliage/Scenes/tree_juniper_regular.tscn"
	var shrub := "res://baseline/Bush_Common.gltf" if index == 0 else "res://vendor/foliage/Scenes/plant_jello_bush_slim.tscn"
	var grass := "res://baseline/Grass_Common_Short.gltf" if index == 0 else "res://vendor/foliage/Scenes/ug_grass_regular_.tscn"
	var rock := "res://baseline/Rock_Medium_1.gltf" if index == 0 else "res://vendor/rocks/Scenes/boulder_round_regular.tscn"
	for at in [Vector3(-5, 0, 0), Vector3(5, 0, -2), Vector3(-7, 0, -7), Vector3(0, 0, -8), Vector3(7, 0, -9), Vector3(-10, 0, -13), Vector3(4, 0, -15)]:
		place(parent, load(tree).instantiate(), at, 6.0, at.x)
	var rng := RandomNumberGenerator.new()
	rng.seed = scatter_seed
	for number in range(26):
		var at := Vector3(rng.randf_range(-10, 10), 0, rng.randf_range(-13, 3))
		if absf(at.x) < 2.8 and at.z > -5: continue
		place(parent, load(shrub).instantiate(), at, rng.randf_range(0.6, 1.1), rng.randf_range(0, TAU))
	for number in range(0 if index == 2 else 100):
		var at := Vector3(rng.randf_range(-11, 11), 0, rng.randf_range(-14, 6))
		if absf(at.x) < 2 and at.z > -5: continue
		var model: Node3D
		if index == 2:
			var clump := MeshInstance3D.new()
			clump.mesh = load("res://vendor/grass/Meshes/EA_Grass_Clump.mesh")
			clump.material_override = grass_material
			clump.extra_cull_margin = 0.6
			model = clump
		else:
			model = load(grass).instantiate()
		place(parent, model, at, rng.randf_range(0.22, 0.45), rng.randf_range(0, TAU))
	place(parent, load(rock).instantiate(), Vector3(-3, 0, 1), 0.7, 0.4)
	place(parent, load(rock).instantiate(), Vector3(3.5, 0, -4), 0.9, 1.8)
	if index == 2: build_meadow(parent)

func build_meadow(parent: Node3D) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = scatter_seed + 1
	var mesh: Mesh = load("res://vendor/grass/Meshes/EA_Grass_Clump.mesh")
	var bounds := mesh.get_aabb()
	var spacing := clampf(meadow_spacing, 0.2, 0.8)
	var size := meadow_size.clamp(Vector2(10, 10), Vector2(50, 50))
	var transforms: Array[Transform3D] = []
	for x in range(ceili(size.x / spacing)):
		for z in range(ceili(size.y / spacing)):
			var at := Vector3((x + rng.randf_range(0.1, 0.9)) * spacing - size.x * 0.5, 0, (z + rng.randf_range(0.1, 0.9)) * spacing - size.y * 0.5 - 4)
			# Narrow, meandering walking trail with irregular soft shoulders.
			var path_center := sin(at.z * 0.18) * 0.8
			var shoulder := smoothstep(0.65, 1.7, absf(at.x - path_center))
			if rng.randf() > shoulder: continue
			var height := clampf(meadow_height, 0.15, 0.65) * rng.randf_range(0.8, 1.2)
			var scale_factor := height / maxf(bounds.size.y, 0.001)
			var basis := Basis(Vector3.UP, rng.randf_range(0, TAU)).scaled(Vector3.ONE * scale_factor)
			at.y = -bounds.position.y * scale_factor
			transforms.append(Transform3D(basis, at))
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = mesh
	multimesh.instance_count = transforms.size()
	for index in range(transforms.size()): multimesh.set_instance_transform(index, transforms[index])
	var meadow := MultiMeshInstance3D.new()
	meadow.multimesh = multimesh
	meadow.material_override = grass_material
	meadow.extra_cull_margin = 0.6
	# Short grass receives tree shadows but does not draw thousands of blade shadows.
	meadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(meadow)
	print("MEADOW: ", transforms.size(), " batched clumps")

func smooth_surfaces(node: Node) -> void:
	if node is MeshInstance3D and node.mesh != null:
		for surface in range(node.mesh.get_surface_count()):
			var source := node.get_active_material(surface) as StandardMaterial3D
			if source == null: continue
			if not smooth_materials.has(source):
				var material := source.duplicate() as StandardMaterial3D
				material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
				if material.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
					material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
					material.alpha_scissor_threshold = 0.4
					material.alpha_antialiasing_mode = BaseMaterial3D.ALPHA_ANTIALIASING_ALPHA_TO_COVERAGE
					material.alpha_antialiasing_edge = 0.4
				# Stone is opaque; its fine normal detail was too strong at this distance.
				if material.uv1_triplanar:
					material.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
					material.normal_scale = 0.25
					material.roughness = 1.0
				smooth_materials[source] = material
			node.set_surface_override_material(surface, smooth_materials[source])
	for child in node.get_children(): smooth_surfaces(child)

func collect_bounds(node: Node3D, transform_from_parent: Transform3D, boxes: Array[AABB]) -> void:
	var local := transform_from_parent * node.transform
	if node is MeshInstance3D and node.mesh != null:
		boxes.append(local * node.mesh.get_aabb())
	for child in node.get_children():
		if child is Node3D: collect_bounds(child, local, boxes)

func place(parent: Node3D, model: Node3D, at: Vector3, height: float, yaw: float) -> void:
	smooth_surfaces(model)
	var boxes: Array[AABB] = []
	collect_bounds(model, Transform3D.IDENTITY, boxes)
	assert(not boxes.is_empty(), "Asset has no mesh bounds")
	var bounds := boxes[0]
	for box in boxes: bounds = bounds.merge(box)
	var factor := height / maxf(bounds.size.y, 0.001)
	var holder := Node3D.new()
	parent.add_child(holder)
	holder.add_child(model)
	holder.scale = Vector3.ONE * factor
	holder.rotation.y = yaw
	holder.position = at - Vector3(0, bounds.position.y * factor, 0)

func select_mode(index: int) -> void:
	mode = index
	refresh()

func cycle_light() -> void:
	condition = (condition + 1) % 3
	refresh()

func set_pixel_effect(value: int) -> void:
	pixel_effect = clampi(value, 0, PIXEL_DIVISORS.size() - 1)
	# No FXAA blur; pixel modes retain deliberately crisp low-resolution edges.
	world_viewport.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
	world_viewport.msaa_3d = Viewport.MSAA_4X if pixel_effect == 0 else Viewport.MSAA_DISABLED
	update_pixel_size()
	for index in range(pixel_buttons.size()): pixel_buttons[index].disabled = index == pixel_effect
	refresh()

func update_pixel_size() -> void:
	var size := get_viewport().get_visible_rect().size
	var target: Vector2 = size / PIXEL_DIVISORS[pixel_effect]
	world_viewport.size = Vector2i(maxi(1, roundi(target.x)), maxi(1, roundi(target.y)))

func refresh() -> void:
	for index in range(versions.size()): versions[index].visible = index == mode
	var sky := environment.sky.sky_material as ProceduralSkyMaterial
	sky.sky_top_color = [Color("668fb9"), Color("6c759e"), Color("07162e")][condition]
	sky.sky_horizon_color = [Color("c0d2d1"), Color("edb58c"), Color("263c59")][condition]
	sky.ground_horizon_color = sky.sky_horizon_color
	sky.ground_bottom_color = Color("253d32") if condition != 2 else Color("060e1a")
	sun.rotation_degrees = [Vector3(-48, -35, 0), Vector3(-12, -65, 0), Vector3(-35, 145, 0)][condition]
	sun.light_color = [Color("fff1d9"), Color("ffc38c"), Color("a7c9f0")][condition]
	sun.light_energy = [1.25, 1.1, 0.32][condition]
	environment.ambient_light_energy = 0.55 if condition != 2 else 0.22
	environment.fog_light_color = sky.sky_horizon_color
	caption.text = "  %s | %s | %s\n  Drag to orbit / wheel to zoom / R reset\n  View 3: continuous wind meadow with a walking trail  " % [["Current assets", "Hand-painted samples", "Samples + wind meadow"][mode], ["Noon", "Sunset", "Night"][condition], PIXEL_NAMES[pixel_effect]]
	var focus := Vector3(0, 2.0, -4)
	camera.position = focus + Vector3(sin(azimuth) * cos(elevation), sin(elevation), cos(azimuth) * cos(elevation)) * distance
	camera.look_at(focus)

func _unhandled_input(event: InputEvent) -> void:
	if capturing: return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1: mode = 0
			KEY_2: mode = 1
			KEY_3: mode = 2
			KEY_N: condition = (condition + 1) % 3
			KEY_4: set_pixel_effect(0)
			KEY_5: set_pixel_effect(1)
			KEY_6: set_pixel_effect(2)
			KEY_7: set_pixel_effect(3)
			KEY_R:
				azimuth = 0.3
				elevation = 0.29
				distance = 23.0
	if event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
		azimuth -= event.relative.x * 0.005
		elevation = clampf(elevation + event.relative.y * 0.005, 0.08, 1.15)
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP: distance = maxf(8, distance - 1)
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN: distance = minf(35, distance + 1)
	refresh()

func capture() -> void:
	capturing = true
	get_tree().create_timer(90).timeout.connect(func(): push_error("Asset capture timed out"); get_tree().quit(1))
	var directory := "res://captures/" + RenderingServer.get_current_rendering_method()
	DirAccess.make_dir_recursive_absolute(directory)
	var report: Array[Dictionary] = []
	for light in range(3):
		condition = light
		for variant in range(3):
			mode = variant
			refresh()
			for frame in range(30): await get_tree().process_frame
			await RenderingServer.frame_post_draw
			var filename := "%s_%s.png" % [["noon", "sunset", "night"][light], ["current", "samples", "wind"][variant]]
			var result := get_viewport().get_texture().get_image().save_png(directory + "/" + filename)
			assert(result == OK, "Cannot save screenshot")
			report.append({"capture": filename, "draw_calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), "primitives": Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)})
	FileAccess.open(directory + "/report.json", FileAccess.WRITE).store_string(JSON.stringify(report, "\t"))
	print("ASSET REVIEW: 9 matched views captured; renderer=", RenderingServer.get_current_rendering_method())
	get_tree().quit()
