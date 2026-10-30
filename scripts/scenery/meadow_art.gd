extends RefCounted
## Individual blades on canonical grass cells; atmosphere supplies the only wind clock.
## Legacy authored grass remains on disk for source/provenance, never rendered here.
const SUPERSEDED_GRASS := ["res://assets/nature/Grass_Common_Short.gltf", "res://assets/nature/Grass_Common_Tall.gltf", "res://assets/nature/Grass_Wispy_Short.gltf", "res://assets/nature/Grass_Wispy_Tall.gltf", "res://assets/biome_placeholders/grass_tuft.tscn"]
static var meshes: Dictionary = {}
static var material: ShaderMaterial
static var style_identity := 0
static var weather: Dictionary = {}

static func mesh(ground: int = 0, style: MeadowAppearance = null) -> ArrayMesh:
	if material == null:
		material = ShaderMaterial.new()
		material.shader = preload("res://shaders/meadow.gdshader")
		material.set_shader_parameter("ground_base_color",Color.WHITE)
		if not weather.is_empty(): set_weather(weather.direction,weather.rain,weather.seconds,weather.origin)
	var width := (style.blade_width if style != null else 0.028) * (style.biome_width[ground] if style != null else Vector4(1.0,1.5,0.65,0.65)[ground])
	var curve := (style.blade_curve if style != null else 0.06) * (style.biome_curve[ground] if style != null else Vector4(1.0,1.4,0.9,0.3)[ground])
	var key := Vector2(width,curve)
	if not meshes.has(key):
		var shape := preload("res://scripts/scenery/grass_blade_mesh.gd").create(width,curve)
		shape.surface_set_material(0,material)
		meshes[key] = shape
	return meshes[key]

static func set_weather(direction: Vector2, rain: float, seconds: float = 0.0, origin: Vector2 = Vector2.ZERO) -> void:
	weather = {"direction":direction,"rain":rain,"seconds":seconds,"origin":origin}
	if material == null: return
	var airflow := direction.normalized() if direction.length_squared() > 0.0001 else Vector2.ZERO
	var strength := lerpf(1.0, 1.6, clampf(rain, 0.0, 1.0)) if airflow != Vector2.ZERO else 0.0
	material.set_shader_parameter("wind_strength", strength)
	material.set_shader_parameter("wind_direction", airflow)
	material.set_shader_parameter("wind_time", seconds)
	material.set_shader_parameter("world_origin", origin)

static func add_cell(chunk: Node3D, terrain: WorldTerrain, cell: Vector2i, data: Dictionary, settings: NatureSettings, leave_center: bool = false) -> void:
	# Dense grass must not disguise an unscalable cell as an inviting hillside.
	# Each grass cell keeps one Vastra identity regardless of blade count.
	if data.ground not in [WorldTerrain.Ground.MEADOW, WorldTerrain.Ground.FOREST, WorldTerrain.Ground.HEATH, WorldTerrain.Ground.MARSH]: return
	if not settings.meadow_enabled or terrain.flora_kind(cell, data) != "plant": return
	var style: MeadowAppearance = settings.meadow_appearance
	var verge := 1.0
	for ring in range(1,style.trail_verge_cells+1):
		var found := false
		for offset in [Vector2i(-ring,0),Vector2i(ring,0),Vector2i(0,-ring),Vector2i(0,ring),Vector2i(-ring,-ring),Vector2i(ring,-ring),Vector2i(-ring,ring),Vector2i(ring,ring)]:
			if terrain.route_axes(cell + offset,1) != 0: found = true
		if found:
			verge = float(ring-1)/maxf(float(style.trail_verge_cells),1.0)
			break
	var cover := lerpf(style.trail_verge_density,1.0,verge)
	var stature := lerpf(style.trail_verge_height,1.0,verge)
	var source := mesh(data.ground,style)
	if settings.meadow_appearance!=null and style_identity!=settings.meadow_appearance.get_instance_id():
		style_identity=settings.meadow_appearance.get_instance_id()
		for property in ["root_shade","tip_brightness","texture_detail","patch_variation","normal_up_bias","backlight_strength","alpha_cutoff","wind_displacement","wind_speed","density_start","density_end","distant_density"]:
			material.set_shader_parameter(property,settings.meadow_appearance.get(property))
	var tint := style.biome_colors[data.ground] * terrain.habitat_tint(cell) * settings.ground_tint_at(terrain, cell)
	var bounds := source.get_aabb()
	var key := "nature_detail_meadow_%d" % data.ground
	var local := cell - Vector2i(chunk.cell_origin)
	var section := Vector2i(local.x / settings.meadow_batch_cells, local.y / settings.meadow_batch_cells)
	if section != Vector2i.ZERO: key += "_%d_%d" % [section.x, section.y]
	chunk.meshes[key] = source
	if not chunk.batches.has(key): chunk.batches[key] = []
	var divisions := clampi(settings.meadow_divisions, 2, 16)
	var source_registered := false
	# Every blade lies inside this cell's two terrain triangles. Resolve their
	# shared vertices and slope admission once, preserving the generator's split.
	# Specialized review terrains may override surface queries independently.
	var shared_surface: bool = terrain.get_script() == WorldTerrain
	var heights := terrain.corners(cell) if shared_surface else Vector4.ZERO
	var upper_ok := Vector3(-(heights.y-heights.x),1,-(heights.z-heights.y)).normalized().y >= 0.8
	var lower_ok := Vector3(-(heights.z-heights.w),1,-(heights.w-heights.x)).normalized().y >= 0.8
	for index in range(divisions * divisions):
		var roll := terrain.roll(cell, 94231 + index * 2)
		if float(terrain.roll(cell,102031 + index) % 1000) / 1000.0 >= style.biome_coverage[data.ground] * cover: continue
		var offset := Vector2(float(index % divisions) + 0.15 + float(roll % 701) / 1000.0, float(index / divisions) + 0.15 + float((roll / 701) % 701) / 1000.0) / float(divisions)
		# Leave the specialist body readable, with surrounding grass in the same cell.
		if leave_center and offset.distance_to(Vector2(0.5,0.5)) < 0.18: continue
		var point := Vector2(cell) + offset
		var surface_offset := point - Vector2(cell)
		if shared_surface:
			if not (upper_ok if surface_offset.y <= surface_offset.x else lower_ok): continue
		elif terrain.surface_normal(point).y < 0.8: continue
		var height: float = settings.meadow_height * style.biome_height[data.ground] * stature * lerpf(0.7, 1.25, float(terrain.roll(cell, 94232 + index * 2) % 1001) / 1000.0)
		var factor := height / maxf(bounds.size.y, 0.001)
		var basis := Basis(Vector3.UP, float(roll % 6283) / 1000.0).scaled(Vector3(1.0,factor,1.0))
		var surface_y := TerrainHeightfield.interpolate(heights,surface_offset) if shared_surface else terrain.surface_height(point)
		var at := Vector3(point.x - chunk.cell_origin.x, surface_y - bounds.position.y * factor, point.y - chunk.cell_origin.y)
		if not source_registered:
			chunk.register_living_source(cell, "detail", "meadow_grass", Vector3(cell.x + 0.5, terrain.surface_height(Vector2(cell) + Vector2(0.5,0.5)) + 0.05, cell.y + 0.5),Vector3.INF,true,-1)
			source_registered = true
		# Unused instance alpha carries a deterministic blade rank, avoiding
		# per-vertex hashes and floating-origin changes in distance thinning.
		var instance_color := tint
		instance_color.a = float(roll % 1001) / 1000.0
		chunk.batches[key].append({"transform":Transform3D(basis, at), "color":instance_color,"plant_cell":cell,"plant_pivot":at})
