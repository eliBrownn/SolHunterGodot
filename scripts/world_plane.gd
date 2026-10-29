extends Node3D
## The existing 2D coordinate system is rendered once onto a real horizontal XZ plane.
## HUD is a sibling of the SubViewport and remains in screen space.

const World = preload("res://scripts/world.gd")
const PlayerModel = preload("res://scripts/player_model.gd")
const SURFACE_SIZE := Vector2(64, 48)
const TEXTURE_SIZE := Vector2i(2048, 1536)
@export_group("Expedition Tuning")
## Movement, starting seed, new-world territory size, and runtime population-summary capacity.
@export var expedition_settings: ExpeditionSettings = preload("res://resources/expedition_settings.tres")
## New-expedition habitat settings. Loaded expeditions retain their saved climate.
@export var climate_settings: ClimateSettings = preload("res://resources/climate_settings.tres")
## Gentle terrain generation for NEW expeditions. Loads retain their saved parameters.
@export var terrain_settings: TerrainReliefSettings = preload("res://resources/terrain_rolling.tres")
## Natural recovery timing, strength, and CPU work budget; applies to loaded worlds too.
@export var vastra_settings: VastraSettings = preload("res://resources/vastra_settings.tres")
## Display, observation range, local movement responses, and animation for the provisional trail Sols.
@export var sighting_settings: SightingSettings = preload("res://resources/sighting_settings.tres")
## Selected owned Sol follows legal species routes, including supported air/water travel. Live tuning; no ownership changes.
@export var companion_settings: OwnedCompanionSettings = preload("res://resources/owned_companion_settings.tres")
## Manual approach, warned guard contact, and temporary withdrawal protection for encounter previews.
@export var encounter_settings: EncounterSettings = preload("res://resources/encounter_settings.tres")
## Provisional starter roster, resolved combat profiles, arena size, movement and release budgets.
@export var battle_settings: BattleSettings = preload("res://resources/battle_settings.tres")

## Shared hovering orb palette, size, height, halo and effects for wild and deployed Sols.
@export var sol_visual_settings: SolVisualSettings = preload("res://resources/sol_visual_settings.tres")

## Species move pools, starting loadouts, prototype move effects and condition recovery.
@export var move_library: MoveLibrary = preload("res://resources/move_library.tres")

## Saved active-time delays and local successor admission for depleted authored wildlife homes.
@export var wild_recovery_settings: WildRecoverySettings = preload("res://resources/wild_recovery_settings.tres")
## Source-derived battle XP, base-stat growth and approved prototype move unlock milestones.
@export var progression_settings: ProgressionSettings = preload("res://resources/progression_settings.tres")

@export_group("Camera")
## Starting tilt above ground in degrees. Middle-drag adjusts live; Home restores this tilt. Not saved.
@export_range(10.0, 80.0, 1.0) var camera_elevation := 35.0
## Starting orbit in degrees. Zero aligns world axes; middle-drag adjusts live. Not saved.
@export_range(-180.0, 180.0, 1.0) var camera_azimuth := 0.0
## Degrees of runtime orbit per mouse pixel. Middle-drag applies immediately; Home resets. Not saved.
@export_range(0.05, 1.0, 0.05) var camera_drag_sensitivity := 0.25
var view_elevation := 35.0
var view_azimuth := 0.0
var camera_dragging := false
var story: Node
var camera_focus := Vector3.ZERO
var pointer_actor_depth := INF
var pointer_terrain_depth := INF
var pointer_ring := MeshInstance3D.new()
var surface := MeshInstance3D.new()
var viewport := SubViewport.new()
var camera := Camera3D.new()
var world: Node2D
var target_size := 22.0
@export_group("Player")
## Player model height in world cells. Applied at startup; presentation only, not saved.
@export_range(1.2, 2.4, 0.05) var player_height := 1.7
## Maximum visual heading change in degrees per second; shortest-arc turning, applies immediately.
@export_range(90.0, 1440.0, 15.0) var player_turn_speed_degrees := 540.0
@export_group("Interface")
## Movable field-menu defaults and theme. Restart after editing; local UI preferences override layout defaults.
@export var menu_settings: MenuSettings = preload("res://resources/menu_settings.tres")
## Controller defaults; local input preferences override these without affecting saves.
@export var controller_settings: ControllerSettings = preload("res://resources/controller_settings.tres")
var gamepad: Node
var player_visual: Node3D
var sightings: Node3D
var companion: Node3D
var encounters: Node
var battles: Node
var wild_recovery: Node
var capture_directory := "res://artifacts"

func _ready() -> void:
	get_window().unresizable = false
	get_window().min_size = Vector2i(640, 400)
	viewport.size = Vector2i(2, 2) if has_method("stream_plan") else TEXTURE_SIZE
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.handle_input_locally = false
	add_child(viewport)
	add_child(camera)
	var ring := TorusMesh.new()
	ring.inner_radius = 0.42
	ring.outer_radius = 0.47
	ring.rings = 24
	ring.ring_segments = 8
	pointer_ring.mesh = ring
	var ring_material := StandardMaterial3D.new()
	ring_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ring_material.albedo_color = menu_settings.accent if menu_settings != null and menu_settings.valid() else Color("dbc48d")
	pointer_ring.material_override = ring_material
	pointer_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	pointer_ring.scale.y = 0.1
	add_child(pointer_ring)
	pointer_ring.hide()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.keep_aspect = Camera3D.KEEP_HEIGHT
	reset_camera()
	camera.current = true
	world = World.new()
	world.host = self
	world.expedition_settings = expedition_settings
	world.climate_settings = climate_settings
	world.terrain_settings = terrain_settings
	world.vastra_settings = vastra_settings
	viewport.add_child(world)
	if not has_method("sync_ground"):
		var light := DirectionalLight3D.new()
		light.rotation_degrees = Vector3(-50, -25, 0)
		add_child(light)
	var plane := PlaneMesh.new()
	plane.size = SURFACE_SIZE
	surface.mesh = plane
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_texture = viewport.get_texture()
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	surface.material_override = material
	add_child(surface)
	player_visual = PlayerModel.new()
	add_child(player_visual)
	player_visual.bind(world.explorer, world.camera, clampf(player_height, 1.2, 2.4) if is_finite(player_height) else 1.7)
	sightings = preload("res://scripts/authored_sightings.gd").new()
	add_child(sightings)
	sightings.bind(world, sighting_settings, sol_visual_settings)
	encounters = preload("res://scripts/encounter_controller.gd").new()
	add_child(encounters)
	encounters.bind(world, sightings, encounter_settings)
	battles = preload("res://scripts/battle_controller.gd").new()
	add_child(battles)
	battles.bind(world, encounters, sightings, battle_settings)
	wild_recovery = preload("res://scripts/wild_recovery_controller.gd").new()
	add_child(wild_recovery)
	wild_recovery.bind(world, sightings, wild_recovery_settings)
	companion = preload("res://scripts/owned_companion.gd").new()
	add_child(companion)
	companion.bind(world, companion_settings)
	var affinity_ground := preload("res://scripts/affinity_ground.gd").new()
	add_child(affinity_ground)
	affinity_ground.bind(world, sightings.visual_settings)
	var vastra_currents := preload("res://scripts/vastra_currents.gd").new()
	add_child(vastra_currents)
	vastra_currents.bind(world)
	gamepad = preload("res://scripts/controller_input.gd").new()
	add_child(gamepad)
	gamepad.bind(world)
	story = preload("res://scripts/story_director.gd").new()
	add_child(story)
	story.bind(world)
	get_window().focus_exited.connect(func() -> void: camera_dragging = false)
	# Match the 2D ground projection to a tilted plane while preserving pixel assets.
	if OS.get_cmdline_user_args().has("--capture"):
		_capture.call_deferred()

func pointer_world(pointer: Vector2 = get_viewport().get_mouse_position()) -> Variant:
	pointer_terrain_depth = INF
	var hit: Variant = Plane(Vector3.UP, 0).intersects_ray(camera.project_ray_origin(pointer), camera.project_ray_normal(pointer))
	if hit == null or (surface.visible and (absf(hit.x) > SURFACE_SIZE.x / 2 or absf(hit.z) > SURFACE_SIZE.y / 2)):
		return null
	if camera.projection == Camera3D.PROJECTION_PERSPECTIVE and (camera.to_local(hit).z > -camera.near or camera.to_local(hit).z < -camera.far):
		return null
	pointer_terrain_depth = camera.project_ray_origin(pointer).distance_to(hit)
	return world.camera.position + Vector2(hit.x, hit.z) * 32.0

func ground_height(at: Vector2) -> float:
	return world.terrain.surface_height(at) if has_method("sync_ground") else 0.0

func ground_mesh(cell: Vector2i, size: float = 0.93) -> Mesh:
	if has_method("sync_ground"):
		return preload("res://scripts/solid_chunk.gd").overlay_mesh(world.terrain, cell, size)
	var mesh := PlaneMesh.new()
	mesh.size = Vector2.ONE * size
	return mesh

func reset_camera() -> void:
	camera_focus = Vector3.ZERO
	view_elevation = clampf(camera_elevation, 10.0, 80.0) if is_finite(camera_elevation) else 35.0
	view_azimuth = wrapf(camera_azimuth, -180.0, 180.0) if is_finite(camera_azimuth) else 0.0
	target_size = 22.0
	apply_camera()

func apply_camera() -> void:
	var elevation := deg_to_rad(view_elevation)
	var azimuth := deg_to_rad(view_azimuth)
	camera.position = Vector3(sin(azimuth) * cos(elevation), sin(elevation), cos(azimuth) * cos(elevation)) * 40.0 + camera_focus
	camera.look_at(camera_focus)
	camera.size = target_size

func movement_direction(input: Vector2) -> Vector2:
	if input.is_zero_approx():
		return Vector2.ZERO
	var azimuth := deg_to_rad(view_azimuth)
	# Preserve the existing eight-direction grid locomotion using the nearest view-relative heading.
	var angle := snappedf(input.angle() - azimuth, PI / 4.0)
	return Vector2.from_angle(angle) * input.length()

func zoom_camera(amount: float) -> void:
	target_size = clampf(target_size + amount, 16.0, 23.0)
	apply_camera()

func _input(event: InputEvent) -> void:
	if gamepad != null:
		gamepad.handle_event(event)
	# Release even over a HUD panel so orbit never gets stuck.
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_MIDDLE and not event.pressed:
		camera_dragging = false

func pointer_cell(pointer: Vector2) -> Variant:
	pointer_actor_depth = INF
	# Pick raised, animated Sols before the ground underneath their screen image.
	var candidates: Array[Node3D] = []
	if battles != null:
		for node in battles.visuals.get_children():
			if node is SolOrb:
				candidates.append(node)
	if sightings != null:
		for member in sightings.members:
			if member.sprite.visible:
				candidates.append(member.sprite)
	var nearest: Variant = null
	var depth := INF
	for node in candidates:
		var position_3d: Vector3 = node.global_position
		var radius: float = node.tuning.diameter * 0.5
		var screen := camera.unproject_position(position_3d)
		var edge := camera.unproject_position(position_3d + camera.global_basis.x * radius)
		var distance := camera.global_position.distance_to(position_3d)
		if camera.is_position_in_frustum(position_3d) and pointer.distance_to(screen) <= screen.distance_to(edge) and distance < depth:
			depth = distance
			nearest = node.get_meta("world_cell")
	if nearest == null and player_visual != null:
		var inverse := player_visual.global_transform.affine_inverse()
		var body := AABB(Vector3(-0.45, 0, -0.35), Vector3(0.9, player_visual.model.scale.y * 2.171, 0.7))
		var body_hit: Variant = body.intersects_ray(inverse * camera.project_ray_origin(pointer), inverse.basis * camera.project_ray_normal(pointer))
		if body_hit != null:
			nearest = world.cell
			depth = camera.project_ray_origin(pointer).distance_to(player_visual.global_transform * body_hit)
	var point: Variant = pointer_world(pointer)
	if nearest == null or (point != null and pointer_terrain_depth + 0.06 < depth):
		nearest = Vector2i((point / 32.0).floor()) if point != null else null
		depth = pointer_terrain_depth
	pointer_actor_depth = depth
	return call("pointer_object_cell", pointer, nearest) if has_method("pointer_object_cell") else nearest

func _unhandled_input(event: InputEvent) -> void:
	if story != null and story.window.visible:
		camera_dragging = false
		if event.is_action_pressed("pause_expedition"):
			story.window.hide()
		get_viewport().set_input_as_handled()
		return
	if world != null and (world.pause_panel.visible or world.confirmation.visible or world.observation_menu.visible or (battles != null and battles.modal_open())):
		camera_dragging = false
		world.handle_input(event)
		get_viewport().set_input_as_handled()
		return
	if world != null and world.menu != null and world.menu.opened:
		world.handle_input(event)
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_HOME:
		reset_camera()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseMotion and camera_dragging:
		var sensitivity := camera_drag_sensitivity if is_finite(camera_drag_sensitivity) and camera_drag_sensitivity >= 0.05 and camera_drag_sensitivity <= 1.0 else 0.25
		view_azimuth = wrapf(view_azimuth - event.relative.x * sensitivity, -180.0, 180.0)
		view_elevation = clampf(view_elevation + event.relative.y * sensitivity, 10.0, 80.0)
		apply_camera()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			camera_dragging = true
			get_viewport().set_input_as_handled()
			return
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_camera(-1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_camera(1)
	world.handle_input(event)

func _capture() -> void:
	DirAccess.make_dir_recursive_absolute(capture_directory)
	for shot in ["camp", "shore", "landmark", "pause"]:
		if shot == "shore":
			var found := false
			for y in range(-96, 192):
				for x in range(-96, 192):
					var point := Vector2i(x, y)
					if world.terrain.natural_ground(point) == WorldTerrain.Ground.SAND and world.terrain.fits(point):
						world.cell = point
						found = true
						break
				if found:
					break
		elif shot == "landmark":
			world.cell = world.terrain.landmark() + Vector2i(-3, 0)
		if shot == "pause":
			world.toggle_pause()
		else:
			world.rebuild_world()
			world.arrived()
		for frame in range(5):
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(capture_directory + "/" + shot + ".png")
	get_tree().quit()

func update_pointer_visual() -> void:
	var over_gui := get_viewport().gui_get_hovered_control() != null
	if gamepad != null and gamepad.active:
		over_gui = gamepad.ui_root() != null
	pointer_ring.visible = world.hover_cell != null and not world.paused and not world.encounter_active and not world.observation_menu.visible and not over_gui and (menu_settings == null or menu_settings.pointer_highlight)
	if pointer_ring.visible:
		var relative: Vector2 = (world.center(world.hover_cell) - world.camera.position) / 32.0
		pointer_ring.position = Vector3(relative.x, ground_height(Vector2(world.hover_cell) + Vector2(0.5, 0.5)) + 0.08, relative.y)
