extends RefCounted
## Original tree geometry through the midrange, then two view-facing vector meshes.

const DISTANCES := [512.0, 608.0, 704.0, 896.0, 1152.0, 1408.0, 1792.0]
const HYSTERESIS := 2.0
const AUTHORED_FRACTIONS := [1.0, 0.75, 0.48, 0.30, 0.18, 0.09]
const LEAF_CARDS_SHADER := preload("res://shaders/tree_leaf_cards.gdshader")
const BILLBOARD_SHADER := preload("res://shaders/map_tree_vector.gdshader")
const BRANCH_KINDS := [
	"Ground contact", "Root collar", "Storage tissue", "Trunk junction",
	"Crown conductor", "Crown socket", "Crown exchange", "Branch fork",
]

static var _billboard_material: ShaderMaterial


static func tier(distance: float, previous: int = -1) -> int:
	var level := maxi(previous, 0)
	var margin := HYSTERESIS if previous >= 0 else 0.0
	while level < DISTANCES.size() and distance >= DISTANCES[level] + margin:
		level += 1
	while level > 0 and distance < DISTANCES[level - 1] - margin:
		level -= 1
	return level


static func build(pieces: Array, bounds: AABB, organs: Array) -> Array[Mesh]:
	var levels: Array[Mesh] = []
	for level in AUTHORED_FRACTIONS.size():
		var mesh := ArrayMesh.new()
		mesh.custom_aabb = bounds
		levels.append(mesh)
	var foliage := PackedVector3Array()
	var pigment := Vector3.ZERO
	var color_samples := 0
	var crown_floor := bounds.position.y + bounds.size.y * 0.25
	for piece: Dictionary in pieces:
		var source: ArrayMesh = piece.mesh
		for surface in source.get_surface_count():
			var material := source.surface_get_material(surface)
			var arrays := source.surface_get_arrays(surface)
			var is_foliage: bool = material is ShaderMaterial and material.get_shader_parameter("bark_surface") != true
			var is_card: bool = is_foliage and material.shader == LEAF_CARDS_SHADER
			var can_thin_cards := is_card and _is_card_index_set(arrays[Mesh.ARRAY_INDEX])
			for level in AUTHORED_FRACTIONS.size():
				var reduced := arrays.duplicate()
				if level > 0:
					reduced[Mesh.ARRAY_INDEX] = _authored_indices(arrays, piece.lod_indices, level, can_thin_cards)
				var mesh: ArrayMesh = levels[level]
				mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, reduced)
				mesh.surface_set_material(mesh.get_surface_count() - 1, material)
			if not is_foliage:
				continue
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var colors: PackedColorArray = arrays[Mesh.ARRAY_COLOR] if arrays[Mesh.ARRAY_COLOR] != null else PackedColorArray()
			var stride := maxi(1, ceili(float(vertices.size()) / 1800.0))
			for index in range(0, vertices.size(), stride):
				if vertices[index].y < crown_floor:
					continue
				foliage.append(vertices[index])
				if index < colors.size():
					var color := colors[index]
					pigment += Vector3(color.r, color.g, color.b)
					color_samples += 1
	var color := Color("65843f")
	if color_samples > 0:
		pigment /= float(color_samples)
		color = Color(pigment.x, pigment.y, pigment.z)
	var groups: Array = []
	if not foliage.is_empty():
		groups.append(_crown_group(foliage))
	_split_crowns(groups, 8)
	var far := _billboard(bounds, groups, organs, color, 5, false)
	_split_crowns(groups, 20)
	var middle := _billboard(bounds, groups, organs, color, 8, true)
	levels.append(middle if middle != null else levels.back())
	levels.append(far if far != null else levels.back())
	return levels


static func _is_card_index_set(indices: Variant) -> bool:
	if indices == null or indices.is_empty() or indices.size() % 6 != 0:
		return false
	# Each authored leaf card consists of two adjacent triangles sharing an edge.
	for offset in range(0, indices.size(), 6):
		var shared := 0
		for second in range(offset + 3, offset + 6):
			for first in range(offset, offset + 3):
				if indices[first] == indices[second]:
					shared += 1
		if shared != 2:
			return false
	return true


static func _authored_indices(arrays: Array, lods: Array[PackedInt32Array], level: int,
		thin_cards: bool) -> Variant:
	var original: Variant = arrays[Mesh.ARRAY_INDEX]
	var count: int = original.size() if original != null and not original.is_empty() else arrays[Mesh.ARRAY_VERTEX].size()
	var target: float = count * AUTHORED_FRACTIONS[level]
	if thin_cards:
		# Reduce complete leaves evenly through the authored crown order.
		if level == 1:
			return original
		var cards := count / 6
		var remaining := maxi(1, roundi(cards * sqrt(AUTHORED_FRACTIONS[level])))
		var retained := PackedInt32Array()
		for index in remaining:
			var card := floori((float(index) + 0.5) * cards / remaining)
			retained.append_array(original.slice(card * 6, card * 6 + 6))
		return retained
	var best: Variant = original
	var error := count - target
	for indices in lods:
		if indices.is_empty() or indices.size() >= count or (level == 1 and indices.size() < count * 0.5):
			continue
		var candidate := absf(indices.size() - target)
		if candidate <= error:
			best = indices
			error = candidate
	return best


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


static func _billboard(bounds: AABB, groups: Array, organs: Array, color: Color,
		max_sides: int, include_forks: bool) -> ArrayMesh:
	if _billboard_material == null:
		_billboard_material = ShaderMaterial.new()
		_billboard_material.shader = BILLBOARD_SHADER
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	tool.set_material(_billboard_material)
	var joints := {}
	for organ: Dictionary in organs:
		if organ.kind in BRANCH_KINDS:
			joints[organ.id] = organ
	for axis in 2:
		for organ: Dictionary in joints.values():
			if not joints.has(organ.parent) or (organ.kind == "Branch fork" and not include_forks):
				continue
			var start := _project(joints[organ.parent].position, axis)
			var end := _project(organ.position, axis)
			if start.distance_squared_to(end) < 0.00001:
				continue
			var width := minf(bounds.size.x, bounds.size.z) * 0.039
			if organ.kind in ["Crown socket", "Crown exchange", "Branch fork"]:
				width *= 0.42 if organ.kind != "Branch fork" else 0.22
			var side := (end - start).normalized().orthogonal() * width
			_polygon(tool, PackedVector2Array([start - side, start + side, end + side * 0.72, end - side * 0.72]),
				Color(0.22, 0.17, 0.13, 0.0), axis)
		for group: Dictionary in groups:
			var points := PackedVector2Array()
			for point: Vector3 in group.points:
				points.append(_project(point, axis))
			var hull := Geometry2D.convex_hull(points)
			if hull.size() < 4:
				continue
			var vertices := hull.size() - 1 # The closing point repeats the first vertex.
			var corners := PackedVector2Array()
			var sides := mini(max_sides, vertices)
			for index in sides:
				corners.append(hull[index * vertices / sides])
			var fraction: float = (group.bounds.get_center().y - bounds.position.y) / maxf(bounds.size.y, 0.01)
			var tint := color * lerpf(0.46, 0.66, clampf(fraction, 0.0, 1.0))
			tint.a = 1.0
			_polygon(tool, corners, tint, axis)
	var mesh := tool.commit()
	if mesh != null:
		# A turning panel may reach past the source footprint's narrow side.
		var radius := maxf(absf(bounds.position.x), absf(bounds.end.x)) + maxf(absf(bounds.position.z), absf(bounds.end.z))
		mesh.custom_aabb = AABB(Vector3(-radius, bounds.position.y, -radius), Vector3(radius * 2.0, bounds.size.y, radius * 2.0))
	return mesh


static func _project(point: Vector3, axis: int) -> Vector2:
	return Vector2(point.x if axis == 0 else point.z, point.y)


static func _polygon(tool: SurfaceTool, points: PackedVector2Array, tint: Color, axis: int) -> void:
	tool.set_color(tint)
	tool.set_uv(Vector2(float(axis), 0.0))
	for index in range(1, points.size() - 1):
		for vertex in [points[0], points[index], points[index + 1]]:
			tool.add_vertex(Vector3(vertex.x, vertex.y, 0.0))
