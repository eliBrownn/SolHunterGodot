extends "res://scripts/sol_creature.gd"
const Parts = preload("res://scripts/sol_model_parts.gd")

func build_model() -> void:
	var hide := skin("c5ad91")
	var mantle := skin("a5b5a1")
	var pale := skin("e0d3b4")
	var dark := skin("303432")
	ellipsoid(body, "TinyDeerTorso", Vector3(0, 0.27, -0.055), Vector3(0.22, 0.21, 0.33), hide)
	ellipsoid(body, "FineNeckMantle", Vector3(0, 0.36, 0.09), Vector3(0.2, 0.2, 0.18), mantle)
	head = joint(body, "Head", Vector3(0, 0.48, 0.14))
	ellipsoid(head, "AttentiveFace", Vector3.ZERO, Vector3(0.2, 0.22, 0.23), hide)
	ellipsoid(head, "SmallMuzzle", Vector3(0, -0.025, 0.125), Vector3(0.1, 0.08, 0.11), pale)
	Parts.eyes(self, 0.061, 0.103, dark, pale)
	for side in [-1.0, 1.0]:
		var suffix := "Left" if side < 0 else "Right"
		Parts.leg(self, "Front" + suffix, Vector3(side * 0.075, 0.23, 0.08), 0.22, 0.035, hide, 0 if side < 0 else 1)
		Parts.leg(self, "Hind" + suffix, Vector3(side * 0.075, 0.21, -0.18), 0.2, 0.04, hide, 1 if side < 0 else 0)
		var antler := joint(head, "Antler" + suffix, Vector3(side * 0.065, 0.09, -0.025))
		ellipsoid(antler, "ShortStem", Vector3(0, 0.04, 0), Vector3(0.022, 0.09, 0.022), pale)
		Parts.ring(antler, "AntlerCup", Vector3(0, 0.085, 0), 0.04, mantle)
		ellipsoid(head, "Ear" + suffix, Vector3(side * 0.13, 0.025, -0.01), Vector3(0.12, 0.055, 0.07), hide).rotation.z = side * 0.4
	var tail := joint(body, "Tail", Vector3(0, 0.3, -0.22))
	ellipsoid(tail, "TailTip", Vector3(0, 0.01, -0.035), Vector3(0.055, 0.06, 0.09), mantle)

func animate_features(_seconds: float, wave: float, gesture: float) -> void:
	head.rotation.x += gesture * 0.28
	joints.AntlerLeft.rotation.z += wave * 0.03
	joints.AntlerRight.rotation.z -= wave * 0.03
	joints.Tail.rotation.y += wave * 0.15

func preview_bounds() -> AABB:
	return AABB(Vector3(-0.4, -0.13, -0.5) * model_scale, Vector3(0.8, 1.0, 1.1) * model_scale)
