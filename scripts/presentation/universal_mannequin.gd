extends Node3D
## Quaternius mannequin with the pack's in-place exploration loops.

const REST_HEIGHT := 1.8287165
# Godot strips the pack's "_Loop" suffix on import.
const MOVEMENT_CLIPS := {
	&"Idle_A": &"Idle",
	&"Walking_A": &"Walk",
	&"Running_A": &"Sprint",
}

var skeleton: Skeleton3D

func prepare(height: float) -> void:
	scale = Vector3.ONE * height / REST_HEIGHT
	skeleton = find_children("*", "Skeleton3D", true, false)[0]

func uses_authored_locomotion() -> bool:
	return true

func animation_library() -> AnimationLibrary:
	var source_player: AnimationPlayer = $AnimationPlayer
	var library := AnimationLibrary.new()
	for state: StringName in MOVEMENT_CLIPS:
		var animation: Animation = source_player.get_animation(MOVEMENT_CLIPS[state]).duplicate()
		animation.loop_mode = Animation.LOOP_LINEAR
		library.add_animation(state, animation)
	# The shared player owns playback. Both players resolve tracks from this scene root.
	source_player.free()
	return library
