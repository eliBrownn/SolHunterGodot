extends SceneTree
## Production shoreline layers, depth attributes and unchanged terrain authority.
const Chunk = preload("res://scripts/presentation/solid_chunk.gd")
const Settings = preload("res://resources/water_appearance.tres")
var checks := 0
var failures := 0
var partial_cells := 0
var shoreline_vertices := 0

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		if failures <= 10:
			push_error(message)

func _initialize() -> void:
	run.call_deferred()

func inspect_chunk(t: WorldTerrain, coord: Vector2i) -> void:
	var cells := t.extract_chunk(coord)
	var chunk := Chunk.new()
	chunk.build_cells(cells, t, coord, preload("res://resources/nature_settings.tres"), 0, 256)
	var ground: Dictionary = {}
	for kind: String in chunk.terrain_surfaces:
		if kind != "ground":
			continue
		var arrays: Array = chunk.terrain_surfaces[kind]
		for first in range(0, arrays[Mesh.ARRAY_VERTEX].size(), 4):
			var vertex: Vector3 = arrays[Mesh.ARRAY_VERTEX][first]
			var local := Vector2i(roundi(vertex.x), roundi(vertex.z))
			ground[local] = true
			for index in range(first, first + 4):
				var at: Vector3 = arrays[Mesh.ARRAY_VERTEX][index]
				var shore: Vector2 = arrays[Mesh.ARRAY_TEX_UV2][index]
				# Low bit remains the bank flag; the next bit marks unscalable ground.
				if fmod(shore.y, 2.0) > 0.5:
					check(absf(shore.x - float(t.pond_at(coord * 16 + local).level)) < 0.000001, "Float32 bank attributes retain the real pond level within one micrometre")
					check(absf(at.y - t.vertex_height(coord * 16 + Vector2i(roundi(at.x), roundi(at.z)))) < 0.00001, "Bank material uses the exact shared terrain skin rather than a lifted mask")
	for index in range(256):
		if cells[index].ground != WorldTerrain.Ground.WATER:
			continue
		var local := Vector2i(index % 16, index / 16)
		var cell := coord * 16 + local
		var h := t.corners(cell)
		if maxf(maxf(h.x, h.y), maxf(h.z, h.w)) >= float(t.pond_at(cell).level):
			partial_cells += 1
			check(ground.has(local), "Partly wet cells retain the shared bank material: no bare sand triangles")
	if chunk.terrain_surfaces.has("water"):
		var water: Array = chunk.terrain_surfaces.water
		for index in range(0, water[Mesh.ARRAY_INDEX].size(), 3):
			var center := Vector3.ZERO
			var depth := 0.0
			for corner in range(3):
				var at: int = water[Mesh.ARRAY_INDEX][index + corner]
				var vertex: Vector3 = water[Mesh.ARRAY_VERTEX][at]
				var metadata: Vector2 = water[Mesh.ARRAY_TEX_UV2][at]
				center += vertex / 3
				depth += metadata.x / 3
				check(metadata.is_finite() and metadata.x >= 0 and metadata.y == 1, "Water depth attributes are finite and explicitly enabled")
				if metadata.x == 0:
					shoreline_vertices += 1
			var absolute := Vector2(center.x, center.z) + Vector2(coord * 16)
			check(absf(depth - (center.y - t.surface_height(absolute))) < 0.0001, "Interpolated visual depth matches the actual clipped ground triangle")
	chunk.free()
	check(cells == t.extract_chunk(coord), "Water appearance never changes generated cells or traversal")

func run() -> void:
	check(Settings.valid(), "Connected appearance defaults validate")
	var invalid := Settings.duplicate()
	invalid.ripple_strength = NAN
	check(not invalid.valid(), "Non-finite appearance tuning rejects")
	invalid = Settings.duplicate()
	invalid.ripple_noise = null
	check(not invalid.valid(), "Missing ripple texture rejects")
	var water: ShaderMaterial = Chunk.mesh_for("water").material
	check(water.get_shader_parameter("ripple_strength") == Settings.ripple_strength and water.get_shader_parameter("deep_color") == Settings.deep_color, "Actual water material uses the editable appearance resource")
	check(water.get_shader_parameter("ripple_noise") == Settings.ripple_noise, "Actual water shader uses the small connected seamless ripple texture")
	var bank: ShaderMaterial = Chunk.mesh_for("grass_0").surface_get_material(0)
	check(bank.get_shader_parameter("bank_blend_height") == Settings.bank_blend_height and bank.get_shader_parameter("wet_bank_color") == Settings.wet_bank_color, "Actual bank shader uses the same connected resource")
	var t := WorldTerrain.new()
	for area in [Vector2i.ZERO, Vector2i(-1, -1)]:
		var pond: Dictionary = t.geography.basins(t, area)[0]
		var center := t.chunk_of(Vector2i(pond.center))
		for offset in [Vector2i.ZERO, Vector2i.LEFT, Vector2i.UP, -Vector2i.ONE, Vector2i.RIGHT, Vector2i.DOWN]:
			inspect_chunk(t, center + offset)
	check(partial_cells > 20 and shoreline_vertices > 40, "Fixtures cover real partial shores across positive and negative chunks")
	var exploration: TerrainReliefSettings = load("res://resources/terrain_exploration.tres")
	var connected := WorldTerrain.new(2601026, {}, exploration.parameters())
	var channels := 0
	for pond: Dictionary in connected.geography.basins(connected, Vector2i(-1, -1)):
		if not pond.has("channel"): continue
		channels += 1
		var midpoint: Vector2 = pond.channel[1]
		var coord := connected.chunk_of(Vector2i(midpoint.floor()))
		inspect_chunk(connected, coord)
		inspect_chunk(connected, coord + Vector2i.RIGHT)
	check(channels > 0, "Production clipping and depth checks include a connected channel across chunks")
	print("WATER SHORELINE: %d checks, %d failures; %d partial cells." % [checks, failures, partial_cells])
	quit(0 if failures == 0 else 1)
