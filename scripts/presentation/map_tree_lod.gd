extends RefCounted
## One authored mesh and six texture-free, faceted silhouettes per tree species.

const DISTANCES := [32.0, 64.0, 112.0, 176.0, 256.0, 384.0]
const HYSTERESIS := 2.0
const RINGS := [8, 7, 6, 5, 4, 3]
const SIDES := [12, 10, 8, 7, 6, 5]
const PROFILE_BANDS := 12
const VECTOR_SHADER := preload("res://shaders/map_tree_vector.gdshader")

static var _vector_material: ShaderMaterial


static func tier(distance: float, previous: int = -1) -> int:
	var level := maxi(previous, 0)
	var margin := HYSTERESIS if previous >= 0 else 0.0
	while level < DISTANCES.size() and distance >= DISTANCES[level] + margin:
		level += 1
	while level > 0 and distance < DISTANCES[level - 1] - margin:
		level -= 1
	return level


static func build(pieces: Array, bounds: AABB) -> Array[Mesh]:
	var authored := ArrayMesh.new()
	var foliage := PackedVector3Array()
	var pigment := Vector3.ZERO
	var color_samples := 0
	# Low ornamental leaves shouldn't fill in the trunk in distant silhouettes.
	var crown_floor := bounds.position.y + bounds.size.y * 0.28
	for piece: Dictionary in pieces:
		var mesh: Mesh = piece.mesh
		for surface in mesh.get_surface_count():
			var material := mesh.surface_get_material(surface)
			var arrays := mesh.surface_get_arrays(surface)
			authored.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
			authored.surface_set_material(authored.get_surface_count() - 1, material)
			if not material is ShaderMaterial or material.get_shader_parameter("bark_surface") == true:
				continue
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var colors: PackedColorArray = arrays[Mesh.ARRAY_COLOR] if arrays[Mesh.ARRAY_COLOR] != null else PackedColorArray()
			var stride := maxi(1, ceili(float(vertices.size()) / 1800.0))
			for index in range(0, vertices.size(), stride):
				var vertex := vertices[index]
				if vertex.y < crown_floor:
					continue
				foliage.append(vertex)
				if index < colors.size():
					var color := colors[index]
					pigment += Vector3(color.r, color.g, color.b)
					color_samples += 1
	authored.custom_aabb = bounds
	var levels: Array[Mesh] = [authored]
	var crown := AABB(bounds.position + Vector3.UP * bounds.size.y * 0.32,
		bounds.size * Vector3(1, 0.68, 1))
	if not foliage.is_empty():
		crown = AABB(foliage[0], Vector3.ZERO)
		for vertex in foliage:
			crown = crown.expand(vertex)
	var profile := _crown_profile(foliage, crown)
	var color := Color("65843f")
	if color_samples > 0:
		pigment /= float(color_samples)
		color = Color(pigment.x, pigment.y, pigment.z)
	for index in RINGS.size():
		levels.append(_silhouette(bounds, crown, profile, color, RINGS[index], SIDES[index]))
	return levels


static func _crown_profile(vertices: PackedVector3Array, crown: AABB) -> Array:
	var bands: Array = []
	bands.resize(PROFILE_BANDS)
	for vertex in vertices:
		var fraction := (vertex.y - crown.position.y) / maxf(crown.size.y, 0.001)
		var index := clampi(int(fraction * PROFILE_BANDS), 0, PROFILE_BANDS - 1)
		var point := Vector2(vertex.x, vertex.z)
		bands[index] = Rect2(point, Vector2.ZERO) if bands[index] == null else bands[index].expand(point)
	var fallback := Rect2(Vector2(crown.position.x, crown.position.z), Vector2(crown.size.x, crown.size.z))
	for index in bands.size():
		if bands[index] == null:
			bands[index] = fallback if index == 0 else bands[index - 1]
	return bands


static func _silhouette(bounds: AABB, crown: AABB, profile: Array, color: Color, rings: int, sides: int) -> ArrayMesh:
	if _vector_material == null:
		_vector_material = ShaderMaterial.new()
		_vector_material.shader = VECTOR_SHADER
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	tool.set_material(_vector_material)
	tool.set_smooth_group(-1)

	var trunk_width := maxf(0.015, minf(bounds.size.x, bounds.size.z) * 0.055)
	var trunk := Rect2(-Vector2.ONE * trunk_width, Vector2.ONE * trunk_width * 2.0)
	var crown_center := Vector2(crown.get_center().x, crown.get_center().z)
	var trunk_top := Rect2(crown_center - Vector2.ONE * trunk_width * 0.45, Vector2.ONE * trunk_width * 0.9)
	_join(tool, _ring(trunk, bounds.position.y, 1.0, 5),
		_ring(trunk_top, crown.position.y + crown.size.y * 0.40, 1.0, 5),
		Color("65503b"), Color("806449"), false)

	var previous := PackedVector3Array()
	var previous_color := color
	for row in rings:
		var fraction := float(row) / float(rings - 1)
		var band: Rect2 = profile[mini(int(fraction * PROFILE_BANDS), PROFILE_BANDS - 1)]
		var radius := 0.025 if row == 0 or row == rings - 1 else 1.0
		var current := _ring(band, crown.position.y + crown.size.y * fraction, radius, sides)
		var tint := color * lerpf(0.78, 1.15, fraction)
		if row > 0:
			_join(tool, previous, current, previous_color, tint, true)
		previous = current
		previous_color = tint
	tool.generate_normals()
	var mesh := tool.commit()
	mesh.custom_aabb = bounds
	return mesh


static func _ring(bounds: Rect2, height: float, taper: float, sides: int) -> PackedVector3Array:
	var ring := PackedVector3Array()
	var radius := (bounds.size * 0.5).max(Vector2.ONE * 0.001) * taper
	for side in sides:
		var point := bounds.get_center() + Vector2.from_angle(TAU * float(side) / sides) * radius
		ring.append(Vector3(point.x, height, point.y))
	return ring


static func _join(tool: SurfaceTool, low: PackedVector3Array, high: PackedVector3Array,
		low_color: Color, high_color: Color, canopy: bool) -> void:
	var marker := 1.0 if canopy else 0.0
	for side in low.size():
		var next := (side + 1) % low.size()
		tool.set_color(Color(low_color.r, low_color.g, low_color.b, marker))
		tool.add_vertex(low[side])
		tool.add_vertex(low[next])
		tool.set_color(Color(high_color.r, high_color.g, high_color.b, marker))
		tool.add_vertex(high[next])
		tool.add_vertex(high[next])
		tool.add_vertex(high[side])
		tool.set_color(Color(low_color.r, low_color.g, low_color.b, marker))
		tool.add_vertex(low[side])
