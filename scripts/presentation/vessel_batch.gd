extends MultiMeshInstance3D
## Presentation-only bodies. No individual nodes, lights, physics or energy state.

@export_range(1, 4096, 1) var member_count := 128
## Art scale in metres; provisional 2 cm segmented body and 11 cm wing spread.
@export_range(0.25, 3.0, 0.05) var body_scale := 1.0
@export_range(0.0, 5.0, 0.1) var spread := 0.8
## Local procedural flight radius in metres before body scale; restart to apply.
@export_range(0.02, 0.3, 0.01) var flight_radius := 0.1
## Curve segments per second before individual variation; restart to apply.
@export_range(0.1, 2.0, 0.05) var motion_speed := 0.85
@export var affinity_tint := Color("e8d895")
## Presentation input only; no ecological anger or danger rule is created here.
@export_range(0.0, 1.0, 0.05) var anger := 0.0:
	set(value):
		anger = clampf(value, 0.0, 1.0)
		if material != null: material.set_shader_parameter("anger", anger)
## Screen-space bending at calm, in pixels. Restart/recreate after editing.
@export_range(0.0, 3.0, 0.05) var refraction_pixels := 0.55
## Additional RGB separation at full anger, in pixels.
@export_range(0.0, 4.0, 0.1) var aberration_pixels := 2.0

var elapsed := 0.0
var frozen := false
var material := ShaderMaterial.new()

func _ready() -> void:
	material.shader = preload("res://shaders/vessel_body.gdshader")
	material.set_shader_parameter("affinity_tint", affinity_tint)
	material.set_shader_parameter("flight_radius", flight_radius)
	material.set_shader_parameter("motion_speed", motion_speed)
	material.set_shader_parameter("anger", anger)
	material.set_shader_parameter("refraction_pixels", refraction_pixels)
	material.set_shader_parameter("aberration_pixels", aberration_pixels)
	material_override = material
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var batch := MultiMesh.new()
	batch.transform_format = MultiMesh.TRANSFORM_3D
	batch.use_custom_data = true
	batch.use_colors = true
	batch.mesh = make_body()
	batch.instance_count = member_count
	var rng := RandomNumberGenerator.new()
	rng.seed = 291030
	for i in range(member_count):
		var at := Vector3.ZERO
		var yaw := -0.5
		if member_count > 1:
			at = Vector3(rng.randf_range(-spread, spread), rng.randf_range(-0.15, 0.5), rng.randf_range(-spread, spread))
			yaw = rng.randf_range(-PI, PI)
		var basis := Basis(Vector3.UP, yaw).scaled(Vector3.ONE * body_scale)
		batch.set_instance_transform(i, Transform3D(basis, at))
		batch.set_instance_color(i, Color.WHITE)
		batch.set_instance_custom_data(i, Color(rng.randf(), 0, 0, 1))
	multimesh = batch
	# Includes shader travel and fin displacement; no per-frame CPU bounds rebuild.
	var padding := (flight_radius * 1.8 + 0.12) * maxf(body_scale, 1.0)
	custom_aabb = AABB(Vector3(-spread - padding, -padding - 0.15, -spread - padding), Vector3(spread * 2 + padding * 2, 0.65 + padding * 2, spread * 2 + padding * 2))

func _process(delta: float) -> void:
	if not frozen:
		elapsed += delta
		material.set_shader_parameter("animation_time", elapsed)

static func triangle(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, color: Color) -> void:
	st.set_color(color)
	for point in [a, b, c]:
		st.set_uv(Vector2(-1, 0))
		st.add_vertex(point)

static func body_segment(st: SurfaceTool, center: Vector3, size: Vector3, color: Color) -> void:
	var ring: Array[Vector3] = [Vector3(-1, 0, 0), Vector3(0, 0, -1), Vector3(1, 0, 0), Vector3(0, 0, 1)]
	for i in range(4):
		triangle(st, center + ring[i] * size, center + Vector3(0, size.y, 0), center + ring[(i + 1) % 4] * size, color)
		triangle(st, center + ring[(i + 1) % 4] * size, center - Vector3(0, size.y, 0), center + ring[i] * size, color)

static func make_body() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Compact head, thorax and abdomen; no elongated tail or dominant oval head.
	var heart := Color(0.49, 0.7, 0.61, 1)
	body_segment(st, Vector3(0, 0.006, -0.007), Vector3(0.003, 0.003, 0.003), heart)
	body_segment(st, Vector3(0, 0.006, 0), Vector3(0.004, 0.004, 0.004), Color(0.72, 0.88, 0.74, 1))
	body_segment(st, Vector3(0, 0.006, 0.007), Vector3(0.003, 0.003, 0.004), heart)
	for side in [-1.0, 1.0]:
		# Three pairs of tiny folded legs, visible only on close inspection.
		for leg in range(3):
			var at := Vector3(side * 0.002, 0.004, (leg - 1) * 0.003)
			var knee := at + Vector3(side * 0.006, -0.004, 0.002)
			var foot := knee + Vector3(-side * 0.002, -0.003, 0.002)
			triangle(st, at, knee, knee + Vector3(0, 0, 0.0007), heart)
			triangle(st, knee, foot, knee + Vector3(0, 0, 0.0007), heart)
	# Four simple envelopes carry sparse shader wisps, not solid membranes.
	# No antennae, particle nodes or long central tail.
	for side in [-1.0, 1.0]:
		for fore in [-1.0, 1.0]:
			var tip := Vector3(side * (0.054 if fore < 0 else 0.041), 0.023, fore * 0.027)
			var across := Vector3(-tip.z, 0, tip.x).normalized()
			for segment in range(8):
				for half in [-1.0, 1.0]:
					for corner in [Vector2(0, 0), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0), Vector2(0, 1), Vector2(1, 1)]:
						var along: float = (segment + corner.x) / 8.0
						var edge: float = corner.y * half
						var width := pow(sin(along * PI), 0.8) * (0.011 if fore < 0 else 0.015)
						var center := tip * along + Vector3(0, 0.006 + sin(along * PI) * 0.009, fore * 0.004 * (1.0 - along))
						st.set_color(Color(0.67, 0.88, 0.8, 1))
						st.set_uv(Vector2(along, edge))
						st.add_vertex(center + across * width * edge)
	st.generate_normals()
	return st.commit()
