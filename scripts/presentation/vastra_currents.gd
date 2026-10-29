extends Node3D
## Bounded cosmetic projection of authoritative readings; never changes terrain or ecology.
const SAMPLE_CACHE_LIMIT := 256
var world: Node2D
var tuning: VastraSettings
var state: ExpeditionState
var batch := MultiMeshInstance3D.new()
var instances := MultiMesh.new()
var material := ShaderMaterial.new()
var sites: Array[Vector2i] = []
var last_center := Vector2i(2147483647, 2147483647)
var batch_origin := Vector2i.ZERO
var last_terrain: WorldTerrain
var refresh_seconds := 0.0
var dirty := true
var samples: Dictionary = {}
var sample_order: Array[Vector2i] = []
var sample_cursor := 0
var last_battle: TacticalBattle
var last_action := -1
var last_clock := -1.0
var last_settings: Array = []
var refresh_count := 0
var sample_builds := 0

func bind(source: Node2D) -> void:
	world = source
	tuning = world.vastra_settings if world.vastra_settings != null and world.vastra_settings.valid() else VastraSettings.new()
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(2.8, 0.42)
	mesh.subdivide_width = 14
	instances.transform_format = MultiMesh.TRANSFORM_3D
	instances.use_colors = true
	instances.use_custom_data = true
	instances.mesh = mesh
	instances.instance_count = tuning.current_limit if tuning.currents_enabled else 0
	instances.visible_instance_count = 0
	material.shader = preload("res://shaders/vastra_current.gdshader")
	material.set_shader_parameter("batched", true)
	batch.multimesh = instances
	batch.material_override = material
	batch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(batch)
	world.state_replaced.connect(on_state)
	world.rebuilt.connect(on_rebuilt)
	on_state(world.persistent_state)
	refresh()
	set_process(instances.instance_count > 0)

func on_state(next: ExpeditionState) -> void:
	if state != null:
		if state.environment_changed.is_connected(on_environment):
			state.environment_changed.disconnect(on_environment)
		if state.battle_progress_changed.is_connected(mark_dirty):
			state.battle_progress_changed.disconnect(mark_dirty)
	state = next
	state.environment_changed.connect(on_environment)
	state.battle_progress_changed.connect(mark_dirty)
	mark_dirty()

func on_environment(cell: Vector2i) -> void:
	if cell.distance_squared_to(world.cell) <= tuning.current_radius * tuning.current_radius:
		mark_dirty()

func mark_dirty() -> void:
	dirty = true

func on_rebuilt() -> void:
	samples.clear()
	sample_order.clear()
	sample_cursor = 0
	mark_dirty()

func sample_for(cell: Vector2i) -> Dictionary:
	if samples.has(cell):
		return samples[cell]
	if sample_order.size() == SAMPLE_CACHE_LIMIT:
		samples.erase(sample_order[sample_cursor])
		sample_order[sample_cursor] = cell
		sample_cursor = (sample_cursor + 1) % SAMPLE_CACHE_LIMIT
	else:
		sample_order.append(cell)
	var hash_value := absi(hash("vastra-current:%d:%d:%d" % [world.terrain.world_seed, cell.x, cell.y]))
	var sample := {"concentration": int(world.terrain.sample(cell).concentration),
		"height": world.host.ground_height(Vector2(cell) + Vector2(0.5, 0.5)) + 0.28,
		"phase": float(hash_value % 1000) / 100.0, "rotation": float(hash_value % 628) / 100.0}
	samples[cell] = sample
	sample_builds += 1
	return sample

func refresh() -> void:
	if instances.instance_count == 0:
		return
	if last_terrain != world.terrain:
		on_rebuilt()
	last_center = world.cell
	batch_origin = world.cell
	last_terrain = world.terrain
	sites = state.vastra_changes_near(world.cell, tuning.current_radius)
	var seen := {}
	for cell in sites:
		seen[cell] = true
	var battle: TacticalBattle = world.host.battles.session if world.host.battles != null else null
	if battle != null:
		for key: String in battle.vastra_overloads:
			var parts := key.split(":")
			var cell := Vector2i(int(parts[0]), int(parts[1]))
			if not seen.has(cell) and cell.distance_squared_to(world.cell) <= tuning.current_radius * tuning.current_radius:
				sites.append(cell)
				seen[cell] = true
	sites.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.distance_squared_to(world.cell) < b.distance_squared_to(world.cell))
	var ambient: Array[Vector2i] = []
	var center := Vector2i(floori(float(world.cell.x) / 4.0) * 4, floori(float(world.cell.y) / 4.0) * 4)
	for y in range(-tuning.current_radius, tuning.current_radius + 1, 4):
		for x in range(-tuning.current_radius, tuning.current_radius + 1, 4):
			var cell := center + Vector2i(x, y)
			if cell.distance_squared_to(world.cell) <= tuning.current_radius * tuning.current_radius and not seen.has(cell):
				ambient.append(cell)
	ambient.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.distance_squared_to(world.cell) < b.distance_squared_to(world.cell))
	sites.append_array(ambient)
	instances.visible_instance_count = mini(instances.instance_count, sites.size())
	var bounds := AABB()
	for index in range(instances.visible_instance_count):
		var cell := sites[index]
		var sample := sample_for(cell)
		var data := state.environment_view(cell, {"concentration": sample.concentration, "overload": 0})
		var overload := int(data.overload)
		if battle != null:
			overload = int(battle.tile_overloads.get(cell, overload))
		# Keep GPU instance translations small even near the world-coordinate limit.
		var anchor := Vector3(cell.x - batch_origin.x + 0.5, sample.height, cell.y - batch_origin.y + 0.5)
		instances.set_instance_transform(index, Transform3D(Basis(Vector3.UP, sample.rotation), anchor))
		var extent := Vector3(1.5, 0.3, 1.5) # Includes the shader's maximum vertical displacement.
		var local_bounds := AABB(anchor - extent, extent * 2.0)
		bounds = local_bounds if index == 0 else bounds.merge(local_bounds)
		var opacity := tuning.current_opacity * (0.4 + float(data.concentration) / 100.0 + float(absi(overload)) / 100.0)
		instances.set_instance_custom_data(index, Color(sample.phase, float(maxi(0, overload)) / 100.0, opacity, 0))
		# MultiMesh colors are linear, matching source_color uniforms on unbatched cues.
		var color: Color = world.host.sightings.visual_settings.color_for(str(data.affinity)) if data.has("affinity") else Color.WHITE
		instances.set_instance_color(index, color.srgb_to_linear())
	instances.custom_aabb = bounds
	position = Vector3(batch_origin.x - world.camera.position.x / 32.0, 0, batch_origin.y - world.camera.position.y / 32.0)
	material.set_shader_parameter("distortion", tuning.current_distortion)
	dirty = false
	refresh_count += 1

func _process(delta: float) -> void:
	if world == null or instances.instance_count == 0:
		return
	var battle: TacticalBattle = world.host.battles.session if world.host.battles != null else null
	if battle != last_battle or (battle != null and battle.action_serial != last_action):
		mark_dirty()
		last_battle = battle
		last_action = battle.action_serial if battle != null else -1
	refresh_seconds += delta
	if refresh_seconds >= 0.5:
		# Resource edits may be made in place without emitting changed.
		var signature := [tuning.current_radius, tuning.current_opacity, tuning.current_distortion, world.host.sightings.visual_settings.palette.duplicate()]
		if signature != last_settings:
			last_settings = signature
			mark_dirty()
		refresh_seconds = 0.0
		if dirty:
			refresh()
	if last_center != world.cell or last_terrain != world.terrain:
		refresh()
	position = Vector3(batch_origin.x - world.camera.position.x / 32.0, 0, batch_origin.y - world.camera.position.y / 32.0)
	var seconds: float = state.activity_seconds()
	if battle != null:
		seconds += world.host.battles.visual_seconds
	if seconds != last_clock:
		material.set_shader_parameter("clock_seconds", seconds)
		last_clock = seconds
