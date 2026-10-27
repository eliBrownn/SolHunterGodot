extends Node3D
## The existing 2D coordinate system is rendered once onto a real horizontal XZ plane.
## HUD is a sibling of the SubViewport and remains in screen space.

const World = preload("res://scripts/world.gd")
const ActorBillboard = preload("res://scripts/actor_billboard.gd")
const SURFACE_SIZE := Vector2(48, 30)
const TEXTURE_SIZE := Vector2i(1536, 960)
var surface := MeshInstance3D.new()
var viewport := SubViewport.new()
var camera := Camera3D.new()
var world: Node2D
var target_size := 22.0
var player_billboard: Sprite3D

func _ready() -> void:
	viewport.size = TEXTURE_SIZE
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.handle_input_locally = false
	add_child(viewport)
	world = World.new()
	world.host = self
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
	camera.position = Vector3(0, 35, 25)
	camera.look_at(Vector3.ZERO)
	camera.current = true
	player_billboard = ActorBillboard.new()
	add_child(player_billboard)
	player_billboard.bind(world.explorer, world.camera)
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
	DirAccess.make_dir_recursive_absolute("res://artifacts")
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
		get_viewport().get_texture().get_image().save_png("res://artifacts/" + shot + ".png")
	get_tree().quit()
