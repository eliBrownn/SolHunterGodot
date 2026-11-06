extends RefCounted
## One authored mesh and six texture-free, faceted silhouettes per tree species.

const DISTANCES := [128.0, 176.0, 224.0, 288.0, 352.0, 448.0]
const HYSTERESIS := 2.0
const CROWN_GROUPS := [96, 64, 40, 24, 14, 8]
const CROWN_SIDES := [6, 6, 5, 5, 4, 4]
const BRANCH_LEVEL := {
	"Ground contact": 5, "Root exchange": 1, "Root collar": 5,
	"Storage tissue": 5, "Trunk junction": 5, "Crown conductor": 5,
	"Crown socket": 5, "Crown exchange": 5, "Branch fork": 2,
}
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


static func build(pieces: Array, bounds: AABB, organs: Array) -> Array[Mesh]:
	var authored := ArrayMesh.new()
	var foliage := PackedVector3Array()
	var pigment := Vector3.ZERO
	var color_samples := 0
	# Low ornamental leaves shouldn't fill in the trunk in distant silhouettes.
	var crown_floor := bounds.position.y + bounds.size.y * 0.25
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
	var color := Color("65843f")
	if color_samples > 0:
		pigment /= float(color_samples)
		color = Color(pigment.x, pigment.y, pigment.z)
	var groups: Array = []
	if not foliage.is_empty():
		groups.append(_crown_group(foliage))
	for index in range(CROWN_GROUPS.size() - 1, -1, -1):
		_split_crowns(groups, CROWN_GROUPS[index])
		levels.insert(1, _silhouette(bounds, groups, organs, color, index))
	return levels


static func _crown_group(points: PackedVector3Array) -> Dictionary:
	var bounds := AABB(points[0], Vector3.ZERO)
	for point in points:
		bounds = bounds.expand(point)
	return {"points": points, "bounds": bounds}


static func _split_crowns(groups: Array, target: int) -> void:
	while groups.size() < target:
		var choice := -1
		var spread := 0.0
		for index in groups.size():
			var group: Dictionary = groups[index]
			var extent: Vector3 = group.bounds.size
			var score := extent[extent.max_axis_index()] * sqrt(group.points.size())
			if group.points.size() >= 8 and score > spread:
				spread = score
				choice = index
		if choice < 0:
			break
		var group: Dictionary = groups[choice]
		var extent: Vector3 = group.bounds.size
		var axis := extent.max_axis_index()
		var sorted: Array[Vector3] = []
		sorted.assign(Array(group.points))
		sorted.sort_custom(func(a: Vector3, b: Vector3) -> bool: return a[axis] < b[axis])
		var split := sorted.size() / 2
		groups[choice] = _crown_group(PackedVector3Array(sorted.slice(0, split)))
		groups.append(_crown_group(PackedVector3Array(sorted.slice(split))))


static func _silhouette(bounds: AABB, groups: Array, organs: Array, color: Color, level: int) -> ArrayMesh:
	if _vector_material == null:
		_vector_material = ShaderMaterial.new()
		_vector_material.shader = VECTOR_SHADER
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	tool.set_material(_vector_material)
	tool.set_smooth_group(-1)
	_add_branches(tool, bounds, organs, level)

	for group: Dictionary in groups:
		var crown: AABB = group.bounds
		var center := crown.get_center()
		var width := Vector2(crown.size.x, crown.size.z).max(Vector2.ONE * bounds.size.y * 0.025)
		var footprint := Rect2(Vector2(center.x, center.z) - width * 0.5, width)
		var sides: int = CROWN_SIDES[level]
		var height := maxf(crown.size.y, bounds.size.y * 0.025)
		var waist := _ring(footprint, center.y, 0.92, sides)
		var bottom := _ring(footprint, center.y - height * 0.5, 0.12, sides)
		var top := _ring(footprint, center.y + height * 0.5, 0.12, sides)
		# The authored foliage's paint darkens its vertex pigment. Approximate that
		# value in the solid tiers so the tree doesn't brighten as it recedes.
		var tint := color * lerpf(0.40, 0.59, clampf((center.y - bounds.position.y) / bounds.size.y, 0.0, 1.0))
		_join(tool, bottom, waist, tint * 0.88, tint, true)
		_join(tool, waist, top, tint, tint * 1.08, true)
	tool.generate_normals()
	var mesh := tool.commit()
	mesh.custom_aabb = bounds
	return mesh


static func _add_branches(tool: SurfaceTool, bounds: AABB, organs: Array, level: int) -> void:
	var joints := {}
	var base_radius := minf(bounds.size.x, bounds.size.z) * 0.042
	for organ: Dictionary in organs:
		if BRANCH_LEVEL.has(organ.kind):
			joints[organ.id] = organ
	for organ: Dictionary in joints.values():
		var last_level: int = BRANCH_LEVEL[organ.kind]
		if level > last_level or not joints.has(organ.parent):
			continue
		var parent: Dictionary = joints[organ.parent]
		var from: Vector3 = parent.position
		var to: Vector3 = organ.position
		if from.distance_squared_to(to) < 0.00001:
			continue
		var base := base_radius
		match organ.kind:
			"Crown socket", "Crown exchange": base *= 0.48
			"Branch fork": base *= 0.25
			"Root exchange": base *= 0.64
			"Trunk junction", "Crown conductor":
				base *= lerpf(1.0, 0.44, clampf((to.y - bounds.position.y) / bounds.size.y, 0.0, 1.0))
		var axis := (to - from).normalized()
		var right := axis.cross(Vector3.FORWARD if absf(axis.z) < 0.9 else Vector3.RIGHT).normalized()
		var forward := right.cross(axis)
		var lower := PackedVector3Array()
		var upper := PackedVector3Array()
		var sides := 5 if level < 2 else 3
		for side in sides:
			var polar := Vector2.from_angle(TAU * float(side) / sides)
			var radial := right * polar.x + forward * polar.y
			lower.append(from + radial * base)
			upper.append(to + radial * base * 0.76)
		_join(tool, lower, upper, Color("382b21"), Color("4a3829"), false)


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
