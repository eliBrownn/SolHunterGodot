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

func reset_locomotion() -> void:
	super.reset_locomotion()

func animate(seconds: float, bob_pixels: float, bob_cycles: float) -> void:
	super.animate(seconds, bob_pixels, bob_cycles)

func preview_bounds() -> AABB:
	if design_body == null: return AABB(Vector3(-1, 0, -1), Vector3(2, 2, 2))
	var bounds: AABB = design_body.bounds()
	return AABB(bounds.position * model_scale, bounds.size * model_scale).grow(0.15)
