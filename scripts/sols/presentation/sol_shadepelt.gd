extends "res://scripts/sols/presentation/sol_creature.gd"
const Parts = preload("res://scripts/sols/presentation/sol_model_parts.gd")

func build_model() -> void:
	var fur := skin("5f5d70")
	var mantle := skin("464859")
	var face_skin := skin("b2a4a0")
	var dark := skin("202a34")
	ellipsoid(body, "LowFurredTorso", Vector3(0, 0.22, -0.09), Vector3(0.26, 0.23, 0.45), fur)
	head = joint(body, "Head", Vector3(0, 0.32, 0.16))
	ellipsoid(head, "ExpressiveFace", Vector3.ZERO, Vector3(0.23, 0.21, 0.22), face_skin)
	ellipsoid(head, "ShortMuzzle", Vector3(0, -0.035, 0.1), Vector3(0.12, 0.08, 0.12), fur)
	Parts.eyes(self, 0.065, 0.095, dark, face_skin)
	for side in [-1.0, 1.0]:
		var suffix := "Left" if side < 0 else "Right"
		Parts.leg(self, "Front" + suffix, Vector3(side * 0.095, 0.17, 0.1), 0.16, 0.045, fur, 0 if side < 0 else 1)
		Parts.leg(self, "Hind" + suffix, Vector3(side * 0.095, 0.17, -0.23), 0.16, 0.045, fur, 1 if side < 0 else 0)
		var shoulder := joint(body, "Mantle" + suffix, Vector3(side * 0.08, 0.32, 0.07))
		for index in range(3):
			ellipsoid(shoulder, "ShoulderStrand%d" % index, Vector3(side * (0.04 + index * 0.015), -0.04 - index * 0.025, 0.035 - index * 0.06), Vector3(0.05, 0.22, 0.12), mantle).rotation.z = side * 0.18
	var tail := joint(body, "Tail", Vector3(0, 0.19, -0.29))
	ellipsoid(tail, "SoftTail", Vector3(0, 0.025, -0.13), Vector3(0.07, 0.08, 0.3), fur)

func animate_features(_seconds: float, wave: float, gesture: float) -> void:
	joints.MantleLeft.rotation.z += gesture * 0.25 + wave * 0.025
	joints.MantleRight.rotation.z -= gesture * 0.25 + wave * 0.025
	joints.Tail.rotation.y += wave * 0.08
	head.rotation.x -= gesture * 0.12

func preview_bounds() -> AABB:
	return AABB(Vector3(-0.4, -0.13, -0.75) * model_scale, Vector3(0.8, 0.85, 1.3) * model_scale)
