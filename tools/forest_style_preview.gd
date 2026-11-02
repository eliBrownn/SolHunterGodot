extends Node3D
## Standalone art fixture, not a new world generator or gameplay scene.

const TREE = preload("res://assets/nature/CommonTree_1.gltf")
const SHRUB = preload("res://assets/nature/Bush_Common.gltf")
const GRASS = preload("res://assets/nature/Grass_Common_Short.gltf")
const ROCK = preload("res://assets/nature/Rock_Medium_1.gltf")
const Art = preload("res://scripts/scenery/nature_art.gd")
const MoodPalette = preload("res://scripts/presentation/world_mood_palette.gd")

@export_group("Foliage study")
## Edit Shader Parameters on this material; restart the preview to apply.
@export var foliage_material: ShaderMaterial = preload("res://resources/painterly_foliage.tres")
## Fixed seed for visual scatter only. No expedition data is read or written.
@export var scatter_seed := 261029
## Initial preview condition: 0 noon, 1 sunset, 2 night.
@export_enum("Noon", "Sunset", "Night") var condition := 0
## Compare imported leaves/current-style lighting against the proposed treatment.
@export var baseline := false
@export_group("Situation and mood")
## Presentation only; disable to return smoothly to the neutral palette.
@export var mood_enabled := true
## Applied on startup; situations can request another palette through set_mood().
@export var initial_mood: StringName = &"welcoming"
## Test default: preferred 0.65 × 1.10 = 0.715 (10% stronger, not +10 points).
@export_range(0.0, 1.0, 0.005) var mood_strength := 0.715
## Seconds for a full smooth transition; zero applies immediately.
@export_range(0.0, 10.0, 0.1) var mood_transition_seconds := 2.5
@export var mood_palettes: Array[Resource] = [preload("res://resources/moods/neutral.tres"), preload("res://resources/moods/welcoming.tres"), preload("res://resources/moods/wondrous.tres"), preload("res://resources/moods/mysterious.tres")]

var environment := Environment.new()
var sun := DirectionalLight3D.new()
var camera := Camera3D.new()
var label := Label.new()
var surfaces: Array[Dictionary] = []
var source_surfaces: Array[Dictionary] = []
var nearest_filter := false
var azimuth := 0.3
var elevation := 0.29
var distance := 19.0
var frozen := false
var current_mood: StringName = &"neutral"
var mood_values: Dictionary = MoodPalette.new().values()
var mood_from: Dictionary = {}
var mood_target: Dictionary = {}
var mood_elapsed := 0.0
var mood_duration := 0.0
var base_lighting: Dictionary = {}

func _ready() -> void:
	get_viewport().msaa_3d = Viewport.MSAA_4X
	var atmosphere := WorldEnvironment.new()
	atmosphere.environment = environment
	add_child(atmosphere)
	var sky := Sky.new()
	sky.sky_material = ProceduralSkyMaterial.new()
	environment.sky = sky
	environment.background_mode = Environment.BG_SKY
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.ambient_light_sky_contribution = 0.65
	environment.ssao_enabled = true
	environment.ssao_radius = 0.65
	environment.ssao_intensity = 0.8
	environment.fog_enabled = true
	environment.fog_density = 0.008
	sun.shadow_enabled = true
	sun.shadow_blur = 1.5
	sun.shadow_opacity = 0.8
	sun.shadow_bias = 0.03
	sun.shadow_normal_bias = 0.6
	sun.directional_shadow_max_distance = 55
	sun.directional_shadow_blend_splits = true
	add_child(sun)
	add_child(camera)
	camera.current = true
	camera.fov = 48
	camera.far = 100
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(100, 100)
	ground.mesh = plane
	var ground_material := StandardMaterial3D.new()
	ground_material.albedo_color = Color("63744b")
	ground_material.roughness = 1
	ground.material_override = ground_material
	add_child(ground)
	# Fixed, asymmetric framing leaves an open center for reading light and shadows.
	for at in [Vector3(-5, 0, 0), Vector3(5, 0, -2), Vector3(-7, 0, -7), Vector3(0, 0, -8), Vector3(7, 0, -9), Vector3(-10, 0, -13), Vector3(4, 0, -15)]:
		place(TREE, at, 6.0, at.x, true)
	var rng := RandomNumberGenerator.new()
	rng.seed = scatter_seed
	for index in range(26):
		var at := Vector3(rng.randf_range(-10, 10), 0, rng.randf_range(-13, 3))
		if absf(at.x) < 2.8 and at.z > -5: continue
		place(SHRUB, at, rng.randf_range(0.6, 1.1), rng.randf_range(0, TAU), true)
	for index in range(100):
		var at := Vector3(rng.randf_range(-11, 11), 0, rng.randf_range(-14, 6))
		if absf(at.x) < 2 and at.z > -5: continue
		place(GRASS, at, rng.randf_range(0.22, 0.45), rng.randf_range(0, TAU), false)
	place(ROCK, Vector3(-3, 0, 1), 0.7, 0.4, false)
	place(ROCK, Vector3(3.5, 0, -4), 0.9, 1.8, false)
	var canvas := CanvasLayer.new()
	add_child(canvas)
	var panel := PanelContainer.new()
	panel.position = Vector2(16, 16)
	canvas.add_child(panel)
	label.add_theme_font_size_override("font_size", 18)
	panel.add_child(label)
	apply_style()
	set_mood(initial_mood, 0.0)
	update_camera()

func place(asset: PackedScene, at: Vector3, height: float, yaw: float, foliage: bool) -> void:
	var model := asset.instantiate() as Node3D
	var bounds: AABB = Art.parts(asset).bounds
	var scale_factor := height / maxf(bounds.size.y, 0.001)
	model.scale = Vector3.ONE * scale_factor
	model.rotation.y = yaw
	model.position = at - Vector3(0, bounds.position.y * scale_factor, 0)
	add_child(model)
	remember_materials(model)
	if foliage:
		adapt_leaves(model)

func remember_materials(node: Node) -> void:
	if node is MeshInstance3D:
		for surface in range(node.mesh.get_surface_count()):
			var source := node.get_active_material(surface) as StandardMaterial3D
			if source == null: continue
			var nearest := source.duplicate() as StandardMaterial3D
			nearest.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
			source_surfaces.append({"node": node, "surface": surface, "source": source, "nearest": nearest})
	for child in node.get_children(): remember_materials(child)

func adapt_leaves(node: Node) -> void:
	if node is MeshInstance3D:
		var mesh: Mesh = node.mesh
		for surface in range(mesh.get_surface_count()):
			var source := node.get_active_material(surface) as StandardMaterial3D
			if source == null or not source.resource_name.begins_with("Leaves_"):
				continue
			var styled := foliage_material.duplicate() as ShaderMaterial
			styled.set_shader_parameter("albedo_texture", source.albedo_texture)
			styled.set_shader_parameter("albedo_texture_nearest", source.albedo_texture)
			styled.set_shader_parameter("albedo_tint", source.albedo_color)
			styled.set_shader_parameter("vertex_color_albedo", source.vertex_color_use_as_albedo)
			styled.set_shader_parameter("uv_scale", Vector2(source.uv1_scale.x, source.uv1_scale.y))
			styled.set_shader_parameter("uv_offset", Vector2(source.uv1_offset.x, source.uv1_offset.y))
			styled.set_shader_parameter("alpha_cutoff", source.alpha_scissor_threshold)
			styled.set_shader_parameter("base_height", mesh.get_aabb().position.y)
			styled.set_shader_parameter("canopy_height", mesh.get_aabb().size.y)
			# Animated vertices must remain in the culling bounds.
			node.extra_cull_margin = 0.3
			surfaces.append({"node": node, "surface": surface, "source": source, "styled": styled})
	for child in node.get_children():
		adapt_leaves(child)

func apply_style() -> void:
	condition = clampi(condition, 0, 2)
	var sky := environment.sky.sky_material as ProceduralSkyMaterial
	var daylight := condition != 2
	sky.sky_top_color = [Color("668fb9"), Color("6c759e"), Color("07162e")][condition]
	sky.sky_horizon_color = [Color("c0d2d1"), Color("edb58c"), Color("263c59")][condition]
	sky.ground_horizon_color = sky.sky_horizon_color
	sky.ground_bottom_color = Color("253d32") if daylight else Color("060e1a")
	sun.rotation_degrees = [Vector3(-48, -35, 0), Vector3(-12, -65, 0), Vector3(-35, 145, 0)][condition]
	sun.light_color = [Color("fff1d9"), Color("ffc38c"), Color("a7c9f0")][condition]
	sun.light_energy = [1.25, 1.1, 0.32][condition]
	environment.ambient_light_color = Color("c6dbed") if daylight else Color("7894b6")
	environment.ambient_light_energy = (0.6 if daylight else 0.28) if baseline else (0.55 if daylight else 0.22)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR if baseline else Environment.AMBIENT_SOURCE_SKY
	environment.tonemap_mode = Environment.TONE_MAPPER_LINEAR if baseline else Environment.TONE_MAPPER_FILMIC
	environment.tonemap_exposure = 1.05 if baseline else 1.2
	environment.fog_light_color = sky.sky_horizon_color
	base_lighting = {"sun_color": sun.light_color, "sun_energy": sun.light_energy,
		"ambient_color": environment.ambient_light_color, "ambient_energy": environment.ambient_light_energy,
		"fog_color": environment.fog_light_color, "exposure": environment.tonemap_exposure}
	for record in source_surfaces:
		record.node.set_surface_override_material(record.surface, record.nearest if nearest_filter else record.source)
	for record in surfaces:
		record.styled.set_shader_parameter("nearest_filter", nearest_filter)
		if not baseline:
			record.node.set_surface_override_material(record.surface, record.styled)
	apply_mood()
	label.text = "  Forest study · %s · %s · %s  \n  B compare | 1 noon · 2 sunset · 3 night | F freeze wind  \n  Z neutral · X welcoming · C wondrous · V mysterious  \n  Drag to orbit · Wheel to zoom · R reset  " % ["Imported / linear" if baseline else "Painterly / filmic", ["Noon", "Sunset", "Night"][condition], current_mood]

## Request a palette from an existing situation owner. A new request starts
## from the currently displayed blend, so interrupted transitions do not jump.
func set_mood(key: StringName, seconds: float = -1.0) -> bool:
	var selected: Resource
	for palette in mood_palettes:
		if palette is MoodPalette and palette.valid() and palette.key == key:
			selected = palette
			break
	if selected == null or not is_finite(seconds): return false
	current_mood = key
	mood_from = mood_values.duplicate()
	mood_target = selected.values()
	mood_elapsed = 0.0
	mood_duration = maxf(0.0, mood_transition_seconds if seconds < 0 else seconds)
	if not is_finite(mood_duration): mood_duration = 0.0
	if mood_duration == 0.0: mood_values = mood_target.duplicate()
	apply_style()
	return true

func _process(delta: float) -> void:
	if mood_duration <= 0.0 or mood_elapsed >= mood_duration: return
	mood_elapsed = minf(mood_duration, mood_elapsed + delta)
	var weight := smoothstep(0.0, 1.0, mood_elapsed / mood_duration)
	mood_values = MoodPalette.blend(mood_from, mood_target, weight)
	apply_mood()

func apply_mood() -> void:
	if base_lighting.is_empty(): return
	var amount := clampf(mood_strength, 0.0, 1.0) if mood_enabled and not baseline and is_finite(mood_strength) else 0.0
	var values := MoodPalette.blend(MoodPalette.new().values(), mood_values, amount)
	sun.light_color = base_lighting.sun_color * values.sun_tint
	# A mood may deepen night, but cannot brighten it beyond its base lighting.
	var night := condition == 2
	sun.light_energy = base_lighting.sun_energy * (minf(values.light_scale, 1.0) if night else values.light_scale)
	environment.ambient_light_color = base_lighting.ambient_color * values.ambient_tint
	environment.ambient_light_energy = base_lighting.ambient_energy * (minf(values.fill_scale, 1.0) if night else values.fill_scale)
	environment.fog_light_color = base_lighting.fog_color * values.fog_tint
	environment.fog_density = values.fog_density
	environment.tonemap_exposure = base_lighting.exposure * (minf(values.exposure_scale, 1.0) if night else values.exposure_scale)
	for record in surfaces:
		record.styled.set_shader_parameter("mood_shadow", values.leaf_shadow)
		record.styled.set_shader_parameter("mood_light", values.leaf_light)
		record.styled.set_shader_parameter("mood_tint", values.leaf_tint)
		record.styled.set_shader_parameter("mood_saturation", values.saturation)

func update_camera() -> void:
	var focus := Vector3(0, 2.0, -4)
	camera.position = focus + Vector3(sin(azimuth) * cos(elevation), sin(elevation), cos(azimuth) * cos(elevation)) * distance
	camera.look_at(focus)

func freeze_wind(value: bool) -> void:
	frozen = value
	for record in surfaces:
		record.styled.set_shader_parameter("preview_time", 2.0 if value else -1.0)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_B: baseline = not baseline
			KEY_1: condition = 0
			KEY_2: condition = 1
			KEY_3: condition = 2
			KEY_F: freeze_wind(not frozen)
			KEY_Z: set_mood(&"neutral")
			KEY_X: set_mood(&"welcoming")
			KEY_C: set_mood(&"wondrous")
			KEY_V: set_mood(&"mysterious")
			KEY_R:
				azimuth = 0.3
				elevation = 0.29
				distance = 19.0
		apply_style()
		update_camera()
	if event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
		azimuth -= event.relative.x * 0.005
		elevation = clampf(elevation + event.relative.y * 0.005, 0.08, 1.15)
		update_camera()
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP: distance = maxf(8, distance - 1)
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN: distance = minf(35, distance + 1)
		update_camera()
