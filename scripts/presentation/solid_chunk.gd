extends Node3D
## Batched solid geometry from prepared terrain data. No new generation or collision rules.

static var meshes: Dictionary = {}
static var surface_uvs: Dictionary = {}
const NatureArt = preload("res://scripts/scenery/nature_art.gd")
const WaterAppearance = preload("res://scripts/presentation/water_appearance_settings.gd")
var batches: Dictionary = {}
var build_biome_patches: Dictionary = {}
var cell_setup_count := 0
var terrain_surfaces: Dictionary = {}
var pick_objects: Array[Dictionary] = []
var pick_bounds := AABB()
var pick_index_ready := false
var traversal_bounds: Array[AABB] = []
var tile_count := 0
var obstacle_count := 0
var shoreline_edges := 0
var cell_origin := Vector2i.ZERO
var vegetation_appearance: VegetationAppearance = preload("res://resources/vegetation_appearance.tres")
## Absolute cosmetic records, compared by asset/cell rather than runtime IDs.
var cosmetic_records: Array[Dictionary] = []
var living_sources: Dictionary = {}
var plant_instances: Dictionary = {}
var animated_plants: Dictionary = {}
var living_regions: Dictionary = {}
var upload_instances: MultiMesh
var upload_cursor := 0
var upload_buffer := PackedFloat32Array()
var upload_identity := ""
var picking_cursor := 0

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
	if not batches.has(kind):
		batches[kind] = []
	var basis := Basis(Vector3.UP, yaw).scaled(size)
	batches[kind].append({"transform": Transform3D(basis, at), "color": color})
	if kind in ["post", "prop", "wall", "roof"]:
		pick_objects.append({"transform": Transform3D(basis, at), "mesh": mesh_for(kind), "bounds": mesh_for(kind).get_aabb(), "cell": Vector2i(Vector2(at.x, at.z).floor())})

## Publish one already-admitted site. This consumer never chooses placements.
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
	if not terrain_surfaces.is_empty():
		var kind: String = terrain_surfaces.keys()[0]
		var arrays: Array = terrain_surfaces[kind]
		if arrays[Mesh.ARRAY_VERTEX].is_empty():
			terrain_surfaces.erase(kind)
			return false # A completely clipped shore batch has no surface to upload.
		var surface_mesh := ArrayMesh.new()
		surface_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays, [], {}, (Mesh.ARRAY_CUSTOM_RG_FLOAT << Mesh.ARRAY_FORMAT_CUSTOM0_SHIFT) if arrays[Mesh.ARRAY_CUSTOM0] != null else 0)
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
		if upload_instances == null:
			upload_instances = MultiMesh.new()
			upload_instances.transform_format = MultiMesh.TRANSFORM_3D
			upload_instances.use_colors = true
			upload_instances.mesh = mesh_for(kind)
			upload_instances.instance_count = entries.size()
			upload_buffer = PackedFloat32Array()
			upload_identity = str(upload_instances.get_instance_id())
		var instances := upload_instances
		var last := mini(upload_cursor + 32, entries.size())
		for index in range(upload_cursor, last):
			var pose: Transform3D = entries[index].transform
			var color: Color = entries[index].color.srgb_to_linear()
			# MultiMesh's bulk buffer uses row-major 3x4 transforms, then RGBA.
			upload_buffer.append_array(PackedFloat32Array([pose.basis.x.x, pose.basis.y.x, pose.basis.z.x, pose.origin.x,
				pose.basis.x.y, pose.basis.y.y, pose.basis.z.y, pose.origin.y,
				pose.basis.x.z, pose.basis.y.z, pose.basis.z.z, pose.origin.z,
				color.r, color.g, color.b, color.a]))
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
		instances.buffer = upload_buffer
		upload_buffer = PackedFloat32Array()
		var view := MultiMeshInstance3D.new()
		view.name = kind.replace(":", "_").replace("/", "_")
		view.multimesh = instances
		if kind.begins_with("nature_detail_meadow"):
			view.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			view.extra_cull_margin = 0.6
		add_child(view)
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
	if not terrain_surfaces.has(kind):
		var empty: Array = []
		empty.resize(Mesh.ARRAY_MAX)
		empty[Mesh.ARRAY_VERTEX] = PackedVector3Array()
		empty[Mesh.ARRAY_NORMAL] = PackedVector3Array()
		empty[Mesh.ARRAY_TEX_UV] = PackedVector2Array()
		empty[Mesh.ARRAY_TEX_UV2] = PackedVector2Array()
		empty[Mesh.ARRAY_COLOR] = PackedColorArray()
		empty[Mesh.ARRAY_CUSTOM0] = PackedFloat32Array()
		empty[Mesh.ARRAY_INDEX] = PackedInt32Array()
		terrain_surfaces[kind] = empty
	var arrays: Array = terrain_surfaces[kind]
	var source_kind := "grass_0" if kind == "ground" else kind
	if not surface_uvs.has(source_kind):
		surface_uvs[source_kind] = mesh_for(source_kind).surface_get_arrays(0)[Mesh.ARRAY_TEX_UV]
	var start: int = arrays[Mesh.ARRAY_VERTEX].size()
	var local := Vector2i(index % 16, index / 16)
	var absolute := coord * 16 + local
	var shore := terrain.lake_distance(absolute) < 2.8
	var pond_level: float = terrain.pond_at(absolute).level if shore else 0.0
	# The movement owner rejects the whole cell when either triangle is too steep.
	# Carry that exact classification rather than infer access from smoothed normals.
	var cliff := not terrain.slope_fits(absolute)
	var offsets := [Vector2i.ZERO, Vector2i.RIGHT, Vector2i.ONE, Vector2i.DOWN]
	for corner in range(4):
		var cell: Vector2i = coord * 16 + local + offsets[corner]
		arrays[Mesh.ARRAY_VERTEX].append(Vector3(local.x + offsets[corner].x, terrain.vertex_height(cell) + lift, local.y + offsets[corner].y))
		arrays[Mesh.ARRAY_NORMAL].append(terrain.vertex_normal(cell))
		arrays[Mesh.ARRAY_TEX_UV].append(surface_uvs[source_kind][corner])
		arrays[Mesh.ARRAY_TEX_UV2].append(Vector2(pond_level, (1.0 if shore else 0.0) + (2.0 if cliff else 0.0)))
		var vertex_color := color
		if nature != null and not nature.biomes.is_empty():
			vertex_color = terrain.habitat_tint(cell) * nature.ground_tint_at(terrain, cell)
		# Alpha is a presentation soil weight, derived from the existing biome owner.
		vertex_color.a = NatureSettings.terrain_soil_at(terrain, cell)
		arrays[Mesh.ARRAY_COLOR].append(vertex_color.srgb_to_linear())
		arrays[Mesh.ARRAY_CUSTOM0].append_array(NatureSettings.terrain_blend_at(terrain,cell))
	arrays[Mesh.ARRAY_INDEX].append_array(PackedInt32Array([start, start + 1, start + 2, start, start + 2, start + 3]))
	terrain_surfaces[kind] = arrays

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
	if not living or category not in ["tree", "detail"]: return
	if not living_sources.has(cell) or (category == "tree" and living_sources[cell].kind != "tree") or presentation_priority > int(living_sources.get(cell,{}).get("priority",0)):
		living_sources[cell] = {"priority":presentation_priority,"kind": category, "anchor": anchor, "high_anchor": high_anchor if high_anchor.is_finite() else anchor, "cell": cell, "flora_id": FloraCatalog.id_for(cell), "id": "%s:%d:%d:%.4f:%.4f" % [subject, cell.x, cell.y, anchor.x, anchor.z]}
		var owner := Vector2i(WorldTerrain.floor_div(cell.x, VastraSettings.SOURCE_REGION_SIZE), WorldTerrain.floor_div(cell.y, VastraSettings.SOURCE_REGION_SIZE))
		if not living_regions.has(owner): living_regions[owner] = {}
		living_regions[owner][cell] = living_sources[cell]

func add_nature(scene: PackedScene, at: Vector3, height: float, yaw: float, category: String, tint: Color = Color.WHITE, living: bool = true) -> void:
	# Imported plant bodies are retired even if an older caller requests them.
	if category in ["tree", "detail"]: return
	if scene.resource_path in preload("res://scripts/scenery/meadow_art.gd").SUPERSEDED_GRASS: return
	var model: Dictionary = NatureArt.tint_parts(NatureArt.compact_parts(scene), tint)
	var bounds: AABB = model.bounds
	var factor := height / maxf(0.01, bounds.size.y)
	var base := Transform3D(Basis(Vector3.UP, yaw).scaled(Vector3.ONE * factor), at)
	base.origin -= base.basis * Vector3(bounds.get_center().x, bounds.position.y, bounds.get_center().z)
	for index in range(model.pieces.size()):
		var piece: Dictionary = model.pieces[index]
		var key := "nature_%s_%s_%d_%d_%d" % [category, scene.resource_path.get_file().get_basename(), scene.get_instance_id(), index, hash(tint)]
		meshes[key] = piece.mesh
		if not batches.has(key):
			batches[key] = []
		var entry := {"transform":base*piece.transform,"color":Color.WHITE}
		if living and category in ["tree","detail"]:
			entry["plant_cell"]=cell_origin+Vector2i(Vector2(at.x,at.z).floor())
			entry["plant_pivot"]=at
		batches[key].append(entry)
	register_living_source(cell_origin + Vector2i(Vector2(at.x, at.z).floor()), category, scene.resource_path.get_file(), Vector3(at.x + cell_origin.x, at.y + minf(height * 0.25, 0.9), at.z + cell_origin.y), Vector3(at.x + cell_origin.x, at.y + height * 0.96, at.z + cell_origin.y), living)
	# Rendering may merge surfaces, but clearance keeps the original per-part
	# boxes so material grouping cannot enlarge an actor's blocked corridors.
	for piece in NatureArt.parts(scene).pieces:
		pick_objects.append({"transform": base * piece.transform, "mesh": piece.mesh, "bounds": piece.mesh.get_aabb(), "cell": cell_origin + Vector2i(Vector2(at.x, at.z).floor()), "category": category, "vastra_anchor": Vector3(at.x + cell_origin.x, at.y + minf(height * 0.25, 0.9), at.z + cell_origin.y), "subject": scene.resource_path.get_file().get_basename().to_snake_case().replace("_", " ").capitalize()})

func add_composed_nature(record: Dictionary) -> void:
	if record.get("living", true) and record.get("patch", "") != "authored_plant": return
	if record.asset in preload("res://scripts/scenery/meadow_art.gd").SUPERSEDED_GRASS: return
	var transform: Transform3D = record.transform
	transform.origin -= Vector3(cell_origin.x, 0, cell_origin.y)
	var tint: Color = record.get("tint", Color.WHITE)
	var category: String = record.get("category","detail")
	var anchor: Vector3 = record.get("vastra_anchor",record.transform * Vector3(record.model.bounds.get_center().x,record.model.bounds.position.y+minf(record.model.bounds.size.y*0.3,0.35),record.model.bounds.get_center().z))
	var model := NatureArt.tint_parts(record.model, tint)
	for index in range(model.pieces.size()):
		var piece: Dictionary = model.pieces[index]
		var key := "nature_detail_%s_%d_%d" % [record.asset, index, hash(tint)]
		meshes[key] = piece.mesh
		if not batches.has(key):
			batches[key] = []
		var entry := {"transform":transform*piece.transform,"color":Color.WHITE}
		if record.get("living",true) and category in ["tree","detail"]:
			entry["plant_cell"]=record.cell
			entry["plant_pivot"]=Vector3(record.cell.x+0.5-cell_origin.x,record.bounds.position.y,record.cell.y+0.5-cell_origin.y)
		batches[key].append(entry)
		pick_objects.append({"transform": transform * piece.transform, "mesh": piece.mesh, "bounds": piece.mesh.get_aabb(), "cell": record.cell, "category": category, "vastra_anchor": anchor, "subject": record.get("subject", record.asset.get_file().get_basename().replace("_", " ").capitalize())})
	register_living_source(record.cell, category, record.get("subject",record.asset), anchor, record.get("high_anchor",Vector3.INF), record.get("living", true))
	if living_sources.has(record.cell): living_sources[record.cell]["organs"] = record.get("vastra_organs",{}).duplicate(true)
	var stable := record.duplicate()
	stable.erase("model")
	if stable.get("living", true): stable["flora_id"] = FloraCatalog.id_for(record.cell)
	cosmetic_records.append(stable)

## Clip each canonical ground triangle against its pond's horizontal plane.
## Dry portions retain ground; water cell centers cannot admit ordinary walking.
func add_pond_surface(terrain: WorldTerrain, cell: Vector2i, level: float, color: Color) -> void:
	if not terrain_surfaces.has("water"):
		var empty: Array = []
		empty.resize(Mesh.ARRAY_MAX)
		empty[Mesh.ARRAY_VERTEX] = PackedVector3Array()
		empty[Mesh.ARRAY_NORMAL] = PackedVector3Array()
		empty[Mesh.ARRAY_TEX_UV] = PackedVector2Array()
		empty[Mesh.ARRAY_TEX_UV2] = PackedVector2Array()
		empty[Mesh.ARRAY_COLOR] = PackedColorArray()
		empty[Mesh.ARRAY_INDEX] = PackedInt32Array()
		terrain_surfaces.water = empty
	var arrays: Array = terrain_surfaces.water
	var local := cell - cell_origin
	var heights := terrain.corners(cell)
	var corners := [Vector3(local.x, heights.x, local.y), Vector3(local.x + 1, heights.y, local.y), Vector3(local.x + 1, heights.z, local.y + 1), Vector3(local.x, heights.w, local.y + 1)]
	for triangle in [[corners[0], corners[1], corners[2]], [corners[0], corners[2], corners[3]]]:
		var polygon: Array[Vector3] = []
		var depths: Array[float] = []
		for index in range(3):
			var a: Vector3 = triangle[index]
			var b: Vector3 = triangle[(index + 1) % 3]
			if a.y <= level:
				polygon.append(Vector3(a.x, level, a.z))
				depths.append(maxf(0.0, level - a.y))
			if (a.y < level) != (b.y < level):
				polygon.append(a.lerp(b, (level - a.y) / (b.y - a.y)))
				depths.append(0.0)
		if polygon.size() < 3:
			continue
		var first: int = arrays[Mesh.ARRAY_VERTEX].size()
		for index in range(polygon.size()):
			var vertex := polygon[index]
			arrays[Mesh.ARRAY_VERTEX].append(vertex)
			arrays[Mesh.ARRAY_NORMAL].append(Vector3.UP)
			arrays[Mesh.ARRAY_TEX_UV].append(Vector2(vertex.x, vertex.z))
			arrays[Mesh.ARRAY_TEX_UV2].append(Vector2(depths[index], 1.0))
			arrays[Mesh.ARRAY_COLOR].append(color)
		for index in range(1, polygon.size() - 1):
			arrays[Mesh.ARRAY_INDEX].append_array(PackedInt32Array([first, first + index, first + index + 1]))
	terrain_surfaces.water = arrays

func build(cells: Array[Dictionary], terrain: WorldTerrain = null, coord: Vector2i = Vector2i.ZERO, nature: NatureSettings = null) -> void:
	if nature == null or not nature.valid():
		nature = preload("res://resources/nature_settings.tres")
	build_cells(cells, terrain, coord, nature, 0, cells.size())
	finish()

func prepare_cell_build(terrain: WorldTerrain,coord: Vector2i,nature: NatureSettings) -> void:
	cell_setup_count+=1
	if nature != null:
		for kind in ["grass_0", "grass_1", "grass_2", "grass_3", "trail_0", "trail_1", "trail_2", "trail_3", "trail_4", "trail_5", "trail_6", "trail_7"]:
			var ground: ShaderMaterial = mesh_for(kind).surface_get_material(0)
			nature.apply_terrain_material(ground)
			if terrain != null: ground.set_shader_parameter("terrain_palette_seed", float(posmod(terrain.world_seed, 65521)))
			ground.set_shader_parameter("ground_base_color", nature.ground_base_color)
			ground.set_shader_parameter("ground_texture_strength", nature.ground_texture_strength)
	cell_origin = coord * 16
	build_biome_patches.clear()
	if terrain != null:
		for biome in nature.biomes:
			build_biome_patches[biome.ground] = biome.detail_patch(terrain, coord)

## Same deterministic geometry path as build(), with bounded cell ranges.
func build_cells(cells: Array[Dictionary], terrain: WorldTerrain, coord: Vector2i, nature: NatureSettings, first: int, count: int) -> void:
	if first==0 or cell_setup_count==0: prepare_cell_build(terrain,coord,nature)
	var biome_patches := build_biome_patches
	var palette := [Color("647d51"), Color("4c6949"), Color("938164"), Color("55796e"), Color("367e89"), Color("c4b183")]
	for index in range(first, mini(first + count, cells.size())):
		var data: Dictionary = cells[index]
		var absolute := coord * 16 + Vector2i(index % 16, index / 16)
		var biome: NatureBiomePalette = nature.biome_for(data.ground)
		var tint: Color = data.get("tint", Color.WHITE)
		if biome != null:
			tint *= nature.ground_tint_at(terrain, absolute) if terrain != null else biome.ground_tint
		var at := Vector3(index % 16 + 0.5, 0.0, floori(float(index) / 16) + 0.5)
		var shade: float = (float(data.variation) - 3.0) * 0.009
		var color: Color = palette[data.ground].lightened(shade)
		if data.ground == WorldTerrain.Ground.WATER:
			var level: float = terrain.pond_at(absolute).level if terrain != null else -0.22
			if terrain != null:
				# Continue the same material through the bank and submerged bed.
				add_terrain_tile("ground", terrain, coord, index, tint, 0.0, nature)
				add_pond_surface(terrain, absolute, level, color)
			else:
				add_piece("water", at + Vector3(0, level - 0.08, 0), Vector3(1.002, 0.16, 1.002), color)
			for direction in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				if neighbor_is_land(cells, index, direction, terrain, coord):
					shoreline_edges += 1
					if terrain != null:
						continue # Continuous bed/plane intersection supplies the real bank.
					var edge := Vector3(direction.x, 0, direction.y)
					var along_x: bool = direction.y != 0
					var top := level + (0.10 if terrain != null else 0.22)
					add_piece("bank", at + edge * 0.5 + Vector3(0, top - 0.17, 0), Vector3(1.0, 0.34, 0.025) if along_x else Vector3(0.025, 0.34, 1.0), Color.WHITE)
					add_piece("shore_rim", at + edge * 0.49 + Vector3(0, top + 0.006, 0), Vector3(1.0, 0.012, 0.06) if along_x else Vector3(0.06, 0.012, 1.0), Color.WHITE)
		else:
			if terrain != null:
				add_terrain_tile("ground", terrain, coord, index, tint, 0.0, nature)
				if terrain.lake_distance(absolute) < 1.8:
					add_pond_surface(terrain, absolute, terrain.pond_at(absolute).level, palette[WorldTerrain.Ground.WATER])
				if data.trail_visible and not nature.terrain_palette_enabled:
					add_terrain_tile("trail_%d" % (int(data.variation) % 8), terrain, coord, index, Color("b2b29d"), 0.035)
			else:
				add_piece("ground", at + Vector3(0, -0.35, 0), Vector3(1.002, 0.70, 1.002), color)
				add_piece("grass_%d" % (int(data.variation) % 4), at + Vector3(0, 0.002, 0), Vector3.ONE, tint)
				if data.trail_visible:
					add_piece("trail_%d" % (int(data.variation) % 8), at + Vector3(0, 0.035, 0), Vector3.ONE, Color("b2b29d"))
		var authored_plant := {}
		if terrain != null:
			at.y = terrain.surface_height(Vector2(absolute) + Vector2(0.5, 0.5))
			authored_plant = preload("res://scripts/scenery/plant_library.gd").add_cell(self,terrain,absolute,data,nature)
		if data.obstacle == 1:
			# Rejected procedural footprints stay empty; never revive legacy trees.
			obstacle_count += 1
		elif data.obstacle == 2:
			add_nature(nature.rocks[int(data.variation) % nature.rocks.size()], at, nature.rock_height * (0.9 + float(data.variation) * 0.04), float(data.variation), "rock")
			obstacle_count += 1
		elif terrain != null and terrain.scenery_reserved(absolute):
			pass # Site access and required spaces own this ground before dressing.
		elif not authored_plant.is_empty():
			pass # Shared plant owner already submitted the body and its ground cover.
		elif terrain != null and biome != null:
			var record := NatureComposition.placement_for(terrain, absolute, biome_patches[data.ground], biome.cluster_cells, biome.cluster_fill, biome.scale_variation, true, false)
			if not record.is_empty() and not record.get("living", true):
				record.tint = biome.detail_tint
				add_composed_nature(record)
		elif terrain != null and nature.composition != null and nature.composition.patch_at(terrain, absolute) != null:
			var patch: NaturePatch = nature.composition.patch_at(terrain, absolute)
			var record := nature.composition.placement(terrain, absolute, patch)
			if not record.is_empty() and not record.get("living", true):
				add_composed_nature(record)
		tile_count += 1

func add_specialist_plant(terrain: WorldTerrain, cell: Vector2i, data: Dictionary) -> bool:
	var record := preload("res://scripts/scenery/plant_library.gd").placement(terrain, cell, data, "plant", true)
	if record.is_empty(): return false
	add_composed_nature(record)
	return true

static func neighbor_is_land(cells: Array[Dictionary], index: int, direction: Vector2i, terrain: WorldTerrain, coord: Vector2i) -> bool:
	var neighbor := Vector2i(index % 16, floori(float(index) / 16)) + direction
	if neighbor.x >= 0 and neighbor.x < 16 and neighbor.y >= 0 and neighbor.y < 16:
		return cells[neighbor.y * 16 + neighbor.x].ground != WorldTerrain.Ground.WATER
	if terrain != null:
		return terrain.sample(coord * 16 + neighbor).ground != WorldTerrain.Ground.WATER
	return false

func apply_plant_animations(events: Dictionary,seconds: float,strength: float=1.0) -> void:
	var cells := animated_plants.duplicate()
	for cell in events:
		if plant_instances.has(cell): cells[cell]=true
	animated_plants.clear()
	for cell in cells:
		if not plant_instances.has(cell): continue
		var shape := Basis.IDENTITY
		if events.has(cell):
			var event: Dictionary=events[cell]
			shape=preload("res://scripts/presentation/plant_animation.gd").pose(event.kind,seconds-event.start,event.duration,strength)
			animated_plants[cell]=true
		for entry: Dictionary in plant_instances[cell].values():
			if not entry.has("rest"):
				var poses: Array[Transform3D] = []
				for index: int in entry.indices: poses.append(entry.mesh.get_instance_transform(index))
				entry["rest"]=poses
			for index in range(entry.indices.size()):
				var rest: Transform3D=entry.rest[index]
				var pivot: Vector3=rest.origin if entry.individual_roots else entry.pivot
				entry.mesh.set_instance_transform(entry.indices[index],Transform3D(shape,pivot-shape*pivot)*rest)
			if not events.has(cell): entry.erase("rest")
