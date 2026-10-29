extends "res://scripts/sols/presentation/sol_creature.gd"
const Parts = preload("res://scripts/sols/presentation/sol_model_parts.gd")

func build_model() -> void:
	var tissue := skin("8f91a6")
	var pale := skin("d6ccc0")
	var dark := skin("242936")
	var clear := skin("b7c4cb")
	clear.albedo_color.a = 0.28
	clear.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS
	ellipsoid(body, "OpaqueCore", Vector3(0, 0.2, 0), Vector3(0.2, 0.14, 0.2), tissue)
	for index in range(3):
		var angle := TAU * index / 3.0
		Parts.leg(self, "Tripod%d" % index, Vector3(sin(angle) * 0.1, 0.17, cos(angle) * 0.1), 0.16, 0.045, tissue, index % 2, true)
	var chamber := joint(body, "Chamber", Vector3(0, 0.29, 0))
	ellipsoid(chamber, "LivingMembrane", Vector3.ZERO, Vector3(0.23, 0.23, 0.23), clear)
	for index in range(3):
		var control := joint(chamber, "Ring%d" % index, Vector3(0, (index - 1) * 0.055, 0))
		Parts.ring(control, "AnatomicalRing", Vector3.ZERO, 0.074, pale)
	head = joint(body, "Head", Vector3(0, 0.48, 0.025))
	ellipsoid(head, "RoundHead", Vector3.ZERO, Vector3(0.24, 0.2, 0.22), tissue)
	Parts.eyes(self, 0.07, 0.096, dark, pale)

func animate_features(_seconds: float, wave: float, gesture: float) -> void:
	for index in range(3):
		joints["Ring%d" % index].rotation.x += wave * 0.07 + gesture * (0.25 + index * 0.1)
	head.rotation.z += gesture * 0.12

func preview_bounds() -> AABB:
	return AABB(Vector3(-0.4, -0.13, -0.4) * model_scale, Vector3(0.8, 0.95, 0.85) * model_scale)
