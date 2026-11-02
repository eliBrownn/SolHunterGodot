extends RefCounted
## Detached, bounded coarse mesh assembly; canonical terrain stays on its owner thread.
var terrain: WorldTerrain
var coord: Vector2i
var step: int
var nature: NatureSettings
var width: int
var tile_cursor := 0
var edge_cursor := 0
var mesh: ArrayMesh
var vertex_cache := {}
var operations := 0
var uploads := 0
var skirt_depth: float
var vertices := PackedVector3Array()
var normals := PackedVector3Array()
var colors := PackedColorArray()
var uvs := PackedVector2Array()
var blends := PackedFloat32Array()
var indices := PackedInt32Array()
var edges: Array = []

func _init(source: WorldTerrain, at: Vector2i, spacing: int = 4, tuning: NatureSettings = null) -> void:
	terrain = source
	coord = at
	step = spacing
	nature = tuning
	width = 16 / step
	skirt_depth = (float(terrain.relief.broad_amplitude) + float(terrain.relief.detail_amplitude) + float(terrain.relief.micro_amplitude)) * 2 + float(terrain.relief.mountain_height) + 2

func vertex_data(at: Vector2i) -> Dictionary:
	if not vertex_cache.has(at):
		vertex_cache[at] = {"soil": NatureSettings.terrain_soil_at(terrain, at), "blend": NatureSettings.terrain_blend_at(terrain, at), "tint": (terrain.habitat_tint(at) * nature.ground_tint_at(terrain, at)).srgb_to_linear() if nature != null and not nature.biomes.is_empty() else Color.WHITE}
	return vertex_cache[at]

func advance(deadline: int, operation_limit: int = 32) -> bool:
	operations = 0
	uploads = 0
	if mesh != null: return true
	while operations < operation_limit and (deadline <= 0 or Time.get_ticks_usec() < deadline):
		operations += 1
		if tile_cursor < width * width:
			build_tile()
			tile_cursor += 1
		elif edge_cursor < edges.size():
			build_skirt()
			edge_cursor += 1
		else:
			upload()
			uploads = 1
			return true
	return false

func build_tile() -> void:
	var x := (tile_cursor % width) * step
	var y := (tile_cursor / width) * step
	var cell := coord * 16 + Vector2i(x, y)
	var sample := cell + Vector2i(step / 2, step / 2)
	var kind: int = terrain.natural_ground(sample)
	var water: bool = kind == WorldTerrain.Ground.WATER
	var level: float = terrain.pond_at(sample).level if water else 0.0
	var trail: bool = false
	if not water:
		trail = terrain.trail_visible_at(sample) if terrain.get_script() == WorldTerrain else terrain.sample(sample).trail_visible
	var cliff := not water and not terrain.slope_fits(sample)
	var color: Color = (Color("b2b29d") if trail else terrain.habitat_tint(sample)).srgb_to_linear()
	var surface_kind := 1.0 if water else (2.0 if trail else 0.0)
	var start := vertices.size()
	var corners := PackedVector3Array()
	for offset in [Vector2i.ZERO, Vector2i(step, 0), Vector2i(step, step), Vector2i(0, step)]:
		var height: float = level if water else terrain.vertex_height(cell + offset)
		corners.append(Vector3(x + offset.x, height, y + offset.y))
	var normal := Vector3(corners[0].y - corners[1].y, step, corners[0].y - corners[3].y).normalized()
	vertices.append_array(corners)
	for corner in range(4):
		normals.append(normal)
		var vertex_color := color
		if not water and nature != null and not nature.biomes.is_empty():
			var at := cell + Vector2i(roundi(corners[corner].x) - x, roundi(corners[corner].z) - y)
			vertex_color = vertex_data(at).tint
		vertex_color.a = vertex_data(cell + Vector2i(roundi(corners[corner].x) - x, roundi(corners[corner].z) - y)).soil
		colors.append(vertex_color)
		blends.append_array(vertex_data(cell + Vector2i(roundi(corners[corner].x)-x,roundi(corners[corner].z)-y)).blend)
		uvs.append(Vector2(surface_kind, 1.0 if cliff else 0.0))
	indices.append_array(PackedInt32Array([start, start + 1, start + 2, start, start + 2, start + 3]))
	# Boundary skirts conceal coarse/full-resolution seams; water skirts also
	# close temporary shore transitions within a chunk. They never collide.
	for edge in range(4):
		if water or [y == 0, x + step == 16, y + step == 16, x == 0][edge]:
			edges.append([corners[edge], corners[(edge + 1) % 4], surface_kind, colors[start + edge], colors[start + (edge + 1) % 4]])

func build_skirt() -> void:
	var edge: Array = edges[edge_cursor]
	var first: Vector3 = edge[0]
	var last: Vector3 = edge[1]
	var start := vertices.size()
	vertices.append_array(PackedVector3Array([first, first - Vector3.UP * skirt_depth, last - Vector3.UP * skirt_depth, last]))
	var along := last - first
	var normal := Vector3(along.z, 0, -along.x).normalized()
	for corner in range(4):
		normals.append(normal)
		colors.append(edge[3] if corner < 2 else edge[4])
		uvs.append(Vector2(edge[2], 0))
		var at := first if corner < 2 else last
		blends.append_array(vertex_data(coord*16 + Vector2i(roundi(at.x),roundi(at.z))).blend)
	indices.append_array(PackedInt32Array([start, start + 1, start + 2, start, start + 2, start + 3]))

func upload() -> void:
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	arrays[Mesh.ARRAY_CUSTOM0] = blends
	mesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays, [], {}, Mesh.ARRAY_CUSTOM_RGB_FLOAT << Mesh.ARRAY_FORMAT_CUSTOM0_SHIFT)
