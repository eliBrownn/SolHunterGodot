extends Node3D
## Supplied grave knight, normalized to the existing player height.
## The source provides relaxed idle only; walking/running use a provisional gait.

const SOURCE = preload("res://assets/characters/grave_knight/grave_knight_female.glb")
const REST_HEIGHT := 0.9483829
var skeleton: Skeleton3D
var imported: Node3D

func prepare(height: float) -> void:
	imported = SOURCE.instantiate()
	add_child(imported)
	scale = Vector3.ONE * height / REST_HEIGHT
	skeleton = imported.find_children("*", "Skeleton3D")[0]

func prepare_static(height: float) -> void:
	prepare(height)
	var source_player: AnimationPlayer = imported.get_node("AnimationPlayer")
	source_player.play("relax-378947")
	source_player.seek(0.0, true)
	source_player.pause()
	source_player.active = false

func animation_library() -> AnimationLibrary:
	var source_player: AnimationPlayer = imported.get_node("AnimationPlayer")
	var idle: Animation = source_player.get_animation("relax-378947")
	var library := AnimationLibrary.new()
	for clip in ["Idle_A", "Walking_A", "Running_A"]:
		var animation: Animation = idle.duplicate(true)
		animation.loop_mode = Animation.LOOP_LINEAR
		# Tracks are relative to the adapter, where the shared player adds its animator.
		for track in animation.get_track_count():
			animation.track_set_path(track, NodePath(str(get_path_to(imported)) + "/" + str(animation.track_get_path(track))))
		if clip != "Idle_A":
			animation.length = 0.8 if clip == "Running_A" else 1.2
			for bone_name in ["CC_Base_L_Thigh_04", "CC_Base_R_Thigh_019", "CC_Base_L_Calf_05", "CC_Base_R_Calf_022", "CC_Base_L_Upperarm_050", "CC_Base_R_Upperarm_065"]:
				var path := NodePath("%s:%s" % [get_path_to(skeleton), bone_name])
				var track := animation.find_track(path, Animation.TYPE_ROTATION_3D)
				var base := skeleton.get_bone_rest(skeleton.find_bone(bone_name)).basis.get_rotation_quaternion()
				if track >= 0:
					base = animation.rotation_track_interpolate(track, 0.0)
					animation.remove_track(track)
				track = animation.add_track(Animation.TYPE_ROTATION_3D)
				animation.track_set_path(track, path)
				var rest := skeleton.get_bone_global_rest(skeleton.find_bone(bone_name)).basis.orthonormalized()
				var axis := rest.inverse() * Vector3.RIGHT
				for key in range(17):
					var phase := float(key) / 16.0
					var wave := sin(phase * TAU + (PI if "_R_" in bone_name else 0.0))
					var angle := wave * (30.0 if clip == "Running_A" else 20.0)
					if "Calf" in bone_name:
						angle = -maxf(0.0, wave) * (48.0 if clip == "Running_A" else 30.0)
					elif "Upperarm" in bone_name:
						angle *= -0.45
					animation.rotation_track_insert_key(track, phase * animation.length, base * Quaternion(axis.normalized(), deg_to_rad(angle)))
		library.add_animation(clip, animation)
	source_player.active = false
	return library
