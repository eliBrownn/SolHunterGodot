extends Node3D
## Local sparse imprint overlay. Immutable generation and distant terrain are untouched.
var world: Node2D
var palette: SolVisualSettings
var state: ExpeditionState
var tiles: Dictionary = {}
var terrain_source: WorldTerrain

func bind(source: Node2D, colors: SolVisualSettings) -> void:
	world = source
	palette = colors
	world.rebuilt.connect(refresh)
	world.state_replaced.connect(on_state)
	on_state(world.persistent_state)

func on_state(next: ExpeditionState) -> void:
	if state != null and state.activity_advanced.is_connected(on_tick):
		state.activity_advanced.disconnect(on_tick)
	state = next
	state.activity_advanced.connect(on_tick)
	refresh()

func on_tick(_tick: int) -> void:
	refresh()

func _process(_delta: float) -> void:
	visible = not world.encounter_active
	# All overlays share the same camera rebase; their immutable ground heights
	# need sampling only when their terrain source or membership changes.
	position = Vector3(-world.camera.position.x / 32.0, 0, -world.camera.position.y / 32.0)

func refresh() -> void:
	if terrain_source != world.terrain:
		for node in tiles.values():
			node.free()
		tiles.clear()
		terrain_source = world.terrain
	var desired: Dictionary = state.affinity_colors_near(world.cell, 14) if palette.imprint_opacity > 0 else {}
	for cell: Vector2i in tiles.keys():
		if not desired.has(cell):
			tiles[cell].free()
			tiles.erase(cell)
	for cell: Vector2i in desired:
		var color := Color(palette.color_for(desired[cell]), palette.imprint_opacity)
		if tiles.has(cell):
			var existing: MeshInstance3D = tiles[cell]
			if existing.material_override.albedo_color != color:
				existing.material_override.albedo_color = color
			continue
		var node := MeshInstance3D.new()
		var mesh: Mesh = world.host.ground_mesh(cell, 0.95)
		var material := StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.albedo_color = color
		node.mesh = mesh
		node.material_override = material
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		node.set_meta("cell", cell)
		node.position = Vector3(cell.x + 0.5, world.host.ground_height(Vector2(cell) + Vector2(0.5, 0.5)) + 0.12, cell.y + 0.5)
		add_child(node)
		tiles[cell] = node
	_process(0)
