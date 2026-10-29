extends Node3D
## Visual bridge only: the expedition remains the movement and save authority.

const MODEL = preload("res://assets/characters/rogue/Rogue_Hooded.glb")
const GENERAL = preload("res://assets/characters/rogue/Rig_Medium_General.glb")
const MOVEMENT = preload("res://assets/characters/rogue/Rig_Medium_MovementBasic.glb")
var actor: Node2D
var terrain_camera: Camera2D
var ground_height := 0.06
var model: Node3D
var animator := AnimationPlayer.new()
var skeleton: Skeleton3D
var meshes: Array[MeshInstance3D] = []
## Trainer sideline run speed in cells per real second. Deployment waits for arrival; no exploration tick.
@export_range(1.0, 10.0, 0.25) var sideline_walk_speed := 6.0
var sideline_session: TacticalBattle
var sideline_route: Array[Vector2i] = []
var sideline_history: Array[Vector2i] = []
var presentation_cell := Vector2.ZERO
var sideline_origin := Vector2i.ZERO
var returning := false
var facing_initialized := false


func bind(source: Node2D, source_camera: Camera2D, height: float = 1.7) -> void:
	actor = source
	terrain_camera = source_camera
	model = MODEL.instantiate()
	add_child(model)
	model.scale = Vector3.ONE * height / 2.171
	skeleton = model.get_node("Rig_Medium/Skeleton3D")
	for node in model.find_children("*", "MeshInstance3D"):
		meshes.append(node)
		for surface in range(node.mesh.get_surface_count()):
			var material: StandardMaterial3D = node.get_active_material(surface).duplicate()
			material.roughness = 0.85
			node.set_surface_override_material(surface, material)
	model.add_child(animator)
	var library := AnimationLibrary.new()
	for pack in [GENERAL, MOVEMENT]:
		var rig: Node = pack.instantiate()
		var source_player: AnimationPlayer = rig.get_node("AnimationPlayer")
		for name in source_player.get_animation_list():
			if library.has_animation(name):
				continue
			var animation: Animation = source_player.get_animation(name).duplicate(true)
			if name.begins_with("Idle") or name.begins_with("Walking") or name.begins_with("Running"):
				animation.loop_mode = Animation.LOOP_LINEAR
			library.add_animation(name, animation)
		rig.free()
	animator.add_animation_library("", library)
	actor.body.hide()
	sync_art()
	animator.advance(0)

func _process(delta: float) -> void:
	update_sideline(delta)
	sync_art(delta)

func update_sideline(delta: float) -> void:
	if actor == null:
		return
	var world: Node2D = terrain_camera.get_parent()
	var battle: TacticalBattle = world.host.battles.session if world.host.battles != null else null
	if battle != sideline_session:
		if battle != null:
			sideline_origin = world.cell
			presentation_cell = Vector2(world.cell)
			sideline_route = sideline_path(world, battle)
			sideline_history = [world.cell]
			returning = false
		elif sideline_session != null:
			sideline_route.clear()
			for index in range(sideline_history.size() - 1, -1, -1):
				sideline_route.append(sideline_history[index])
			returning = true
		sideline_session = battle
	if battle != null and (world.host.battles.modal_open() or world.observation_menu.visible):
		return
	# Loading, defeat relocation or manual exploration supersedes the cosmetic walk.
	if world.cell != sideline_origin and (returning or battle != null):
		sideline_route.clear()
		returning = false
	if not sideline_route.is_empty():
		var goal := Vector2(sideline_route[0])
		var speed := sideline_walk_speed if is_finite(sideline_walk_speed) else 4.0
		presentation_cell = presentation_cell.move_toward(goal, maxf(delta, 0) * clampf(speed, 1, 10))
		if presentation_cell.is_equal_approx(goal):
			var reached: Vector2i = sideline_route.pop_front()
			if not returning:
				sideline_history.append(reached)
	if returning and sideline_route.is_empty():
		returning = false

func sideline_path(world: Node2D, battle: TacticalBattle) -> Array[Vector2i]:
	# The battle controller validated this exact path and authoritative release origin.
	return battle.commander_route.duplicate()

func reset_sideline() -> void:
	sideline_session = null
	sideline_route.clear()
	sideline_history.clear()
	returning = false


func sync_art(delta: float = 0.0) -> void:
	if actor == null:
		return
	var relative: Vector2 = (actor.position - terrain_camera.position) / WorldTerrain.CELL_SIZE
	if sideline_session != null or returning:
		relative = presentation_cell + Vector2(0.5, 0.5) - terrain_camera.position / WorldTerrain.CELL_SIZE
	var source_world: Node2D = terrain_camera.get_parent()
	var absolute := relative + terrain_camera.position / WorldTerrain.CELL_SIZE
	position = Vector3(relative.x, source_world.host.ground_height(absolute) + ground_height, relative.y)
	var heading_angle := atan2(actor.facing.x, actor.facing.y)
	var animation := ("Running_A" if actor.running else "Walking_A") if actor.walking else "Idle_A"
	if not sideline_route.is_empty():
		var heading := Vector2(sideline_route[0]) - presentation_cell
		if not heading.is_zero_approx():
			heading_angle = atan2(heading.x, heading.y)
		animation = "Walking_A" if returning else "Running_A"
	var world: Node2D = terrain_camera.get_parent()
	if not facing_initialized:
		rotation.y = heading_angle
		facing_initialized = true
	elif not world.paused or world.encounter_active:
		var turn_speed: float = world.host.player_turn_speed_degrees
		if not is_finite(turn_speed):
			turn_speed = 540.0
		rotation.y = rotate_toward(rotation.y, heading_angle, deg_to_rad(clampf(turn_speed, 90.0, 1440.0)) * maxf(0, delta))
	if animator.current_animation != animation:
		animator.play(animation, 0.15)
	animator.speed_scale = 0.0 if world.paused and not world.encounter_active else 1.0
