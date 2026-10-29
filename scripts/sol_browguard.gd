extends "res://scripts/sol_creature.gd"
const Parts = preload("res://scripts/sol_model_parts.gd")

func build_model() -> void:
	var hide := skin("a88772")
	var brow := skin("c9b89d")
	var dark := skin("252731")
	ellipsoid(body, "StockyChest", Vector3(0, 0.3, 0), Vector3(0.31, 0.32, 0.24), hide)
	head = joint(body, "Head", Vector3(0, 0.51, 0.06))
	ellipsoid(head, "CalfHead", Vector3.ZERO, Vector3(0.29, 0.25, 0.26), hide)
	ellipsoid(head, "SoftMuzzle", Vector3(0, -0.045, 0.13), Vector3(0.22, 0.12, 0.13), brow)
	ellipsoid(head, "PaddedBrow", Vector3(0, 0.06, 0.105), Vector3(0.27, 0.065, 0.07), brow)
	Parts.eyes(self, 0.085, 0.105, dark, brow)
	for side in [-1.0, 1.0]:
		var suffix := "Left" if side < 0 else "Right"
		Parts.leg(self, "Front" + suffix, Vector3(side * 0.09, 0.19, 0), 0.18, 0.065, hide, 0 if side < 0 else 1, true)
		var arm := joint(body, "Arm" + suffix, Vector3(side * 0.17, 0.37, 0.02))
		ellipsoid(arm, "ThickForearm", Vector3(0, -0.08, 0.035), Vector3(0.11, 0.2, 0.13), hide)
		ellipsoid(head, "Ear" + suffix, Vector3(side * 0.17, 0.02, 0), Vector3(0.13, 0.055, 0.08), brow)
		taper(head, "HornBud" + suffix, Vector3(side * 0.095, 0.135, 0), 0.06, 0.025, brow)

func animate_features(_seconds: float, wave: float, gesture: float) -> void:
	head.rotation.x += gesture * 0.35
	joints.ArmLeft.rotation.x -= gesture * 0.35 + wave * 0.025
	joints.ArmRight.rotation.x -= gesture * 0.35 - wave * 0.025

func preview_bounds() -> AABB:
	return AABB(Vector3(-0.4, -0.13, -0.35) * model_scale, Vector3(0.8, 0.95, 0.9) * model_scale)
