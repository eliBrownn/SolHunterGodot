extends Node3D
## Lightweight, read-only ground coverage while budgeted terrain/scenery is queued.
## Samples the existing generator; edge skirts cover LOD seams without moving fog.
const ViewStreaming = preload("res://scripts/presentation/view_streaming.gd")
var chunks: Dictionary = {}
var retained: Dictionary = {}
var cache_limit := 64
var builds := 0
var reuses := 0
var visibility_passes := 0
var last_view: Array = []
var last_pending: Array[Vector2i] = []
var source: WorldTerrain
var source_nature: NatureSettings
var material := ShaderMaterial.new()
var max_prepare_ms := 0.0
var max_runtime_ms := 0.0
var sample_step := 4
var preparing := Vector2i(2147483647, 2147483647)
var geography_prepared := 0
var work_job: RefCounted
var work_coord := Vector2i.ZERO
var last_operations := 0
var last_uploads := 0

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

func sync(terrain: WorldTerrain, pending: Array[Vector2i], camera: Camera3D, origin: Vector2, height: float, step: int, retained_limit: int = 64, deadline_usec: int = 0, nature: NatureSettings = null, operation_limit: int = 32, upload_limit: int = 1) -> void:
	var started := Time.get_ticks_usec()
	last_operations = 0
	last_uploads = 0
	if source != terrain or sample_step != step or source_nature != nature:
		clear()
		source = terrain
		source_nature = nature
		sample_step = step
		# Settings apply on rebuild; camera motion does not change these uniforms.
		if nature != null:
			nature.apply_terrain_material(material)
			material.set_shader_parameter("terrain_palette_seed", float(posmod(terrain.world_seed, 65521)))
			material.set_shader_parameter("ground_base_color", nature.ground_base_color)
			material.set_shader_parameter("ground_texture_strength", nature.ground_texture_strength)
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
	if work_job != null and not wanted.has(work_coord): work_job = null
	for coord: Vector2i in chunks.keys():
		if not wanted.has(coord):
			remove(coord)
	var complete := true
	var ordered: Array = wanted.keys()
	if work_job != null:
		ordered.erase(work_coord)
		ordered.push_front(work_coord)
	for coord: Vector2i in ordered:
		if not chunks.has(coord):
			var ground: MeshInstance3D
			if retained.has(coord):
				ground = retained[coord]
				retained.erase(coord)
				ground.show()
				reuses += 1
			else:
				if deadline_usec > 0 and (last_operations >= operation_limit or last_uploads >= upload_limit):
					complete = false
					break
				if deadline_usec > 0 and Time.get_ticks_usec() >= deadline_usec:
					complete = false
					break
				if deadline_usec > 0 and not prepare_geography(terrain, coord, deadline_usec, operation_limit):
					complete = false
					break
				if deadline_usec > 0 and Time.get_ticks_usec() >= deadline_usec:
					complete = false
					break
				var ready_mesh: ArrayMesh
				if deadline_usec > 0:
					if work_job == null:
						work_coord = coord
						work_job = preload("res://scripts/presentation/coarse_ground_job.gd").new(terrain, coord, sample_step, nature)
					var ready: bool = work_job.advance(deadline_usec, operation_limit - last_operations)
					last_operations += work_job.operations
					last_uploads += work_job.uploads
					if not ready:
						complete = false
						break
					ready_mesh = work_job.mesh
					work_job = null
				else:
					ready_mesh = build(terrain, coord, sample_step, nature)
				ground = MeshInstance3D.new()
				ground.mesh = ready_mesh
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
	if deadline_usec > 0: max_runtime_ms = maxf(max_runtime_ms, (Time.get_ticks_usec() - started) / 1000.0)

## Temporary coverage shares the detailed terrain deadline. Otherwise its first
## coarse sample can synchronously compile all cold road districts before the
## budgeted detail job gets a chance to run.
func prepare_geography(terrain: WorldTerrain, coord: Vector2i, deadline: int, operation_limit: int = 32) -> bool:
	if preparing != coord:
		preparing = coord
		geography_prepared = 0
	var low: Vector2i = terrain.geography.region(Vector2(coord * 16 - Vector2i.ONE)) - Vector2i(2, 2)
	var high: Vector2i = terrain.geography.region(Vector2(coord * 16 + Vector2i(16, 16))) + Vector2i(2, 2)
	var width := high.x - low.x + 1
	var count := width * (high.y - low.y + 1)
	while geography_prepared < count and Time.get_ticks_usec() < deadline and last_operations < operation_limit:
		last_operations += 1
		var owner := low + Vector2i(geography_prepared % width, geography_prepared / width)
		if terrain.geography.prepare_paths(terrain, owner): geography_prepared += 1
	return geography_prepared == count

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
	work_job = null
	preparing = Vector2i(2147483647, 2147483647)
	geography_prepared = 0
	for ground in chunks.values():
		ground.free()
	chunks.clear()
	for ground in retained.values():
		ground.free()
	retained.clear()
	last_view.clear()
	last_pending.clear()

static func build(terrain: WorldTerrain, coord: Vector2i, step: int = 4, nature: NatureSettings = null) -> ArrayMesh:
	var job := preload("res://scripts/presentation/coarse_ground_job.gd").new(terrain, coord, step, nature)
	while not job.advance(0): pass
	return job.mesh
