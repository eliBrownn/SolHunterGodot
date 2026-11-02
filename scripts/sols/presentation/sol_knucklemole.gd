extends "res://scripts/sols/presentation/sol_creature.gd"
const Parts = preload("res://scripts/sols/presentation/sol_model_parts.gd")

func build_model() -> void:
	var hide := skin("8b776c")
	var paw := skin("b99e86")
	var claw := skin("ded0b0")
	var dark := skin("26252a")
	ellipsoid(body, "LowWedge", Vector3(0, 0.2, -0.08), Vector3(0.35, 0.26, 0.46), hide)
	head = joint(body, "Head", Vector3(0, 0.25, 0.2))
	ellipsoid(head, "SoftSkull", Vector3.ZERO, Vector3(0.27, 0.22, 0.24), hide)
	ellipsoid(head, "ProbeNose", Vector3(0, -0.025, 0.14), Vector3(0.12, 0.08, 0.16), paw)
	face(head, 0.085, 0.095, dark, claw)
	for side in [-1.0, 1.0]:
		var suffix := "Left" if side < 0 else "Right"
		Parts.leg(self, "Front" + suffix, Vector3(side * 0.18, 0.2, 0.14), 0.19, 0.095, paw, 0 if side < 0 else 1, true)
		Parts.leg(self, "Hind" + suffix, Vector3(side * 0.11, 0.16, -0.23), 0.15, 0.05, hide, 1 if side < 0 else 0)
		var foot: Node3D = joints["Front" + suffix + "Foot"]
		ellipsoid(foot, "ShovelPalm", Vector3(side * 0.025, 0.018, 0.035), Vector3(0.2, 0.055, 0.17), paw)
		for index in range(3):
			ellipsoid(foot, "Claw%d" % index, Vector3((index - 1) * 0.045, 0.018, 0.12), Vector3(0.025, 0.025, 0.1), claw)

func animate_features(_seconds: float, wave: float, gesture: float) -> void:
	head.rotation.x += wave * 0.04 + gesture * 0.2
	head.rotation.y += gesture * 0.25

func preview_bounds() -> AABB:
	return AABB(Vector3(-0.48, -0.13, -0.55) * model_scale, Vector3(0.96, 0.75, 1.15) * model_scale)
