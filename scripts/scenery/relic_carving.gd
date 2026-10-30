extends RefCounted
## Cuts vertices into the owning stone mesh. No attached channel geometry.
const Relic = preload("res://scripts/scenery/procedural_relic.gd")
static var cache: Dictionary = {}

static func prepare(layout: Dictionary, style: int, etch_depth: float = 0.1) -> Dictionary:
	etch_depth = clampf(etch_depth, 0.04, 0.12) if is_finite(etch_depth) else 0.1
	var key := hash(var_to_str(layout) + "/" + str(style) + "/" + str(etch_depth))
	if cache.has(key): return cache[key].duplicate(true)
	var stones: Array[Dictionary] = []
	for part in layout.parts:
		var mesh := Relic.stone_mesh(part)
		stones.append({"part": part, "mesh": mesh, "vertices": mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX], "basis": Basis.from_euler(Vector3(0, part.yaw, part.roll))})
	var inlet: PackedVector3Array = layout.input_channel.duplicate()
	var outlet: PackedVector3Array = layout.output_channel.duplicate()
	inlet = project_route(stones, inlet)
	outlet = project_route(stones, outlet)
	var socket := nearest_surface(stones, layout.node_anchor + Vector3(0, 0, 0.1))
	var meshes := {}
	for stone in stones:
		var part: Dictionary = stone.part
		if str(part.id).begins_with("rubble_"):
			meshes[part.id] = stone.mesh
			continue
		var inverse: Basis = stone.basis.inverse()
		var local_routes: Array[PackedVector3Array] = []
		for route in [inlet, outlet]:
			var local := PackedVector3Array()
			for point in route: local.append(inverse * (point - part.at))
			local_routes.append(local)
		meshes[part.id] = carve(stone.mesh, local_routes, inverse * (socket - part.at), style, etch_depth)
	var result := {"meshes": meshes, "input_channel": inlet, "output_channel": outlet, "socket": socket}
	if cache.size() >= 12: cache.erase(cache.keys()[0])
	cache[key] = result
	return result.duplicate(true)

static func project_route(stones: Array[Dictionary], route: PackedVector3Array) -> PackedVector3Array:
	var result := route.duplicate()
	for i in range(1, result.size() - 1): result[i] = nearest_surface(stones, result[i])
	return result

static func nearest_surface(stones: Array[Dictionary], point: Vector3) -> Vector3:
	var best := point
	var distance := INF
	for stone in stones:
		if str(stone.part.id).begins_with("rubble_"): continue
		var local: Vector3 = stone.basis.inverse() * (point - stone.part.at)
		var vertices: PackedVector3Array = stone.vertices
		# Primitive columns may have indexed triangles; other stones are expanded.
		var index_data: Variant = stone.mesh.surface_get_arrays(0)[Mesh.ARRAY_INDEX]
		var indices: PackedInt32Array = index_data if index_data is PackedInt32Array else PackedInt32Array()
		var count := indices.size() if not indices.is_empty() else vertices.size()
		for i in range(0, count, 3):
			var a := vertices[indices[i] if not indices.is_empty() else i]
			var b := vertices[indices[i + 1] if not indices.is_empty() else i + 1]
			var c := vertices[indices[i + 2] if not indices.is_empty() else i + 2]
			var candidate := closest_triangle(local, a, b, c)
			var d := local.distance_squared_to(candidate)
			if d < distance:
				distance = d
				best = stone.basis * candidate + stone.part.at
	return best

static func closest_triangle(point: Vector3, a: Vector3, b: Vector3, c: Vector3) -> Vector3:
	var normal := (b - a).cross(c - a).normalized()
	var projected := point - normal * (point - a).dot(normal)
	if (b - a).cross(projected - a).dot(normal) >= -0.000001 and (c - b).cross(projected - b).dot(normal) >= -0.000001 and (a - c).cross(projected - c).dot(normal) >= -0.000001: return projected
	var best := Geometry3D.get_closest_point_to_segment(point, a, b)
	for pair in [[b, c], [c, a]]:
		var candidate := Geometry3D.get_closest_point_to_segment(point, pair[0], pair[1])
		if candidate.distance_squared_to(point) < best.distance_squared_to(point): best = candidate
	return best

static func carve(base: ArrayMesh, routes: Array[PackedVector3Array], socket: Vector3, style: int, etch_depth: float = 0.1) -> ArrayMesh:
	var arrays := base.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX] is PackedInt32Array else PackedInt32Array()
	var count := indices.size() if not indices.is_empty() else vertices.size()
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_smooth_group(-1)
	for i in range(0, count, 3):
		var a := vertices[indices[i] if not indices.is_empty() else i]
		var b := vertices[indices[i + 1] if not indices.is_empty() else i + 1]
		var c := vertices[indices[i + 2] if not indices.is_empty() else i + 2]
		var bounds := AABB(a, Vector3.ZERO).expand(b).expand(c).grow(0.13)
		var nearby := bounds.has_point(socket)
		var active_routes: Array[PackedVector3Array] = []
		for route in routes:
			for j in range(1, route.size()):
				if bounds.intersects_segment(route[j - 1], route[j]) != null:
					nearby = true
					active_routes.append(PackedVector3Array([route[j - 1], route[j]]))
		var divisions := clampi(ceili(maxf(a.distance_to(b), maxf(a.distance_to(c), b.distance_to(c))) / 0.065), 2, 36) if nearby else 1
		var normal := -(b - a).cross(c - a).normalized()
		# Do not excavate both sides of thin floor slabs.
		if normal.y < -0.6:
			emit_face(surface, [a, b, c], Color(1, 1, 1, 0))
			continue
		for row in range(divisions):
			for column in range(divisions - row):
				var p := a + (b - a) * float(row) / divisions + (c - a) * float(column) / divisions
				var q := a + (b - a) * float(row + 1) / divisions + (c - a) * float(column) / divisions
				var r := a + (b - a) * float(row) / divisions + (c - a) * float(column + 1) / divisions
				emit_cut_triangle(surface, [p, q, r], normal, active_routes, socket, style, etch_depth)
				if column + row + 1 < divisions:
					var s := a + (b - a) * float(row + 1) / divisions + (c - a) * float(column + 1) / divisions
					emit_cut_triangle(surface, [q, s, r], normal, active_routes, socket, style, etch_depth)
	surface.generate_normals()
	return surface.commit()

static func cut_field(point: Vector3, routes: Array[PackedVector3Array], socket: Vector3, style: int) -> float:
	var distance := INF
	for route in routes:
		for i in range(1, route.size()): distance = minf(distance, point.distance_to(Geometry3D.get_closest_point_to_segment(point, route[i - 1], route[i])))
	var delta := point - socket
	var socket_distance := maxf(absf(delta.x), maxf(absf(delta.y), absf(delta.z)))
	if style == 1: socket_distance = (absf(delta.x) + absf(delta.y) + absf(delta.z)) * 0.75
	elif style == 2: socket_distance = maxf(absf(delta.x) * 1.4, maxf(absf(delta.y), absf(delta.z)))
	return minf(distance - 0.095, socket_distance - 0.22)

static func emit_cut_triangle(surface: SurfaceTool, points: Array, normal: Vector3, routes: Array[PackedVector3Array], socket: Vector3, style: int, depth: float) -> void:
	var inside: Array[Dictionary] = []
	var outside: Array[Dictionary] = []
	var fields: Array[float] = []
	for point in points: fields.append(cut_field(point, routes, socket, style))
	for i in range(3):
		var next := (i + 1) % 3
		var entry := {"point": points[i], "edge": absf(fields[i]) < 0.000001}
		if fields[i] <= 0: inside.append(entry)
		else: outside.append(entry)
		if (fields[i] < 0 and fields[next] > 0) or (fields[i] > 0 and fields[next] < 0):
			var boundary: Vector3 = points[i].lerp(points[next], fields[i] / (fields[i] - fields[next]))
			inside.append({"point": boundary, "edge": true})
			outside.append({"point": boundary, "edge": true})
	for polygon in [outside, inside]:
		var recessed: bool = polygon == inside
		var offset := -normal * depth if recessed else Vector3.ZERO
		var color := Color(0.28, 0.28, 0.28, 1.0) if recessed else Color(1, 1, 1, 0)
		for i in range(1, polygon.size() - 1): emit_face(surface, [polygon[0].point + offset, polygon[i].point + offset, polygon[i + 1].point + offset], color)
	# Boundary walls are parallel to the face normal: an exact right-angle cut.
	for i in range(inside.size()):
		var next := (i + 1) % inside.size()
		if not inside[i].edge or not inside[next].edge: continue
		var a: Vector3 = inside[i].point
		var b: Vector3 = inside[next].point
		emit_face(surface, [a, b, b - normal * depth], Color(0.14, 0.14, 0.14, 0))
		emit_face(surface, [a, b - normal * depth, a - normal * depth], Color(0.14, 0.14, 0.14, 0))

static func emit_face(surface: SurfaceTool, points: Array, color: Color) -> void:
	if (points[1] - points[0]).cross(points[2] - points[0]).length_squared() < 0.000000000001: return
	surface.set_color(color)
	for point in points: surface.add_vertex(point)
