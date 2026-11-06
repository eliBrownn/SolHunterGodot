extends Node3D
## Streams the completed atlas into nearby terrain and distant horizon rings.

const CHUNK_SIZE := 64
const CHUNK_RADIUS := 8
const CENTER_HYSTERESIS := 8
const SAMPLE_STEP := 4
const SEED_ARGUMENT := "--world-seed="
const Plan := preload("res://scripts/world/world_map_plan.gd")
const Surface := preload("res://scripts/world/world_map_surface.gd")
# Extend the existing sampling bands by at least 30%, aligned to the
# following ring's grid so the shared edges can still stitch.
const HORIZON_RINGS := [688, 736, 832, 1024, 1408, 2816, 5632, 8192]
const GRID_SHADER := preload("res://shaders/map_terrain.gdshader")
const TreeSpecies := preload("res://scripts/scenery/map_tree_species.gd")
const Vegetation := preload("res://scripts/presentation/map_vegetation.gd")
const HorizonForest := preload("res://scripts/presentation/map_horizon_forest.gd")
const Community := preload("res://scripts/world/plant_community.gd")
const COOL_WATER_PATH := "res://assets/local/emace_cool_water/Materials/EA_Water_DeepBlue.tres"
const WATER_DETAIL_END := 260.0

const CHUNK_UPLOADS_PER_FRAME := 2

## Visual plant density, captured when the scene starts. Zero shows terrain alone.
@export_range(0.0, 1.0, 0.05) var plant_coverage := 0.72
## Uniform size of grass, ground plants and trees. Captured at startup.
@export_range(0.5, 2.5, 0.05) var plant_scale := 1.5
## Custom tree species, with spawn biomes and per-species size settings.
@export var tree_species: Array[TreeSpecies] = Vegetation.DEFAULT_TREE_SPECIES.duplicate()

class TerrainSamples:
	var _surface: Surface
	var _broad := FastNoiseLite.new()
	var _ridge := FastNoiseLite.new()
	var _heights: Dictionary = {}
	var _cache := preload("res://scripts/core/derived_cache_window.gd").new(32768)
	var _cool_water: bool

	func _init(surface: Surface, cool_water: bool, world_seed: int) -> void:
		_surface = surface
		_cool_water = cool_water
		TerrainHeightfield.configure(_broad, world_seed ^ 0x31c8f, 1.0 / 52.0)
		TerrainHeightfield.configure(_ridge, world_seed ^ 0x5a711, 1.0 / 285.0)

	func _sample(at: Vector2i) -> Vector2:
		if _heights.has(at):
			return _heights[at]
		var point := Vector2(at)
		var value := Vector2(_surface.sample_height(point, _broad, _ridge),
			_surface.water_depth(point, _ridge) if _cool_water else 0.0)
		_cache.store(_heights, at, value)
		return value

	func height(at: Vector2i) -> float:
		return _sample(at).x

	func depth(at: Vector2i) -> float:
		return _sample(at).y

	func bed(at: Vector2i) -> float:
		var sample := _sample(at)
		return sample.x - sample.y

	func normal(at: Vector2i) -> Vector3:
		var dx := (bed(at + Vector2i.RIGHT) - bed(at + Vector2i.LEFT)) * 0.5
		var dz := (bed(at + Vector2i.DOWN) - bed(at + Vector2i.UP)) * 0.5
		return Vector3(-dx, 1.0, -dz).normalized()

var _chunks: Dictionary[Vector2i, MeshInstance3D] = {}
var _center := Vector2i.ZERO
var _requested_center := Vector2i.ZERO
var _material: ShaderMaterial
var _water_material: ShaderMaterial
var _plan: Plan
var _surface: Surface
var _samples: TerrainSamples
var _horizon: MeshInstance3D
var _vegetation: Vegetation
var _worker: Thread
var _prepared: Dictionary = {}
var _staged_horizon: ArrayMesh
var _horizon_forest: Node3D
var _staged_forest: Node3D
var _next_surface := 0
var _next_forest_patch := 0
var world_seed: int


func _ready() -> void:
	world_seed = _choose_seed()
	print("SolHunter world seed: ", world_seed)
	_plan = Plan.new(world_seed)
	_surface = Surface.new(_plan, world_seed)
	_material = _surface.make_material(GRID_SHADER, _plan.terrain_layers().irrigation)
	if RenderingServer.get_current_rendering_method() != "gl_compatibility" and ResourceLoader.exists(COOL_WATER_PATH):
		var preset := load(COOL_WATER_PATH) as ShaderMaterial
		if preset != null:
			_water_material = preset.duplicate() as ShaderMaterial
			for parameter in ["atlas_flags", "atlas_rivers", "atlas_origin", "atlas_extent"]:
				_water_material.set_shader_parameter(parameter, _material.get_shader_parameter(parameter))
			_water_material.set_shader_parameter("water_detail_end", WATER_DETAIL_END)
			_material.set_shader_parameter("water_detail_end", WATER_DETAIL_END)
			_material.set_shader_parameter("cool_water_enabled", true)
	_samples = TerrainSamples.new(_surface, _water_material != null, world_seed)
	_horizon = MeshInstance3D.new()
	_horizon.material_override = _material
	_horizon.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_horizon)
	_vegetation = Vegetation.new()
	_vegetation.name = "Vegetation"
	_vegetation.configure(_plan, _surface, world_seed, CHUNK_SIZE, plant_coverage, plant_scale, tree_species,
		height_at, _planting_chunk_ready)
	add_child(_vegetation)


func _choose_seed() -> int:
	for argument in OS.get_cmdline_user_args():
		if not argument.begins_with(SEED_ARGUMENT):
			continue
		var value := argument.trim_prefix(SEED_ARGUMENT)
		if value.is_valid_int() and value.to_int() >= 1 and value.to_int() <= 2147483646:
			return value.to_int()
		push_warning("Invalid world seed. Generating a new one.")
		break
	return RandomNumberGenerator.new().randi_range(1, 2147483646)


func _exit_tree() -> void:
	if _staged_forest != null:
		_staged_forest.free()
		_staged_forest = null
	if _worker != null:
		_worker.wait_to_finish()

func beach_spawn() -> Dictionary:
	return _surface.beach_spawn()


func is_land_at(at: Vector2) -> bool:
	return _surface.is_land(at)


func biome_name(cell: Vector2i) -> String:
	return _surface.biome_name(Vector2(cell) + Vector2(0.5, 0.5))

func height_at(at: Vector2) -> float:
	var sample_origin := (at / SAMPLE_STEP).floor() * SAMPLE_STEP
	var origin := Vector2i(sample_origin)
	var heights := Vector4(_samples.height(origin),
		_samples.height(origin + Vector2i(SAMPLE_STEP, 0)),
		_samples.height(origin + Vector2i.ONE * SAMPLE_STEP),
		_samples.height(origin + Vector2i(0, SAMPLE_STEP)))
	return TerrainHeightfield.interpolate(heights, (at - sample_origin) / SAMPLE_STEP)


func cover(cell: Vector2i) -> void:
	_vegetation.cover(cell)
	var containing := Vector2i((Vector2(cell) / CHUNK_SIZE).floor())
	if not _chunks.is_empty():
		var offset := cell - _requested_center * CHUNK_SIZE
		if offset.x < -CENTER_HYSTERESIS or offset.x >= CHUNK_SIZE + CENTER_HYSTERESIS:
			_requested_center.x = containing.x
		if offset.y < -CENTER_HYSTERESIS or offset.y >= CHUNK_SIZE + CENTER_HYSTERESIS:
			_requested_center.y = containing.y
		return
	_requested_center = containing
	# Prepare the initial walkable ground before releasing the player. The
	# horizon and all subsequent terrain rebuilds go through the worker.
	_center = _requested_center
	for key in _missing_chunks(_center):
		_publish_chunk(key, _build_chunk_arrays(key * CHUNK_SIZE, _samples))


func _planting_chunk_ready(key: Vector2i) -> bool:
	return _chunks.has(key) and _chunks[key].visible


func _process(_delta: float) -> void:
	if _worker != null:
		if _worker.is_alive():
			return
		_prepared = _worker.wait_to_finish()
		_worker = null
		_staged_horizon = ArrayMesh.new()
		_staged_forest = Node3D.new()
		_staged_forest.name = "HorizonForest"
		_next_surface = 0
		_next_forest_patch = 0
	if not _prepared.is_empty():
		_publish_prepared()
		return
	if _horizon.mesh != null and _requested_center == _center:
		return
	var worker := Thread.new()
	var result := worker.start(_prepare_terrain.bind(_requested_center, _missing_chunks(_requested_center), _surface,
		_water_material != null, world_seed, _plan, _vegetation.horizon_settings()), Thread.PRIORITY_LOW)
	if result == OK:
		_worker = worker
	else:
		push_warning("Could not start the terrain worker.")
		set_process(false)


func _missing_chunks(center: Vector2i) -> Array[Vector2i]:
	var missing: Array[Vector2i] = []
	for z in range(center.y - CHUNK_RADIUS, center.y + CHUNK_RADIUS):
		for x in range(center.x - CHUNK_RADIUS, center.x + CHUNK_RADIUS):
			var key := Vector2i(x, z)
			if not _chunks.has(key):
				missing.append(key)
	return missing


func _prepare_terrain(center: Vector2i, missing: Array[Vector2i], surface: Surface, cool_water: bool,
		seed_value: int, plan: Plan, forest_settings: Dictionary) -> Dictionary:
	# The worker owns its sample caches and only returns packed mesh arrays.
	var samples := TerrainSamples.new(surface, cool_water, seed_value)
	var chunks: Dictionary[Vector2i, Array] = {}
	for key in missing:
		chunks[key] = _build_chunk_arrays(key * CHUNK_SIZE, samples)
	var forest: Array = []
	var horizon := _build_horizon(center * CHUNK_SIZE, samples, plan, seed_value, forest_settings, forest)
	return {"center": center, "chunks": chunks, "horizon": horizon, "forest": forest}


func _publish_prepared() -> void:
	var prepared_center: Vector2i = _prepared.center
	# Publish useful forward progress when the player outruns the worker.
	if _horizon.mesh != null and prepared_center.distance_squared_to(_requested_center) >= _center.distance_squared_to(_requested_center):
		_finish_prepared()
		return
	var chunks: Dictionary = _prepared.chunks
	var keys := chunks.keys()
	for index in mini(keys.size(), CHUNK_UPLOADS_PER_FRAME):
		var key: Vector2i = keys[index]
		_publish_chunk(key, chunks[key], false)
		chunks.erase(key)
	if not keys.is_empty():
		return
	var surfaces: Array = _prepared.horizon
	var forest: Array = _prepared.forest
	for index in range(_next_surface, mini(_next_surface + CHUNK_UPLOADS_PER_FRAME, surfaces.size())):
		var patches: Array = forest[index] if index < forest.size() else []
		if _next_forest_patch < patches.size():
			var patch: Dictionary = patches[_next_forest_patch]
			if not _vegetation.prepare_horizon_models(patch.groups):
				break
			_vegetation.publish_horizon_patch(_staged_forest, patch, index)
			_next_forest_patch += 1
			if _next_forest_patch < patches.size():
				break
		_staged_horizon.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surfaces[index])
		_next_surface += 1
		_next_forest_patch = 0
	if _next_surface < surfaces.size():
		return
	_center = prepared_center
	var anchor := _center * CHUNK_SIZE
	_horizon.position = Vector3(anchor.x, 0.0, anchor.y)
	_horizon.mesh = _staged_horizon
	if _horizon_forest != null:
		_horizon.remove_child(_horizon_forest)
		_horizon_forest.queue_free()
	_horizon_forest = _staged_forest
	_staged_forest = null
	_horizon.add_child(_horizon_forest)
	_vegetation.activate_horizon_lods(_horizon_forest)
	_finish_prepared()


func _finish_prepared() -> void:
	_staged_horizon = null
	if _staged_forest != null:
		_staged_forest.free()
		_staged_forest = null
	_prepared.clear()
	for key: Vector2i in _chunks.keys():
		var offset := key - _center
		if offset.x < -CHUNK_RADIUS or offset.x >= CHUNK_RADIUS or offset.y < -CHUNK_RADIUS or offset.y >= CHUNK_RADIUS:
			var old_chunk := _chunks[key]
			remove_child(old_chunk)
			old_chunk.queue_free()
			_chunks.erase(key)
		else:
			_chunks[key].show()
	_vegetation.sync_terrain_coverage()


func _publish_chunk(key: Vector2i, arrays: Array, show_now: bool = true) -> void:
	var chunk := MeshInstance3D.new()
	chunk.mesh = _make_mesh(arrays[0])
	chunk.position = Vector3(key.x, 0.0, key.y) * CHUNK_SIZE
	chunk.material_override = _material
	chunk.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	chunk.visible = show_now
	if not arrays[1].is_empty():
		var water := MeshInstance3D.new()
		water.name = "CoolWater"
		water.mesh = _make_mesh(arrays[1])
		water.material_override = _water_material
		water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		# Cull whole patches outside the shader's fade, with a margin for patch bounds.
		water.visibility_range_end = WATER_DETAIL_END + CHUNK_SIZE
		chunk.add_child(water)
	add_child(chunk)
	_chunks[key] = chunk

func _build_horizon(anchor: Vector2i, samples: TerrainSamples, plan: Plan = null,
		seed_value: int = 0, forest_settings: Dictionary = {}, forest: Array = []) -> Array:
	var surfaces: Array = []
	var canopy: Community
	if not forest_settings.is_empty():
		canopy = Community.new()
		canopy.configure(seed_value ^ 0x712d3, 24.0, 1.0, 4.0, 0.0, 1)
	var radius := CHUNK_RADIUS * CHUNK_SIZE
	var inner := Rect2i(-radius, -radius, radius * 2, radius * 2)
	var step := SAMPLE_STEP
	for ring in HORIZON_RINGS.size():
		radius = HORIZON_RINGS[ring]
		var stitch := ring < HORIZON_RINGS.size() - 1
		# Keep distant samples fixed in world space as the inner hole moves.
		var grid := step * 2 if stitch else step
		var offset := Vector2i(Vector2(anchor).snapped(Vector2.ONE * grid)) - anchor
		var outer := Rect2i(offset - Vector2i.ONE * radius, Vector2i.ONE * radius * 2)
		var strips := [
			Rect2i(outer.position.x, outer.position.y, outer.size.x, inner.position.y - outer.position.y),
			Rect2i(outer.position.x, inner.end.y, outer.size.x, outer.end.y - inner.end.y),
			Rect2i(outer.position.x, inner.position.y, inner.position.x - outer.position.x, inner.size.y),
			Rect2i(inner.end.x, inner.position.y, outer.end.x - inner.end.x, inner.size.y),
		]
		for strip: Rect2i in strips:
			var vertices := PackedVector3Array()
			var normals := PackedVector3Array()
			var indices := PackedInt32Array()
			_append_strip(samples, anchor, strip, step, outer if stitch else Rect2i(),
				vertices, normals, indices)
			surfaces.append(_mesh_arrays(vertices, normals, indices))
			if canopy != null:
				forest.append(HorizonForest.sample_strip(plan, samples._surface, canopy, forest_settings,
					anchor, strip, step, ring, vertices))
		inner = outer
		step *= 2
	return surfaces


func _append_strip(samples: TerrainSamples, anchor: Vector2i, strip: Rect2i, step: int, stitch_edge: Rect2i,
		vertices: PackedVector3Array, normals: PackedVector3Array, indices: PackedInt32Array) -> void:
	var base := vertices.size()
	var width := strip.size.x / step + 1
	var depth := strip.size.y / step + 1
	for z in depth:
		for x in width:
			var local := strip.position + Vector2i(x, z) * step
			var at := anchor + local
			var height := samples.bed(at)
			var normal := samples.normal(at)
			# Midpoints on the outer edge must lie on the next ring's coarser edge.
			var axis := Vector2i.ZERO
			if stitch_edge.has_area():
				if (local.x == stitch_edge.position.x or local.x == stitch_edge.end.x) and posmod(at.y, step * 2) != 0:
					axis = Vector2i.DOWN
				elif (local.y == stitch_edge.position.y or local.y == stitch_edge.end.y) and posmod(at.x, step * 2) != 0:
					axis = Vector2i.RIGHT
			if axis != Vector2i.ZERO:
				var offset := axis * step
				height = (samples.bed(at - offset) + samples.bed(at + offset)) * 0.5
				normal = (samples.normal(at - offset) + samples.normal(at + offset)).normalized()
			vertices.append(Vector3(local.x, height, local.y))
			normals.append(normal)
			if x < width - 1 and z < depth - 1:
				var nw := base + z * width + x
				var se := nw + width + 1
				indices.append_array(PackedInt32Array([nw, nw + 1, se, nw, se, nw + width]))


func _build_chunk_arrays(origin: Vector2i, samples: TerrainSamples) -> Array:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var indices := PackedInt32Array()
	_append_strip(samples, origin, Rect2i(0, 0, CHUNK_SIZE, CHUNK_SIZE), SAMPLE_STEP, Rect2i(),
		vertices, normals, indices)
	return [_mesh_arrays(vertices, normals, indices), _build_water_arrays(origin, samples, vertices, indices)]


func _build_water_arrays(origin: Vector2i, samples: TerrainSamples, ground: PackedVector3Array,
		triangles: PackedInt32Array) -> Array:
	if not samples._cool_water:
		return []
	var depths := PackedFloat32Array()
	depths.resize(ground.size())
	var has_water := false
	for index in ground.size():
		var vertex := ground[index]
		var depth := samples.depth(origin + Vector2i(int(vertex.x), int(vertex.z)))
		depths[index] = depth
		has_water = has_water or depth > 0.02
	if not has_water:
		return []
	var vertices := ground.duplicate()
	var normals := PackedVector3Array()
	normals.resize(vertices.size())
	normals.fill(Vector3.UP)
	for index in vertices.size():
		vertices[index].y += depths[index] + 0.015
	var indices := PackedInt32Array()
	for index in range(0, triangles.size(), 3):
		var a := triangles[index]
		var b := triangles[index + 1]
		var c := triangles[index + 2]
		if maxf(depths[a], maxf(depths[b], depths[c])) > 0.02:
			indices.append_array(PackedInt32Array([a, b, c]))
	return _mesh_arrays(vertices, normals, indices)


func _mesh_arrays(vertices: PackedVector3Array, normals: PackedVector3Array, indices: PackedInt32Array) -> Array:
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	return arrays


func _make_mesh(arrays: Array) -> ArrayMesh:
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh
