extends MeshInstance3D
## A depth-tested silhouette only for the player pixels hidden by opaque geometry.

var source: Sprite3D
var view_camera: Camera3D
var indicator_material := ShaderMaterial.new()
var quad := QuadMesh.new()

func bind(actor: Sprite3D, camera: Camera3D) -> void:
	source = actor
	view_camera = camera
	process_priority = 2
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	indicator_material.shader = preload("res://shaders/player_occlusion.gdshader")
	indicator_material.render_priority = 100
	mesh = quad
	material_override = indicator_material
	sync_source()

func _process(_delta: float) -> void:
	sync_source()

func sync_source() -> void:
	if source == null or not source.texture is AtlasTexture:
		return
	var atlas: AtlasTexture = source.texture
	quad.size = Vector2(atlas.get_width(), atlas.get_height()) * source.pixel_size
	basis = view_camera.global_basis
	position = source.position + basis.x * source.offset.x * source.pixel_size + basis.y * source.offset.y * source.pixel_size
	var size := Vector2(atlas.atlas.get_width(), atlas.atlas.get_height())
	var first := (atlas.region.position + Vector2(0.5, 0.5)) / size
	var extent := (atlas.region.size - Vector2.ONE) / size
	indicator_material.set_shader_parameter("actor_texture", atlas.atlas)
	indicator_material.set_shader_parameter("atlas_region", Vector4(first.x, first.y, extent.x, extent.y))
	indicator_material.set_shader_parameter("flip_h", source.flip_h)
