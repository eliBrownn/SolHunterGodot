extends Node3D
## Read-only, bounded projection. Swarm members have no simulation authority.
const Particles = preload("res://scenes/vessel_particle_swarm.tscn")
const MEMBERS := 24
const MAX_GROUPS := 16
const PLANT_LIMIT := 24
const Art = preload("res://scripts/scenery/nature_art.gd")
var appearance: VegetationAppearance = preload("res://resources/vegetation_appearance.tres")
var world: Node2D
var batch: GPUParticles3D = Particles.instantiate()
var swarm_batches: Array[GPUParticles3D] = []
var plant_pulses := MultiMeshInstance3D.new()
var groups: Array[Dictionary] = []
var plants: Dictionary = {}
var picks: Array[Dictionary] = []
var last_tick := -1
var last_state: ExpeditionState
var last_focus := Vector2i(2147483647, 2147483647)
var warning := Label.new()
var ground_cache: Dictionary = {}
var last_terrain: WorldTerrain

func bind(source: Node2D) -> void:
	world = source
	if world.host.get("vegetation_appearance") is VegetationAppearance: appearance = world.host.vegetation_appearance
	configure_batch(batch)
	swarm_batches.append(batch)
	var pulse_mesh := TorusMesh.new()
	pulse_mesh.inner_radius = 0.17
	pulse_mesh.outer_radius = 0.19
	pulse_mesh.rings = 12
	pulse_mesh.ring_segments = 6
	var pulse_material := StandardMaterial3D.new()
	pulse_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	pulse_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	pulse_material.vertex_color_use_as_albedo = true
	plant_pulses.material_override = pulse_material
	plant_pulses.multimesh = MultiMesh.new()
	plant_pulses.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	plant_pulses.multimesh.use_colors = true
	plant_pulses.multimesh.mesh = pulse_mesh
	plant_pulses.multimesh.instance_count = PLANT_LIMIT
	plant_pulses.multimesh.visible_instance_count = 0
	plant_pulses.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(plant_pulses)
	warning.add_theme_font_size_override("font_size", 18)
	warning.add_theme_color_override("font_color", Color("f3d7b0"))
	warning.add_theme_color_override("font_shadow_color", Color.BLACK)
	warning.add_theme_constant_override("shadow_offset_x", 2)
	warning.add_theme_constant_override("shadow_offset_y", 2)
	warning.set_meta("ui_keep_single_line", true)
	warning.autowrap_mode = TextServer.AUTOWRAP_OFF
	warning.clip_text = true
	warning.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	warning.size = Vector2(700, 28)
	warning.mouse_filter = Control.MOUSE_FILTER_IGNORE
	world.hud.add_child(warning)


func configure_batch(target: GPUParticles3D) -> void:
	target.member_count = clampi(target.member_count, 1, MEMBERS)
	target.external_clock = true
	target.visible = false
	add_child(target)
	target.process_material.set_shader_parameter("live_group", true)

func ground(at: Vector2) -> float:
	if not ground_cache.has(at): ground_cache[at] = world.host.ground_height(at)
	return float(ground_cache[at])

func refresh() -> void:
	groups = world.persistent_state.active_vessels()
	groups.resize(mini(groups.size(), MAX_GROUPS))
	var wanted := {}
	var rows: Array[Dictionary] = world.persistent_state.ecology_plants(world.cell, PLANT_LIMIT)
	for row in rows:
		wanted[row.id] = true
		if plants.has(row.id):
			plants[row.id].activity = row.activity
			continue
		var model := appearance.model_for(str(row.traits["class"]))
		var parts: Dictionary = Art.compact_parts(model)
		var root := Node3D.new()
		for part: Dictionary in parts.pieces:
			var piece := MeshInstance3D.new()
			piece.mesh = part.mesh
			piece.transform = part.transform
			piece.material_override = appearance.material_for(model)
			root.add_child(piece)
		var bounds: AABB = parts.bounds
		var height := appearance.height_for(str(row.traits["class"]))
		var width := clampf(appearance.maximum_width, 0.2, 1.5) if is_finite(appearance.maximum_width) else 0.8
		var factor := minf(height / maxf(0.01, bounds.size.y), width / maxf(0.01, maxf(bounds.size.x, bounds.size.z)))
		root.scale = Vector3.ONE * factor
		add_child(root)
		plants[row.id] = {"root": root, "cell": row.cell, "subject": row.traits.name, "activity": row.activity, "offset": Vector3(bounds.get_center().x, bounds.position.y, bounds.get_center().z) * factor}
	for id in plants.keys():
		if not wanted.has(id):
			plants[id].root.free()
			plants.erase(id)

func _process(_delta: float) -> void:
	if world == null: return
	if last_terrain != world.terrain:
		last_terrain = world.terrain
		ground_cache.clear()
	var tick: int = world.persistent_state.activity_tick()
	if last_state != world.persistent_state or tick != last_tick or last_focus != world.cell:
		if ground_cache.size() > 256: ground_cache.clear()
		last_state = world.persistent_state
		last_tick = tick
		last_focus = world.cell
		refresh()
	var origin: Vector2 = world.camera.position / 32.0
	var clock: float = world.persistent_state.activity_seconds()
	var group_index := 0
	picks.clear()
	var hazard := ""
	for target: GPUParticles3D in swarm_batches: target.visible = false
	for group in groups:
		if group_index >= swarm_batches.size():
			var target: GPUParticles3D = Particles.instantiate()
			configure_batch(target)
			swarm_batches.append(target)
		var target: GPUParticles3D = swarm_batches[group_index]
		group_index += 1
		var visual_delta: float = maxf(0.0, clock - target.elapsed)
		target.set_visual_time(clock)
		var requested_anger := 1.0 if group.state == "escalating" else (0.4 if group.state == "responding" else 0.0)
		target.anger = move_toward(target.anger, requested_anger, visual_delta)
		var at := Vector2(float(group.cell[0]) + 0.5, float(group.cell[1]) + 0.5)
		var floor_y := ground(at)
		var center := Vector3(at.x - origin.x, floor_y + 0.6, at.y - origin.y)
		var storm: bool = int(group.storm_until) > tick
		var radius := {"ordinary": 1.0, "investigating": 0.85, "responding": 0.6, "escalating": 1.5, "recovering": 1.15}[str(group.state)] as float
		if storm: radius = 2.0
		var tint: Color = world.host.sol_visual_settings.color_for(str(world.persistent_state.environment_view(VesselEcology.cell(group), {"affinity": world.terrain.affinity_at(VesselEcology.cell(group))}).affinity))
		target.position = center
		target.visibility_aabb = AABB(Vector3(-radius - 0.35, -0.7, -radius - 0.35), Vector3((radius + 0.35) * 2, 2.8 if storm else 1.5, (radius + 0.35) * 2))
		target.material.set_shader_parameter("affinity_tint", tint)
		target.process_material.set_shader_parameter("group_seed", float(absi(hash(str(group.id))) % 65536))
		target.process_material.set_shader_parameter("group_radius", radius)
		target.process_material.set_shader_parameter("response_active", group.state in ["responding", "escalating"])
		target.process_material.set_shader_parameter("storm_active", storm)
		target.process_material.set_shader_parameter("recovering", group.state == "recovering")
		target.visible = true
		picks.append({"center": center, "radius": radius + 0.15, "cell": VesselEcology.cell(group), "subject": "Vessel swarm"})
		if at.distance_to(Vector2(world.cell)) < 5:
			if storm: hazard = "Vastra storm nearby"
			elif group.state == "escalating" and hazard.is_empty(): hazard = "Vessel discharges nearby"
	var pulse_index := 0
	for record: Dictionary in plants.values():
		var at := Vector2(float(record.cell[0]) + 0.5, float(record.cell[1]) + 0.5)
		var anchor := Vector3(at.x - origin.x, ground(at), at.y - origin.y)
		record.root.position = anchor - record.offset
		picks.append({"center": anchor + Vector3(0, 0.2, 0), "radius": 0.4, "cell": Vector2i(int(record.cell[0]), int(record.cell[1])), "subject": record.subject})
		if record.activity == "idle": continue
		var phase := fposmod(clock / ExpeditionContract.ACTIVITY_INTERVAL, 1.0)
		var size := lerpf(0.6, 1.8, phase)
		var lift := 0.12
		if record.activity == "repairing": size = lerpf(1.8, 0.4, phase)
		if record.activity == "regulating":
			size = 0.7
			lift += phase * 0.3
		plant_pulses.multimesh.set_instance_transform(pulse_index, Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * size), anchor + Vector3.UP * lift))
		var plant_cell := Vector2i(int(record.cell[0]), int(record.cell[1]))
		var plant_affinity: String = world.persistent_state.environment_view(plant_cell, {"affinity": world.terrain.affinity_at(plant_cell)}).affinity
		var tint: Color = world.host.sol_visual_settings.color_for(plant_affinity)
		tint.a = (1.0 - phase) * 0.55
		plant_pulses.multimesh.set_instance_color(pulse_index, tint)
		pulse_index += 1
	plant_pulses.multimesh.visible_instance_count = pulse_index
	warning.text = hazard
	warning.position = Vector2(24, maxf(90, get_viewport().get_visible_rect().size.y - 115))
	warning.size.x = maxf(100, get_viewport().get_visible_rect().size.x - 48)
	warning.visible = not hazard.is_empty() and not world.paused

func pick(origin: Vector3, direction: Vector3, maximum: float) -> Dictionary:
	var result := {}
	for target in picks:
		var delta: Vector3 = target.center - origin
		var along := delta.dot(direction)
		if along < 0 or along >= maximum: continue
		var radius := float(target.radius)
		var lateral := delta.length_squared() - along * along
		if lateral > radius * radius: continue
		var distance := maxf(0, along - sqrt(maxf(0, radius * radius - lateral)))
		if distance < maximum:
			maximum = distance
			result = {"cell": target.cell, "subject": target.subject, "distance": distance}
	return result

func _exit_tree() -> void:
	if is_instance_valid(warning): warning.queue_free()
