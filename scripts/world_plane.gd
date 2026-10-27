extends Node3D
## The existing 2D coordinate system is rendered once onto a real horizontal XZ plane.
## HUD is a sibling of the SubViewport and remains in screen space.

const World = preload("res://scripts/world.gd")
const ActorBillboard = preload("res://scripts/actor_billboard.gd")
const SURFACE_SIZE := Vector2(64, 48)
const TEXTURE_SIZE := Vector2i(2048, 1536)
@export_group("Expedition Tuning")
## Movement, starting seed, new-world territory size, and runtime population-summary capacity.
@export var expedition_settings: ExpeditionSettings = preload("res://resources/expedition_settings.tres")
## New-expedition habitat settings. Loaded expeditions retain their saved climate.
@export var climate_settings: ClimateSettings = preload("res://resources/climate_settings.tres")
## Natural recovery timing, strength, and CPU work budget; applies to loaded worlds too.
@export var vastra_settings: VastraSettings = preload("res://resources/vastra_settings.tres")
## Display, observation range, local movement responses, and animation for the provisional trail Sols.
@export var sighting_settings: SightingSettings = preload("res://resources/sighting_settings.tres")
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

@export_group("Camera")
## Degrees above the ground plane. Smaller is lower; 35 preserves the selected low-angle presentation. Applied at startup.
@export_range(35.0, 70.0, 1.0) var camera_elevation := 35.0
## Sideways camera rotation. Zero keeps world axes aligned. Applied at startup.
@export_range(-45.0, 45.0, 1.0) var camera_azimuth := 0.0
var surface := MeshInstance3D.new()
var viewport := SubViewport.new()
var camera := Camera3D.new()
var world: Node2D
var target_size := 22.0
var player_billboard: Sprite3D
var sightings: Node3D
var encounters: Node
var battles: Node
var wild_recovery: Node
var capture_directory := "res://artifacts"

func _ready() -> void:
	viewport.size = TEXTURE_SIZE
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.handle_input_locally = false
	add_child(viewport)
	world = World.new()
	world.host = self
	world.expedition_settings = expedition_settings
	world.climate_settings = climate_settings
	world.vastra_settings = vastra_settings
	viewport.add_child(world)
	var plane := PlaneMesh.new()
	plane.size = SURFACE_SIZE
	surface.mesh = plane
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_texture = viewport.get_texture()
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	surface.material_override = material
	add_child(surface)
	add_child(camera)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.keep_aspect = Camera3D.KEEP_HEIGHT
	camera.size = target_size
	# Lower the camera toward the XZ plane without rotating the world sideways.
	var elevation := deg_to_rad(camera_elevation)
	var azimuth := deg_to_rad(camera_azimuth)
	camera.position = Vector3(sin(azimuth) * cos(elevation), sin(elevation), cos(azimuth) * cos(elevation)) * 40.0
	camera.look_at(Vector3.ZERO)
	camera.current = true
	player_billboard = ActorBillboard.new()
	add_child(player_billboard)
	player_billboard.bind(world.explorer, world.camera)
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
	var affinity_ground := preload("res://scripts/affinity_ground.gd").new()
	add_child(affinity_ground)
	affinity_ground.bind(world, sightings.visual_settings)
	# Match the 2D ground projection to a tilted plane while preserving pixel assets.
	if OS.get_cmdline_user_args().has("--capture"):
		_capture.call_deferred()

func pointer_world() -> Variant:
	var pointer := get_viewport().get_mouse_position()
	var hit: Variant = Plane(Vector3.UP, 0).intersects_ray(camera.project_ray_origin(pointer), camera.project_ray_normal(pointer))
	if hit == null or absf(hit.x) > SURFACE_SIZE.x / 2 or absf(hit.z) > SURFACE_SIZE.y / 2:
		return null
	return world.camera.position + Vector2(hit.x, hit.z) * 32.0

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and not world.paused:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			target_size = maxf(16, target_size - 1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			target_size = minf(23, target_size + 1)
		camera.size = target_size
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
