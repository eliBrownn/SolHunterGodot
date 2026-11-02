extends SceneTree
## Focused asset contract: public source scale, skin/UVs and shared terrain locomotion.

var failures := 0

class TestActor extends Node2D:
	var body := Node2D.new()
	var facing := Vector2.DOWN
	var walking := false
	var running := false

class TestHost extends Node3D:
	var battles = null
	var player_height_smoothing := 0.06
	var player_turn_speed_degrees := 540.0
	var player_procedural_movement := true
	var player_stride_length := 0.2
	var player_step_seconds := 0.32
	var player_step_height := 0.09
	var player_lean_degrees := 8.0
	func ground_height(_at: Vector2) -> float:
		return 0.0

class TestTerrain extends Node2D:
	signal rebuilt
	var host: TestHost
	var cell := Vector2i.ZERO
	var paused := false
	var encounter_active := false

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _initialize() -> void:
	run.call_deferred()

func bounds(model: Node3D) -> AABB:
	var result := AABB()
	var first := true
	for mesh: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		var box: AABB = model.global_transform.affine_inverse() * mesh.global_transform * mesh.get_aabb()
		result = box if first else result.merge(box)
		first = false
	return result

func run() -> void:
	var model: Node3D = load("res://scenes/customizable_base.tscn").instantiate()
	root.add_child(model)
	model.prepare(0.85)
	var box := bounds(model)
	check(absf(box.size.y * model.scale.y - 0.85) < 0.002, "Base respects the existing 0.85 player height")
	check(absf(box.position.y) < 0.002, "Base soles sit at the root ground anchor")
	var previous: Node3D = load("res://scenes/grave_knight.tscn").instantiate()
	root.add_child(previous)
	previous.prepare(0.85)
	var old_box := bounds(previous)
	print("Height comparison: base=", box.size.y * model.scale.y, " knight=", old_box.size.y * previous.scale.y)
	check(absf(old_box.size.y * previous.scale.y - box.size.y * model.scale.y) < 0.02, "Base matches the previous knight's measured height")
	for name in ["head", "upper_arm.L", "upper_arm.R", "thigh.L", "thigh.R", "shin.L", "shin.R", "foot.L", "foot.R"]:
		check(model.skeleton.find_bone(name) >= 0, "Required animation/IK bone exists: " + name)
	var triangles := 0
	for mesh: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		check(mesh.skin != null, "Every body piece follows the rig")
		for surface in mesh.mesh.get_surface_count():
			var arrays: Array = mesh.mesh.surface_get_arrays(surface)
			triangles += arrays[Mesh.ARRAY_INDEX].size() / 3
			check(arrays[Mesh.ARRAY_TEX_UV] != null, "Body pieces have UVs")
			check(arrays[Mesh.ARRAY_NORMAL] != null, "Body pieces have shading normals")
	check(triangles < 4000, "Base stays within its low-poly budget")
	var animator := AnimationPlayer.new()
	model.add_child(animator)
	animator.add_animation_library("", model.animation_library())
	for clip in ["Idle_A", "Walking_A", "Running_A"]:
		var animation := animator.get_animation(clip)
		check(not animation.has_meta("source_pack"), "Public fallback has no withheld animation source")
		check(animation.get_track_count() == 0 and animation.loop_mode == Animation.LOOP_LINEAR, "Fallback selection clip delegates motion to the shared gait")
		animator.play(clip)
		animator.advance(0.3)
		for bone in model.skeleton.get_bone_count():
			check(model.skeleton.get_bone_global_pose(bone).is_finite(), "Animation pose stays finite")
	print("Customizable base: ", triangles, " triangles; failures=", failures)
	model.free()
	previous.free()
	# The dummy renderer reports a material error disposing skinned characters;
	# run the bridge/IK lifecycle on the real renderer (omit --headless).
	if DisplayServer.get_name() == "headless":
		quit(0 if failures == 0 else 1)
		return
	# Exercise the production bridge and animation selection without world generation.
	var host := TestHost.new()
	root.add_child(host)
	var terrain := TestTerrain.new()
	terrain.host = host
	root.add_child(terrain)
	var camera := Camera2D.new()
	terrain.add_child(camera)
	var actor := TestActor.new()
	terrain.add_child(actor)
	actor.add_child(actor.body)
	var visual: Node3D = load("res://scripts/presentation/player_model.gd").new()
	host.add_child(visual)
	visual.bind(actor, camera, 0.85)
	check(visual.model.scene_file_path.ends_with("customizable_base.tscn"), "Production bridge selects the new base")
	check(visual.locomotion != null, "Public base reuses the shared procedural terrain gait")
	check(not visual.model.uses_authored_locomotion(), "Public base never loads the withheld animation pack")
	for clip in ["Idle_A", "Walking_A", "Running_A"]:
		actor.walking = clip != "Idle_A"
		actor.running = clip == "Running_A"
		for frame in range(8):
			actor.position.y += 0.1 if actor.walking else 0.0
			visual._process(0.016)
			visual.animator.advance(0.016)
		check(visual.animator.current_animation == clip, "Player bridge selects " + clip)
		await process_frame
		await process_frame
	visual.set_process(false)
	await process_frame
	host.free()
	terrain.free()
	print("Player bridge and fallback animation selection: failures=", failures)
	quit(0 if failures == 0 else 1)
