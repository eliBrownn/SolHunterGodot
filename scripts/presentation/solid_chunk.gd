extends Node3D
## Batched solid geometry from prepared terrain data. No new generation or collision rules.

var vegetation_visual_queue: RefCounted
static var meshes: Dictionary = {}
static var surface_uvs: Dictionary = {}
var cell_work: Dictionary:
	get: return preparation.cell_work
	set(value): preparation.cell_work = value
var preparation := preload("res://scripts/presentation/chunk_build_data.gd").new()
const NatureArt = preload("res://scripts/scenery/nature_art.gd")
const WaterAppearance = preload("res://scripts/presentation/water_appearance_settings.gd")
const BufferTask = preload("res://scripts/presentation/chunk_buffer_task.gd")
var batches: Dictionary:
	get: return preparation.batches
	set(value): preparation.batches = value
var build_biome_patches: Dictionary:
	get: return preparation.build_biome_patches
	set(value): preparation.build_biome_patches = value
var cell_setup_count: int:
	get: return preparation.cell_setup_count
	set(value): preparation.cell_setup_count = value
var terrain_surfaces: Dictionary:
	get: return preparation.terrain_surfaces
	set(value): preparation.terrain_surfaces = value
var pick_objects: Array[Dictionary]:
	get: return preparation.pick_objects
	set(value): preparation.pick_objects = value
var pick_bounds := AABB()
var pick_index_ready := false
var traversal_bounds: Array[AABB] = []
var tile_count: int:
	get: return preparation.tile_count
	set(value): preparation.tile_count = value
var obstacle_count: int:
	get: return preparation.obstacle_count
	set(value): preparation.obstacle_count = value
var shoreline_edges: int:
	get: return preparation.shoreline_edges
	set(value): preparation.shoreline_edges = value
var cell_origin: Vector2i:
	get: return preparation.cell_origin
	set(value): preparation.cell_origin = value
var vegetation_appearance: VegetationAppearance = preload("res://resources/vegetation_appearance.tres")
## Absolute cosmetic records, compared by asset/cell rather than runtime IDs.
var cosmetic_records: Array[Dictionary]:
	get: return preparation.cosmetic_records
	set(value): preparation.cosmetic_records = value
var living_source_revision: int:
	get: return preparation.living_source_revision
var living_sources: Dictionary:
	get: return preparation.living_sources
	set(value):
		preparation.living_sources = value
		preparation.living_source_revision += 1
var plant_instances: Dictionary = {}
var animated_plants: Dictionary = {}
var reserve_transition_seconds := 1.2
var living_regions: Dictionary:
	get: return preparation.living_regions
	set(value):
		preparation.living_regions = value
		preparation.living_source_revision += 1
var upload_instances: MultiMesh
var upload_cursor := 0
var upload_buffer := PackedFloat32Array()
var upload_identity := ""
var picking_cursor := 0
var last_finish_uploaded := false
var terrain_vertex_cache: Dictionary:
	get: return preparation.terrain_vertex_cache
	set(value): preparation.terrain_vertex_cache = value
var buffer_worker: RefCounted
var buffer_stamp: Array = []
var buffer_min_rows := 512
var buffer_poses: Array[Transform3D] = []
var buffer_colors: Array[Color] = []
var buffer_handle := -1
var waiting_buffer := false
var worker_failure := ""

func cancel_buffer_work() -> void:
	if buffer_worker != null and buffer_handle >= 0: buffer_worker.cancel(buffer_handle)
	buffer_handle = -1
	buffer_poses = []
	buffer_colors = []

## Dispose only detached/hidden visuals. Release owned records in small groups
## before freeing the root; never edit shared terrain/source-cell arrays.
func retire_step() -> bool:
	preparation.cell_work.clear()
	cancel_buffer_work()
	for records in [pick_objects, cosmetic_records, traversal_bounds]:
		if not records.is_empty():
			for index in range(mini(32, records.size())): records.pop_back()
			return false
	if not batches.is_empty():
		var key: Variant = batches.keys()[0]
		var entries: Array = batches[key]
		for index in range(mini(32, entries.size())): entries.pop_back()
		if entries.is_empty(): batches.erase(key)
		return false
	for records in [plant_instances, animated_plants, living_sources, living_regions, terrain_surfaces, build_biome_patches, terrain_vertex_cache]:
		if not records.is_empty():
			var keys: Array = records.keys()
			for index in range(mini(32, keys.size())): records.erase(keys[index])
			return false
	if get_child_count() > 0:
		get_child(get_child_count() - 1).free()
		return false
	return true

static func water_tuning() -> Resource:
	var selected: Resource = load("res://resources/water_appearance.tres")
	return selected if selected != null and selected.valid() else WaterAppearance.new()

static func mesh_for(kind: String) -> Mesh:
	if meshes.has(kind):
		return meshes[kind]
	if kind.begins_with("grass_") or kind.begins_with("trail_") or kind.begins_with("sprite_") or kind.begins_with("asset:"):
		var pixel_mesh := pixel_mesh_for(kind)
		meshes[kind] = pixel_mesh
		return pixel_mesh
	var mesh: Mesh
	match kind:
		"post":
			var cylinder := CylinderMesh.new()
			cylinder.top_radius = 0.5
			cylinder.bottom_radius = 0.5
			cylinder.height = 1.0
			cylinder.radial_segments = 8
			mesh = cylinder
		"roof":
			var prism := PrismMesh.new()
			prism.size = Vector3.ONE
			mesh = prism
		_:
			var box := BoxMesh.new()
			box.size = Vector3.ONE
			mesh = box
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.roughness = 0.92
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	if kind == "wall" or kind == "roof":
		var tile: AtlasTexture = PackArt.atlas("TX Tileset Wall/TX Tileset Wall_11")
		material.albedo_texture = ImageTexture.create_from_image(tile.atlas.get_image().get_region(Rect2i(tile.region)))
		material.uv1_scale = Vector3(3, 2, 1)
	if kind == "water":
		var water := ShaderMaterial.new()
		water.shader = preload("res://shaders/pixel_water.gdshader")
		water_tuning().apply_water(water)
		mesh.material = water
	elif kind == "bank" or kind == "shore_rim":
		var bank := ShaderMaterial.new()
		bank.shader = preload("res://shaders/pixel_bank.gdshader")
		mesh.material = bank
	else:
		mesh.material = material
	meshes[kind] = mesh
	return mesh

static func pixel_mesh_for(kind: String) -> ArrayMesh:
	var standing := kind.begins_with("sprite_") or kind.begins_with("asset:")
	var key: String
	if kind.begins_with("asset:"):
		key = kind.trim_prefix("asset:")
	elif kind.begins_with("grass_"):
		key = "TX Tileset Grass/TX Tileset Grass " + kind.trim_prefix("grass_")
	elif kind.begins_with("trail_"):
		key = "TX Tileset Grass/TX Tileset Grass Pavement " + kind.trim_prefix("trail_")
	else:
		key = {"sprite_tree_lower": "TX Plant/TX Tree T1 Lower", "sprite_tree_upper": "TX Plant/TX Tree T1 Upper", "sprite_rock": "TX Props/TX Props Stone T7"}[kind]
	var atlas: AtlasTexture = PackArt.atlas(key)
	var entry: Dictionary = PackArt.entry(key)
	var vertices: PackedVector3Array
	if standing:
		var left := -float(entry.pivot[0]) / 32.0
		var right := (float(entry.rect[2]) - float(entry.pivot[0])) / 32.0
		var top := float(entry.pivot[1]) / 32.0
		var bottom := (float(entry.pivot[1]) - float(entry.rect[3])) / 32.0
		vertices = PackedVector3Array([Vector3(left, top, 0), Vector3(right, top, 0), Vector3(right, bottom, 0), Vector3(left, bottom, 0)])
	else:
		vertices = PackedVector3Array([Vector3(-0.5, 0, -0.5), Vector3(0.5, 0, -0.5), Vector3(0.5, 0, 0.5), Vector3(-0.5, 0, 0.5)])
	# Inset half a texel to prevent neighboring atlas sprites bleeding into the quad.
	var texture_size := Vector2(atlas.atlas.get_width(), atlas.atlas.get_height())
	var first := (atlas.region.position + Vector2(0.5, 0.5)) / texture_size
	var last := (atlas.region.end - Vector2(0.5, 0.5)) / texture_size
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	var normal := Vector3.BACK if standing else Vector3.UP
	arrays[Mesh.ARRAY_NORMAL] = PackedVector3Array([normal, normal, normal, normal])
	arrays[Mesh.ARRAY_TEX_UV] = PackedVector2Array([first, Vector2(last.x, first.y), last, Vector2(first.x, last.y)])
	# Godot uses clockwise front faces. Reversed terrain faces flip lit normals down.
	arrays[Mesh.ARRAY_INDEX] = PackedInt32Array([0, 1, 2, 0, 2, 3])
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var material := StandardMaterial3D.new()
	material.albedo_texture = atlas.atlas
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	material.vertex_color_use_as_albedo = true
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	material.alpha_scissor_threshold = 0.35
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.roughness = 1.0
	material.metallic_specular = 0.0
	# Terrain receives the same daylight, moonlight and moving shadows as 3D scenery.
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED if standing else BaseMaterial3D.SHADING_MODE_PER_PIXEL
	if standing:
		material.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
		material.billboard_keep_scale = true
	if kind.begins_with("grass_") or kind.begins_with("trail_"):
		var shore := ShaderMaterial.new()
		shore.shader = preload("res://shaders/shore_ground.gdshader")
		shore.set_shader_parameter("ground_atlas", atlas.atlas)
		shore.set_shader_parameter("terrain_trail", kind.begins_with("trail_"))
		shore.set_shader_parameter("terrain_trail", kind.begins_with("trail_"))
		water_tuning().apply_bank(shore)
		mesh.surface_set_material(0, shore)
	else:
		mesh.surface_set_material(0, material)
	return mesh

func add_piece(kind: String, at: Vector3, size: Vector3, color: Color, yaw: float = 0.0) -> void:
	preparation.add_piece(kind, at, size, color, yaw)

func add_site(site: Dictionary, include_trim: bool = true) -> void:
	if not site.get("admitted", false):
		return
	for element in site.elements:
		if not include_trim and str(element.id).ends_with("/trim"):
			continue
		var kind: String = element.kind
		if not batches.has(kind):
			batches[kind] = []
		batches[kind].append({"transform": element.transform, "color": element.color})
		var at: Vector3 = element.transform.origin
		pick_objects.append({"transform": element.transform, "mesh": mesh_for(kind), "bounds": mesh_for(kind).get_aabb(), "cell": Vector2i(Vector2(at.x, at.z).floor()), "category": "structure", "subject": site.get("subject", "Woodland shelter"), "site_id": site.id, "element_id": element.id})

func finish() -> void:
	while not finish_step():
		pass

## Upload one material batch per step so streaming can yield between uploads.
func finish_step() -> bool:
	last_finish_uploaded = false
	waiting_buffer = false
	terrain_vertex_cache.clear() # Construction-only data; do not retain it in resident chunks.
	if not terrain_surfaces.is_empty():
		var kind: String = terrain_surfaces.keys()[0]
		var arrays: Array = terrain_surfaces[kind]
		if arrays[Mesh.ARRAY_VERTEX].is_empty():
			terrain_surfaces.erase(kind)
			return false # A completely clipped shore batch has no surface to upload.
		var surface_mesh := ArrayMesh.new()
		surface_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays, [], {}, (Mesh.ARRAY_CUSTOM_RGB_FLOAT << Mesh.ARRAY_FORMAT_CUSTOM0_SHIFT) if arrays[Mesh.ARRAY_CUSTOM0] != null else 0)
		last_finish_uploaded = true
		# Blend turf, shore and rock in one opaque skin on the canonical vertices.
		var surface_material: Material
		if kind == "ground":
			surface_material = mesh_for("grass_0").surface_get_material(0)
		elif kind == "water":
			surface_material = mesh_for(kind).material
		else:
			surface_material = mesh_for(kind).surface_get_material(0)
		surface_mesh.surface_set_material(0, surface_material)
		var view := MeshInstance3D.new()
		view.name = kind
		view.mesh = surface_mesh
		add_child(view)
		terrain_surfaces.erase(kind)
		return false
	if not batches.is_empty():
		var kind: String = batches.keys()[0]
		var entries: Array = batches[kind]
		var use_worker := not preparation.prepared_buffers.has(kind) and buffer_worker != null and entries.size() >= buffer_min_rows and entries.size() <= BufferTask.MAX_ROWS
		if use_worker and buffer_handle < 0 and buffer_poses.is_empty():
			if buffer_worker.closed:
				worker_failure = "Closed buffer coordinator"
				return false
			# There is only one producer. Do not allocate a second snapshot while
			# canceled work still owns the coordinator's input/output reservation.
			if buffer_worker.task != null:
				waiting_buffer = true
				return false
		if upload_instances == null:
			upload_instances = MultiMesh.new()
			upload_instances.transform_format = MultiMesh.TRANSFORM_3D
			upload_instances.use_colors = true
			upload_instances.mesh = mesh_for(kind)
			for surface_index in range(upload_instances.mesh.get_surface_count()):
				var material: Material = upload_instances.mesh.surface_get_material(surface_index)
				if material is ShaderMaterial and material.shader != null:
					var shader_path: String = material.shader.resource_path
					if shader_path in ["res://shaders/tree_leaf_cards.gdshader", "res://shaders/meadow.gdshader"] or (shader_path == "res://shaders/procedural_plant_foliage.gdshader" and not material.get_shader_parameter("bark_surface")):
						upload_instances.use_custom_data = true
			upload_instances.instance_count = entries.size()
			upload_buffer = preparation.prepared_buffers.get(kind, PackedFloat32Array())
			upload_identity = str(upload_instances.get_instance_id())
		var instances := upload_instances
		if preparation.prepared_groups.has(kind):
			for cell in preparation.prepared_groups[kind]:
				if not plant_instances.has(cell): plant_instances[cell] = {}
				for suffix in preparation.prepared_groups[kind][cell]:
					var group: Dictionary = preparation.prepared_groups[kind][cell][suffix].duplicate()
					group["mesh"] = instances
					plant_instances[cell][upload_identity+suffix] = group
			upload_cursor = entries.size()
		var last := mini(upload_cursor + 32, entries.size())
		for index in range(upload_cursor, last):
			var pose: Transform3D = entries[index].transform
			var color: Color = entries[index].color
			if use_worker:
				buffer_poses.append(pose)
				buffer_colors.append(color)
			elif not preparation.prepared_buffers.has(kind):
				BufferTask.append_row(upload_buffer, pose, color, instances.use_custom_data)
			if entries[index].has("plant_cell"):
				var entry: Dictionary=entries[index]
				if not plant_instances.has(entry.plant_cell): plant_instances[entry.plant_cell]={}
				var group: Dictionary=plant_instances[entry.plant_cell]
				# Blades share a cell and batch, but retain their individual root pivots.
				# Do not allocate a dictionary and stringified pivot for every blade.
				var individual_roots: bool = entry.plant_pivot == entry.transform.origin
				var identity := upload_identity+(":roots" if individual_roots else ":"+str(entry.plant_pivot))
				if not group.has(identity): group[identity]={"mesh":instances,"indices":PackedInt32Array(),"pivot":entry.plant_pivot,"individual_roots":entry.plant_pivot==entry.transform.origin}
				group[identity].indices.append(index)
		upload_cursor = last
		if upload_cursor < entries.size():
			return false
		if use_worker:
			if buffer_handle < 0:
				buffer_poses.make_read_only()
				buffer_colors.make_read_only()
				buffer_handle = buffer_worker.submit(buffer_poses, buffer_colors, instances.use_custom_data, buffer_stamp)
				if buffer_handle < 0:
					if buffer_worker.closed or buffer_worker.task == null:
						worker_failure = "Buffer task admission failed"
						return false
					waiting_buffer = true
					return false
			var result: Dictionary = buffer_worker.take(buffer_handle, buffer_stamp)
			if result.status == "pending":
				waiting_buffer = true
				return false
			if result.status != "ready":
				worker_failure = str(result.get("error", result.status))
				return false
			upload_buffer = result.buffer
			buffer_handle = -1
			buffer_poses = []
			buffer_colors = []
		instances.buffer = upload_buffer
		last_finish_uploaded = true
		upload_buffer = PackedFloat32Array()
		var view := MultiMeshInstance3D.new()
		view.name = kind.replace(":", "_").replace("/", "_")
		view.multimesh = instances
		if entries[0].has("visibility_group"):
			view.set_meta("visibility_group", entries[0].visibility_group)
			if entries[0].visibility_group == "grass":
				view.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if instances.use_custom_data: view.extra_cull_margin = 0.2
		if kind.begins_with("nature_detail_meadow"):
			view.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			view.extra_cull_margin = 0.6
		add_child(view)
		preparation.prepared_buffers.erase(kind)
		preparation.prepared_groups.erase(kind)
		batches.erase(kind)
		upload_instances = null
		upload_cursor = 0
		return false
	return prepare_picking_step()

func prepare_picking() -> void:
	pick_index_ready = false
	traversal_bounds.clear()
	picking_cursor = 0
	while not prepare_picking_step():
		pass

func prepare_picking_step() -> bool:
	var last := mini(picking_cursor + 32, pick_objects.size())
	for index in range(picking_cursor, last):
		var object: Dictionary = pick_objects[index]
		object.inverse = object.transform.affine_inverse()
		var bounds: AABB = object.transform * object.bounds.grow(0.02)
		traversal_bounds.append(bounds)
		pick_bounds = pick_bounds.merge(bounds) if pick_index_ready else bounds
		pick_index_ready = true
	picking_cursor = last
	return picking_cursor == pick_objects.size()

func add_terrain_tile(kind: String, terrain: WorldTerrain, coord: Vector2i, index: int, color: Color, lift: float, nature: NatureSettings = null) -> void:
	preparation.surface_uvs = surface_uvs
	preparation.add_terrain_tile(kind, terrain, coord, index, color, lift, nature)

static func overlay_mesh(terrain: WorldTerrain, cell: Vector2i, size: float = 0.93) -> ArrayMesh:
	var vertices := PackedVector3Array()
	for offset in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
		var local: Vector2 = offset * size * 0.5
		var at := Vector2(cell) + Vector2(0.5, 0.5) + local
		vertices.append(Vector3(local.x, terrain.surface_height(at) - terrain.surface_height(Vector2(cell) + Vector2(0.5, 0.5)), local.y))
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = PackedVector3Array([Vector3.UP, Vector3.UP, Vector3.UP, Vector3.UP])
	arrays[Mesh.ARRAY_INDEX] = PackedInt32Array([0, 1, 2, 0, 2, 3])
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

## Each visible plant references its cell-level Vastra owner; clumps never mint energy.
## Membership is explicit, so arbitrary asset names and model substitutions are safe.
func register_living_source(cell: Vector2i, category: String, subject: String, anchor: Vector3, high_anchor: Vector3 = Vector3.INF, living: bool = true, presentation_priority: int = 0) -> void:
	preparation.register_living_source(cell, category, subject, anchor, high_anchor, living, presentation_priority)

func add_nature(scene: PackedScene, at: Vector3, height: float, yaw: float, category: String, tint: Color = Color.WHITE, living: bool = true) -> void:
	preparation.add_nature(scene, at, height, yaw, category, tint, living)

func add_composed_nature(record: Dictionary) -> void:
	preparation.add_composed_nature(record)

func add_pond_surface(terrain: WorldTerrain, cell: Vector2i, level: float, color: Color) -> void:
	preparation.add_pond_surface(terrain, cell, level, color)

func build(cells: Array[Dictionary], terrain: WorldTerrain = null, coord: Vector2i = Vector2i.ZERO, nature: NatureSettings = null) -> void:
	if nature == null or not nature.valid():
		nature = preload("res://resources/nature_settings.tres")
	build_cells(cells, terrain, coord, nature, 0, cells.size())
	finish()

func prepare_cell_build(terrain: WorldTerrain,coord: Vector2i,nature: NatureSettings) -> void:
	if nature != null:
		for kind in ["grass_0", "grass_1", "grass_2", "grass_3", "trail_0", "trail_1", "trail_2", "trail_3", "trail_4", "trail_5", "trail_6", "trail_7"]:
			var ground: ShaderMaterial = mesh_for(kind).surface_get_material(0)
			nature.apply_terrain_material(ground)
			if terrain != null: ground.set_shader_parameter("terrain_palette_seed", float(posmod(terrain.world_seed, 65521)))
			ground.set_shader_parameter("ground_base_color", nature.ground_base_color)
			ground.set_shader_parameter("ground_texture_strength", nature.ground_texture_strength)
	preparation.surface_uvs = surface_uvs
	preparation.prepare_cell_build(terrain, coord, nature)

func build_cells(cells: Array[Dictionary], terrain: WorldTerrain, coord: Vector2i, nature: NatureSettings, first: int, count: int) -> void:
	prepare_cell_build(terrain, coord, nature) if first == 0 and cell_setup_count == 0 else null
	preparation.build_cells(cells, terrain, coord, nature, first, count)

func build_cell_step(cells: Array[Dictionary], terrain: WorldTerrain, coord: Vector2i, nature: NatureSettings, index: int) -> bool:
	if index == 0 and preparation.cell_work.is_empty() and preparation.cell_setup_count == 0: prepare_cell_build(terrain, coord, nature)
	var complete: bool = preparation.build_cell_step(cells, terrain, coord, nature, index)
	return complete

func build_cell_ground(cells: Array[Dictionary], terrain: WorldTerrain, coord: Vector2i, nature: NatureSettings, index: int) -> void:
	preparation.build_cell_ground(cells, terrain, coord, nature, index)

func build_cell_dressing(cells: Array[Dictionary], terrain: WorldTerrain, coord: Vector2i, nature: NatureSettings, index: int, authored_plant: Dictionary) -> void:
	preparation.build_cell_dressing(cells, terrain, coord, nature, index, authored_plant)

func add_specialist_plant(terrain: WorldTerrain, cell: Vector2i, data: Dictionary) -> bool:
	return preparation.add_specialist_plant(terrain, cell, data)

static func neighbor_is_land(cells: Array[Dictionary], index: int, direction: Vector2i, terrain: WorldTerrain, coord: Vector2i) -> bool:
	return preload("res://scripts/presentation/chunk_build_data.gd").neighbor_is_land(cells, index, direction, terrain, coord)

func apply_plant_animations(events: Dictionary,seconds: float,strength: float=1.0) -> void:
	var cells := animated_plants.duplicate()
	for cell in events:
		if plant_instances.has(cell): cells[cell]=true
	animated_plants.clear()
	for cell in cells:
		if not plant_instances.has(cell): continue
		var shape := Basis.IDENTITY
		var tree: bool = living_sources.get(cell,{}).get("kind","")=="tree"
		if events.has(cell) and not tree:
			var event: Dictionary=events[cell]
			shape=preload("res://scripts/presentation/plant_animation.gd").pose(event.kind,seconds-event.start,event.duration,strength)
			animated_plants[cell]=true
		for entry: Dictionary in plant_instances[cell].values():
			if tree and not entry.has("rest"): continue
			if not entry.has("rest"):
				var poses: Array[Transform3D] = []
				for index: int in entry.indices: poses.append(entry.mesh.get_instance_transform(index))
				entry["rest"]=poses
			if vegetation_visual_queue != null:
				vegetation_visual_queue.enqueue(self, cell, entry, "pose", {"shape": shape, "rest": entry.rest, "individual_roots": entry.individual_roots, "pivot": entry.pivot})
			else:
				for index in range(entry.indices.size()):
					var rest: Transform3D=entry.rest[index]
					var pivot: Vector3=rest.origin if entry.individual_roots else entry.pivot
					entry.mesh.set_instance_transform(entry.indices[index],Transform3D(shape,pivot-shape*pivot)*rest)
			if vegetation_visual_queue == null and (not events.has(cell) or tree): entry.erase("rest")

## The canonical cell owns this reading. Shared materials and clumps own no energy.
func apply_plant_reserve(cell: Vector2i, fraction: float, seconds: float = -1.0) -> void:
	var level := clampi(roundi(fraction * 20.0), 0, 20)
	for group: Dictionary in plant_instances.get(cell, {}).values():
		var mesh: MultiMesh = group.mesh
		if not mesh.use_custom_data or group.get("reserve_level", -1) == level: continue
		var target := float(level)/20.0
		var previous: Color=group.get("reserve_transition",Color(target,target,seconds,1.0))
		var blend := smoothstep(0.0,reserve_transition_seconds,maxf(0.0,seconds-previous.b))
		var shown := lerpf(previous.r,previous.g,blend) if seconds>=0.0 else target
		var transition := Color(shown,target,seconds,1.0)
		group["reserve_level"] = level
		group["reserve_transition"] = transition
		if vegetation_visual_queue != null:
			vegetation_visual_queue.enqueue(self, cell, group, "reserve", transition)
		else:
			for index: int in group.indices: mesh.set_instance_custom_data(index, transition)

func adopt_prepared(task: RefCounted, terrain: WorldTerrain, coord: Vector2i, nature: NatureSettings) -> void:
	prepare_cell_build(terrain, coord, nature)
	preparation = task.data
	meshes.merge(preparation.meshes)
	pick_bounds = task.pick_bounds
	traversal_bounds = task.traversal
	pick_index_ready = not pick_objects.is_empty()
	picking_cursor = pick_objects.size()

func _init() -> void:
	preparation.meshes = meshes
	preparation.surface_uvs = surface_uvs

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		# A partial cursor refers back to this RefCounted calculation owner.
		# Direct scene teardown must break that cycle as incremental retirement does.
		preparation.cell_work.clear()
		preparation.catalog = null
