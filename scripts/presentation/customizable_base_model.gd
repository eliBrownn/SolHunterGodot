extends Node3D
## Project-owned public base; optional owner-supplied sources stay local.

const SOURCE = preload("res://assets/characters/customizable_base/customizable_base.glb")
const LOCAL_SOURCE := "res://assets/characters/human_low_poly/human_low_poly.glb"
const LOCAL_GENERAL := "res://assets/characters/rogue/Rig_Medium_General.glb"
const LOCAL_MOVEMENT := "res://assets/characters/rogue/Rig_Medium_MovementBasic.glb"
const REST_HEIGHT := 1.8

## Opt into the withheld model/animations only on a workstation with all three files.
## Applies when prepared; public/default builds use the original project base.
@export var use_local_source := false
## Presentation-only skin tint, applied when the model is prepared.
@export var skin_color := Color(0.722, 0.570, 0.449)
var skeleton: Skeleton3D
var imported: Node3D
var authored_locomotion := false

func prepare(height: float) -> void:
	authored_locomotion = use_local_source and ResourceLoader.exists(LOCAL_SOURCE) and ResourceLoader.exists(LOCAL_GENERAL) and ResourceLoader.exists(LOCAL_MOVEMENT)
	var source: PackedScene = load(LOCAL_SOURCE) if authored_locomotion else SOURCE
	imported = source.instantiate()
	add_child(imported)
	scale = Vector3.ONE * height / REST_HEIGHT
	skeleton = imported.find_children("*", "Skeleton3D", true, false)[0]
	for mesh: MeshInstance3D in imported.find_children("*", "MeshInstance3D", true, false):
		if mesh.name != &"BaseBody":
			continue
		for surface in mesh.mesh.get_surface_count():
			var material: StandardMaterial3D = mesh.get_active_material(surface).duplicate()
			material.albedo_color = skin_color
			mesh.set_surface_override_material(surface, material)

func uses_authored_locomotion() -> bool:
	return authored_locomotion

func animation_library() -> AnimationLibrary:
	if authored_locomotion:
		return preload("res://scripts/presentation/rogue_animation_retarget.gd").build(skeleton, get_path_to(skeleton))
	# The shared player locomotion owner supplies terrain stepping. Empty selection
	# clips preserve its idle/walk/run interface without third-party animation data.
	var library := AnimationLibrary.new()
	for clip in ["Idle_A", "Walking_A", "Running_A"]:
		var animation := Animation.new()
		animation.length = 1.0
		animation.loop_mode = Animation.LOOP_LINEAR
		library.add_animation(clip, animation)
	return library
