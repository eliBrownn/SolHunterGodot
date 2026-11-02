extends RefCounted
## Assembly owns arrangement; existing relic generator owns the reusable stone geometry.
const VERSION := 3
const Recipe = preload("res://scripts/scenery/stone_obstacle_definition.gd")
const Stone = preload("res://scripts/scenery/procedural_relic.gd")
const Carving = preload("res://scripts/scenery/relic_carving.gd")
const Surfaces = preload("res://scripts/scenery/structure_stone_materials.gd")
const Materials = preload("res://scripts/scenery/relic_materials.gd")
const NAMES := ["Barrier", "Corner", "Horseshoe", "Pillars", "Stepped outcrop", "Broken enclosure", "Monolith cluster", "Broken gateway", "Split ring", "Layered remnant"]
# Base assets selected from actual relic layouts; no whole relic is instantiated.
static func module_asset(key: String) -> Dictionary:
	if key in ["column", "capital"]:
		for part in Stone.layout(6, 73, 1.0, 0.0, 0).parts:
			if part.id == ("column_0" if key == "column" else "capital_0"): return part.duplicate(true)
		return {}
	var source_family := {"block": 3, "slab": 3, "pier": 2, "taper": 5, "arch": 2, "rubble": 1, "foot": 1}[key] as int
	var source_id: String = {"block": "wall_0_0", "slab": "slab_0_0", "pier": "pier_-1_0", "taper": "tapered_spire_0_3", "arch": "arch_0", "rubble": "rubble_0", "foot": "footing"}[key]
	for part in Stone.layout(source_family, 73, 1.0, 0.0, 1).parts:
		if part.id == source_id: return part.duplicate(true)
	return {}

static func layout(recipe: Resource) -> Dictionary:
	if not recipe is Recipe or not recipe.valid(): return {}
	if recipe.family >= 6: return large_layout(recipe)
	var anchors: Array[Vector2i] = []
	for x in range(recipe.length):
		anchors.append(Vector2i(x, 0))
	if recipe.family in [1, 2, 5]:
		for z in range(1, recipe.length): anchors.append(Vector2i(0, z))
	if recipe.family in [2, 5]:
		for z in range(1, recipe.length): anchors.append(Vector2i(recipe.length - 1, z))
	if recipe.family == 5:
		for x in range(1, recipe.length - 1):
			if x != recipe.length / 2: anchors.append(Vector2i(x, recipe.length - 1))
	if recipe.family == 3:
		anchors.clear()
		for x in range(3): anchors.append(Vector2i(x * 2, 0))
	if recipe.family == 4:
		anchors.clear()
		for z in range(3):
			for x in range(recipe.length): anchors.append(Vector2i(x, z))
	var parts: Array[Dictionary] = []
	var bounds := AABB()
	for anchor in anchors:
		var key := "%d/%d" % [anchor.x, anchor.y]
		var rng := RandomNumberGenerator.new()
		rng.seed = hash("obstacle/%d/%d/%d/%s/height" % [VERSION, recipe.family, recipe.seed_value, key])
		var count: int = maxi(1, recipe.courses - floori(rng.randf() * recipe.brokenness * recipe.courses))
		if recipe.family == 4: count = maxi(1, recipe.courses - anchor.y)
		var base_module: String = ["block", "pier", "block", "pier", "slab", "block"][recipe.family]
		var bottom := 0.0
		for tier in range(count):
			var module := base_module
			if tier == count - 1:
				module = ["slab", "arch", "taper", "taper", "slab", "arch"][recipe.family]
			var asset := module_asset(module)
			var size: Vector3 = asset.size * recipe.object_scale
			# Module envelopes keep neighbouring columns clear; heights retain asset proportions.
			var fit := minf(1.0, 0.96 * recipe.object_scale / maxf(size.x, size.z))
			size *= fit
			var at := Vector3(anchor.x, 0, anchor.y) * float(recipe.object_scale)
			at.y = bottom + size.y / 2
			bottom += size.y
			asset.id = "%s/%d" % [key, tier]
			asset.at = at
			asset.size = size
			asset.roll = 0.0
			asset.yaw = 0.0
			asset["module"] = module
			parts.append(asset)
			var box := AABB(at - size / 2, size)
			bounds = box if parts.size() == 1 else bounds.merge(box)
	# Detail uses its own stream and cannot alter structural stacks.
	var scatter := Stone.random_stream(recipe.seed_value, "obstacle/%d/rubble" % recipe.family)
	for i in range(recipe.rubble_count):
		var asset := module_asset("rubble")
		asset.size *= recipe.object_scale * scatter.randf_range(0.8, 1.6)
		asset.at = Vector3(scatter.randf_range(-0.7, recipe.length - 0.3) * recipe.object_scale, asset.size.y / 2, -scatter.randf_range(0.7, 1.4) * recipe.object_scale)
		asset.id = "rubble/%d" % i
		asset["module"] = "rubble"
		parts.append(asset)
		bounds = bounds.merge(AABB(asset.at - asset.size / 2, asset.size))

	return {"version": VERSION, "stone_version": Stone.VERSION, "family": recipe.family, "seed": recipe.seed_value, "surface_style": recipe.surface_style, "parts": parts, "bounds": bounds}

static func build(data: Dictionary) -> Node3D:
	var root := Node3D.new()
	if data.is_empty(): return root
	root.name = NAMES[data.family]
	# One material and cached base meshes per build; no carved nodes or energy circuits.
	var material := Surfaces.create(data.get("surface_style", 0))
	var meshes := {}
	for part in data.parts:
		var key := "%s/%s" % [part.module, str(part.size)]
		if not meshes.has(key):
			var mesh := Stone.stone_mesh(part)
			if part.module != "rubble" and part.size.y > 0.35:
				var w: float = part.size.x
				var h: float = part.size.y
				var z: float = part.size.z / 2
				var route := PackedVector3Array([Vector3(-w * 0.22, h * 0.35, z), Vector3(-w * 0.22, 0, z), Vector3(w * 0.22, 0, z), Vector3(w * 0.22, -h * 0.35, z)])
				mesh = Carving.carve(mesh, [route], Vector3(0, 0, -10), 0, minf(0.08, part.size.z * 0.12))
			meshes[key] = mesh
		var piece := MeshInstance3D.new()
		piece.name = part.id.replace("/", "_")
		piece.mesh = meshes[key]
		piece.material_override = material
		root.add_child(piece)
		piece.position = part.at
		piece.rotation = Vector3(0, part.yaw, part.roll)
	return root


# Larger grammars reuse the same mesh owner, with additional architectural proportions.
static func large_layout(recipe: Resource) -> Dictionary:
	var parts: Array[Dictionary] = []
	var rng := Stone.random_stream(recipe.seed_value, "obstacle/%d/main" % recipe.family)
	if recipe.family == 6:
		for i in range(3):
			var height: float = rng.randf_range(2.5, 5.5) * (1.0 - recipe.brokenness * 0.45)
			large_piece(parts, "foot_%d" % i, "foot", Vector3((i - 1) * 1.8, 0.2, 0), Vector3(1.6, 0.4, 1.6), recipe)
			large_piece(parts, "spire_%d" % i, ("column" if i == 1 else "taper"), Vector3((i - 1) * 1.8, 0.4 + height / 2, 0), Vector3(1.0, height, 1.1), recipe)
			if i == 1: large_piece(parts, "capital", "capital", Vector3(0, 0.4 + height + 0.15, 0), Vector3(1.45, 0.3, 1.45), recipe)
	elif recipe.family == 7:
		for side in [-1, 1]:
			large_piece(parts, "foot_%d" % side, "foot", Vector3(side * 2.0, 0.25, 0), Vector3(2, 0.5, 1.9), recipe)
			large_piece(parts, "pier_%d" % side, "pier", Vector3(side * 2.0, 2, 0), Vector3(1.15, 3, 1.25), recipe)
			# Cantilevered remnants stay attached to the two uprights; central gap stays open.
			large_piece(parts, "lintel_%d" % side, "arch", Vector3(side * 1.6, 3.8, 0), Vector3(1.95, 0.6, 1.45), recipe)
	elif recipe.family == 8:
		large_piece(parts, "plinth", "foot", Vector3(0, 0.25, 0), Vector3(5.5, 0.5, 2), recipe)
		for side in [-1, 1]:
			var reach := 5 - floori(recipe.brokenness * rng.randf_range(1, 3))
			for i in range(reach):
				var angle: float = -PI / 2 + side * (i + 0.5) * PI / 7
				large_piece(parts, "ring_%d_%d" % [side, i], "arch", Vector3(cos(angle) * 2.1, 2.6 + sin(angle) * 2.1, 0), Vector3(1.02, 0.65, 1.05), recipe, angle - PI / 2)
	else:
		for tier in range(recipe.courses):
			large_piece(parts, "terrace_%d" % tier, "slab", Vector3(0, 0.2 + tier * 0.4, 0), Vector3(5.6 - tier * 0.8, 0.4, 3.8 - tier * 0.5), recipe)
		for side in [-1, 1]:
			var height: float = rng.randf_range(1.5, 3.0)
			large_piece(parts, "marker_%d" % side, "taper", Vector3(side * 1.4, recipe.courses * 0.4 + height / 2, 0), Vector3(0.8, height, 0.8), recipe)
	var bounds := AABB()
	for i in range(parts.size()):
		var part: Dictionary = parts[i]
		var box := Transform3D(Basis.from_euler(Vector3(0, part.yaw, part.roll)), part.at) * AABB(-part.size / 2, part.size)
		bounds = box if i == 0 else bounds.merge(box)
	return {"version": VERSION, "stone_version": Stone.VERSION, "family": recipe.family, "seed": recipe.seed_value, "surface_style": recipe.surface_style, "parts": parts, "bounds": bounds}

static func large_piece(parts: Array[Dictionary], id: String, module: String, at: Vector3, size: Vector3, recipe: Resource, roll := 0.0) -> void:
	var part := module_asset(module)
	part.id = id
	part.at = at * float(recipe.object_scale)
	part.size = size * float(recipe.object_scale)
	part.roll = roll
	part.yaw = 0.0
	part["module"] = module
	parts.append(part)


