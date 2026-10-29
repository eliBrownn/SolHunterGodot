class_name SolCreature
extends SolOrb
## Articulated primitive blockouts. Joint transforms are local visual controls,
## never navigation, collision, affinity identity or saved simulation state.

## Body plan selected by the authored species scene.
@export_enum("Crown-Ear", "Reedback", "Bellroot") var body_plan := 0
## Uniform art scale, in world cells/metres. Rebuild the view after editing.
@export_range(0.5, 1.5, 0.05) var model_scale := 1.0
## Breathing and secondary idle motion multiplier; zero holds the neutral pose.
@export_range(0.0, 2.0, 0.1) var idle_strength := 1.0
## Idle cycles per second. Does not change simulation speed.
@export_range(0.0, 2.0, 0.05) var idle_rate := 0.6
## Cosmetic attack/hit and recovery duration in seconds. Does not delay battle rules.
@export_range(0.1, 1.0, 0.05) var action_seconds := 0.45
## Distance in world metres before a support pair takes another step. Art scale applies.
@export_range(0.04, 0.3, 0.01) var step_distance := 0.06
## Maximum swing-foot lift in metres. Zero keeps the swing near the surface.
@export_range(0.0, 0.15, 0.005) var step_lift := 0.045
## Visual heading response in inverse seconds; higher values turn faster.
@export_range(1.0, 30.0, 0.5) var turn_response := 12.0
## Procedural flight wingbeats per second, used only with admitted flight presentation.
@export_range(1.0, 6.0, 0.1) var wingbeat_rate := 3.0
## Surface-swimming strokes per second, used only with admitted swim presentation.
@export_range(0.5, 3.0, 0.1) var swim_stroke_rate := 1.5

var rig: Node3D
var body: Node3D
var head: Node3D
var joints: Dictionary = {}
var rest_rotations: Dictionary = {}
var rest_transforms: Dictionary = {}
var ground_motion = preload("res://scripts/sols/sol_ground_motion.gd").new()
var traversal_visual: Dictionary = {}
var turn_velocity := 0.0
var wing_surfaces: Array[Dictionary] = []
var body_materials: Array[StandardMaterial3D] = []
var stance := "rest"
var action := ""
var action_started := 0.0

func set_stance(value: String) -> void:
	stance = value if value in ["rest", "alert"] else "rest"

func play_action(value: String, seconds: float) -> void:
	if value in ["attack", "hit", "signature"]:
		action = value
		action_started = seconds

func apply_impact(color: Color, strength: float) -> void:
	for material in body_materials:
		material.emission_enabled = strength > 0.0
		material.emission = color * clampf(strength, 0.0, 1.0) * 0.5

func configure(assigned_affinity: String, settings: SolVisualSettings, phase_offset: float = 0.0) -> void:
	super.configure(assigned_affinity, settings, phase_offset)
	# Keep the existing individual-affinity motes, shadow and combat flash contract.
	# Species skin and silhouette never inherit affinity color.
	mesh = null
	halo.hide()
	rig = joint(self, "Rig", Vector3.ZERO)
	rig.scale = Vector3.ONE * model_scale
	body = joint(rig, "Body", Vector3.ZERO)
	build_model()
	for key in joints:
		rest_rotations[key] = joints[key].rotation
		rest_transforms[key] = joints[key].transform
	animate(0.0, 0.0, 0.0)

## Override this and animate_features/preview_bounds for a new species body.
func build_model() -> void:
	match body_plan:
		0: build_crown_ear()
		1: build_reedback()
		2: build_bellroot()

func sync_locomotion(at: Vector2, delta: float, sampler: Callable) -> void:
	var previous_heading: float = ground_motion.heading
	ground_motion.advance(at, delta, sampler, model_scale, step_distance, step_lift, turn_response)
	if delta > 0:
		turn_velocity = wrapf(ground_motion.heading - previous_heading, -PI, PI) / delta

func set_traversal(value: Dictionary) -> void:
	if value.get("mode", "ground") == "ground" and traversal_visual.get("mode", "ground") != "ground":
		ground_motion.reset()
	traversal_visual = value.duplicate()

func reset_locomotion() -> void:
	ground_motion.reset()
	turn_velocity = 0.0

func register_support(hip: Node3D, knee: Node3D, foot: Node3D, group: int, inset: float = 1.0) -> void:
	ground_motion.add_chain(self, hip, knee, foot, group, inset)

func joint(parent: Node3D, title: String, offset: Vector3) -> Node3D:
	var node := Node3D.new()
	node.name = title
	node.position = offset
	parent.add_child(node)
	joints[title] = node
	return node

func skin(color: String) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = Color(color)
	result.roughness = 0.9
	body_materials.append(result)
	return result

func ellipsoid(parent: Node3D, title: String, offset: Vector3, dimensions: Vector3, material: Material) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = title
	var sphere := SphereMesh.new()
	sphere.radius = 0.5
	sphere.height = 1.0
	sphere.radial_segments = 12
	sphere.rings = 6
	node.mesh = sphere
	node.position = offset
	node.scale = dimensions
	node.material_override = material
	parent.add_child(node)
	return node

func taper(parent: Node3D, title: String, offset: Vector3, height: float, radius: float, material: Material) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = title
	var cone := CylinderMesh.new()
	cone.top_radius = radius * 0.12
	cone.bottom_radius = radius
	cone.height = height
	cone.radial_segments = 8
	node.mesh = cone
	node.position = offset
	node.material_override = material
	parent.add_child(node)
	return node

func face(parent: Node3D, width: float, forward: float, eyes: Material, muzzle: Material) -> void:
	for side in [-1.0, 1.0]:
		ellipsoid(parent, "EyeLeft" if side < 0 else "EyeRight", Vector3(side * width, 0.018, forward), Vector3(0.038, 0.047, 0.025), eyes)
		ellipsoid(parent, "GlintLeft" if side < 0 else "GlintRight", Vector3(side * width - 0.006, 0.03, forward + 0.014), Vector3.ONE * 0.009, muzzle)

func limb(parent: Node3D, title: String, origin: Vector3, length: float, width: float, material: Material, webbed: bool = false) -> void:
	var hip := joint(parent, title, origin)
	ellipsoid(hip, "Upper", Vector3(0, -length * 0.25, 0), Vector3(width, length * 0.65, width), material)
	var knee := joint(hip, title + "Knee", Vector3(0, -length * 0.5, 0.018))
	ellipsoid(knee, "Lower", Vector3(0, -length * 0.25, 0), Vector3(width * 0.75, length * 0.55, width * 0.8), material)
	var foot := joint(knee, title + "Foot", Vector3(0, -length * 0.5, 0.022))
	ellipsoid(foot, "Pad", Vector3(0, 0.015, 0.02), Vector3(width * (1.7 if webbed else 1.2), 0.045, width * 1.8), material)
	var contact := Marker3D.new()
	contact.name = "Contact"
	foot.add_child(contact)
	register_support(hip, knee, foot, 0 if title in ["FrontLeft", "HindRight"] else 1)

func build_crown_ear() -> void:
	var fur := skin("62536e")
	var light := skin("d9b59b")
	var membrane := skin("a16c78")
	var eyes := skin("171e2b")
	ellipsoid(body, "Torso", Vector3(0, 0.19, -0.025), Vector3(0.21, 0.24, 0.2), fur)
	ellipsoid(body, "Chest", Vector3(0, 0.19, 0.063), Vector3(0.13, 0.17, 0.05), light)
	head = joint(body, "Head", Vector3(0, 0.29, 0.075))
	ellipsoid(head, "Face", Vector3.ZERO, Vector3(0.22, 0.16, 0.15), fur)
	ellipsoid(head, "Muzzle", Vector3(0, -0.018, 0.067), Vector3(0.09, 0.055, 0.045), light)
	face(head, 0.054, 0.067, eyes, light)
	for side in [-1.0, 1.0]:
		var suffix := "Left" if side < 0 else "Right"
		var ear := joint(head, "Ear" + suffix, Vector3(side * 0.073, 0.046, 0))
		ear.rotation.z = -side * 0.3
		ellipsoid(ear, "Rim", Vector3(0, 0.082, 0), Vector3(0.135, 0.18, 0.042), fur)
		ellipsoid(ear, "Inner", Vector3(0, 0.09, 0.021), Vector3(0.1, 0.13, 0.013), membrane)
		var wing := joint(body, "Wing" + suffix, Vector3(side * 0.09, 0.22, 0))
		var elbow := joint(wing, "WingElbow" + suffix, Vector3(side * 0.14, -0.045, 0))
		var wrist := joint(elbow, "Wrist" + suffix, Vector3(side * 0.11, -0.09, 0.035))
		var contact := Marker3D.new()
		contact.name = "Contact"
		wrist.add_child(contact)
		register_support(wing, elbow, wrist, 0 if side < 0 else 1, 0.75)
		wing_membrane(wing, side, membrane)
		ellipsoid(wing, "Arm", Vector3(side * 0.07, -0.024, 0), Vector3(0.17, 0.035, 0.035), fur).rotation.z = -side * 0.3
		ellipsoid(elbow, "Forearm", Vector3(side * 0.055, -0.045, 0.018), Vector3(0.15, 0.028, 0.03), fur).rotation.z = -side * 0.65
		ellipsoid(wrist, "Thumb", Vector3.ZERO, Vector3(0.035, 0.045, 0.045), light)
		joint(wrist, "WingTip" + suffix, Vector3(side * 0.1, -0.025, -0.13))
		limb(body, "Hind" + suffix, Vector3(side * 0.07, 0.13, -0.075), 0.12, 0.045, fur)
	var tail := joint(body, "Tail", Vector3(0, 0.13, -0.12))
	ellipsoid(tail, "Tip", Vector3(0, -0.015, -0.055), Vector3(0.035, 0.04, 0.12), fur)

func wing_membrane(parent: Node3D, side: float, material: Material) -> void:
	var surface := ArrayMesh.new()
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array([Vector3.ZERO, Vector3.RIGHT, Vector3.UP])
	arrays[Mesh.ARRAY_NORMAL] = PackedVector3Array([Vector3.BACK, Vector3.BACK, Vector3.BACK])
	surface.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var two_sided := material.duplicate() as StandardMaterial3D
	two_sided.cull_mode = BaseMaterial3D.CULL_DISABLED
	body_materials.append(two_sided)
	var triangles: Array[MeshInstance3D] = []
	for index in range(3):
		var node := MeshInstance3D.new()
		node.name = "Membrane%d" % index
		node.mesh = surface
		node.material_override = two_sided
		node.set_meta("articulated_membrane", true)
		parent.add_child(node)
		triangles.append(node)
	wing_surfaces.append({"triangles": triangles, "root": parent, "side": side})

func update_membranes() -> void:
	for wing in wing_surfaces:
		var suffix := "Left" if wing.side < 0 else "Right"
		var points := [Vector3.ZERO,
			ground_motion.relative_transform(joints["WingElbow" + suffix], wing.root).origin,
			ground_motion.relative_transform(joints["Wrist" + suffix], wing.root).origin,
			ground_motion.relative_transform(joints["WingTip" + suffix], wing.root).origin,
			Vector3(wing.side * 0.04, -0.1, -0.11)]
		for index in range(3):
			var a: Vector3 = points[index + 1]
			var b: Vector3 = points[index + 2]
			var normal := a.cross(b)
			var node: MeshInstance3D = wing.triangles[index]
			node.visible = normal.length_squared() > 0.0000001
			if node.visible:
				node.transform = Transform3D(Basis(a, b, normal.normalized()), Vector3.ZERO)

func build_reedback() -> void:
	var hide := skin("71847b")
	var plate := skin("5b6860")
	var reed := skin("c6ad6d")
	var eyes := skin("182d29")
	var light := skin("d9cfaa")
	ellipsoid(body, "Torso", Vector3(0, 0.22, -0.035), Vector3(0.46, 0.3, 0.55), hide)
	head = joint(body, "Head", Vector3(0, 0.24, 0.245))
	ellipsoid(head, "Skull", Vector3.ZERO, Vector3(0.32, 0.19, 0.23), hide)
	face(head, 0.09, 0.103, eyes, light)
	for side in [-1.0, 1.0]:
		ellipsoid(head, "Nostril" + str(side), Vector3(side * 0.045, 0.07, 0.08), Vector3(0.024, 0.018, 0.03), eyes)
		for row in [0, 1]:
			limb(body, ("Front" if row == 0 else "Hind") + ("Left" if side < 0 else "Right"), Vector3(side * 0.21, 0.15, 0.14 if row == 0 else -0.19), 0.14, 0.085, hide, true)
	for index in range(3):
		var shell := joint(body, "Plate%d" % index, Vector3(0, 0.34, 0.12 - index * 0.17))
		ellipsoid(shell, "Shield", Vector3.ZERO, Vector3(0.45, 0.115, 0.23), plate)
		var stalk := joint(shell, "Reed%d" % index, Vector3(0.055 * (-1 if index % 2 else 1), 0.045, -0.03))
		stalk.rotation.z = 0.17 * (index - 1)
		taper(stalk, "Stem", Vector3(0, 0.095, 0), 0.19, 0.009, reed)
		ellipsoid(stalk, "SeedHead", Vector3(0, 0.19, 0), Vector3(0.026, 0.065, 0.026), reed)
	var tail := joint(body, "Tail", Vector3(0, 0.19, -0.29))
	ellipsoid(tail, "Base", Vector3(0, -0.005, -0.075), Vector3(0.17, 0.1, 0.19), hide)
	var tip := joint(tail, "TailTip", Vector3(0, -0.01, -0.14))
	ellipsoid(tip, "Paddle", Vector3(0, 0, -0.06), Vector3(0.12, 0.045, 0.17), hide)

func build_bellroot() -> void:
	var bulb := skin("bd9674")
	var root_skin := skin("886e52")
	var leaf := skin("66835c")
	var pale := skin("d9cc96")
	var eyes := skin("25362a")
	ellipsoid(body, "Bulb", Vector3(0, 0.22, 0), Vector3(0.3, 0.31, 0.28), bulb)
	head = joint(body, "Head", Vector3(0, 0.18, 0.117))
	face(head, 0.057, 0.02, eyes, pale)
	ellipsoid(head, "Mouth", Vector3(0, -0.035, 0.023), Vector3(0.033, 0.013, 0.013), root_skin)
	for side in [-1.0, 1.0]:
		for row in [0, 1]:
			limb(body, ("Front" if row == 0 else "Hind") + ("Left" if side < 0 else "Right"), Vector3(side * 0.13, 0.13, 0.08 if row == 0 else -0.09), 0.12, 0.065, root_skin)
	var canopy := joint(body, "Canopy", Vector3(0, 0.365, 0))
	taper(canopy, "Stem", Vector3(0, 0.032, 0), 0.085, 0.027, root_skin)
	for index in range(6):
		var angle := TAU * index / 6.0
		var base := joint(canopy, "Leaf%d" % index, Vector3(sin(angle) * 0.03, 0, cos(angle) * 0.03))
		base.rotation.y = angle
		base.rotation.x = -0.4
		ellipsoid(base, "Blade", Vector3(0, -0.065, 0.095), Vector3(0.16, 0.05, 0.28), leaf)
		var tip := joint(base, "LeafTip%d" % index, Vector3(0, -0.065, 0.19))
		taper(tip, "Point", Vector3(0, -0.03, 0), 0.09, 0.038, leaf).rotation.x = -0.65

func animate(seconds: float, bob_pixels: float, bob_cycles: float) -> void:
	# Existing callers own elapsed time (pause and hidden-view policies stay intact).
	super.animate(seconds, bob_pixels, bob_cycles)
	position.y = ground_y
	shadow.position.y = 0.015
	if rig == null:
		return
	var wave := sin(seconds * TAU * idle_rate + phase) * idle_strength
	for key in rest_transforms:
		joints[key].transform = rest_transforms[key]
	body.scale = Vector3(1.0 + wave * 0.012, 1.0 + wave * 0.018, 1.0 + wave * 0.012)
	body.position.y = -0.008 if stance == "rest" else 0.0
	if ground_motion.initialized:
		body.position.y -= 0.03
	head.rotation.y = sin(seconds * TAU * idle_rate * 0.37 + phase) * 0.09 * idle_strength
	if stance == "alert":
		head.rotation.x = -0.1
	# One characteristic gesture during each rest cycle, or explicitly cued for review.
	var resting: bool = stance == "rest" and ground_motion.speed <= 0.001 and float(traversal_visual.get("amount", 0)) <= 0.001
	var gesture := pow(maxf(0, sin(seconds * TAU * idle_rate * 0.2 + phase)), 12.0) * idle_strength if resting else 0.0
	var progress := clampf((seconds - action_started) / action_seconds, 0.0, 1.0)
	var pulse := sin(progress * PI)
	if action == "signature" and progress < 1.0:
		gesture = pulse
	elif action == "attack":
		body.rotation.x = pulse * 0.15
		head.rotation.x -= pulse * 0.18
	elif action == "hit":
		body.rotation.x = -pulse * 0.12
		body.scale.y *= 1.0 - pulse * 0.08
	animate_features(seconds, wave, gesture)
	var free_amount: float = traversal_visual.get("amount", 0.0)
	if free_amount < 1.0:
		ground_motion.apply(self, rig, model_scale, released_support(gesture))
	else:
		rig.rotation.y = ground_motion.heading
	apply_traversal_pose(free_amount)
	update_membranes()

## Override for a signature gesture that intentionally lifts one support.
func released_support(gesture: float) -> String:
	return "FrontLeft" if body_plan == 1 and gesture > 0.05 else ""

func blend_joint(key: String, target: Vector3, amount: float) -> void:
	if not joints.has(key):
		return
	var node: Node3D = joints[key]
	node.quaternion = node.quaternion.slerp(Quaternion.from_euler(target), amount)

func apply_traversal_pose(amount: float) -> void:
	if traversal_visual.is_empty():
		return
	position.y = traversal_visual.height
	var clock: float = traversal_visual.clock
	if traversal_visual.kind == "flight":
		var flap := sin(clock * TAU * wingbeat_rate + phase)
		for side in [-1.0, 1.0]:
			var suffix := "Left" if side < 0 else "Right"
			blend_joint("Wing" + suffix, Vector3(0, 0, side * flap * 0.8), amount)
			blend_joint("WingElbow" + suffix, Vector3(0, side * 0.12, -side * 0.16), amount)
			blend_joint("Wrist" + suffix, Vector3(0, 0, side * flap * 0.15), amount)
			blend_joint("Hind" + suffix, Vector3(0.8, 0, 0), amount)
			blend_joint("Hind" + suffix + "Knee", Vector3(-0.8, 0, 0), amount)
		body.rotation.z = lerpf(body.rotation.z, clampf(-turn_velocity * 0.06, -0.3, 0.3), amount)
		body.rotation.x += minf(ground_motion.speed, 2.0) * 0.04 * amount
	else:
		var cycle := clock * TAU * swim_stroke_rate + phase
		for index in range(4):
			var key: String = ["FrontLeft", "HindRight", "FrontRight", "HindLeft"][index]
			var stroke := sin(cycle + (0.0 if index < 2 else PI))
			blend_joint(key, Vector3(stroke * 0.65, 0, 0), amount)
			blend_joint(key + "Knee", Vector3(-absf(stroke) * 0.45, 0, 0), amount)
		blend_joint("Tail", Vector3(0, sin(cycle) * 0.3, 0), amount)
		blend_joint("TailTip", Vector3(0, sin(cycle - 0.5) * 0.25, 0), amount)
		position.y += sin(cycle * 0.5) * 0.012 * amount
	shadow.position.y = ground_y - position.y + 0.015

## Secondary joints only; the shared solver runs afterward to preserve contacts.
func animate_features(seconds: float, wave: float, gesture: float) -> void:
	match body_plan:
		0: # Open the listening crown without steering the actor.
			joints.EarLeft.rotation.z += wave * 0.09 + gesture * 0.25
			joints.EarRight.rotation.z -= wave * 0.09 + gesture * 0.25
			joints.WingLeft.rotation.z += wave * 0.018
			joints.WingRight.rotation.z -= wave * 0.018
		1: # Lift a forefoot to groom the nearest plate.
			for index in range(3):
				joints["Reed%d" % index].rotation.z += sin(seconds * TAU * idle_rate + index * 0.6) * 0.045 * idle_strength
			joints.Tail.rotation.y = wave * 0.035
			joints.FrontLeft.rotation.x -= gesture * 0.5
			joints.Plate0.rotation.x += gesture * 0.09
		2: # Gather the leaf skirt around the bulb, then release.
			for index in range(6):
				joints["Leaf%d" % index].rotation.x += wave * 0.035 + gesture * 0.25

func preview_bounds() -> AABB:
	# Conservative envelope includes idle ears, reeds, leaf tips and folded wings.
	var dimensions := [Vector3(0.95, 0.58, 0.47), Vector3(0.7, 0.67, 1.02), Vector3(0.6, 0.51, 0.6)][body_plan] as Vector3
	var origin := Vector3(-dimensions.x * 0.5, 0, -dimensions.z * 0.5)
	if body_plan == 1:
		origin.z = -0.61
	return AABB(origin * model_scale, dimensions * model_scale).grow(0.08 * model_scale)
