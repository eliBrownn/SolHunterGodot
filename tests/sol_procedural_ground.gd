extends SceneTree
## Static presentation replaces the retired procedural-ground animation contract.
const Catalog = preload("res://resources/sol_species/catalog.tres")
const DesignBody = preload("res://scripts/sols/presentation/sol_design_body.gd")
var checks := 0
var failures := 0
var samples := 0
func check(value: bool, description: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(description)
func _initialize() -> void:
	run.call_deferred()
func sampler(_at: Vector2) -> float:
	samples += 1
	return 123.0
func pose(model: Node3D) -> Array:
	var result: Array = [model.body.transform]
	for key in model.joints:
		if model.joints[key] != model.rig: result.append(model.joints[key].transform)
	if model.get("design_body") != null:
		for key in model.design_body.joints: result.append(model.design_body.joints[key].transform)
	return result
func run() -> void:
	var ids: Array[String] = ["unknown-static-fixture"]
	for entry in Catalog.entries: ids.append(entry.species_id)
	for identity in ids:
		var model: Variant = SolSpeciesView.create(identity, "water", SolVisualSettings.new())
		root.add_child(model)
		var neutral := pose(model)
		model.ground_y = 2.0
		model.sync_locomotion(Vector2.ZERO, 0.0, sampler)
		for cue in ["idle", "attack", "hit", "signature"]:
			model.play_action(cue, 0.0)
			for frame in range(60):
				model.sync_locomotion(Vector2(float(frame) * 0.01, 0), 1.0 / 60.0, sampler)
				model.animate(float(frame) / 60.0, 6.0, 2.0)
			check(pose(model) == neutral, identity + " keeps neutral joints during " + cue)
		check(samples == 0 and not model.ground_motion.initialized and model.ground_motion.steps_started == 0, "No terrain sampling or support solver")
		check(is_equal_approx(model.position.y, 2.0), "Ground height remains caller-owned")
		check(is_equal_approx(model.rig.rotation.y, PI / 2.0), "Rigid model faces actual travel")
		var heading: float = model.rig.rotation.y
		model.reset_locomotion()
		model.sync_locomotion(Vector2(100, 100), 0.0, sampler)
		check(is_equal_approx(model.rig.rotation.y, heading), "Relocation/pause does not invent heading")
		model.set_traversal({"mode": "flight", "kind": "flight", "amount": 1.0, "height": 4.0, "clock": 10.0})
		model.animate(10.0, 6.0, 2.0)
		check(is_equal_approx(model.position.y, 4.0) and pose(model) == neutral, "Flight height survives without wing posing")
		model.set_traversal({"mode": "swim", "kind": "swim", "amount": 1.0, "height": 1.5, "clock": 20.0})
		model.animate(20.0, 6.0, 2.0)
		check(is_equal_approx(model.position.y, 1.5) and pose(model) == neutral, "Swim height survives without fin posing")
		model.set_traversal({})
		model.animate(21.0, 6.0, 2.0)
		check(is_equal_approx(model.position.y, 2.0), "Return to ground restores caller height")
		check(model.tint == model.tuning.color_for("water"), "Individual affinity remains independent")
		model.free()
	# Exercise authoring previews directly, independently of the runtime adapter.
	var body = DesignBody.new()
	root.add_child(body)
	body.build({}, "")
	var neutral: Array = []
	for key in body.joints: neutral.append(body.joints[key].transform)
	for mode in ["idle", "walk", "run", "turns", "slope", "flight", "swim", "attack", "hit", "signature"]:
		body.animate_visual(0.2, mode)
		body.animate_visual(1.0, mode)
		var current: Array = []
		for key in body.joints: current.append(body.joints[key].transform)
		check(current == neutral and not body.ground_motion.initialized, "Preview remains static: " + mode)
	body.free()
	print("STATIC SOL PRESENTATION: %d checks, %d failures." % [checks, failures])
	quit(0 if failures == 0 else 1)
