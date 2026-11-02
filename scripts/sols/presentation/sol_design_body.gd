extends Node3D
## Shared modular appearance with connected joints and existing support solver.
const Recipe = preload("res://scripts/sols/presentation/sol_design_recipe.gd")
const Motion = preload("res://scripts/sols/sol_ground_motion.gd")
const Wisp = preload("res://scripts/sols/presentation/sol_visual_core.gd")
var selected := "Body"
var meshes: Array[MeshInstance3D] = []
var joints: Dictionary = {}
var rests: Dictionary = {}
var ground_motion := Motion.new()
var rig: Node3D
var torso: Node3D
var recipe: Dictionary
var skeleton := false
var silhouette := false
var last_seconds := 0.0
var wisp_head: Node3D
var visual_core: Node3D

func joint(parent: Node3D, key: String, at: Vector3) -> Node3D:
	var node := Node3D.new()
	node.name = key
	node.position = at
	parent.add_child(node)
	joints[key] = node
	return node

func build(value: Dictionary, highlight: String) -> void:
	selected = highlight
	recipe = Recipe.resolved(value)
	for child in get_children():
		remove_child(child)
		child.queue_free()
	meshes.clear()
	joints.clear()
	rests.clear()
	ground_motion = Motion.new()
	var settings := Recipe.design(recipe)
	var modules: Dictionary = settings.modules
	var length := float(recipe.body_length)
	var width := float(recipe.body_width)
	var height := float(recipe.body_height)
	var head := float(recipe.head_size)
	var plan: String = settings.body_plan
	var center := float(recipe.leg_length) + height * 0.4
	if plan in ["serpentine", "aquatic"]: center = height * 0.5 + 0.08
	var color := Color.html(recipe.color)
	rig = joint(self, "Rig", Vector3.ZERO)
	# Match the existing game rig's forward (+Z) without changing shape-space keys.
	rig.scale.z = -1.0
	torso = joint(rig, "Body", Vector3(0, center, 0))
	var body_dimensions := Vector3(width, height, length)
	if settings.structure in ["petal", "mushroom", "vine"]: body_dimensions *= Vector3(0.7, 1.2, 0.5)
	ellipsoid(torso, "Body", Vector3.ZERO, body_dimensions, color)
	var head_joint := joint(torso, "Head", Vector3(0, height * 0.3 + float(recipe.head_offset), -length * 0.5 - head * 0.45))
	var neck := MeshInstance3D.new()
	var neck_mesh := CylinderMesh.new()
	neck_mesh.top_radius = head * 0.05
	neck_mesh.bottom_radius = head * 0.15
	neck_mesh.height = maxf(0.01, head_joint.position.length())
	neck.mesh = neck_mesh
	neck.position = head_joint.position * 0.5
	neck.quaternion = Quaternion(Vector3.UP, head_joint.position.normalized())
	neck.material_override = material_for("Head", color)
	neck.set_meta("part", "Head")
	torso.add_child(neck)
	meshes.append(neck)
	if modules.get("anatomical_head", true): ellipsoid(head_joint, "Head", Vector3.ZERO, Vector3.ONE * head, color.lightened(0.15))
	var pairs := 3 if plan == "insectoid" else 1 if plan in ["biped", "avian"] else 0 if plan in ["serpentine", "aquatic"] else 2
	for pair in pairs:
		for side in [-1.0, 1.0]:
			var z := length * (0.1 if pairs == 1 else lerpf(-0.32, 0.32, float(pair) / (pairs - 1)))
			var asymmetry: float = 1.0 if settings.symmetry or side < 0 else 1.0 - settings.asymmetry * 0.15
			var hip := joint(torso, "Leg%d_%s" % [pair, str(side)], Vector3(side * width * recipe.limb_spread, 0, z))
			ellipsoid(hip, "Legs", Vector3(-side * width * recipe.limb_spread * 0.5, 0, 0), Vector3(width * recipe.limb_spread + width * 0.15, width * 0.18, width * 0.18), color)
			var segment := center * 0.52 * asymmetry
			ellipsoid(hip, "Legs", Vector3(0, -segment * 0.45, 0.02), Vector3(width * 0.22, segment * 1.15, width * 0.24), color.darkened(0.15))
			var knee := joint(hip, str(hip.name) + "Knee", Vector3(0, -segment, 0.055))
			ellipsoid(knee, "Legs", Vector3(0, -segment * 0.45, -0.02), Vector3(width * 0.18, segment * 1.1, width * 0.22), color.darkened(0.2))
			var foot := joint(knee, str(hip.name) + "Foot", Vector3(0, -segment * 0.92, -0.055))
			ellipsoid(foot, "Legs", Vector3(0, 0.025, -0.04), Vector3(width * 0.27, 0.07, width * 0.4), color.darkened(0.2))
			ground_motion.add_chain(self, hip, knee, foot, (pair + (1 if side > 0 else 0)) % 2)
	var accent := Color.html(settings.accent)
	for side in [-1.0, 1.0]:
		if modules.get("anatomical_head", true): ellipsoid(head_joint, "Head", Vector3(side * head * 0.25, head * 0.05, -head * 0.4), Vector3.ONE * head * 0.14, Color("19212d"))
		if modules.get("ears", true):
			var ear := joint(head_joint, "Ear" + str(side), Vector3(side * head * 0.3, head * 0.3, 0))
			ellipsoid(ear, "Ears", Vector3(0, recipe.ear_length * 0.35, 0), Vector3(head * 0.25, recipe.ear_length, head * 0.25), accent)
		if modules.get("horns", false):
			var horn := joint(head_joint, "Horn" + str(side), Vector3(side * head * 0.27, head * 0.3, 0.04))
			ellipsoid(horn, "Horns", Vector3(0, recipe.horn_length * 0.4, 0), Vector3(head * 0.24, recipe.horn_length, head * 0.24), accent)
			var cone := CylinderMesh.new()
			cone.top_radius = 0.01
			cone.bottom_radius = 0.5
			cone.height = 1
			meshes[-1].mesh = cone
		if modules.get("wings", false):
			var wing := joint(torso, "Wing" + str(side), Vector3(side * width * 0.3, height * 0.15, -length * 0.1))
			ellipsoid(wing, "Wings", Vector3(side * recipe.wing_span * 0.3, 0, 0.1), Vector3(recipe.wing_span * 0.85, 0.09, length * 0.55), accent)
		if modules.get("fins", false):
			var fin := joint(torso, "Fin" + str(side), Vector3(side * width * 0.35, 0, length * 0.1))
			ellipsoid(fin, "Fins", Vector3(side * recipe.fin_size * 0.3, 0, 0), Vector3(recipe.fin_size, 0.06, recipe.fin_size * 0.7), accent)
	if modules.get("anatomical_head", true) and modules.get("muzzle", false): ellipsoid(head_joint, "Head", Vector3(0, -head * 0.15, -head * 0.3 - recipe.muzzle_length * 0.25), Vector3(head * 0.55, head * 0.4, recipe.muzzle_length), accent)
	if modules.get("tail", true):
		var tail := joint(torso, "Tail", Vector3(0, 0, length * 0.35))
		tail.rotation.x = deg_to_rad(recipe.tail_angle)
		ellipsoid(tail, "Tail", Vector3(0, 0, recipe.tail_length * 0.35), Vector3(width * 0.23, height * 0.24, recipe.tail_length), color)
	build_structure(settings.structure, head_joint, width, height, length, accent)
	visual_core = Wisp.new()
	visual_core.name = "VisualCore"
	visual_core.configure(recipe.core_size, recipe, Color.html(settings.core_tint))
	var anchor: Node3D = torso
	var offset := Vector3(0, 0, -length * 0.5 - float(recipe.core_size) * 0.35)
	match settings.core_anchor:
		"head": anchor = head_joint; offset = Vector3(0, 0, -head * 0.45)
		"back": offset = Vector3(0, height * 0.55, length * 0.1)
		"root": anchor = rig; offset = Vector3(0, recipe.core_size * 0.55, 0)
		"tail": anchor = joints.get("Tail", torso); offset = Vector3(0, 0, recipe.tail_length * 0.5)
		"free": anchor = rig; offset = Vector3.ZERO
	visual_core.position = offset + Vector3(recipe.core_offset_x, recipe.core_offset_y, recipe.core_offset_z)
	anchor.add_child(visual_core)
	wisp_head = visual_core # Compatibility for early lab documents/tools.
	for key in joints: rests[key] = joints[key].transform
	if skeleton:
		for key in joints:
			var dot := MeshInstance3D.new()
			var sphere := SphereMesh.new()
			sphere.radius = 0.035
			sphere.height = 0.07
			dot.mesh = sphere
			var material := StandardMaterial3D.new()
			material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			material.albedo_color = Color("ffb14b")
			material.no_depth_test = true
			dot.material_override = material
			joints[key].add_child(dot)
	last_seconds = 0

func build_structure(kind: String, face: Node3D, width: float, height: float, length: float, color: Color) -> void:
	var size := float(recipe.structure_size)
	match kind:
		"petal", "mushroom", "vine":
			var count := 8 if kind == "petal" else 5
			if kind == "mushroom": ellipsoid(face, "Structure", Vector3(0, recipe.head_size * 0.4, 0), Vector3(size * 1.9, size * 0.5, size * 1.5), color)
			for index in count:
				var angle := index * TAU / count
				var leaf := joint(torso, "Leaf%d" % index, Vector3(sin(angle) * width * 0.1, 0, cos(angle) * length * 0.1))
				leaf.rotation = Vector3(cos(angle) * 0.6, angle, sin(angle) * 0.6)
				ellipsoid(leaf, "Structure", Vector3(0, size * 0.3, size * 0.2), Vector3(size * 0.35, size * 1.3, 0.08), color)
				if kind == "vine":
					ellipsoid(leaf, "Structure", Vector3(0, -size * 0.3, 0), Vector3(0.08, size * 1.3, 0.08), color.darkened(0.25))
		"shell", "plates", "coil":
			var count := 1 if kind == "shell" else 5
			for index in count:
				var z := 0.0 if count == 1 else lerpf(-length * 0.4, length * 0.4, float(index) / (count - 1))
				ellipsoid(torso, "Structure", Vector3(0, height * 0.35, z), Vector3(width * 1.15, height * 0.8, length * 1.1 if count == 1 else length * 0.3), color)
				if kind == "coil":
					var ring := TorusMesh.new()
					ring.inner_radius = width * 0.35
					ring.outer_radius = width * 0.65
					meshes[-1].mesh = ring
					meshes[-1].scale = Vector3.ONE
					meshes[-1].rotation.x = PI * 0.5
		"ruff", "frill", "fan", "feathers", "web":
			var parent := face if kind in ["ruff", "frill"] else torso
			for index in 7:
				var angle := lerpf(-1.2, 1.2, float(index) / 6)
				var node := joint(parent, "Fan%d" % index, Vector3(0, height * 0.1, 0.1))
				node.rotation.z = angle
				ellipsoid(node, "Structure", Vector3(0, size * 0.45, 0), Vector3(size * (0.3 if kind != "web" else 0.07), size * 1.2, 0.08), color)
		"sail", "spines", "crystal":
			for index in (1 if kind == "sail" else 5):
				ellipsoid(torso, "Structure", Vector3(0, height * 0.3 + size * 0.4, (index - 2) * length * 0.18 if kind != "sail" else 0), Vector3(size * 0.2, size, length * 0.85 if kind == "sail" else size * 0.25), color)
				if kind != "sail":
					var prism := PrismMesh.new()
					prism.size = Vector3.ONE
					meshes[-1].mesh = prism
		"pouch":
			ellipsoid(torso, "Structure", Vector3(0, -height * 0.15, -length * 0.3), Vector3(width * 1.35, height * 1.3, length * 0.6), color)
		"burrow", "broadarms", "centaur":
			var base := torso
			if kind == "centaur":
				base = joint(torso, "UprightTorso", Vector3(0, height * 0.55, -length * 0.28))
				ellipsoid(base, "Structure", Vector3.ZERO, Vector3(width * 0.65, height * 1.4, width * 0.65), color)
			for side in [-1.0, 1.0]:
				var arm := joint(base, "Arm" + str(side), Vector3(side * width * 0.4, height * 0.15, -length * 0.15))
				arm.rotation.z = side * 0.5
				ellipsoid(arm, "Structure", Vector3(0, -size * 0.35, 0), Vector3(size * 0.4, size * 1.2, size * 0.45), color)
		"fold", "mask":
			for index in (4 if kind == "fold" else 1):
				ellipsoid(face, "Structure", Vector3(0, index * size * 0.12, -recipe.head_size * 0.3), Vector3(size * 1.25, size * 0.8, 0.13), color)
				var prism := PrismMesh.new()
				prism.size = Vector3.ONE
				meshes[-1].mesh = prism
				meshes[-1].rotation.z = (index % 2 * 2 - 1) * 0.35
		"wheel", "cage":
			for index in (3 if kind == "cage" else 1):
				ellipsoid(torso, "Structure", Vector3(0, 0, (index - 1) * 0.2), Vector3.ONE, color)
				var ring := TorusMesh.new()
				ring.inner_radius = size * 0.65
				ring.outer_radius = size
				meshes[-1].mesh = ring
				meshes[-1].rotation.x = PI * 0.5
			if kind == "wheel":
				for index in 8:
					var angle := index * TAU / 8
					ellipsoid(torso, "Structure", Vector3(sin(angle) * size * 0.8, cos(angle) * size * 0.8, -0.1), Vector3.ONE * 0.14, Color("19212d"))
		"threads", "ribbon", "veil":
			for index in (8 if kind == "veil" else 5):
				var angle := index * TAU / (8 if kind == "veil" else 5)
				var thread := joint(torso, "Thread%d" % index, Vector3(sin(angle) * width * 0.3, 0, cos(angle) * length * 0.3))
				thread.rotation.z = sin(angle) * 0.4
				ellipsoid(thread, "Structure", Vector3(0, -size * 0.3, size * 0.2), Vector3(0.12 if kind == "threads" else size * 0.5, size * 1.5, 0.08), color)
		"bell", "totem":
			for index in 3:
				ellipsoid(torso, "Structure", Vector3(0, index * size * 0.3, 0), Vector3(size * (1.3 - index * 0.3), size * 0.6, size * (1.3 - index * 0.3)), color)
				if kind == "totem":
					var block := BoxMesh.new()
					block.size = Vector3.ONE
					meshes[-1].mesh = block
		"antlers":
			for side in [-1.0, 1.0]:
				for index in 3:
					var antler := joint(face, "Antler%s_%d" % [str(side), index], Vector3(side * recipe.head_size * 0.3, recipe.head_size * 0.3, 0))
					antler.rotation.z = side * (0.2 + index * 0.3)
					ellipsoid(antler, "Structure", Vector3(0, size * 0.3, 0), Vector3(0.07, size * (0.7 + index * 0.2), 0.07), color)
		"slender":
			ellipsoid(torso, "Structure", Vector3(0, height * 0.35, -length * 0.3), Vector3(width * 0.4, size * 1.3, width * 0.4), color)

func material_for(part: String, color: Color) -> StandardMaterial3D:
	var settings := Recipe.design(recipe)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color.BLACK if silhouette else color
	material.roughness = settings.roughness
	if silhouette: material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if settings.pattern != "plain" and part not in ["Horns", "Ears"] and color != Color("19212d") and not silhouette:
		var image := Image.create(32, 32, false, Image.FORMAT_RGBA8)
		var accent := Color.html(settings.accent)
		for y in 32:
			for x in 32:
				var marked: bool = (x / 4) % 2 == 0 if settings.pattern == "stripes" else (y / 5) % 2 == 0 if settings.pattern == "bands" else Vector2(x % 8 - 4, y % 8 - 4).length() < 2.5
				image.set_pixel(x, y, accent if marked else color)
		material.albedo_color = Color.WHITE
		material.albedo_texture = ImageTexture.create_from_image(image)
	if selected == part and not silhouette:
		material.emission_enabled = true
		material.emission = Color("508f9d")
		material.emission_energy_multiplier = 0.25
	return material

func ellipsoid(parent: Node3D, part: String, at: Vector3, dimensions: Vector3, color: Color) -> void:
	var node := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.5
	sphere.height = 1.0
	sphere.radial_segments = 16
	sphere.rings = 8
	node.mesh = sphere
	node.position = at
	node.scale = dimensions
	node.set_meta("part", part)
	node.material_override = material_for(part, color)
	parent.add_child(node)
	meshes.append(node)

func animate_visual(seconds: float, _mode: String = "idle", _speed: float = 0.3, _stride: float = 0.12, _lift: float = 0.08) -> void:
	# Preview callers retain the API; authored body transforms stay neutral.
	if wisp_head != null: wisp_head.set_visual_time(seconds)

func bounds() -> AABB:
	var result := AABB()
	for mesh in meshes:
		var box: AABB = Motion.relative_transform(mesh, self) * mesh.get_aabb()
		result = box if result.size == Vector3.ZERO else result.merge(box)
	if wisp_head != null:
		var radius: float = wisp_head.envelope_radius()
		var box := AABB(Vector3.ONE * -radius, Vector3.ONE * radius * 2)
		result = result.merge(Motion.relative_transform(wisp_head, self) * box)
	return result

func diagnostics() -> Dictionary:
	var error := 0.0
	for chain in ground_motion.chains: error = maxf(error, chain.get("error", 0.0))
	return {"parts": meshes.size(), "joints": joints.size(), "supports": ground_motion.chains.size(), "max_contact_error": error, "height": bounds().size.y}

func pick(camera: Camera3D, point: Vector2) -> String:
	var origin := camera.project_ray_origin(point)
	var direction := camera.project_ray_normal(point)
	var closest := INF
	var result := ""
	if wisp_head != null:
		var offset: Vector3 = origin - wisp_head.global_position
		var b := offset.dot(direction)
		var disc := b * b - offset.length_squared() + pow(wisp_head.envelope_radius(), 2)
		if disc >= 0:
			var distance := -b - sqrt(disc)
			if distance >= 0:
				return "Core" # The translucent core remains selectable over body geometry.
	for mesh in meshes:
		var inverse := mesh.global_transform.affine_inverse()
		var local_origin: Vector3 = inverse * origin
		var local_direction: Vector3 = inverse.basis * direction
		var a := local_direction.dot(local_direction)
		var b := 2.0 * local_origin.dot(local_direction)
		var c := local_origin.dot(local_origin) - 0.25
		var discriminant := b * b - 4.0 * a * c
		if discriminant < 0: continue
		var distance := (-b - sqrt(discriminant)) / (2.0 * a)
		if distance >= 0 and distance < closest:
			closest = distance
			result = mesh.get_meta("part")
	return result
