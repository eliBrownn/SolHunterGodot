extends Node3D
## Disposable visual fixture. Never reads or writes expedition state.

const Batch = preload("res://scripts/presentation/vessel_particle_swarm.gd")
var vessels: GPUParticles3D
var camera := Camera3D.new()
var caption := Label.new()
var target := Vector3(0, 0.23, 0.03)
var distance := 0.34
var yaw := 0.6
var pitch := 0.34
var environment := Environment.new()
var sun := DirectionalLight3D.new()
var view := 0
var anger := 0.5
var aberration_pixels := 12.0
var aberration_label := Label.new()
var aberration_meter := ProgressBar.new()
var anger_slider := HSlider.new()
var aberration_slider := HSlider.new()

func _ready() -> void:
	DisplayServer.window_set_title("SolHunter — Woodland Vessel study")
	var world := WorldEnvironment.new()
	world.environment = environment
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("33483d")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("a9bfab")
	environment.ambient_light_energy = 0.7
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.glow_enabled = true
	environment.glow_intensity = 0.8
	add_child(world)
	sun.rotation_degrees = Vector3(-48, -28, 0)
	sun.light_color = Color("fff0cc")
	sun.light_energy = 1.6
	sun.shadow_enabled = true
	add_child(sun)
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(30, 30)
	ground.mesh = plane
	var moss := StandardMaterial3D.new()
	moss.albedo_color = Color("43563a")
	moss.roughness = 1
	ground.material_override = moss
	add_child(ground)
	# Existing scenery supplies scale and context, with a clear foreground perch.
	place("res://assets/nature/Rock_Medium_1.gltf", Vector3(-0.07, 0, 0.02), 0.25)
	for i in range(18):
		var angle := i * 2.39996
		var radius := 0.32 + float(i % 5) * 0.27
		place("res://assets/nature/Grass_Common_Short.gltf", Vector3(cos(angle) * radius, 0, sin(angle) * radius), 0.18)
	place("res://assets/nature/CommonTree_1.gltf", Vector3(-2, 0, -2), 4.5)
	place("res://assets/nature/CommonTree_1.gltf", Vector3(2, 0, -3), 5.0)
	add_child(camera)
	camera.current = true
	camera.near = 0.005
	camera.fov = 48
	var canvas := CanvasLayer.new()
	add_child(canvas)
	var panel := PanelContainer.new()
	canvas.add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	panel.offset_left = -18
	panel.offset_right = -18
	panel.offset_top = 18
	panel.offset_bottom = 18
	caption.add_theme_font_size_override("font_size", 18)
	var controls := VBoxContainer.new()
	panel.add_child(controls)
	controls.add_child(caption)
	controls.add_child(aberration_label)
	aberration_meter.max_value = 24.0
	aberration_meter.show_percentage = false
	aberration_meter.custom_minimum_size = Vector2(360, 12)
	controls.add_child(aberration_meter)
	for label_text in ["Anger", "Maximum color separation (pixels)"]:
		var title := Label.new()
		title.text = label_text
		controls.add_child(title)
		var slider := anger_slider if label_text == "Anger" else aberration_slider
		slider.max_value = 1.0 if slider == anger_slider else 24.0
		slider.step = 0.05 if slider == anger_slider else 0.5
		controls.add_child(slider)
	anger_slider.value_changed.connect(func(value: float):
		anger = value
		vessels.anger = anger
		update_caption())
	aberration_slider.value_changed.connect(func(value: float):
		aberration_pixels = value
		vessels.aberration_pixels = value
		update_caption())
	set_view(0)

func place(path: String, at: Vector3, height: float) -> void:
	var packed: PackedScene = load(path)
	var art := preload("res://scripts/scenery/nature_art.gd")
	var bounds: AABB = art.parts(packed).bounds
	var item := packed.instantiate() as Node3D
	var factor := height / maxf(bounds.size.y, 0.001)
	item.scale = Vector3.ONE * factor
	item.position = at - Vector3(0, bounds.position.y * factor, 0)
	add_child(item)

func set_view(index: int) -> void:
	view = index
	if is_instance_valid(vessels):
		remove_child(vessels)
		vessels.queue_free()
	vessels = Batch.new()
	vessels.member_count = [1, 128, 2048][index]
	vessels.spread = [0.0, 0.8, 2.5][index]
	# Smaller inspection orbit keeps the tiny body in frame; field views retain full flight.
	if index == 0: vessels.flight_radius = 0.06
	vessels.anger = anger
	vessels.aberration_pixels = aberration_pixels
	# Keep the entire close-up flight above the 25 cm reference rock.
	vessels.position.y = 0.36 if index == 0 else 0.45
	add_child(vessels)
	target = Vector3(0, vessels.position.y + 0.012, 0)
	distance = [0.28, 3.6, 8.0][index]
	update_caption()
	update_camera()

func update_caption() -> void:
	caption.text = "VESSEL PARTICLES · %s\n1 Close-up   2 Small swarm   3 Many   ·   Drag to orbit · Wheel to zoom\nSpace: hold motion · N: day/night · R: reset · A: anger %d%%\nGlowing orbs + fading wakes · %s Vessels / %s particles" % [["Close inspection", "Field scale", "Density study"][view], roundi(anger * 100), vessels.member_count, vessels.amount]
	var applied := aberration_pixels * anger * anger
	var warp: float = vessels.refraction_pixels * (0.005 + 1.995 * anger * anger)
	aberration_label.text = "Warp: %.2f px · color offset: %.2f px / %.1f maximum" % [warp, applied, aberration_pixels]
	aberration_meter.value = applied
	anger_slider.set_value_no_signal(anger)
	aberration_slider.set_value_no_signal(aberration_pixels)

func update_camera() -> void:
	camera.position = target + Vector3(sin(yaw) * cos(pitch), sin(pitch), cos(yaw) * cos(pitch)) * distance
	camera.look_at(target)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1: set_view(0)
			KEY_2: set_view(1)
			KEY_3: set_view(2)
			KEY_R: yaw = 0.6; pitch = 0.34; set_view(view)
			KEY_SPACE: vessels.frozen = not vessels.frozen
			KEY_A:
				anger = 0.0 if anger >= 1.0 else anger + 0.25
				vessels.anger = anger
				update_caption()
			KEY_N:
				var night := environment.ambient_light_energy > 0.2
				environment.ambient_light_energy = 0.12 if night else 0.7
				sun.light_energy = 0.12 if night else 1.6
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		yaw -= event.relative.x * 0.008
		pitch = clampf(pitch + event.relative.y * 0.005, -0.1, 1.35)
		update_camera()
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP: distance = maxf(0.15, distance * 0.85)
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN: distance = minf(15.0, distance / 0.85)
		update_camera()
