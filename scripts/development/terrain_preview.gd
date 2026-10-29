extends Node3D
## T0 review scene: raw landforms, scale references and maps. No game state or saves.

const StudyMesh = preload("res://scripts/development/terrain_study_mesh.gd")
const NatureArt = preload("res://scripts/scenery/nature_art.gd")
const MODEL = preload("res://assets/characters/rogue/Rogue_Hooded.glb")
const IDLE_RIG = preload("res://assets/characters/rogue/Rig_Medium_General.glb")
const TREE = preload("res://assets/nature/CommonTree_1.gltf")
const ROCK = preload("res://assets/nature/Rock_Medium_1.gltf")
## Preview seed only. Restart/rebuild to apply. The live expedition is untouched.
@export_range(0, 2147483646) var study_seed := 2601026
## Three connected comparison resources, applied by the preset buttons or keys 1–3.
@export var presets: Array[TerrainReliefSettings] = []

var field: TerrainHeightfield
var terrain: WorldTerrain
var geometry := Node3D.new()
var camera := Camera3D.new()
var environment := Environment.new()
var avatar: Node3D
var info := Label.new()
var selected := 1
var actor_cell := Vector2(14.5, 2.5)
var azimuth := -1.2
var elevation := 0.33
var distance := 22.0
var overview := false
var dragging := false
var maps: HBoxContainer

func _ready() -> void:
	if presets.size() != 3:
		presets = [load("res://resources/terrain_very_gentle.tres"), load("res://resources/terrain_rolling.tres"), load("res://resources/terrain_upper_relief.tres")]
	terrain = WorldTerrain.new(study_seed)
	actor_cell = Vector2(14.5, terrain.trail_y(14) + 0.5)
	add_child(geometry)
	add_child(camera)
	camera.current = true
	camera.fov = 55
	camera.far = 220
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("b9cfda")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("d5dfdf")
	environment.ambient_light_energy = 0.35
	environment.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	environment.fog_enabled = true
	environment.fog_mode = Environment.FOG_MODE_DEPTH
	environment.fog_light_color = environment.background_color
	environment.fog_depth_begin = 44
	environment.fog_depth_end = 78
	environment.fog_density = 1
	var world_environment := WorldEnvironment.new()
	world_environment.environment = environment
	add_child(world_environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-48, -30, 0)
	light.light_energy = 0.8
	light.shadow_enabled = true
	light.directional_shadow_max_distance = 75
	add_child(light)
	avatar = MODEL.instantiate()
	avatar.scale = Vector3.ONE * (1.7 / 2.171)
	avatar.rotation.y = PI
	add_child(avatar)
	var rig: Node = IDLE_RIG.instantiate()
	var source: AnimationPlayer = rig.get_node("AnimationPlayer")
	var animation: Animation = source.get_animation("Idle_A").duplicate(true)
	animation.loop_mode = Animation.LOOP_LINEAR
	var library := AnimationLibrary.new()
	library.add_animation("Idle_A", animation)
	var animator := AnimationPlayer.new()
	avatar.add_child(animator)
	animator.add_animation_library("", library)
	animator.play("Idle_A")
	animator.advance(0)
	animator.pause()
	rig.free()
	build_hud()
	select_preset(selected)

func build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var panel := PanelContainer.new()
	panel.position = Vector2(18, 18)
	layer.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 12)
	panel.add_child(margin)
	var column := VBoxContainer.new()
	margin.add_child(column)
	var title := Label.new()
	title.text = "SOLHUNTER  /  TERRAIN STUDY"
	title.add_theme_font_size_override("font_size", 22)
	column.add_child(title)
	column.add_child(info)
	var row := HBoxContainer.new()
	column.add_child(row)
	for index in range(3):
		var button := Button.new()
		button.text = "%d  %s" % [index + 1, presets[index].title if presets[index] != null else "Rolling fallback"]
		button.pressed.connect(select_preset.bind(index))
		row.add_child(button)
	var view_button := Button.new()
	view_button.text = "Overview / walking view  [Tab]"
	view_button.pressed.connect(toggle_overview)
	column.add_child(view_button)
	var controls := Label.new()
	controls.text = "WASD: move scale model  •  middle drag: orbit  •  wheel: zoom  •  Home: reset\nRaw shape study: routes follow slopes; ponds, slope collision and gameplay come later.\nModel: 1.7 cells  /  trees: 3.5 cells  /  no expedition or save changes"
	controls.add_theme_font_size_override("font_size", 14)
	column.add_child(controls)
	maps = HBoxContainer.new()
	maps.position = Vector2(18, 610)
	layer.add_child(maps)
	get_viewport().size_changed.connect(func() -> void: maps.position.y = maxf(300, get_viewport().get_visible_rect().size.y - 190))
	maps.position.y = maxf(300, get_viewport().get_visible_rect().size.y - 190)

func select_preset(index: int) -> void:
	selected = clampi(index, 0, presets.size() - 1)
	var tuning := presets[selected] if presets[selected] != null and presets[selected].valid() else TerrainReliefSettings.new()
	field = TerrainHeightfield.new(study_seed, tuning)
	for child in geometry.get_children():
		child.free()
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.roughness = 1.0
	for z in range(-4, 4):
		for x in range(-4, 8):
			var coord := Vector2i(x, z)
			var instance := MeshInstance3D.new()
			instance.mesh = StudyMesh.build(field, terrain, coord)
			instance.material_override = material
			instance.position = Vector3(x * 16, 0, z * 16)
			geometry.add_child(instance)
	add_scenery(TREE, 1, 3.5)
	add_scenery(ROCK, 2, 0.65)
	update_maps()
	info.text = "%s  •  seed %d  •  shared scenery and comparison view" % [tuning.title, study_seed]
	update_camera()

func add_scenery(scene: PackedScene, obstacle: int, height: float) -> void:
	var description: Dictionary = NatureArt.parts(scene)
	var bounds: AABB = description.bounds
	var factor := height / bounds.size.y
	var placements: Array[Transform3D] = []
	for z in range(-44, 45):
		for x in range(-44, 105):
			var cell := Vector2i(x, z)
			if terrain.sample(cell).obstacle != obstacle:
				continue
			var at := Vector2(cell) + Vector2(0.5, 0.5)
			var basis := Basis(Vector3.UP, float(terrain.roll(cell, 190) % 628) / 100.0).scaled(Vector3.ONE * factor)
			var transform := Transform3D(basis, Vector3(at.x, field.surface_height(at), at.y))
			transform.origin -= basis * Vector3(bounds.get_center().x, bounds.position.y, bounds.get_center().z)
			placements.append(transform)
	for piece: Dictionary in description.pieces:
		var multimesh := MultiMesh.new()
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimesh.mesh = piece.mesh
		multimesh.instance_count = placements.size()
		for index in range(placements.size()):
			multimesh.set_instance_transform(index, placements[index] * piece.transform)
		var instance := MultiMeshInstance3D.new()
		instance.multimesh = multimesh
		geometry.add_child(instance)

func map_image(slopes: bool) -> Image:
	var result := Image.create(192, 128, false, Image.FORMAT_RGB8)
	for z in range(128):
		for x in range(192):
			var at := Vector2(x - 64, z - 64)
			var amount := maxf(field.slope_degrees(at + Vector2(0.67, 0.33)), field.slope_degrees(at + Vector2(0.33, 0.67))) / 25.0 if slopes else (field.surface_height(at) + 6.0) / 12.0
			var color := Color("254857").lerp(Color("e5d6a1"), clampf(amount, 0, 1))
			if slopes:
				color = Color("385e48").lerp(Color("e0ae55"), clampf(amount, 0, 1))
				if amount > 1:
					color = Color("dc6255")
			result.set_pixel(x, z, color)
	return result

func update_maps() -> void:
	for child in maps.get_children():
		child.free()
	for slopes in [false, true]:
		var panel := PanelContainer.new()
		maps.add_child(panel)
		var box := VBoxContainer.new()
		panel.add_child(box)
		var label := Label.new()
		label.text = "Slope  /  0° green · 25° gold · >25° red" if slopes else "Height  /  -6 blue · +6 cream  /  cells"
		label.add_theme_font_size_override("font_size", 13)
		label.custom_minimum_size.x = 250
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(label)
		var image := TextureRect.new()
		image.texture = ImageTexture.create_from_image(map_image(slopes))
		image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		image.custom_minimum_size = Vector2(250, 140)
		box.add_child(image)

func toggle_overview() -> void:
	overview = not overview
	update_camera()

func reset_view() -> void:
	actor_cell = Vector2(14.5, terrain.trail_y(14) + 0.5)
	azimuth = -1.2
	elevation = 0.33
	distance = 22.0
	overview = false
	update_camera()

func update_camera() -> void:
	if field == null:
		return
	var center := Vector3(actor_cell.x, field.surface_height(actor_cell), actor_cell.y)
	avatar.position = center
	if overview:
		camera.position = Vector3(25, 112, 62)
		camera.look_at(Vector3(25, 0, 0))
	else:
		camera.position = center + Vector3(sin(azimuth) * cos(elevation), sin(elevation), cos(azimuth) * cos(elevation)) * distance
		camera.look_at(center + Vector3(0, 0.8, 0))
	environment.fog_enabled = not overview

func _process(delta: float) -> void:
	var change := Vector2(float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A)), float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W)))
	if change.length_squared() > 0:
		actor_cell += change.normalized().rotated(-azimuth) * minf(delta, 0.05) * 5.0
		actor_cell = actor_cell.clamp(Vector2(-36, -36), Vector2(96, 36))
		update_camera()

func _input(event: InputEvent) -> void:
	# Release can land over a GUI panel that consumes unhandled events.
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_MIDDLE and not event.pressed:
		dragging = false

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		dragging = false

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode >= KEY_1 and event.keycode <= KEY_3:
			select_preset(event.keycode - KEY_1)
		elif event.keycode == KEY_TAB:
			toggle_overview()
		elif event.keycode == KEY_HOME:
			reset_view()
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			dragging = event.pressed
		elif event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			distance = clampf(distance + (-2 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 2), 10, 40)
			update_camera()
	if event is InputEventMouseMotion and dragging:
		azimuth -= event.relative.x * 0.005
		elevation = clampf(elevation + event.relative.y * 0.005, 0.15, 1.1)
		update_camera()
