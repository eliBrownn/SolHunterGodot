extends Node3D
## Bounded cosmetic projection of authoritative readings; never changes terrain or ecology.
const SAMPLE_CACHE_LIMIT := 512
const SURFACE_BANKS := 3
const REGION_SIZE := VastraSettings.SOURCE_REGION_SIZE
const MAX_PARTICLES := 128
const MAX_GLOW_LIGHTS := 8
var glow_lights: Array[OmniLight3D] = []
var study_mode := false # Explicit art fixture only; live play consumes conserved simulation transfers.
var world: Node2D
var tuning: VastraSettings
var state: ExpeditionState
var batch := MeshInstance3D.new()
var wisp_batch := MeshInstance3D.new()
var wisp_material := ShaderMaterial.new()
var particle_batch := MultiMeshInstance3D.new()
var particle_material := ShaderMaterial.new()
var particle_paths: Array[Dictionary] = []
var last_particle_clock := -INF
var last_particle_settings: Array = []
var previous_batch := MeshInstance3D.new()
var previous_wisps := MeshInstance3D.new()
var transition_progress := 1.0
var heatmap_batch := MeshInstance3D.new()
var heatmap_material := ShaderMaterial.new()
var network_nodes: Dictionary = {}
var network_edges: Array = []
var source_assets: Dictionary = {}
var node_assets: Dictionary = {}
var edge_styles: Dictionary = {}
var network_vertices := PackedVector3Array()
var optical_seconds := 0.0
var flow_focus := Vector3.ZERO
var flow_distances: Dictionary = {}
var secondary_links := 0
var living_anchors: Array[Vector4] = []
var living_groups: Array[Dictionary] = []
var last_living_signature: Array = []
var selected_regions: Array[Vector2i] = []
var vegetation_cache: Dictionary = {}
var source_region_cache: Dictionary = {}
var anchor_cache: Dictionary = {}
var junction_cache: Dictionary = {}
var edge_cache: Dictionary = {}
var geometry_signature: Array = []
var material := ShaderMaterial.new()
var optical_noise := ImageTexture3D.new()
var sites: Array[Vector2i] = []
var batch_origin := Vector2i.ZERO
var last_terrain: WorldTerrain
var refresh_seconds := 0.0
var dirty := true
var samples: Dictionary = {}
var sample_order: Array[Vector2i] = []
var sample_cursor := 0
var clearance_cache: Dictionary = {}
var last_battle: TacticalBattle
var last_action := -1
var last_clock := -1.0
var last_settings: Array = []
var refresh_count := 0
var sample_builds := 0
var refresh_stage_peaks: Dictionary = {}

func bind(source: Node2D) -> void:
	world = source
	tuning = world.vastra_settings if world.vastra_settings != null and world.vastra_settings.valid() else VastraSettings.new()
	material.shader = preload("res://shaders/vastra_current.gdshader")
	material.set_shader_parameter("network", true)
	build_optical_noise()
	batch.material_override = material
	batch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(batch)
	wisp_material.shader = material.shader
	wisp_material.set_shader_parameter("network", true)
	wisp_material.set_shader_parameter("wisp_layer", true)
	wisp_material.set_shader_parameter("field_noise", optical_noise)
	wisp_batch.material_override = wisp_material
	wisp_batch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(wisp_batch)
	particle_material.shader = preload("res://shaders/vastra_particles.gdshader")
	particle_material.set_shader_parameter("particle_texture", preload("res://assets/effects/kenney_particles/light_01.png"))
	var motes := MultiMesh.new()
	motes.transform_format = MultiMesh.TRANSFORM_3D
	motes.use_colors = true
	motes.use_custom_data = true
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE
	motes.mesh = quad
	motes.instance_count = MAX_PARTICLES
	motes.visible_instance_count = 0
	particle_batch.multimesh = motes
	particle_batch.material_override = particle_material
	particle_batch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(particle_batch)
	for index in range(MAX_GLOW_LIGHTS):
		var light := OmniLight3D.new()
		light.name = "VastraGlow%d" % index
		light.shadow_enabled = false
		light.light_bake_mode = Light3D.BAKE_DISABLED
		light.hide()
		add_child(light)
		glow_lights.append(light)
	for layer in [previous_batch, previous_wisps]:
		layer.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		layer.visible = false
		add_child(layer)
	heatmap_material.shader = preload("res://shaders/vastra_heatmap.gdshader")
	heatmap_batch.material_override = heatmap_material
	heatmap_batch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	heatmap_batch.visible = false
	add_child(heatmap_batch)
	world.state_replaced.connect(on_state)
	world.rebuilt.connect(on_rebuilt)
	on_state(world.persistent_state)
	refresh()
	sync_wisps()
	set_process(tuning.currents_enabled and tuning.current_limit > 0)

func build_optical_noise() -> void:
	# Small periodic volume: trilinear GPU sampling replaces dozens of fragment hashes.
	var rng := RandomNumberGenerator.new()
	rng.seed = 721031
	var slices: Array[Image] = []
	for z in range(32):
		var bytes := PackedByteArray()
		bytes.resize(32 * 32 * 4)
		for pixel in range(32 * 32):
			var value := rng.randi()
			for channel in range(4):
				bytes[pixel * 4 + channel] = (value >> (channel * 8)) & 255
		slices.append(Image.create_from_data(32, 32, false, Image.FORMAT_RGBA8, bytes))
	optical_noise.create(Image.FORMAT_RGBA8, 32, 32, 32, false, slices)
	material.set_shader_parameter("field_noise", optical_noise)

func on_state(next: ExpeditionState) -> void:
	if state != null:
		if state.environment_changed.is_connected(on_environment):
			state.environment_changed.disconnect(on_environment)
		if state.battle_progress_changed.is_connected(mark_dirty):
			state.battle_progress_changed.disconnect(mark_dirty)
		if state.flora_changed.is_connected(mark_dirty): state.flora_changed.disconnect(mark_dirty)
	state = next
	last_clock = -1.0
	optical_seconds = 0.0
	state.environment_changed.connect(on_environment)
	state.battle_progress_changed.connect(mark_dirty)
	state.flora_changed.connect(mark_dirty)
	mark_dirty()

func on_environment(cell: Vector2i) -> void:
	if active_bounds().grow(4).has_point(cell):
		mark_dirty()

func mark_dirty() -> void:
	dirty = true

func on_rebuilt() -> void:
	finish_transition()
	selected_regions.clear()
	vegetation_cache.clear()
	source_region_cache.clear()
	anchor_cache.clear()
	junction_cache.clear()
	edge_cache.clear()
	samples.clear()
	sample_order.clear()
	sample_cursor = 0
	clearance_cache.clear()
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
	# Optical readings need neither route searches nor obstacle/scenery admission.
	var sample := {"concentration": world.terrain.concentration_at(cell), "affinity": world.terrain.affinity_at(cell)}
	samples[cell] = sample
	sample_builds += 1
	return sample

func refresh(prepared_anchors: Variant = null) -> void:
	for light in glow_lights:
		light.hide()
	if not tuning.valid():
		finish_transition()
		batch.visible = false
		wisp_batch.visible = false
		particle_batch.visible = false
		heatmap_batch.visible = false
		return
	batch.visible = tuning.current_debug_view == 0
	heatmap_batch.visible = tuning.current_debug_view != 0
	if not tuning.currents_enabled or tuning.current_limit == 0:
		finish_transition()
		batch.visible = false
		wisp_batch.visible = false
		particle_batch.visible = false
		heatmap_batch.visible = false
		return
	if last_terrain != world.terrain:
		on_rebuilt()
	var transition_began := Time.get_ticks_usec()
	var previous_origin := batch_origin
	capture_transition()
	record_stage("transition", transition_began)
	batch_origin = world.terrain.chunk_of(Vector2i((world.camera.position / 32.0).floor())) * 16
	previous_batch.position = Vector3(previous_origin.x - batch_origin.x, 0, previous_origin.y - batch_origin.y)
	previous_wisps.position = previous_batch.position
	last_terrain = world.terrain
	sites = state.vastra_changes_near(batch_origin + Vector2i(8, 8), stream_extent())
	var seen := {}
	for cell in sites:
		seen[cell] = true
	var battle: TacticalBattle = world.host.battles.session if world.host.battles != null else null
	if battle != null:
		for key: String in battle.vastra_overloads:
			var parts := key.split(":")
			var cell := Vector2i(int(parts[0]), int(parts[1]))
			if not seen.has(cell) and active_bounds().has_point(cell):
				sites.append(cell)
				seen[cell] = true
	sites.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.x < b.x if a.x != b.x else a.y < b.y)
	var began := Time.get_ticks_usec()
	living_anchors = collect_living_anchors() if prepared_anchors == null else prepared_anchors
	record_stage("anchors", began)
	if study_mode:
		build_network(battle)
	else:
		build_transfer_network(battle)
	prepare_particle_paths()
	position = Vector3(batch_origin.x - world.camera.position.x / 32.0, 0, batch_origin.y - world.camera.position.y / 32.0)
	var optics_began := Time.get_ticks_usec()
	update_optics()
	update_heatmap()
	record_stage("optics", optics_began)
	dirty = false
	refresh_count += 1
	var sync_began := Time.get_ticks_usec()
	sync_wisps()
	record_stage("uniform_sync", sync_began)

# Seeded world-space junctions are independent of the player's position and local budget.
func junction(key: Vector2i) -> Vector2:
	var base := Vector2(key) * tuning.current_spacing
	var roll := absi(hash("vastra-web:%d:%d:%d" % [world.terrain.world_seed, key.x, key.y]))
	return base + Vector2(float(roll % 997) / 996.0 - 0.5, float((roll / 997) % 991) / 990.0 - 0.5) * tuning.current_spacing * 0.85

func junction_point(key: Vector2i) -> Vector3:
	if network_nodes.has(key):
		return network_nodes[key]
	if junction_cache.has(key):
		return junction_cache[key]
	var at := junction(key)
	var lift := 0.75 + sin(at.x * 0.17 + at.y * 0.11) * 0.25
	var point := Vector3(at.x, world.host.ground_height(at) + tuning.current_hover_height * lift, at.y)
	if junction_cache.size() >= 128:
		junction_cache.erase(junction_cache.keys()[0])
	junction_cache[key] = point
	return point

func edge_points(a: Vector2i, b: Vector2i) -> PackedVector3Array:
	var key := Vector4i(a.x, a.y, b.x, b.y)
	if edge_cache.has(key):
		return edge_cache[key]
	var start := junction_point(a)
	var finish := junction_point(b)
	var length := start.distance_to(finish)
	var kind: String = edge_styles.get(key, "medium")
	var side := Vector3(-(finish - start).z, 0, (finish - start).x).normalized()
	var points := PackedVector3Array()
	for step in range(9):
		var t := float(step) / 8.0
		var point := start if step == 0 else finish if step == 8 else start.lerp(finish, t)
		if step > 0 and step < 8:
			var at := Vector2(point.x, point.z)
			if kind == "small":
				point.y = world.host.ground_height(at) + tuning.current_ground_clearance + sin(t * PI) * 0.02
			elif kind == "large":
				point += side * sin(t * PI) * minf(length * 0.04, 0.8)
				point.y += sin(t * PI) * minf(length * tuning.current_canopy_arc, 6.0)
				point = clear_ground(point, 0.3)
			else:
				var ground_a: float = world.host.ground_height(Vector2(start.x, start.z))
				var ground_b: float = world.host.ground_height(Vector2(finish.x, finish.z))
				point.y = world.host.ground_height(at) + lerpf(start.y - ground_a, finish.y - ground_b, t) + sin(t * PI) * 0.15
		points.append(point)
	if edge_cache.size() >= 256:
		edge_cache.erase(edge_cache.keys()[0])
	edge_cache[key] = points
	return points

# Geographic ownership is independent of 16-cell render chunks. Only admit a
# complete 12-cell region, so asynchronous scenery uploads cannot alter membership.
func region_of(cell: Vector2i) -> Vector2i:
	return Vector2i(WorldTerrain.floor_div(cell.x, REGION_SIZE), WorldTerrain.floor_div(cell.y, REGION_SIZE))

func stream_extent() -> int:
	return 48

func active_bounds() -> Rect2i:
	return Rect2i(batch_origin - Vector2i(48, 48), Vector2i(112, 112))

func collect_living_anchors() -> Array[Vector4]:
	var result: Array[Vector4] = []
	if world.host.get("solid_root") == null:
		return result
	source_assets.clear()
	var complete := {}
	var owners := {}
	var retained := {}
	for chunk in world.host.solid_chunks.values():
		if chunk.get("pick_objects") == null or chunk.get("tile_count") != 256:
			continue
		complete[world.terrain.chunk_of(chunk.cell_origin)] = true
		var cache_key: int = chunk.get_instance_id()
		retained[cache_key] = true
		if not vegetation_cache.has(cache_key):
			vegetation_cache[cache_key] = chunk.living_regions
		for owner: Vector2i in vegetation_cache[cache_key]:
			if not owners.has(owner): owners[owner] = []
			owners[owner].append({"id": cache_key, "records": vegetation_cache[cache_key][owner]})
	for key: int in vegetation_cache.keys():
		if not retained.has(key):
			vegetation_cache.erase(key)
	var regions: Array = []
	for owner: Vector2i in owners:
		var low: Vector2i = world.terrain.chunk_of(owner * REGION_SIZE)
		var high: Vector2i = world.terrain.chunk_of(owner * REGION_SIZE + Vector2i(REGION_SIZE - 1, REGION_SIZE - 1))
		var ready := true
		for y in range(low.y, high.y + 1):
			for x in range(low.x, high.x + 1):
				ready = ready and complete.has(Vector2i(x, y))
		if ready and (Vector2(owner * REGION_SIZE) + Vector2.ONE * REGION_SIZE * 0.5).distance_to(world.camera.position / 32.0) <= stream_extent():
			regions.append(owner)
	regions.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		var da := (Vector2(a * REGION_SIZE) + Vector2.ONE * REGION_SIZE * 0.5).distance_squared_to(world.camera.position / 32.0)
		var db := (Vector2(b * REGION_SIZE) + Vector2.ONE * REGION_SIZE * 0.5).distance_squared_to(world.camera.position / 32.0)
		return da < db if da != db else (a.x < b.x or (a.x == b.x and a.y < b.y)))
	# Retain visible owners instead of replacing a whole grove at nearest-rank ties.
	var chosen: Array[Vector2i] = []
	for owner in selected_regions:
		if regions.has(owner) and chosen.size() < tuning.current_region_limit:
			chosen.append(owner)
	for owner: Vector2i in regions:
		if not chosen.has(owner) and chosen.size() < tuning.current_region_limit:
			chosen.append(owner)
	selected_regions = chosen
	for owner in chosen:
		var signature: Array = []
		for piece: Dictionary in owners[owner]: signature.append(piece.id)
		if not source_region_cache.has(owner) or source_region_cache[owner].signature != signature:
			var records := {}
			for piece: Dictionary in owners[owner]: records.merge(piece.records, true)
			var cells: Array = records.keys()
			var center := Vector2(owner * REGION_SIZE) + Vector2.ONE * REGION_SIZE * 0.5
			cells.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
				var da := Vector2(a).distance_squared_to(center)
				var db := Vector2(b).distance_squared_to(center)
				return da < db if da != db else (a.x < b.x or (a.x == b.x and a.y < b.y)))
			var selected: Array[Dictionary] = []
			var selected_cells := {}
			for cell: Vector2i in cells:
				if records[cell].kind == "tree" and selected.size() < 4:
					selected.append(records[cell])
					selected_cells[cell] = true
			for cell: Vector2i in cells:
				if not selected_cells.has(cell) and selected.size() < 16: selected.append(records[cell])
			if source_region_cache.size() >= 128: source_region_cache.erase(source_region_cache.keys()[0])
			source_region_cache[owner] = {"signature": signature, "assets": selected}
		for asset: Dictionary in source_region_cache[owner].assets:
			var cell: Vector2i = asset.cell
			var tree: bool = asset.kind == "tree"
			if not anchor_cache.has(cell) and anchor_cache.size() >= 128: anchor_cache.erase(anchor_cache.keys()[0])
			var anchor: Vector3 = asset.anchor
			anchor_cache[cell] = Vector4(anchor.x, anchor.y, anchor.z, 0.9 if tree else 0.55)
			source_assets[asset.anchor] = asset
			source_assets[asset.high_anchor] = asset
			result.append(anchor_cache[cell])
	result.sort_custom(func(a: Vector4, b: Vector4) -> bool: return a.x < b.x if a.x != b.x else (a.z < b.z if a.z != b.z else a.y < b.y))
	return result

func collect_sol_voids() -> PackedVector4Array:
	var sources: Array[Vector3] = []
	var origin: Vector2 = world.camera.position / 32.0
	if world.host.get("companion") != null:
		var companion: Node3D = world.host.companion
		if companion.get("sprite") != null and companion.sprite.visible:
			sources.append(Vector3(companion.sprite.global_position.x + origin.x, companion.sprite.global_position.y + 0.35, companion.sprite.global_position.z + origin.y))
	if world.host.get("sightings") != null:
		for member: Dictionary in world.host.sightings.members:
			if member.sprite.visible:
				sources.append(Vector3(member.sprite.global_position.x + origin.x, member.sprite.global_position.y + 0.35, member.sprite.global_position.z + origin.y))
	sources.sort_custom(func(a: Vector3, b: Vector3) -> bool: return Vector2(a.x, a.z).distance_squared_to(world.camera.position / 32.0) < Vector2(b.x, b.z).distance_squared_to(world.camera.position / 32.0))
	var result := PackedVector4Array()
	for point in sources:
		if Vector2(point.x, point.z).distance_to(world.camera.position / 32.0) <= stream_extent() + tuning.current_sol_dissipation_radius:
			result.append(Vector4(point.x - batch_origin.x, point.y, point.z - batch_origin.y, tuning.current_sol_dissipation_radius))
		if result.size() == 16:
			break
	return result

func update_sol_voids() -> void:
	var sources := collect_sol_voids()
	var count := sources.size()
	material.set_shader_parameter("sol_count", count)
	sources.resize(16)
	material.set_shader_parameter("sol_voids", sources)
	heatmap_material.set_shader_parameter("sol_count", count)
	heatmap_material.set_shader_parameter("sol_voids", sources)

func group_living_sources() -> Array[Dictionary]:
	var anchors: Array[Vector4] = living_anchors.duplicate()
	anchors.sort_custom(func(a: Vector4, b: Vector4) -> bool: return a.x < b.x if a.x != b.x else (a.z < b.z if a.z != b.z else a.y < b.y))
	var groups: Array[Dictionary] = []
	var region_indices := {}
	var owners: Array[Vector2i] = []
	for index in range(anchors.size()):
		var owner := region_of(Vector2i(floori(anchors[index].x), floori(anchors[index].z)))
		owners.append(owner)
		if not region_indices.has(owner): region_indices[owner] = []
		region_indices[owner].append(index)
	var visited := {}
	for first in range(anchors.size()):
		if visited.has(first):
			continue
		var members: Array[int] = [first]
		visited[first] = true
		var cursor := 0
		while cursor < members.size():
			var anchor := anchors[members[cursor]]
			cursor += 1
			for other: int in region_indices[owners[first]]:
				var candidate := anchors[other]
				if not visited.has(other) and Vector3(anchor.x, anchor.y, anchor.z).distance_to(Vector3(candidate.x, candidate.y, candidate.z)) <= tuning.current_life_radius:
					visited[other] = true
					members.append(other)
		var center := Vector3.ZERO
		var mass := 0.0
		var score := 0.0
		var focus := Vector3.ZERO
		var best_concentration := -1.0
		var best_low := -1.0
		var sources: Array[Vector4] = []
		var crown := Vector3.INF
		var low := Vector3(INF, INF, INF)
		var high := -low
		var identity := Vector2i(2147483647, 2147483647)
		for index in members:
			var anchor := anchors[index]
			var point := Vector3(anchor.x, anchor.y, anchor.z)
			sources.append(anchor)
			if anchor.w >= 0.8 and source_assets.has(point):
				var high_point: Vector3 = source_assets[point].high_anchor
				if not crown.is_finite() or high_point.y > crown.y: crown = high_point
			var key := Vector2i(floori(anchor.x), floori(anchor.z))
			if key.x < identity.x or (key.x == identity.x and key.y < identity.y):
				identity = key
			center += point * anchor.w
			mass += anchor.w
			var concentration := concentration_at(point)
			score += concentration * anchor.w
			var low_score := concentration + (1000.0 if is_grass_source(point) else 0.0)
			if anchor.w < 0.8 and low_score > best_low:
				best_low = low_score
				focus = point
			elif best_low < 0 and concentration > best_concentration:
				focus = point
			best_concentration = maxf(best_concentration, concentration)
			low = low.min(point)
			high = high.max(point)
		center /= maxf(mass, 0.01)
		center.y += tuning.current_hover_height * 0.7
		var extent := (high - low) * 0.5 + Vector3(tuning.current_spacing * 0.4, tuning.current_hover_height * 0.8, tuning.current_spacing * 0.4)
		groups.append({"id": identity, "center": center, "extent": extent, "score": score / maxf(mass, 0.01), "focus": focus, "sources": sources, "crown": crown, "members": members.size()})
	groups.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var da: float = Vector2(a.center.x, a.center.z).distance_squared_to(world.camera.position / 32.0)
		var db: float = Vector2(b.center.x, b.center.z).distance_squared_to(world.camera.position / 32.0)
		return da < db if da != db else (a.id.x < b.id.x or (a.id.x == b.id.x and a.id.y < b.id.y)))
	return groups

func life_strength(point: Vector3) -> float:
	if living_anchors.is_empty():
		return tuning.current_empty_visibility
	var strength := field_strength(point, living_groups)
	for edge: Dictionary in network_edges:
		if edge.bridge:
			strength = maxf(strength, tuning.current_connection_visibility * corridor_strength(point, edge.points))
	return strength

func corridor_strength(point: Vector3, points: PackedVector3Array) -> float:
	var nearest := INF
	for index in range(points.size() - 1):
		var closest := Geometry3D.get_closest_point_to_segment(point, points[index], points[index + 1])
		var delta := point - closest
		delta.y *= 0.35
		nearest = minf(nearest, delta.length_squared())
	return exp(-nearest / maxf(0.1, tuning.current_width * tuning.current_width * 0.4))

func field_strength(point: Vector3, groups: Array) -> float:
	var strength := 0.0
	for group: Dictionary in groups:
		if int(group.get("members", 1)) == 0:
			continue
		var difference := Vector2((point.x - group.center.x) / group.extent.x, (point.z - group.center.z) / group.extent.z)
		strength = maxf(strength, exp(-difference.length_squared() * 0.75))
	return lerpf(tuning.current_empty_visibility, 1.0, clampf(strength, 0.0, 1.0))

func connect_pair(pairs: Array[Dictionary], seen: Dictionary, a: Vector2i, b: Vector2i, bridge: bool = false) -> void:
	if a == b:
		return
	if a.x > b.x or (a.x == b.x and a.y > b.y):
		var swap := a
		a = b
		b = swap
	var key := Vector4i(a.x, a.y, b.x, b.y)
	if seen.has(key):
		return
	seen[key] = true
	pairs.append({"a": a, "b": b, "bridge": bridge})

func concentration_at(point: Vector3) -> float:
	var cell := Vector2i(floori(point.x), floori(point.z))
	return float(state.environment_view(cell, {"concentration": sample_for(cell).concentration, "affinity": sample_for(cell).affinity, "overload": 0}).concentration)

func update_optics() -> void:
	material.set_shader_parameter("distance_taper", tuning.current_distance_taper)
	material.set_shader_parameter("flow_spread", tuning.current_flow_spread)
	material.set_shader_parameter("spread_distance", tuning.current_ground_reach)
	material.set_shader_parameter("strand_shake", tuning.current_strand_shake)
	material.set_shader_parameter("haze_strength", tuning.current_haze_strength)
	material.set_shader_parameter("distortion", tuning.current_distortion)
	material.set_shader_parameter("aberration", tuning.current_aberration)
	material.set_shader_parameter("fine_detail", tuning.current_fine_detail)
	material.set_shader_parameter("glint_strength", tuning.current_glints)
	material.set_shader_parameter("pulse_strength", tuning.current_pulse_strength)
	material.set_shader_parameter("pulse_seconds", tuning.current_pulse_seconds)
	material.set_shader_parameter("wind_velocity", tuning.current_wind_velocity)
	material.set_shader_parameter("attraction", tuning.current_attraction)
	update_sol_voids()

func record_stage(label: String, began: int) -> void:
	refresh_stage_peaks[label] = maxf(float(refresh_stage_peaks.get(label, 0.0)), float(Time.get_ticks_usec() - began) / 1000.0)

func build_network(battle: TacticalBattle) -> void:
	var began := Time.get_ticks_usec()
	var signature := [tuning.current_height_range_multiplier, tuning.current_range_height, tuning.current_ground_reach, tuning.current_ground_clearance, tuning.current_canopy_links, tuning.current_canopy_arc, tuning.current_spacing, tuning.current_hover_height, tuning.current_wind_velocity]
	if signature != geometry_signature:
		junction_cache.clear()
		edge_cache.clear()
		geometry_signature = signature
	var previous_nodes := network_nodes.duplicate()
	var previous_styles := edge_styles.duplicate()
	network_nodes.clear()
	network_edges.clear()
	node_assets.clear()
	edge_styles.clear()
	network_vertices.clear()
	living_groups = group_living_sources()
	record_stage("groups", began)
	began = Time.get_ticks_usec()
	var groups: Array[Dictionary] = living_groups.duplicate(true)
	if groups.is_empty():
		var key := region_of(batch_origin + Vector2i(8, 8))
		var at := Vector2(key * REGION_SIZE) + Vector2.ONE * REGION_SIZE * 0.5
		groups.append({"id": key * REGION_SIZE, "center": Vector3(at.x, world.host.ground_height(at) + tuning.current_hover_height, at.y), "extent": Vector3(3, 1, 3), "score": concentration_at(Vector3(at.x, 0, at.y)), "members": 0})
	var group_limit := mini(tuning.current_region_limit, maxi(1, tuning.current_limit / 3))
	if groups.size() > group_limit:
		groups.resize(group_limit)
	var canopy_reserve := mini(tuning.current_canopy_links * 2, maxi(0, tuning.current_limit - group_limit * 3))
	var count := maxi(1, mini(9, (tuning.current_limit - canopy_reserve) / group_limit))
	var roots: Array[Vector2i] = []
	var region_members := {}
	var node_regions := {}
	var node_parents := {}
	var pairs: Array[Dictionary] = []
	var seen := {}
	var peak_score := -1.0
	for group in groups:
		var keys: Array[Vector2i] = []
		var candidates: Array[Vector3] = []
		var root_point: Vector3 = group.get("focus", group.center)
		for anchor: Vector4 in group.get("sources", []):
			var point := Vector3(anchor.x, anchor.y, anchor.z)
			if anchor.w < 0.8 and point != root_point and point.distance_to(root_point) <= tuning.current_ground_reach:
				candidates.append(point)
		candidates.sort_custom(func(a: Vector3, b: Vector3) -> bool: return a.distance_squared_to(root_point) < b.distance_squared_to(root_point))
		candidates.push_front(root_point)
		for index in range(mini(count, candidates.size())):
			var key: Vector2i = group.id * 16 + Vector2i(index, 0)
			var point: Vector3 = candidates[index]
			node_assets[key] = source_assets.get(point, {})
			network_nodes[key] = point
			node_regions[key] = group
			junction_cache[key] = point
			keys.append(key)
			if index > 0:
				var parent: Vector2i = keys[0]
				node_parents[key] = parent
				connect_pair(pairs, seen, parent, key)
		roots.append(keys[0])
		region_members[keys[0]] = keys
		if float(group.score) > peak_score:
			peak_score = group.score
			flow_focus = group.center
	# A bounded spanning tree provides finer connections between whole living regions.
	if not roots.is_empty():
		var connected := {roots[0]: true}
		while connected.size() < roots.size():
			var best := INF
			var from := roots[0]
			var to := roots[0]
			for a: Vector2i in connected:
				for b in roots:
					if connected.has(b):
						continue
					var distance := junction_point(a).distance_squared_to(junction_point(b))
					if distance < best:
						best = distance
						from = a
						to = b
			connect_pair(pairs, seen, from, to, true)
			connected[to] = true
	# Extra inter-grove links form a landscape web, without wrapping individual plants.
	for root_key in roots:
		var neighbors := roots.duplicate()
		neighbors.erase(root_key)
		neighbors.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return junction_point(root_key).distance_squared_to(junction_point(a)) < junction_point(root_key).distance_squared_to(junction_point(b)))
		for index in range(mini(tuning.current_web_links, neighbors.size())):
			connect_pair(pairs, seen, root_key, neighbors[index], true)
	# Join through facing outer branches, spreading the meeting points across a grove.
	for pair in pairs:
		if not pair.bridge:
			continue
		var best := INF
		var endpoint_a: Vector2i = pair.a
		var endpoint_b: Vector2i = pair.b
		var members_a: Array = region_members[pair.a]
		var members_b: Array = region_members[pair.b]
		for a: Vector2i in members_a.slice(1 if members_a.size() > 1 else 0):
			for b: Vector2i in members_b.slice(1 if members_b.size() > 1 else 0):
				var distance := junction_point(a).distance_squared_to(junction_point(b))
				if distance < best:
					best = distance
					endpoint_a = a
					endpoint_b = b
		pair.a = endpoint_a
		pair.b = endpoint_b
	# Reserve a small global canopy budget, independent of the common ground web.
	var crown_pairs: Array[Dictionary] = []
	for i in range(groups.size()):
		for j in range(i + 1, groups.size()):
			var ca: Vector3 = groups[i].get("crown", Vector3.INF)
			var cb: Vector3 = groups[j].get("crown", Vector3.INF)
			if not ca.is_finite() or not cb.is_finite(): continue
			var height := maxf(ca.y - world.host.ground_height(Vector2(ca.x, ca.z)), cb.y - world.host.ground_height(Vector2(cb.x, cb.z)))
			var distance := ca.distance_to(cb)
			if distance >= tuning.current_ground_reach * 2.5 and distance <= reach_at_height(height) * 0.9:
				crown_pairs.append({"a": groups[i], "b": groups[j], "distance": ca.distance_squared_to(cb)})
	# Spend the rare large tier on farther eligible crowns, rather than consuming
	# its quota on short hops or on targets beyond the height-derived range.
	crown_pairs.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.distance > b.distance)
	var admitted_canopies := 0
	for candidate in crown_pairs:
		if admitted_canopies >= tuning.current_canopy_links: break
		var a: Vector2i = candidate.a.id * 16 + Vector2i(15, 0)
		var b: Vector2i = candidate.b.id * 16 + Vector2i(15, 0)
		var needed := int(not network_nodes.has(a)) + int(not network_nodes.has(b))
		if network_nodes.size() + needed > tuning.current_limit: continue
		for group: Dictionary in [candidate.a, candidate.b]:
			var key: Vector2i = group.id * 16 + Vector2i(15, 0)
			if network_nodes.has(key): continue
			var point: Vector3 = group.crown
			network_nodes[key] = point
			junction_cache[key] = point
			node_regions[key] = group
			node_assets[key] = source_assets.get(point, {})
			var parent: Vector2i = group.id * 16
			node_parents[key] = parent
			connect_pair(pairs, seen, parent, key)
		connect_pair(pairs, seen, a, b, true)
		pairs[-1]["canopy"] = true
		admitted_canopies += 1
	# Reach grows with height above the local ground, never with render budget.
	# Disconnected short flows are valid; do not invent long ground bridges merely
	# to force the whole visible field into a single graph.
	var ranged_pairs: Array[Dictionary] = []
	var active_nodes := {}
	for pair in pairs:
		var start: Vector3 = network_nodes[pair.a]
		var finish: Vector3 = network_nodes[pair.b]
		var height := maxf(start.y - world.host.ground_height(Vector2(start.x, start.z)), finish.y - world.host.ground_height(Vector2(finish.x, finish.z)))
		var reach := reach_at_height(height)
		if start.distance_to(finish) > reach * 0.9: continue
		var path_key := Vector4i(pair.a.x, pair.a.y, pair.b.x, pair.b.y)
		var kind := kind_for_pair(pair)
		if previous_nodes.get(pair.a) != start or previous_nodes.get(pair.b) != finish or previous_styles.get(path_key) != kind:
			edge_cache.erase(path_key)
		edge_styles[path_key] = kind
		var points := edge_points(pair.a, pair.b)
		var path_length := 0.0
		for i in range(1, points.size()): path_length += points[i].distance_to(points[i - 1])
		if path_length > reach: continue
		pair["range_limit"] = reach
		ranged_pairs.append(pair)
		active_nodes[pair.a] = true
		active_nodes[pair.b] = true
	pairs = ranged_pairs
	for key: Vector2i in network_nodes.keys():
		if not active_nodes.has(key):
			network_nodes.erase(key)
			node_assets.erase(key)
	for key: Vector4i in edge_cache.keys():
		var a := Vector2i(key.x, key.y)
		var b := Vector2i(key.z, key.w)
		if previous_nodes.get(a) != network_nodes.get(a) or previous_nodes.get(b) != network_nodes.get(b):
			edge_cache.erase(key)
	while junction_cache.size() > 128:
		var discarded := false
		for key: Vector2i in junction_cache.keys():
			if not network_nodes.has(key):
				junction_cache.erase(key)
				discarded = true
				break
		if not discarded:
			break
	var adjacency := {}
	for key: Vector2i in network_nodes:
		adjacency[key] = []
	for pair in pairs:
		adjacency[pair.a].append(pair.b)
		adjacency[pair.b].append(pair.a)
	# Each region owns phase. Loading neighbors never reroutes an existing signal.
	flow_distances.clear()
	for group in groups:
		var phase := -float(group.score) * 0.25 + float(absi(hash(group.id)) % 997) / 997.0 * 0.2
		for index in range(count):
			var key: Vector2i = group.id * 16 + Vector2i(index, 0)
			if network_nodes.has(key):
				# Metric phase along each tributary gives signals a clear inward direction.
				if node_parents.has(key):
					var parent: Vector2i = node_parents[key]
					flow_distances[key] = float(flow_distances.get(parent, phase)) + junction_point(key).distance_to(junction_point(parent))
				else:
					flow_distances[key] = phase
	for key: Vector2i in network_nodes:
		if not flow_distances.has(key):
			var parent: Vector2i = node_parents[key]
			flow_distances[key] = float(flow_distances.get(parent, 0.0)) + network_nodes[key].distance_to(junction_point(parent))
	record_stage("paths", began)
	began = Time.get_ticks_usec()
	var arrays := {"colors": [], "uvs": [], "readings": [], "indices": [], "tile_cache": {}}
	secondary_links = 0
	for pair in pairs:
		var key: Vector2i = pair.a
		var next: Vector2i = pair.b
		var kind := kind_for_pair(pair)
		var edge_key := Vector4i(key.x, key.y, next.x, next.y)
		edge_styles[edge_key] = kind
		var points := edge_points(key, next)
		var profile := strand_profile(kind)
		arrays["strand_profile"] = profile
		arrays["clearance"] = tuning.current_ground_clearance if kind == "small" else 0.12
		arrays["field_groups"] = [node_regions[key], node_regions[next]]
		arrays["connection"] = points if pair.bridge else PackedVector3Array()
		arrays["layer_gain"] = 0.75
		var start_phase := -float(flow_distances[key])
		var end_phase := -float(flow_distances[next])
		if pair.bridge:
			# Similar grove scores used to compress a long bridge into almost zero
			# phase distance: it flickered as a whole instead of carrying a signal.
			var wind := Vector3(tuning.current_wind_velocity.x, 0, tuning.current_wind_velocity.z).normalized()
			if wind.length_squared() < 0.01:
				wind = Vector3.RIGHT
			start_phase = points[0].dot(wind)
			var direction := 1.0 if (points[-1] - points[0]).dot(wind) >= 0.0 else -1.0
			end_phase = start_phase + points[0].distance_to(points[-1]) * direction
		network_edges.append({"a": key, "b": next, "points": points, "flow_direction": signf(end_phase - start_phase), "start_phase": start_phase, "end_phase": end_phase, "profile": profile, "range_limit": pair.range_limit, "kind": kind, "source_asset": node_assets.get(key if end_phase > start_phase else next, {}), "destination_asset": node_assets.get(next if end_phase > start_phase else key, {}), "charge_role": "future_generator_destination", "bridge": pair.bridge})
		append_surface(points, tuning.current_width * (0.04 if kind == "small" else 0.26 if kind == "large" else 0.11), start_phase, end_phase, arrays, battle)
		if kind == "large":
			var fine := PackedVector3Array()
			var delta := points[7] - points[1]
			var side := Vector3(-delta.z, 0, delta.x).normalized()
			for i in range(1, 8):
				var t := float(i - 1) / 6.0
				fine.append(points[i] + (side + Vector3.UP * 0.25) * (4.0 * t * (1.0 - t)) * tuning.current_spacing * 0.06)
			arrays["layer_gain"] = 0.12
			append_surface(fine, tuning.current_width * 0.08, lerpf(start_phase, end_phase, 0.125), lerpf(start_phase, end_phase, 0.875), arrays, battle)
			secondary_links += 1
	var wisps := mesh_from_arrays(arrays)
	record_stage("wisps", began)
	began = Time.get_ticks_usec()
	# Broad density uses open tapered layers; there is no enclosing shell.
	network_vertices.clear()
	var density := {"colors": [], "uvs": [], "readings": [], "indices": [], "tile_cache": arrays.tile_cache}
	for group in groups:
		append_region(group, density, battle)
	for pair in pairs:
		if pair.bridge:
			density["layer_gain"] = 1.0
			density["field_groups"] = [node_regions[pair.a], node_regions[pair.b]]
			density["connection"] = edge_points(pair.a, pair.b)
			var edge: Dictionary = network_edges[pairs.find(pair)]
			density["strand_profile"] = edge.profile
			density["clearance"] = tuning.current_ground_clearance
			append_surface(edge.points, tuning.current_width * (0.3 if edge.kind == "large" else 0.18), edge.start_phase, edge.end_phase, density, battle)
	batch.mesh = mesh_from_arrays(density)
	wisp_batch.mesh = wisps
	batch.custom_aabb = batch.mesh.get_aabb().grow(0.02)
	wisp_batch.custom_aabb = wisps.get_aabb().grow(0.02)
	record_stage("density", began)

func mesh_from_arrays(arrays: Dictionary) -> ArrayMesh:
	var mesh := ArrayMesh.new()
	if not network_vertices.is_empty():
		var surface_arrays := []
		surface_arrays.resize(Mesh.ARRAY_MAX)
		surface_arrays[Mesh.ARRAY_VERTEX] = network_vertices
		surface_arrays[Mesh.ARRAY_COLOR] = PackedColorArray(arrays.colors)
		surface_arrays[Mesh.ARRAY_TEX_UV] = PackedVector2Array(arrays.uvs)
		surface_arrays[Mesh.ARRAY_TEX_UV2] = PackedVector2Array(arrays.readings)
		surface_arrays[Mesh.ARRAY_INDEX] = PackedInt32Array(arrays.indices)
		surface_arrays[Mesh.ARRAY_CUSTOM0] = PackedFloat32Array(arrays.profiles)
		surface_arrays[Mesh.ARRAY_CUSTOM1] = PackedFloat32Array(arrays.flights)
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_arrays, [], {}, (Mesh.ARRAY_CUSTOM_RGBA_FLOAT << Mesh.ARRAY_FORMAT_CUSTOM0_SHIFT) | (Mesh.ARRAY_CUSTOM_RGBA_FLOAT << Mesh.ARRAY_FORMAT_CUSTOM1_SHIFT))
	return mesh

func append_region(group: Dictionary, arrays: Dictionary, battle: TacticalBattle) -> void:
	var direction := tuning.current_wind_velocity.normalized()
	if direction.length_squared() < 0.01:
		direction = Vector3(0.9, 0.15, 0.35).normalized()
	var across := Vector3(-direction.z, 0, direction.x).normalized()
	var phase := float(absi(hash(group.id)) % 4096) / 32.0
	var reach := Vector3(group.extent).length()
	arrays["field_groups"] = [group]
	# Unequal veils overlap in depth, leaving dark gaps rather than an enclosing shell.
	for layer in range(2):
		var points := PackedVector3Array()
		for step in range(9):
			var t := float(step) / 8.0
			var along := t * 2.0 - 1.0
			var point: Vector3 = group.center + direction * along * reach
			var bend := sin(phase * 0.7 + float(layer) * 2.1) * 0.4
			point += across * sin(t * PI) * group.extent.x * bend
			point.y += (float(layer) - 1.0) * group.extent.y * 0.65 + sin(t * PI) * group.extent.y * bend
			points.append(point)
		var width := maxf(tuning.current_width, minf(group.extent.x, group.extent.z) * 1.3)
		arrays["layer_gain"] = 0.4
		append_surface(points, width * (0.7 + float(layer) * 0.15), phase + float(layer) * 0.37, phase + reach * 2.0 + float(layer) * 0.37, arrays, battle)

# Cache only mesh-build samples; optical animation never queries terrain per frame.
func clear_ground(point: Vector3, clearance: float = 0.22) -> Vector3:
	var at := Vector2(point.x, point.z)
	if not clearance_cache.has(at):
		if clearance_cache.size() >= 4096:
			clearance_cache.erase(clearance_cache.keys()[0])
		clearance_cache[at] = world.host.ground_height(at)
	point.y = maxf(point.y, float(clearance_cache[at]) + clearance)
	return point

func append_surface(points: PackedVector3Array, width: float, start_phase: float, end_phase: float, arrays: Dictionary, battle: TacticalBattle) -> void:
	var first := network_vertices.size()
	if not arrays.has("profiles"): arrays["profiles"] = []
	if not arrays.has("flights"): arrays["flights"] = []
	var flight: Vector4 = arrays.get("flight_profile", Vector4.ZERO)
	var profile: Vector4 = arrays.get("strand_profile", strand_profile("medium"))
	var distances := PackedFloat32Array([0.0])
	for i in range(1, points.size()):
		distances.append(distances[-1] + points[i].distance_to(points[i - 1]))
	for i in range(points.size()):
		var point := points[i]
		var t := distances[i] / maxf(distances[-1], 0.001)
		var tangent := (points[mini(i + 1, points.size() - 1)] - points[maxi(0, i - 1)]).normalized()
		var side := Vector3(-tangent.z, 0, tangent.x).normalized()
		# Tilt the membranes into space rather than laying flat strips over the floor.
		side = side.rotated(tangent, 0.65 + sin(points[0].x * 0.37 + points[0].z * 0.21) * 0.8)
		for bank in range(SURFACE_BANKS):
			var across := float(bank) / float(SURFACE_BANKS - 1)
			var taper := 0.12 + 0.88 * pow(sin(t * PI), 0.7)
			var traveled := distances[i]
			var spread := 1.0 + tuning.current_flow_spread * minf(traveled / tuning.current_ground_reach, 4.0) if flight.w > 0.5 else 1.0
			var vertex := point + side * (across * 2.0 - 1.0) * width * taper * spread * 0.5
			vertex = clear_ground(vertex, float(arrays.get("clearance", 0.22)))
			var cell := Vector2i(floori(vertex.x), floori(vertex.z))
			if not arrays.tile_cache.has(cell):
				arrays.tile_cache[cell] = state.environment_view(cell, {"concentration": sample_for(cell).concentration, "affinity": sample_for(cell).affinity, "overload": 0})
			var data: Dictionary = arrays.tile_cache[cell]
			var overload := int(battle.tile_overloads.get(cell, data.overload)) if battle != null else int(data.overload)
			var color: Color = world.host.sightings.visual_settings.color_for(str(data.affinity)) if data.has("affinity") else Color.WHITE
			color = color.srgb_to_linear()
			var support := field_strength(vertex, arrays.get("field_groups", living_groups))
			var connection: PackedVector3Array = arrays.get("connection", PackedVector3Array())
			if not connection.is_empty():
				support = maxf(support, tuning.current_connection_visibility * corridor_strength(vertex, connection))
			var ends := lerpf(0.45, 1.0, smoothstep(0.0, 0.18, t) * smoothstep(0.0, 0.18, 1.0 - t))
			color.a = tuning.current_opacity * (0.4 + float(data.concentration) / 100.0 + float(absi(overload)) / 100.0) * support * ends * float(arrays.get("layer_gain", 1.0))
			color.a /= sqrt(spread)
			network_vertices.append(vertex - Vector3(batch_origin.x, 0, batch_origin.y))
			arrays.profiles.append_array([profile.x, profile.y, profile.z, profile.w])
			arrays.flights.append_array([flight.x, flight.y, flight.z, flight.w])
			arrays.colors.append(color)
			arrays.uvs.append(Vector2(lerpf(start_phase, end_phase, t), across))
			arrays.readings.append(Vector2(float(data.concentration) / 100.0, float(maxi(0, overload)) / 100.0))
			if i < points.size() - 1 and bank < SURFACE_BANKS - 1:
				var v := first + i * SURFACE_BANKS + bank
				arrays.indices.append_array([v, v + 1, v + SURFACE_BANKS, v + 1, v + SURFACE_BANKS + 1, v + SURFACE_BANKS])

func update_heatmap() -> void:
	heatmap_batch.visible = tuning.current_debug_view != 0
	batch.visible = tuning.current_debug_view == 0
	if not heatmap_batch.visible:
		return
	var vertices := PackedVector3Array()
	var colors := PackedColorArray()
	var readings := PackedVector2Array()
	var indices := PackedInt32Array()
	var radius := stream_extent()
	var step := maxi(1, ceili(float(radius * 2) / 20.0))
	var segments := ceili(float(radius * 2) / float(step))
	for y in range(segments + 1):
		for x in range(segments + 1):
			var at := Vector2(batch_origin) + Vector2(-radius + x * step, -radius + y * step)
			var cell := Vector2i(at.floor())
			var sample := sample_for(cell)
			var data := state.environment_view(cell, {"concentration": sample.concentration, "overload": 0})
			var point := Vector3(at.x, world.host.ground_height(at) + 0.06, at.y)
			vertices.append(point - Vector3(batch_origin.x, 0, batch_origin.y))
			colors.append(Color(1, 1, 1, life_strength(point)))
			readings.append(Vector2(float(data.concentration) / 100.0, 0))
			if x < segments and y < segments:
				var v := y * (segments + 1) + x
				indices.append_array(PackedInt32Array([v, v + 1, v + segments + 1, v + 1, v + segments + 2, v + segments + 1]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_TEX_UV2] = readings
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	heatmap_batch.mesh = mesh
	heatmap_material.set_shader_parameter("density_mode", tuning.current_debug_view)

func _process(delta: float) -> void:
	for light in glow_lights:
		light.hide()
	if world == null:
		return
	if not tuning.valid():
		finish_transition()
		batch.visible = false
		wisp_batch.visible = false
		particle_batch.visible = false
		heatmap_batch.visible = false
		return
	batch.visible = tuning.current_debug_view == 0
	heatmap_batch.visible = tuning.current_debug_view != 0
	if not tuning.currents_enabled or tuning.current_limit == 0:
		finish_transition()
		batch.visible = false
		wisp_batch.visible = false
		particle_batch.visible = false
		heatmap_batch.visible = false
		return
	var battle: TacticalBattle = world.host.battles.session if world.host.battles != null else null
	if battle != last_battle or (battle != null and battle.action_serial != last_action):
		mark_dirty()
		last_battle = battle
		last_action = battle.action_serial if battle != null else -1
	if not study_mode and dirty: refresh()
	refresh_seconds += delta
	if refresh_seconds >= 0.5:
		# Rendering follows living sources; screen-space actor counts never change ecology.
		var scan_began := Time.get_ticks_usec()
		var anchors := collect_living_anchors()
		record_stage("source_scan", scan_began)
		var living_signature: Array = []
		for anchor in anchors:
			living_signature.append(Vector4(snappedf(anchor.x, 0.25), snappedf(anchor.y, 0.25), snappedf(anchor.z, 0.25), anchor.w))
		if living_signature != last_living_signature:
			last_living_signature = living_signature
			mark_dirty()
		# Resource edits may be made in place without emitting changed.
		var signature := [tuning.current_height_range_multiplier, tuning.current_range_height, tuning.current_ground_reach, tuning.current_ground_clearance, tuning.current_canopy_links, tuning.current_canopy_arc, tuning.current_strand_shake, tuning.current_web_links, tuning.current_connection_visibility, tuning.current_haze_strength, tuning.current_debug_view, tuning.current_region_limit, tuning.current_limit, tuning.currents_enabled, tuning.current_opacity, tuning.current_distortion, tuning.current_spacing, tuning.current_width, tuning.current_hover_height, tuning.current_wind_velocity, tuning.current_attraction, tuning.current_life_radius, tuning.current_empty_visibility, tuning.current_pulse_strength, tuning.current_pulse_seconds, tuning.current_fine_detail, tuning.current_aberration, tuning.current_glints, world.host.sightings.visual_settings.palette.duplicate()]
		signature.append(tuning.current_path_variation)
		signature.append(tuning.current_flow_spread)
		signature.append(tuning.current_distance_taper)
		if signature != last_settings:
			last_settings = signature
			mark_dirty()
		refresh_seconds = 0.0
		if dirty:
			refresh(anchors)
	# Floating-origin movement only translates retained paths. Rebuild for source
	# changes, or after a full stream extent, not every 16-cell render boundary.
	if last_terrain != world.terrain or Vector2(batch_origin).distance_to(world.camera.position / 32.0) > stream_extent():
		refresh()
	position = Vector3(batch_origin.x - world.camera.position.x / 32.0, 0, batch_origin.y - world.camera.position.y / 32.0)
	var seconds: float = state.activity_seconds()
	# The active expedition clock already advances during combat. Adding the
	# battle clock caused a phase jump on entry and a freeze after leaving.
	update_sol_voids()
	if last_clock >= 0.0 and seconds >= last_clock:
		optical_seconds += (seconds - last_clock) * tuning.current_flow_speed
	elif last_clock < 0.0:
		optical_seconds = seconds * tuning.current_flow_speed
	last_clock = seconds
	material.set_shader_parameter("clock_seconds", optical_seconds)
	material.set_shader_parameter("active_seconds", seconds)
	if world.host.get("sun") != null:
		material.set_shader_parameter("sun_direction", world.host.sun.global_basis.z)
		material.set_shader_parameter("sun_color", world.host.sun.light_color)
		material.set_shader_parameter("sun_strength", world.host.sun.light_energy)
	advance_transition(delta)
	sync_wisps(false)

# One bounded old pair bridges source admission/removal without abrupt mesh swaps.
func capture_transition() -> void:
	if batch.mesh == null or batch.mesh.get_surface_count() == 0:
		return
	previous_batch.mesh = batch.mesh
	previous_batch.material_override = material.duplicate()
	previous_wisps.mesh = wisp_batch.mesh
	previous_wisps.material_override = wisp_material.duplicate()
	transition_progress = 0.0
	material.set_shader_parameter("layer_visibility", 0.0)
	wisp_material.set_shader_parameter("layer_visibility", 0.0)

func finish_transition() -> void:
	transition_progress = 1.0
	previous_batch.hide()
	previous_wisps.hide()
	previous_batch.mesh = null
	previous_wisps.mesh = null
	material.set_shader_parameter("layer_visibility", 1.0)
	wisp_material.set_shader_parameter("layer_visibility", 1.0)

func advance_transition(delta: float) -> void:
	if transition_progress >= 1.0:
		return
	transition_progress = minf(1.0, transition_progress + delta / 0.45)
	if transition_progress >= 1.0:
		finish_transition()
		return
	var weight := smoothstep(0.0, 1.0, transition_progress)
	material.set_shader_parameter("layer_visibility", weight)
	wisp_material.set_shader_parameter("layer_visibility", weight)
	for layer in [previous_batch, previous_wisps]:
		layer.visible = batch.visible and tuning.currents_enabled and tuning.current_limit > 0
		var previous: ShaderMaterial = layer.material_override
		previous.set_shader_parameter("layer_visibility", 1.0 - weight)
		for name in ["clock_seconds", "active_seconds", "sol_count", "sol_voids", "sun_direction", "sun_color", "sun_strength"]:
			var value: Variant = material.get_shader_parameter(name)
			if value != null:
				previous.set_shader_parameter(name, value)

func sync_wisps(full: bool = true) -> void:
	material.set_shader_parameter("emission_energy", tuning.current_emission_energy)
	wisp_material.set_shader_parameter("emission_energy", tuning.current_emission_energy)
	particle_material.set_shader_parameter("emission_energy", tuning.current_emission_energy)
	wisp_batch.visible = batch.visible and tuning.currents_enabled and tuning.current_limit > 0
	var names: Array = ["clock_seconds", "active_seconds", "sun_direction", "sun_color", "sun_strength", "sol_count", "sol_voids"]
	if full:
		names.clear()
		for parameter: Dictionary in material.shader.get_shader_uniform_list():
			if parameter.name != "wisp_layer":
				names.append(parameter.name)
	for name: String in names:
		var value: Variant = material.get_shader_parameter(name)
		if value != null:
			wisp_material.set_shader_parameter(name, value)
	update_particles()
	update_glow_lights()

# Bounded real lights illuminate scenery; HDR emission supplies the visible glow.
# Read the same analytic mote positions, so pause, transfer arrival and rebasing
# cannot leave a light traveling independently of its visible current.
func update_glow_lights() -> void:
	for light in glow_lights:
		light.hide()
	if not particle_batch.visible or not batch.visible or tuning.current_debug_view != 0 or tuning.current_light_energy <= 0.0:
		return
	var visibility_value: Variant = material.get_shader_parameter("layer_visibility")
	var visibility := float(visibility_value) if visibility_value != null else 1.0
	var void_value: Variant = material.get_shader_parameter("sol_voids")
	var void_count_value: Variant = material.get_shader_parameter("sol_count")
	var void_count := int(void_count_value) if void_count_value != null else 0
	var count := 0
	for index in range(particle_batch.multimesh.visible_instance_count):
		if count >= tuning.current_light_limit:
			break
		var point := particle_batch.multimesh.get_instance_transform(index).origin
		var color := particle_batch.multimesh.get_instance_color(index)
		var strength := color.a * visibility
		for void_index in range(void_count):
			var clearing: Vector4 = void_value[void_index]
			var difference := point - Vector3(clearing.x, clearing.y, clearing.z)
			difference.y *= 0.5
			strength = minf(strength, color.a * visibility * smoothstep(clearing.w * 0.25, clearing.w, difference.length()))
		if strength <= 0.005:
			continue
		var overlapping := false
		for previous in range(count):
			if glow_lights[previous].position.distance_squared_to(point) < pow(tuning.current_light_range * 0.6, 2):
				overlapping = true
				break
		if overlapping:
			continue
		var light := glow_lights[count]
		light.position = point
		# Mote colors are already linear; Light3D's authored color is sRGB.
		light.light_color = Color(color.r, color.g, color.b).linear_to_srgb()
		light.light_energy = tuning.current_light_energy * strength
		light.omni_range = tuning.current_light_range
		light.show()
		count += 1

# Analytic motes follow the same metric phase as the bright heads. No per-frame
# terrain sampling, physics bodies, emitter nodes, or growing particle history.
func prepare_particle_paths() -> void:
	particle_paths.clear()
	last_particle_clock = -INF
	for edge: Dictionary in network_edges:
		var point: Vector3 = edge.points[4]
		var cell := Vector2i(floori(point.x), floori(point.z))
		var reading := state.environment_view(cell, sample_for(cell))
		var color: Color = world.host.sightings.visual_settings.color_for(str(reading.affinity)).srgb_to_linear()
		var distances := PackedFloat32Array([0.0])
		for i in range(1, edge.points.size()):
			distances.append(distances[-1] + edge.points[i].distance_to(edge.points[i - 1]))
		particle_paths.append({"edge": edge, "distances": distances, "color": color, "support": life_strength(point)})
	particle_batch.custom_aabb = wisp_batch.custom_aabb.grow(0.4)

func update_particles() -> void:
	if particle_batch.multimesh == null:
		return
	particle_batch.visible = wisp_batch.visible and tuning.current_particle_limit > 0
	if not particle_batch.visible:
		particle_batch.multimesh.visible_instance_count = 0
		last_particle_clock = -INF
		return
	for name in ["sol_count", "sol_voids", "layer_visibility"]:
		var value: Variant = material.get_shader_parameter(name)
		if value != null: particle_material.set_shader_parameter(name, value)
	var clock_value: Variant = material.get_shader_parameter("clock_seconds")
	var clock: float = float(clock_value) if clock_value != null else 0.0
	var active_value: Variant = material.get_shader_parameter("active_seconds")
	var active_seconds: float = float(active_value) if active_value != null else state.activity_seconds()
	var settings: Array = [active_seconds if not study_mode else 0.0, tuning.current_particle_limit, tuning.current_particle_size, tuning.current_opacity, tuning.current_strand_shake, tuning.current_wind_velocity, tuning.current_attraction]
	if clock == last_particle_clock and settings == last_particle_settings:
		return
	last_particle_clock = clock
	last_particle_settings = settings
	var transport := clock * (0.35 + tuning.current_wind_velocity.length() * 0.25 + tuning.current_attraction * 0.4)
	var count := 0
	var origin := Vector3(batch_origin.x, 0, batch_origin.y)
	for path in particle_paths:
		var edge: Dictionary = path.edge
		var span: float = edge.end_phase - edge.start_phase
		if absf(span) < 0.001: continue
		for mote in range(4):
			if count >= tuning.current_particle_limit: break
			var phase: float
			if edge.has("flight"):
				var flight: Dictionary = edge.flight
				var elapsed: float = active_seconds - float(flight.sent) * ExpeditionContract.ACTIVITY_INTERVAL
				var duration: float = float(flight.arrival - flight.sent) * ExpeditionContract.ACTIVITY_INTERVAL
				elapsed = active_seconds - float(flight.get("visual_sent", flight.sent)) * ExpeditionContract.ACTIVITY_INTERVAL
				if flight.get("pending", false): elapsed = minf(elapsed, duration)
				phase = elapsed / duration * span - float(mote) * float(edge.profile.y) * 0.2
			else:
				phase = minf(edge.start_phase, edge.end_phase) + fposmod(transport - 0.18 - float(mote) * float(edge.profile.y) * 0.2 - minf(edge.start_phase, edge.end_phase), float(edge.profile.x))
			if phase < minf(edge.start_phase, edge.end_phase) or phase > maxf(edge.start_phase, edge.end_phase): continue
			var fraction: float = (phase - edge.start_phase) / span
			var distance: float = path.distances[-1] * fraction
			var segment := 1
			while segment < path.distances.size() - 1 and path.distances[segment] < distance: segment += 1
			var along: float = (distance - path.distances[segment - 1]) / maxf(0.001, path.distances[segment] - path.distances[segment - 1])
			var point: Vector3 = edge.points[segment - 1].lerp(edge.points[segment], along)
			var tangent: Vector3 = (edge.points[segment] - edge.points[segment - 1]).normalized()
			var side := Vector3(-tangent.z, 0, tangent.x).normalized()
			var ripple := tuning.current_strand_shake * (sin(phase * 2.4 - clock * 4.2) * 0.7 + sin(phase * 4.1 + clock * 3.1) * 0.3)
			var envelope := sin(fraction * PI)
			point += (side * ripple * tuning.current_width * 0.3 + Vector3.UP * float(mote) * 0.035) * envelope
			point -= origin
			var size := tuning.current_particle_size * (0.45 if edge.kind == "small" else 1.4 if edge.kind == "large" else 0.8) * (1.0 - float(mote) * 0.16)
			var color: Color = path.color.lerp(Color.WHITE, 0.65)
			color.a = tuning.current_opacity * float(path.support) * (0.75 - float(mote) * 0.12) * smoothstep(0.0, 0.08, fraction) * smoothstep(0.0, 0.08, 1.0 - fraction)
			particle_batch.multimesh.set_instance_transform(count, Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * size), point))
			particle_batch.multimesh.set_instance_color(count, color)
			particle_batch.multimesh.set_instance_custom_data(count, Color(point.x, point.y, point.z, 0))
			count += 1
	particle_batch.multimesh.visible_instance_count = count

func strand_profile(kind: String) -> Vector4:
	# Pulse spacing, tail length, ripple gain, size tier. Packed into CUSTOM0.
	if kind == "small": return Vector4(3.0, 0.8, 0.65, 0.0)
	if kind == "large": return Vector4(16.0, 5.0, 1.35, 2.0)
	return Vector4(8.0, 2.0, 1.0, 1.0)

func is_grass_source(point: Vector3) -> bool:
	return source_assets.has(point) and "grass" in str(source_assets[point].id).to_lower()

## Presentation endpoint inspection only. Live energy and recipients are owned by
## ExpeditionState/PlantVastra; the explicit art study retains its preview roles.
func charge_destinations() -> Array[Dictionary]:
	var unique := {}
	for edge: Dictionary in network_edges:
		var asset: Dictionary = edge.destination_asset
		if asset.is_empty(): continue
		unique[asset.id] = {"asset_id": asset.id, "cell": asset.cell, "anchor": network_nodes[edge.b] if edge.end_phase > edge.start_phase else network_nodes[edge.a], "kind": asset.kind, "role": edge.charge_role}
	var ids: Array = unique.keys()
	ids.sort()
	var result: Array[Dictionary] = []
	for id: String in ids: result.append(unique[id].duplicate(true))
	return result

func reach_at_height(height_above_ground: float) -> float:
	return tuning.current_ground_reach * lerpf(1.0, tuning.current_height_range_multiplier, clampf(height_above_ground / tuning.current_range_height, 0.0, 1.0))

func kind_for_pair(pair: Dictionary) -> String:
	if pair.get("canopy", false): return "large"
	if not pair.bridge and (Vector2i(pair.a) - Vector2i(pair.b)).length() < 10.0 and is_grass_source(network_nodes[pair.a]) and is_grass_source(network_nodes[pair.b]): return "small"
	return "medium"

func transfer_asset(node: Dictionary, crown: bool, height_fraction: float = -1.0) -> Dictionary:
	var cell := Vector2i(int(node.cell[0]), int(node.cell[1]))
	var coord: Vector2i = world.terrain.chunk_of(cell)
	if not world.host.solid_chunks.has(coord): return {}
	var sources: Dictionary = world.host.solid_chunks[coord].living_sources
	if not sources.has(cell): return {}
	var asset: Dictionary = sources[cell]
	var point: Vector3 = asset.high_anchor if crown else asset.anchor
	if node.kind == "tree" and not crown:
		point.y = world.host.ground_height(Vector2(point.x, point.z)) + 0.1
	if node.kind == "tree" and height_fraction >= 0.0:
		var base: Vector3 = asset.anchor
		base.y = world.host.ground_height(Vector2(base.x, base.z)) + 0.1
		point = point.lerp(base.lerp(asset.high_anchor, height_fraction), tuning.current_path_variation)
	return {"asset": asset, "point": point}

# One stable curve per conserved packet. Camera movement cannot reroll its shape.
func transfer_points(start: Vector3, finish: Vector3, seed_value: int, crown: bool) -> PackedVector3Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var distance := start.distance_to(finish)
	var side := Vector3(-(finish - start).z, 0, (finish - start).x).normalized()
	var bend := rng.randf_range(-1.0, 1.0) * minf(distance * 0.18, tuning.current_width) * tuning.current_path_variation
	var twist := rng.randf_range(-0.45, 0.45) * bend
	var arc := minf(distance * tuning.current_canopy_arc, 6.0) if crown else 0.02
	arc = lerpf(arc, minf(distance * tuning.current_canopy_arc * rng.randf_range(0.3, 1.2), 6.0), tuning.current_path_variation)
	var skew := rng.randf_range(-0.35, 0.35) * tuning.current_path_variation
	var points := PackedVector3Array([start])
	var ground_a: float = world.host.ground_height(Vector2(start.x, start.z))
	var ground_b: float = world.host.ground_height(Vector2(finish.x, finish.z))
	for step in range(1, 8):
		var t := float(step) / 8.0
		var envelope := sin(t * PI)
		var point := start.lerp(finish, t) + side * (bend * envelope + twist * sin(t * TAU))
		var ground: float = world.host.ground_height(Vector2(point.x, point.z))
		# Follow relief while retaining each endpoint's independent attachment height.
		point.y = ground + lerpf(start.y - ground_a, finish.y - ground_b, t) + envelope * arc * (1.0 + skew * (t * 2.0 - 1.0))
		points.append(clear_ground(point, tuning.current_ground_clearance))
	points.append(finish)
	return points

## Same art as the study, with a finite, one-way pulse for each real conserved packet.
func build_transfer_network(battle: TacticalBattle) -> void:
	network_nodes.clear()
	network_edges.clear()
	network_vertices.clear()
	flow_distances.clear()
	living_groups = group_living_sources()
	var flights := state.flora_transfers()
	flights.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var ac := Vector2(a.source_node.cell[0], a.source_node.cell[1])
		var bc := Vector2(b.source_node.cell[0], b.source_node.cell[1])
		var da := ac.distance_squared_to(world.camera.position / 32.0)
		var db := bc.distance_squared_to(world.camera.position / 32.0)
		return da < db if da != db else int(a.id) < int(b.id))
	# Keep a small reserved visual share for real canopy packets. A busy nearby
	# grass patch must not hide every long arc; this never changes routing/energy.
	var canopy_flights: Array[Dictionary] = []
	var common_flights: Array[Dictionary] = []
	for flight in flights:
		if not flight.get("root", false) and flight.source_node.kind == "tree" and float(flight.distance) >= tuning.current_ground_reach * 2.5:
			if canopy_flights.size() < tuning.current_canopy_links and not transfer_asset(flight.source_node, true).is_empty() and not transfer_asset(flight.target_node, true).is_empty(): canopy_flights.append(flight)
		else:
			common_flights.append(flight)
	flights = canopy_flights + common_flights
	var arrays := {"colors": [], "uvs": [], "readings": [], "indices": [], "tile_cache": {}, "field_groups": living_groups}
	var density := {"colors": [], "uvs": [], "readings": [], "indices": [], "tile_cache": arrays.tile_cache, "field_groups": living_groups}
	var density_paths: Array[Dictionary] = []
	var canopies := 0
	for flight in flights:
		if network_nodes.size() + 2 > tuning.current_limit: break
		var root: bool = flight.get("root", false)
		var crown: bool = flight.source_node.kind == "tree" and not root
		var path_seed := hash("vastra-flight:%s:%s:%s" % [flight.source_node.cell, flight.target_node.cell, flight.id])
		var rng := RandomNumberGenerator.new()
		rng.seed = path_seed
		var source := transfer_asset(flight.source_node, crown, -1.0 if root else rng.randf_range(0.12, 0.96))
		var target := transfer_asset(flight.target_node, crown, -1.0 if root else rng.randf_range(0.12, 0.96))
		if source.is_empty() or target.is_empty(): continue
		var kind := "large" if crown and float(flight.distance) >= tuning.current_ground_reach * 2.5 else "medium" if crown else "small"
		if kind == "large" and canopies >= tuning.current_canopy_links: continue
		if kind == "large": canopies += 1
		var start: Vector3 = source.point
		var finish: Vector3 = target.point
		var points := transfer_points(start, finish, path_seed, crown)
		if root:
			for index in range(1, points.size() - 1):
				points[index].y = world.host.ground_height(Vector2(points[index].x, points[index].z)) + tuning.current_ground_clearance + sin(float(index) / 8.0 * PI) * 0.02
		var length := 0.0
		for i in range(1, points.size()): length += points[i].distance_to(points[i - 1])
		var key := Vector2i(network_nodes.size(), 0)
		var next := key + Vector2i.RIGHT
		network_nodes[key] = start
		network_nodes[next] = finish
		var profile := strand_profile(kind)
		var event := Vector4(float(flight.get("visual_sent", flight.sent)) * ExpeditionContract.ACTIVITY_INTERVAL, float(flight.arrival - flight.sent) * ExpeditionContract.ACTIVITY_INTERVAL, length, 2.0 if flight.get("pending", false) else 1.0)
		var edge := {"a": key, "b": next, "points": points, "start_phase": 0.0, "end_phase": length, "flow_direction": 1.0, "profile": profile, "kind": kind, "flight": flight, "source_asset": source.asset, "destination_asset": target.asset, "charge_role": "energy_recipient", "bridge": crown}
		network_edges.append(edge)
		arrays["strand_profile"] = profile
		arrays["flight_profile"] = event
		arrays["clearance"] = tuning.current_ground_clearance if not crown else 0.12
		arrays["connection"] = points
		arrays["layer_gain"] = 0.75
		append_surface(points, tuning.current_width * (0.26 if kind == "large" else 0.11 if crown else 0.04), 0, length, arrays, battle)
		density_paths.append({"edge": edge, "event": event})
	var wisps := mesh_from_arrays(arrays)
	network_vertices.clear()
	for entry in density_paths:
		var edge: Dictionary = entry.edge
		density["strand_profile"] = edge.profile
		density["flight_profile"] = entry.event
		density["clearance"] = tuning.current_ground_clearance
		density["connection"] = edge.points
		density["layer_gain"] = 0.35
		append_surface(edge.points, tuning.current_width * (0.3 if edge.kind == "large" else 0.12), 0, edge.end_phase, density, battle)
	batch.mesh = mesh_from_arrays(density)
	wisp_batch.mesh = wisps
	batch.custom_aabb = batch.mesh.get_aabb().grow(0.02)
	wisp_batch.custom_aabb = wisps.get_aabb().grow(0.02)
