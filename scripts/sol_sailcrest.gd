extends "res://scripts/sol_creature.gd"
const Parts = preload("res://scripts/sol_model_parts.gd")

func build_model() -> void:
	var hide := skin("9aaca5")
	var membrane := skin("c0b8a0")
	var ridge := skin("657e80")
	var dark := skin("25313b")
	ellipsoid(body, "LightTorso", Vector3(0, 0.25, 0), Vector3(0.18, 0.23, 0.29), hide)
	head = joint(body, "Head", Vector3(0, 0.38, 0.13))
	ellipsoid(head, "NarrowFace", Vector3.ZERO, Vector3(0.16, 0.17, 0.22), hide)
	Parts.eyes(self, 0.05, 0.095, dark, membrane)
	for side in [-1.0, 1.0]:
		var suffix := "Left" if side < 0 else "Right"
		Parts.leg(self, "Front" + suffix, Vector3(side * 0.06, 0.18, -0.02), 0.17, 0.035, ridge, 0 if side < 0 else 1)
		var wing := joint(body, "Sail" + suffix, Vector3(side * 0.06, 0.29, 0.035))
		wing.rotation.z = -side * 0.45
		var points := PackedVector3Array([Vector3.ZERO, Vector3(side * 0.36, 0, 0.035), Vector3(side * 0.26, -0.02, -0.2), Vector3(0, -0.08, -0.2)])
		Parts.fan(wing, "KiteMembrane", points, membrane)
		Parts.beam(wing, "LeadingRib", points[0], points[1], 0.02, 0.025, ridge)
	var tail := joint(body, "Tail", Vector3(0, 0.2, -0.12))
	ellipsoid(tail, "TailStem", Vector3(0, 0, -0.16), Vector3(0.04, 0.045, 0.34), ridge)
	Parts.fan(tail, "SteeringCrest", PackedVector3Array([Vector3(0, 0, -0.04), Vector3(0, 0.19, -0.23), Vector3(0, 0, -0.34)]), hide)

func animate_features(_seconds: float, wave: float, gesture: float) -> void:
	joints.SailLeft.rotation.z += wave * 0.06 + gesture * 0.3
	joints.SailRight.rotation.z -= wave * 0.06 + gesture * 0.3
	joints.Tail.rotation.y += wave * 0.08 - clampf(turn_velocity * 0.02, -0.2, 0.2)
	head.rotation.z += gesture * 0.15

func preview_bounds() -> AABB:
	return AABB(Vector3(-0.55, -0.13, -0.6) * model_scale, Vector3(1.1, 0.85, 1.15) * model_scale)
