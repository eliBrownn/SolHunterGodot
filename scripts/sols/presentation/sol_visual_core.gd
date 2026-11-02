extends Node3D
## Shared wispy visual core. Reuses the existing Vessel wake renderer, not its ecology.
const Swarm = preload("res://scripts/presentation/vessel_particle_swarm.gd")
const RANGES := {"wisp_density": [8.0, 96.0, 48.0], "wisp_length": [0.1, 1.0, 0.45], "wisp_speed": [0.1, 2.0, 0.85], "wisp_spread": [0.02, 0.3, 0.08], "wisp_softness": [0.0, 1.0, 0.7], "wisp_opacity": [0.1, 1.0, 0.75], "wisp_glow": [0.2, 3.0, 1.0]}
var diameter := 0.25
var parameters: Dictionary = {}
var core_tint := Color("d0eaf0")
var swarm: GPUParticles3D
var elapsed := 0.0

func configure(size: float, values: Dictionary = {}, color: Color = Color("d0eaf0")) -> void:
	diameter = clampf(size, 0.05, 2.0)
	core_tint = color
	if values.get("core_tint") is String and Color.html_is_valid(values.core_tint): core_tint = Color.html(values.core_tint)
	elif values.get("head_tint") is String and Color.html_is_valid(values.head_tint): core_tint = Color.html(values.head_tint)
	for key in RANGES:
		var value: Variant = values.get(key, RANGES[key][2])
		if not (value is int or value is float) or not is_finite(float(value)): value = RANGES[key][2]
		parameters[key] = clampf(float(value), RANGES[key][0], RANGES[key][1])
	if is_inside_tree(): rebuild()

func _ready() -> void:
	if parameters.is_empty(): configure(diameter)
	else: rebuild()

func rebuild() -> void:
	if swarm != null:
		remove_child(swarm)
		swarm.queue_free()
	swarm = Swarm.new()
	swarm.name = "WispParticles"
	swarm.member_count = roundi(parameters.wisp_density)
	swarm.trail_samples = 8
	swarm.trail_seconds = parameters.wisp_length
	swarm.flight_radius = parameters.wisp_spread
	swarm.motion_speed = parameters.wisp_speed
	swarm.spread = 0.0
	swarm.body_scale = 1.0
	swarm.scale = Vector3.ONE * diameter
	swarm.external_clock = true
	swarm.affinity_tint = core_tint # Existing renderer's tint slot; never inferred from affinity.
	swarm.refraction_pixels = 0
	swarm.aberration_pixels = 0
	add_child(swarm)
	swarm.process_material.set_shader_parameter("sphere_group", true)
	swarm.process_material.set_shader_parameter("sphere_radius", 0.36)
	swarm.material.set_shader_parameter("softness", parameters.wisp_softness)
	swarm.material.set_shader_parameter("opacity", parameters.wisp_opacity)
	swarm.material.set_shader_parameter("emission_strength", parameters.wisp_glow)
	swarm.material.set_shader_parameter("wispy_core", true)
	# Use the established luminous wake pass without the Vessel screen-refraction pass.
	var sprite: Mesh = swarm.draw_pass_2
	(sprite as QuadMesh).size = Vector2.ONE * 0.24
	swarm.draw_passes = 1
	swarm.draw_pass_1 = sprite
	swarm.visibility_aabb = AABB(Vector3.ONE * -1.5, Vector3.ONE * 3.0)
	swarm.set_visual_time(elapsed)

func set_visual_time(seconds: float) -> void:
	elapsed = seconds
	if swarm != null and swarm.process_material != null: swarm.set_visual_time(seconds)

func envelope_radius() -> float:
	return diameter * (0.43 + float(parameters.get("wisp_spread", 0.08)) * 1.5)
