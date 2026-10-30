extends SceneTree
## Shared physical vertices must carry identical blend weights across chunks/LODs.
const Chunk = preload("res://scripts/presentation/solid_chunk.gd")
const Coverage = preload("res://scripts/presentation/streaming_ground.gd")
var failures := 0
var checks := 0
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)
func _initialize() -> void:
	run.call_deferred()
func run() -> void:
	var nature: NatureSettings = load("res://resources/nature_settings.tres")
	check(nature.valid(), "Connected terrain tuning validates")
	check(nature.terrain_palette.get_layers() == 13 and nature.terrain_palette.get_width() == 1024, "Runtime palette retains the entire compact library")
	check(nature.terrain_normals.get_layers() == 13 and nature.terrain_normals.get_width() == nature.terrain_palette.get_width(), "Provided normal layers match the color palette")
	check(nature.terrain_heights.get_layers() == 13, "Provided displacement layers cover every terrain material")
	var material := ShaderMaterial.new()
	material.shader = load("res://shaders/shore_ground.gdshader")
	nature.apply_terrain_material(material)
	check(material.get_shader_parameter("terrain_normals") == nature.terrain_normals, "Terrain material receives the supplied normal palette")
	check(material.get_shader_parameter("terrain_heights") == nature.terrain_heights, "Terrain material receives supplied displacement")
	check(material.get_shader_parameter("terrain_relief_depth") == nature.terrain_relief_depth, "Connected parallax depth matches tuning")
	check(material.get_shader_parameter("terrain_cliff_start_degrees") == nature.terrain_cliff_start_degrees and material.get_shader_parameter("terrain_cliff_full_degrees") == nature.terrain_cliff_full_degrees, "Cliff texture slope tuning reaches the shared material")
	for angles in [Vector2(52,32),Vector2(32,32),Vector2(-1,52),Vector2(32,90),Vector2(NAN,52),Vector2(32,INF)]:
		var tuning := nature.duplicate()
		tuning.terrain_cliff_start_degrees = angles.x
		tuning.terrain_cliff_full_degrees = angles.y
		check(not tuning.valid(), "Invalid or reversed cliff slope transitions reject")
	for property in ["terrain_relief_distance", "terrain_normal_distance"]:
		var tuning := nature.duplicate()
		tuning.set(property, 0.0)
		check(tuning.valid(), "Zero distance permits full-detail comparison")
		tuning.apply_terrain_material(material)
		check(is_zero_approx(float(material.get_shader_parameter(property))), "Distance comparison reaches the terrain shader")
		for invalid_distance in [-1.0, 129.0, NAN, INF]:
			tuning.set(property, invalid_distance)
			check(not tuning.valid(), "Invalid terrain detail distance rejects")
	var bad_depth := nature.duplicate()
	bad_depth.terrain_relief_depth = NAN
	check(not bad_depth.valid(), "Non-finite parallax depth rejects")
	var bad_normals := nature.duplicate()
	bad_normals.terrain_normals = null
	check(not bad_normals.valid(), "Missing provided normals rejects")
	var terrain := WorldTerrain.new()
	for coord in [Vector2i(-1, 0), Vector2i.ZERO, Vector2i(1, 0)]:
		var before := terrain.extract_chunk(coord)
		var chunk := Chunk.new()
		for index in range(256):
			chunk.add_terrain_tile("grass_0", terrain, coord, index, Color.WHITE, 0.0, nature)
		var near: Array = chunk.terrain_surfaces["grass_0"]
		var by_vertex := {}
		var blend_by_vertex := {}
		for i in range(near[Mesh.ARRAY_VERTEX].size()):
			var p: Vector3 = near[Mesh.ARRAY_VERTEX][i]
			var absolute: Vector2i = coord * 16 + Vector2i(roundi(p.x), roundi(p.z))
			var alpha: float = near[Mesh.ARRAY_COLOR][i].a
			if by_vertex.has(absolute): check(is_equal_approx(by_vertex[absolute], alpha), "Adjacent terrain tiles share soil/path weights")
			by_vertex[absolute] = alpha
			var weights: PackedFloat32Array = near[Mesh.ARRAY_CUSTOM0]
			var blend := Vector2(weights[i*2],weights[i*2+1])
			if blend_by_vertex.has(absolute): check(blend_by_vertex[absolute].is_equal_approx(blend),"Adjacent tiles share independent trail/soil blends")
			blend_by_vertex[absolute] = blend
		var mesh := Coverage.build(terrain, coord, 4, nature)
		var distant: Array = mesh.surface_get_arrays(0)
		# First 64 vertices are the 16 coverage quads; skirts follow afterwards.
		for i in range(64):
			var p: Vector3 = distant[Mesh.ARRAY_VERTEX][i]
			var absolute: Vector2i = coord * 16 + Vector2i(roundi(p.x), roundi(p.z))
			var weights: PackedFloat32Array = distant[Mesh.ARRAY_CUSTOM0]
			check(blend_by_vertex[absolute].is_equal_approx(Vector2(weights[i*2],weights[i*2+1])),"Detailed and streaming meshes share exact trail/soil weights")
			# ArrayMesh packs uploaded vertex colors into 8-bit channels.
			check(absf(by_vertex[absolute] - distant[Mesh.ARRAY_COLOR][i].a) <= 1.0 / 255.0 + 0.0001, "Close and distant coverage agree at shared vertices")
		check(before == terrain.extract_chunk(coord), "Materials preserve terrain and traversal data")
		chunk.free()
		var production := Chunk.new()
		production.build(before,terrain,coord,nature)
		var skin: Array = production.get_node("ground").mesh.surface_get_arrays(0)
		check(skin[Mesh.ARRAY_VERTEX].size() == 256*4, "Each cell contributes exactly one canonical ground skin, including pond beds")
		for child in production.get_children():
			check(not child.name.begins_with("grass_") and not child.name.begins_with("trail_"), "Default terrain has no nearly coplanar turf or trail overlays")
		check(production.get_node("ground").mesh.surface_get_material(0).shader == material.shader, "The single ground skin retains textured shore and cliff shading")
		production.free()
	var invalid := nature.duplicate()
	var probe := Vector2i(-17, 9)
	var expected := NatureSettings.terrain_blend_at(terrain, probe)
	var edited := NatureSettings.terrain_blend_at(terrain, probe)
	edited[0] = -100.0
	check(NatureSettings.terrain_blend_at(terrain, probe) == expected, "Returned material weights cannot mutate cached values")
	var other := WorldTerrain.new(42)
	NatureSettings.terrain_blend_at(other, probe)
	check(NatureSettings._weight_source.get_ref() == other, "Material cache switches with expedition ownership")
	check(NatureSettings.terrain_blend_at(terrain, probe) == expected, "Returning to another terrain reconstructs identical weights")
	NatureSettings._vertex_weights.clear()
	check(NatureSettings.terrain_blend_at(terrain, probe) == expected, "Discarding material cache preserves terrain appearance")
	invalid.terrain_tile_size = NAN
	check(not invalid.valid(), "Non-finite repeat size rejects")
	print("TERRAIN MATERIALS: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)


