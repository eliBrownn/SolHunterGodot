extends Node3D
## Batched solid geometry from prepared terrain data. No new generation or collision rules.

static var meshes: Dictionary = {}
var batches: Dictionary = {}
var tile_count := 0
var obstacle_count := 0

static func mesh_for(kind: String) -> Mesh:
	if meshes.has(kind):
		return meshes[kind]
	var mesh: Mesh
	match kind:
		"roof":
			var prism := PrismMesh.new()
			prism.size = Vector3.ONE
			mesh = prism
		"trunk":
			var cylinder := CylinderMesh.new()
			cylinder.top_radius = 0.10
			cylinder.bottom_radius = 0.16
			cylinder.height = 1.5
			cylinder.radial_segments = 6
			mesh = cylinder
		"crown", "rock":
			var sphere := SphereMesh.new()
			sphere.radius = 1.0
			sphere.height = 2.0
			sphere.radial_segments = 7
			sphere.rings = 3
			mesh = sphere
		_:
			var box := BoxMesh.new()
			box.size = Vector3.ONE
			mesh = box
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.roughness = 0.92
	if kind == "water":
		material.roughness = 0.28
	mesh.material = material
	meshes[kind] = mesh
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
		view.name = kind
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
			if data.trail_visible:
				for z in [-0.24, 0.24]:
					for x in [-0.24, 0.24]:
						add_piece("paving", at + Vector3(x, 0.018, z), Vector3(0.44, 0.036, 0.44), Color("999b86").lightened(shade))
		if data.obstacle == 1:
			add_piece("trunk", at + Vector3(0, 0.75, 0), Vector3.ONE, Color("76573b"))
			add_piece("crown", at + Vector3(0, 1.80, 0), Vector3(0.94, 0.86, 0.85), Color("52784b").lightened(shade))
			add_piece("crown", at + Vector3(0.20, 2.37, 0.05), Vector3(0.65, 0.65, 0.67), Color("71904f").lightened(shade))
			obstacle_count += 1
		elif data.obstacle == 2:
			add_piece("rock", at + Vector3(0, 0.26, 0), Vector3(0.52, 0.38, 0.43), Color("93958c"), float(data.variation) * 0.5)
			obstacle_count += 1
		tile_count += 1
	finish()
