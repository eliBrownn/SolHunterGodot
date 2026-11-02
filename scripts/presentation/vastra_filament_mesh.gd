extends RefCounted
static func create() -> ArrayMesh:
	# 24 segments allow actual curved silhouettes in each GPU particle.
	var vertices := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	for i in range(25):
		var u := float(i)/24.0
		for v in range(2):
			vertices.append(Vector3(u-0.5,float(v)-0.5,0))
			uvs.append(Vector2(u,v))
		if i<24:
			var at := i*2
			indices.append_array([at,at+1,at+2,at+1,at+3,at+2])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=vertices
	arrays[Mesh.ARRAY_TEX_UV]=uvs
	arrays[Mesh.ARRAY_INDEX]=indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	return mesh
