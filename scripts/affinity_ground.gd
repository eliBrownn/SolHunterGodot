extends Node3D
## Local sparse imprint overlay. Immutable generation and distant terrain are untouched.
var world: Node2D
var palette: SolVisualSettings
var state: ExpeditionState

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
	for node in get_children():
		var cell: Vector2i = node.get_meta("cell")
		var point: Vector2 = Vector2(cell) * 32.0 + Vector2(16, 16) - world.camera.position
		node.position = Vector3(point.x / 32.0, 0.12, point.y / 32.0)

func refresh() -> void:
	for child in get_children():
		child.free()
	var tiles := state.affinity_tiles()
	for at in tiles:
		var parts: PackedStringArray = at.split(":")
		var cell := Vector2i(int(parts[0]), int(parts[1]))
		if Vector2(cell - world.cell).length() > 14:
			continue
		var row: Dictionary = tiles[at]
		var node := MeshInstance3D.new()
		var mesh := PlaneMesh.new()
		mesh.size = Vector2(0.95, 0.95)
		var material := StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.albedo_color = Color(palette.color_for(row.affinity), palette.imprint_opacity)
		node.mesh = mesh
		node.material_override = material
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		node.set_meta("cell", cell)
		var point: Vector2 = Vector2(cell) * 32.0 + Vector2(16, 16) - world.camera.position
		node.position = Vector3(point.x / 32.0, 0.12, point.y / 32.0)
		add_child(node)
