extends SceneTree
## Contracts needed before elevation can become gameplay terrain.

const StudyMesh = preload("res://scripts/terrain_study_mesh.gd")
var checks := 0
var failures := 0

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var presets: Array[TerrainReliefSettings] = [load("res://resources/terrain_very_gentle.tres"), load("res://resources/terrain_rolling.tres"), load("res://resources/terrain_upper_relief.tres")]
	var saddle := Vector4(0, 0, 1, 0)
	check(is_equal_approx(TerrainHeightfield.interpolate(saddle, Vector2(0.75, 0.25)), 0.25), "First triangle uses barycentric rather than bilinear height")
	check(is_equal_approx(TerrainHeightfield.interpolate(saddle, Vector2(0.25, 0.75)), 0.25), "Second triangle uses the same diagonal")
	check(is_equal_approx(TerrainHeightfield.interpolate(saddle, Vector2(0.5, 0.5)), 0.5), "Diagonal interpolation is continuous")
	for tuning in presets:
		check(tuning.valid(), "Authored preview settings are valid")
		for seed_value in [0, 17, 2601026, 2147483646]:
			var field := TerrainHeightfield.new(seed_value, tuning)
			var restored := TerrainHeightfield.restore(JSON.parse_string(JSON.stringify(field.snapshot())))
			check(restored != null, "JSON parameter snapshot restores")
			for cell in [Vector2i(-17, -16), Vector2i.ZERO, Vector2i(16, 16), Vector2i(1000000, -1000000)]:
				var normal := field.vertex_normal(cell)
				check(is_finite(field.vertex_height(cell)) and normal.is_finite() and normal.y > 0, "Finite height and upward normals at supported coordinates")
				check(restored.vertex_height(cell) == field.vertex_height(cell), "Saveable parameters exactly reproduce pinned-runtime vertices")
				var at := Vector2(cell) + Vector2(0.7, 0.3)
				var step := 0.001
				var gradient := Vector2((field.surface_height(at + Vector2(step, 0)) - field.surface_height(at)) / step, (field.surface_height(at + Vector2(0, step)) - field.surface_height(at)) / step)
				# Float32 Vector2 positions near the coordinate limit cannot retain 0.001.
				if cell.length() < 100:
					check(field.surface_normal(at).distance_to(Vector3(-gradient.x, 1, -gradient.y).normalized()) < 0.003, "Analytic triangle normal matches the interpolated surface")
				check(absf(field.surface_height(Vector2(cell)) - field.vertex_height(cell)) < 0.000001, "Surface and mesh agree at integer vertices")
	var settings := TerrainReliefSettings.new()
	var field := TerrainHeightfield.new(17, settings)
	var before := field.vertex_height(Vector2i(12, 31))
	settings.broad_amplitude = 0
	check(field.vertex_height(Vector2i(12, 31)) == before, "Editing the source resource does not mutate an existing field")
	var invalid := field.snapshot()
	invalid.contract_version = 999
	check(TerrainHeightfield.restore(invalid) == null, "Unknown heightfield contracts are rejected")
	invalid = field.snapshot()
	invalid.parameters.detail_scale = 0
	check(TerrainHeightfield.restore(invalid) == null, "Invalid saved frequency parameters are rejected")
	invalid = field.snapshot()
	invalid.seed = 2.5
	check(TerrainHeightfield.restore(invalid) == null, "Fractional seeds are rejected")
	invalid = field.snapshot()
	invalid.parameters.micro_amplitude = NAN
	check(TerrainHeightfield.restore(invalid) == null, "Nonfinite saved parameters are rejected")
	invalid = field.snapshot()
	invalid.contract_version = true
	check(TerrainHeightfield.restore(invalid) == null, "Boolean contract versions are rejected")
	var terrain := WorldTerrain.new(17)
	var terrain_before := terrain.extract_chunk(Vector2i.ZERO)
	for pair in [[Vector2i(-1, -1), Vector2i(0, -1)], [Vector2i.ZERO, Vector2i(1, 0)]]:
		var left_mesh := StudyMesh.build(field, terrain, pair[0])
		var right_mesh := StudyMesh.build(field, terrain, pair[1])
		var left := left_mesh.surface_get_arrays(0)
		var right := right_mesh.surface_get_arrays(0)
		check(left[Mesh.ARRAY_VERTEX].size() == 289 and left[Mesh.ARRAY_INDEX].size() == 1536, "Chunk mesh has shared corner lattice and two triangles per cell")
		for index in range(17):
			check(left[Mesh.ARRAY_VERTEX][index * 17 + 16].y == right[Mesh.ARRAY_VERTEX][index * 17].y, "Independent neighboring meshes share border heights")
			check(left[Mesh.ARRAY_NORMAL][index * 17 + 16] == right[Mesh.ARRAY_NORMAL][index * 17], "Independent neighboring meshes share border normals")
	check(terrain.extract_chunk(Vector2i.ZERO) == terrain_before, "Preview sampling never changes the production generator")
	var north := StudyMesh.build(field, terrain, Vector2i(-1, -1)).surface_get_arrays(0)
	var south := StudyMesh.build(field, terrain, Vector2i(-1, 0)).surface_get_arrays(0)
	for index in range(17):
		check(north[Mesh.ARRAY_VERTEX][16 * 17 + index].y == south[Mesh.ARRAY_VERTEX][index].y and north[Mesh.ARRAY_NORMAL][16 * 17 + index] == south[Mesh.ARRAY_NORMAL][index], "North/south meshes share border heights and normals")
	var scene: Node3D = load("res://scenes/terrain_preview.tscn").instantiate()
	root.add_child(scene)
	check(scene.selected == 1 and scene.field.snapshot().parameters == presets[1].parameters(), "Preview starts with the connected rolling resource")
	var initial: Dictionary = scene.field.snapshot()
	var key := InputEventKey.new()
	key.keycode = KEY_3
	key.pressed = true
	scene._unhandled_input(key)
	check(scene.selected == 2 and scene.field.snapshot() != initial, "Preset shortcut rebuilds the actual field")
	key.keycode = KEY_TAB
	scene._unhandled_input(key)
	check(scene.overview and not scene.environment.fog_enabled, "Overview control changes camera and fog")
	key.keycode = KEY_HOME
	scene._unhandled_input(key)
	check(not scene.overview and scene.environment.fog_enabled, "Reset restores the walking comparison camera")
	scene.presets[0] = null
	scene.select_preset(0)
	check(scene.field.snapshot().parameters == TerrainReliefSettings.new().parameters(), "Missing preview presets safely use connected default parameters")
	scene.dragging = true
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_MIDDLE
	release.pressed = false
	scene._input(release)
	check(not scene.dragging, "Camera drag releases even when pointer is over GUI")
	scene.free()
	print("TERRAIN HEIGHTFIELD: %d checks, %d failures." % [checks, failures])
	quit(0 if failures == 0 else 1)
