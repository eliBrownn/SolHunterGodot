extends Node3D
## Isolated art proof: generated geometry, existing painted textures, no game state.
const Builder = preload("res://scripts/scenery/procedural_plant_mesh.gd")
@export_range(1, 1000, 1) var generation_seed := 73
@export_range(3, 14, 1) var branch_count := 8
@export_range(0.02, 20.0, 0.02) var plant_size := 1.0
@export_range(0.02, 12.0, 0.02) var leaf_size := 1.0
@export_range(0.4, 1.8, 0.1) var foliage_density := 1.0
@export_range(0.0, 1.0, 0.05) var leaf_curl := 0.35
@export_range(0.0, 2.0, 0.1) var wind_strength := 0.6
@export var show_labels := true
var camera := Camera3D.new()
var samples := Node3D.new()
var materials: Array[Material] = []
var specimens: Array[Dictionary] = []
var family_picker := OptionButton.new()
var yaw := 0.12
var pitch := 0.68
var distance_value := 19.0
var elapsed := 0.0
var build_ms := 0.0
var previous_msaa: Viewport.MSAA

func _ready() -> void:
	var started := Time.get_ticks_usec()
	previous_msaa = get_viewport().msaa_3d
	get_viewport().msaa_3d = Viewport.MSAA_4X
	var world := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("202e36")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("c6d9df")
	environment.ambient_light_energy = 0.65
	world.environment = environment
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48,-28,0)
	sun.light_color = Color("fff0d6")
	sun.light_energy = 1.25
	sun.shadow_enabled = true
	add_child(sun)
	add_child(camera)
	camera.current = true
	camera.fov = 48
	add_child(samples)
	create_materials()
	for family in range(8): build_bed(family)
	update_camera()
	build_controls()
	build_ms = (Time.get_ticks_usec() - started) / 1000.0

func create_materials() -> void:
	materials = Builder.make_materials()

func build_bed(family: int) -> void:
	var bed := Node3D.new()
	bed.name = Builder.LABELS[family]
	bed.position = Vector3((family%4-1.5)*3.9,0,(-1.9 if family < 4 else 2.4))
	samples.add_child(bed)
	var soil := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 1.72
	cylinder.bottom_radius = 1.76
	cylinder.height = 0.15
	cylinder.radial_segments = 48
	soil.mesh = cylinder
	soil.position.y = -0.08
	var ground := StandardMaterial3D.new()
	ground.albedo_texture = preload("res://assets/terrain/ambientcg/ground048/Ground048_2K-JPG_Color.jpg")
	ground.normal_enabled = true
	ground.normal_texture = preload("res://assets/terrain/ambientcg/ground048/Ground048_2K-JPG_NormalGL.jpg")
	ground.roughness = 1.0
	soil.material_override = ground
	bed.add_child(soil)
	for variant in range(3):
		var builder := Builder.new()
		var specimen_seed := generation_seed*10000 + family*101 + variant
		var mesh: ArrayMesh = builder.create(family,specimen_seed,{"branches": branch_count,"leaf_scale": leaf_size,"foliage": foliage_density,"curl": leaf_curl},materials)
		var plant := MeshInstance3D.new()
		plant.name = "Variant%d" % (variant+1)
		plant.mesh = mesh
		plant.position = Vector3((variant-1)*0.88,0,0.38 if variant==1 else -0.2)
		plant.rotation.y = variant*2.399
		var size_factor := plant_size*(0.68 + variant*0.09) if family < 2 else plant_size
		plant.scale = Vector3.ONE*size_factor
		plant.extra_cull_margin = 0.3
		bed.add_child(plant)
		specimens.append({"family": Builder.LABELS[family],"seed": specimen_seed,"vertices": builder.counts.reduce(func(total: int, n: int): return total+n,0),"bounds": mesh.get_aabb()})
	if show_labels:
		var label := Label3D.new()
		label.text = "%02d  /  %s\n3 SEEDED VARIANTS" % [family+1,Builder.LABELS[family].to_upper()]
		label.position = Vector3(0,0.13,1.48)
		label.font_size = 32
		label.pixel_size = 0.005
		label.outline_size = 6
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		bed.add_child(label)

func build_controls() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var column := VBoxContainer.new()
	column.position = Vector2(16,14)
	layer.add_child(column)
	var title := Label.new()
	title.text = "PROCEDURAL PLANTS"
	title.add_theme_font_size_override("font_size",18)
	column.add_child(title)
	var hint := Label.new()
	hint.text = "Painted textures / generated forms\nRight-drag: orbit · Wheel: zoom"
	column.add_child(hint)
	family_picker.add_item("All growth forms")
	family_picker.name = "GrowthForm"
	for label in Builder.LABELS: family_picker.add_item(label)
	column.add_child(family_picker)
	family_picker.item_selected.connect(select_family)
	var next := Button.new()
	next.name = "SeedVariations"
	next.text = "New seed variations"
	column.add_child(next)
	next.pressed.connect(func():
		if get_parent() is SubViewport and get_parent().get_parent() != null:
			var host := get_parent().get_parent()
			while host != null and not host.has_method("load_fixture"): host = host.get_parent()
			if host != null:
				host.overrides["generation_seed"] = generation_seed%1000 + 1
				host.load_fixture.call_deferred()
				return
		generation_seed = generation_seed%1000 + 1
		for child in samples.get_children(): child.free()
		specimens.clear()
		for family in range(8): build_bed(family)
		select_family(family_picker.selected))
	var footer := Label.new()
	footer.text = "ART PROOF · Vastra forms provisional · Underwater deferred"
	footer.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	footer.offset_left = 16
	footer.offset_top = -30
	layer.add_child(footer)

func select_family(index: int) -> void:
	for family in range(samples.get_child_count()):
		var bed := samples.get_child(family) as Node3D
		bed.visible = index == 0 or family == index-1
		bed.position = Vector3((family%4-1.5)*3.9,0,(-1.9 if family<4 else 2.4)) if index == 0 else Vector3.ZERO
	distance_value = 19.0 if index == 0 else (8.0 if index <= 2 else 6.5)
	update_camera()

func _process(delta: float) -> void:
	elapsed += delta
	for index in range(1,materials.size()):
		materials[index].set_shader_parameter("wind_time",elapsed)
		materials[index].set_shader_parameter("wind_strength",wind_strength)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_RIGHT:
		yaw -= event.relative.x*0.008
		pitch = clampf(pitch+event.relative.y*0.006,0.15,1.35)
		update_camera()
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP: distance_value = maxf(0.015,distance_value*0.85)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN: distance_value = minf(10000,distance_value/0.85)
		update_camera()

func update_camera() -> void:
	var target := Vector3(0,0.9 if family_picker.selected in [1,2] else 0.6,0)
	camera.position = target + Vector3(sin(yaw)*cos(pitch),sin(pitch),cos(yaw)*cos(pitch))*distance_value
	camera.look_at(target)

func _exit_tree() -> void:
	get_viewport().msaa_3d = previous_msaa

func workstation_readings() -> Dictionary:
	return {"specimens": specimens,"build_ms": build_ms,"seed": generation_seed,"scope": "Isolated morphology proof; no expedition or ecology writes", "textures": ["Leaves.png","Flowers.png","Bark_NormalTree.png + authored normal","Ground048 + authored normal"]}
