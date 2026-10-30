extends GPUParticles3D
## Orb/wake presentation pool. No individual nodes, lights, physics or energy state.

@export_range(1, 4096, 1) var member_count := 128
## Multiplies orb size and local flight radius; restart/recreate to apply.
@export_range(0.25, 3.0, 0.05) var body_scale := 1.0
@export_range(0.0, 5.0, 0.1) var spread := 0.8
## Metres of local flight; restart/recreate to apply.
@export_range(0.02, 0.3, 0.01) var flight_radius := 0.1
@export_range(0.1, 2.0, 0.05) var motion_speed := 0.85
## Live world supplies saved active time; the standalone preview owns its clock.
@export var external_clock := false
@export var affinity_tint := Color("e8d895")
## Fading samples per head; restart/recreate to apply.
@export_range(4, 16, 1) var trail_samples := 10
## Seconds of the path represented by the wake; not a biological lifetime.
@export_range(0.1, 1.0, 0.05) var trail_seconds := 0.65
@export_range(0.0, 1.0, 0.05) var anger := 0.0:
	set(value):
		anger = clampf(value, 0.0, 1.0)
		if material != null: material.set_shader_parameter("anger", anger)
		if lens_material != null: lens_material.set_shader_parameter("anger", anger)
@export_range(0.0, 32.0, 0.5) var refraction_pixels := 14.0
## Maximum per-channel screen offset in pixels; updates immediately.
@export_range(0.0, 24.0, 0.5) var aberration_pixels := 12.0:
	set(value):
		aberration_pixels = clampf(value, 0.0, 24.0)
		if material != null: material.set_shader_parameter("aberration_pixels", aberration_pixels)
		if lens_material != null: lens_material.set_shader_parameter("aberration_pixels", aberration_pixels)

var elapsed := 0.0
var frozen := false
var material := ShaderMaterial.new()
var lens_material := ShaderMaterial.new()

func _ready() -> void:
	member_count = clampi(member_count, 1, 4096)
	trail_samples = clampi(trail_samples, 4, 16)
	amount = member_count * (trail_samples + 1)
	lifetime = 3600.0 # Rendering pool reuse, not a Vessel lifecycle rule.
	explosiveness = 1.0
	local_coords = true
	fixed_fps = 60
	use_fixed_seed = true
	seed = 291030
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var movement := ShaderMaterial.new()
	movement.shader = preload("res://shaders/vessel_particles.gdshader")
	for key in ["member_count", "trail_samples", "trail_seconds", "flight_radius", "motion_speed", "spread", "body_scale"]:
		movement.set_shader_parameter(key, get(key))
	process_material = movement
	material.shader = preload("res://shaders/vessel_particle_draw.gdshader")
	material.render_priority = 10
	for key in ["affinity_tint", "anger", "refraction_pixels", "aberration_pixels", "body_scale"]:
		material.set_shader_parameter(key, get(key))
	lens_material.shader = preload("res://shaders/vessel_particle_lens.gdshader")
	lens_material.render_priority = -10
	for key in ["anger", "refraction_pixels", "aberration_pixels", "body_scale"]:
		lens_material.set_shader_parameter(key, get(key))
	var lens := QuadMesh.new()
	lens.size = Vector2(0.12, 0.12)
	lens.material = lens_material
	var sprite := QuadMesh.new()
	sprite.size = Vector2(0.06, 0.06)
	sprite.material = material
	draw_passes = 2
	draw_pass_1 = lens
	draw_pass_2 = sprite
	var padding := (flight_radius * 1.8 + 0.1) * maxf(body_scale, 1.0)
	visibility_aabb = AABB(Vector3(-spread - padding, -padding - 0.15, -spread - padding), Vector3(spread * 2 + padding * 2, 0.65 + padding * 2, spread * 2 + padding * 2))
	preprocess = 0.1
	emitting = true

func _process(delta: float) -> void:
	if not frozen and not external_clock:
		set_visual_time(elapsed + delta)

func set_visual_time(seconds: float) -> void:
	elapsed = seconds
	process_material.set_shader_parameter("animation_time", seconds)
