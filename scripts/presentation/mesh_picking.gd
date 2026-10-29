extends RefCounted
## CPU triangle/alpha picking for batched scenery, including gaps in imported foliage.

static var surfaces: Dictionary = {}
static var images: Dictionary = {}

## Shared mesh-space bins bound all triangles assigned to them, including long
## triangles crossing bin edges. This preserves exact triangle/alpha selection.
static func prepare(mesh: Mesh) -> void:
	var key := mesh.get_instance_id()
	if not surfaces.has(key):
		var rows: Array[Dictionary] = []
		for index in range(mesh.get_surface_count()):
			var arrays := mesh.surface_get_arrays(index)
			var row := {"vertices": arrays[Mesh.ARRAY_VERTEX], "indices": arrays[Mesh.ARRAY_INDEX], "uv": arrays[Mesh.ARRAY_TEX_UV], "material": mesh.surface_get_material(index)}
			var vertices: PackedVector3Array = row.vertices
			var indices: PackedInt32Array = row.indices if row.indices != null else PackedInt32Array()
			var bounds := mesh.get_aabb()
			var scale := Vector3(4.0 / maxf(bounds.size.x, 0.001), 4.0 / maxf(bounds.size.y, 0.001), 4.0 / maxf(bounds.size.z, 0.001))
			var bins := {}
			var count: int = indices.size() if not indices.is_empty() else vertices.size()
			for offset in range(0, count - 2, 3):
				var a: int = indices[offset] if not indices.is_empty() else offset
				var b: int = indices[offset + 1] if not indices.is_empty() else offset + 1
				var c: int = indices[offset + 2] if not indices.is_empty() else offset + 2
				var center := (vertices[a] + vertices[b] + vertices[c]) / 3.0
				var bin := Vector3i(((center - bounds.position) * scale).floor()).clamp(Vector3i.ZERO, Vector3i(3, 3, 3))
				var triangle := AABB(vertices[a], Vector3.ZERO).expand(vertices[b]).expand(vertices[c]).grow(0.00001)
				if not bins.has(bin):
					bins[bin] = {"bounds": triangle, "triangles": PackedInt32Array()}
				else:
					bins[bin].bounds = bins[bin].bounds.merge(triangle)
				bins[bin].triangles.append_array(PackedInt32Array([a, b, c]))
			row.bins = bins.values()
			prepare_image(row.material)
			rows.append(row)
		surfaces[key] = rows

static func prepare_image(material: Material) -> void:
	if not material is StandardMaterial3D or material.transparency == BaseMaterial3D.TRANSPARENCY_DISABLED or material.albedo_texture == null:
		return
	var texture: Texture2D = material.albedo_texture
	var key := texture.get_instance_id()
	if images.has(key):
		return
	var source_image := texture.get_image()
	if source_image != null and source_image.is_compressed():
		source_image.decompress()
	images[key] = source_image

static func ray(mesh: Mesh, origin: Vector3, direction: Vector3) -> Variant:
	prepare(mesh)
	var key := mesh.get_instance_id()
	var closest: Variant = null
	var distance := INF
	for row in surfaces[key]:
		var vertices: PackedVector3Array = row.vertices
		for bin in row.bins:
			if bin.bounds.intersects_ray(origin, direction) == null:
				continue
			var triangles: PackedInt32Array = bin.triangles
			for index in range(0, triangles.size(), 3):
				var a := triangles[index]
				var b := triangles[index + 1]
				var c := triangles[index + 2]
				var hit: Variant = Geometry3D.ray_intersects_triangle(origin, direction, vertices[a], vertices[b], vertices[c])
				if hit == null or origin.distance_squared_to(hit) >= distance:
					continue
				if not opaque(row, a, b, c, hit):
					continue
				closest = hit
				distance = origin.distance_squared_to(hit)
	return closest

static func opaque(row: Dictionary, a: int, b: int, c: int, hit: Vector3) -> bool:
	var material: Material = row.material
	if not material is StandardMaterial3D or material.transparency == BaseMaterial3D.TRANSPARENCY_DISABLED or material.albedo_texture == null or row.uv == null:
		return true
	var texture: Texture2D = material.albedo_texture
	var key := texture.get_instance_id()
	if not images.has(key):
		prepare_image(material)
	if images[key] == null:
		return true
	var vertices: PackedVector3Array = row.vertices
	var e0 := vertices[b] - vertices[a]
	var e1 := vertices[c] - vertices[a]
	var e2 := hit - vertices[a]
	var denominator := e0.dot(e0) * e1.dot(e1) - e0.dot(e1) * e0.dot(e1)
	if absf(denominator) < 0.0000001:
		return false
	var v := (e1.dot(e1) * e2.dot(e0) - e0.dot(e1) * e2.dot(e1)) / denominator
	var w := (e0.dot(e0) * e2.dot(e1) - e0.dot(e1) * e2.dot(e0)) / denominator
	var uv: Vector2 = row.uv[a] * (1.0 - v - w) + row.uv[b] * v + row.uv[c] * w
	var source_image: Image = images[key]
	var alpha := source_image.get_pixel(clampi(int(fposmod(uv.x, 1) * source_image.get_width()), 0, source_image.get_width() - 1), clampi(int(fposmod(uv.y, 1) * source_image.get_height()), 0, source_image.get_height() - 1)).a
	return alpha * material.albedo_color.a >= material.alpha_scissor_threshold
