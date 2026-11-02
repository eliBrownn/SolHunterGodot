extends "res://scripts/sols/presentation/sol_creature.gd"
## Isolated first-form art prototype. No catalog or expedition changes.
const Parts = preload("res://scripts/sols/presentation/sol_model_parts.gd")
var core_size := 0.4
var core_gap := 0.12
var leaf_droop := 0.0

func uses_custom_visual_core() -> bool:
	return true

func build_model() -> void:
	var plum := skin("895566")
	var root_skin := skin("d5bd91")
	var leaf := skin("788b43")
	var eyes := skin("251e28")
	var pale := skin("fff0d5")
	# Four lobes frame a genuinely open cup, with no solid torso inside it.
	for index in range(4):
		var angle := TAU * index / 4.0 + PI / 4.0
		ellipsoid(body, "BulbLobe%d" % index, Vector3(sin(angle) * 0.16, 0.22, cos(angle) * 0.13), Vector3(0.28, 0.25, 0.23), plum)
	head = joint(body, "Head", Vector3(0, 0.18, 0.245))
	face(head, 0.068, 0.0, eyes, pale)
	for side in [-1.0, 1.0]:
		var suffix := "Left" if side < 0 else "Right"
		for row in range(2):
			limb(body, ("Front" if row == 0 else "Hind") + suffix, Vector3(side * 0.18, 0.13, 0.10 if row == 0 else -0.10), 0.12, 0.07, root_skin)
		var blade := joint(body, "Leaf" + suffix, Vector3(side * 0.22, 0.30, 0))
		# Folded faceted leaf surface: center ridge, broad shoulders, rounded tip.
		var points := PackedVector3Array([
			Vector3(side * 0.14, 0.025, 0), Vector3.ZERO,
			Vector3(side * 0.12, 0.06, -0.13), Vector3(side * 0.32, -0.04, -0.14),
			Vector3(side * 0.43, -0.20, -0.06), Vector3(side * 0.44, -0.23, 0.04),
			Vector3(side * 0.31, -0.06, 0.15), Vector3(side * 0.12, 0.06, 0.13), Vector3.ZERO])
		Parts.fan(blade, "Blade", points, leaf)
	var tend := joint(body, "TendingRoot", Vector3(0.23, 0.14, 0.17))
	Parts.beam(tend, "RootReach", Vector3.ZERO, Vector3(0.16, 0.01, 0.13), 0.025, 0.025, root_skin)
	Parts.beam(tend, "RootTip", Vector3(0.16, 0.01, 0.13), Vector3(0.22, 0.07, 0.17), 0.018, 0.018, root_skin)
	visual_core = preload("res://scripts/sols/presentation/sol_visual_core.gd").new()
	visual_core.name = "VisualCore"
	visual_core.configure(core_size, {"wisp_spread": 0.04, "wisp_length": 0.3, "core_tint": "fff0d5"})
	body.add_child(visual_core)
	wisp_head = visual_core
	update_core()

func update_core() -> void:
	if visual_core == null: return
	# Reserve a conservative particle envelope, above all bulb tissue.
	visual_core.position = Vector3(0, 0.40 + core_gap + visual_core.envelope_radius(), 0)

func animate_features(seconds: float, wave: float, gesture: float) -> void:
	for side in [-1.0, 1.0]:
		var blade: Node3D = joints["LeafLeft" if side < 0 else "LeafRight"]
		blade.rotation.z = side * (leaf_droop + wave * 0.045)
	joints.TendingRoot.rotation.x = -gesture * 0.4
	joints.TendingRoot.rotation.y = gesture * 0.25
	update_core()
	visual_core.position.y += sin(seconds * 1.4) * 0.008

func released_support(_gesture: float) -> String:
	return ""

func preview_bounds() -> AABB:
	return AABB(Vector3(-0.75, -0.1, -0.45) * model_scale, Vector3(1.5, 1.3, 1.0) * model_scale)
