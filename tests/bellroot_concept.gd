extends SceneTree
## Focused prototype journey: stable clearance, supports, sliders and lab entry.
var failures := 0

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var scene := load("res://scenes/bellroot_concept_preview.tscn") as PackedScene
	var preview: Node = scene.instantiate()
	root.add_child(preview)
	await process_frame
	var model: Node3D = preview.model
	check(model.ground_motion.chains.size() == 4, "Four registered root supports required")
	for gap in [0.08, 0.25]:
		model.core_gap = gap
		for size in [0.25, 0.55]:
			model.visual_core.configure(size, {"wisp_spread": 0.04})
			for frame in range(120):
				var seconds := frame / 30.0
				model.sync_locomotion(Vector2(0, seconds * 0.3), 1.0 / 30.0, func(_at: Vector2): return 0.0)
				model.animate(seconds, 0.0, 0.0)
				check(model.visual_core.position.y - model.visual_core.envelope_radius() > 0.40, "Particle envelope must clear bulb during motion")
				check(model.visual_core.position.is_finite(), "Finite core pose")
	preview.walking = false
	model.core_gap = 0.12
	model.visual_core.configure(0.4, {"wisp_spread": 0.04, "core_tint": "fff0d5"})
	model.reset_locomotion()
	for frame in range(100): await process_frame
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://artifacts/bellroot-concept-preview.png")
	preview.queue_free()
	await process_frame
	var lab: Node = load("res://scenes/sol_lab.tscn").instantiate()
	root.add_child(lab)
	await process_frame
	lab.open_bellroot_concept()
	await process_frame
	var windows := 0
	for child in lab.get_children():
		if child is Window and child.name == "BellrootConceptWindow": windows += 1
	check(windows == 1, "Sol Lab opens isolated concept window")
	lab.queue_free()
	await process_frame
	print("Bellroot concept journey: ", "PASS" if failures == 0 else "FAIL")
	quit(0 if failures == 0 else 1)
