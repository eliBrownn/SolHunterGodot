extends Node3D
## Cosmetic stepping with an adjustable slow cadence. Absolute terrain coordinates
## keep stance feet stable within leg reach while the camera rebases the world.

var player: Node3D
var solver := TwoBoneIK3D.new()
var feet: Array[Dictionary] = []
var previous := Vector2.ZERO
var initialized := false
var swinging := -1
var next_foot := 0
var swing_progress := 0.0
var swing_start := Vector3.ZERO
var swing_end := Vector3.ZERO
var travel_speed := 0.0
var last_heading := 0.0

func bind(source: Node3D) -> void:
	player = source
	solver.mutable_bone_axes = false
	solver.setting_count = 2
	player.skeleton.add_child(solver)
	for index in range(2):
		var suffix := ".L" if index == 0 else ".R"
		var target := Node3D.new()
		var pole := Node3D.new()
		add_child(target)
		add_child(pole)
		var bone: int = player.skeleton.find_bone("foot" + suffix)
		var neutral: Vector3 = player.to_local(player.skeleton.to_global(player.skeleton.get_bone_global_rest(bone).origin))
		feet.append({"neutral": Vector2(neutral.x, neutral.z), "target": target, "pole": pole, "planted": Vector3.ZERO})
		solver.set_root_bone_name(index, "thigh" + suffix)
		solver.set_middle_bone_name(index, "shin" + suffix)
		solver.set_end_bone_name(index, "foot" + suffix)
		solver.set_use_virtual_end(index, false)
		solver.set_target_node(index, solver.get_path_to(target))
		solver.set_pole_node(index, solver.get_path_to(pole))
		solver.set_pole_direction(index, SkeletonModifier3D.SECONDARY_DIRECTION_NONE)
	last_heading = player.rotation.y
	player.terrain_camera.get_parent().rebuilt.connect(reset)

func reset() -> void:
	initialized = false
	swinging = -1
	travel_speed = 0.0
	last_heading = player.rotation.y

func ground_point(at: Vector2) -> Vector3:
	var world: Node2D = player.terrain_camera.get_parent()
	return Vector3(at.x, world.host.ground_height(at) + player.model_height * 0.07, at.y)

func neutral_point(at: Vector2, index: int) -> Vector2:
	var offset: Vector2 = feet[index].neutral
	var rotated := Basis(Vector3.UP, player.rotation.y) * Vector3(offset.x, 0, offset.y)
	return at + Vector2(rotated.x, rotated.z)

func update_pose(at: Vector2, delta: float, frozen: bool) -> void:
	var host: Node3D = player.terrain_camera.get_parent().host
	solver.active = host.player_procedural_movement
	if not solver.active:
		player.model.rotation = Vector3.ZERO
		player.model.position.y = 0.0
		initialized = false
		return
	var height: float = player.model_height
	# The visual anchor sits above the ground; lower the rig to plant its soles
	# and leave a little knee bend for slopes instead of locking extended legs.
	player.model.position.y = -player.ground_height - height * 0.025
	var displacement := at - previous
	# Reconstruction/teleports must not sweep a planted foot across the map.
	if not initialized or displacement.length() > height * 2.0:
		for index in range(2):
			feet[index].planted = ground_point(neutral_point(at, index))
		swinging = -1
		travel_speed = 0.0
		initialized = true
		previous = at
		displacement = Vector2.ZERO
	if not frozen and delta > 0:
		travel_speed = lerpf(travel_speed, displacement.length() / delta, 1.0 - exp(-12.0 * delta))
		var stride: float = height * safe_value(host.player_stride_length, 0.2, 0.08, 0.4)
		var direction := displacement.normalized()
		if swinging == -1:
			for attempt in range(2):
				var index := (next_foot + attempt) % 2
				var planted: Vector3 = feet[index].planted
				var neutral := neutral_point(at, index)
				var error := neutral.distance_to(Vector2(planted.x, planted.z))
				var threshold := stride * (0.45 if direction != Vector2.ZERO else 0.12)
				if error <= threshold:
					continue
				swinging = index
				swing_progress = 0.0
				swing_start = planted
				swing_end = ground_point(neutral + direction * stride * 0.35)
				break
		if swinging != -1:
			# Keep cadence calm regardless of the tiny rig's stride length. Carry
			# swing endpoints with the body so a long swing cannot trail behind it.
			var motion := Vector3(displacement.x, 0, displacement.y)
			swing_start += motion
			swing_end += motion
			var duration := safe_value(host.player_step_seconds, 0.32, 0.18, 0.8)
			if player.actor.running or (player.sideline_session != null and not player.returning):
				duration *= 0.8
			swing_progress = minf(1.0, swing_progress + delta / duration)
			var eased := smoothstep(0.0, 1.0, swing_progress)
			var foot := swing_start.lerp(swing_end, eased)
			var clearance: float = height * safe_value(host.player_step_height, 0.09, 0.02, 0.2)
			# Sample the actual surface throughout the swing, including triangle seams.
			foot.y = maxf(foot.y, ground_point(Vector2(foot.x, foot.z)).y) + sin(PI * swing_progress) * clearance
			feet[swinging].planted = foot
			if swing_progress >= 1.0:
				feet[swinging].planted = swing_end
				next_foot = 1 - swinging
				swinging = -1
		# Release a stance lock gradually when the body outruns a short leg.
		# Slower steps must not stretch the rig or accelerate into tiny shuffles.
		for index in range(2):
			var foot: Vector3 = feet[index].planted
			var neutral := neutral_point(at, index)
			var offset := Vector2(foot.x, foot.z) - neutral
			var bounded := neutral + offset.limit_length(stride * 0.6)
			var lift := maxf(0.0, foot.y - ground_point(Vector2(foot.x, foot.z)).y) if index == swinging else 0.0
			feet[index].planted = ground_point(bounded) + Vector3.UP * lift
		update_lean(at, delta, host)
	previous = at
	var origin: Vector2 = player.terrain_camera.position / WorldTerrain.CELL_SIZE
	for index in range(2):
		var planted: Vector3 = feet[index].planted
		feet[index].target.global_position = planted - Vector3(origin.x, 0, origin.y)
		feet[index].pole.global_position = player.to_global(Vector3(feet[index].neutral.x, height * 0.45, height * 0.65))
	if not frozen and delta > 0 and travel_speed > 0.01:
		# Authored upper-body motion follows actual speed and character size; IK owns legs.
		player.animator.speed_scale = clampf(travel_speed / (height * 2.5) * 0.25, 0.2, 0.75)

func update_lean(at: Vector2, delta: float, host: Node3D) -> void:
	var height: float = player.model_height
	var forward := Vector2(sin(player.rotation.y), cos(player.rotation.y))
	var right := Vector2(forward.y, -forward.x)
	var ahead := ground_point(at + forward * height * 0.2).y
	var behind := ground_point(at - forward * height * 0.2).y
	var slope := atan2(ahead - behind, height * 0.4)
	var turn := angle_difference(last_heading, player.rotation.y) / maxf(delta, 0.001)
	var limit := deg_to_rad(safe_value(host.player_lean_degrees, 8.0, 0.0, 15.0))
	var cross_slope := atan2(ground_point(at + right * height * 0.2).y - ground_point(at - right * height * 0.2).y, height * 0.4)
	var desired := Vector3(clampf(slope * 0.3 + travel_speed * 0.012, -limit, limit), 0, clampf(cross_slope * 0.2 - turn * travel_speed * 0.015, -limit, limit))
	player.model.rotation = player.model.rotation.lerp(desired, 1.0 - exp(-10.0 * delta))
	last_heading = player.rotation.y

func safe_value(value: float, fallback: float, low: float, high: float) -> float:
	return clampf(value, low, high) if is_finite(value) else fallback
