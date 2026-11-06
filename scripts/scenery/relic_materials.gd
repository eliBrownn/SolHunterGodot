extends RefCounted
## Authored ambientCG maps, shared by generated relic stones. No synthetic normals.
const PREFIX := "res://assets/terrain/ambientcg/rock051/Rock051_2K-JPG"

static func create(style: int, tint: Color, texture_scale: float) -> StandardMaterial3D:
	var prefix := PREFIX
	var surface := StandardMaterial3D.new()
	surface.albedo_color = tint * [Color("202329"), Color("13161b"), Color("303039")][clampi(style, 0, 2)]
	surface.albedo_texture = load(prefix + "_Color.jpg")
	surface.normal_enabled = true
	surface.normal_texture = load(prefix + "_NormalGL.jpg")
	surface.normal_scale = 0.65
	surface.roughness_texture = load(prefix + "_Roughness.jpg")
	surface.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
	surface.ao_enabled = true
	surface.ao_texture = load(prefix + "_AmbientOcclusion.jpg")
	surface.ao_light_affect = 0.35
	surface.metallic_texture = load(prefix + "_Metalness.jpg")
	surface.metallic_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
	surface.metallic = 0.0
	surface.uv1_triplanar = true
	surface.uv1_scale = Vector3.ONE * clampf(texture_scale, 0.25, 3.0)
	surface.vertex_color_use_as_albedo = true
	return surface
