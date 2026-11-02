extends RefCounted
## Bake the supplied rogue clips onto the human rig without changing its mesh.

const CLIPS := {
	"Idle_A": "res://assets/characters/rogue/Rig_Medium_General.glb",
	"Walking_A": "res://assets/characters/rogue/Rig_Medium_MovementBasic.glb",
	"Running_A": "res://assets/characters/rogue/Rig_Medium_MovementBasic.glb",
}
const BONES := {
	"pelvis": "hips", "spine": "spine", "chest": "chest", "head": "head",
	"upper_arm.L": "upperarm.l", "forearm.L": "lowerarm.l", "hand.L": "hand.l",
	"upper_arm.R": "upperarm.r", "forearm.R": "lowerarm.r", "hand.R": "hand.r",
	"thigh.L": "upperleg.l", "shin.L": "lowerleg.l", "foot.L": "foot.l",
	"thigh.R": "upperleg.r", "shin.R": "lowerleg.r", "foot.R": "foot.r",
}

static func build(target: Skeleton3D, skeleton_path: NodePath) -> AnimationLibrary:
	var library := AnimationLibrary.new()
	for clip: String in CLIPS:
		var rig: Node3D = (load(CLIPS[clip]) as PackedScene).instantiate()
		var source: Skeleton3D = rig.find_children("*", "Skeleton3D", true, false)[0]
		var player: AnimationPlayer = rig.get_node("AnimationPlayer")
		var original := player.get_animation(clip)
		library.add_animation(clip, bake(original, source, target, skeleton_path))
		library.get_animation(clip).set_meta("source_pack", CLIPS[clip])
		library.get_animation(clip).set_meta("source_clip", clip)
		rig.free()
	return library

static func bake(original: Animation, source: Skeleton3D, target: Skeleton3D, path: NodePath) -> Animation:
	var animation := Animation.new()
	animation.length = original.length
	animation.loop_mode = Animation.LOOP_LINEAR
	var mappings: Dictionary = {}
	var corrections: Dictionary = {}
	var tracks: Dictionary = {}
	for name: String in BONES:
		var to := target.find_bone(name)
		var from := source.find_bone(BONES[name])
		assert(to >= 0 and from >= 0, "Rogue retarget mapping must resolve: " + name)
		mappings[to] = from
		var source_rest := source.get_bone_global_rest(from).basis.orthonormalized()
		var target_rest := target.get_bone_global_rest(to).basis.orthonormalized()
		# Match longitudinal bone axes before preserving roll. The rogue is in a
		# T-pose and the human's arms are down; copying local rotations doubles it.
		if name.begins_with("upper_arm") or name.begins_with("forearm") or name.begins_with("hand"):
			var align := Basis(Quaternion(source_rest.y, target_rest.y))
			corrections[to] = (align * source_rest).inverse() * target_rest
		else:
			# Keep the human's leg splay and foot angle; their rest directions are
			# already compatible, unlike the two different arm bind poses.
			corrections[to] = source_rest.inverse() * target_rest
		var track := animation.add_track(Animation.TYPE_ROTATION_3D)
		animation.track_set_path(track, NodePath("%s:%s" % [path, name]))
		tracks[to] = track
	var pelvis := target.find_bone("pelvis")
	var source_hips := source.find_bone("hips")
	var bob_track := animation.add_track(Animation.TYPE_POSITION_3D)
	animation.track_set_path(bob_track, NodePath("%s:pelvis" % path))
	var height_ratio := target.get_bone_global_rest(pelvis).origin.y / source.get_bone_global_rest(source_hips).origin.y
	var samples := ceili(original.length * 30.0)
	for sample in range(samples + 1):
		var time := original.length * sample / samples
		var local: Array[Transform3D] = []
		for bone in source.get_bone_count():
			local.append(source.get_bone_rest(bone))
		for track in original.get_track_count():
			var source_path := original.track_get_path(track)
			if source_path.get_subname_count() != 1:
				continue
			var bone := source.find_bone(source_path.get_subname(0))
			if bone < 0:
				continue
			match original.track_get_type(track):
				Animation.TYPE_ROTATION_3D:
					local[bone].basis = Basis(original.rotation_track_interpolate(track, time))
				Animation.TYPE_POSITION_3D:
					local[bone].origin = original.position_track_interpolate(track, time)
		var source_pose: Array[Transform3D] = []
		for bone in source.get_bone_count():
			var parent := source.get_bone_parent(bone)
			source_pose.append(local[bone] if parent < 0 else source_pose[parent] * local[bone])
		var target_pose: Array[Basis] = []
		for bone in target.get_bone_count():
			var parent := target.get_bone_parent(bone)
			var parent_basis := Basis.IDENTITY if parent < 0 else target_pose[parent]
			var desired := parent_basis * target.get_bone_rest(bone).basis.orthonormalized()
			if mappings.has(bone):
				desired = source_pose[mappings[bone]].basis.orthonormalized() * corrections[bone]
				var rotation := (parent_basis.inverse() * desired).get_rotation_quaternion().normalized()
				animation.rotation_track_insert_key(tracks[bone], time, rotation)
			target_pose.append(desired)
		# Preserve authored hip bob. Actor movement owns travel, so strip root motion
		# and retain the human's bone lengths instead of copying source positions.
		var position := target.get_bone_rest(pelvis).origin
		position.y += (local[source_hips].origin.y - source.get_bone_rest(source_hips).origin.y) * height_ratio
		animation.position_track_insert_key(bob_track, time, position)
	return animation
