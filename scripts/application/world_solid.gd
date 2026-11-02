extends "res://scripts/application/world_plane.gd"
## Optional solid-3D view over the unchanged generated world and expedition simulation.

const SolidChunk = preload("res://scripts/presentation/solid_chunk.gd")
const PlayerVisibility = preload("res://scripts/presentation/player_visibility.gd")
const ViewStreaming = preload("res://scripts/presentation/view_streaming.gd")
const MeshPicking = preload("res://scripts/presentation/mesh_picking.gd")
const TerrainRay = preload("res://scripts/presentation/terrain_ray.gd")
@export_group("3D View")
## Perspective, dolly range, draw/stream/shadow distances, sky and fog. Restart/reapply to use edits.
@export var view_settings: View3DSettings = preload("res://resources/view_3d_settings.tres")
## Optional specialist plant art. Missing local models use the bundled CC0 fallback.
@export var vegetation_appearance: VegetationAppearance = preload("res://resources/vegetation_appearance.tres")
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
var stream_jobs_started := 0
var stream_jobs_cancelled := 0
var stream_jobs_completed := 0
var stream_work_frames := 0
var stream_operations_used := 0
var stream_upload_steps_used := 0
var retirement_steps_used := 0
var max_retirement_ms := 0.0
var chunk_workers := preload("res://scripts/presentation/chunk_buffer_worker.gd").new()
var chunk_assets := preload("res://scripts/presentation/chunk_asset_loader.gd").new()
var chunk_workers_failed := false
var scenery_fades: Dictionary = {}
var stream_job: RefCounted
var population := preload("res://scripts/presentation/chunk_population.gd").new()
var nearby_stream_chunks := {}
var max_stream_slice_ms := 0.0
var last_presentation_process_ms := 0.0
var max_stream_geometry_ms := 0.0
var stream_step_peaks := {"geography": 0.0, "generation": 0.0, "cell": 0.0, "upload": 0.0}
var streaming_ground := preload("res://scripts/presentation/streaming_ground.gd").new()
var selection := Node3D.new()
var player_shadow := MeshInstance3D.new()
var visibility_aid: Node3D
var pixel_effect: CanvasLayer
var camera_ground_y := 0.0
var camera_ground_at := Vector2.ZERO
var camera_ground_source: WorldTerrain
var vessel_swarms: Node3D
@export_group("Plant event animations")
@export_range(0.0,2.0,0.1) var plant_animation_strength := 1.0
@export_range(0.5,3.0,0.1) var plant_animation_duration := 1.6
var plant_animation = preload("res://scripts/presentation/plant_animation.gd").new()
## Maximum canonical plant cells inspected per frame for reserve appearance.
@export_range(1, 256, 1) var plant_reserve_cells_per_frame := 64
## Combined leaf-reserve and plant-reaction instance writes per frame.
@export_range(32, 4096, 32) var vegetation_writes_per_frame := 512
var vegetation_visual_queue = preload("res://scripts/presentation/vegetation_visual_queue.gd").new()
var plant_reserves = preload("res://scripts/presentation/plant_reserve_view.gd").new()
var ground_reserves = preload("res://scripts/presentation/ground_reserve_view.gd").new()
var authored_plant_revision := -1
var selection_geometry_inputs: Array = []

func _ready() -> void:
	active_view = view_settings if view_settings != null and view_settings.valid() else View3DSettings.new()
	if active_view != view_settings:
		push_warning("Invalid 3D view settings; using defaults.")
	# Establish renderer features before the base scene admits meshes and effects.
	configure_environment()
	var atmosphere := WorldEnvironment.new()
	atmosphere.environment = environment
	add_child(atmosphere)
	sun.directional_shadow_max_distance = minf(active_view.shadow_distance, active_view.render_distance)
	add_child(sun)
	preload("res://scripts/scenery/plant_library.gd").all()
	authored_plant_revision=preload("res://scripts/scenery/plant_library.gd").revision
	active_nature = nature_settings if nature_settings != null and nature_settings.valid() else NatureSettings.new()
	if active_nature != nature_settings:
		push_warning("Invalid nature settings; using the default visual palette.")
	# Shared art/picking caches prepare only assets actually requested by chunks.
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
	atmosphere_controller = preload("res://scripts/presentation/atmosphere_controller.gd").new()
	add_child(atmosphere_controller)
	atmosphere_controller.bind(self, atmosphere_settings)
	vessel_swarms = preload("res://scripts/presentation/vessel_swarms.gd").new()
	add_child(vessel_swarms)
	vessel_swarms.bind(world)
	sync_ground()
	view_hint = world.label("", 14, Color("e1c791"))
	view_hint.position = Vector2(350, 30)
	world.hud.add_child(view_hint)
	get_viewport().size_changed.connect(view_changed)
	view_changed()
	pixel_effect = preload("res://scripts/presentation/pixel_effect.gd").new()
	pixel_effect.native_msaa = active_view.multisample_antialiasing
	pixel_effect.level = active_view.pixel_effect_level
	add_child(pixel_effect)

func configure_environment() -> void:
	get_viewport().msaa_3d = active_view.multisample_antialiasing
	if pixel_effect != null:
		pixel_effect.native_msaa = active_view.multisample_antialiasing
		pixel_effect.set_level(active_view.pixel_effect_level)
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
	# Keep post-processing glow disabled.
	environment.glow_enabled = false
	environment.fog_enabled = true
	environment.fog_mode = Environment.FOG_MODE_DEPTH
	environment.fog_light_color = active_view.horizon_color
	environment.fog_depth_begin = active_view.fog_distance() * active_view.fog_start_fraction
	environment.fog_depth_end = active_view.fog_distance()
	environment.fog_density = 1.0
	environment.fog_sky_affect = 0.0
	if atmosphere_controller != null:
		atmosphere_controller.update()

func apply_atmosphere_settings() -> void:
	if atmosphere_controller != null:
		atmosphere_controller.configure(atmosphere_settings)

func reset_camera() -> void:
	camera_ground_source = null
	camera_focus = Vector3.ZERO
	target_size = active_view.starting_distance if active_view != null else 22.0
	view_elevation = clampf(camera_elevation, 10, 80) if is_finite(camera_elevation) else 35.0
	view_azimuth = wrapf(camera_azimuth, -180, 180) if is_finite(camera_azimuth) else 0.0
	apply_camera()

func apply_camera() -> void:
	update_camera_pose()
	view_changed()

func update_camera_pose(delta: float = 0.0) -> void:
	if active_view == null:
		return
	camera.projection = Camera3D.PROJECTION_PERSPECTIVE
	camera.fov = active_view.field_of_view
	camera.near = 0.1
	camera.far = active_view.render_distance+preload("res://scripts/scenery/plant_library.gd").maximum_height()
	var close_blend := 1.0-smoothstep(active_view.minimum_distance,active_view.starting_distance,target_size)
	# Keep the close-up neutral pose while mapping both sides of the orbit
	# control to their full tilt range. A fixed close tilt swallows vertical input.
	var close_tilt: float
	if view_elevation <= 35.0:
		close_tilt = lerpf(minf(10.0, active_view.close_elevation), active_view.close_elevation, inverse_lerp(10.0, 35.0, view_elevation))
	else:
		close_tilt = lerpf(active_view.close_elevation, 80.0, inverse_lerp(35.0, 80.0, view_elevation))
	var elevation := deg_to_rad(lerpf(view_elevation, close_tilt, close_blend))
	var azimuth := deg_to_rad(view_azimuth)
	var focus := camera_focus
	if world != null:
		var at: Vector2 = world.camera.position / 32.0 + Vector2(focus.x, focus.z)
		var target_height: float = world.terrain.surface_height(at)
		if camera_ground_source != world.terrain or at.distance_to(camera_ground_at) > 2.0 or active_view.height_smoothing_seconds <= 0.0:
			camera_ground_y = target_height
		elif delta > 0.0 and not world.paused:
			camera_ground_y = lerpf(camera_ground_y, target_height, 1.0 - exp(-delta / active_view.height_smoothing_seconds))
			camera_ground_y = clampf(camera_ground_y, target_height - 0.35, target_height + 0.35)
		camera_ground_source = world.terrain
		camera_ground_at = at
		focus.y = camera_ground_y + player_height*active_view.close_focus_height*close_blend
	camera.position = Vector3(sin(azimuth) * cos(elevation), sin(elevation), cos(azimuth) * cos(elevation)) * target_size + focus
	if world != null:
		var camera_at: Vector2 = world.camera.position / 32.0 + Vector2(camera.position.x, camera.position.z)
		camera.position.y = maxf(camera.position.y, world.terrain.surface_height(camera_at) + active_view.ground_clearance)
	camera.look_at(focus)
	camera.size = target_size # Diagnostic parity with the flat comparison scene.

func height_bound() -> float:
	var tuning: Dictionary = world.terrain.relief
	return (float(tuning.broad_amplitude) + float(tuning.detail_amplitude) + float(tuning.micro_amplitude)) * 2.0 + 5.0 * float(tuning.landform_strength) + float(tuning.mountain_height) + 1.0

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
	if not active_view.zoom_enabled: return
	target_size = clampf(target_size + amount, active_view.minimum_distance, active_view.maximum_distance)
	apply_camera()

func view_changed() -> void:
	view_revision += 1
	if world != null and world.is_node_ready():
		world.plan_chunks()

func apply_view_settings() -> void:
	population.invalidate()
	population.source = null
	cancel_stream_chunk()
	chunk_workers.invalidate()
	chunk_assets.invalidate()
	chunk_workers_failed = false
	active_view = view_settings if view_settings != null and view_settings.valid() else View3DSettings.new()
	configure_environment()
	sun.directional_shadow_max_distance = minf(active_view.shadow_distance, active_view.render_distance)
	target_size = clampf(target_size, active_view.minimum_distance, active_view.maximum_distance)
	apply_camera()
	for chunk in solid_chunks.values():
		configure_asset_distances(chunk)
	for chunk in retained_solid.values():
		configure_asset_distances(chunk)
	trim_detail_cache()
	view_changed()
	# Explicit settings reapplication is a synchronous rebuild boundary.
	while resident_detail_count() > active_view.max_resident_chunks and not retired_solid.is_empty(): retired_solid.pop_front().free()
	while resident_detail_count() > active_view.max_resident_chunks and not retained_solid.is_empty():
		var oldest: Vector2i = retained_solid.keys()[0]
		retained_solid[oldest].free()
		retained_solid.erase(oldest)

func stream_key() -> String:
	var lead := population_lookahead()
	return "%d:%d:%d:%d:%d:%d:%d" % [floori(world.camera.position.x / 128.0), floori(world.camera.position.y / 128.0), WorldTerrain.floor_div(world.cell.x, 16), WorldTerrain.floor_div(world.cell.y, 16), view_revision,roundi(lead.x/4.0),roundi(lead.y/4.0)]

func stream_plan() -> Array[Vector2i]:
	var library:=preload("res://scripts/scenery/plant_library.gd")
	var desired := ViewStreaming.plan(camera, world.camera.position / 32.0, world.cell, active_view, maxf(active_nature.canopy_height_bound(),library.maximum_height()) + 3 + height_bound(), -height_bound(), library.maximum_width()*0.5,population_lookahead())
	nearby_stream_chunks.clear()
	for index in range(ceili(desired.size()*active_view.nearby_chunk_fraction)):
		nearby_stream_chunks[desired[index]] = true
	return desired

func chunk_detail_deadline(wanted: Array[Vector2i], deadline: int) -> int:
	if not active_view.spiral_chunk_loading: return deadline
	var target: Variant = spiral_population_target(wanted)
	if target == null or nearby_stream_chunks.has(target): return deadline
	return mini(deadline,Time.get_ticks_usec()+int(active_view.distant_chunk_work_ms*1000.0))

func chunk_visible(coord: Vector2i) -> bool:
	var library:=preload("res://scripts/scenery/plant_library.gd")
	return ViewStreaming.visible(camera, Vector2(coord * 16) - world.camera.position / 32.0, maxf(active_nature.canopy_height_bound(),library.maximum_height()) + 3 + height_bound(), library.maximum_width()*0.5, -height_bound())

func stream_capacity() -> int:
	return ViewStreaming.live_capacity(active_view)

func keep_stream_chunk(coord: Vector2i) -> bool:
	var local: Vector2i = world.terrain.chunk_of(world.cell)
	return ViewStreaming.within_radius(coord, local, active_view.active_chunk_radius + active_view.chunk_unload_buffer)

func resident_detail_count() -> int:
	return solid_chunks.size() + retained_solid.size() + retired_solid.size() + int(stream_job != null and stream_job.chunk != null) + population.reservations()

func stream_diagnostics() -> String:
	var stage := "idle"
	if stream_job != null:
		stage = "roads %d/%d; cells %d/256; geometry %d/256" % [stream_job.geography_prepared, stream_job.geography_count, stream_job.generated, stream_job.built]
	return "Detail resident %d/%d · retired %d · jobs started/completed/cancelled %d/%d/%d\nDetail operations %d/%d · uploads %d/%d · cleanup steps %d/%d\nCoverage runtime max %.2f ms · cleanup max %.2f ms\n%s" % [resident_detail_count(), active_view.max_resident_chunks, retired_solid.size(), stream_jobs_started, stream_jobs_completed, stream_jobs_cancelled, stream_operations_used, active_view.chunk_operations_per_frame, stream_upload_steps_used, active_view.chunk_upload_steps_per_frame, retirement_steps_used, active_view.retirement_steps_per_frame, streaming_ground.max_runtime_ms, max_retirement_ms, stage]

func configure_asset_distances(chunk: Node3D) -> void:
	if chunk.has_meta("scenery_distance_tier"): chunk.remove_meta("scenery_distance_tier")
	if chunk.get_script() == SolidChunk:
		chunk.reserve_transition_seconds = active_nature.reserve_transition_seconds
	for mesh in chunk.get_children():
		if mesh is GeometryInstance3D:
			if mesh.name.begins_with("nature_"): mesh.lod_bias = active_view.scenery_lod_bias
			# Legacy study blades retain their label fallback. Live plant/cover
			# batches carry the category supplied by their admitted render record.
			var group: String = mesh.get_meta("visibility_group", "grass" if mesh.name.begins_with("nature_detail_meadow") else "detail" if mesh.name.begins_with("nature_detail_") else "tree" if mesh.name.begins_with("nature_tree_") else "")
			mesh.visibility_range_end = active_view.visibility_distance(group)
			mesh.visibility_range_end_margin = 8.0 if group == "grass" else 12.0
			mesh.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF if mesh.visibility_range_end > 0 else GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED
			if group == "grass" and mesh.has_meta("visibility_group"):
				var end := active_view.visibility_distance("grass")
				if mesh is MultiMeshInstance3D:
					var source: Material = mesh.multimesh.mesh.surface_get_material(0)
					if source is ShaderMaterial:
						var fade: ShaderMaterial = preload("res://scripts/scenery/plant_library.gd").grass_material(source)
						fade.set_shader_parameter("grass_fade_range",Vector2(maxf(0.0,end-active_view.grass_fade_cells),end))
						mesh.material_override = fade
				# Coarse CPU culling is deliberately beyond every point of the
				# 16-cell chunk. The shader owns the visible per-clump transition.
				mesh.visibility_range_end = end + 16.0
				mesh.visibility_range_end_margin = 0.0
				mesh.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED
			if mesh is MeshInstance3D and mesh.name == "ground":
				var material: Material = mesh.mesh.surface_get_material(0)
				if material is ShaderMaterial:
					material.set_shader_parameter("grass_cover_transition",Vector2(active_view.grass_distance-active_view.grass_fade_cells,active_view.grass_distance))
			if mesh is MultiMeshInstance3D:
				if mesh.material_override is ShaderMaterial:
					active_nature.apply_plant_material(mesh.material_override)
				else:
					for surface in range(mesh.multimesh.mesh.get_surface_count()):
						var material: Material = mesh.multimesh.mesh.surface_get_material(surface)
						if material is ShaderMaterial: active_nature.apply_plant_material(material)
	streaming_ground.material.set_shader_parameter("grass_cover_transition",Vector2(active_view.grass_distance-active_view.grass_fade_cells,active_view.grass_distance))

func _process(delta: float) -> void:
	var process_started := Time.get_ticks_usec()
	vegetation_visual_queue.begin_frame(solid_chunks)
	for chunk in solid_chunks.values(): chunk.vegetation_visual_queue = vegetation_visual_queue
	plant_animation.update(world.persistent_state,solid_chunks,world.cell,plant_animation_strength,plant_animation_duration)
	plant_reserves.update(world.persistent_state, solid_chunks, plant_reserve_cells_per_frame, Vector3(world.camera.position.x / 32.0 + camera.position.x, camera.position.y, world.camera.position.y / 32.0 + camera.position.z), active_view.detail_distance)
	ground_reserves.update(world.persistent_state,world.cell,active_nature)
	vegetation_visual_queue.drain(vegetation_writes_per_frame)
	var library := preload("res://scripts/scenery/plant_library.gd")
	if authored_plant_revision<0: authored_plant_revision=library.revision
	elif authored_plant_revision!=library.revision:
		authored_plant_revision=library.revision
		refresh_authored_plant_scenery()
	update_camera_pose(delta)
	trim_detail_cache()
	update_scenery_tiers()
	for chunk: Node3D in scenery_fades.keys():
		if not is_instance_valid(chunk):
			scenery_fades.erase(chunk)
			continue
		var weight: float = minf(1.0, float(scenery_fades[chunk]) + delta / 0.6)
		for mesh in chunk.get_children():
			if mesh is GeometryInstance3D and mesh.name.begins_with("nature_"):
				mesh.transparency = 1.0 - smoothstep(0.0, 1.0, weight)
		if weight >= 1.0:
			scenery_fades.erase(chunk)
		else:
			scenery_fades[chunk] = weight
	sync_ground()
	update_horizon(delta)
	if atmosphere_controller != null:
		atmosphere_controller.update()
	last_presentation_process_ms = (Time.get_ticks_usec()-process_started)/1000.0

func refresh_authored_plant_scenery() -> void:
	population.invalidate()
	population.source = null
	# Derived render data only. Expedition, terrain, clock and flora reserves survive.
	cancel_stream_chunk()
	for coord in world.chunks.keys(): world.remove_chunk(coord)
	for chunk: Node3D in retained_solid.values(): retired_solid.append(chunk)
	retained_solid.clear()
	world.last_chunk=Vector2i(999999,999999)
	world.last_stream_key=""
	world.plan_chunks()

func update_horizon(_delta: float) -> void:
	# Camera motion must not pull fog over the trainer. Temporary ground covers
	# visible queued chunks while detailed terrain/scenery keeps its frame budget.
	environment.fog_depth_end = active_view.fog_distance()
	environment.fog_depth_begin = environment.fog_depth_end * active_view.fog_start_fraction

func stream_ground_has_gaps() -> bool:
	update_camera_pose()
	var planes := camera.get_frustum()
	var origin: Vector2 = world.camera.position / 32.0
	var height := height_bound()
	for coord: Vector2i in world.pending:
		if streaming_ground.chunks.has(coord) or streaming_ground.retained.has(coord):
			continue
		if ViewStreaming.visible_with_planes(planes, Vector2(coord * 16) - origin, height, 0.0, -height):
			return true
	return false

func prepare_stream_ground(deadline_usec: int) -> void:
	# The simulation moves first. Use the new pose for coverage, sharing the
	# detailed terrain deadline rather than spending a second unbounded budget.
	update_camera_pose()
	streaming_ground.sync(world.terrain, world.pending, camera, world.camera.position / 32.0, height_bound(), active_view.stream_ground_step, active_view.stream_ground_cache_chunks, deadline_usec, active_nature, active_view.ground_operations_per_frame, active_view.ground_uploads_per_frame)

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
	if vessel_swarms != null:
		var ecological: Dictionary = vessel_swarms.pick(origin, direction, distance)
		if not ecological.is_empty():
			selected = ecological.cell
			pointer_subject = ecological.subject
	return selected

func sync_ground() -> void:
	update_camera_pose()
	if view_hint != null:
		var arrows := ["↑", "↗", "→", "↘", "↓", "↙", "←", "↖"]
		var compass := "N %s" % arrows[posmod(roundi(view_azimuth / 45.0), 8)]
		if view_hint.text != compass: view_hint.text = compass
	solid_root.position = Vector3(-world.camera.position.x / 32.0, 0, -world.camera.position.y / 32.0)
	var origin: Vector2 = world.camera.position / 32.0
	for kind in ["water", "bank", "shore_rim"]:
		if SolidChunk.meshes.has(kind):
			sync_material_origin(SolidChunk.meshes[kind].material, origin)
	# Shared terrain materials use absolute coordinates despite the camera-relative root.
	for kind in SolidChunk.meshes:
		if str(kind).begins_with("grass_") or str(kind).begins_with("trail_"):
			sync_material_origin(SolidChunk.meshes[kind].surface_get_material(0), origin)
	var player_at: Vector2 = Vector2(player_visual.position.x, player_visual.position.z) + world.camera.position / 32.0
	player_shadow.position = Vector3(player_visual.position.x, world.terrain.surface_height(player_at) + 0.045, player_visual.position.z)
	player_shadow.basis = Basis(Quaternion(Vector3.UP, world.terrain.surface_normal(player_at))).scaled(Vector3(1, 1, 0.55) * player_visual.model_height / 1.7)
	selection.visible = world.hover_outline.visible
	if selection.visible:
		var hovered: Vector2 = world.hover_outline.position / 32.0
		# Selection geometry is terrain-derived; camera rebasing moves its parent.
		var inputs: Array = [world.terrain.get_instance_id(), hovered, selection.get_instance_id(), selection.get_child_count()]
		if inputs == selection_geometry_inputs: return
		selection_geometry_inputs = inputs
		var data: Dictionary = world.terrain.sample(Vector2i(hovered))
		selection.position = Vector3(hovered.x + 0.5, world.terrain.display_height(hovered + Vector2(0.5, 0.5)) + 0.07, hovered.y + 0.5)
		for index in range(selection.get_child_count()):
			var bar: MeshInstance3D = selection.get_child(index)
			var at := hovered + Vector2(0.5 + bar.position.x, 0.5 + bar.position.z)
			bar.position.y = world.terrain.display_height(at) + 0.07 - selection.position.y
			bar.basis = Basis(Quaternion(Vector3.UP, world.terrain.surface_normal(at))) if data.ground != WorldTerrain.Ground.WATER else Basis.IDENTITY

func sync_material_origin(material: ShaderMaterial, origin: Vector2) -> void:
	# Read the actual value: plant weather and other views share some materials.
	# A private last-value cache could miss another consumer's origin write.
	if material.get_shader_parameter("world_origin") != origin:
		material.set_shader_parameter("world_origin", origin)

func build_player_shadow() -> void:
	var disc := CylinderMesh.new()
	disc.top_radius = 0.34
	disc.bottom_radius = 0.34
	disc.height = 0.002
	disc.radial_segments = 16
	player_shadow.mesh = disc
	player_shadow.scale = Vector3.ONE * player_visual.model_height / 1.7
	player_shadow.scale.z *= 0.55
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
		if stream_job.has_meta("population_requested_usec"):
			population.published(coord,stream_job.get_meta("population_requested_usec"))
		stream_job.chunk = null
		stream_job = null
	else:
		chunk = SolidChunk.new()
		chunk.vegetation_appearance = vegetation_appearance
		chunk.position = Vector3(coord.x * 16, 0, coord.y * 16)
		chunk.build(cells, world.terrain, coord, active_nature)
	# Keep imported cutouts in their normal depth-writing pass. Instance alpha
	# forces whole plant batches into transparency and can hide/sort them wrongly.
	for mesh in chunk.get_children():
		if mesh is GeometryInstance3D and mesh.name.begins_with("nature_"):
			mesh.transparency = 0.0
	configure_asset_distances(chunk)
	chunk.set_meta("source_terrain", world.terrain)
	chunk.set_meta("source_nature", active_nature)
	chunk.set_meta("source_vegetation", vegetation_appearance)
	chunk.set_meta("source_cells", cells)
	chunk.set_meta("source_content_revision", preload("res://scripts/scenery/plant_library.gd").revision)
	if chunk.get_parent() == null:
		solid_root.add_child(chunk)
	solid_chunks[coord] = chunk
	streaming_ground.remove(coord)

func prepare_stream_chunk(coord: Vector2i, deadline_usec: int) -> Variant:
	if world.paused: return null
	if background_chunks_enabled(): return prepare_population_chunk(coord,deadline_usec)
	if stream_job != null and (stream_job.coord != coord or stream_job.terrain != world.terrain or stream_job.source_content_revision != preload("res://scripts/scenery/plant_library.gd").revision):
		cancel_stream_chunk()
	if cached_detail_valid(coord):
		return retained_solid[coord].get_meta("source_cells")
	if Time.get_ticks_usec() >= deadline_usec or stream_operations_used >= active_view.chunk_operations_per_frame or stream_upload_steps_used >= active_view.chunk_upload_steps_per_frame:
		return null
	if stream_job == null:
		# Backpressure: release retired visuals incrementally before admitting more.
		if resident_detail_count() >= active_view.max_resident_chunks: return null
		stream_jobs_started += 1
		var chunk := SolidChunk.new()
		chunk.vegetation_appearance = vegetation_appearance
		if active_view.threaded_chunk_buffers and not chunk_workers_failed:
			chunk.buffer_worker = chunk_workers
			chunk.buffer_min_rows = active_view.chunk_worker_min_instances
			chunk.buffer_stamp = [world.terrain.get_instance_id(), coord, preload("res://scripts/scenery/plant_library.gd").revision, stream_jobs_started]
		stream_job = preload("res://scripts/presentation/stream_chunk_job.gd").new(world.terrain, coord, active_nature, chunk)
		stream_job.source_content_revision = preload("res://scripts/scenery/plant_library.gd").revision
		stream_job.set_meta("population_requested_usec",population.announced.get(coord,Time.get_ticks_usec()))
		if active_view.threaded_chunk_assets: stream_job.asset_loader = chunk_assets
		trim_detail_cache()
	stream_work_frames += 1
	var ready: bool = stream_job.advance(deadline_usec, active_view.chunk_operations_per_frame - stream_operations_used, active_view.chunk_upload_steps_per_frame - stream_upload_steps_used)
	stream_operations_used += stream_job.last_operations
	stream_upload_steps_used += stream_job.last_upload_steps
	if not stream_job.chunk.worker_failure.is_empty():
		chunk_workers_failed = true
		push_warning("Chunk buffer worker rejected a result; rebuilding through the same serial packer.")
		cancel_stream_chunk()
		return null
	for stage in stream_step_peaks:
		stream_step_peaks[stage] = maxf(stream_step_peaks[stage], stream_job.step_peaks[stage])
	max_stream_slice_ms = maxf(max_stream_slice_ms, stream_job.max_slice_ms)
	if not ready:
		return null
	stream_jobs_completed += 1
	world.max_generation_ms = maxf(world.max_generation_ms, stream_job.generation_ms)
	max_stream_geometry_ms = maxf(max_stream_geometry_ms, stream_job.geometry_ms)
	return stream_job.cells

func cancel_stream_chunk() -> void:
	if stream_job != null:
		chunk_assets.drop_queued()
		stream_jobs_cancelled += 1
		if stream_job.chunk != null:
			stream_job.chunk.cancel_buffer_work()
			retired_solid.append(stream_job.chunk)
			stream_job.chunk = null
		stream_job.discard()
		stream_job = null

func _exit_tree() -> void:
	population.shutdown()
	cancel_stream_chunk()
	chunk_workers.shutdown()
	chunk_assets.shutdown()
	for chunk in retired_solid:
		if chunk.get_parent() == null: chunk.free()
	retired_solid.clear()

func remove_solid(coord: Vector2i) -> void:
	if solid_chunks.has(coord):
		var chunk: Node3D = solid_chunks[coord]
		if scenery_fades.has(chunk):
			scenery_fades.erase(chunk)
			for mesh in chunk.get_children():
				if mesh is GeometryInstance3D:
					mesh.transparency = 0.0
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
	if chunk.get_meta("source_terrain", null) == world.terrain and chunk.get_meta("source_nature", null) == active_nature and chunk.get_meta("source_vegetation", null) == vegetation_appearance and chunk.get_meta("source_content_revision", -1) == preload("res://scripts/scenery/plant_library.gd").revision:
		return true
	retired_solid.append(chunk)
	retained_solid.erase(coord)
	return false

func trim_detail_cache() -> void:
	while retained_solid.size() > active_view.stream_detail_cache_chunks:
		var oldest: Vector2i = retained_solid.keys()[0]
		retired_solid.append(retained_solid[oldest])
		retained_solid.erase(oldest)
	# Pending retirement counts against admission; never force-free a burst here.

func begin_stream_frame() -> void:
	population.poll()
	chunk_workers.poll()
	chunk_assets.advance()
	stream_operations_used = 0
	stream_upload_steps_used = 0
	retire_detail(Time.get_ticks_usec() + int(active_view.retirement_work_ms * 1000.0))

func retire_detail(deadline_usec: int) -> void:
	var began := Time.get_ticks_usec()
	retirement_steps_used = 0
	while not retired_solid.is_empty() and retirement_steps_used < active_view.retirement_steps_per_frame and Time.get_ticks_usec() < deadline_usec:
		var chunk: Node3D = retired_solid[0]
		if chunk.has_method("retire_step"):
			if chunk.retire_step(): retired_solid.pop_front().free()
		elif chunk.get_child_count() > 0:
			chunk.get_child(chunk.get_child_count() - 1).free()
		else:
			retired_solid.pop_front().free()
		retirement_steps_used += 1
	max_retirement_ms = maxf(max_retirement_ms, (Time.get_ticks_usec() - began) / 1000.0)

func build_solid_places() -> void:
	population.invalidate()
	population.source = null
	chunk_workers.invalidate()
	chunk_assets.invalidate()
	camera_ground_source = null
	scenery_fades.clear()
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
	# Coarse generated terrain covers the first view; expensive scenery arrives
	# through the normal resumable jobs instead of blocking every visible chunk.
	streaming_ground.sync(world.terrain,world.pending,camera,world.camera.position/32.0,height_bound(),active_view.stream_ground_step,active_view.stream_ground_cache_chunks,0,active_nature)
	if background_chunks_enabled():
		population.prime(world.terrain,active_nature,preload("res://scripts/scenery/plant_library.gd").revision,active_view.chunk_preparation_jobs)

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

func background_chunks_enabled() -> bool:
	var library := preload("res://scripts/scenery/plant_library.gd")
	return active_view.threaded_chunk_preparation and not population.failed and world.terrain.get_script() == WorldTerrain and library.use_baked_palette and library.palette_current

func pump_chunk_population(wanted: Array[Vector2i], deadline: int) -> void:
	population.sync_inputs(world.terrain,active_nature,preload("res://scripts/scenery/plant_library.gd").revision)
	if world.paused: return
	var requests: Array[Vector2i] = []
	for coord in wanted:
		if stream_job != null and stream_job.coord == coord: continue
		if not cached_detail_valid(coord): requests.append(coord)
	population.note_requests(requests)
	if not background_chunks_enabled(): return
	if active_view.spiral_chunk_loading:
		# A taken worker slot becomes idle before its chunk finishes GPU uploads.
		# Keep that publication in flight alone instead of admitting the next task.
		var target: Variant = spiral_population_target(wanted)
		requests.clear()
		if stream_job == null and target != null and not cached_detail_valid(target): requests.append(target)
	population.advance(requests,deadline,active_view.max_resident_chunks-resident_detail_count()+population.reservations(),1 if active_view.spiral_chunk_loading else active_view.chunk_preparation_jobs)

func spiral_population_target(wanted: Array[Vector2i]) -> Variant:
	if stream_job != null and wanted.has(stream_job.coord): return stream_job.coord
	# Finish an admitted chunk even when movement changes the spiral center.
	for slot in population.slots:
		if slot.task != null and wanted.has(slot.task.coord): return slot.task.coord
	return wanted[0] if not wanted.is_empty() else null

func next_population_coord(wanted: Array[Vector2i]) -> Variant:
	if world.paused: return null
	if active_view.spiral_chunk_loading:
		var target: Variant = spiral_population_target(wanted)
		if target == null: return null
		if stream_job != null or cached_detail_valid(target): return target
		var ordered: Array[Vector2i] = [target]
		return population.ready_coord(ordered)
	if stream_job != null and wanted.has(stream_job.coord): return stream_job.coord
	for coord in wanted:
		if cached_detail_valid(coord): return coord
	return population.ready_coord(wanted)

func prepare_population_chunk(coord: Vector2i, deadline: int) -> Variant:
	if world.paused: return null
	if cached_detail_valid(coord): return retained_solid[coord].get_meta("source_cells")
	if Time.get_ticks_usec() >= deadline: return null
	if stream_job != null and (stream_job.coord != coord or stream_job.terrain != world.terrain or stream_job.source_content_revision != preload("res://scripts/scenery/plant_library.gd").revision): cancel_stream_chunk()
	if stream_job == null:
		var task: RefCounted = population.take(coord)
		if task == null: return null
		var chunk := SolidChunk.new()
		chunk.vegetation_appearance = vegetation_appearance
		chunk.position = Vector3(coord.x*16,0,coord.y*16)
		chunk.adopt_prepared(task,world.terrain,coord,active_nature)
		stream_job = preload("res://scripts/presentation/stream_chunk_job.gd").new(world.terrain,coord,active_nature,chunk)
		stream_job.cells = task.cells
		stream_job.geography_prepared = stream_job.geography_count
		stream_job.generated = 256
		stream_job.built = 256
		stream_job.geometry_ms = task.compute_ms
		stream_job.source_content_revision = preload("res://scripts/scenery/plant_library.gd").revision
		stream_job.set_meta("population_requested_usec",task.requested_usec)
		stream_jobs_started += 1
	stream_work_frames += 1
	var ready: bool = stream_job.advance(deadline,maxi(0,active_view.chunk_operations_per_frame-stream_operations_used),maxi(0,active_view.chunk_upload_steps_per_frame-stream_upload_steps_used))
	stream_operations_used += stream_job.last_operations
	stream_upload_steps_used += stream_job.last_upload_steps
	max_stream_slice_ms = maxf(max_stream_slice_ms,stream_job.max_slice_ms)
	if not ready: return null
	stream_jobs_completed += 1
	return stream_job.cells

func population_lookahead() -> Vector2:
	if (not active_view.threaded_chunk_preparation and not active_view.spiral_chunk_loading) or not world.moving: return Vector2.ZERO
	var speed := 1.0 / maxf(0.01,float(world.expedition_parameters().move_seconds))
	if Input.is_action_pressed("run") or (gamepad != null and gamepad.sprinting()): speed *= float(world.expedition_parameters().run_multiplier)
	var latency: float = population.cached_p95_ms / 1000.0
	var seconds := clampf(maxf(active_view.chunk_lookahead_seconds,latency+0.25),0.25,4.0)
	return world.explorer.facing * minf(active_view.chunk_lookahead_cells,speed*seconds)

func update_scenery_tiers() -> void:
	# Native mesh LOD retains authored silhouettes; distant groups cast no shadows.
	var vertical_bound := height_bound()
	for chunk in solid_chunks.values():
		var nearest := AABB(chunk.global_position + Vector3(0, -vertical_bound, 0), Vector3(16, vertical_bound * 2.0, 16))
		var point: Vector3 = camera.global_position.clamp(nearest.position, nearest.end)
		var distance := camera.global_position.distance_to(point)
		var tier := 0 if distance < 24.0 else (1 if distance < 48.0 else 2)
		var inputs := [tier, active_view.scenery_lod_bias]
		if chunk.get_meta("scenery_distance_tier", []) == inputs: continue
		chunk.set_meta("scenery_distance_tier", inputs)
		for mesh in chunk.get_children():
			if not mesh is GeometryInstance3D or not mesh.name.begins_with("nature_"): continue
			if not mesh.has_meta("near_shadow_mode"): mesh.set_meta("near_shadow_mode", mesh.cast_shadow)
			mesh.lod_bias = active_view.scenery_lod_bias * (1.0 if tier == 0 else 0.5 if tier == 1 else 0.25)
			mesh.cast_shadow = mesh.get_meta("near_shadow_mode") if tier == 0 else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
