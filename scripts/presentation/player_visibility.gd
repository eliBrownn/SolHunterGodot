extends Node3D
## Overlay uses the same skinned meshes and bone poses as the visible player.

var source: Node3D
var indicator_material := ShaderMaterial.new()

func bind(actor: Node3D, _camera: Camera3D) -> void:
	source = actor
	indicator_material.shader = preload("res://shaders/model_occlusion.gdshader")
	# Ignore depth differences between the rogue's overlapping skinned body pieces.
	indicator_material.set_shader_parameter("self_depth_margin", actor.model.scale.y * 1.4)
	indicator_material.render_priority = 100
	sync_source()

func _process(_delta: float) -> void:
	sync_source()

func sync_source() -> void:
	if source == null or DisplayServer.get_name() == "headless":
		return
	for mesh in source.meshes:
		var overlay: Material = indicator_material if is_visible_in_tree() else null
		if mesh.material_overlay != overlay:
			mesh.material_overlay = overlay
