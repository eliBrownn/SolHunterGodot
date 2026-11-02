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
## Leaf-only pigment correction; flower/stem palette swatches stay authored. Restart/rebuild.
@export var leaf_tint := Color(0.56,0.67,0.45,1.0)
@export_range(0.0,1.0,0.05) var leaf_normal_up_bias := 0.2
@export_range(0.0,0.4,0.05) var leaf_backlight := 0.1
## Tip movement in terrain cells; roots remain anchored. Restart/rebuild.
@export_range(0.0,0.08,0.002) var leaf_wind_displacement := 0.018
var palette_materials: Dictionary = {}
var prepared_parts: Dictionary = {}
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

func parts_for(category: String) -> Dictionary:
	if prepared_parts.has(category): return prepared_parts[category]
	var scene := model_for(category)
	var source: Dictionary = preload("res://scripts/scenery/nature_art.gd").compact_parts(scene)
	var material := material_for(scene, source.bounds)
	var result: Dictionary = source.duplicate()
	var pieces: Array[Dictionary] = []
	for part: Dictionary in source.pieces:
		var mesh: ArrayMesh = part.mesh
		if material != null:
			mesh = mesh.duplicate()
			for surface in range(mesh.get_surface_count()): mesh.surface_set_material(surface, material)
		pieces.append({"mesh": mesh, "transform": part.transform})
	result.pieces = pieces
	result["asset"] = scene.resource_path
	prepared_parts[category] = result
	return result

## Deterministic visual identity; neither active ecology nor player distance owns a body.
func placement(terrain: WorldTerrain, cell: Vector2i, data: Dictionary) -> Dictionary:
	# Aquatic/bank members keep their authored wetland body rather than a land specialist.
	if data.ground in [WorldTerrain.Ground.WATER, WorldTerrain.Ground.SAND]: return {}
	if terrain.flora_kind(cell, data) != "plant": return {}
	var traits := FloraTraits.describe(terrain.world_seed, {"id": FloraCatalog.id_for(cell), "cell": [cell.x, cell.y], "kind": "plant"},terrain.flora_specialist_percent)
	var category: String = traits["class"]
	if category.is_empty(): return {}
	var parts := parts_for(category)
	var bounds: AABB = parts.bounds
	var width := clampf(maximum_width, 0.2, 1.5) if is_finite(maximum_width) else 0.8
	var factor := minf(height_for(category) / maxf(0.01, bounds.size.y), width / maxf(0.01, maxf(bounds.size.x, bounds.size.z)))
	var point := Vector2(cell) + Vector2(0.5, 0.5)
	var transform := Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * factor), Vector3(point.x, terrain.surface_height(point), point.y))
	transform.origin -= Vector3(bounds.get_center().x, bounds.position.y, bounds.get_center().z) * factor
	var visual: AABB = transform * bounds
	for y in range(floori(visual.position.z), ceili(visual.end.z)):
		for x in range(floori(visual.position.x), ceili(visual.end.x)):
			var at := Vector2i(x, y)
			if terrain.scenery_reserved(at) or terrain.route_axes(at, 1) != 0 or terrain.is_camp(at) or terrain.is_landmark(at): return {}
	return {"asset": parts.asset, "cell": cell, "transform": transform, "bounds": visual, "patch": "flora_specialist", "living": true, "model": parts, "subject": traits.name}

func material_for(scene: PackedScene, bounds: AABB = AABB()) -> Material:
	if not scene.resource_path.begins_with("res://assets/local/tropical_plants/"): return null
	var texture_path := "res://assets/local/tropical_plants/Textures/T_Tropical_plants.png"
	if not ResourceLoader.exists(texture_path): return null
	if not palette_materials.has(scene.resource_path):
		var material := ShaderMaterial.new()
		material.shader=preload("res://shaders/vegetation_leaf.gdshader")
		material.set_shader_parameter("palette",load(texture_path))
		material.set_shader_parameter("leaf_tint",leaf_tint)
		material.set_shader_parameter("normal_up_bias",clampf(leaf_normal_up_bias,0,1))
		material.set_shader_parameter("backlight_strength",clampf(leaf_backlight,0,0.4))
		material.set_shader_parameter("wind_displacement",clampf(leaf_wind_displacement,0,0.08))
		material.set_shader_parameter("base_height",bounds.position.y)
		material.set_shader_parameter("plant_height",maxf(bounds.size.y,0.001))
		palette_materials[scene.resource_path]=material
	return palette_materials[scene.resource_path]

func set_weather(direction: Vector2, seconds: float, origin: Vector2) -> void:
	var airflow := direction.normalized() if direction.length_squared()>0.0001 else Vector2.ZERO
	for material: ShaderMaterial in palette_materials.values():
		material.set_shader_parameter("wind_time",seconds)
		material.set_shader_parameter("wind_direction",airflow)
		material.set_shader_parameter("world_origin",origin)
