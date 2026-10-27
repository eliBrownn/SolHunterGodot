extends Node3D
## Batched solid geometry from prepared terrain data. No new generation or collision rules.

static var meshes: Dictionary = {}
var batches: Dictionary = {}
var tile_count := 0
var obstacle_count := 0

static func mesh_for(kind: String) -> Mesh:
	if meshes.has(kind):
		return meshes[kind]
	if kind.begins_with("grass_") or kind.begins_with("trail_") or kind.begins_with("sprite_") or kind.begins_with("asset:"):
		var pixel_mesh := pixel_mesh_for(kind)
		meshes[kind] = pixel_mesh
		return pixel_mesh
	var mesh: Mesh
	match kind:
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
		if kind == "wall":
			material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if kind == "water":
		material.roughness = 0.28
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
	arrays[Mesh.ARRAY_INDEX] = PackedInt32Array([0, 2, 1, 0, 3, 2])
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
	# The source artwork already carries its lighting and palette; retain it exactly.
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if standing:
		material.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
		material.billboard_keep_scale = true
	mesh.surface_set_material(0, material)
	return mesh

func add_piece(kind: String, at: Vector3, size: Vector3, color: Color, yaw: float = 0.0) -> void:
	if not batches.has(kind):
		batches[kind] = []
	var basis := Basis(Vector3.UP, yaw).scaled(size)
	batches[kind].append({"transform": Transform3D(basis, at), "color": color})

func finish() -> void:
	for kind: String in batches:
		var entries: Array = batches[kind]
		var instances := MultiMesh.new()
		instances.transform_format = MultiMesh.TRANSFORM_3D
		instances.use_colors = true
		instances.mesh = mesh_for(kind)
		instances.instance_count = entries.size()
		for index in range(entries.size()):
			instances.set_instance_transform(index, entries[index].transform)
			# MultiMesh instance colors are supplied in linear space.
			instances.set_instance_color(index, entries[index].color.srgb_to_linear())
		var view := MultiMeshInstance3D.new()
		view.name = kind.replace(":", "_").replace("/", "_")
		view.multimesh = instances
		add_child(view)
	batches.clear()

func build(cells: Array[Dictionary]) -> void:
	var palette := [Color("647d51"), Color("4c6949"), Color("938164"), Color("55796e"), Color("367e89"), Color("c4b183")]
	for index in range(cells.size()):
		var data: Dictionary = cells[index]
		var at := Vector3(index % 16 + 0.5, 0.0, floori(float(index) / 16) + 0.5)
		var shade: float = (float(data.variation) - 3.0) * 0.009
		var color: Color = palette[data.ground].lightened(shade)
		if data.ground == WorldTerrain.Ground.WATER:
			add_piece("water", at + Vector3(0, -0.30, 0), Vector3(1.002, 0.16, 1.002), color)
		else:
			add_piece("ground", at + Vector3(0, -0.35, 0), Vector3(1.002, 0.70, 1.002), color)
			add_piece("grass_%d" % (int(data.variation) % 4), at + Vector3(0, 0.002, 0), Vector3.ONE, data.get("tint", Color.WHITE))
			if data.trail_visible:
				add_piece("trail_%d" % (int(data.variation) % 8), at + Vector3(0, 0.035, 0), Vector3.ONE, Color("b2b29d"))
		if data.obstacle == 1:
			add_piece("sprite_tree_lower", at, Vector3.ONE, Color.WHITE)
			add_piece("sprite_tree_upper", at + Vector3(0, 63.0 / 32.0, 0), Vector3.ONE, Color.WHITE)
			obstacle_count += 1
		elif data.obstacle == 2:
			add_piece("sprite_rock", at, Vector3.ONE, Color.WHITE)
			obstacle_count += 1
		tile_count += 1
	finish()
