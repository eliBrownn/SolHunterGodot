extends Node3D
## Isolated art prototype. One mesh instance is one blade; no ecological writes.
## The production meadow, weather and Vastra owners are not changed by this lab.
## Existing plant ledger owns all visible packet endpoints and timing.
@export var vastra_visible := true
@export var night_view := false
@export_range(0.0, 1.0, 0.05) var vastra_visibility := 0.55
@export_range(0.05, 1.5, 0.05) var vastra_height := 0.35
@export_range(0.02, 0.3, 0.01) var vastra_thickness := 0.12
@export_range(0.25, 4.0, 0.25) var simulation_speed := 1.0
@export_range(16, 256, 16) var vastra_filaments := 32
@export_range(10, 300, 10) var blades_per_square_metre := 100
@export_range(0.15, 1.2, 0.05) var blade_height := 0.5
@export_range(0.01, 0.12, 0.005) var blade_width := 0.045
@export_range(0.0, 0.6, 0.02) var blade_curve := 0.22
@export_range(0.0, 2.0, 0.1) var wind_strength := 0.8
@export_range(0.0, 360.0, 5.0) var wind_direction_degrees := 35.0
const NAMES := ["MEADOW", "WOODLAND", "HEATH", "MARSH"]
const COLORS := [Color("879e65"), Color("46764a"), Color("9a8c52"), Color("528867")]
const HEIGHTS := [1.0, 0.75, 0.55, 1.65]
const WIDTHS := [1.0, 1.5, 0.65, 0.65]
const CURVES := [1.0, 1.4, 0.9, 0.3]
const COVER := [1.0, 0.75, 0.45, 0.8]
var camera := Camera3D.new()
var materials: Array[ShaderMaterial] = []
var blade_counts: Array[int] = []
var elapsed := 0.0
var yaw := 0.0
var pitch := 0.65
var distance_value := 11.0
var previous_msaa: Viewport.MSAA
var vastra_network: Node3D
var optical_noise: ImageTexture3D
var functional_readout := Label.new()

static func blade_mesh(width: float, curve: float) -> ArrayMesh:
	return preload("res://scripts/scenery/grass_blade_mesh.gd").create(width,curve)

func _ready() -> void:
	previous_msaa = get_viewport().msaa_3d
	get_viewport().msaa_3d = Viewport.MSAA_4X
	var world := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("101d2a") if night_view else Color("25343c")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("c2d8e0")
	environment.ambient_light_energy = 0.22 if night_view else 0.65
	world.environment = environment
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48,-35,0)
	sun.light_color = Color("fff1cf")
	sun.light_energy = 0.18 if night_view else 1.3
	sun.shadow_enabled = true
	add_child(sun)
	add_child(camera)
	camera.current = true
	camera.fov = 48
	# Reuse the exact noise construction from the existing Vastra lab.
	optical_noise = preload("res://tools/vastra_particle_lab.gd").optical_noise()
	for biome in range(4): build_patch(biome)
	vastra_network = preload("res://tools/grass_vastra_fixture.gd").new()
	add_child(vastra_network)
	vastra_network.bind(self)
	update_camera()
	var layer := CanvasLayer.new()
	add_child(layer)
	var hint := Label.new()
	hint.text = "GRASS + VASTRA  /  FOUR BIOMES\nRight-drag to orbit · Wheel to zoom\nToggle Vastra / night in the sidebar · Drag sliders"
	hint.position = Vector2(16,16)
	hint.add_theme_font_size_override("font_size",16)
	layer.add_child(hint)
	functional_readout.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	functional_readout.offset_left = 16
	functional_readout.offset_top = -84
	functional_readout.add_theme_font_size_override("font_size",15)
	layer.add_child(functional_readout)

func build_patch(biome: int) -> void:
	var center := Vector3(-1.85 if biome % 2 == 0 else 1.85,0,-1.85 if biome < 2 else 1.85)
	var soil := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(3,0.12,3)
	soil.mesh = box
	soil.position = center - Vector3(0,0.065,0)
	var soil_material := StandardMaterial3D.new()
	soil_material.albedo_color = COLORS[biome].darkened(0.56)
	soil_material.roughness = 1.0
	soil.material_override = soil_material
	add_child(soil)
	var shader_material := ShaderMaterial.new()
	shader_material.shader = preload("res://shaders/meadow.gdshader")
	shader_material.set_shader_parameter("ground_base_color",COLORS[biome])
	shader_material.set_shader_parameter("wind_displacement",0.12)
	shader_material.set_shader_parameter("distant_density",1.0)
	materials.append(shader_material)
	var source := blade_mesh(blade_width * WIDTHS[biome],blade_curve * CURVES[biome])
	source.surface_set_material(0,shader_material)
	var batch := MultiMesh.new()
	batch.transform_format = MultiMesh.TRANSFORM_3D
	batch.use_colors = true
	batch.mesh = source
	batch.instance_count = int(9 * blades_per_square_metre * COVER[biome])
	blade_counts.append(batch.instance_count)
	var rng := RandomNumberGenerator.new()
	rng.seed = 83471 + biome
	for index in range(batch.instance_count):
		var height: float = blade_height * HEIGHTS[biome] * rng.randf_range(0.7,1.25)
		var at := center + Vector3(rng.randf_range(-1.46,1.46),0,rng.randf_range(-1.46,1.46))
		var basis := Basis(Vector3.UP,rng.randf_range(0,TAU)).scaled(Vector3(1,height,1))
		batch.set_instance_transform(index,Transform3D(basis,at))
		var tint := Color.WHITE.darkened(rng.randf_range(0,0.18))
		tint.a = rng.randf()
		batch.set_instance_color(index,tint)
	var blades := MultiMeshInstance3D.new()
	blades.name = NAMES[biome].capitalize() + "SingleBlades"
	blades.multimesh = batch
	blades.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Include maximum shader movement in the culling bounds.
	blades.extra_cull_margin = 0.5
	add_child(blades)
	var label := Label3D.new()
	label.text = NAMES[biome]
	label.position = center + Vector3(0,0.1,1.75)
	label.font_size = 48
	label.pixel_size = 0.006
	label.outline_size = 8
	add_child(label)

func _process(delta: float) -> void:
	elapsed += delta * simulation_speed
	vastra_network.advance(delta * simulation_speed)
	var ledger: Dictionary = vastra_network.readings()
	functional_readout.text = "LIVE TEST LEDGER · %d cell reserves · %d packets\nStored %.0f · Travelling %.0f · Balance error %.3f\nGrass → tree reserves / Tree roots → grass · Seeded test state" % [ledger.registered_cells,ledger.active_transfers,ledger.stored,ledger.in_transit,ledger.conservation_error]
	var direction := Vector2.from_angle(deg_to_rad(wind_direction_degrees))
	for surface in materials:
		surface.set_shader_parameter("wind_direction",direction)
		surface.set_shader_parameter("wind_strength",wind_strength)
		surface.set_shader_parameter("wind_time",elapsed)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_RIGHT:
		yaw -= event.relative.x * 0.008
		pitch = clampf(pitch + event.relative.y * 0.006,0.12,1.35)
		update_camera()
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP: distance_value = maxf(3,distance_value-0.65)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN: distance_value = minf(24,distance_value+0.65)
		update_camera()

func update_camera() -> void:
	camera.position = Vector3(sin(yaw)*cos(pitch),sin(pitch),cos(yaw)*cos(pitch)) * distance_value
	camera.look_at(Vector3(0,0.15,0))

func workstation_readings() -> Dictionary:
	return {"single_blade_instances":blade_counts,"triangles_per_blade":7,"biomes":NAMES,"wind_seconds":elapsed,"functional_network":vastra_network.readings(),"vastra_visible":vastra_visible,"vastra_visibility":vastra_visibility,"vastra_height":vastra_height,"vastra_clock":elapsed,"night":night_view,"vastra_paths":"Real flora_transfers source/target IDs, root/crown anchors and arrival ticks","scope":"Art fixture; no expedition ledger or weather writes"}

func _exit_tree() -> void:
	get_viewport().msaa_3d = previous_msaa


func workstation_parameter_info(key: String) -> Dictionary:
	var groups := {
		"blade_height": ["Appearance", "Blade height (m)", 0],
		"blade_width": ["Appearance", "Blade width (m)", 1],
		"blade_curve": ["Appearance", "Blade curvature", 2],
		"blades_per_square_metre": ["Coverage", "Blades per m²", 3],
		"wind_strength": ["Motion", "Wind strength", 4],
		"wind_direction_degrees": ["Motion", "Wind direction (°)", 5],
		"night_view": ["View", "Night lighting", 6],
		"vastra_visible": ["Vastra display", "Show Vastra", 7],
		"vastra_visibility": ["Vastra display", "Visibility", 8],
		"vastra_height": ["Vastra display", "Path arc height (m)", 9],
		"vastra_thickness": ["Vastra display", "Filament thickness (m)", 10],
		"vastra_filaments": ["Vastra display", "Filament count", 11],
		"simulation_speed": ["Simulation", "Shared clock speed (×)", 12]
	}
	if not groups.has(key): return {}
	var item: Array = groups[key]
	return {"group": item[0], "label": item[1], "order": item[2], "help": "Applies on release; rebuilds the lab sample and restarts its simulation. Camera and baseline are retained."}
