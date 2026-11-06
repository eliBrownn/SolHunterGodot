extends RefCounted
## Shared mesh levels from the same vertex attributes and materials as the source.

const TreeLod := preload("res://scripts/presentation/map_tree_lod.gd")


static func build(pieces: Array, bounds: AABB) -> Array[Mesh]:
	var surfaces: Array[Dictionary] = []
	for piece: Dictionary in pieces:
		var mesh: ArrayMesh = piece.mesh
		for surface in mesh.get_surface_count():
			var arrays := mesh.surface_get_arrays(surface)
			var material := material_for_map(mesh.surface_get_material(surface))
			var importer := ImporterMesh.new()
			importer.add_surface(Mesh.PRIMITIVE_TRIANGLES, arrays, [], {}, material)
			importer.generate_lods(60.0, 25.0, [])
			var simplified := importer.get_surface_arrays(0)
			var indices: Array[PackedInt32Array] = []
			for level in importer.get_surface_lod_count(0):
				var lod := importer.get_surface_lod_indices(0, level)
				if not lod.is_empty():
					indices.append(lod)
			indices.sort_custom(func(a: PackedInt32Array, b: PackedInt32Array) -> bool: return a.size() > b.size())
			surfaces.append({"source": arrays, "simplified": simplified, "indices": indices, "material": material})
	var levels: Array[Mesh] = []
	for level in TreeLod.DISTANCES.size() + 1:
		var mesh := ArrayMesh.new()
		for surface in surfaces:
			var arrays: Array = surface.source
			var indices: Array[PackedInt32Array] = surface.indices
			if level > 0 and not indices.is_empty():
				arrays = surface.simplified.duplicate()
				var index := ceili(float(level * indices.size()) / TreeLod.DISTANCES.size()) - 1
				arrays[Mesh.ARRAY_INDEX] = indices[index]
			mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
			mesh.surface_set_material(mesh.get_surface_count() - 1, surface.material)
		mesh.custom_aabb = bounds
		levels.append(mesh)
	return levels


static func fade_band() -> Vector2:
	var start: float = TreeLod.DISTANCES.back()
	return Vector2(start, start + 128.0)


static func material_for_map(source: Material) -> Material:
	if not source is ShaderMaterial:
		return source
	var material := source.duplicate() as ShaderMaterial
	material.set_shader_parameter("map_ground_asset_range", fade_band())
	return material
