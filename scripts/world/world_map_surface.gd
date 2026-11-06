extends RefCounted
## Read-only terrain projection of a completed WorldMapPlan.
## GPU textures are built on the main thread. Workers only read the packed fields.

const Plan := preload("res://scripts/world/world_map_plan.gd")
const SCALE := Plan.WORLD_CELLS_PER_SAMPLE
const SEA_LEVEL := 0.0
const LOWLAND_RISE := 180.0
const MOUNTAIN_RISE := 460.0
const RIVER_DETAIL := 12
const RIVER_SIZE := Plan.SIZE * RIVER_DETAIL
const RIVER_CURVE_STEPS := 4
const CARDINAL := [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
# Match the material's layer order. The first four weights fit one RGBA atlas.
const GROUND_LAYERS := {
	Plan.Biome.COAST: 0, Plan.Biome.PLAINS: 1, Plan.Biome.HEATH: 2,
	Plan.Biome.JUNGLE: 3, Plan.Biome.DESERT: 4,
}
const GROUND_ALBEDOS := [
	preload("res://assets/terrain/lynocs/coast_albedo.png"),
	preload("res://assets/terrain/lynocs/plains_albedo.png"),
	preload("res://assets/terrain/lynocs/heath_albedo.png"),
	preload("res://assets/terrain/lynocs/jungle_albedo.png"),
	preload("res://assets/terrain/lynocs/desert_albedo.png"),
]
const GROUND_NORMALS := [
	preload("res://assets/terrain/lynocs/coast_normal.png"),
	preload("res://assets/terrain/lynocs/plains_normal.png"),
	preload("res://assets/terrain/lynocs/heath_normal.png"),
	preload("res://assets/terrain/lynocs/jungle_normal.png"),
	preload("res://assets/terrain/lynocs/desert_normal.png"),
]
const PALETTE := [
	Color("b5bc7c"), Color("527c5e"), Color("c7aa81"), Color("79ac9d"), Color("395f77"),
	Color("dfc894"), Color("d6a15e"), Color("286b49"), Color("b2a35a"), Color("b8b2a9"),
	Color("b9bfc3"), Color("537d78"), Color("4998b6"),
]
const LABELS := [
	"Meadow", "Woodland", "Heath", "Marsh", "Ocean", "Coast", "Desert",
	"Jungle", "Savanna", "Alpine", "Tundra", "Taiga", "Lake",
]

var _elevation: PackedFloat32Array
var _biomes: PackedByteArray
var _lakes: PackedFloat32Array
var _landform_offsets := PackedFloat32Array()
var _banks := PackedByteArray()
var _river_bytes := PackedByteArray()
var _river_regions := PackedByteArray()


func _init(plan: Plan, world_seed: int) -> void:
	var layers := plan.terrain_layers()
	_elevation = layers.elevation
	_biomes = layers.biome
	_lakes = layers.lake_level
	_banks.resize(_biomes.size())
	_river_regions.resize(_biomes.size())
	_river_bytes.resize(RIVER_SIZE.x * RIVER_SIZE.y)
	_build_banks()
	_build_rivers(layers.river_flow, layers.downstream, world_seed)
	_build_landforms(world_seed, layers.irrigation)


func make_material(shader: Shader, irrigation: PackedInt32Array) -> ShaderMaterial:
	var colors := PackedByteArray()
	colors.resize(_biomes.size() * 4)
	var ground_masks := PackedByteArray()
	ground_masks.resize(_biomes.size() * 2)
	var ground_weights := PackedByteArray()
	ground_weights.resize(_biomes.size() * 4)
	for index in _biomes.size():
		var biome := int(_biomes[index])
		var color: Color = PALETTE[biome]
		var offset := index * 4
		colors[offset] = color.r8
		colors[offset + 1] = color.g8
		colors[offset + 2] = color.b8
		colors[offset + 3] = 255 if _is_water(index) else 0
		ground_masks[index * 2] = 255 if irrigation[index] > 0 else 0
		var layer: int = GROUND_LAYERS.get(biome, -1)
		if layer == 4:
			ground_masks[index * 2 + 1] = 255
		elif layer >= 0:
			ground_weights[offset + layer] = 255
	var atlas := Image.create_from_data(Plan.SIZE.x, Plan.SIZE.y, false, Image.FORMAT_RGBA8, colors)
	var ground_atlas := Image.create_from_data(Plan.SIZE.x, Plan.SIZE.y, false, Image.FORMAT_RG8, ground_masks)
	var weight_atlas := Image.create_from_data(Plan.SIZE.x, Plan.SIZE.y, false, Image.FORMAT_RGBA8, ground_weights)
	var rivers := Image.create_from_data(RIVER_SIZE.x, RIVER_SIZE.y, false, Image.FORMAT_R8, _river_bytes)
	rivers.generate_mipmaps()
	var material := ShaderMaterial.new()
	material.shader = shader
	var atlas_texture := ImageTexture.create_from_image(atlas)
	material.set_shader_parameter("atlas_colors", atlas_texture)
	material.set_shader_parameter("atlas_flags", atlas_texture)
	material.set_shader_parameter("atlas_rivers", ImageTexture.create_from_image(rivers))
	material.set_shader_parameter("atlas_ground_masks", ImageTexture.create_from_image(ground_atlas))
	var ground_albedos := _make_ground_array(GROUND_ALBEDOS)
	var ground_normals := _make_ground_array(GROUND_NORMALS)
	if ground_albedos != null and ground_normals != null:
		material.set_shader_parameter("atlas_ground_weights", ImageTexture.create_from_image(weight_atlas))
		material.set_shader_parameter("ground_albedos", ground_albedos)
		material.set_shader_parameter("ground_normals", ground_normals)
		material.set_shader_parameter("ground_detail_enabled", true)
	material.set_shader_parameter("atlas_origin", Vector2(Plan.WORLD_ORIGIN))
	material.set_shader_parameter("atlas_extent", Vector2(Plan.SIZE * SCALE))
	return material


func _make_ground_array(textures: Array) -> Texture2DArray:
	var images: Array[Image] = []
	for texture: Texture2D in textures:
		var image := texture.get_image()
		if image == null or image.is_empty():
			return null
		if image.is_compressed() and image.decompress() != OK:
			return null
		image.convert(Image.FORMAT_RGBA8)
		if not image.has_mipmaps():
			image.generate_mipmaps()
		images.append(image)
	var layers := Texture2DArray.new()
	return layers if layers.create_from_images(images) == OK else null


func _southern_crest() -> Vector2i:
	var best := -1
	var highest := -1.0
	# Use a crest on the southern landmass, overlooking the central basin.
	for z in range(Plan.SIZE.y * 11 / 20, Plan.SIZE.y * 17 / 20):
		for x in range(Plan.SIZE.x * 7 / 20, Plan.SIZE.x * 4 / 5):
			var index := z * Plan.SIZE.x + x
			if not _is_water(index) and _elevation[index] > highest:
				highest = _elevation[index]
				best = index
	if best < 0:
		for index in _elevation.size():
			if not _is_water(index) and _elevation[index] > highest:
				highest = _elevation[index]
				best = index
		if best < 0:
			return Vector2i.ZERO
	return Vector2i(best % Plan.SIZE.x, best / Plan.SIZE.x)


func beach_spawn() -> Dictionary:
	var best := _southern_crest()
	var shore := Vector2i.ZERO
	var best_score := INF
	for index in _biomes.size():
		if _biomes[index] != Plan.Biome.COAST or _river_regions[index]:
			continue
		var cell := Vector2i(index % Plan.SIZE.x, index / Plan.SIZE.x)
		var edge := mini(mini(cell.x, Plan.SIZE.x - 1 - cell.x), mini(cell.y, Plan.SIZE.y - 1 - cell.y))
		if edge > mini(Plan.SIZE.x, Plan.SIZE.y) / 5:
			continue
		for direction: Vector2i in CARDINAL:
			var sea := _index(cell + direction)
			var inland := _index(cell - direction)
			if sea < 0 or _biomes[sea] != Plan.Biome.OCEAN or _is_water(inland):
				continue
			var right := Vector2i(direction.y, -direction.x)
			if _is_water(_index(cell + right)):
				continue
			var relief := _inland_relief(cell, -direction, right)
			var score := float(edge) * 0.35 + _elevation[index] * 20.0 - relief * 5.0
			if score < best_score:
				best = cell
				shore = direction
				best_score = score
	return {"cell": Plan.WORLD_ORIGIN + best * SCALE + Vector2i.ONE * (SCALE / 2) + shore * (SCALE / 4),
		"heading": -shore if shore != Vector2i.ZERO else Vector2i.UP}


func _inland_relief(coast: Vector2i, inland: Vector2i, right: Vector2i) -> float:
	# Score high ground in the opening view, inside the camera's visible range.
	var prominence := 0.0
	for distance in range(4, 57, 2):
		for flank: int in [-1, 0, 1]:
			var index := _index(coast + inland * distance + right * (distance * flank / 3))
			if not _is_water(index) and _elevation[index] > 0.44:
				prominence = maxf(prominence, (elevation_to_height(_elevation[index]) - 80.0) / distance)
	return prominence


func is_land(at: Vector2) -> bool:
	var atlas := (at - Vector2(Plan.WORLD_ORIGIN)) / SCALE
	return _shore_sample(atlas, _index(Vector2i(atlas.floor()))).x < 0.5


func planting_ground(at: Vector2) -> bool:
	var relative := at - Vector2(Plan.WORLD_ORIGIN)
	var atlas := relative / SCALE
	var index := _index(Vector2i(atlas.floor()))
	# Leave room between plant roots and the rendered shoreline or river mask.
	return _shore_sample(atlas, index).x < 0.20 and (not _river_regions[index] or _river_strength(relative) < 0.24)


func biome_name(at: Vector2) -> String:
	var index := _index_at(at)
	return LABELS[_biomes[index]] if index >= 0 else "Ocean"


static func elevation_to_height(elevation: float) -> float:
	# A monotonic curve keeps lake spill and drainage ordering while giving
	# the upper ranges much more relief than the lowlands.
	return SEA_LEVEL + elevation * (LOWLAND_RISE + MOUNTAIN_RISE * elevation * elevation)


func sample_height(at: Vector2, broad: FastNoiseLite, ridge: FastNoiseLite) -> float:
	var relative := at - Vector2(Plan.WORLD_ORIGIN)
	var atlas := relative / SCALE
	var index := _index(Vector2i(atlas.floor()))
	var shore := _shore_sample(atlas, index)
	if shore.x >= 0.5:
		return shore.y
	var p := (atlas - Vector2(0.5, 0.5)).clamp(Vector2.ZERO, Vector2(Plan.SIZE - Vector2i.ONE))
	var a := Vector2i(p.floor())
	var b := (a + Vector2i.ONE).min(Plan.SIZE - Vector2i.ONE)
	var f := p - Vector2(a)
	var nw := a.y * Plan.SIZE.x + a.x
	var ne := a.y * Plan.SIZE.x + b.x
	var sw := b.y * Plan.SIZE.x + a.x
	var se := b.y * Plan.SIZE.x + b.x
	var corners := Vector4i(nw, ne, sw, se)
	var weights := Vector4((1.0 - f.x) * (1.0 - f.y), f.x * (1.0 - f.y), (1.0 - f.x) * f.y, f.x * f.y)
	var top := lerpf(_elevation[nw], _elevation[ne], f.x)
	var bottom := lerpf(_elevation[sw], _elevation[se], f.x)
	var macro := lerpf(top, bottom, f.y)
	var landform := lerpf(lerpf(_landform_offsets[nw], _landform_offsets[ne], f.x),
		lerpf(_landform_offsets[sw], _landform_offsets[se], f.x), f.y)
	var meadow := 0.0
	var desert := 0.0
	for side in range(4):
		match _biomes[corners[side]]:
			Plan.Biome.PLAINS: meadow += weights[side]
			Plan.Biome.DESERT: desert += weights[side]
	var roughness := lerpf(0.7, 2.4, smoothstep(0.12, 0.36, macro))
	var local := broad.get_noise_2dv(at) * lerpf(roughness, 0.30, meadow)
	if desert > 0.0:
		# Follow a prevailing wind with drifting crests and gradual lee slopes.
		# The atlas weight tapers the dunes across biome boundaries.
		var wind := at.dot(Vector2(0.42, 0.91))
		var bend := ridge.get_noise_2dv(at * 1.6)
		var phase := (wind + bend * 64.0) / 116.0 * TAU
		var dune := sin(phase) + sin(phase * 2.0 + 0.65) * 0.18
		var dune_height := lerpf(3.2, 8.0, smoothstep(-0.62, 0.62, bend))
		landform += dune * dune_height * desert * (1.0 - smoothstep(0.28, 0.58, macro))
	# Elongated spurs and gullies break up high slopes at a mountain scale.
	var ridge_at := Vector2(at.x * 0.52 + at.y * 0.17, at.y - at.x * 0.24)
	var ribs := 1.0 - absf(ridge.get_noise_2dv(ridge_at))
	local += (smoothstep(0.24, 0.90, ribs) - 0.5) * 64.0 * smoothstep(0.32, 0.72, macro)
	# Sharper, narrower ribs gain height through the upper mountain ranges.
	var summit := smoothstep(0.45, 0.90, macro)
	if summit > 0.0:
		var crag := 1.0 - absf(ridge.get_noise_2dv(ridge_at * 2.7 + Vector2(83.0, -117.0)))
		local += (pow(crag, 3.0) - 0.45) * 38.0 * summit
	var surface := elevation_to_height(macro) + local
	if _river_regions[index]:
		var river := _river_strength(relative)
		surface -= river * 2.5
		landform *= 1.0 - smoothstep(0.0, 0.55, river)
	surface = maxf(SEA_LEVEL, surface + landform)
	# Ease the bank into the water plane at the same contour the shader uses.
	return lerpf(surface, shore.y, smoothstep(0.16, 0.5, shore.x))


func _build_landforms(world_seed: int, irrigation: PackedInt32Array) -> void:
	# Bake regional relief once. Both terrain meshes and traversal interpolate
	# the same offsets, including where two biome categories meet.
	var noise := FastNoiseLite.new()
	TerrainHeightfield.configure(noise, world_seed ^ 0x42f19, 0.12)
	_landform_offsets.resize(_biomes.size())
	for index in _biomes.size():
		if _is_water(index) or irrigation[index] > 0 or _river_regions[index]:
			continue
		var elevation := _elevation[index]
		var weight := 1.0 - smoothstep(0.34, 0.62, elevation)
		var height := elevation_to_height(elevation)
		var at := Vector2(index % Plan.SIZE.x, index / Plan.SIZE.x)
		var offset := 0.0
		match _biomes[index]:
			Plan.Biome.COAST:
				# Low, gently rising beach shelves.
				var bars := noise.get_noise_2dv(at * 1.4)
				offset = -height * 0.55 + smoothstep(0.0, 5.0, height) * maxf(0.0, bars) * 2.0
			Plan.Biome.PLAINS:
				# Broad, open ground with shallow folds instead of repeated hills.
				var folds := Vector2(at.x * 0.42 + at.y * 0.21, at.y * 0.63)
				offset = ((26.0 - height) * 0.72 + noise.get_noise_2dv(folds) * 3.5) \
					* smoothstep(4.0, 25.0, height)
			Plan.Biome.WOODLAND:
				# Broad shoulders frame elongated, lower hollows between them.
				var along := Vector2(at.x * 0.82 + at.y * 0.28, at.y * 0.48 - at.x * 0.15)
				var hollow := noise.get_noise_2dv(along)
				offset = 17.0 * smoothstep(0.10, 0.70, hollow) - 12.0 * smoothstep(0.10, 0.65, -hollow)
				offset -= 5.0 * smoothstep(0.48, 0.85, noise.get_noise_2dv(at * 1.4))
			Plan.Biome.HEATH:
				# Low wind-shaped sand ridges and open, dry saddles.
				var along := Vector2(at.x * 0.48 + at.y * 0.32, at.y - at.x * 0.45)
				var crest := 1.0 - absf(noise.get_noise_2dv(along))
				var notch := smoothstep(0.45, 0.80, noise.get_noise_2dv(at * 1.2))
				offset = smoothstep(0.30, 0.98, crest) * (32.0 - 11.0 * notch) - 13.0
			Plan.Biome.MARSH:
				# Broad low basins with broken raised margins. The atlas owns water.
				var basin := noise.get_noise_2dv(at * 0.72)
				var margin := smoothstep(0.0, 0.24, basin) * (1.0 - smoothstep(0.32, 0.66, basin))
				var hummocks := smoothstep(0.46, 0.82, noise.get_noise_2dv(at * 1.55))
				offset = 7.0 * margin - 8.0 * smoothstep(0.02, 0.55, -basin) + 5.0 * hummocks
			Plan.Biome.DESERT:
				# Long dune fronts with a broad windward slope and a shorter lee.
				var bend := noise.get_noise_2dv(at * 0.58)
				var phase := fposmod(at.dot(Vector2(0.33, 0.74)) + bend * 3.0, TAU) / TAU
				var dune := smoothstep(0.0, 0.71, phase) * (1.0 - smoothstep(0.71, 1.0, phase))
				offset = (dune - 0.35) * lerpf(23.0, 42.0, bend * 0.5 + 0.5)
				offset -= 6.0 * smoothstep(0.55, 0.90, -bend)
			Plan.Biome.JUNGLE:
				# Rounded hills with deeper hollows between them.
				var hills := noise.get_noise_2dv(at * 0.74)
				offset = 41.0 * pow(maxf(0.0, hills), 0.85) - 48.0 * pow(maxf(0.0, -hills), 0.80)
				offset += 8.0 * smoothstep(0.35, 0.78, noise.get_noise_2dv(at * 1.5))
			Plan.Biome.SAVANNA:
				# Flat-topped rises stand above wide, gently cut swales.
				var mesa := noise.get_noise_2dv(at * 0.66)
				offset = 16.0 * smoothstep(0.28, 0.60, mesa) - 5.0 * smoothstep(0.1, 0.65, -mesa)
			Plan.Biome.ALPINE:
				# Sharp ribs alternate with cols within the mountain belt.
				var spine := noise.get_noise_2dv(Vector2(at.x * 1.28, at.y * 0.82 + at.x * 0.35))
				offset = 27.0 * smoothstep(0.32, 0.80, spine) - 15.0 * smoothstep(0.28, 0.75, -spine)
				weight = smoothstep(0.62, 0.76, elevation)
			Plan.Biome.TUNDRA:
				# Wide high benches are broken by low frost ridges.
				var frost := noise.get_noise_2dv(Vector2(at.x * 0.77, at.y * 0.49 + at.x * 0.29))
				offset = 8.0 * smoothstep(0.14, 0.62, frost) - 6.0 * smoothstep(0.12, 0.65, -frost)
				weight = 1.0 - smoothstep(0.51, 0.62, elevation)
			Plan.Biome.TAIGA:
				# Long rounded ridges flank cool troughs.
				var trough := noise.get_noise_2dv(Vector2(at.x * 0.88 + at.y * 0.26, at.y * 0.42))
				offset = 13.0 * smoothstep(0.18, 0.70, trough) - 9.0 * smoothstep(0.10, 0.70, -trough)
		_landform_offsets[index] = maxf(offset, -height * 0.65) * weight


func water_depth(at: Vector2, seabed: FastNoiseLite) -> float:
	var relative := at - Vector2(Plan.WORLD_ORIGIN)
	var atlas := relative / SCALE
	var index := _index(Vector2i(atlas.floor()))
	var shore := _shore_sample(atlas, index)
	if shore.x < 0.5:
		return 1.35 * _river_strength(relative) if _river_regions[index] else 0.0
	var relief := seabed.get_noise_2dv(at * 0.35)
	if shore.y > SEA_LEVEL:
		var depth := clampf(shore.y - elevation_to_height(_elevation[index]), 0.8, 10.0)
		return depth * lerpf(0.85, 1.15, relief * 0.5 + 0.5) * smoothstep(0.5, 0.78, shore.x)
	# The shallow shelf meets the shore; broad offshore hollows deepen the bed.
	var depth := lerpf(6.0, 14.0, smoothstep(-0.50, 0.65, relief))
	return depth * smoothstep(0.5, 0.90, shore.x)


func _shore_sample(atlas: Vector2, index: int) -> Vector2:
	if index < 0:
		return Vector2(1.0, SEA_LEVEL)
	if not _banks[index]:
		return Vector2(float(_is_water(index)), _water_height(index))
	# Match the GPU's linear sampling of the water mask at atlas texel centers.
	var p := (atlas - Vector2(0.5, 0.5)).clamp(Vector2.ZERO, Vector2(Plan.SIZE - Vector2i.ONE))
	var a := Vector2i(p.floor())
	var b := (a + Vector2i.ONE).min(Plan.SIZE - Vector2i.ONE)
	var f := p - Vector2(a)
	var corners := Vector4i(a.y * Plan.SIZE.x + a.x, a.y * Plan.SIZE.x + b.x,
		b.y * Plan.SIZE.x + a.x, b.y * Plan.SIZE.x + b.x)
	var weights := Vector4((1.0 - f.x) * (1.0 - f.y), f.x * (1.0 - f.y), (1.0 - f.x) * f.y, f.x * f.y)
	var wet := 0.0
	var dominant_weight := -1.0
	var level := SEA_LEVEL
	for side in 4:
		if _is_water(corners[side]):
			wet += weights[side]
			if weights[side] > dominant_weight:
				dominant_weight = weights[side]
				level = _water_height(corners[side])
	return Vector2(wet, level)


func _build_banks() -> void:
	for index in _biomes.size():
		var wet := _is_water(index)
		var cell := Vector2i(index % Plan.SIZE.x, index / Plan.SIZE.x)
		for z in range(-1, 2):
			for x in range(-1, 2):
				if _is_water(_index(cell + Vector2i(x, z))) != wet:
					_banks[index] = 1
					break
			if _banks[index]:
				break


func _build_rivers(flow: PackedFloat32Array, downstream: PackedInt32Array, world_seed: int) -> void:
	var bend := FastNoiseLite.new()
	TerrainHeightfield.configure(bend, world_seed ^ 0x936bd, 0.26)
	var dominant := PackedInt32Array()
	dominant.resize(flow.size())
	dominant.fill(-1)
	for index in flow.size():
		var outlet := downstream[index]
		if flow[index] <= 0.0 or outlet < 0 or _is_water(index):
			continue
		var upstream := dominant[outlet]
		if upstream < 0 or flow[index] > flow[upstream]:
			dominant[outlet] = index
	for index in flow.size():
		var outlet := downstream[index]
		if flow[index] <= 0.0 or outlet < 0 or _is_water(index):
			continue
		var start := _river_point(index, bend)
		var finish := _river_point(outlet, bend)
		var before := start.lerp(finish, -1.0) if dominant[index] < 0 else _river_point(dominant[index], bend)
		var next := downstream[outlet]
		var after := finish.lerp(start, -1.0) if next < 0 or _is_water(outlet) else _river_point(next, bend)
		var start_radius := _river_radius(flow[index])
		var end_radius := _river_radius(maxf(flow[index], flow[outlet]))
		var previous := start
		for step in range(1, RIVER_CURVE_STEPS + 1):
			var t := float(step) / RIVER_CURVE_STEPS
			var point := start.cubic_interpolate(finish, before, after, t)
			var radius := lerpf(start_radius, end_radius, t - 0.5 / RIVER_CURVE_STEPS)
			_stamp_river(previous, point, radius)
			previous = point


func _river_point(index: int, bend: FastNoiseLite) -> Vector2:
	var point := Vector2(index % Plan.SIZE.x, index / Plan.SIZE.x) + Vector2(0.5, 0.5)
	# All tributaries share their junction. Coast and lake endpoints stay fixed.
	if not _is_water(index):
		point += Vector2(bend.get_noise_2dv(point), bend.get_noise_2dv(point + Vector2(91.0, 37.0))) * 0.24
	return point * RIVER_DETAIL


static func _river_radius(discharge: float) -> float:
	return clampf(1.2 + log(discharge / 140.0) * 0.65, 1.2, 4.65)


func _stamp_river(start: Vector2, finish: Vector2, radius: float) -> void:
	var margin := Vector2.ONE * (radius + 0.9)
	var low := Vector2i((start.min(finish) - margin).floor()).max(Vector2i.ZERO)
	var high := Vector2i((start.max(finish) + margin).ceil()).min(RIVER_SIZE - Vector2i.ONE)
	for z in range(low.y, high.y + 1):
		for x in range(low.x, high.x + 1):
			var p := Vector2(x + 0.5, z + 0.5)
			var distance := p.distance_to(Geometry2D.get_closest_point_to_segment(p, start, finish))
			var strength := roundi(255.0 * (1.0 - smoothstep(radius * 0.55, radius + 0.9, distance)))
			if strength > 0:
				var texel := z * RIVER_SIZE.x + x
				_river_bytes[texel] = maxi(_river_bytes[texel], strength)
				_river_regions[(z / RIVER_DETAIL) * Plan.SIZE.x + x / RIVER_DETAIL] = 1


func _river_strength(relative: Vector2) -> float:
	var p := (relative * (float(RIVER_DETAIL) / SCALE) - Vector2(0.5, 0.5)).clamp(
		Vector2.ZERO, Vector2(RIVER_SIZE - Vector2i.ONE))
	var a := Vector2i(p.floor())
	var b := (a + Vector2i.ONE).min(RIVER_SIZE - Vector2i.ONE)
	var f := p - Vector2(a)
	return lerpf(lerpf(_river_bytes[a.y * RIVER_SIZE.x + a.x], _river_bytes[a.y * RIVER_SIZE.x + b.x], f.x),
		lerpf(_river_bytes[b.y * RIVER_SIZE.x + a.x], _river_bytes[b.y * RIVER_SIZE.x + b.x], f.x), f.y) / 255.0


func _index_at(at: Vector2) -> int:
	return _index(Vector2i(((at - Vector2(Plan.WORLD_ORIGIN)) / SCALE).floor()))


func _index(cell: Vector2i) -> int:
	if cell.x < 0 or cell.y < 0 or cell.x >= Plan.SIZE.x or cell.y >= Plan.SIZE.y:
		return -1
	return cell.y * Plan.SIZE.x + cell.x


func _is_water(index: int) -> bool:
	return index < 0 or _biomes[index] == Plan.Biome.OCEAN or _biomes[index] == Plan.Biome.LAKE


func _water_height(index: int) -> float:
	return elevation_to_height(_lakes[index]) if index >= 0 and _biomes[index] == Plan.Biome.LAKE else SEA_LEVEL
