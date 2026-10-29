extends "res://scripts/sol_creature.gd"
const Parts = preload("res://scripts/sol_model_parts.gd")

func build_model() -> void:
	var tissue := skin("a7a9b4")
	var veil := skin("d0c9cd")
	var inside := skin("777e96")
	var dark := skin("292c3e")
	ellipsoid(body, "LivingTorso", Vector3(0, 0.24, 0), Vector3(0.25, 0.25, 0.24), tissue)
	head = joint(body, "Head", Vector3(0, 0.41, 0.055))
	ellipsoid(head, "ShyFace", Vector3.ZERO, Vector3(0.23, 0.2, 0.2), inside)
	Parts.eyes(self, 0.065, 0.087, dark, veil)
	ellipsoid(head, "VeilCrown", Vector3(0, 0.075, -0.015), Vector3(0.32, 0.12, 0.3), veil)
	for index in range(5):
		var angle := TAU * index / 5.0
		var fold := joint(head, "Veil%d" % index, Vector3(sin(angle) * 0.11, 0.04, cos(angle) * 0.1))
		ellipsoid(fold, "LivingDrape", Vector3(sin(angle) * 0.025, -0.11, cos(angle) * 0.035), Vector3(0.11, 0.27, 0.07), veil)
	for side in [-1.0, 1.0]:
		var suffix := "Left" if side < 0 else "Right"
		Parts.leg(self, "Front" + suffix, Vector3(side * 0.075, 0.16, 0), 0.15, 0.045, inside, 0 if side < 0 else 1, true)
		var arm := joint(body, "Arm" + suffix, Vector3(side * 0.14, 0.28, 0.01))
		ellipsoid(arm, "GraspingHand", Vector3(0, -0.065, 0.035), Vector3(0.055, 0.14, 0.08), inside)

func animate_features(_seconds: float, wave: float, gesture: float) -> void:
	for index in range(5):
		joints["Veil%d" % index].rotation.x += wave * 0.025 + gesture * 0.3
	joints.ArmLeft.rotation.x -= gesture * 0.2
	joints.ArmRight.rotation.x -= gesture * 0.2

func preview_bounds() -> AABB:
	return AABB(Vector3(-0.4, -0.13, -0.4) * model_scale, Vector3(0.8, 0.95, 0.95) * model_scale)
