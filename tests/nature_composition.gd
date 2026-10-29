extends SceneTree
const Art = preload("res://scripts/scenery/nature_art.gd")
const Chunk = preload("res://scripts/presentation/solid_chunk.gd")
const Settings = preload("res://resources/nature_cohesive_sample.tres")
var failures: Array[String] = []
var checks := 0

func check(value: bool, description: String) -> void:
	checks += 1
	if not value:
		failures.append(description)
		push_error(description)

func _initialize() -> void:
	create_timer(120).timeout.connect(func(): quit(1))
	run.call_deferred()

func records(t: WorldTerrain, coord: Vector2i, settings: NatureSettings = Settings) -> Array:
	var chunk := Chunk.new()
	chunk.build(t.extract_chunk(coord), t, coord, settings)
	var original := Chunk.new()
	original.build(t.extract_chunk(coord), t, coord, NatureSettings.new())
	check(original.obstacle_count == chunk.obstacle_count, "Composition retains every generated blocking tree and rock")
	var original_blockers: Array = []
	var composed_blockers: Array = []
	for object in original.pick_objects:
		if object.get("category") in ["tree","rock"]:
			original_blockers.append(object)
	for object in chunk.pick_objects:
		if object.get("category") in ["tree","rock"]:
			composed_blockers.append(object)
	check(original_blockers == composed_blockers, "Blocking assets, transforms and picks remain identical")
	original.free()
	var result := chunk.cosmetic_records.duplicate(true)
	var parts := 0
	var triangles := 0
	for record in result:
		var model: Dictionary = Art.parts(load(record.asset))
		parts += model.pieces.size()
		triangles += model.triangles
		var found := false
		for piece in chunk.pick_objects:
			if piece.get("category") == "detail" and piece.cell == record.cell:
				var transformed: Transform3D = piece.transform
				transformed.origin += Vector3(coord.x * 16, 0, coord.y * 16)
				check((transformed * piece.bounds).intersects(record.bounds.grow(0.001)), "Published visual uses the admitted absolute transform")
				found = true
				break
		check(found, "Admitted dressing is actually published and pickable")
	check(result.size() <= 48 and parts <= 256 and triangles <= 12000, "Bounded sample stays within the provisional per-chunk cosmetic complexity envelope")
	chunk.free()
	return result

func run() -> void:
	check(Settings.valid(), "Sample settings form a valid bounded contract")
	check(NatureSettings.new().composition == null, "Global defaults do not expand the sample palettes")
	var invalid := Settings.composition.patches[0].entries[0].duplicate()
	invalid.uniform_scale = NAN
	check(not invalid.valid() and invalid.admitted_model().is_empty(), "Nonfinite scale is rejected")
	invalid = Settings.composition.patches[2].entries[2].duplicate()
	invalid.uniform_scale = 2
	invalid.maximum_width = 0.1
	check(invalid.admitted_model().is_empty(), "Flat pads cannot bypass horizontal extent limits")
	var node := Node3D.new()
	var mesh := MeshInstance3D.new()
	mesh.mesh = BoxMesh.new()
	mesh.mesh.material = StandardMaterial3D.new()
	node.add_child(mesh)
	check(Art.supported_static(node), "Static mesh materials are supported")
	mesh.material_override = StandardMaterial3D.new()
	check(not Art.supported_static(node), "Overrides cannot silently lose materials")
	mesh.material_override = null
	mesh.hide()
	check(not Art.supported_static(node), "Hidden helpers cannot silently become visible")
	mesh.show()
	var animation := AnimationPlayer.new()
	node.add_child(animation)
	check(not Art.supported_static(node), "Animated scenes are outside static admission")
	node.free()
	var t := WorldTerrain.new(2601026)
	var state := ExpeditionState.new(2601026)
	var before := state.snapshot()
	var baseline: Dictionary = {}
	var counts: Dictionary = {}
	var chunks: Dictionary = {}
	for patch in Settings.composition.patches:
		counts[patch.patch_id] = 0
		for entry in patch.entries:
			check(not entry.admitted_model().is_empty(), "Palette entry satisfies bounds and static complexity admission")
			var raw := Art.parts(entry.scene)
			var compact := entry.admitted_model()
			var compact_bounds := AABB()
			var compact_triangles := 0
			var materials: Array = []
			var actual_bounds := AABB()
			var first_vertex := true
			for piece in raw.pieces:
				for surface in range(piece.mesh.get_surface_count()):
					materials.append(piece.mesh.surface_get_material(surface))
					var raw_arrays: Array = piece.mesh.surface_get_arrays(surface)
					for vertex in raw_arrays[Mesh.ARRAY_VERTEX]:
						var posed: Vector3 = piece.transform * vertex
						actual_bounds = AABB(posed,Vector3.ZERO) if first_vertex else actual_bounds.expand(posed)
						first_vertex = false
			for i in range(compact.pieces.size()):
				var piece: Dictionary = compact.pieces[i]
				var box: AABB = piece.transform * piece.mesh.get_aabb()
				compact_bounds = box if i == 0 else compact_bounds.merge(box)
				for surface in range(piece.mesh.get_surface_count()):
					check(piece.mesh.surface_get_material(surface) in materials, "Static batching retains the exact authored mesh material")
					var arrays: Array = piece.mesh.surface_get_arrays(surface)
					compact_triangles += (arrays[Mesh.ARRAY_INDEX].size() if arrays[Mesh.ARRAY_INDEX] != null else arrays[Mesh.ARRAY_VERTEX].size()) / 3
			# A rotated part's AABB is conservative. Compare the actual transformed
			# vertex bounds, rather than requiring its empty corners to be geometry.
			check(actual_bounds.position.is_equal_approx(compact_bounds.position) and actual_bounds.size.is_equal_approx(compact_bounds.size), "Static batching preserves transformed vertex bounds")
			check(compact_triangles == raw.triangles, "Static batching preserves every admitted triangle")
		for y in range(patch.bounds.position.y, patch.bounds.end.y):
			for x in range(patch.bounds.position.x, patch.bounds.end.x):
				chunks[t.chunk_of(Vector2i(x, y))] = true
	for coord in chunks:
		baseline[coord] = records(t, coord)
		for record in baseline[coord]:
			counts[record.patch] += 1
			var sample := t.sample(record.cell)
			check(sample.obstacle == 0, "Dressing never moves or hides a generated blocker")
			check(Rect2(Vector2(coord * 16), Vector2(16, 16)).encloses(Rect2(Vector2(record.bounds.position.x, record.bounds.position.z), Vector2(record.bounds.size.x, record.bounds.size.z))), "Full visual footprint remains in the owning chunk")
			if record.surface == NatureAssetEntry.Surface.WATER:
				check(not t.is_walkable(record.cell) and absf(record.bounds.position.y - float(t.pond_at(record.cell).level) - 0.012) < 0.00001, "Floating plants use the pond level without changing water legality")
	var reverse: Array = chunks.keys()
	reverse.reverse()
	t._height_cache.clear()
	t._normal_cache.clear()
	t._pond_cache.clear()
	t._slope_cache.clear()
	Art.cache.clear()
	Art.compact_cache.clear()
	for coord in reverse:
		check(baseline[coord] == records(t, coord), "Eviction and reversed publication reconstruct exact cosmetic records")
	var save := ExpeditionSave.snapshot(t.world_seed, Vector2i.ZERO, false, false, t.generation_version, t.climate, state.snapshot(), t.relief)
	check(ExpeditionSave.validate(save), "Current generation snapshot is valid")
	var restored := WorldTerrain.new(int(save.seed), save.climate, save.relief)
	for coord in chunks:
		check(baseline[coord] == records(restored, coord), "Save settings reconstruct matching asset/cell/world transforms")
	check(Settings.composition.patch_at(WorldTerrain.new(7), Vector2i(32,16)) == null, "Other expedition seeds retain existing scenery")
	check(Settings.composition.patch_at(t, Vector2i(-100,-100)) == null, "Outside bounded samples retains existing scenery")
	for kind in counts:
		check(counts[kind] > 0, "Each actual habitat sample publishes dressing")
	var negative := NatureSettings.new()
	negative.composition = NatureComposition.new()
	var negative_patch: NaturePatch = Settings.composition.patches[0].duplicate(true)
	negative_patch.bounds = Rect2i(-44,-44,24,24)
	negative_patch.habitats.assign([0,1,2,3,5])
	negative.composition.patches.assign([negative_patch])
	var negative_count := 0
	for coord in [Vector2i(-3,-3),Vector2i(-2,-3),Vector2i(-3,-2),Vector2i(-2,-2)]:
		var first := records(t,coord,negative)
		negative_count += first.size()
		check(first == records(restored,coord,negative), "Negative-coordinate borders reconstruct the same absolute cosmetic transforms")
	check(negative_count > 0, "Negative-coordinate fixture exercises actual admitted geometry")
	var main: Node3D = load(ProjectSettings.get_setting("application/run/main_scene")).instantiate()
	root.add_child(main)
	check(main.active_nature.composition != null, "Normal F5 entry includes the owner-approved bounded scenery")
	var live_before: Dictionary = main.world.persistent_state.snapshot()
	main.world.rebuild_world()
	check(live_before == main.world.persistent_state.snapshot(), "Promoted scenery rebuild preserves live persistent state")
	var marker_parts := 0
	for object in main.place_root.pick_objects:
		if object.get("subject", "") == "Pond side path":
			marker_parts += 1
	check(marker_parts == 2, "Normal entry publishes one two-part pond sign without duplicate review cues")
	main.environment.sky = null
	main.free()
	print("NATURE COMPOSITION: %d checks, %d failures; placements %s" % [checks, failures.size(), counts])
	quit(0 if failures.is_empty() else 1)
