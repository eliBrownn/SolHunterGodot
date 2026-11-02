extends SceneTree
## Verify uploaded LOD indices, winding and exact blade anchors, not just metadata.
var failures := 0
var checks := 0
func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)
func _initialize() -> void:
	for width in [0.018,0.028,0.045]:
		for curve in [0.0,0.06,0.22]:
			var mesh := preload("res://scripts/scenery/grass_blade_mesh.gd").create(width,curve)
			var surface := RenderingServer.mesh_get_surface(mesh.get_rid(),0)
			var vertices: PackedVector3Array = mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
			check(vertices.size()==21 and surface.index_count==21,"Close blades keep their seven authored triangles")
			check(surface.lods.size()==2,"GPU receives medium and far LODs")
			for level in range(surface.lods.size()):
				var data: PackedByteArray = surface.lods[level].index_data
				var indices: Array[int] = []
				for offset in range(0,data.size(),2): indices.append(data.decode_u16(offset))
				check(indices.size()==(9 if level==0 else 3),"LOD uses three or one triangles")
				var low := 1.0
				var high := 0.0
				for index in indices:
					check(index>=0 and index<vertices.size(),"LOD index addresses an existing vertex")
					low=minf(low,vertices[index].y)
					high=maxf(high,vertices[index].y)
				check(is_zero_approx(low) and is_equal_approx(high,1.0),"Every distance retains the exact root and tip heights")
				for offset in range(0,indices.size(),3):
					var a:=vertices[indices[offset]]
					var b:=vertices[indices[offset+1]]
					var c:=vertices[indices[offset+2]]
					check((b-a).cross(c-a).z<0.0,"LOD triangles retain nondegenerate clockwise winding")
	print("SCENERY DISTANCE LOD: %d checks, %d failures"%[checks,failures])
	quit(0 if failures==0 else 1)
