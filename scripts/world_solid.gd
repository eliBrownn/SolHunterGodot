extends "res://scripts/world_plane.gd"
## Optional solid-3D view over the unchanged generated world and expedition simulation.

const SolidChunk = preload("res://scripts/solid_chunk.gd")
const PlayerVisibility = preload("res://scripts/player_visibility.gd")
const ViewStreaming = preload("res://scripts/view_streaming.gd")
const MeshPicking = preload("res://scripts/mesh_picking.gd")
const TerrainRay = preload("res://scripts/terrain_ray.gd")
@export_group("3D View")
## Perspective, dolly range, draw/stream/shadow distances, sky and fog. Restart/reapply to use edits.
@export var view_settings: View3DSettings = preload("res://resources/view_3d_settings.tres")
## Imported biome meshes, visual sizes and nonblocking decoration density. Rebuild/restart to apply; not saved.
@export var nature_settings: NatureSettings = preload("res://resources/nature_settings.tres")
## Cosmetic roof trim only. Rebuild/restart applies, including loaded expeditions.
@export var shelter_roof_trim := true
## Saved-clock day/night, deterministic clear/cloudy/rain weather, sun/moon and ambient lighting.
@export var atmosphere_settings: AtmosphereSettings = preload("res://resources/atmosphere_settings.tres")
var atmosphere_controller: Node
var active_nature: NatureSettings
var active_view: View3DSettings
var environment := Environment.new()
var sun := DirectionalLight3D.new()
var view_revision := 0
var view_hint: Label
var pointer_subject := ""
var solid_root := Node3D.new()
var place_root: Node3D
var solid_chunks: Dictionary = {}
var retained_solid: Dictionary = {}
var retired_solid: Array[Node3D] = []
var detail_cache_reuses := 0
var stream_job: RefCounted
var max_stream_slice_ms := 0.0
var max_stream_geometry_ms := 0.0
var stream_step_peaks := {"geography": 0.0, "generation": 0.0, "cell": 0.0, "upload": 0.0}
var streaming_ground := preload("res://scripts/streaming_ground.gd").new()
var selection := Node3D.new()
var player_shadow := MeshInstance3D.new()
var visibility_aid: Node3D

func _ready() -> void:
	active_view = view_settings if view_settings != null and view_settings.valid() else View3DSettings.new()
	if active_view != view_settings:
		push_warning("Invalid 3D view settings; using defaults.")
	active_nature = nature_settings if nature_settings != null and nature_settings.valid() else NatureSettings.new()
	if active_nature != nature_settings:
		push_warning("Invalid nature settings; using the default visual palette.")
	if active_nature.composition != null:
		# Compile the small bounded static palette before publishing streamed chunks.
		for patch in active_nature.composition.patches:
			for entry in patch.entries:
				entry.admitted_model()
	# Flatten and prepare shared static mesh/picking data before walking begins.
	for palette in [active_nature.common_trees, active_nature.hardy_trees, active_nature.rocks, active_nature.undergrowth]:
		for asset in palette:
			preload("res://scripts/nature_art.gd").compact_parts(asset)
			for piece in preload("res://scripts/nature_art.gd").parts(asset).pieces:
				MeshPicking.prepare(piece.mesh)
	capture_directory = "res://artifacts/solid3d"
	super._ready()
	# Rebase after the 2D simulation updates its camera, avoiding a one-frame ground lag.
	process_priority = 1
	# Retain the simulation and HUD; remove the baked world image from this view.
	surface.hide()
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	world.chunk_root.hide()
	world.actors.hide()
	player_visual.ground_height = 0.06
	add_child(solid_root)
	solid_root.add_child(streaming_ground)
	build_selection()
	build_player_shadow()
	visibility_aid = PlayerVisibility.new()
	add_child(visibility_aid)
	visibility_aid.bind(player_visual, camera)
	world.chunk_published.connect(publish_solid)
	world.chunk_removed.connect(remove_solid)
	world.rebuilt.connect(build_solid_places)
	for coord: Vector2i in world.chunks:
		publish_solid(coord, world.chunks[coord].view.cells)
	build_solid_places()
	sun.directional_shadow_max_distance = minf(active_view.shadow_distance, active_view.render_distance)
	add_child(sun)
	configure_environment()
	var atmosphere := WorldEnvironment.new()
	atmosphere.environment = environment
	add_child(atmosphere)
	atmosphere_controller = preload("res://scripts/atmosphere_controller.gd").new()
	add_child(atmosphere_controller)
	atmosphere_controller.bind(self, atmosphere_settings)
	sync_ground()
	view_hint = world.label("", 14, Color("e1c791"))
	view_hint.position = Vector2(350, 30)
	world.hud.add_child(view_hint)
	get_viewport().size_changed.connect(view_changed)
	view_changed()

func configure_environment() -> void:
	get_viewport().msaa_3d = active_view.multisample_antialiasing
	environment.ssao_enabled = active_view.ambient_occlusion
	environment.ssao_radius = active_view.occlusion_radius
	environment.ssao_intensity = active_view.occlusion_intensity
	var sky: Sky = environment.sky if environment.sky != null else Sky.new()
	var material: ShaderMaterial = sky.sky_material if sky.sky_material is ShaderMaterial else ShaderMaterial.new()
	material.shader = active_view.sky_shader
	material.set_shader_parameter("cloud_tex_01", active_view.cloud_primary)
	material.set_shader_parameter("cloud_tex_02", active_view.cloud_secondary)
	material.set_shader_parameter("sky_day", active_view.sky_color)
	material.set_shader_parameter("horizon_day", active_view.horizon_color)
	material.set_shader_parameter("cloud_density", active_view.cloud_density)
	material.set_shader_parameter("wind_speed", active_view.cloud_wind)
	sky.sky_material = material
	sky.radiance_size = Sky.RADIANCE_SIZE_128
	environment.sky = sky
	environment.background_mode = Environment.BG_SKY
	environment.fog_enabled = true
	environment.fog_mode = Environment.FOG_MODE_DEPTH
	environment.fog_light_color = active_view.horizon_color
	environment.fog_depth_begin = (active_view.render_distance - 4.0) * active_view.fog_start_fraction
	environment.fog_depth_end = active_view.render_distance - 4.0
	environment.fog_density = 1.0
	environment.fog_sky_affect = 0.0
	if atmosphere_controller != null:
		atmosphere_controller.update()

func apply_atmosphere_settings() -> void:
	if atmosphere_controller != null:
		atmosphere_controller.configure(atmosphere_settings)

func reset_camera() -> void:
	camera_focus = Vector3.ZERO
	target_size = active_view.starting_distance if active_view != null else 22.0
	view_elevation = clampf(camera_elevation, 10, 80) if is_finite(camera_elevation) else 35.0
	view_azimuth = wrapf(camera_azimuth, -180, 180) if is_finite(camera_azimuth) else 0.0
	apply_camera()

func apply_camera() -> void:
	update_camera_pose()
	view_changed()

func update_camera_pose() -> void:
	if active_view == null:
		return
	camera.projection = Camera3D.PROJECTION_PERSPECTIVE
	camera.fov = active_view.field_of_view
	camera.near = 0.1
	camera.far = active_view.render_distance
	var elevation := deg_to_rad(view_elevation)
	var azimuth := deg_to_rad(view_azimuth)
	var focus := camera_focus
	if world != null:
		focus.y = world.terrain.surface_height(world.camera.position / 32.0 + Vector2(focus.x, focus.z))
	camera.position = Vector3(sin(azimuth) * cos(elevation), sin(elevation), cos(azimuth) * cos(elevation)) * target_size + focus
	if world != null:
		var camera_at: Vector2 = world.camera.position / 32.0 + Vector2(camera.position.x, camera.position.z)
		camera.position.y = maxf(camera.position.y, world.terrain.surface_height(camera_at) + active_view.ground_clearance)
	camera.look_at(focus)
	camera.size = target_size # Diagnostic parity with the flat comparison scene.

func height_bound() -> float:
	var tuning: Dictionary = world.terrain.relief
	return (float(tuning.broad_amplitude) + float(tuning.detail_amplitude) + float(tuning.micro_amplitude)) * 2.0 + 1.0

func pointer_world(pointer: Vector2 = get_viewport().get_mouse_position()) -> Variant:
	pointer_terrain_depth = INF
	var origin := camera.project_ray_origin(pointer)
	var offset: Vector2 = world.camera.position / 32.0
	var absolute := origin + Vector3(offset.x, 0, offset.y)
	var hit: Variant = TerrainRay.intersect(world.terrain, absolute, camera.project_ray_normal(pointer), camera.far * 1.6)
	if hit == null:
		return null
	var local: Vector3 = hit - Vector3(offset.x, 0, offset.y)
	var depth: float = -camera.to_local(local).z
	if depth < camera.near or depth > camera.far:
		return null
	pointer_terrain_depth = absolute.distance_to(hit)
	return Vector2(hit.x, hit.z) * 32.0

func zoom_camera(amount: float) -> void:
	target_size = clampf(target_size + amount, active_view.minimum_distance, active_view.maximum_distance)
	apply_camera()

func view_changed() -> void:
	view_revision += 1
	if world != null and world.is_node_ready():
		world.plan_chunks()

func apply_view_settings() -> void:
	active_view = view_settings if view_settings != null and view_settings.valid() else View3DSettings.new()
	configure_environment()
	sun.directional_shadow_max_distance = minf(active_view.shadow_distance, active_view.render_distance)
	target_size = clampf(target_size, active_view.minimum_distance, active_view.maximum_distance)
	apply_camera()
	for chunk in solid_chunks.values():
		configure_asset_distances(chunk)

func stream_key() -> String:
	return "%d:%d:%d:%d:%d" % [floori(world.camera.position.x / 128.0), floori(world.camera.position.y / 128.0), WorldTerrain.floor_div(world.cell.x, 16), WorldTerrain.floor_div(world.cell.y, 16), view_revision]

func stream_plan() -> Array[Vector2i]:
	return ViewStreaming.plan(camera, world.camera.position / 32.0, world.cell, active_view, active_nature.tree_height * 1.2 + 3 + height_bound(), -height_bound())

func chunk_visible(coord: Vector2i) -> bool:
	return ViewStreaming.visible(camera, Vector2(coord * 16) - world.camera.position / 32.0, active_nature.tree_height * 1.2 + 3 + height_bound(), 0.0, -height_bound())

func stream_capacity() -> int:
	var radius := ceili((active_view.render_distance + active_view.stream_margin) / 16.0) + 1
	return (radius * 2 + 1) * (radius * 2 + 1) + 18

func configure_asset_distances(chunk: Node3D) -> void:
	for mesh in chunk.get_children():
		if mesh is GeometryInstance3D:
			mesh.visibility_range_end = active_view.detail_distance if mesh.name.begins_with("nature_detail_") else 0.0
			mesh.visibility_range_end_margin = 4.0
			mesh.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED

func _process(delta: float) -> void:
	trim_detail_cache()
	for index in range(mini(active_view.chunks_per_frame, retired_solid.size())):
		retired_solid.pop_front().free()
	sync_ground()
	update_horizon(delta)
	if atmosphere_controller != null:
		atmosphere_controller.update()

func update_horizon(_delta: float) -> void:
	# Camera motion must not pull fog over the trainer. Temporary ground covers
	# visible queued chunks while detailed terrain/scenery keeps its frame budget.
	environment.fog_depth_end = active_view.render_distance - 4.0
	environment.fog_depth_begin = environment.fog_depth_end * active_view.fog_start_fraction

func prepare_stream_ground(deadline_usec: int) -> void:
	# The simulation moves first. Use the new pose for coverage, sharing the
	# detailed terrain deadline rather than spending a second unbounded budget.
	update_camera_pose()
	streaming_ground.sync(world.terrain, world.pending, camera, world.camera.position / 32.0, height_bound(), active_view.stream_ground_step, active_view.stream_ground_cache_chunks, deadline_usec)

func pointer_object_cell(pointer: Vector2, fallback: Variant) -> Variant:
	pointer_subject = ""
	var origin := camera.project_ray_origin(pointer)
	var direction := camera.project_ray_normal(pointer)
	var distance := pointer_actor_depth
	var selected: Variant = fallback
	for group in solid_root.get_children():
		if group.get_script() != SolidChunk or not group.is_visible_in_tree():
			continue
		var group_inverse: Transform3D = group.global_transform.affine_inverse()
		var local_origin: Vector3 = group_inverse * origin
		var local_direction: Vector3 = group_inverse.basis * direction
		if group.pick_index_ready and group.pick_bounds.intersects_ray(local_origin, local_direction) == null:
			continue
		for object in group.pick_objects:
			if object.get("category", "") == "detail" and active_view.detail_distance > 0 and group.global_position.distance_to(camera.global_position) > active_view.detail_distance:
				continue
			var transform: Transform3D = group.global_transform * object.transform
			var inverse: Transform3D = object.inverse if object.has("inverse") else object.transform.affine_inverse()
			var object_origin: Vector3 = inverse * local_origin
			var object_direction: Vector3 = inverse.basis * local_direction
			var hit: Variant = object.bounds.grow(0.02).intersects_ray(object_origin, object_direction)
			if hit == null:
				continue
			var depth := origin.distance_to(transform * hit)
			if depth >= distance:
				continue
			hit = MeshPicking.ray(object.mesh, object_origin, object_direction)
			if hit == null:
				continue
			depth = origin.distance_to(transform * hit)
			var camera_depth: float = -camera.to_local(transform * hit).z
			if camera_depth < camera.near or camera_depth > camera.far:
				continue
			if depth < distance:
				distance = depth
				selected = object.cell
				pointer_subject = object.get("subject", "")
	return selected

func sync_ground() -> void:
	update_camera_pose()
	if view_hint != null:
		var arrows := ["↑", "↗", "→", "↘", "↓", "↙", "←", "↖"]
		view_hint.text = "N %s" % arrows[posmod(roundi(view_azimuth / 45.0), 8)]
	solid_root.position = Vector3(-world.camera.position.x / 32.0, 0, -world.camera.position.y / 32.0)
	var origin: Vector2 = world.camera.position / 32.0
	for kind in ["water", "bank", "shore_rim"]:
		if SolidChunk.meshes.has(kind):
			SolidChunk.meshes[kind].material.set_shader_parameter("world_origin", origin)
	var player_at: Vector2 = Vector2(player_visual.position.x, player_visual.position.z) + world.camera.position / 32.0
	player_shadow.position = Vector3(player_visual.position.x, world.terrain.surface_height(player_at) + 0.045, player_visual.position.z)
	player_shadow.basis = Basis(Quaternion(Vector3.UP, world.terrain.surface_normal(player_at)))
	selection.visible = world.hover_outline.visible
	if selection.visible:
		var hovered: Vector2 = world.hover_outline.position / 32.0
		var data: Dictionary = world.terrain.sample(Vector2i(hovered))
		selection.position = Vector3(hovered.x + 0.5, world.terrain.display_height(hovered + Vector2(0.5, 0.5)) + 0.07, hovered.y + 0.5)
		for index in range(selection.get_child_count()):
			var bar: MeshInstance3D = selection.get_child(index)
			var at := hovered + Vector2(0.5 + bar.position.x, 0.5 + bar.position.z)
			bar.position.y = world.terrain.display_height(at) + 0.07 - selection.position.y
			bar.basis = Basis(Quaternion(Vector3.UP, world.terrain.surface_normal(at))) if data.ground != WorldTerrain.Ground.WATER else Basis.IDENTITY

func build_player_shadow() -> void:
	var disc := CylinderMesh.new()
	disc.top_radius = 0.34
	disc.bottom_radius = 0.34
	disc.height = 0.002
	disc.radial_segments = 16
	player_shadow.mesh = disc
	player_shadow.scale.z = 0.55
	player_shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(0.04, 0.06, 0.04, 0.28)
	player_shadow.material_override = material
	add_child(player_shadow)

func build_selection() -> void:
	solid_root.add_child(selection)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color("e1cd95")
	for side in range(4):
		var bar := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(1.0, 0.025, 0.025) if side < 2 else Vector3(0.025, 0.025, 1.0)
		bar.mesh = box
		bar.material_override = material
		bar.position = Vector3(0, 0, -0.49 if side == 0 else 0.49) if side < 2 else Vector3(-0.49 if side == 2 else 0.49, 0, 0)
		selection.add_child(bar)
	selection.hide()

## Absolute-world conservative bounds for published scenery; empty readiness fails closed.
func sol_clearance_bounds(home: Vector2i, radius: int) -> Dictionary:
	var region := AABB(Vector3(home.x - radius, -1000, home.y - radius), Vector3(radius * 2 + 1, 2000, radius * 2 + 1))
	for y in range(floori(region.position.z / 16), floori(region.end.z / 16) + 1):
		for x in range(floori(region.position.x / 16), floori(region.end.x / 16) + 1):
			if not solid_chunks.has(Vector2i(x, y)):
				return {"ready": false, "bounds": []}
	var result: Array[AABB] = []
	var groups: Array = solid_chunks.values()
	if place_root != null:
		groups.append(place_root)
	for group in groups:
		if group.pick_index_ready and not (group.transform * group.pick_bounds).intersects(region):
			continue
		for local: AABB in group.traversal_bounds:
			var absolute: AABB = group.transform * local
			if absolute.intersects(region):
				result.append(absolute)
	return {"ready": true, "bounds": result}

func publish_solid(coord: Vector2i, cells: Array[Dictionary]) -> void:
	remove_solid(coord)
	var chunk: Node3D
	if cached_detail_valid(coord):
		chunk = retained_solid[coord]
		retained_solid.erase(coord)
		chunk.show()
		detail_cache_reuses += 1
	elif stream_job != null and stream_job.coord == coord and stream_job.terrain == world.terrain and stream_job.cells == cells:
		chunk = stream_job.chunk
		stream_job.chunk = null
		stream_job = null
	else:
		chunk = SolidChunk.new()
		chunk.position = Vector3(coord.x * 16, 0, coord.y * 16)
		chunk.build(cells, world.terrain, coord, active_nature)
	configure_asset_distances(chunk)
	chunk.set_meta("source_terrain", world.terrain)
	chunk.set_meta("source_nature", active_nature)
	chunk.set_meta("source_cells", cells)
	if chunk.get_parent() == null:
		solid_root.add_child(chunk)
	solid_chunks[coord] = chunk
	streaming_ground.remove(coord)

func prepare_stream_chunk(coord: Vector2i, deadline_usec: int) -> Variant:
	if stream_job != null and (stream_job.coord != coord or stream_job.terrain != world.terrain):
		cancel_stream_chunk()
	if cached_detail_valid(coord):
		return retained_solid[coord].get_meta("source_cells")
	if stream_job == null:
		stream_job = preload("res://scripts/stream_chunk_job.gd").new(world.terrain, coord, active_nature, SolidChunk.new())
	var ready: bool = stream_job.advance(deadline_usec)
	for stage in stream_step_peaks:
		stream_step_peaks[stage] = maxf(stream_step_peaks[stage], stream_job.step_peaks[stage])
	max_stream_slice_ms = maxf(max_stream_slice_ms, stream_job.max_slice_ms)
	if not ready:
		return null
	world.max_generation_ms = maxf(world.max_generation_ms, stream_job.generation_ms)
	max_stream_geometry_ms = maxf(max_stream_geometry_ms, stream_job.geometry_ms)
	return stream_job.cells

func cancel_stream_chunk() -> void:
	if stream_job != null:
		stream_job.discard()
		stream_job = null

func _exit_tree() -> void:
	cancel_stream_chunk()

func remove_solid(coord: Vector2i) -> void:
	if solid_chunks.has(coord):
		var chunk: Node3D = solid_chunks[coord]
		chunk.hide()
		if retained_solid.has(coord):
			retired_solid.append(retained_solid[coord])
		retained_solid[coord] = chunk
		solid_chunks.erase(coord)
		trim_detail_cache()

func cached_detail_valid(coord: Vector2i) -> bool:
	if not retained_solid.has(coord):
		return false
	var chunk: Node3D = retained_solid[coord]
	if chunk.get_meta("source_terrain", null) == world.terrain and chunk.get_meta("source_nature", null) == active_nature:
		return true
	retired_solid.append(chunk)
	retained_solid.erase(coord)
	return false

func trim_detail_cache() -> void:
	while retained_solid.size() > active_view.stream_detail_cache_chunks:
		var oldest: Vector2i = retained_solid.keys()[0]
		retired_solid.append(retained_solid[oldest])
		retained_solid.erase(oldest)

func build_solid_places() -> void:
	# Rebuild/load is an explicit synchronous boundary, and must drop old worlds.
	for chunk in retained_solid.values():
		chunk.free()
	retained_solid.clear()
	for chunk in retired_solid:
		chunk.free()
	retired_solid.clear()
	streaming_ground.clear()
	if place_root != null:
		place_root.free()
	place_root = SolidChunk.new()
	solid_root.add_child(place_root)
	place_root.add_site(world.terrain.cabin_layout)
	place_root.add_site(world.terrain.scenery_site, shelter_roof_trim)
	# Preserve authored place anchors while giving each prop real volume.
	for prop: Node2D in world.place_props:
		var key: String = prop.get_meta("asset_key", "")
		if not key.is_empty():
			var first: int = place_root.pick_objects.size()
			build_prop(key, prop.position / 32.0)
			for index in range(first, place_root.pick_objects.size()):
				place_root.pick_objects[index].subject = key.get_file().replace("TX Props ", "")
	if active_nature.composition != null and world.terrain.world_seed == active_nature.composition.world_seed:
		var marker: Vector2i = active_nature.composition.orientation_marker
		if world.terrain.fits(marker) and world.terrain.route_axes(marker) == 0:
			var first: int = place_root.pick_objects.size()
			build_prop("TX Props Road Sign S", Vector2(marker) + Vector2(0.5, 0.5))
			for index in range(first, place_root.pick_objects.size()):
				place_root.pick_objects[index].subject = "Pond side path"
	place_root.finish()
	sync_ground()

func build_prop(key: String, at: Vector2) -> void:
	var wood := Color("72523b")
	var stone := Color("8f9996")
	if "Road Sign" in key:
		piece("post", at, Vector3(0, 0.65, 0), Vector3(0.12, 1.3, 0.12), wood)
		piece("prop", at, Vector3(0, 1.15, 0), Vector3(0.9, 0.22, 0.12), Color("b99a6b"))
	elif "Bench" in key:
		piece("prop", at, Vector3(0, 0.48, 0), Vector3(1.4, 0.18, 0.5), stone)
		for x in [-0.45, 0.45]:
			piece("prop", at, Vector3(x, 0.2, 0), Vector3(0.18, 0.4, 0.4), stone.darkened(0.15))
	elif "Crate" in key:
		piece("prop", at, Vector3(0, 0.35, 0), Vector3(0.7, 0.7, 0.7), wood)
		for y in [0.1, 0.6]:
			piece("prop", at, Vector3(0, y, 0), Vector3(0.74, 0.08, 0.74), Color("a88458"))
	elif "Lantern" in key:
		piece("prop", at, Vector3(0, 0.15, 0), Vector3(0.55, 0.3, 0.55), stone)
		piece("prop", at, Vector3(0, 0.5, 0), Vector3(0.3, 0.4, 0.3), Color("f0c578"))
		piece("roof", at, Vector3(0, 0.8, 0), Vector3(0.7, 0.25, 0.7), stone)
	elif "Altar" in key:
		piece("prop", at, Vector3(0, 0.25, 0), Vector3(1.2, 0.5, 0.9), stone)
		piece("prop", at, Vector3(0, 0.55, 0), Vector3(1.4, 0.15, 1.1), stone.lightened(0.15))
	else:
		var height := 0.8 if "Broken" in key else 1.8
		piece("prop", at, Vector3(0, height * 0.5, 0), Vector3(0.5, height, 0.5), stone)
		piece("prop", at, Vector3(0, height * 0.7, 0.26), Vector3(0.2, 0.3, 0.015), Color("b6d1c6"))

func piece(kind: String, anchor: Vector2, offset: Vector3, size: Vector3, color: Color) -> void:
	place_root.add_piece(kind, Vector3(anchor.x, world.terrain.surface_height(anchor), anchor.y) + offset, size, color)
