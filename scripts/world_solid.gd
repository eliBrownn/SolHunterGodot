extends "res://scripts/world_plane.gd"
## Optional solid-3D view over the unchanged generated world and expedition simulation.

const SolidChunk = preload("res://scripts/solid_chunk.gd")
var solid_root := Node3D.new()
var place_root: Node3D
var solid_chunks: Dictionary = {}
var selection := Node3D.new()
var player_shadow := MeshInstance3D.new()

func _ready() -> void:
	capture_directory = "res://artifacts/solid3d"
	super._ready()
	# Rebase after the 2D simulation updates its camera, avoiding a one-frame ground lag.
	process_priority = 1
	# Retain the simulation and HUD; remove the baked world image from this view.
	surface.hide()
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	world.chunk_root.hide()
	world.actors.hide()
	player_billboard.ground_height = 0.06
	add_child(solid_root)
	build_selection()
	build_player_shadow()
	world.chunk_published.connect(publish_solid)
	world.chunk_removed.connect(remove_solid)
	world.rebuilt.connect(build_solid_places)
	for coord: Vector2i in world.chunks:
		publish_solid(coord, world.chunks[coord].view.cells)
	build_solid_places()
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52, -28, 0)
	sun.light_color = Color("fff0d7")
	sun.light_energy = 0.85
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 80.0
	add_child(sun)
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("90a5ad")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("c6d2db")
	environment.ambient_light_energy = 0.35
	# Preserve authored sprite colors instead of applying a cinematic contrast curve.
	environment.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	var atmosphere := WorldEnvironment.new()
	atmosphere.environment = environment
	add_child(atmosphere)
	sync_ground()

func _process(_delta: float) -> void:
	sync_ground()

func sync_ground() -> void:
	solid_root.position = Vector3(-world.camera.position.x / 32.0, 0, -world.camera.position.y / 32.0)
	var player_relative: Vector2 = (world.explorer.position - world.camera.position) / 32.0
	player_shadow.position = Vector3(player_relative.x, 0.045, player_relative.y)
	selection.visible = world.hover_outline.visible
	if selection.visible:
		var hovered: Vector2 = world.hover_outline.position / 32.0
		var data: Dictionary = world.terrain.sample(Vector2i(hovered))
		selection.position = Vector3(hovered.x + 0.5, -0.20 if data.ground == WorldTerrain.Ground.WATER else 0.07, hovered.y + 0.5)

func build_player_shadow() -> void:
	var disc := CylinderMesh.new()
	disc.top_radius = 0.34
	disc.bottom_radius = 0.34
	disc.height = 0.002
	disc.radial_segments = 16
	player_shadow.mesh = disc
	player_shadow.scale.z = 0.55
	player_shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(0.04, 0.06, 0.04, 0.28)
	player_shadow.material_override = material
	add_child(player_shadow)

func build_selection() -> void:
	solid_root.add_child(selection)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color("e1cd95")
	for side in range(4):
		var bar := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(1.0, 0.025, 0.025) if side < 2 else Vector3(0.025, 0.025, 1.0)
		bar.mesh = box
		bar.material_override = material
		bar.position = Vector3(0, 0, -0.49 if side == 0 else 0.49) if side < 2 else Vector3(-0.49 if side == 2 else 0.49, 0, 0)
		selection.add_child(bar)
	selection.hide()

func publish_solid(coord: Vector2i, cells: Array[Dictionary]) -> void:
	remove_solid(coord)
	var chunk := SolidChunk.new()
	chunk.position = Vector3(coord.x * 16, 0, coord.y * 16)
	chunk.build(cells)
	solid_root.add_child(chunk)
	solid_chunks[coord] = chunk

func remove_solid(coord: Vector2i) -> void:
	if solid_chunks.has(coord):
		solid_chunks[coord].free()
		solid_chunks.erase(coord)

func build_solid_places() -> void:
	if place_root != null:
		place_root.free()
	place_root = SolidChunk.new()
	solid_root.add_child(place_root)
	# A deliberately decorative refuge mockup for judging architectural depth.
	var cabin := Vector2i(-3, -4)
	piece("prop", cabin, Vector3(0, 0.12, 0), Vector3(3.0, 0.24, 2.4), Color("777d76"))
	piece("wall", cabin, Vector3(0, 1.04, 0), Vector3(2.8, 1.60, 2.0), Color.WHITE)
	piece("roof", cabin, Vector3(0, 2.27, 0), Vector3(3.3, 0.86, 2.5), Color("665a4f"))
	piece("prop", cabin, Vector3(0, 0.86, 1.015), Vector3(0.64, 1.24, 0.05), Color("594431"))
	for window_x in [-0.94, 0.94]:
		piece("prop", cabin, Vector3(window_x, 1.13, 1.025), Vector3(0.48, 0.44, 0.06), Color("d1bb81"))
	# Reuse the authored artwork and anchors instead of re-authoring a low-poly prop set.
	for prop: Node2D in world.place_props:
		var key: String = prop.get_meta("asset_key", "")
		if not key.is_empty():
			place_root.add_piece("asset:" + key, Vector3(prop.position.x / 32.0, 0.04, prop.position.y / 32.0), Vector3.ONE, Color.WHITE)
	place_root.finish()
	sync_ground()

func piece(kind: String, cell: Vector2i, offset: Vector3, size: Vector3, color: Color) -> void:
	place_root.add_piece(kind, Vector3(cell.x + 0.5, 0, cell.y + 0.5) + offset, size, color)
