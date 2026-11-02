extends RefCounted
## Seeded object geometry only. No placement, collision, cover rules or energy ownership.
const VERSION := 1
const Definition = preload("res://scripts/scenery/structure_blockout_definition.gd")
const FAMILIES := ["boulder", "root", "fallen_trunk", "tree", "bank", "ridge", "wall", "arch"]

static func layout(recipe: Resource) -> Dictionary:
	if recipe == null or not recipe is Definition or not recipe.valid(): return {}
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("structure/%d/%d/%d/layout" % [VERSION, recipe.family, recipe.seed_value])
	var stretch := Vector3.ONE
	for axis in range(3): stretch[axis] = 1.0 + rng.randf_range(-0.25, 0.25) * recipe.variation
	stretch *= recipe.object_scale
	var parts: Array[Dictionary] = []
	var stone := Color("777b79")
	var wood := Color("73533a")
	match recipe.family:
		0: add(parts, "stone", "sphere", Vector3(0, 0.85, 0), Vector3(2.3, 1.7, 1.8), stone)
		1:
			add(parts, "root_base", "box", Vector3(0, 0.35, 0), Vector3(1.4, 0.7, 1.2), wood)
			for i in range(3): add(parts, "root_%d" % i, "box", Vector3((i - 1) * 0.7, 0.18, 0.9), Vector3(0.35, 0.36, 2.1), wood)
		2: add(parts, "trunk", "cylinder", Vector3(0, 0.45, 0), Vector3(0.9, 3.8, 0.9), wood, Vector3(0, 0, PI / 2))
		3:
			add(parts, "trunk", "cylinder", Vector3(0, 1.5, 0), Vector3(0.65, 3, 0.65), wood)
			add(parts, "crown", "sphere", Vector3(0, 3.4, 0), Vector3(2.7, 2.4, 2.7), Color("56774b"))
		4, 5:
			for i in range(3):
				var h := (i + 1) * 0.45 if recipe.family == 4 else (2 - absi(i - 1)) * 0.75
				add(parts, "earth_%d" % i, "box", Vector3(0, h / 2, (i - 1) * 0.9), Vector3(3.6, h, 0.9), Color("80725b"))
		6:
			for i in range(4): add(parts, "stone_%d" % i, "box", Vector3((i - 1.5) * 0.8, 0.5 + (i % 2) * 0.2, 0), Vector3(0.78, 1.0 + (i % 2) * 0.4, 0.65), stone)
		7:
			for side in [-1, 1]: add(parts, "pier_%d" % side, "box", Vector3(side * 1.2, 1.2, 0), Vector3(0.65, 2.4, 0.8), stone)
			add(parts, "lintel", "box", Vector3(0, 2.65, 0), Vector3(3.05, 0.5, 0.8), stone)
	for part in parts:
		part.at *= stretch
		# Scale in parent space, including horizontal cylinders.
	return {"version": VERSION, "family": FAMILIES[recipe.family], "seed": recipe.seed_value, "scale": stretch, "parts": parts}

static func add(parts: Array[Dictionary], id: String, shape: String, at: Vector3, size: Vector3, color: Color, rotation := Vector3.ZERO) -> void:
	parts.append({"id": id, "shape": shape, "at": at, "size": size, "color": color, "rotation": rotation})

static func build(data: Dictionary) -> Node3D:
	var root := Node3D.new()
	if data.is_empty(): return root
	root.name = data.family
	for part in data.parts:
		var mesh: PrimitiveMesh
		match part.shape:
			"sphere":
				var sphere := SphereMesh.new()
				sphere.radius = 0.5
				sphere.height = 1.0
				sphere.radial_segments = 12
				sphere.rings = 6
				mesh = sphere
			"cylinder":
				var cylinder := CylinderMesh.new()
				cylinder.top_radius = 0.5
				cylinder.bottom_radius = 0.5
				cylinder.height = 1.0
				cylinder.radial_segments = 10
				mesh = cylinder
			_:
				var box := BoxMesh.new()
				box.size = Vector3.ONE
				mesh = box
		var node := MeshInstance3D.new()
		node.name = part.id
		node.mesh = mesh
		var material := StandardMaterial3D.new()
		material.albedo_color = part.color
		material.roughness = 0.95
		node.material_override = material
		root.add_child(node)
		node.transform = Transform3D(Basis.from_euler(part.rotation) * Basis.from_scale(part.size), part.at / data.scale)
	root.scale = data.scale
	return root

