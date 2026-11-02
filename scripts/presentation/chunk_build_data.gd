extends RefCounted
## Shared detached chunk calculations; scene publication belongs to SolidChunk.
const NatureArt = preload("res://scripts/scenery/nature_art.gd")
var prepared_buffers: Dictionary = {}
var prepared_groups: Dictionary = {}
var catalog: RefCounted
var meshes: Dictionary = {}
var surface_uvs: Dictionary = {}
var batches: Dictionary = {}
var build_biome_patches: Dictionary = {}
var cell_setup_count := 0
var terrain_surfaces: Dictionary = {}
var pick_objects: Array[Dictionary] = []
var tile_count := 0
var obstacle_count := 0
var shoreline_edges := 0
var cell_origin := Vector2i.ZERO
var cosmetic_records: Array[Dictionary] = []
var living_source_revision := 0
var living_sources: Dictionary = {}
var living_regions: Dictionary = {}
var terrain_vertex_cache: Dictionary = {}
var cell_work: Dictionary = {}

func retire_data_step() -> bool:
	cell_work.clear()
	catalog = null
	for records in [pick_objects,cosmetic_records]:
		if not records.is_empty():
			for index in range(mini(32,records.size())): records.pop_back()
			return false
	if not batches.is_empty():
		var key: Variant = batches.keys()[0]
		var rows: Array = batches[key]
		for index in range(mini(32,rows.size())): rows.pop_back()
		if rows.is_empty(): batches.erase(key)
		return false
	for records in [prepared_buffers,prepared_groups,terrain_surfaces,living_sources,living_regions,terrain_vertex_cache,build_biome_patches,meshes]:
		if not records.is_empty():
			records.erase(records.keys()[0])
			return false
	return true

func add_piece(kind: String, at: Vector3, size: Vector3, color: Color, yaw: float = 0.0) -> void:
	if not batches.has(kind):
		batches[kind] = []
	var basis := Basis(Vector3.UP, yaw).scaled(size)
	batches[kind].append({"transform": Transform3D(basis, at), "color": color})
	if kind in ["post", "prop", "wall", "roof"]:
		pick_objects.append({"transform": Transform3D(basis, at), "mesh": simple_mesh(kind).mesh, "bounds": simple_mesh(kind).bounds, "cell": Vector2i(Vector2(at.x, at.z).floor())})

## Publish one already-admitted site. This consumer never chooses placements.

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
		surface_uvs[source_kind] = load("res://scripts/presentation/solid_chunk.gd").mesh_for(source_kind).surface_get_arrays(0)[Mesh.ARRAY_TEX_UV]
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
		if not terrain_vertex_cache.has(cell):
			terrain_vertex_cache[cell] = {"tint": terrain.habitat_tint(cell) * nature.ground_tint_at(terrain, cell) if nature != null and not nature.biomes.is_empty() else Color.WHITE, "soil": NatureSettings.terrain_soil_at(terrain, cell), "blend": NatureSettings.terrain_blend_at(terrain, cell)}
		var cached: Dictionary = terrain_vertex_cache[cell]
		var vertex_color: Color = cached.tint if nature != null and not nature.biomes.is_empty() else color
		# Alpha is a presentation soil weight, derived from the existing biome owner.
		vertex_color.a = cached.soil
		arrays[Mesh.ARRAY_COLOR].append(vertex_color.srgb_to_linear())
		arrays[Mesh.ARRAY_CUSTOM0].append_array(cached.blend)
	arrays[Mesh.ARRAY_INDEX].append_array(PackedInt32Array([start, start + 1, start + 2, start, start + 2, start + 3]))
	terrain_surfaces[kind] = arrays

func register_living_source(cell: Vector2i, category: String, subject: String, anchor: Vector3, high_anchor: Vector3 = Vector3.INF, living: bool = true, presentation_priority: int = 0) -> void:
	if not living or category not in ["tree", "detail"]: return
	if not living_sources.has(cell) or (category == "tree" and living_sources[cell].kind != "tree") or presentation_priority > int(living_sources.get(cell,{}).get("priority",0)):
		living_source_revision += 1
		living_sources[cell] = {"priority":presentation_priority,"kind": category, "anchor": anchor, "high_anchor": high_anchor if high_anchor.is_finite() else anchor, "cell": cell, "flora_id": FloraCatalog.id_for(cell), "id": "%s:%d:%d:%.4f:%.4f" % [subject, cell.x, cell.y, anchor.x, anchor.z]}
		var owner := Vector2i(WorldTerrain.floor_div(cell.x, VastraSettings.SOURCE_REGION_SIZE), WorldTerrain.floor_div(cell.y, VastraSettings.SOURCE_REGION_SIZE))
		if not living_regions.has(owner): living_regions[owner] = {}
		living_regions[owner][cell] = living_sources[cell]

func add_nature(scene: PackedScene, at: Vector3, height: float, yaw: float, category: String, tint: Color = Color.WHITE, living: bool = true) -> void:
	# Imported plant bodies are retired even if an older caller requests them.
	if category in ["tree", "detail"]: return
	if scene.resource_path in preload("res://scripts/scenery/meadow_art.gd").SUPERSEDED_GRASS: return
	var model: Dictionary = catalog.scene_model(scene, tint, true) if catalog != null else NatureArt.tint_parts(NatureArt.compact_parts(scene), tint)
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
	for piece in (catalog.scene_model(scene, tint, false) if catalog != null else NatureArt.parts(scene)).pieces:
		pick_objects.append({"transform": base * piece.transform, "mesh": piece.mesh, "bounds": piece_bounds(piece), "cell": cell_origin + Vector2i(Vector2(at.x, at.z).floor()), "category": category, "vastra_anchor": Vector3(at.x + cell_origin.x, at.y + minf(height * 0.25, 0.9), at.z + cell_origin.y), "subject": scene.resource_path.get_file().get_basename().to_snake_case().replace("_", " ").capitalize()})

func add_composed_nature(record: Dictionary) -> void:
	if record.get("living", true) and record.get("patch", "") != "authored_plant": return
	if record.asset in preload("res://scripts/scenery/meadow_art.gd").SUPERSEDED_GRASS: return
	var transform: Transform3D = record.transform
	transform.origin -= Vector3(cell_origin.x, 0, cell_origin.y)
	var tint: Color = record.get("tint", Color.WHITE)
	var category: String = record.get("category","detail")
	var visibility_group := "grass" if record.get("ground_cover",false) else "tree" if category == "tree" else "detail"
	var anchor: Vector3 = record.get("vastra_anchor",record.transform * Vector3(record.model.bounds.get_center().x,record.model.bounds.position.y+minf(record.model.bounds.size.y*0.3,0.35),record.model.bounds.get_center().z))
	var model: Dictionary = catalog.tint_model(record.model, tint) if catalog != null else NatureArt.tint_parts(record.model, tint)
	for index in range(model.pieces.size()):
		var piece: Dictionary = model.pieces[index]
		# Keep the same asset in distinct presentation groups when it is reused
		# as a full plant and as ground cover. Category never changes ecology.
		var key := "nature_detail_%s_%d_%d_%s" % [record.asset, index, hash(tint), visibility_group]
		meshes[key] = piece.mesh
		if not batches.has(key):
			batches[key] = []
		var entry := {"transform":transform*piece.transform,"color":Color.WHITE,"visibility_group":visibility_group}
		if record.get("living",true) and category in ["tree","detail"]:
			entry["plant_cell"]=record.cell
			entry["plant_pivot"]=Vector3(record.cell.x+0.5-cell_origin.x,record.bounds.position.y,record.cell.y+0.5-cell_origin.y)
		batches[key].append(entry)
		# Grass retains terrain/canonical-cell interaction, as blade grass did.
		# Its soft leaves must not become solid actor-clearance obstacles.
		if not record.get("ground_cover",false):
			pick_objects.append({"transform": transform * piece.transform, "mesh": piece.mesh, "bounds": piece_bounds(piece), "cell": record.cell, "category": category, "vastra_anchor": anchor, "subject": record.get("subject", record.asset.get_file().get_basename().replace("_", " ").capitalize())})
	if not record.get("preserve_body",false):
		register_living_source(record.cell, category, record.get("subject",record.asset), anchor, record.get("high_anchor",Vector3.INF), record.get("living", true))
		if living_sources.has(record.cell) and record.has("vastra_organs"):
			living_sources[record.cell]["organs"] = record.vastra_organs.duplicate(true)
			living_source_revision += 1
	var stable := record.duplicate()
	stable.erase("model")
	# The canonical living source owns anatomy; placement comparisons need only
	# stable asset/cell/transform data, not thousands of repeated organ graphs.
	stable.erase("vastra_organs")
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

func prepare_cell_build(terrain: WorldTerrain,coord: Vector2i,nature: NatureSettings) -> void:
	terrain_vertex_cache.clear()
	cell_setup_count+=1
	cell_origin = coord * 16
	build_biome_patches.clear()
	if terrain != null:
		for biome in nature.biomes:
			build_biome_patches[biome.ground] = biome.detail_patch(terrain, coord)

## Same deterministic geometry path as build(), with bounded cell ranges.

func build_cells(cells: Array[Dictionary], terrain: WorldTerrain, coord: Vector2i, nature: NatureSettings, first: int, count: int) -> void:
	for index in range(first, mini(first + count, cells.size())):
		while not build_cell_step(cells,terrain,coord,nature,index): pass


## One ground, plant or dressing operation. No partial chunk is published.

func build_cell_step(cells: Array[Dictionary], terrain: WorldTerrain, coord: Vector2i, nature: NatureSettings, index: int) -> bool:
	if cell_work.is_empty():
		if cell_setup_count==0: prepare_cell_build(terrain,coord,nature)
		build_cell_ground(cells,terrain,coord,nature,index)
		cell_work={"plant":{},"body":{}}
		if terrain != null:
			cell_work.plant=preload("res://scripts/scenery/plant_library.gd").begin_cell(self,terrain,coord*16+Vector2i(index%16,index/16),cells[index],nature,catalog)
		return false
	if not cell_work.plant.is_empty():
		if not preload("res://scripts/scenery/plant_library.gd").advance_cell(cell_work.plant): return false
		cell_work.body=cell_work.plant.body
		cell_work.plant={}
		return false
	build_cell_dressing(cells,terrain,coord,nature,index,cell_work.body)
	cell_work.clear()
	return true

func build_cell_ground(cells: Array[Dictionary], terrain: WorldTerrain, coord: Vector2i, nature: NatureSettings, index: int) -> void:
	var palette := [Color("647d51"), Color("4c6949"), Color("938164"), Color("55796e"), Color("367e89"), Color("c4b183")]
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

func build_cell_dressing(cells: Array[Dictionary], terrain: WorldTerrain, coord: Vector2i, nature: NatureSettings, index: int, authored_plant: Dictionary) -> void:
	var data: Dictionary=cells[index]
	var absolute := coord*16+Vector2i(index%16,index/16)
	var at := Vector3(index%16+0.5,0.0,floori(float(index)/16)+0.5)
	if terrain != null: at.y=terrain.surface_height(Vector2(absolute)+Vector2(0.5,0.5))
	var biome: NatureBiomePalette=nature.biome_for(data.ground)
	var biome_patches := build_biome_patches
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
		var record := NatureComposition.placement_for(terrain, absolute, biome_patches[data.ground], biome.cluster_cells, biome.cluster_fill, biome.scale_variation, true, false, true, false)
		if not record.is_empty() and not record.get("living", true):
			record.tint = biome.detail_tint
			add_composed_nature(record)
	elif terrain != null and nature.composition != null and nature.composition.patch_at(terrain, absolute) != null:
		var patch: NaturePatch = nature.composition.patch_at(terrain, absolute)
		var record := nature.composition.placement(terrain, absolute, patch, false)
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

func simple_mesh(kind: String) -> Dictionary:
	if catalog != null: return catalog.simple[kind]
	var mesh: Mesh = load("res://scripts/presentation/solid_chunk.gd").mesh_for(kind)
	return {"mesh":mesh,"bounds":mesh.get_aabb()}

func piece_bounds(piece: Dictionary) -> AABB:
	return piece.bounds if piece.has("bounds") else piece.mesh.get_aabb()
