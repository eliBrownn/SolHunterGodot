extends Sprite3D
## Camera-facing character art; simulation and the flat ground shadow stay in 2D.

var actor: Node2D
var terrain_camera: Camera2D

func bind(source: Node2D, source_camera: Camera2D) -> void:
	actor = source
	terrain_camera = source_camera
	pixel_size = 1.0 / WorldTerrain.CELL_SIZE
	billboard = BaseMaterial3D.BILLBOARD_ENABLED
	texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	actor.body.hide()
	sync_art()

func _process(_delta: float) -> void:
	sync_art()

func sync_art() -> void:
	if actor == null or actor.body == null:
		return
	var body: Sprite2D = actor.body
	texture = body.texture
	flip_h = body.flip_h
	# Preserve the source pack's foot pivot rather than centering the body on the ground.
	offset = Vector2(texture.get_width() * 0.5 + body.offset.x,
		-texture.get_height() * 0.5 - body.offset.y - body.position.y)
	var relative: Vector2 = actor.position - terrain_camera.position
	position = Vector3(relative.x / WorldTerrain.CELL_SIZE, 0.01, relative.y / WorldTerrain.CELL_SIZE)
