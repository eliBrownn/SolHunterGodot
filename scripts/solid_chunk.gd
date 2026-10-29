extends Node3D
## Batched solid geometry from prepared terrain data. No new generation or collision rules.

static var meshes: Dictionary = {}
static var surface_uvs: Dictionary = {}
const NatureArt = preload("res://scripts/nature_art.gd")
const WaterAppearance = preload("res://scripts/water_appearance_settings.gd")
var batches: Dictionary = {}
var terrain_surfaces: Dictionary = {}
var pick_objects: Array[Dictionary] = []
var pick_bounds := AABB()
var pick_index_ready := false
var traversal_bounds: Array[AABB] = []
var tile_count := 0
var obstacle_count := 0
var shoreline_edges := 0
var cell_origin := Vector2i.ZERO
## Absolute cosmetic records, compared by asset/cell rather than runtime IDs.
var cosmetic_records: Array[Dictionary] = []
var upload_instances: MultiMesh
var upload_cursor := 0
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
	if kind.begins_with("grass_"):
		var shore := ShaderMaterial.new()
		shore.shader = preload("res://shaders/shore_ground.gdshader")
		shore.set_shader_parameter("ground_atlas", atlas.atlas)
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
		surface_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		surface_mesh.surface_set_material(0, mesh_for(kind).material if kind in ["ground", "water"] else mesh_for(kind).surface_get_material(0))
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
		var instances := upload_instances
		var last := mini(upload_cursor + 32, entries.size())
		for index in range(upload_cursor, last):
			instances.set_instance_transform(index, entries[index].transform)
			# MultiMesh instance colors are supplied in linear space.
			instances.set_instance_color(index, entries[index].color.srgb_to_linear())
		upload_cursor = last
		if upload_cursor < entries.size():
			return false
		var view := MultiMeshInstance3D.new()
		view.name = kind.replace(":", "_").replace("/", "_")
		view.multimesh = instances
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

func add_terrain_tile(kind: String, terrain: WorldTerrain, coord: Vector2i, index: int, color: Color, lift: float) -> void:
	if not terrain_surfaces.has(kind):
		var empty: Array = []
		empty.resize(Mesh.ARRAY_MAX)
		empty[Mesh.ARRAY_VERTEX] = PackedVector3Array()
		empty[Mesh.ARRAY_NORMAL] = PackedVector3Array()
		empty[Mesh.ARRAY_TEX_UV] = PackedVector2Array()
		empty[Mesh.ARRAY_TEX_UV2] = PackedVector2Array()
		empty[Mesh.ARRAY_COLOR] = PackedColorArray()
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
	var offsets := [Vector2i.ZERO, Vector2i.RIGHT, Vector2i.ONE, Vector2i.DOWN]
	for corner in range(4):
		var cell: Vector2i = coord * 16 + local + offsets[corner]
		arrays[Mesh.ARRAY_VERTEX].append(Vector3(local.x + offsets[corner].x, terrain.vertex_height(cell) + lift, local.y + offsets[corner].y))
		arrays[Mesh.ARRAY_NORMAL].append(terrain.vertex_normal(cell))
		arrays[Mesh.ARRAY_TEX_UV].append(surface_uvs[source_kind][corner])
		arrays[Mesh.ARRAY_TEX_UV2].append(Vector2(pond_level, 1.0 if shore else 0.0))
		arrays[Mesh.ARRAY_COLOR].append(color.srgb_to_linear())
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

func add_nature(scene: PackedScene, at: Vector3, height: float, yaw: float, category: String) -> void:
	var model: Dictionary = NatureArt.compact_parts(scene)
	var bounds: AABB = model.bounds
	var factor := height / maxf(0.01, bounds.size.y)
	var base := Transform3D(Basis(Vector3.UP, yaw).scaled(Vector3.ONE * factor), at)
	base.origin -= base.basis * Vector3(bounds.get_center().x, bounds.position.y, bounds.get_center().z)
	for index in range(model.pieces.size()):
		var piece: Dictionary = model.pieces[index]
		var key := "nature_%s_%s_%d_%d" % [category, scene.resource_path.get_file().get_basename(), scene.get_instance_id(), index]
		meshes[key] = piece.mesh
		if not batches.has(key):
			batches[key] = []
		batches[key].append({"transform": base * piece.transform, "color": Color.WHITE})
	# Rendering may merge surfaces, but clearance keeps the original per-part
	# boxes so material grouping cannot enlarge an actor's blocked corridors.
	for piece in NatureArt.parts(scene).pieces:
		pick_objects.append({"transform": base * piece.transform, "mesh": piece.mesh, "bounds": piece.mesh.get_aabb(), "cell": cell_origin + Vector2i(Vector2(at.x, at.z).floor()), "category": category, "subject": scene.resource_path.get_file().get_basename().to_snake_case().replace("_", " ").capitalize()})

func add_composed_nature(record: Dictionary) -> void:
	var transform: Transform3D = record.transform
	transform.origin -= Vector3(cell_origin.x, 0, cell_origin.y)
	for index in range(record.model.pieces.size()):
		var piece: Dictionary = record.model.pieces[index]
		var key := "nature_detail_%s_%d" % [record.asset, index]
		meshes[key] = piece.mesh
		if not batches.has(key):
			batches[key] = []
		batches[key].append({"transform": transform * piece.transform, "color": Color.WHITE})
		pick_objects.append({"transform": transform * piece.transform, "mesh": piece.mesh, "bounds": piece.mesh.get_aabb(), "cell": record.cell, "category": "detail", "subject": record.asset.get_file().get_basename().replace("_", " ").capitalize()})
	var stable := record.duplicate()
	stable.erase("model")
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

## Same deterministic geometry path as build(), with bounded cell ranges.
func build_cells(cells: Array[Dictionary], terrain: WorldTerrain, coord: Vector2i, nature: NatureSettings, first: int, count: int) -> void:
	cell_origin = coord * 16
	var palette := [Color("647d51"), Color("4c6949"), Color("938164"), Color("55796e"), Color("367e89"), Color("c4b183")]
	for index in range(first, mini(first + count, cells.size())):
		var data: Dictionary = cells[index]
		var at := Vector3(index % 16 + 0.5, 0.0, floori(float(index) / 16) + 0.5)
		var absolute := coord * 16 + Vector2i(index % 16, index / 16)
		var shade: float = (float(data.variation) - 3.0) * 0.009
		var color: Color = palette[data.ground].lightened(shade)
		if data.ground == WorldTerrain.Ground.WATER:
			var level: float = terrain.pond_at(absolute).level if terrain != null else -0.22
			if terrain != null:
				add_terrain_tile("ground", terrain, coord, index, palette[WorldTerrain.Ground.SAND], 0.0)
				# Continue the same bank/grass layer through partially wet cells.
				# The old bare-sand water-cell path exposed triangular mask seams.
				var heights := terrain.corners(absolute)
				if maxf(maxf(heights.x, heights.y), maxf(heights.z, heights.w)) >= level - 0.002:
					add_terrain_tile("grass_%d" % (int(data.variation) % 4), terrain, coord, index, data.get("tint", Color.WHITE), 0.002)
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
				add_terrain_tile("ground", terrain, coord, index, color, 0.0)
				if terrain.lake_distance(absolute) < 1.8:
					add_pond_surface(terrain, absolute, terrain.pond_at(absolute).level, palette[WorldTerrain.Ground.WATER])
				add_terrain_tile("grass_%d" % (int(data.variation) % 4), terrain, coord, index, data.get("tint", Color.WHITE), 0.002)
				if data.trail_visible:
					add_terrain_tile("trail_%d" % (int(data.variation) % 8), terrain, coord, index, Color("b2b29d"), 0.035)
			else:
				add_piece("ground", at + Vector3(0, -0.35, 0), Vector3(1.002, 0.70, 1.002), color)
				add_piece("grass_%d" % (int(data.variation) % 4), at + Vector3(0, 0.002, 0), Vector3.ONE, data.get("tint", Color.WHITE))
				if data.trail_visible:
					add_piece("trail_%d" % (int(data.variation) % 8), at + Vector3(0, 0.035, 0), Vector3.ONE, Color("b2b29d"))
		if terrain != null:
			at.y = terrain.surface_height(Vector2(absolute) + Vector2(0.5, 0.5))
		if data.obstacle == 1:
			var trees: Array[PackedScene] = nature.hardy_trees if data.ground in [WorldTerrain.Ground.HEATH, WorldTerrain.Ground.MARSH] else nature.common_trees
			add_nature(trees[int(data.variation) % trees.size()], at, nature.tree_height * (0.85 + float(data.variation) * 0.05), float(data.variation) * 1.7, "tree")
			obstacle_count += 1
		elif data.obstacle == 2:
			add_nature(nature.rocks[int(data.variation) % nature.rocks.size()], at, nature.rock_height * (0.9 + float(data.variation) * 0.04), float(data.variation), "rock")
			obstacle_count += 1
		elif terrain != null and nature.composition != null and nature.composition.patch_at(terrain, absolute) != null:
			var patch: NaturePatch = nature.composition.patch_at(terrain, absolute)
			var record := nature.composition.placement(terrain, absolute, patch)
			if not record.is_empty():
				add_composed_nature(record)
		elif terrain != null and data.get("walkable", false) and not data.get("trail", false) and not terrain.is_camp(coord * 16 + Vector2i(index % 16, index / 16)) and not terrain.is_landmark(coord * 16 + Vector2i(index % 16, index / 16)):
			var cell := coord * 16 + Vector2i(index % 16, index / 16)
			var roll := terrain.roll(cell, 20261027)
			if roll % 100 < nature.undergrowth_percent:
				add_nature(nature.undergrowth[(roll / 100) % nature.undergrowth.size()], at, nature.undergrowth_height, float(roll % 628) / 100.0, "detail")
		tile_count += 1

static func neighbor_is_land(cells: Array[Dictionary], index: int, direction: Vector2i, terrain: WorldTerrain, coord: Vector2i) -> bool:
	var neighbor := Vector2i(index % 16, floori(float(index) / 16)) + direction
	if neighbor.x >= 0 and neighbor.x < 16 and neighbor.y >= 0 and neighbor.y < 16:
		return cells[neighbor.y * 16 + neighbor.x].ground != WorldTerrain.Ground.WATER
	if terrain != null:
		return terrain.sample(coord * 16 + neighbor).ground != WorldTerrain.Ground.WATER
	return false
