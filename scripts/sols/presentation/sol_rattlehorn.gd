extends "res://scripts/sols/presentation/sol_creature.gd"
## Approved direction B: elevated chest, narrow steps, short ring horns and mane.

func build_model() -> void:
	var hide := skin("7c7971")
	var keratin := skin("c4b9a3")
	var filament := skin("494b53")
	var eyes := skin("20252c")
	ellipsoid(body, "HighChest", Vector3(0, 0.34, 0.1), Vector3(0.3, 0.31, 0.3), hide)
	ellipsoid(body, "TaperedHaunches", Vector3(0, 0.29, -0.15), Vector3(0.23, 0.23, 0.27), hide)
	head = joint(body, "Head", Vector3(0, 0.51, 0.22))
	ellipsoid(head, "Skull", Vector3.ZERO, Vector3(0.26, 0.24, 0.25), hide)
	ellipsoid(head, "BluntMuzzle", Vector3(0, -0.035, 0.125), Vector3(0.15, 0.1, 0.13), hide)
	face(head, 0.085, 0.111, eyes, keratin)
	for eye in head.find_children("Eye*", "MeshInstance3D", false, false):
		eye.scale *= 1.4
	for side in [-1.0, 1.0]:
		var suffix := "Left" if side < 0 else "Right"
		for row in range(2):
			var title := ("Front" if row == 0 else "Hind") + suffix
			limb(body, title, Vector3(side * 0.095, 0.25 if row == 0 else 0.23, 0.13 if row == 0 else -0.19), 0.24 if row == 0 else 0.22, 0.045, hide)
			var foot: Node3D = joints[title + "Foot"]
			# Two distinct keratin toes surround the central support contact.
			for toe in [-1.0, 1.0]:
				ellipsoid(foot, "Hoof" + str(toe), Vector3(toe * 0.017, 0.011, 0.027), Vector3(0.026, 0.035, 0.07), keratin)
		var horn := joint(head, "Horn" + suffix, Vector3(side * 0.09, 0.105, -0.025))
		horn.rotation.z = -side * 0.4
		for index in range(2):
			var ring := MeshInstance3D.new()
			ring.name = "Ring%d" % index
			var torus := TorusMesh.new()
			torus.inner_radius = 0.018 - index * 0.003
			torus.outer_radius = 0.033 - index * 0.004
			torus.rings = 8
			torus.ring_segments = 6
			ring.mesh = torus
			ring.material_override = keratin
			ring.position.y = index * 0.035
			horn.add_child(ring)
	var mane := joint(body, "Mane", Vector3(0, 0.42, -0.005))
	for index in range(9):
		var side := -1.0 if index % 2 == 0 else 1.0
		var base := joint(mane, "Filament%d" % index, Vector3(side * 0.065, -index * 0.009, -index * 0.024))
		base.rotation = Vector3(-0.5, 0, -side * 0.35)
		taper(base, "Bristle", Vector3(0, 0.05, 0), 0.1, 0.018, filament)
	var tail := joint(body, "Tail", Vector3(0, 0.3, -0.26))
	ellipsoid(tail, "ShortTail", Vector3(0, -0.035, -0.06), Vector3(0.045, 0.09, 0.14), filament)

func released_support(gesture: float) -> String:
	return "FrontLeft" if gesture > 0.05 else ""

func animate_features(seconds: float, wave: float, gesture: float) -> void:
	joints.Mane.rotation.x -= gesture * 0.3
	for index in range(9):
		joints["Filament%d" % index].rotation.z += sin(seconds * 12.0 + index) * 0.035 * gesture
	joints.HornLeft.rotation.z += sin(seconds * 18.0) * gesture * 0.045
	joints.HornRight.rotation.z -= sin(seconds * 18.0) * gesture * 0.045
	joints.Tail.rotation.y += wave * 0.08
	# Three supports remain solved while the left forefoot tests the surface.
	body.position.x += gesture * 0.012
	joints.FrontLeft.rotation.x -= gesture * 0.8
	joints.FrontLeftKnee.rotation.x += gesture * 1.5
	head.rotation.x += gesture * 0.15

func preview_bounds() -> AABB:
	return AABB(Vector3(-0.4, -0.14, -0.6) * model_scale, Vector3(0.8, 1.14, 1.3) * model_scale)
