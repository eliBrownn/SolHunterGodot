extends Node3D
## Isolated art experiment. All readings are synthetic; no expedition or ecology access.

const PRESETS := ["Low energy", "Ambient", "Rich / healthy", "Restorative", "Disturbed", "All-affinity storm"]
# Concentration and signed overload remain independent. These are art samples, not mechanics.
const VALUES := [[10,0,0.3,0.06,0.055,0.45,1.0], [45,0,0.65,0.16,0.075,0.55,1.4], [95,0,0.55,0.12,0.08,0.6,1.6], [65,-70,0.35,0.08,0.09,0.55,1.6], [45,85,1.2,0.5,0.08,0.7,2.0], [90,0,1.8,0.65,0.1,0.75,2.4]]
const AFFINITIES := ["Air", "Fire", "Water", "Earth", "Lightning", "Void", "Spectral", "Quantum"]
const TINTS := [Color("b7eee6"),Color("ff9254"),Color("459fe8"),Color("ba9465"),Color("f5d65b"),Color("604099"),Color("9df1ca"),Color("ed8edd")]
@export_range(128,4096,128) var max_members := 128
@export_range(4,16,1) var trail_samples := 10
@export_range(2.0,8.0,0.5) var field_radius := 4.0
var particles := GPUParticles3D.new()
var motion := ShaderMaterial.new()
var draw := ShaderMaterial.new()
var camera := Camera3D.new()
var environment := Environment.new()
var sun := DirectionalLight3D.new()
var dummy := MeshInstance3D.new()
var controls: Dictionary = {}
var preset_picker := OptionButton.new()
var pattern_picker := OptionButton.new()
var affinity_picker := OptionButton.new()
var status := Label.new()
var pause_button := Button.new()
var moving := false
var frozen := false
var elapsed := 0.0
var yaw := 0.5
var pitch := 0.5
var distance := 12.0
var selected_preset := 1
var all_colors := false
var body_enabled := false
var night := false
var night_toggle: CheckButton
var body_toggle: CheckButton
var walk_toggle: CheckButton
var plant_nodes: Node3D
var ambient_toggle := CheckButton.new()
var clear_toggle := CheckButton.new()
var appearance_picker := OptionButton.new()
var settings_dialog: AcceptDialog
var settings_text: TextEdit
var settings_json := ""
var clear_view := false
var floor_node := MeshInstance3D.new()

func _ready() -> void:
	DisplayServer.window_set_title("SolHunter — Vastra particle lab")
	build_stage()
	build_particles()
	build_controls()
	apply_preset(1)
	apply_owner_baseline()
	update_camera()

func build_stage() -> void:
	var world := WorldEnvironment.new()
	world.environment = environment
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("293e42")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("a9bfab")
	environment.ambient_light_energy = 0.65
	environment.glow_enabled = true
	environment.glow_intensity = 0.65
	add_child(world)
	sun.rotation_degrees = Vector3(-48,-28,0)
	sun.light_energy = 1.4
	add_child(sun)
	var floor_mesh := PlaneMesh.new()
	floor_mesh.size = Vector2(28,28)
	floor_node.mesh = floor_mesh
	var floor_material := StandardMaterial3D.new()
	floor_material.albedo_color = Color("34443b")
	floor_node.material_override = floor_material
	add_child(floor_node)
	plant_nodes = preload("res://tools/vastra_particle_nodes.gd").new()
	add_child(plant_nodes)
	plant_nodes.bind(self)
	var body := CapsuleMesh.new()
	body.radius = 0.22
	body.height = 0.85
	dummy.mesh = body
	dummy.position.y = 0.425
	var neutral := StandardMaterial3D.new()
	neutral.albedo_color = Color("d4c9af")
	dummy.material_override = neutral
	add_child(dummy)
	dummy.hide()
	add_child(camera)
	camera.current = true
	camera.fov = 48

func build_particles() -> void:
	motion.shader = preload("res://shaders/vastra_particle_lab_motion.gdshader")
	draw.shader = preload("res://shaders/vastra_particle_lab_draw.gdshader")
	draw.set_shader_parameter("field_noise", optical_noise())
	particles.amount = max_members * (trail_samples+1)
	particles.lifetime = 3600.0
	particles.explosiveness = 1.0
	particles.local_coords = true
	particles.fixed_fps = 60
	particles.use_fixed_seed = true
	particles.seed = 291030
	particles.process_material = motion
	motion.set_shader_parameter("trail_samples",trail_samples)
	motion.set_shader_parameter("spread",field_radius)
	draw.set_shader_parameter("spread",field_radius)
	var ports := PackedVector3Array()
	for row in plant_nodes.rows: ports.append(row.port)
	motion.set_shader_parameter("plant_ports",ports)
	draw.set_shader_parameter("plant_ports",ports)
	var quad := filament_mesh()
	quad.surface_set_material(0,draw)
	particles.draw_pass_1 = quad
	particles.visibility_aabb = AABB(Vector3(-10,-2,-10),Vector3(20,12,20))
	particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	particles.preprocess = 0.1
	add_child(particles)

func build_controls() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var panel := PanelContainer.new()
	panel.position = Vector2(16,16)
	panel.custom_minimum_size.x = 300
	layer.add_child(panel)
	var scroll := ScrollContainer.new()
	panel.add_child(scroll)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var fit_panel := func(): panel.size = Vector2(386, maxf(200, get_viewport().get_visible_rect().size.y-32))
	get_viewport().size_changed.connect(fit_panel)
	fit_panel.call()
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation",4)
	scroll.add_child(box)
	var title := Label.new()
	title.text = "VASTRA · PARTICLE LAB"
	title.add_theme_font_size_override("font_size",20)
	box.add_child(title)
	var note := Label.new()
	note.text = "Visual samples · separate from the game\n1–6 states · right-drag orbit · wheel zoom"
	box.add_child(note)
	var row := HBoxContainer.new()
	box.add_child(row)
	pause_button.text = "Pause [Space]"
	row.add_child(pause_button)
	pause_button.pressed.connect(toggle_pause)
	var reset := Button.new()
	reset.text = "Reset motion [R]"
	row.add_child(reset)
	reset.pressed.connect(reset_motion)
	clear_toggle.text = "Clear view · isolate interaction"
	box.add_child(clear_toggle)
	clear_toggle.toggled.connect(set_clear_view)
	appearance_picker.add_item("In-game look · filament particles")
	appearance_picker.add_item("Earlier glowing trail comparison")
	box.add_child(appearance_picker)
	appearance_picker.item_selected.connect(func(index: int):
		draw.set_shader_parameter("appearance",index)
		controls["Glow"].value=1.4 if index==1 else 0.0)
	plant_nodes.build_controls(box)
	ambient_toggle.text = "Show ambient field"
	ambient_toggle.button_pressed = true
	box.add_child(ambient_toggle)
	ambient_toggle.toggled.connect(func(on: bool): particles.visible=on and not clear_view)
	var copy := Button.new()
	copy.text = "Copy all test parameters"
	box.add_child(copy)
	copy.pressed.connect(copy_parameters)
	var baseline_button := Button.new()
	baseline_button.text="Restore your baseline"
	box.add_child(baseline_button)
	baseline_button.pressed.connect(apply_owner_baseline)
	var field_title := Label.new()
	field_title.text = "AMBIENT FIELD · scroll for more controls"
	box.add_child(field_title)
	for preset in PRESETS: preset_picker.add_item(preset)
	box.add_child(preset_picker)
	preset_picker.item_selected.connect(apply_preset)
	for pattern in ["Landscape currents", "Grove circulation", "Rising vortex"]: pattern_picker.add_item(pattern)
	box.add_child(pattern_picker)
	pattern_picker.item_selected.connect(func(index: int): motion.set_shader_parameter("pattern",index); draw.set_shader_parameter("pattern",index))
	for affinity in AFFINITIES: affinity_picker.add_item(affinity)
	affinity_picker.add_item("All affinities")
	affinity_picker.add_item("Neutral field optics")
	box.add_child(affinity_picker)
	affinity_picker.item_selected.connect(set_affinity)
	add_slider(box,"Concentration",0,100,1,45)
	add_slider(box,"Overload",-100,100,1,0)
	add_slider(box,"Flow speed",0,3,0.05,0.65)
	add_slider(box,"Turbulence",0,1,0.02,0.16)
	add_slider(box,"Particle size",0.02,0.2,0.005,0.075)
	add_slider(box,"Opacity",0,1,0.05,0.55)
	add_slider(box,"Glow",0,4,0.1,1.4)
	add_slider(box,"Trail seconds",0.05,1.5,0.05,0.65)
	add_slider(box,"Field height",0.3,4,0.1,1.6)
	add_slider(box,"Filament length",0.15,2.0,0.05,1.1)
	add_slider(box,"Refraction",0.0,0.01,0.0005,0.003)
	add_slider(box,"Ambient visibility",0.0,1.0,0.05,1.0)
	var body := CheckButton.new()
	body_toggle=body
	body.text = "Character disturbance (visual test)"
	box.add_child(body)
	body.toggled.connect(func(on: bool): body_enabled=on; dummy.visible=on and not clear_view)
	var walk := CheckButton.new()
	walk_toggle=walk
	walk.text = "Walk character through field"
	box.add_child(walk)
	walk.toggled.connect(func(on: bool): moving=on)
	var dark := CheckButton.new()
	night_toggle=dark
	dark.text = "Night lighting"
	box.add_child(dark)
	dark.toggled.connect(func(on: bool):
		night=on
		sun.light_energy=0.12 if on else 1.4
		environment.ambient_light_energy=0.16 if on else 0.65
		environment.background_color=Color("0d1723") if on else Color("293e42"))
	status.text = ""
	box.add_child(status)

func add_slider(box: VBoxContainer, caption: String, low: float, high: float, step: float, initial: float) -> void:
	var label := Label.new()
	box.add_child(label)
	var slider := HSlider.new()
	slider.min_value=low
	slider.max_value=high
	slider.step=step
	slider.value=initial
	box.add_child(slider)
	controls[caption]=slider
	slider.value_changed.connect(func(value: float):
		label.text="%s: %.3f" % [caption,value]
		apply_tuning())
	label.text="%s: %.3f" % [caption,initial]

func apply_preset(index: int) -> void:
	selected_preset=index
	preset_picker.select(index)
	var keys := ["Concentration","Overload","Flow speed","Turbulence","Particle size","Opacity","Glow"]
	for i in range(keys.size()): controls[keys[i]].value=VALUES[index][i]
	controls["Trail seconds"].value=0.65
	controls["Field height"].value=2.8 if index==5 else 1.6
	pattern_picker.select(2 if index==5 else 0)
	motion.set_shader_parameter("pattern",pattern_picker.selected)
	draw.set_shader_parameter("pattern",pattern_picker.selected)
	affinity_picker.select(8 if index==5 else 9)
	set_affinity(affinity_picker.selected)
	controls["Glow"].value=0.0 if appearance_picker.selected==0 else VALUES[index][6]
	reset_motion()
	apply_tuning()

func set_affinity(index: int) -> void:
	all_colors=index==8
	draw.set_shader_parameter("all_affinities",all_colors)
	if not all_colors: draw.set_shader_parameter("tint",Color.WHITE if index==9 else TINTS[index])

func apply_tuning() -> void:
	if controls.size()<12: return
	var concentration: float=controls["Concentration"].value
	# Synthetic optical coverage only; no saved concentration is consumed.
	particles.amount_ratio=concentration/100.0
	for pair in [["Flow speed","flow_speed"],["Turbulence","turbulence"],["Trail seconds","trail_seconds"],["Field height","field_height"]]:
		motion.set_shader_parameter(pair[1],controls[pair[0]].value)
		draw.set_shader_parameter(pair[1],controls[pair[0]].value)
	for pair in [["Particle size","particle_size"],["Opacity","opacity"],["Glow","glow"],["Filament length","filament_length"],["Refraction","refraction"]]:
		draw.set_shader_parameter(pair[1],controls[pair[0]].value)
	draw.set_shader_parameter("visibility_scale",controls["Ambient visibility"].value)
	var overload: float=controls["Overload"].value/100.0
	motion.set_shader_parameter("turbulence",maxf(0.0,controls["Turbulence"].value+maxf(overload,0.0)*0.35+minf(overload,0.0)*0.08))
	draw.set_shader_parameter("turbulence",motion.get_shader_parameter("turbulence"))
	status.text="%s heads · %s sprites/head\nSigned overload is an independent art input." % [roundi(max_members*concentration/100.0),trail_samples+1]

func reset_motion() -> void:
	elapsed=0.0
	motion.set_shader_parameter("animation_time",0.0)
	draw.set_shader_parameter("animation_time",0.0)
	dummy.position=Vector3(0,0.425,0)
	motion.set_shader_parameter("body_position",dummy.position)
	draw.set_shader_parameter("body_position",dummy.position)
	particles.restart()
	if plant_nodes != null and not plant_nodes.controls.is_empty(): plant_nodes.reset_nodes()

func toggle_pause() -> void:
	frozen=not frozen
	pause_button.text="Resume [Space]" if frozen else "Pause [Space]"

func _process(delta: float) -> void:
	if frozen: return
	plant_nodes.advance(delta)
	elapsed+=delta
	motion.set_shader_parameter("animation_time",elapsed)
	draw.set_shader_parameter("animation_time",elapsed)
	if moving: dummy.position=Vector3(sin(elapsed*0.55)*3.5,0.425,sin(elapsed*1.1)*0.6)
	motion.set_shader_parameter("body_position",dummy.position)
	draw.set_shader_parameter("body_position",dummy.position)
	motion.set_shader_parameter("disturbance",0.8 if body_enabled else 0.0)
	draw.set_shader_parameter("disturbance",0.8 if body_enabled else 0.0)

func update_camera() -> void:
	var target := Vector3(0,0.8,0)
	camera.position=target+Vector3(sin(yaw)*cos(pitch),sin(pitch),cos(yaw)*cos(pitch))*distance
	camera.look_at(target)
	# Keep the field centered in the space beside the controls.
	camera.h_offset=-1.8

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode>=KEY_1 and event.keycode<=KEY_6: apply_preset(event.keycode-KEY_1)
		if event.keycode==KEY_SPACE: toggle_pause()
		if event.keycode==KEY_R: reset_motion()
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		yaw-=event.relative.x*0.008
		pitch=clampf(pitch+event.relative.y*0.006,0.1,1.4)
		update_camera()
	if event is InputEventMouseButton and event.pressed:
		if event.button_index==MOUSE_BUTTON_WHEEL_UP: distance=maxf(3.0,distance*0.9)
		if event.button_index==MOUSE_BUTTON_WHEEL_DOWN: distance=minf(25.0,distance*1.1)
		update_camera()



func copy_parameters(output_path: String = "res://artifacts/vastra-particle-lab/latest-settings.json") -> void:
	var values := {}
	for key in controls: values[key]=controls[key].value
	var snapshot := {"lab_version":7,"max_members":max_members,"trail_samples":trail_samples,"field_radius":field_radius,"appearance":appearance_picker.get_item_text(appearance_picker.selected),"clear_view":clear_view,"preset":PRESETS[selected_preset],"pattern":pattern_picker.get_item_text(pattern_picker.selected),"affinity":affinity_picker.get_item_text(affinity_picker.selected),"ambient_visible":particles.visible,"night":night,"character":body_enabled,"walking":moving,"values":values,"plants":plant_nodes.settings()}
	settings_json=JSON.stringify(snapshot,"  ")
	DirAccess.make_dir_recursive_absolute("res://artifacts/vastra-particle-lab")
	var file := FileAccess.open(output_path,FileAccess.WRITE)
	if file != null: file.store_string(settings_json)
	if settings_dialog == null:
		settings_dialog=AcceptDialog.new()
		settings_dialog.title="Test parameters · select text and copy, or use the saved JSON file"
		settings_dialog.ok_button_text="Close"
		settings_dialog.add_button("Copy again",false,"copy")
		settings_dialog.custom_action.connect(func(action: StringName):
			if action==&"copy": copy_settings_clipboard())
		settings_text=TextEdit.new()
		settings_text.custom_minimum_size=Vector2(640,420)
		settings_text.editable=false
		settings_dialog.add_child(settings_text)
		add_child(settings_dialog)
	settings_text.text=settings_json
	settings_dialog.popup_centered(Vector2i(760,560))
	settings_text.grab_focus()
	settings_text.select_all()
	copy_settings_clipboard()

func copy_settings_clipboard() -> void:
	DisplayServer.clipboard_set(settings_json)
	var verified := DisplayServer.clipboard_get()==settings_json
	plant_nodes.note("Clipboard verified · parameters also displayed and saved." if verified else "Clipboard unavailable · select the displayed text or use latest-settings.json.")

func set_clear_view(enabled: bool) -> void:
	clear_view=enabled
	floor_node.visible=not enabled
	particles.visible=ambient_toggle.button_pressed and not enabled
	ambient_toggle.disabled=enabled
	dummy.visible=body_enabled and not enabled
	plant_nodes.update_visibility()

func optical_noise() -> ImageTexture3D:
	# Identical seed/volume construction to the current in-game optical material.
	var rng := RandomNumberGenerator.new()
	rng.seed=721031
	var slices: Array[Image]=[]
	for z in range(32):
		var bytes := PackedByteArray()
		bytes.resize(32*32*4)
		for pixel in range(32*32):
			var value := rng.randi()
			for channel in range(4): bytes[pixel*4+channel]=(value>>(channel*8))&255
		slices.append(Image.create_from_data(32,32,false,Image.FORMAT_RGBA8,bytes))
	var texture := ImageTexture3D.new()
	texture.create(Image.FORMAT_RGBA8,32,32,32,false,slices)
	return texture

func filament_mesh() -> ArrayMesh:
	return preload("res://scripts/presentation/vastra_filament_mesh.gd").create()

func apply_owner_baseline() -> void:
	var data: Variant=JSON.parse_string(FileAccess.get_file_as_string("res://resources/vastra_particle_lab_baseline.json"))
	if not data is Dictionary: return
	apply_preset(PRESETS.find(data.preset))
	pattern_picker.select(2)
	motion.set_shader_parameter("pattern",2)
	draw.set_shader_parameter("pattern",2)
	affinity_picker.select(9)
	set_affinity(9)
	for key in data.values:
		if controls.has(key): controls[key].value=data.values[key]
	for key in data.plants.values:
		if plant_nodes.controls.has(key): plant_nodes.controls[key].value=data.plants.values[key]
	plant_nodes.scenario.select(0)
	plant_nodes.source.select(2)
	plant_nodes.target.select(1)
	plant_nodes.source.disabled=false
	ambient_toggle.button_pressed=data.ambient_visible
	night_toggle.button_pressed=data.night
	body_toggle.button_pressed=data.character
	walk_toggle.button_pressed=data.walking
	clear_toggle.button_pressed=data.clear_view
	reset_motion()
	apply_tuning()
	plant_nodes.note("Your baseline restored · C → B needs root-return mode to send.")
