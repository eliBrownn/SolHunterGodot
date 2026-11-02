extends RefCounted
## Structure-only palette. Original relic materials remain unchanged.
const BASES := [
	"res://assets/terrain/ambientcg/rock051/Rock051_2K-JPG",
	"res://assets/terrain/ambientcg/rock035/Rock035_2K-JPG",
	"res://assets/terrain/ambientcg/rock030/Rock030_2K-JPG",
	"res://assets/structures/ambientcg/bricks075a/Bricks075A_2K-JPG",
	"res://assets/structures/ambientcg/rock034/Rock034_2K-JPG"
]
static func create(style: int) -> StandardMaterial3D:
	var surface := StandardMaterial3D.new()
	var prefix: String = BASES[clampi(style, 0, BASES.size() - 1)]
	surface.albedo_color = [Color("30333b"), Color("454854"), Color("53535b"), Color("53515b"), Color("40434d")][clampi(style, 0, 4)]
	surface.albedo_texture = load(prefix + "_Color.jpg")
	surface.normal_enabled = true
	surface.normal_texture = load(prefix + "_NormalGL.jpg")
	surface.normal_scale = 0.65
	surface.roughness_texture = load(prefix + "_Roughness.jpg")
	surface.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
	surface.roughness = 0.95
	if ResourceLoader.exists(prefix + "_AmbientOcclusion.jpg"):
		surface.ao_enabled = true
		surface.ao_texture = load(prefix + "_AmbientOcclusion.jpg")
	surface.uv1_triplanar = true
	surface.uv1_scale = Vector3.ONE
	return surface
