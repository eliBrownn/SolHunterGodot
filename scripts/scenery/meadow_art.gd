extends RefCounted
## Shared meadow rendering. Existing geography/route owners admit the ground;
## atmosphere supplies wind. Local licensed art is optional, never preloaded.
static var shared_mesh: ArrayMesh
static var material: ShaderMaterial

static func mesh() -> ArrayMesh:
	if shared_mesh != null: return shared_mesh
	material = ShaderMaterial.new()
	material.shader = preload("res://shaders/meadow.gdshader")
	var local_path := "res://assets/local/emace_grass/Materials/EA_Grass_Green.tres"
	if ResourceLoader.exists(local_path):
		var original: ShaderMaterial = load(local_path)
		var albedo: Texture2D = original.get_shader_parameter("albedo_texture")
		var image := albedo.get_image().duplicate() as Image
		if image.is_compressed(): image.decompress()
		image.generate_mipmaps()
		material.set_shader_parameter("albedo_texture", ImageTexture.create_from_image(image))
		material.set_shader_parameter("textured", true)
		var source: ArrayMesh = load("res://assets/local/emace_grass/Meshes/EA_Grass_Clump.mesh")
		shared_mesh = ArrayMesh.new()
		for surface in range(source.get_surface_count()):
			var arrays := source.surface_get_arrays(surface)
			# Imported vertex colors are asset masks, not our biome color.
			arrays[Mesh.ARRAY_COLOR] = null
			shared_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	else:
		var builder := SurfaceTool.new()
		builder.begin(Mesh.PRIMITIVE_TRIANGLES)
		for index in range(5):
			var rotation := Basis(Vector3.UP, float(index) * 2.4)
			for vertex in [Vector3(-0.2,0,0), Vector3(0.2,0,0), Vector3(0.12,1,0.08)]:
				builder.set_normal(Vector3.UP)
				builder.add_vertex(rotation * vertex)
		shared_mesh = builder.commit()
	var bounds := shared_mesh.get_aabb()
	material.set_shader_parameter("base_height", bounds.position.y)
	material.set_shader_parameter("blade_length", bounds.size.y)
	for surface in range(shared_mesh.get_surface_count()): shared_mesh.surface_set_material(surface, material)
	return shared_mesh

static func set_weather(direction: Vector2, rain: float) -> void:
	if material == null: return
	var airflow := direction.normalized() if direction.length_squared() > 0.0001 else Vector2.ZERO
	var strength := lerpf(0.14, 0.3, clampf(rain, 0.0, 1.0)) if airflow != Vector2.ZERO else 0.0
	material.set_shader_parameter("wind_strength", strength)
	material.set_shader_parameter("wind_direction", airflow)

static func add_cell(chunk: Node3D, terrain: WorldTerrain, cell: Vector2i, data: Dictionary, settings: NatureSettings) -> void:
	# Dense grass must not disguise an unscalable cell as an inviting hillside.
	if not settings.meadow_enabled or terrain.flora_kind(cell, data) != "plant": return
	var source := mesh()
	material.set_shader_parameter("ground_base_color", settings.ground_base_color)
	var tint := terrain.habitat_tint(cell) * settings.ground_tint_at(terrain, cell)
	var bounds := source.get_aabb()
	var key := "nature_detail_meadow"
	chunk.meshes[key] = source
	if not chunk.batches.has(key): chunk.batches[key] = []
	var divisions := clampi(settings.meadow_divisions, 2, 4)
	var source_registered := false
	for index in range(divisions * divisions):
		var roll := terrain.roll(cell, 94231 + index * 2)
		var offset := Vector2(float(index % divisions) + 0.15 + float(roll % 701) / 1000.0, float(index / divisions) + 0.15 + float((roll / 701) % 701) / 1000.0) / float(divisions)
		var point := Vector2(cell) + offset
		if terrain.surface_normal(point).y < 0.8: continue
		var height := settings.meadow_height * lerpf(0.8, 1.2, float(terrain.roll(cell, 94232 + index * 2) % 1001) / 1000.0)
		var factor := height / maxf(bounds.size.y, 0.001)
		var basis := Basis(Vector3.UP, float(roll % 6283) / 1000.0).scaled(Vector3.ONE * factor)
		var at := Vector3(point.x - chunk.cell_origin.x, terrain.surface_height(point) - bounds.position.y * factor, point.y - chunk.cell_origin.y)
		if not source_registered:
			chunk.register_living_source(cell, "detail", "meadow_grass", Vector3(point.x, terrain.surface_height(point) + height * 0.22, point.y))
			source_registered = true
		chunk.batches[key].append({"transform":Transform3D(basis, at), "color":tint})
