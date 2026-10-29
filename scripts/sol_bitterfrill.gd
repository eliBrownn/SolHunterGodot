extends "res://scripts/sol_creature.gd"
const Parts = preload("res://scripts/sol_model_parts.gd")

func build_model() -> void:
	var flesh := skin("8b9878")
	var frill_skin := skin("a6aa7c")
	var gland := skin("c4b58d")
	var dark := skin("252b29")
	ellipsoid(body, "ContinuousSlugFoot", Vector3(0, 0.11, -0.12), Vector3(0.32, 0.16, 0.65), flesh)
	head = joint(body, "Head", Vector3(0, 0.2, 0.17))
	ellipsoid(head, "BluntFace", Vector3.ZERO, Vector3(0.28, 0.19, 0.23), flesh)
	Parts.eyes(self, 0.08, 0.103, dark, gland)
	for side in [-1.0, 1.0]:
		for row in range(2):
			Parts.sole(self, "Sole%s%d" % ["Left" if side < 0 else "Right", row], Vector3(side * 0.075, 0.16, 0.08 - row * 0.3), 0.15, flesh, (row + (0 if side < 0 else 1)) % 2)
	var frill := joint(body, "Frill", Vector3(0, 0.16, -0.1))
	Parts.fan(frill, "LivingSail", PackedVector3Array([Vector3(0, 0, 0.2), Vector3(0.018, 0.21, 0.14), Vector3(-0.018, 0.29, 0), Vector3(0.018, 0.2, -0.15), Vector3(0, 0, -0.27)]), frill_skin)
	for index in range(4):
		ellipsoid(frill, "RoundedGland%d" % index, Vector3(0, 0.18 + sin(index * PI / 3.0) * 0.07, 0.13 - index * 0.09), Vector3.ONE * 0.045, gland)

func animate_features(_seconds: float, wave: float, gesture: float) -> void:
	joints.Frill.rotation.z += wave * 0.08 + gesture * 0.2
	joints.Frill.scale.y *= 1.0 + gesture * 0.12
	head.rotation.x += gesture * 0.12

func preview_bounds() -> AABB:
	return AABB(Vector3(-0.35, -0.13, -0.65) * model_scale, Vector3(0.7, 0.85, 1.15) * model_scale)
