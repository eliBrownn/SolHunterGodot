extends "res://scripts/sols/presentation/sol_creature.gd"
## Approved direction B: broad forebody, four supports, separately moving soft fins.

func build_model() -> void:
	var hide := skin("74838e")
	var fold := skin("a6aeb8")
	var underside := skin("d3cfc4")
	var eyes := skin("202a32")
	ellipsoid(body, "LongTorso", Vector3(0, 0.19, -0.12), Vector3(0.32, 0.23, 0.55), hide)
	ellipsoid(body, "BroadForebody", Vector3(0, 0.2, 0.13), Vector3(0.46, 0.23, 0.32), hide)
	head = joint(body, "Head", Vector3(0, 0.23, 0.34))
	ellipsoid(head, "FlatSkull", Vector3.ZERO, Vector3(0.5, 0.2, 0.3), hide)
	ellipsoid(head, "SoftJaw", Vector3(0, -0.04, 0.02), Vector3(0.35, 0.065, 0.24), underside)
	face(head, 0.16, 0.13, eyes, underside)
	for eye in head.find_children("Eye*", "MeshInstance3D", false, false):
		eye.scale *= 1.45
	for side in [-1.0, 1.0]:
		var suffix := "Left" if side < 0 else "Right"
		limb(body, "Front" + suffix, Vector3(side * 0.23, 0.21, 0.15), 0.2, 0.09, hide, true)
		limb(body, "Hind" + suffix, Vector3(side * 0.13, 0.16, -0.27), 0.15, 0.05, hide, true)
		for index in range(2):
			var fin := joint(body, "Fin" + suffix + str(index), Vector3(side * (0.18 - index * 0.025), 0.22 - index * 0.018, 0.07 - index * 0.18))
			fin.rotation.z = -side * 0.25
			# Broad opaque lobes stand in for translucent fleshy tissue at blockout cost.
			ellipsoid(fin, "LivingFold", Vector3(side * 0.065, -0.035, -0.055), Vector3(0.2 - index * 0.025, 0.065, 0.24), fold)
	var tail := joint(body, "Tail", Vector3(0, 0.16, -0.36))
	ellipsoid(tail, "TaperedTail", Vector3(0, -0.015, -0.1), Vector3(0.1, 0.075, 0.23), hide)

func animate_features(_seconds: float, wave: float, gesture: float) -> void:
	for side in [-1.0, 1.0]:
		var suffix := "Left" if side < 0 else "Right"
		for index in range(2):
			var fin: Node3D = joints["Fin" + suffix + str(index)]
			fin.rotation.z += -side * wave * 0.04
			# A single leading lobe reaches; the feet stay registered and planted.
			fin.rotation.z += side * gesture * (0.6 if side < 0 and index == 0 else -0.3)
			if side < 0 and index == 0:
				fin.rotation.y += gesture * 0.45
	joints.Tail.rotation.y += wave * 0.08 - clampf(turn_velocity * 0.02, -0.2, 0.2)
	head.rotation.y -= gesture * 0.15

func preview_bounds() -> AABB:
	return AABB(Vector3(-0.65, -0.15, -0.95) * model_scale, Vector3(1.3, 0.86, 1.65) * model_scale)
