extends "res://scripts/sols/presentation/sol_creature.gd"
const Parts = preload("res://scripts/sols/presentation/sol_model_parts.gd")

func build_model() -> void:
	var hide := skin("8d9b83")
	var scale_skin := skin("b8ae89")
	var pale := skin("d9c7a7")
	var dark := skin("2c312a")
	ellipsoid(body, "YoungDragonTorso", Vector3(0, 0.23, -0.05), Vector3(0.29, 0.25, 0.4), hide)
	for index in range(3):
		ellipsoid(body, "RoundScale%d" % index, Vector3(0, 0.35, 0.04 - index * 0.105), Vector3(0.18, 0.075, 0.15), scale_skin)
	head = joint(body, "Head", Vector3(0, 0.34, 0.2))
	ellipsoid(head, "BigSkull", Vector3.ZERO, Vector3(0.29, 0.25, 0.27), hide)
	ellipsoid(head, "BluntSnout", Vector3(0, -0.035, 0.14), Vector3(0.22, 0.13, 0.17), pale)
	Parts.eyes(self, 0.09, 0.113, dark, pale)
	for side in [-1.0, 1.0]:
		var suffix := "Left" if side < 0 else "Right"
		taper(head, "SoftHornBud" + suffix, Vector3(side * 0.105, 0.12, -0.035), 0.065, 0.028, scale_skin)
		Parts.leg(self, "Front" + suffix, Vector3(side * 0.125, 0.18, 0.1), 0.17, 0.06, hide, 0 if side < 0 else 1, true)
		Parts.leg(self, "Hind" + suffix, Vector3(side * 0.12, 0.18, -0.18), 0.17, 0.065, hide, 1 if side < 0 else 0, true)
	var tail := joint(body, "Tail", Vector3(0, 0.2, -0.23))
	var points := [Vector3.ZERO, Vector3(0.12, 0, -0.14), Vector3(0.24, 0, -0.09), Vector3(0.2, 0.02, 0.02)]
	for index in range(3):
		var segment := joint(tail, "TailCurl%d" % index, points[index])
		var end: Vector3 = points[index + 1] - points[index]
		var mesh := ellipsoid(segment, "RoundTailSegment", end * 0.5, Vector3(0.08 - index * 0.015, 0.075 - index * 0.012, end.length() + 0.04), hide)
		mesh.quaternion = Quaternion(Vector3.BACK, end.normalized())

func animate_features(_seconds: float, wave: float, gesture: float) -> void:
	joints.Tail.rotation.y += wave * 0.06 + gesture * 0.25
	head.rotation.x += gesture * 0.16

func preview_bounds() -> AABB:
	return AABB(Vector3(-0.42, -0.13, -0.6) * model_scale, Vector3(0.94, 0.95, 1.25) * model_scale)
