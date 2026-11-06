extends RefCounted
## Preview-only mesh adapter. All vertices/normals come from the shared heightfield.

static func build(field: TerrainHeightfield, terrain: WorldTerrain, coord: Vector2i) -> ArrayMesh:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()
	for z in range(17):
		for x in range(17):
			var cell := coord * 16 + Vector2i(x, z)
			vertices.append(Vector3(x, field.vertex_height(cell), z))
			normals.append(field.vertex_normal(cell))
			var tint := Color("71865b").lerp(Color("929367"), clampf(terrain.wetness_at(cell), 0, 1))
			if absi(cell.y - terrain.trail_y(cell.x)) <= 1 or terrain.route_axes(cell, -2) != 0:
				tint = Color("b1a387")
			colors.append(tint)
	for z in range(16):
		for x in range(16):
			var first := z * 17 + x
			indices.append_array(PackedInt32Array([first, first + 1, first + 18, first, first + 18, first + 17]))
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh
