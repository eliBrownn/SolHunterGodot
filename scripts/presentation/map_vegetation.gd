extends Node3D
## Bounded, presentation-only planting for the map-first world. A patch owns
## absolute sample positions, while residency follows the player's chunk.

const Plan := preload("res://scripts/world/world_map_plan.gd")
const Surface := preload("res://scripts/world/world_map_surface.gd")
const Community := preload("res://scripts/world/plant_community.gd")
const Art := preload("res://scripts/scenery/nature_art.gd")
const Meadow := preload("res://scripts/scenery/meadow_art.gd")
const Library := preload("res://scripts/scenery/plant_library.gd")
const TreeSpecies := preload("res://scripts/scenery/map_tree_species.gd")
const TreeLod := preload("res://scripts/presentation/map_tree_lod.gd")
const GroundLod := preload("res://scripts/presentation/map_ground_asset_lod.gd")
const PlantMesh := preload("res://scripts/scenery/plant_vastra_anatomy_mesh.gd")
const GROUND_RADIUS := 2
const GROUND_PROXY_STEP := 8
const TREE_REFERENCE_HEIGHT := 6.0
const MAX_GROUND_LOD_SCALE := 0.24
const CANOPY_RADIUS := 8
const GROUND_STEP := 2
const TREE_STEP := 8
const BANK_SEARCH := 12.0
const CARDINALS := [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]
const WORK_USEC := 1600
const MAX_CANDIDATES_PER_FRAME := 96
const SPAWN_CLEARANCE := 5.0

enum Plant { GRASS, OPEN_FAN, DIVIDED_FROND, OXIDE_THORN_CROWN, RIBBON_LEAVES,
	SALT_RIBBON, DUNE_PADDLE, SCREE_CUSHION, FROST_MAT, TREE_BASE }
const DEFAULT_TREE_SPECIES: Array[TreeSpecies] = [
	preload("res://resources/plants/map_tree_species/meadow_crimson_umbrella.tres"),
	preload("res://resources/plants/map_tree_species/woodland_blue_twin_arch.tres"),
	preload("res://resources/plants/map_tree_species/heath_bone_jointed_caudex.tres"),
	preload("res://resources/plants/map_tree_species/marsh_violet_stilt_curtain.tres"),
	preload("res://resources/plants/map_tree_species/meadow_new_plant.tres"),
	preload("res://resources/plants/map_tree_species/meadow_canopy_1.tres"),
	preload("res://resources/plants/map_tree_species/meadow_canopy_2.tres"),
	preload("res://resources/plants/map_tree_species/meadow_canopy_3.tres"),
	preload("res://resources/plants/map_tree_species/woodland_canopy_1.tres"),
	preload("res://resources/plants/map_tree_species/woodland_canopy_2.tres"),
	preload("res://resources/plants/map_tree_species/woodland_canopy_3.tres"),
	preload("res://resources/plants/map_tree_species/heath_canopy_1.tres"),
	preload("res://resources/plants/map_tree_species/heath_canopy_2.tres"),
	preload("res://resources/plants/map_tree_species/heath_canopy_3.tres"),
	preload("res://resources/plants/map_tree_species/marsh_canopy_1.tres"),
	preload("res://resources/plants/map_tree_species/marsh_canopy_2.tres"),
	preload("res://resources/plants/map_tree_species/marsh_canopy_3.tres"),
]
const BIOME_HUE_DEGREES := {
	Plan.Biome.PLAINS: 0.0, Plan.Biome.WOODLAND: 14.0, Plan.Biome.HEATH: -22.0,
	Plan.Biome.MARSH: 24.0, Plan.Biome.COAST: -12.0, Plan.Biome.DESERT: -38.0,
	Plan.Biome.JUNGLE: 34.0, Plan.Biome.SAVANNA: -29.0, Plan.Biome.ALPINE: 48.0,
	Plan.Biome.TUNDRA: 61.0, Plan.Biome.TAIGA: 43.0,
}
const GROUND_DESIGNS := {
	Plant.OPEN_FAN: "meadow_open_fan",
	Plant.DIVIDED_FROND: "woodland_divided_frond",
	Plant.OXIDE_THORN_CROWN: "heath_oxide_thorn_crown",
	Plant.RIBBON_LEAVES: "marsh_ribbon_leaves",
}
# New visual drafts reuse the Bible plants' growth vocabulary and mesh builder.
# These recipes stay local to map presentation until design review.
const NEW_DESIGNS := {
	Plant.SALT_RIBBON: {
		"name": "Salt ribbon", "base": 3, "height": 0.44, "seed": 237,
		"settings": {"height_ratio": 0.62, "leaf_architecture": 4, "biome_palette_variant": 1},
	},
	Plant.DUNE_PADDLE: {
		"name": "Dune paddle", "base": 2, "height": 0.48, "seed": 196,
		"settings": {"leaf_architecture": 3, "leaf_width": 1.55, "biome_palette_variant": 2},
	},
	Plant.SCREE_CUSHION: {
		"name": "Scree cushion", "base": 2, "height": 0.19, "seed": 123,
		"settings": {"height_ratio": 0.65, "spread_ratio": 1.2, "node_count": 10,
			"foliage_palette": 4},
	},
	Plant.FROST_MAT: {
		"name": "Frost mat", "base": 0, "height": 0.17, "seed": 346,
		"settings": {"height_ratio": 0.52, "spread_ratio": 1.5, "leaf_architecture": 2,
			"foliage_palette": 4, "hue_shift": 30.0},
	},
}

# Ground cover, fraction of cover that is foliage or scrub, and tree density.
const HABITATS := {
	Plan.Biome.COAST: Vector3(0.20, 0.14, 0.035),
	Plan.Biome.PLAINS: Vector3(0.82, 0.16, 0.045),
	Plan.Biome.WOODLAND: Vector3(0.58, 0.38, 0.64),
	Plan.Biome.HEATH: Vector3(0.27, 0.55, 0.05),
	Plan.Biome.MARSH: Vector3(0.65, 0.19, 0.08),
	Plan.Biome.DESERT: Vector3(0.10, 0.83, 0.025),
	Plan.Biome.JUNGLE: Vector3(0.78, 0.58, 0.78),
	Plan.Biome.SAVANNA: Vector3(0.46, 0.32, 0.15),
	Plan.Biome.ALPINE: Vector3(0.12, 0.68, 0.035),
	Plan.Biome.TUNDRA: Vector3(0.16, 0.60, 0.03),
	Plan.Biome.TAIGA: Vector3(0.38, 0.35, 0.48),
}
const TINTS := {
	Plan.Biome.COAST: Color("a6a866"),
	Plan.Biome.PLAINS: Color("698b37"),
	Plan.Biome.WOODLAND: Color("57743c"),
	Plan.Biome.HEATH: Color("89905b"),
	Plan.Biome.MARSH: Color("718d4a"),
	Plan.Biome.DESERT: Color("a8a16a"),
	Plan.Biome.JUNGLE: Color("4f843f"),
	Plan.Biome.SAVANNA: Color("a7a156"),
	Plan.Biome.ALPINE: Color("898a5d"),
	Plan.Biome.TUNDRA: Color("a8ad83"),
	Plan.Biome.TAIGA: Color("647c5b"),
}

var _plan: Plan
var _surface: Surface
var _height: Callable
var _terrain_ready: Callable
var _coverage := 0.0
var _plant_scale := 1.0
var _chunk_size := 64
var _spawn := Vector2i.ZERO
var _has_spawn := false
var _center := Vector2i.ZERO
var _ground := Community.new()
var _canopy := Community.new()
var _models := {}
var _species: Array[TreeSpecies]
var _biome_species := {}
var _biome_weights := {}
var _lod_camera := Vector2.INF
var _horizon_lod_root: Node3D
var _wanted := {}
var _pending: Array[Vector3i] = []
var _patches: Dictionary[Vector3i, Node3D] = {}
var _job: Dictionary = {}


func configure(plan: Plan, surface: Surface, seed_value: int, chunk_size: int,
		coverage: float, plant_scale: float, species: Array[TreeSpecies],
		height_at: Callable, terrain_ready: Callable) -> void:
	_plan = plan
	_surface = surface
	_chunk_size = chunk_size
	_coverage = clampf(coverage, 0.0, 1.0)
	_plant_scale = clampf(plant_scale, 0.5, 2.5)
	_height = height_at
	_terrain_ready = terrain_ready
	_ground.configure(seed_value ^ 0x5739b, 16.0, 1.0, 2.0, 0.0, 0)
	_canopy.configure(seed_value ^ 0x712d3, 24.0, 1.0, 4.0, 0.0, 1)
	_species = species.duplicate()
	for index in _species.size():
		var entry := _species[index]
		if entry == null or entry.model == null or entry.model.scene == null or entry.spawn_weight <= 0.0:
			continue
		for biome in entry.biomes:
			if not HABITATS.has(biome):
				continue
			if not _biome_species.has(biome):
				_biome_species[biome] = []
				_biome_weights[biome] = 0.0
			var candidates: Array = _biome_species[biome]
			if index not in candidates:
				candidates.append(index)
				_biome_weights[biome] += entry.spawn_weight
	set_process(false)


func cover(cell: Vector2i) -> void:
	if _coverage <= 0.0:
		return
	var center := Vector2i((Vector2(cell) / _chunk_size).floor())
	if _has_spawn and center == _center:
		return
	if not _has_spawn:
		_spawn = cell
		_has_spawn = true
	_center = center
	_wanted.clear()
	_pending.clear()
	for z in range(-CANOPY_RADIUS, CANOPY_RADIUS + 1):
		for x in range(-CANOPY_RADIUS, CANOPY_RADIUS + 1):
			var chunk := center + Vector2i(x, z)
			_wanted[Vector3i(chunk.x, chunk.y, 1)] = true
			_wanted[Vector3i(chunk.x, chunk.y, 2)] = true
			if maxi(absi(x), absi(z)) <= GROUND_RADIUS:
				_wanted[Vector3i(chunk.x, chunk.y, 0)] = true
	for key: Vector3i in _patches.keys():
		if not _wanted.has(key):
			var patch := _patches[key]
			remove_child(patch)
			patch.queue_free()
			_patches.erase(key)
	if not _job.is_empty() and not _wanted.has(_job.key):
		_job.clear()
	for key: Vector3i in _wanted:
		if not _patches.has(key) and (_job.is_empty() or key != _job.key):
			_pending.append(key)
	_pending.sort_custom(func(a: Vector3i, b: Vector3i) -> bool:
		var da := Vector2i(a.x, a.y).distance_squared_to(_center) * 2 + a.z
		var db := Vector2i(b.x, b.y).distance_squared_to(_center) * 2 + b.z
		return da < db if da != db else (a.y < b.y if a.y != b.y else a.x < b.x))
	set_process(true)


func _process(_delta: float) -> void:
	var camera := get_viewport().get_camera_3d()
	if camera != null:
		var position := Vector2(camera.global_position.x, camera.global_position.z)
		if _lod_camera.distance_squared_to(position) >= 4.0:
			_lod_camera = position
			_update_asset_lods(position)
	if _job.is_empty():
		for index in range(_pending.size()):
			var key := _pending[index]
			if not _terrain_ready.call(Vector2i(key.x, key.y)):
				continue
			_pending.remove_at(index)
			_job = {"key": key, "next": 0, "groups": {}}
			break
		if _job.is_empty():
			return
	var key: Vector3i = _job.key
	var origin := Vector2i(key.x, key.y) * _chunk_size
	var step: int = [GROUND_STEP, TREE_STEP, GROUND_PROXY_STEP][key.z]
	var width := _chunk_size / step
	var deadline := Time.get_ticks_usec() + WORK_USEC
	var stop := mini(width * width, int(_job.next) + MAX_CANDIDATES_PER_FRAME)
	while int(_job.next) < stop and Time.get_ticks_usec() < deadline:
		var index: int = _job.next
		var cell := origin + Vector2i(index % width, index / width) * step
		_job.next += 1
		# Sparse sites are a stable subset of the dense lattice, with one owner.
		if key.z == 0 and posmod(cell.x, GROUND_PROXY_STEP) == 0 and posmod(cell.y, GROUND_PROXY_STEP) == 0:
			continue
		var plant := _placement(cell, key.z == 1, origin)
		if not plant.is_empty():
			var groups: Dictionary = _job.groups
			var kind: int = plant.kind
			if not groups.has(kind):
				groups[kind] = []
			groups[kind].append(plant)
	if int(_job.next) == width * width:
		_publish(key, origin, _job.groups)
		_job.clear()


func _placement(cell: Vector2i, tree: bool, origin: Vector2i) -> Dictionary:
	var patch := _canopy if tree else _ground
	var step := TREE_STEP if tree else GROUND_STEP
	# One jittered site per absolute lattice square. A site's jitter stays
	# inside its square, so separate chunks never contend for ownership.
	var offset := Vector2(patch.roll(cell, 17), patch.roll(cell, 31))
	var point := Vector2(cell) + Vector2.ONE * (step * 0.5) + (offset - Vector2.ONE * 0.5) * (step * 0.72)
	if point.distance_squared_to(Vector2(_spawn) + Vector2(0.5, 0.5)) < SPAWN_CLEARANCE * SPAWN_CLEARANCE:
		return {}
	var ground := _plan.sample_world_cell(Vector2i(point.floor()))
	if not HABITATS.has(ground.biome):
		return {}
	var profile: Vector3 = HABITATS[ground.biome]
	var irrigated_dry: bool = ground.biome == Plan.Biome.PLAINS and ground.natural_biome in [Plan.Biome.DESERT, Plan.Biome.SAVANNA]
	var density: float
	var grove := 0.0
	if tree:
		if not _biome_species.has(ground.biome):
			return {}
		grove = smoothstep(0.34, 0.72, _canopy.patch_at(cell))
		density = _tree_density(ground, point, grove, profile.z, irrigated_dry)
	else:
		var field := smoothstep(0.18, 0.70, patch.patch_at(cell))
		var moisture := lerpf(0.65, 1.12, float(ground.soil_moisture))
		density = profile.x * moisture * lerpf(0.08, 1.45, field)
		if irrigated_dry:
			density *= 0.72
	var roll := patch.roll(cell, 52)
	if roll >= density * _coverage or not _surface.planting_ground(point):
		return {}
	var reach := 1.2 * _plant_scale if tree else 0.38
	var height: float = _height.call(point)
	var dx: float = _height.call(point + Vector2(reach, 0.0)) - _height.call(point - Vector2(reach, 0.0))
	var dz: float = _height.call(point + Vector2(0.0, reach)) - _height.call(point - Vector2(0.0, reach))
	var grade := Vector2(dx, dz).length() / (2.0 * reach)
	if grade > (0.425 if tree else 0.575):
		return {}
	if tree and roll >= density * _coverage * (1.0 - smoothstep(0.12, 0.425, grade)):
		return {}
	if ground.biome == Plan.Biome.DESERT:
		var shelter: float = (_height.call(point + Vector2(4.0, 0.0)) + _height.call(point - Vector2(4.0, 0.0))
			+ _height.call(point + Vector2(0.0, 4.0)) + _height.call(point - Vector2(0.0, 4.0))) * 0.25
		if height > shelter + 0.12:
			return {}
	if tree:
		for direction: Vector2 in CARDINALS:
			if not _surface.planting_ground(point + direction * reach):
				return {}
	var kind := _tree_kind(cell, ground.biome) if tree else _ground_kind(cell, profile.y)
	var tint: Color = TINTS[ground.natural_biome] if irrigated_dry else TINTS[ground.biome]
	if irrigated_dry:
		tint = tint.lerp(TINTS[Plan.Biome.PLAINS], 0.53)
	if kind == Plant.GRASS:
		tint = tint.lerp(Color.WHITE, patch.roll(cell, 91) * 0.18)
		tint.a = patch.roll(cell, 97)
	else:
		tint = Color.WHITE
	var size_roll := patch.roll(cell, 79)
	var height_scale := lerpf(0.70, 1.28, size_roll)
	if tree:
		# The same continuous grove field governs admission and mature size.
		var maturity := grove * (1.0 - smoothstep(0.12, 0.425, grade) * 0.45)
		height_scale = lerpf(0.72, 1.16, maturity) * lerpf(0.93, 1.07, size_roll)
	if kind == Plant.GRASS and ground.biome == Plan.Biome.MARSH:
		height_scale *= 1.35
	var basis := Basis(Vector3.UP, patch.roll(cell, 85) * TAU).scaled(Vector3.ONE * height_scale * _plant_scale)
	var at := Vector3(point.x - origin.x, height, point.y - origin.y)
	var record := {"kind": kind, "transform": Transform3D(basis, at), "color": tint}
	if tree:
		record.hue = tree_hue(ground.biome)
	return record


func _ground_kind(cell: Vector2i, foliage_fraction: float) -> int:
	if _ground.roll(cell, 68) >= foliage_fraction:
		return Plant.GRASS
	return Plant.OPEN_FAN + mini(int(_ground.roll(cell, 101) * (Plant.TREE_BASE - Plant.OPEN_FAN)),
		Plant.TREE_BASE - Plant.OPEN_FAN - 1)


func _tree_kind(cell: Vector2i, biome: int) -> int:
	var candidates: Array = _biome_species[biome]
	var roll: float = _canopy.roll(cell, 101) * _biome_weights[biome]
	for index: int in candidates:
		roll -= _species[index].spawn_weight
		if roll < 0.0:
			return Plant.TREE_BASE + index
	return Plant.TREE_BASE + int(candidates.back())


static func tree_hue(biome: int) -> float:
	return fposmod(float(BIOME_HUE_DEGREES.get(biome, 0.0)) / 360.0, 1.0)


func _update_asset_lods(camera: Vector2) -> void:
	for key: Vector3i in _patches:
		if key.z == 1:
			_set_tree_lod(_patches[key], camera)
		else:
			_set_ground_lods(_patches[key], camera)
	if is_instance_valid(_horizon_lod_root):
		for patch: Node3D in _horizon_lod_root.get_children():
			_set_tree_lod(patch, camera)


func activate_horizon_lods(root: Node3D) -> void:
	_horizon_lod_root = root
	if _lod_camera.is_finite():
		for patch: Node3D in root.get_children():
			_set_tree_lod(patch, _lod_camera)


func _patch_distance(root: Node3D, camera: Vector2) -> float:
	var bounds: Rect2 = root.get_meta("tree_bounds", Rect2(Vector2.ZERO, Vector2.ONE * _chunk_size))
	bounds.position += Vector2(root.global_position.x, root.global_position.z)
	return camera.distance_to(camera.clamp(bounds.position, bounds.end))


func _set_ground_lods(root: Node3D, camera: Vector2) -> void:
	var distance := _patch_distance(root, camera)
	for view: MultiMeshInstance3D in root.get_children():
		var kind: int = view.get_meta("ground_kind")
		var model: Dictionary = _models[kind]
		var previous: int = view.get_meta("asset_lod", -1)
		var level := TreeLod.tier(distance / float(model.lod_scale), previous)
		if level != previous:
			view.multimesh.mesh = model.levels[level]
			view.set_meta("asset_lod", level)


func _set_tree_lod(root: Node3D, camera: Vector2) -> void:
	var distance := _patch_distance(root, camera)
	var previous: int = root.get_meta("tree_lod", -1)
	var level := TreeLod.tier(distance, previous)
	if previous == level:
		return
	root.set_meta("tree_lod", level)
	for view: MultiMeshInstance3D in root.get_children():
		var kind: int = view.get_meta("tree_kind")
		view.multimesh.mesh = _models[kind].levels[level]


func _tree_density(ground: Dictionary, point: Vector2, grove: float, base: float, irrigated_dry: bool) -> float:
	var wet: float = ground.soil_moisture
	var warmth: float = ground.temperature
	match ground.biome:
		Plan.Biome.COAST, Plan.Biome.DESERT, Plan.Biome.ALPINE, Plan.Biome.TUNDRA:
			# Sparse sites in exposed biomes can still use the full canopy palette.
			return base * lerpf(0.35, 1.0, grove)
		Plan.Biome.WOODLAND, Plan.Biome.JUNGLE:
			# Dense interiors open up where the grove field is low.
			return base * lerpf(0.0, 1.75, grove) * smoothstep(0.29, 0.62, wet)
		Plan.Biome.TAIGA:
			var climate := smoothstep(0.19, 0.32, warmth) * smoothstep(0.24, 0.52, wet)
			return base * lerpf(0.02, 1.55, grove) * climate
		Plan.Biome.HEATH:
			# Dry exposed ridges thin out toward the treeline.
			var treeline := 1.0 - smoothstep(0.34, 0.59, float(ground.elevation))
			return base * grove * treeline * smoothstep(0.14, 0.36, wet)

	# Open country favors damp pockets and banks. In marshes, the root
	# footprint still has to fit on an exposed hummock or solid bank.
	var near_bank := false
	for direction: Vector2 in CARDINALS:
		if not _surface.planting_ground(point + direction * BANK_SEARCH):
			near_bank = true
			break
	if irrigated_dry:
		# Water can green the ground without turning a dry climate into woodland.
		return base * grove * (1.2 if near_bank else 0.16)
	if ground.biome == Plan.Biome.MARSH:
		return base * grove * (1.8 if near_bank else 0.35)
	return base * grove * smoothstep(0.18, 0.55, wet) * (1.8 if near_bank else 0.55)


func horizon_settings() -> Dictionary:
	if _coverage <= 0.0 or _biome_species.is_empty():
		return {}
	var weights := {}
	for biome: int in _biome_species:
		var cumulative := PackedFloat32Array()
		var sum := 0.0
		for index: int in _biome_species[biome]:
			sum += _species[index].spawn_weight
			cumulative.append(float(index))
			cumulative.append(sum)
		weights[biome] = cumulative
	return {"weights": weights, "coverage": _coverage, "scale": _plant_scale}


func sync_terrain_coverage() -> void:
	for key: Vector3i in _patches:
		_patches[key].visible = _terrain_ready.call(Vector2i(key.x, key.y))


func prepare_horizon_models(groups: Dictionary) -> bool:
	for kind: int in groups:
		if not _models.has(kind):
			_model(kind)
			return false
	return true


func publish_horizon_patch(parent: Node3D, data: Dictionary, surface_index: int) -> void:
	var patch := Node3D.new()
	patch.set_meta("terrain_surface", surface_index)
	patch.set_meta("tree_bounds", data.bounds)
	_add_batches(patch, data.groups, true, true)
	parent.add_child(patch)


func _publish(key: Vector3i, origin: Vector2i, groups: Dictionary) -> void:
	var root := Node3D.new()
	root.position = Vector3(origin.x, 0.0, origin.y)
	var count := _add_batches(root, groups, key.z == 1, false, key.z == 0)
	root.set_meta("plant_count", count)
	root.set_meta("placement_signature", hash(groups))
	add_child(root)
	_patches[key] = root
	if _lod_camera.is_finite():
		if key.z == 1:
			_set_tree_lod(root, _lod_camera)
		else:
			_set_ground_lods(root, _lod_camera)


func _add_batches(root: Node3D, groups: Dictionary, tree: bool, far: bool = false, dense: bool = false) -> int:
	var count := 0
	for kind: int in groups:
		var model := _model(kind)
		var rows: Array = groups[kind]
		for piece: Dictionary in model.pieces:
			var instances := MultiMesh.new()
			instances.transform_format = MultiMesh.TRANSFORM_3D
			instances.use_colors = true
			instances.use_custom_data = true
			instances.mesh = model.levels.back() if far else piece.mesh
			instances.instance_count = rows.size()
			for index in range(rows.size()):
				var record: Dictionary = rows[index]
				instances.set_instance_transform(index, record.transform * model.fit * piece.transform)
				instances.set_instance_color(index, record.color)
				if tree:
					instances.set_instance_custom_data(index, Color(record.hue, 0, 0, 1))
				else:
					instances.set_instance_custom_data(index, Color(model.lod_scale, float(dense), 1, 0))
			var view := MultiMeshInstance3D.new()
			view.name = model.name
			view.multimesh = instances
			view.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			if tree:
				view.set_meta("tree_kind", kind)
			else:
				view.set_meta("ground_kind", kind)
				# The shader fades individual plants. Allow for a whole patch's bounds.
				view.visibility_range_end = (96.0 if dense else GroundLod.fade_band().y * model.lod_scale) + _chunk_size
			root.add_child(view)
		if not model.pieces.is_empty():
			count += rows.size()
	return count


func _model(kind: int) -> Dictionary:
	if _models.has(kind):
		return _models[kind]
	if kind == Plant.GRASS:
		var blade := Meadow.mesh(1)
		var simple_blade := Meadow.mesh(1, null, 3)
		var material := GroundLod.material_for_map(blade.surface_get_material(0))
		var levels: Array[Mesh] = []
		for level in TreeLod.DISTANCES.size() + 1:
			var count := TreeLod.DISTANCES.size() - maxi(0, level - 1)
			var shape := blade if level == 0 else simple_blade
			var clump := SurfaceTool.new()
			clump.begin(Mesh.PRIMITIVE_TRIANGLES)
			clump.set_material(material)
			for index in count:
				var angle := float(index) * 2.39996
				var offset := Vector2.from_angle(angle) * lerpf(0.04, 0.19, float(index) / 6.0)
				var basis := Basis(Vector3.UP, angle).scaled(Vector3(1.2, 0.28 + 0.02 * index, 1.25))
				clump.append_from(shape, 0, Transform3D(basis, Vector3(offset.x, 0.0, offset.y)))
			levels.append(clump.commit())
		_models[kind] = _ground_model("Grass", levels, Transform3D.IDENTITY, levels[0].get_aabb().size.y)
		return _models[kind]
	var is_tree := kind >= Plant.TREE_BASE
	var definition: Resource
	var target: float
	var scene: PackedScene
	var name: String
	if NEW_DESIGNS.has(kind):
		var draft: Dictionary = NEW_DESIGNS[kind]
		name = draft.name
		target = draft.height
		scene = _draft_scene(draft)
	else:
		if is_tree:
			definition = _species[kind - Plant.TREE_BASE].model
		else:
			definition = Library.official_definition(GROUND_DESIGNS[kind])
		if definition != null:
			scene = definition.scene
			target = definition.world_height
			name = str(_species[kind - Plant.TREE_BASE].species_id) if is_tree else definition.plant_id
	var model := Art.compact_parts(scene) if scene != null else {"supported": false}
	if not model.supported or model.pieces.is_empty():
		_models[kind] = {"pieces": [], "fit": Transform3D.IDENTITY}
		return _models[kind]
	var bounds: AABB = model.bounds
	var base: Vector3 = definition.ground_offset(bounds) if definition != null else Vector3.ZERO
	var scale := target / maxf(bounds.end.y - base.y, 0.01)
	var width := maxf(bounds.size.x, bounds.size.z)
	var width_limit := _species[kind - Plant.TREE_BASE].canopy_width if is_tree else 1.5
	scale = minf(scale, width_limit / maxf(width, 0.01))
	var fit := Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * scale), -base * scale)
	if is_tree:
		var levels := TreeLod.build(model.pieces, bounds, definition.organ_graph)
		_models[kind] = {"name": name, "pieces": [{"mesh": levels[0], "transform": Transform3D.IDENTITY}],
			"fit": fit, "levels": levels}
	else:
		var levels := GroundLod.build(model.pieces, bounds)
		_models[kind] = _ground_model(name, levels, fit, (bounds.end.y - base.y) * scale)
	return _models[kind]


func _ground_model(name: String, levels: Array[Mesh], fit: Transform3D, height: float) -> Dictionary:
	var lod_scale := clampf(height * _plant_scale / TREE_REFERENCE_HEIGHT, 0.01, MAX_GROUND_LOD_SCALE)
	return {"name": name, "pieces": [{"mesh": levels[0], "transform": Transform3D.IDENTITY}],
		"fit": fit, "levels": levels, "lod_scale": lod_scale}


func _draft_scene(draft: Dictionary) -> PackedScene:
	var builder := PlantMesh.new()
	builder.tube_sides = 4
	var settings := {"branches": 6, "node_count": 7}
	settings.merge(draft.settings, true)
	var sample := builder.create_sample(draft.base, 0, draft.seed, settings, PlantMesh.make_anatomy_materials())
	var body := MeshInstance3D.new()
	body.mesh = sample.body
	var scene := PackedScene.new()
	scene.pack(body)
	body.free()
	return scene
