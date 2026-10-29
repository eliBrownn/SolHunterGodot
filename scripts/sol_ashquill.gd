extends "res://scripts/sol_creature.gd"
## Approved direction B: upright bird, two supports and a long arched feather tail.

func build_model() -> void:
	var feather := skin("45454c")
	var edge := skin("aaa49c")
	var down := skin("767079")
	var eyes := skin("181e25")
	ellipsoid(body, "UprightBreast", Vector3(0, 0.32, 0), Vector3(0.32, 0.34, 0.3), feather)
	ellipsoid(body, "SoftBreast", Vector3(0, 0.34, 0.11), Vector3(0.24, 0.27, 0.09), down)
	head = joint(body, "Head", Vector3(0, 0.54, 0.095))
	ellipsoid(head, "Skull", Vector3.ZERO, Vector3(0.24, 0.23, 0.23), feather)
	face(head, 0.072, 0.102, eyes, edge)
	for eye in head.find_children("Eye*", "MeshInstance3D", false, false):
		eye.scale *= 1.35
	taper(head, "Beak", Vector3(0, -0.015, 0.145), 0.09, 0.035, edge).rotation.x = PI * 0.5
	var crest := joint(head, "Crest", Vector3(0, 0.075, -0.035))
	for index in range(3):
		ellipsoid(crest, "Down%d" % index, Vector3((index - 1) * 0.035, 0.025, -0.035), Vector3(0.055, 0.085, 0.12), down).rotation.x = -0.35
	for side in [-1.0, 1.0]:
		var suffix := "Left" if side < 0 else "Right"
		limb(body, "Front" + suffix, Vector3(side * 0.08, 0.21, 0.015), 0.2, 0.045, edge)
		var wing := joint(body, "Wing" + suffix, Vector3(side * 0.14, 0.37, -0.015))
		for index in range(3):
			ellipsoid(wing, "FoldedFeather%d" % index, Vector3(side * index * 0.012, -0.035 - index * 0.025, -index * 0.035), Vector3(0.055, 0.17, 0.23), feather if index % 2 == 0 else down).rotation.x = -0.35
	var tail := joint(body, "Tail", Vector3(0, 0.29, -0.13))
	# Three ribbons share the same arch, but have independently visible pale edges.
	var points := [Vector3.ZERO, Vector3(0, 0.12, -0.1), Vector3(0, 0.2, -0.23), Vector3(0, 0.17, -0.36), Vector3(0, 0.08, -0.48)]
	for row in range(3):
		for index in range(4):
			var start: Vector3 = points[index] + Vector3((row - 1) * 0.06, row * 0.012, row * 0.025)
			var finish: Vector3 = points[index + 1] + Vector3((row - 1) * 0.07, row * 0.012, row * 0.025)
			var segment := ellipsoid(tail, "TailFeather%d_%d" % [row, index], (start + finish) * 0.5, Vector3(0.065, 0.025, start.distance_to(finish) + 0.035), feather if row != 1 else edge)
			segment.quaternion = Quaternion(Vector3.BACK, (finish - start).normalized())

func animate_features(_seconds: float, wave: float, gesture: float) -> void:
	joints.Crest.rotation.x += wave * 0.08
	joints.Tail.rotation.y += wave * 0.06 - clampf(turn_velocity * 0.015, -0.15, 0.15)
	joints.Tail.rotation.x += gesture * 0.12
	joints.WingLeft.rotation.z += gesture * 0.32
	joints.WingRight.rotation.z -= gesture * 0.12
	head.rotation.y += gesture * 0.7
	head.rotation.x += gesture * 0.45
	# Puffing the torso retains a distinctly avian frame and does not move contacts.
	body.scale.x *= 1.0 + gesture * 0.08

func preview_bounds() -> AABB:
	return AABB(Vector3(-0.42, -0.14, -1.05) * model_scale, Vector3(0.84, 1.02, 1.55) * model_scale)
