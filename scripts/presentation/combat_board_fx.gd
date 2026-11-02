extends RefCounted
## Bounded, purely visual embers emitted from sampled board markings.
const EMBER_SHADER = preload("res://shaders/combat_board_ember.gdshader")

static func ring_points(radius: float, count: int = 10) -> PackedVector3Array:
	var points := PackedVector3Array()
	for index in range(count):
		var angle := TAU * float(index) / count
		points.append(Vector3(cos(angle) * radius, 0, sin(angle) * radius))
	return points

static func apply(parent: Node3D, points: PackedVector3Array, tint: Color, tuning: SolVisualSettings) -> void:
	var sparks := parent.get_node_or_null("PatternEmbers") as MultiMeshInstance3D
	if sparks == null:
		sparks = MultiMeshInstance3D.new()
		sparks.name = "PatternEmbers"
		sparks.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		sparks.multimesh = MultiMesh.new()
		sparks.multimesh.transform_format = MultiMesh.TRANSFORM_3D
		sparks.multimesh.use_custom_data = true
		sparks.multimesh.mesh = QuadMesh.new()
		var material := ShaderMaterial.new()
		material.shader = EMBER_SHADER
		sparks.material_override = material
		parent.add_child(sparks)
	var instances := sparks.multimesh
	instances.instance_count = mini(points.size(), 128)
	for index in range(instances.instance_count):
		var source_index := int(float(index) * points.size() / instances.instance_count)
		instances.set_instance_transform(index, Transform3D(Basis.IDENTITY, points[source_index]))
		instances.set_instance_custom_data(index, Color(fposmod(index * 0.618034, 1.0), fposmod(index * 0.381966, 1.0), 0, 1))
	# Shader motion is world-sized, so flattening a ground ring never flattens its embers.
	var bounds := AABB(points[0], Vector3.ZERO) if not points.is_empty() else AABB()
	for point in points: bounds = bounds.expand(point)
	sparks.custom_aabb = bounds.grow(4.0)
	sparks.material_override.set_shader_parameter("mark_color", Color(tint, tuning.board_ember_opacity))
	sparks.material_override.set_shader_parameter("rise_height", tuning.board_ember_rise)
	sparks.material_override.set_shader_parameter("ember_size", tuning.board_ember_size)
	sparks.visible = tuning.board_ember_opacity > 0 and tuning.board_ember_rise > 0
