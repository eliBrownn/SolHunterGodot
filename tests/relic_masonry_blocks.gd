extends SceneTree
const Blocks = preload("res://scripts/scenery/relic_masonry_blocks.gd")
func _initialize() -> void:
	for key in Blocks.KEYS:
		for seed_value in [0,73,99999]:
			var data := Blocks.definition(key,seed_value)
			assert(data == Blocks.definition(key,seed_value))
			assert(Geometry2D.triangulate_polygon(data.profile).size() == (data.profile.size()-2)*3)
			var mesh := Blocks.mesh(data)
			assert(mesh.get_surface_count() == 1)
			assert(mesh.get_aabb().position.y == 0)
			var arrays := mesh.surface_get_arrays(0)
			for vertex in arrays[Mesh.ARRAY_VERTEX]: assert(vertex.is_finite())
			for normal in arrays[Mesh.ARRAY_NORMAL]: assert(normal.is_finite() and normal.length() > 0.9)
			var large := Blocks.mesh(Blocks.definition(key,seed_value,2.0))
			assert(large.get_aabb().size.is_equal_approx(mesh.get_aabb().size*2))
	assert(Blocks.definition("missing").is_empty())
	assert(Blocks.definition("wedge",73,NAN).is_empty())
	print("Relic masonry: 12 profiles, reconstruction, triangulation, normals, anchors and scale passed")
	quit()
