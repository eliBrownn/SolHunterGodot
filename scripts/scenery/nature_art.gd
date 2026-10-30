extends RefCounted
## Flatten imported scene transforms once, then reuse meshes in chunk MultiMeshes.

static var cache: Dictionary = {}
static var compact_cache: Dictionary = {}
static var tinted_cache: Dictionary = {}
static var foliage_materials: Dictionary = {}
static var foliage_textures: Dictionary = {}

static func foliage_material(source: Material) -> Material:
	if not source is BaseMaterial3D or source.transparency != BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR:
		return source
	if foliage_materials.has(source): return foliage_materials[source]
	var adapted: BaseMaterial3D = source.duplicate()
	adapted.alpha_antialiasing_mode = BaseMaterial3D.ALPHA_ANTIALIASING_ALPHA_TO_COVERAGE
	adapted.alpha_antialiasing_edge = adapted.alpha_scissor_threshold * 0.75
	adapted.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	adapted.roughness = 1.0
	adapted.metallic_specular = 0.0
	if source.albedo_texture != null:
		var texture: Texture2D = source.albedo_texture
		if not foliage_textures.has(texture):
			var image := texture.get_image().duplicate() as Image
			if image.is_compressed(): image.decompress()
			image.generate_mipmaps()
			foliage_textures[texture] = ImageTexture.create_from_image(image)
		adapted.albedo_texture = foliage_textures[texture]
	foliage_materials[source] = adapted
	return adapted

static func tint_parts(source: Dictionary, tint: Color) -> Dictionary:
	if tint == Color.WHITE or source.pieces.is_empty():
		return source
	var key := "%d:%d" % [source.pieces[0].mesh.get_instance_id(), hash(tint)]
	if tinted_cache.has(key):
		return tinted_cache[key]
	var result: Dictionary = source.duplicate()
	var pieces: Array[Dictionary] = []
	for piece in source.pieces:
		var mesh: ArrayMesh = piece.mesh.duplicate()
		for index in range(mesh.get_surface_count()):
			var material: Material = mesh.surface_get_material(index)
			if material is BaseMaterial3D:
				var colored: BaseMaterial3D = material.duplicate()
				colored.albedo_color *= tint
				mesh.surface_set_material(index, colored)
		pieces.append({"mesh": mesh, "transform": piece.transform})
	result.pieces = pieces
	tinted_cache[key] = result
	return result

static func compact_parts(scene: PackedScene) -> Dictionary:
	var key := scene.get_instance_id()
	if compact_cache.has(key):
		return compact_cache[key]
	var source := parts(scene)
	if not source.supported:
		return source
	# One static surface per shared material, rather than a draw for every stem,
	# fern frond or mushroom piece. SurfaceTool preserves the vertex attributes.
	var groups: Dictionary = {}
	for piece in source.pieces:
		for surface in range(piece.mesh.get_surface_count()):
			var material: Material = piece.mesh.surface_get_material(surface)
			if not groups.has(material):
				var builder := SurfaceTool.new()
				builder.begin(Mesh.PRIMITIVE_TRIANGLES)
				builder.set_material(material)
				groups[material] = builder
			groups[material].append_from(piece.mesh, surface, piece.transform)
	var pieces: Array[Dictionary] = []
	for material in groups:
		var mesh: ArrayMesh = groups[material].commit()
		preload("res://scripts/presentation/mesh_picking.gd").prepare(mesh)
		pieces.append({"mesh":mesh,"transform":Transform3D.IDENTITY})
	var result: Dictionary = source.duplicate()
	result.pieces = pieces
	compact_cache[key] = result
	return result

static func parts(scene: PackedScene) -> Dictionary:
	var key := scene.get_instance_id()
	if cache.has(key):
		return cache[key]
	var model := scene.instantiate()
	var pieces: Array[Dictionary] = []
	collect(model, Transform3D.IDENTITY, pieces)
	var supported := supported_static(model)
	var bounds := AABB()
	var triangles := 0
	var surfaces := 0
	for index in range(pieces.size()):
		var piece: Dictionary = pieces[index]
		var box: AABB = piece.transform * piece.mesh.get_aabb()
		bounds = box if index == 0 else bounds.merge(box)
		for surface in range(piece.mesh.get_surface_count()):
			surfaces += 1
			if not piece.mesh is PrimitiveMesh and (not piece.mesh is ArrayMesh or piece.mesh.surface_get_primitive_type(surface) != Mesh.PRIMITIVE_TRIANGLES):
				supported = false
				continue
			var arrays: Array = piece.mesh.surface_get_arrays(surface)
			var indices: Variant = arrays[Mesh.ARRAY_INDEX]
			triangles += (indices.size() if indices != null and not indices.is_empty() else arrays[Mesh.ARRAY_VERTEX].size()) / 3
	model.free()
	supported = supported and finite_box(bounds) and bounds.size.x > 0 and bounds.size.y > 0 and bounds.size.z > 0
	var result := {"pieces": pieces, "bounds": bounds, "supported": supported, "triangles": triangles, "surfaces": surfaces}
	cache[key] = result
	return result

static func finite_box(box: AABB) -> bool:
	return box.position.is_finite() and box.size.is_finite() and box.size.x >= 0 and box.size.y >= 0 and box.size.z >= 0

static func supported_static(node: Node) -> bool:
	# Fail admission rather than silently flatten hidden helpers, overrides or animation.
	if node is AnimationPlayer or node is AnimationTree or node is Skeleton3D:
		return false
	if node is Node3D and (not node.visible or not node.transform.is_finite() or node.is_set_as_top_level()):
		return false
	if node is MeshInstance3D:
		if node.mesh == null or node.material_override != null or node.material_overlay != null or node.skin != null:
			return false
		for surface in range(node.mesh.get_surface_count()):
			if node.get_surface_override_material(surface) != null or node.mesh.surface_get_material(surface) == null:
				return false
	for child in node.get_children():
		if not supported_static(child):
			return false
	return true

static func collect(node: Node, parent: Transform3D, result: Array[Dictionary]) -> void:
	var transform := parent
	if node is Node3D:
		transform = parent * node.transform
	if node is MeshInstance3D and node.mesh != null:
		var mesh: Mesh = node.mesh.duplicate()
		if mesh is ArrayMesh:
			for surface in range(mesh.get_surface_count()):
				mesh.surface_set_material(surface, foliage_material(mesh.surface_get_material(surface)))
		elif mesh is PrimitiveMesh:
			mesh.material = foliage_material(mesh.material)
		result.append({"mesh": mesh, "transform": transform})
	for child in node.get_children():
		collect(child, transform, result)
