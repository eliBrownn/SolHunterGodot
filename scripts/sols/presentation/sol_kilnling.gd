extends "res://scripts/sols/presentation/sol_creature.gd"
const Parts = preload("res://scripts/sols/presentation/sol_model_parts.gd")

func build_model() -> void:
	var ceramic := skin("bb9b7b")
	var seam := skin("7e8581")
	var pale := skin("ddcbb0")
	var dark := skin("2c3336")
	ellipsoid(body, "LivingSeamCore", Vector3(0, 0.29, 0), Vector3(0.27, 0.3, 0.25), seam)
	for index in range(4):
		var angle := TAU * index / 4.0
		var plate := joint(body, "Plate%d" % index, Vector3(sin(angle) * 0.11, 0.29, cos(angle) * 0.1))
		plate.rotation.y = angle
		ellipsoid(plate, "CeramicPatch", Vector3.ZERO, Vector3(0.18, 0.25, 0.08), ceramic)
	Parts.ring(body, "LivingVesselRim", Vector3(0, 0.43, 0), 0.14, pale)
	head = joint(body, "Head", Vector3(0, 0.39, 0.105))
	ellipsoid(head, "SoftFace", Vector3.ZERO, Vector3(0.2, 0.16, 0.13), seam)
	Parts.eyes(self, 0.06, 0.057, dark, pale)
	for side in [-1.0, 1.0]:
		var suffix := "Left" if side < 0 else "Right"
		Parts.leg(self, "Front" + suffix, Vector3(side * 0.08, 0.16, 0), 0.15, 0.07, seam, 0 if side < 0 else 1, true)
		var hand := joint(body, "Hand" + suffix, Vector3(side * 0.16, 0.32, 0.025))
		ellipsoid(hand, "ShortArm", Vector3(0, -0.055, 0.015), Vector3(0.06, 0.14, 0.075), seam)
		ellipsoid(hand, "RoundPalm", Vector3(0, -0.11, 0.045), Vector3(0.08, 0.055, 0.065), ceramic)

func animate_features(_seconds: float, wave: float, gesture: float) -> void:
	joints.HandLeft.rotation.z -= gesture * 0.65
	joints.HandRight.rotation.z += gesture * 0.65
	for index in range(4):
		joints["Plate%d" % index].rotation.z += wave * 0.015

func preview_bounds() -> AABB:
	return AABB(Vector3(-0.4, -0.13, -0.35) * model_scale, Vector3(0.8, 0.85, 0.85) * model_scale)
