extends "res://scripts/sols/presentation/sol_creature.gd"
const Parts = preload("res://scripts/sols/presentation/sol_model_parts.gd")

func build_model() -> void:
	var shell := skin("7d8f89")
	var seam := skin("b4aa87")
	var dark := skin("24342e")
	ellipsoid(body, "BroadCarapace", Vector3(0, 0.23, -0.05), Vector3(0.41, 0.21, 0.47), shell)
	for side in [-1.0, 1.0]:
		var suffix := "Left" if side < 0 else "Right"
		var plate := joint(body, "Plate" + suffix, Vector3(side * 0.09, 0.28, -0.09))
		ellipsoid(plate, "BackPlate", Vector3(side * 0.025, 0, 0), Vector3(0.2, 0.11, 0.35), seam)
		for row in range(3):
			var title := "Leg" + suffix + str(row)
			Parts.leg(self, title, Vector3(side * 0.19, 0.17, 0.14 - row * 0.17), 0.16, 0.035, dark, (row + (0 if side < 0 else 1)) % 2)
			if row == 0:
				var hook := joint(joints[title + "Foot"], "Clasp" + suffix, Vector3(side * 0.018, 0.04, 0.06))
				ellipsoid(hook, "HookPalm", Vector3(0, 0.035, 0.025), Vector3(0.055, 0.1, 0.09), seam)
				ellipsoid(hook, "CurvedTip", Vector3(-side * 0.025, 0.08, 0.03), Vector3(0.07, 0.025, 0.035), shell)
	head = joint(body, "Head", Vector3(0, 0.25, 0.22))
	ellipsoid(head, "Face", Vector3.ZERO, Vector3(0.24, 0.18, 0.2), shell)
	Parts.eyes(self, 0.07, 0.087, dark, seam)
	for side in [-1.0, 1.0]:
		ellipsoid(head, "Feeler" + str(side), Vector3(side * 0.07, 0.1, 0.025), Vector3(0.022, 0.14, 0.03), dark).rotation.z = -side * 0.3

func animate_features(_seconds: float, wave: float, gesture: float) -> void:
	joints.ClaspLeft.rotation.z -= gesture * 0.5
	joints.ClaspRight.rotation.z += gesture * 0.5
	joints.PlateLeft.rotation.z += wave * 0.03
	joints.PlateRight.rotation.z -= wave * 0.03

func preview_bounds() -> AABB:
	return AABB(Vector3(-0.48, -0.13, -0.5) * model_scale, Vector3(0.96, 0.85, 1.05) * model_scale)
