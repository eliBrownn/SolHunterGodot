extends RefCounted
## Shared approved single-blade geometry for the lab and streamed world.
static func create(width: float, curve: float, segments: int = 4) -> ArrayMesh:
	var builder := SurfaceTool.new()
	builder.begin(Mesh.PRIMITIVE_TRIANGLES)
	for segment in segments:
		var t0 := float(segment) / segments
		var t1 := float(segment + 1) / segments
		var w0 := width * 0.5 * (1.0 - t0)
		var w1 := width * 0.5 * (1.0 - t1)
		var vertices := [Vector3(-w0,t0,curve*t0*t0), Vector3(w0,t0,curve*t0*t0), Vector3(-w1,t1,curve*t1*t1), Vector3(w1,t1,curve*t1*t1)]
		# Final segment ends in a single tip; omit the degenerate second triangle.
		var corners := [0,2,1] if segment == segments - 1 else [0,2,1,1,2,3]
		for corner in corners:
			var t := t0 if corner < 2 else t1
			builder.set_normal(Vector3(0,-2.0*curve*t,1).normalized())
			builder.set_uv(Vector2(0.0 if corner in [0,2] else 1.0,t))
			builder.add_vertex(vertices[corner])
	var mesh := builder.commit()
	var arrays := mesh.surface_get_arrays(0)
	var points: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	arrays[Mesh.ARRAY_INDEX] = PackedInt32Array(range(points.size()))
	var base_left := -1
	var base_right := -1
	var middle_left := -1
	var middle_right := -1
	var tip := -1
	for index in range(points.size()):
		var point := points[index]
		if is_zero_approx(point.y):
			if point.x < 0.0: base_left = index
			else: base_right = index
		elif is_equal_approx(point.y, 0.5):
			if point.x < 0.0: middle_left = index
			else: middle_right = index
		elif is_equal_approx(point.y, 1.0): tip = index
	# Native screen-error LOD reduces vertex processing, unlike shader thinning
	# alone. Reuse the exact roots, midpoint and tip; close geometry stays intact.
	if mini(base_left, mini(base_right, mini(middle_left, mini(middle_right, tip)))) >= 0:
		var lods := {}
		lods[maxf(absf(curve) * 0.0625, 0.001)] = PackedInt32Array([base_left,middle_left,base_right,base_right,middle_left,middle_right,middle_left,tip,middle_right])
		lods[maxf(absf(curve) * 0.25, 0.004)] = PackedInt32Array([base_left,tip,base_right])
		mesh = ArrayMesh.new()
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays, [], lods)
	return mesh

