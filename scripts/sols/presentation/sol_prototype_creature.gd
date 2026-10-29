extends SolCreature
## Temporary creature art for legacy identities and uncatalogued Sols.
## These silhouettes do not approve a species or change its gameplay data.

@export_enum("Unassigned", "Seedmote", "Bramblepup", "Ashkit", "Rillfin") var prototype_kind := 0

func build_model() -> void:
	var colors := ["8c8195", "b4ad76", "7a8661", "b97859", "658d9c"]
	var hide := skin(colors[prototype_kind])
	var light := skin("e6d6b2")
	var accent := skin(["b6a1c0", "5b8254", "52694f", "704d48", "b4c9b7"][prototype_kind])
	var eyes := skin("202631")
	match prototype_kind:
		1: # Bloom: split seed husk, root legs and broad cotyledons; no mammal anatomy.
			ellipsoid(body, "SeedHusk", Vector3(0, 0.24, 0), Vector3(0.29, 0.32, 0.23), hide)
			ellipsoid(body, "HuskSeam", Vector3(0, 0.24, 0.112), Vector3(0.018, 0.24, 0.015), accent)
			head = joint(body, "Head", Vector3(0, 0.34, 0.025))
			face(head, 0.065, 0.1, eyes, light)
			for side in [-1.0, 1.0]:
				limb(body, "FrontLeft" if side < 0 else "FrontRight", Vector3(side * 0.08, 0.12, 0), 0.11, 0.035, accent, true)
				ellipsoid(body, "LeafArm", Vector3(side * 0.17, 0.23, 0), Vector3(0.18, 0.045, 0.08), accent).rotation.z = side * 0.6
		2: # Beast: long-backed hound with a projecting nose, broad paws and low ears.
			ellipsoid(body, "HoundTorso", Vector3(0, 0.29, -0.055), Vector3(0.28, 0.25, 0.56), hide)
			head = joint(body, "Head", Vector3(0, 0.35, 0.25))
			ellipsoid(head, "Skull", Vector3.ZERO, Vector3(0.22, 0.21, 0.25), hide)
			ellipsoid(head, "LongMuzzle", Vector3(0, -0.025, 0.14), Vector3(0.15, 0.11, 0.2), light)
			ellipsoid(head, "Nose", Vector3(0, -0.01, 0.235), Vector3(0.09, 0.065, 0.045), eyes)
			face(head, 0.069, 0.104, eyes, light)
			for side in [-1.0, 1.0]:
				var ear := joint(head, "EarLeft" if side < 0 else "EarRight", Vector3(side * 0.12, 0.035, -0.02))
				ellipsoid(ear, "FoldedEar", Vector3(side * 0.025, -0.04, 0), Vector3(0.09, 0.18, 0.09), accent)
				limb(body, "FrontLeft" if side < 0 else "FrontRight", Vector3(side * 0.11, 0.21, 0.15), 0.2, 0.065, hide)
				limb(body, "HindLeft" if side < 0 else "HindRight", Vector3(side * 0.11, 0.21, -0.23), 0.2, 0.075, hide)
			var tail := joint(body, "Tail", Vector3(0, 0.29, -0.31))
			ellipsoid(tail, "Brush", Vector3(0, 0.025, -0.14), Vector3(0.11, 0.11, 0.33), accent)
			for index in range(3):
				taper(body, "Bramble%d" % index, Vector3(0, 0.45, -0.18 + index * 0.1), 0.12, 0.045, accent)
		3: # CinderKin: upright charcoal kitten, ash ruff and cinder-shaped tail tuft.
			ellipsoid(body, "UprightTorso", Vector3(0, 0.29, 0), Vector3(0.22, 0.37, 0.19), hide)
			ellipsoid(body, "AshRuff", Vector3(0, 0.43, 0), Vector3(0.33, 0.13, 0.25), light)
			head = joint(body, "Head", Vector3(0, 0.53, 0.025))
			ellipsoid(head, "Skull", Vector3.ZERO, Vector3(0.25, 0.2, 0.21), hide)
			face(head, 0.065, 0.102, eyes, light)
			for side in [-1.0, 1.0]:
				var ear := joint(head, "EarLeft" if side < 0 else "EarRight", Vector3(side * 0.09, 0.085, 0))
				taper(ear, "CinderEar", Vector3(0, 0.045, 0), 0.14, 0.055, accent)
				limb(body, "FrontLeft" if side < 0 else "FrontRight", Vector3(side * 0.085, 0.14, 0), 0.13, 0.07, accent)
				var arm := joint(body, "ArmLeft" if side < 0 else "ArmRight", Vector3(side * 0.13, 0.36, 0))
				ellipsoid(arm, "Paw", Vector3(0, -0.07, 0.04), Vector3(0.065, 0.17, 0.075), hide)
			var tail := joint(body, "Tail", Vector3(0, 0.18, -0.1))
			ellipsoid(tail, "CurledTail", Vector3(0, 0.11, -0.13), Vector3(0.06, 0.25, 0.17), hide)
			taper(tail, "CinderTuft", Vector3(0, 0.29, -0.15), 0.2, 0.085, accent)
		4: # Abyssal: low amphibious fish body, lateral fins and a deep tail paddle.
			ellipsoid(body, "StreamlinedTorso", Vector3(0, 0.16, -0.06), Vector3(0.3, 0.2, 0.58), hide)
			head = joint(body, "Head", Vector3(0, 0.18, 0.23))
			ellipsoid(head, "FlatSkull", Vector3.ZERO, Vector3(0.33, 0.15, 0.27), hide)
			face(head, 0.11, 0.115, eyes, light)
			for side in [-1.0, 1.0]:
				var fin := joint(body, "FinLeft" if side < 0 else "FinRight", Vector3(side * 0.14, 0.16, 0.06))
				ellipsoid(fin, "PectoralFan", Vector3(side * 0.075, 0, -0.015), Vector3(0.21, 0.035, 0.23), accent)
				limb(body, "FrontLeft" if side < 0 else "FrontRight", Vector3(side * 0.12, 0.085, 0.12), 0.075, 0.03, hide, true)
				limb(body, "HindLeft" if side < 0 else "HindRight", Vector3(side * 0.12, 0.085, -0.23), 0.075, 0.03, hide, true)
			var tail := joint(body, "Tail", Vector3(0, 0.16, -0.32))
			ellipsoid(tail, "TailStem", Vector3(0, 0, -0.12), Vector3(0.1, 0.1, 0.28), hide)
			ellipsoid(tail, "TailPaddle", Vector3(0, 0.035, -0.28), Vector3(0.045, 0.3, 0.22), accent)
			taper(body, "DorsalFin", Vector3(0, 0.3, -0.1), 0.18, 0.08, accent)
		_: # Neutral diagnostic creature; no class assignment is inferred.
			ellipsoid(body, "Torso", Vector3(0, 0.23, 0), Vector3(0.25, 0.25, 0.3), hide)
			head = joint(body, "Head", Vector3(0, 0.44, 0.08))
			ellipsoid(head, "Skull", Vector3.ZERO, Vector3(0.19, 0.19, 0.2), hide)
			face(head, 0.05, 0.095, eyes, light)
			for side in [-1.0, 1.0]:
				limb(body, "FrontLeft" if side < 0 else "FrontRight", Vector3(side * 0.09, 0.14, 0), 0.13, 0.05, hide)
	if prototype_kind == 1:
		var sprout := joint(head, "Sprout", Vector3(0, 0.09, 0))
		for side in [-1.0, 1.0]:
			ellipsoid(sprout, "Leaf", Vector3(side * 0.06, 0.07, 0), Vector3(0.16, 0.045, 0.08), accent).rotation.z = side * 0.5

func animate_features(_seconds: float, wave: float, gesture: float) -> void:
	if joints.has("Tail"):
		joints.Tail.rotation.y += wave * 0.18 + gesture * 0.3
	if joints.has("EarLeft"):
		joints.EarLeft.rotation.z += wave * 0.06 + gesture * 0.12
		joints.EarRight.rotation.z -= wave * 0.06 + gesture * 0.12
	if joints.has("ArmLeft"):
		joints.ArmLeft.rotation.x += wave * 0.12 + gesture * 0.4
		joints.ArmRight.rotation.x -= wave * 0.12 + gesture * 0.4
	if joints.has("FinLeft"):
		joints.FinLeft.rotation.z += wave * 0.15 + gesture * 0.3
		joints.FinRight.rotation.z -= wave * 0.15 + gesture * 0.3
	if joints.has("Sprout"):
		joints.Sprout.rotation.z += wave * 0.12

func preview_bounds() -> AABB:
	# Each silhouette has its own envelope so the small seed stays readable in menus.
	var origins := [Vector3(-0.25, -0.08, -0.2), Vector3(-0.3, -0.08, -0.2), Vector3(-0.3, -0.08, -0.7), Vector3(-0.3, -0.08, -0.46), Vector3(-0.4, -0.08, -0.81)]
	var sizes := [Vector3(0.5, 0.85, 0.55), Vector3(0.6, 0.75, 0.55), Vector3(0.6, 0.85, 1.34), Vector3(0.6, 1.0, 0.81), Vector3(0.8, 0.7, 1.25)]
	return AABB(origins[prototype_kind] * model_scale, sizes[prototype_kind] * model_scale)
