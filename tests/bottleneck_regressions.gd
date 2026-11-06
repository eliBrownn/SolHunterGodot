extends SceneTree
const Library = preload("res://scripts/scenery/plant_library.gd")
const Chunk = preload("res://scripts/presentation/solid_chunk.gd")
const Currents = preload("res://scripts/presentation/vastra_currents.gd")
const Picking = preload("res://scripts/presentation/mesh_picking.gd")
var checks := 0
var failures := 0

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	Library.refresh()
	check(Library.baked_definition("procedural_0_1_0") != null, "Runtime palette is current and admitted")
	check(Library.baked_definition("missing_palette_entry") == null, "Missing baked entries use the original builder")
	Library.palette_current = false
	check(Library.baked_definition("procedural_0_1_0") == null, "Stale palette cannot be admitted")
	Library.palette_checked = false
	for filename in DirAccess.get_files_at(Library.PALETTE_DIRECTORY):
		if not filename.ends_with(".res"): continue
		var key := filename.get_basename()
		var baked := Library.baked_definition(key)
		if baked == null:
			check(false, "Missing palette entry: " + key)
			continue
		Library.use_baked_palette = false
		var original: Resource
		if baked.growth_category == "generic_foliage":
			original = Library.foliage_definition(baked.biome, int(baked.recipe.foliage_variation), "emanator")
		else:
			original = Library.procedural_definition(baked.biome, {"role":baked.circulation_role, "class":baked.specialist_class}, baked.size_class)
		Library.use_baked_palette = true
		check(baked.recipe == original.recipe and baked.organ_graph == original.organ_graph and baked.organ_anchors == original.organ_anchors, "Bake preserves exact recipe and anatomy: " + key)
		check(baked.world_height == original.world_height and baked.world_width == original.world_width, "Bake preserves deterministic dimensions: " + key)
		var old_model := Library.Art.compact_parts(original.scene)
		var baked_model := Library.Art.parts(baked.scene)
		check(baked_model.bounds == old_model.bounds and baked_model.triangles == old_model.triangles, "Bake preserves bounds and full-resolution triangle count: " + key)
		check(baked_model.surfaces == old_model.pieces.size() - 2, "Neutral tissue surfaces merge without dropping geometry: " + key)
		for piece: Dictionary in baked_model.pieces:
			var mesh: Mesh = piece.mesh
			check(mesh.has_meta("picking_bins_v1"), "Runtime palette carries its triangle index")
			Picking.prepare(mesh)
			var uncached: Mesh = mesh.duplicate()
			uncached.remove_meta("picking_bins_v1")
			Picking.prepare(uncached)
			check(Picking.surfaces[mesh.get_instance_id()][0].bins == Picking.surfaces[uncached.get_instance_id()][0].bins, "Baked triangle bins exactly match fresh mesh indexing")
	Library.refresh()
	var chunk := Chunk.new()
	var poses: Array[Transform3D] = []
	var colors: Array[Color] = []
	for index in range(75):
		var pose := Transform3D(Basis(Vector3.UP, index * 0.13).scaled(Vector3(0.5, 1.7, 0.9)), Vector3(index * 0.1, -0.7, 2.3))
		poses.append(pose)
		colors.append(Color(0.2, index / 100.0, 0.6, 0.37))
		if not chunk.batches.has("post"): chunk.batches.post = []
		chunk.batches.post.append({"transform":pose,"color":colors[-1],"plant_cell":Vector2i.ZERO,"plant_pivot":pose.origin})
	chunk.finish()
	var instances: MultiMesh = chunk.get_child(0).multimesh
	check(chunk.plant_instances[Vector2i.ZERO].size() == 1, "Individual grass roots share one animation group per cell/batch")
	check(chunk.plant_instances[Vector2i.ZERO].values()[0].indices.size() == poses.size(), "Bulk upload retains every animated instance across slices")
	if DisplayServer.get_name() != "headless":
		for index in range(poses.size()):
			check(instances.get_instance_transform(index).is_equal_approx(poses[index]), "Bulk buffer retains basis and translation")
			check(instances.get_instance_color(index).is_equal_approx(colors[index].srgb_to_linear()), "Bulk buffer retains linear color and alpha")
	else:
		print("Bulk GPU transform/color readback requires the rendered run")
	chunk.free()
	var scene: Node3D = load("res://scenes/world_3d.tscn").instantiate()
	root.add_child(scene)
	scene.world.smoke_mode = true
	var currents: Node3D
	for child in scene.get_children():
		if child.get_script() == Currents: currents = child
	check(currents.uses_filaments() and not currents.legacy_geometry, "Production filaments skip hidden ribbon construction")
	check(currents.network_vertices.is_empty() and currents.particle_paths.is_empty(), "Hidden ribbons and legacy motes allocate no per-transfer geometry")
	var before: Dictionary = scene.world.persistent_state.snapshot()
	var refreshes: int = currents.refresh_count
	currents.mark_dirty()
	currents.refresh_seconds = 0.5
	currents._process(0.0)
	check(currents.refresh_count == refreshes + 1, "State and periodic invalidations coalesce into one refresh")
	currents.tuning.particle_filaments.enabled = false
	currents._process(0.0)
	check(currents.legacy_geometry, "Disabling filaments restores legacy geometry immediately")
	currents.tuning.particle_filaments.enabled = true
	currents._process(0.0)
	check(not currents.legacy_geometry, "Re-enabling filaments releases hidden geometry")
	currents.tuning.current_light_limit = 1
	currents.tuning.current_light_energy = 0.1
	currents._process(0.0)
	check(currents.legacy_light_paths, "Enabling optional lights refreshes their retained legacy path support")
	check(before == scene.world.persistent_state.snapshot(), "Presentation optimizations preserve saved expedition state")
	scene.environment.sky = null
	scene.free()
	print("BOTTLENECK REGRESSIONS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
