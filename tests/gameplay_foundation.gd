extends SceneTree
## Exercise the configured startup scene through normal keyboard input.

var _failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var scene_path: String = ProjectSettings.get_setting("application/run/main_scene")
	if change_scene_to_file(scene_path) != OK:
		push_error("Could not start the gameplay scene.")
		quit(1)
		return
	await scene_changed
	var world = current_scene
	var terrain := world.get_node("Terrain") as Node3D
	var player := world.get_node("Player") as Node3D
	var avatar := player.get_node("UniversalMannequin") as Node3D
	var animator: AnimationPlayer = world._player_animator
	var skeleton: Skeleton3D = avatar.skeleton
	_check(OS.get_user_data_dir().get_file() == "SolHunter-Gameplay", "User data is isolated")
	_check(animator.is_playing() and animator.current_animation == &"Idle_A", "Mannequin idles at spawn")
	var storms = world.get_node("VastraStorms")
	_check(world.get_child_count() == 7, "Only the foundation systems, storms and FPS display are active")
	var spawn: Vector2i = world.cell
	var yaw: float = world.get_node("Camera3D").rotation.y
	var right := Vector2i(Vector2.RIGHT.rotated(-yaw).round())
	var forward := Vector2i(Vector2.UP.rotated(-yaw).round())
	_check(_centered(player, terrain, spawn) and terrain.biome_name(spawn) == "Coast", "Spawn is centered on the outer beach")
	const Plan := preload("res://scripts/world/world_map_plan.gd")
	var crest: Vector2i = terrain._surface._southern_crest()
	var peak := Vector2(Plan.WORLD_ORIGIN + crest * Plan.WORLD_CELLS_PER_SAMPLE) + Vector2.ONE * (Plan.WORLD_CELLS_PER_SAMPLE * 0.5)
	_check(terrain.height_at(peak) - player.position.y >= 150.0, "Mountain crest has substantial relief above the beach spawn")
	for z in range(-1, 2):
		for x in range(-1, 2):
			var neighbor := Vector2(spawn + Vector2i(x, z)) + Vector2(0.5, 0.5)
			_check(terrain.is_land_at(neighbor), "Spawn has dry ground around it")
	await _wait_for_terrain(terrain)
	_check_terrain(terrain, spawn)
	_check_shared_vegetation(terrain)
	if "--world-seed=2601026" in OS.get_cmdline_user_args():
		_check_horizon_forest(terrain)
	var original_horizon := _far_samples(terrain)
	_check_horizon_reversal(terrain)
	_check_atlas(terrain)
	_check(world.get_node("HUD/Biome").text == terrain.biome_name(spawn), "HUD reports the map biome")

	_send_key(KEY_A, true)
	_send_key(KEY_UP, true)
	for frame in 18:
		await physics_frame
	_check(animator.current_animation == &"Walking_A", "Moving selects the authored walk loop")
	var calf := skeleton.find_bone("DEF-shin.L")
	_check(calf >= 0, "The mannequin has its animated calf bone")
	if calf >= 0:
		var pose := skeleton.get_bone_pose(calf)
		animator.advance(0.15)
		_check(not skeleton.get_bone_pose(calf).is_equal_approx(pose), "The walk clip poses the mannequin rig")
	var diagonal_cell: Vector2i = world.cell
	var diagonal := Vector2(diagonal_cell - spawn)
	_check(diagonal.dot(Vector2(forward)) > 0.0 and diagonal.dot(Vector2(right)) < 0.0,
		"Diagonal movement crosses both tile boundaries")
	var displacement := Vector2(player.position.x, player.position.z) - Vector2(spawn) - Vector2(0.5, 0.5)
	_check(absf(displacement.dot(Vector2(right + forward))) < 0.04,
		"Diagonal motion is even within world-coordinate precision")
	_send_key(KEY_A, false)
	_send_key(KEY_UP, false)
	for frame in 12:
		await physics_frame
	_check(_centered(player, terrain, diagonal_cell), "Release settles at the nearest center")
	_check(animator.current_animation == &"Idle_A", "Releasing movement returns to idle")
	await _wait_for_terrain(terrain)
	_check_terrain(terrain, world.cell)
	_send_key(KEY_RIGHT, true)
	for frame in 90:
		await physics_frame
	var walked := Vector2(world.cell - diagonal_cell)
	_check(walked.dot(Vector2(right)) >= 64 and is_zero_approx(walked.dot(Vector2(forward))),
		"A held key crosses a chunk boundary")
	_send_key(KEY_RIGHT, false)
	await _wait_for_terrain(terrain)
	_check_terrain(terrain, world.cell)
	var shared_samples := 0
	var shifted_horizon := _far_samples(terrain)
	for point in original_horizon:
		if shifted_horizon.has(point):
			shared_samples += 1
			_check(original_horizon[point] == shifted_horizon[point], "Shared horizon samples keep their height across rebuilds")
	_check(shared_samples > 100, "Distant terrain stays on the same world grid after moving")
	var before := player.position
	_send_key(KEY_RIGHT, false)
	_send_key(KEY_LEFT, true)
	for frame in 12:
		await physics_frame
	var reversal := Vector2(player.position.x - before.x, player.position.z - before.z)
	_check(reversal.dot(Vector2(right)) < 0.0, "Reversal moves in the new direction")
	_send_key(KEY_LEFT, false)
	_check(absf(angle_difference(avatar.rotation.y, yaw - PI / 2.0)) < 0.001, "Mannequin faces the new direction")
	for frame in 18:
		await physics_frame
	_check(_centered(player, terrain, world.cell), "Movement ends centered on the atlas terrain")
	if "--world-seed=2601026" in OS.get_cmdline_user_args():
		_send_key(KEY_LEFT, true)
		for frame in 120:
			if Vector2(world.cell - diagonal_cell).dot(Vector2(right)) <= 0.0:
				break
			await physics_frame
		_send_key(KEY_LEFT, false)
		_check(Vector2(world.cell - diagonal_cell).dot(Vector2(right)) <= 0.0,
			"The player walks back across the planted chunk seam")
		await _wait_for_terrain(terrain)
		await _check_plant_revisit(terrain, world.cell)
		var sprint_start := player.position
		_send_key(KEY_SHIFT, true)
		_send_key(KEY_RIGHT, true)
		for frame in 18:
			await physics_frame
		_check(animator.current_animation == &"Running_A", "Shift movement selects the authored sprint loop")
		_send_key(KEY_RIGHT, false)
		_send_key(KEY_SHIFT, false)
		var sprint := Vector2(player.position.x - sprint_start.x, player.position.z - sprint_start.z)
		_check(sprint.dot(Vector2(right)) > 24.0, "Sprinting keeps moving through planted terrain")
	var site: Vector2i = storms.site_for(Vector2i.ZERO)
	storms.advance(0.0, Vector2i.ZERO, terrain.height_at)
	var storm: GPUParticles3D = storms._emitters[site]
	var motion := storm.process_material as ShaderMaterial
	var draw := storm.draw_pass_1.surface_get_material(0) as ShaderMaterial
	_check(motion.get_shader_parameter("pattern") == 2 and draw.get_shader_parameter("all_affinities"), "Storm uses the lab's all-affinity vortex")
	var storm_position := storm.position
	storms.advance(7200.0, Vector2i.ZERO, terrain.height_at)
	_check(storms._emitters.has(site) and storm.emitting, "Storm does not expire")
	storms.advance(0.0, Vector2i(100, -100), terrain.height_at)
	_check(not storms._emitters.has(site), "Distant storm visuals unload")
	storms.advance(0.0, Vector2i.ZERO, terrain.height_at)
	_check(storms._emitters[site].position == storm_position, "Storm returns at the same position")
	var other_region := Vector2i(-3, 7)
	var other_site: Variant = storms.site_for(other_region)
	var original_seed: int = terrain.world_seed
	var fps := world.get_node("HUD/FPS") as Label
	_check(fps.anchor_right == 1.0 and fps.text.ends_with(" FPS"), "FPS counter updates at the top right")
	change_scene_to_file(scene_path)
	await scene_changed
	var reloaded = current_scene.get_node("VastraStorms")
	var reloaded_seed: int = current_scene.get_node("Terrain").world_seed
	if "--world-seed=%d" % original_seed in OS.get_cmdline_user_args():
		_check(reloaded_seed == original_seed and reloaded.site_for(other_region) == other_site,
			"Replaying a seed restores its world and storm layout")
	else:
		_check(reloaded_seed != original_seed, "Normal scene reload generates a new world")
	_check(reloaded.layout_seed == reloaded_seed, "Storm sites follow the world seed")
	if _failures == 0:
		print("Gameplay foundation smoke test passed.")
	quit(0 if _failures == 0 else 1)


func _centered(player: Node3D, terrain, cell: Vector2i) -> bool:
	var center := Vector2(cell) + Vector2(0.5, 0.5)
	return player.position.is_equal_approx(Vector3(center.x, terrain.height_at(center), center.y))


func _check_atlas(terrain) -> void:
	const Plan := preload("res://scripts/world/world_map_plan.gd")
	const Surface := preload("res://scripts/world/world_map_surface.gd")
	_check(terrain.height_at(Vector2(Plan.WORLD_ORIGIN - Vector2i.ONE * 64)) == Surface.SEA_LEVEL,
		"Ocean outside the atlas shares the sea level datum")
	var layers: Dictionary = terrain._plan.terrain_layers()
	for biome in [Plan.Biome.OCEAN, Plan.Biome.LAKE, Plan.Biome.DESERT, Plan.Biome.JUNGLE, Plan.Biome.PLAINS]:
		var index: int = layers.biome.find(biome)
		if index < 0:
			_check(false, "Approved seed includes biome %s" % biome)
			continue
		var cell := _atlas_cell(index)
		var sample: Dictionary = terrain._plan.sample_world_cell(cell)
		_check(sample.biome == biome and terrain.is_land_at(Vector2(cell)) == sample.land,
			"Terrain uses the approved biome and land mask")
		if not sample.land:
			_check(is_equal_approx(terrain.height_at(Vector2(cell)), Surface.elevation_to_height(sample.lake_level)),
				"Sea and lake surfaces use their planned levels")
			if biome == Plan.Biome.LAKE and terrain._water_material != null:
				var origin := Vector2i((Vector2(cell) / 64.0).floor()) * 64
				var arrays: Array = terrain._build_chunk_arrays(origin, terrain._samples)
				_check(not arrays[1].is_empty() and terrain._samples.bed(cell) < terrain._samples.height(cell),
					"Cool Water has a surface above an opaque lakebed")
	var river_found := false
	var irrigation_found := false
	var adjusted_biome_found := false
	for index: int in layers.biome.size():
		if not river_found and layers.river_flow[index] > 200.0 and layers.biome[index] != Plan.Biome.LAKE:
			var cell := _atlas_cell(index)
			var relative := Vector2(cell - Plan.WORLD_ORIGIN)
			_check(terrain._surface._river_strength(relative) > 0.4, "Atlas river reaches the terrain water mask")
			river_found = true
		if not irrigation_found and layers.irrigation[index] > 0:
			var sample: Dictionary = terrain._plan.sample_world_cell(_atlas_cell(index))
			_check(sample.irrigation_intake != null and sample.soil_moisture > sample.moisture,
				"Irrigated land retains its supplying intake and extra moisture")
			irrigation_found = true
		if not adjusted_biome_found and layers.irrigation[index] > 0:
			var cell := _atlas_cell(index)
			var sample: Dictionary = terrain._plan.sample_world_cell(cell)
			if sample.biome != sample.natural_biome:
				_check(terrain.biome_name(cell) == Surface.LABELS[sample.biome] and sample.irrigation_intake != null,
					"Live biome uses the irrigated classification and keeps the natural biome and intake")
				adjusted_biome_found = true
		if river_found and irrigation_found and adjusted_biome_found:
			break
	_check(river_found and irrigation_found, "Playable seed includes rivers and irrigation")
	_check(adjusted_biome_found, "Playable seed includes an irrigation-driven biome change")


func _atlas_cell(index: int) -> Vector2i:
	const Plan := preload("res://scripts/world/world_map_plan.gd")
	return Plan.WORLD_ORIGIN + Vector2i(index % Plan.SIZE.x, index / Plan.SIZE.x) * Plan.WORLD_CELLS_PER_SAMPLE \
		+ Vector2i.ONE * (Plan.WORLD_CELLS_PER_SAMPLE / 2)


func _wait_for_terrain(terrain) -> void:
	var center: Vector2i = terrain._requested_center
	var deadline := Time.get_ticks_msec() + 15000
	while (terrain._center != center or terrain._horizon.mesh == null) and Time.get_ticks_msec() < deadline:
		await process_frame
	_check(terrain._center == center and terrain._horizon.mesh != null, "Worker terrain is published")


func _check_terrain(terrain, cell: Vector2i) -> void:
	var center: Vector2i = terrain._center
	var offset: Vector2i = cell - center * terrain.CHUNK_SIZE
	var margin: int = terrain.CENTER_HYSTERESIS
	var window := Rect2i(-margin, -margin, terrain.CHUNK_SIZE + margin * 2, terrain.CHUNK_SIZE + margin * 2)
	_check(window.has_point(offset), "Published terrain center covers the current player cell")
	var expected: Array[Vector3] = []
	for z in range(center.y - 8, center.y + 8):
		for x in range(center.x - 8, center.x + 8):
			expected.append(Vector3(x, 0.0, z) * 64)
	for node in terrain.get_children():
		if node == terrain._vegetation:
			continue
		var chunk := node as MeshInstance3D
		if chunk == null:
			_check(false, "Terrain children are ground meshes")
			continue
		if chunk == terrain._horizon:
			if chunk.mesh == null:
				continue
			var horizon_bounds: AABB = chunk.mesh.get_aabb()
			_check(horizon_bounds.size.x == 16384.0 and horizon_bounds.size.z == 16384.0,
				"Coarse terrain covers the horizon in all directions")
			var horizon_vertices: PackedVector3Array = chunk.mesh.surface_get_arrays(3)[Mesh.ARRAY_VERTEX]
			var edge := Vector3(528, 0, 4)
			var seam_found := false
			for vertex in horizon_vertices:
				if vertex.x == edge.x and vertex.z == edge.z:
					var a := Vector2i(int(chunk.position.x + edge.x), int(chunk.position.z + edge.z))
					var midpoint: float = (terrain._samples.bed(a - Vector2i(0, 4)) + terrain._samples.bed(a + Vector2i(0, 4))) * 0.5
					_check(is_equal_approx(vertex.y, midpoint), "Fine horizon edges meet coarse edges")
					seam_found = true
			_check(seam_found, "The first horizon ring includes the seam midpoint")
			continue
		_check(chunk.mesh is ArrayMesh, "Chunk contains generated ground")
		if chunk.get_child_count() > 0:
			var water := chunk.get_node_or_null("CoolWater") as MeshInstance3D
			_check(water != null and water.material_override == terrain._water_material
				and water.visibility_range_end > 260.0, "Cool Water uses a range-limited overlay")
		_check(expected.has(chunk.position), "Chunk aligns with the signed grid")
		expected.erase(chunk.position)
		var vertices: PackedVector3Array = chunk.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		var corner := vertices[-1] + chunk.position
		_check(is_equal_approx(corner.y, terrain._samples.bed(Vector2i(int(corner.x), int(corner.z)))),
			"Mesh and terrain bed agree at chunk edges")
	_check(expected.is_empty(), "All chunks in the far view are present")


func _check_horizon_forest(terrain) -> void:
	const TreeLod := preload("res://scripts/presentation/map_tree_lod.gd")
	var forest: Node3D = terrain._horizon_forest
	_check(forest != null and forest.get_parent() == terrain._horizon,
		"Distant forest publishes with its terrain")
	if forest == null:
		return
	var outermost := -1
	for strip in forest.get_children():
		var surface: int = strip.get_meta("terrain_surface")
		outermost = maxi(outermost, surface / 4)
		var batch := strip.get_child(0) as MultiMeshInstance3D
		var material := batch.multimesh.mesh.surface_get_material(0) as ShaderMaterial
		_check(batch.multimesh.instance_count > 0 and material.shader == TreeLod.VECTOR_SHADER,
			"Horizon strips render solid tree silhouettes in populated biomes")
	_check(outermost == terrain.HORIZON_RINGS.size() - 1,
		"The seeded forest reaches the outermost terrain ring")


func _check_shared_vegetation(terrain) -> void:
	const MapPlants := preload("res://scripts/presentation/map_vegetation.gd")
	const Plan := preload("res://scripts/world/world_map_plan.gd")
	var vegetation = terrain._vegetation
	const TreeLod := preload("res://scripts/presentation/map_tree_lod.gd")
	var tree_limit: int = MapPlants.Plant.TREE_BASE + vegetation._species.size()
	for kind in tree_limit:
		var model: Dictionary = vegetation._model(kind)
		_check(not model.pieces.is_empty(), "Every plant and tree species has a batched model")
		if kind < MapPlants.Plant.TREE_BASE:
			continue
		_check(model.levels.size() == 7, "Each tree species has seven geometry tiers")
		var previous_vertices := 2147483647
		for level in range(1, model.levels.size()):
			var mesh: ArrayMesh = model.levels[level]
			var count := mesh.surface_get_array_len(0)
			_check(count < previous_vertices and mesh.surface_get_material(0).shader == TreeLod.VECTOR_SHADER,
				"Each distant tree tier reduces solid geometry")
			previous_vertices = count
	var trees := {}
	for sample in 1024:
		var cell := Vector2i(-42 + sample * MapPlants.TREE_STEP, 117)
		trees[vegetation._tree_kind(cell, Plan.Biome.WOODLAND)] = true
	_check(trees.size() == vegetation._species.size(), "The default woodland list can reach all tree species")
	var coast_only: MapPlants.TreeSpecies = vegetation._species[0].duplicate()
	coast_only.biomes.assign([Plan.Biome.COAST])
	var fixture := MapPlants.new()
	fixture.configure(terrain._plan, terrain._surface, terrain.world_seed, terrain.CHUNK_SIZE,
		terrain.plant_coverage, terrain.plant_scale, [coast_only], terrain.height_at, terrain._planting_chunk_ready)
	_check(fixture._tree_kind(Vector2i.ZERO, Plan.Biome.COAST) == MapPlants.Plant.TREE_BASE
		and not fixture._biome_species.has(Plan.Biome.WOODLAND),
		"Species resources allow spawning only in their listed biomes")
	fixture.free()
	_check(MapPlants.tree_hue(Plan.Biome.DESERT) != MapPlants.tree_hue(Plan.Biome.TAIGA),
		"The same species receives a different hue in desert and taiga")
	_check(TreeLod.tier(127.0) == 0 and TreeLod.tier(128.0) == 1 and TreeLod.tier(448.0) == 6
		and TreeLod.tier(129.0, 0) == 0 and TreeLod.tier(130.0, 0) == 1
		and TreeLod.tier(126.0, 1) == 1 and TreeLod.tier(125.0, 1) == 0,
		"The authored model extends to 128 cells with stable transitions at the boundary")
	var patch_key := Vector3i(-2048, 2048, 1)
	var patch_origin := Vector2i(patch_key.x, patch_key.y) * int(terrain.CHUNK_SIZE)
	var kind := MapPlants.Plant.TREE_BASE
	vegetation._publish(patch_key, patch_origin, {kind: [{
		"transform": Transform3D.IDENTITY, "color": Color.WHITE, "hue": MapPlants.tree_hue(Plan.Biome.TAIGA),
	}]})
	var patch: Node3D = vegetation._patches[patch_key]
	var batch := patch.get_child(0) as MultiMeshInstance3D
	var instances := batch.multimesh
	vegetation._set_tree_lod(patch, Vector2(patch_origin))
	var near_mesh := instances.mesh
	vegetation._set_tree_lod(patch, Vector2(patch_origin) - Vector2(120.0, 0.0))
	_check(instances.mesh == near_mesh, "A streamed tree patch keeps its authored mesh at 120 cells")
	vegetation._set_tree_lod(patch, Vector2(patch_origin) - Vector2(460.0, 0.0))
	_check(instances.mesh != near_mesh and instances.instance_count == 1 and batch.multimesh == instances,
		"A streamed tree batch swaps to a vector mesh with the same instance buffer")
	vegetation._set_tree_lod(patch, Vector2(patch_origin))
	_check(instances.mesh == near_mesh, "Returning to a tree patch restores its authored model")
	vegetation._patches.erase(patch_key)
	patch.free()
	for biome in Plan.Biome.size():
		if biome == Plan.Biome.OCEAN or biome == Plan.Biome.LAKE:
			_check(not MapPlants.HABITATS.has(biome), "Water biomes have no terrestrial planting profile")
			continue
		var profile: Vector3 = MapPlants.HABITATS.get(biome, Vector3.ZERO)
		_check(profile.z > 0.0, "Every land biome admits trees")
		var ground_kinds := {}
		for sample in 1024:
			var cell := Vector2i(-42 + sample * MapPlants.GROUND_STEP, 117)
			ground_kinds[vegetation._ground_kind(cell, profile.y)] = true
		_check(ground_kinds.size() == MapPlants.Plant.TREE_BASE,
			"Every land biome can select all ground plants and grass")
	_check(is_equal_approx(terrain.plant_scale, 1.5) and is_equal_approx(vegetation._plant_scale, 1.5),
		"The startup scene applies the larger shared plant scale")


func _check_plant_revisit(terrain, cell: Vector2i) -> void:
	const MapPlants := preload("res://scripts/presentation/map_vegetation.gd")
	var vegetation = terrain._vegetation
	var chunk := Vector2i((Vector2(cell) / float(terrain.CHUNK_SIZE)).floor())
	var key := Vector3i(chunk.x, chunk.y, 0)
	var first := await _wait_for_plant_patch(vegetation, key)
	_check(first != null and int(first.get_meta("plant_count", 0)) > 0, "Normal gameplay publishes a planted ground patch")
	if first == null:
		return
	var signature: int = first.get_meta("placement_signature")
	var origin := chunk * int(terrain.CHUNK_SIZE)
	var patch_width := int(terrain.CHUNK_SIZE) / MapPlants.GROUND_STEP
	var scale_checked := false
	for index in patch_width * patch_width:
		var site := origin + Vector2i(index % patch_width, index / patch_width) * MapPlants.GROUND_STEP
		var grown: Dictionary = vegetation._placement(site, false, origin)
		if grown.is_empty():
			continue
		var scale: float = vegetation._plant_scale
		vegetation._plant_scale = 1.0
		var baseline: Dictionary = vegetation._placement(site, false, origin)
		vegetation._plant_scale = scale
		var grown_pose: Transform3D = grown.transform
		var baseline_pose: Transform3D = baseline.transform
		scale_checked = grown_pose.origin.is_equal_approx(baseline_pose.origin) and (
			grown_pose.basis.get_scale().is_equal_approx(baseline_pose.basis.get_scale() * 1.5))
		break
	_check(scale_checked, "The larger default scales a planted site's width and height around its root")
	for batch in first.get_children():
		_check(batch is MultiMeshInstance3D and batch.multimesh.instance_count > 0, "Plants publish in shared instance batches")
	vegetation.cover(cell + Vector2i(640, 0))
	_check(not vegetation._patches.has(key), "A distant plant patch is retired")
	vegetation.cover(cell)
	var returned := await _wait_for_plant_patch(vegetation, key)
	_check(returned != null and returned.get_meta("placement_signature") == signature,
		"A regenerated patch has identical positions, sizes, kinds and colors")
	_check(vegetation._patches.size() <= pow(2 * MapPlants.CANOPY_RADIUS + 1, 2)
		+ pow(2 * MapPlants.GROUND_RADIUS + 1, 2), "Plant residency stays within the bounded patch window")


func _wait_for_plant_patch(vegetation, key: Vector3i) -> Node3D:
	var deadline := Time.get_ticks_msec() + 5000
	while not vegetation._patches.has(key) and Time.get_ticks_msec() < deadline:
		await process_frame
	return vegetation._patches.get(key)


func _check_horizon_reversal(terrain) -> void:
	var center: Vector2i = terrain._center
	var origin := center * 64
	for x in [63, 64, 63, 64]:
		terrain.cover(origin + Vector2i(x, 32))
		_check(terrain._requested_center == center, "Walking along a chunk edge keeps the requested center stable")
	terrain.cover(origin + Vector2i(72, 32))
	_check(terrain._requested_center == center + Vector2i.RIGHT, "Walking beyond the margin requests fresh terrain")
	terrain.cover(origin + Vector2i(55, 32))
	var mesh: Mesh = terrain._horizon.mesh
	terrain._prepared = {"center": center + Vector2i.RIGHT}
	terrain._publish_prepared()
	_check(terrain._center == center and terrain._horizon.mesh == mesh and terrain._prepared.is_empty(),
		"A build completed after reversing cannot replace the current horizon")


func _far_samples(terrain) -> Dictionary:
	var horizon: MeshInstance3D = terrain._horizon
	var samples := {}
	for surface in range(horizon.mesh.get_surface_count() - 4, horizon.mesh.get_surface_count()):
		for vertex: Vector3 in horizon.mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]:
			var at := vertex + horizon.position
			samples[Vector2i(int(at.x), int(at.z))] = at.y
	return samples


func _send_key(key: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = key
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()


func _check(condition: bool, description: String) -> void:
	if not condition:
		_failures += 1
		push_error(description)
