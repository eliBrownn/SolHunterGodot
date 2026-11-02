extends RefCounted
## Primitive geometry/support helpers; species builders own their distinct anatomy.

static func ring(parent: Node3D, title: String, at: Vector3, radius: float, material: Material) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = title
	var mesh := TorusMesh.new()
	mesh.inner_radius = radius * 0.65
	mesh.outer_radius = radius
	mesh.rings = 12
	mesh.ring_segments = 6
	node.mesh = mesh
	node.material_override = material
	node.position = at
	parent.add_child(node)
	return node

static func beam(parent: Node3D, title: String, start: Vector3, finish: Vector3, width: float, depth: float, material: Material) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = title
	var mesh := BoxMesh.new()
	mesh.size = Vector3(width, depth, start.distance_to(finish))
	node.mesh = mesh
	node.material_override = material
	node.position = (start + finish) * 0.5
	node.quaternion = Quaternion(Vector3.BACK, (finish - start).normalized())
	parent.add_child(node)
	return node

static func fan(parent: Node3D, title: String, points: PackedVector3Array, material: StandardMaterial3D) -> MeshInstance3D:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	for index in range(1, points.size() - 1):
		var normal := (points[index] - points[0]).cross(points[index + 1] - points[0]).normalized()
		for at in [points[0], points[index], points[index + 1]]:
			vertices.append(at)
			normals.append(normal)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var node := MeshInstance3D.new()
	node.name = title
	node.mesh = mesh
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	node.material_override = material
	parent.add_child(node)
	return node

static func leg(model: Node3D, title: String, at: Vector3, length: float, width: float, material: Material, group: int, broad: bool = false) -> void:
	model.limb(model.body, title, at, length, width, material, broad)
	model.ground_motion.chains[-1].group = group

static func sole(model: Node3D, title: String, at: Vector3, width: float, material: Material, group: int) -> void:
	# Real zones of a continuous creeping sole/band end, not invented walking legs.
	var hip: Node3D = model.joint(model.body, title, at)
	var knee: Node3D = model.joint(hip, title + "Knee", Vector3(0, -0.075, 0.018))
	var foot: Node3D = model.joint(knee, title + "Foot", Vector3(0, -0.075, 0.022))
	model.ellipsoid(foot, "SoftContact", Vector3(0, 0.015, 0), Vector3(width, 0.035, 0.16), material)
	var contact := Marker3D.new()
	contact.name = "Contact"
	foot.add_child(contact)
	model.register_support(hip, knee, foot, group)

static func eyes(model: Node3D, width: float, forward: float, dark: Material, light: Material) -> void:
	model.face(model.head, width, forward, dark, light)
	for eye in model.head.find_children("Eye*", "MeshInstance3D", false, false):
		eye.scale *= 1.3
