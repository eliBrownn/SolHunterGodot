class_name TerrainHeightfield
extends RefCounted
## Raw T0 landforms, not a replacement WorldTerrain generator. No world/save mutation.
## Canonical integer XZ vertices; each cell splits from (0,0) to (1,1).

const CONTRACT_VERSION := 3
var _seed: int
var _parameters: Dictionary
var _broad := FastNoiseLite.new()
var _detail := FastNoiseLite.new()
var _micro := FastNoiseLite.new()
var _origin_height := 0.0
var _landforms: Dictionary = {} # Bounded descriptor cache; order never changes output.

func _init(seed_value: int = 2601026, settings: TerrainReliefSettings = null) -> void:
	var selected := settings if settings != null and settings.valid() else TerrainReliefSettings.new()
	_seed = seed_value
	_parameters = selected.parameters().duplicate(true)
	configure(_broad, seed_value ^ 0x6a341, 1.0 / _parameters.broad_scale, int(_parameters.elevation_noise))
	configure(_detail, seed_value ^ 0x2b759, 1.0 / _parameters.detail_scale, int(_parameters.elevation_noise))
	configure(_micro, seed_value ^ 0x53c17, 1.0 / 8.0, int(_parameters.elevation_noise))
	_broad.domain_warp_enabled = _parameters.warp_amplitude > 0
	_broad.domain_warp_amplitude = _parameters.warp_amplitude
	_broad.domain_warp_frequency = 1.0 / 192.0
	_broad.domain_warp_fractal_type = FastNoiseLite.DOMAIN_WARP_FRACTAL_NONE
	_origin_height = raw_height(Vector2.ZERO)

static func configure(noise: FastNoiseLite, noise_seed: int, frequency: float, family: int = FastNoiseLite.TYPE_SIMPLEX_SMOOTH) -> void:
	noise.seed = noise_seed
	noise.noise_type = family
	noise.fractal_type = FastNoiseLite.FRACTAL_NONE
	noise.frequency = frequency

func snapshot() -> Dictionary:
	return {"contract_version": CONTRACT_VERSION, "seed": _seed,
		"parameters": _parameters.duplicate(true)}

static func valid_snapshot(value: Variant) -> bool:
	if not value is Dictionary:
		return false
	var version: Variant = value.get("contract_version")
	if not (version is int or version is float) or version != CONTRACT_VERSION:
		return false
	var seed_value: Variant = value.get("seed")
	return (seed_value is int or seed_value is float) and is_finite(float(seed_value)) and float(seed_value) == floor(float(seed_value)) and seed_value >= 0 and seed_value <= 2147483646 and TerrainReliefSettings.valid_parameters(value.get("parameters"))

static func restore(value: Dictionary) -> TerrainHeightfield:
	if not valid_snapshot(value):
		return null
	var settings := TerrainReliefSettings.new()
	for key in value.parameters:
		if key in settings.parameters():
			settings.set(key, value.parameters[key])
	return TerrainHeightfield.new(int(value.seed), settings)

func noise_height(at: Vector2) -> float:
	return _broad.get_noise_2d(at.x, at.y) * float(_parameters.broad_amplitude) + _detail.get_noise_2d(at.x, at.y) * float(_parameters.detail_amplitude) + _micro.get_noise_2d(at.x, at.y) * float(_parameters.micro_amplitude)

func landform_at(at: Vector2) -> Dictionary:
	var district := Vector2i(floori(at.x / 128.0), floori(at.y / 128.0))
	if not _landforms.has(district):
		var roll: int = ("landform-v1:%d:%d:%d" % [_seed, district.x, district.y]).hash()
		var center := Vector2(district * 128) + Vector2(52 + roll % 25, 52 + (roll / 29) % 25)
		if _landforms.size() >= 128:
			_landforms.erase(_landforms.keys()[0])
		_landforms[district] = {"kind": roll % 4, "center": center,
			"angle": float((roll / 997) % 6283) / 1000.0, "level": noise_height(center)}
	return _landforms[district].duplicate()

func raw_height(at: Vector2) -> float:
	var base := noise_height(at)
	var strength: float = _parameters.landform_strength
	if strength == 0:
		return base
	var form := landform_at(at)
	var local := (at - Vector2(form.center)).rotated(-float(form.angle))
	var radius := Vector2(local.x / 46.0, local.y / 34.0).length()
	if radius >= 1:
		return base
	var weight := 1.0 - smoothstep(0.65, 1.0, radius)
	match int(form.kind):
		0: # Long ridge with a lower central pass; independent of path placement.
			var spine := pow(maxf(0.0, 1.0 - absf(local.y) / 18.0), 2.0)
			var ends := 1.0 - smoothstep(18.0, 46.0, absf(local.x))
			var saddle := lerpf(0.35, 1.0, smoothstep(0.0, 10.0, absf(local.x)))
			return base + strength * 5.0 * spine * ends * saddle * weight
		1: # Enclosed depression; existing pond admission still decides actual water.
			return base - strength * 3.5 * pow(1.0 - radius * radius, 2.0)
		2: # Broad level shoulder with a softened escarpment.
			return lerpf(base, float(form.level) + strength * 4.0, weight)
		3: # Two broad terraces rather than repeated sinusoidal hills.
			var tiers := smoothstep(-22.0, -12.0, local.x) * 2.0 + smoothstep(4.0, 14.0, local.x) * 2.0
			return lerpf(base, float(form.level) + strength * tiers, weight)
	return base

func vertex_height(at: Vector2i) -> float:
	return raw_height(Vector2(at)) - _origin_height

func corners(cell: Vector2i) -> Vector4:
	return Vector4(vertex_height(cell), vertex_height(cell + Vector2i.RIGHT),
		vertex_height(cell + Vector2i.ONE), vertex_height(cell + Vector2i.DOWN))

static func interpolate(heights: Vector4, offset: Vector2) -> float:
	# NW, NE, SE, SW. Match the mesh triangles, not bilinear interpolation.
	if offset.y <= offset.x:
		return heights.x + (heights.y - heights.x) * offset.x + (heights.z - heights.y) * offset.y
	return heights.x + (heights.z - heights.w) * offset.x + (heights.w - heights.x) * offset.y

func surface_height(at: Vector2) -> float:
	var cell := Vector2i(floori(at.x), floori(at.y))
	return interpolate(corners(cell), at - Vector2(cell))

func surface_normal(at: Vector2) -> Vector3:
	var cell := Vector2i(floori(at.x), floori(at.y))
	var offset := at - Vector2(cell)
	var h := corners(cell)
	var gradient := Vector2(h.y - h.x, h.z - h.y) if offset.y <= offset.x else Vector2(h.z - h.w, h.w - h.x)
	return Vector3(-gradient.x, 1.0, -gradient.y).normalized()

func vertex_normal(at: Vector2i) -> Vector3:
	var dx := (vertex_height(at + Vector2i.RIGHT) - vertex_height(at + Vector2i.LEFT)) * 0.5
	var dz := (vertex_height(at + Vector2i.DOWN) - vertex_height(at + Vector2i.UP)) * 0.5
	return Vector3(-dx, 1.0, -dz).normalized()

func slope_degrees(at: Vector2) -> float:
	return rad_to_deg(acos(clampf(surface_normal(at).y, -1.0, 1.0)))
