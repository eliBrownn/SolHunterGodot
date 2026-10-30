extends "res://scripts/sols/presentation/sol_creature.gd"
## Authored appearance consumes existing individual, locomotion and action contracts.
const Recipe = preload("res://scripts/sols/presentation/sol_design_recipe.gd")
const Builder = preload("res://scripts/sols/presentation/sol_design_body.gd")
@export var appearance_recipe: Dictionary = {}
var design_body: Node3D

func uses_custom_visual_core() -> bool:
	return true

func build_model() -> void:
	head = joint(body, "HeadProxy", Vector3.ZERO)
	design_body = Builder.new()
	body.add_child(design_body)
	design_body.build(appearance_recipe, "")
	visual_core = design_body.visual_core
	wisp_head = visual_core

func animate_features(_seconds: float, _wave: float, _gesture: float) -> void:
	pass # The appearance builder owns its feature joints.

func sync_locomotion(at: Vector2, delta: float, sampler: Callable) -> void:
	super.sync_locomotion(at, delta, sampler)
	if design_body == null: return
	var ground: float = sampler.call(at)
	var relative := func(point: Vector2) -> float: return float(sampler.call(point)) - ground
	design_body.ground_motion.advance(at, delta, relative, model_scale, step_distance, step_lift, turn_response)

func reset_locomotion() -> void:
	super.reset_locomotion()
	if design_body != null: design_body.ground_motion.reset()

func animate(seconds: float, bob_pixels: float, bob_cycles: float) -> void:
	if design_body == null: return
	super.animate(seconds, bob_pixels, bob_cycles)
	rig.rotation.y = 0.0 # The shared design rig owns heading; avoid applying it twice.
	var mode := "idle"
	if float(traversal_visual.get("amount", 0)) > 0.5: mode = "flight" if traversal_visual.get("kind") == "flight" else "swim"
	elif not action.is_empty() and seconds - action_started < action_seconds: mode = action
	design_body.animate_visual(seconds, mode)
	if mode not in ["flight", "swim"]:
		design_body.ground_motion.apply(design_body, design_body.rig, model_scale)
	else:
		# Existing traversal owns height; the builder only poses appendages.
		design_body.rig.position.y = 0

func preview_bounds() -> AABB:
	if design_body == null: return AABB(Vector3(-1, 0, -1), Vector3(2, 2, 2))
	var bounds: AABB = design_body.bounds()
	return AABB(bounds.position * model_scale, bounds.size * model_scale).grow(0.15)
