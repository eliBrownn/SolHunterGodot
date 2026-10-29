extends Node3D
## Lightweight, read-only ground coverage while budgeted terrain/scenery is queued.
## Samples the existing generator; edge skirts cover LOD seams without moving fog.
const ViewStreaming = preload("res://scripts/view_streaming.gd")
var chunks: Dictionary = {}
var retained: Dictionary = {}
var cache_limit := 64
var builds := 0
var reuses := 0
var visibility_passes := 0
var last_view: Array = []
var last_pending: Array[Vector2i] = []
var source: WorldTerrain
var material := ShaderMaterial.new()
var max_prepare_ms := 0.0
var sample_step := 4

func _init() -> void:
	material.shader = preload("res://shaders/streaming_ground.gdshader")
	var grass: AtlasTexture = PackArt.atlas("TX Tileset Grass/TX Tileset Grass 0")
	material.set_shader_parameter("ground_atlas", grass.atlas)
	material.set_shader_parameter("grass_uv", region(grass))
	material.set_shader_parameter("trail_uv", region(PackArt.atlas("TX Tileset Grass/TX Tileset Grass Pavement 0")))

static func region(atlas: AtlasTexture) -> Vector4:
	var size := Vector2(atlas.atlas.get_width(), atlas.atlas.get_height())
	var first := (atlas.region.position + Vector2(0.5, 0.5)) / size
	var last := (atlas.region.end - Vector2(0.5, 0.5)) / size
	return Vector4(first.x, first.y, last.x, last.y)

func sync(terrain: WorldTerrain, pending: Array[Vector2i], camera: Camera3D, origin: Vector2, height: float, step: int, retained_limit: int = 64, deadline_usec: int = 0) -> void:
	var started := Time.get_ticks_usec()
	if source != terrain or sample_step != step:
		clear()
		source = terrain
		sample_step = step
	cache_limit = clampi(retained_limit, 0, 256)
	trim_cache()
	var view: Array = [camera.global_transform, camera.get_camera_projection(), camera.get_viewport().get_visible_rect().size, origin, height, cache_limit]
	if view == last_view and pending == last_pending:
		return
	visibility_passes += 1
	material.set_shader_parameter("world_origin", origin)
	var planes := camera.get_frustum()
	var wanted := {}
	for coord in pending:
		if ViewStreaming.visible_with_planes(planes, Vector2(coord * 16) - origin, height, 0.0, -height):
			wanted[coord] = true
	for coord: Vector2i in chunks.keys():
		if not wanted.has(coord):
			remove(coord)
	var complete := true
	for coord: Vector2i in wanted:
		if not chunks.has(coord):
			var ground: MeshInstance3D
			if retained.has(coord):
				ground = retained[coord]
				retained.erase(coord)
				ground.show()
				reuses += 1
			else:
				if deadline_usec > 0 and Time.get_ticks_usec() >= deadline_usec:
					complete = false
					break
				ground = MeshInstance3D.new()
				ground.mesh = build(terrain, coord, sample_step)
				ground.material_override = material
				ground.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				ground.position = Vector3(coord.x * 16, 0, coord.y * 16)
				add_child(ground)
				builds += 1
			chunks[coord] = ground
	if complete:
		last_view = view
		last_pending.assign(pending)
	else:
		last_view.clear() # Retry unfinished coverage even if the camera stops.
	max_prepare_ms = maxf(max_prepare_ms, (Time.get_ticks_usec() - started) / 1000.0)

func remove(coord: Vector2i) -> void:
	if chunks.has(coord):
		var ground: MeshInstance3D = chunks[coord]
		chunks.erase(coord)
		ground.hide()
		retained[coord] = ground
		trim_cache()
		last_view.clear()

func trim_cache() -> void:
	while retained.size() > cache_limit:
		var oldest: Vector2i = retained.keys()[0]
		retained[oldest].free()
		retained.erase(oldest)

func clear() -> void:
	for ground in chunks.values():
		ground.free()
	chunks.clear()
	for ground in retained.values():
		ground.free()
	retained.clear()
	last_view.clear()
	last_pending.clear()

static func build(terrain: WorldTerrain, coord: Vector2i, step: int = 4) -> ArrayMesh:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	var edges: Array = []
	for y in range(0, 16, step):
		for x in range(0, 16, step):
			var cell := coord * 16 + Vector2i(x, y)
			var sample := cell + Vector2i(step / 2, step / 2)
			var kind: int = terrain.natural_ground(sample)
			var water: bool = kind == WorldTerrain.Ground.WATER
			var level: float = terrain.pond_at(sample).level if water else 0.0
			var trail: bool = not water and (absi(sample.y - terrain.trail_y(sample.x)) <= 1 or terrain.route_axes(sample, -2) != 0)
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
				colors.append(color)
				uvs.append(Vector2(surface_kind, 0))
			indices.append_array(PackedInt32Array([start, start + 1, start + 2, start, start + 2, start + 3]))
			# Boundary skirts conceal coarse/full-resolution seams; water skirts also
			# close temporary shore transitions within a chunk. They never collide.
			for edge in range(4):
				if water or [y == 0, x + step == 16, y + step == 16, x == 0][edge]:
					edges.append([corners[edge], corners[(edge + 1) % 4], color, surface_kind])
	var skirt_depth: float = (float(terrain.relief.broad_amplitude) + float(terrain.relief.detail_amplitude) + float(terrain.relief.micro_amplitude)) * 2 + 2
	for edge in edges:
		var first: Vector3 = edge[0]
		var last: Vector3 = edge[1]
		var start := vertices.size()
		vertices.append_array(PackedVector3Array([first, first - Vector3.UP * skirt_depth, last - Vector3.UP * skirt_depth, last]))
		var along := last - first
		var normal := Vector3(along.z, 0, -along.x).normalized()
		for corner in range(4):
			normals.append(normal)
			colors.append(edge[2])
			uvs.append(Vector2(edge[3], 0))
		indices.append_array(PackedInt32Array([start, start + 1, start + 2, start, start + 2, start + 3]))
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh
