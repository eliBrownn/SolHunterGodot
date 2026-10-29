extends "res://scripts/sols/presentation/sol_creature.gd"
const Parts = preload("res://scripts/sols/presentation/sol_model_parts.gd")

func build_model() -> void:
	var tissue := skin("8b809a")
	var edge := skin("c3b1b8")
	var dark := skin("292638")
	for index in range(3):
		var band := joint(body, "Band%d" % index, Vector3(0, 0.23, 0))
		band.rotation.y = (index - 1) * 0.9
		var points := [Vector3(-0.16, -0.12, 0), Vector3(0.16, -0.12, 0), Vector3(0, 0.2, 0)]
		for corner in range(3):
			Parts.beam(band, "Ribbon%d" % corner, points[corner], points[(corner + 1) % 3], 0.055, 0.075, tissue if index != 1 else edge)
		var angle := TAU * index / 3.0
		Parts.sole(self, "BandEnd%d" % index, Vector3(sin(angle) * 0.12, 0.16, cos(angle) * 0.12), 0.09, tissue, index % 2)
	head = joint(body, "Head", Vector3(0, 0.23, 0.055))
	ellipsoid(head, "CentralFace", Vector3.ZERO, Vector3(0.15, 0.13, 0.13), tissue)
	Parts.eyes(self, 0.04, 0.058, dark, edge)

func animate_features(_seconds: float, wave: float, gesture: float) -> void:
	for index in range(3):
		joints["Band%d" % index].rotation.y += wave * 0.025 + gesture * (0.35 if index == 0 else -0.08)
	head.rotation.z += gesture * 0.1

func preview_bounds() -> AABB:
	return AABB(Vector3(-0.45, -0.13, -0.45) * model_scale, Vector3(0.9, 0.82, 0.95) * model_scale)
