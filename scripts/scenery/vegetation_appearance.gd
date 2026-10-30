class_name VegetationAppearance
extends Resource
## Art paths are optional and independent of saved ecology/class identities.
@export_file("*.fbx", "*.gltf", "*.glb", "*.tscn") var warden_model := "res://assets/local/tropical_plants/Fbx/Tropical_plant_019.fbx"
@export_file("*.fbx", "*.gltf", "*.glb", "*.tscn") var mender_model := "res://assets/local/tropical_plants/Fbx/Tropical_plant_015.fbx"
@export_file("*.fbx", "*.gltf", "*.glb", "*.tscn") var regulator_model := "res://assets/local/tropical_plants/Fbx/Tropical_plant_017.fbx"
@export_range(0.1, 1.5, 0.05) var warden_height := 0.5
@export_range(0.1, 1.5, 0.05) var mender_height := 0.35
@export_range(0.1, 1.5, 0.05) var regulator_height := 0.45
@export_range(0.2, 1.5, 0.05) var maximum_width := 0.8
var palette_material: StandardMaterial3D
const FALLBACK := {"warden": preload("res://assets/nature/Plant_7.gltf"), "mender": preload("res://assets/nature/Flower_3_Group.gltf"), "regulator": preload("res://assets/nature/Plant_1.gltf")}

func model_for(category: String) -> PackedScene:
	var path := str(get(category + "_model"))
	if ResourceLoader.exists(path):
		var scene := load(path) as PackedScene
		if scene != null: return scene
	return FALLBACK.get(category)

func height_for(category: String) -> float:
	var height := float(get(category + "_height"))
	return clampf(height, 0.1, 1.5) if is_finite(height) else 0.4

func material_for(scene: PackedScene) -> Material:
	if not scene.resource_path.begins_with("res://assets/local/tropical_plants/"): return null
	var texture_path := "res://assets/local/tropical_plants/Textures/T_Tropical_plants.png"
	if not ResourceLoader.exists(texture_path): return null
	if palette_material == null:
		palette_material = StandardMaterial3D.new()
		palette_material.albedo_texture = load(texture_path)
		palette_material.roughness = 1.0
		palette_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return palette_material
