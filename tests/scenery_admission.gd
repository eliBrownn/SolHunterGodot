extends SceneTree

class Clock extends RefCounted:
	var seconds := 0.0
	func activity_seconds() -> float: return seconds

class Source extends Node3D:
	var tuning := VastraSettings.new()
	var study_mode := false
	var state := Clock.new()
	var network_edges: Array = []
	var batch_origin := Vector2i.ZERO
	var material := ShaderMaterial.new()
	var optical_noise := ImageTexture3D.new()

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var source := Source.new()
	source.tuning.particle_filaments = VastraParticleSettings.new()
	source.material.shader = preload("res://shaders/vastra_current.gdshader")
	root.add_child(source)
	var renderer = preload("res://scripts/presentation/vastra_filament_renderer.gd").new()
	source.add_child(renderer)
	var points := PackedVector3Array()
	for index in range(9): points.append(Vector3(index, 1, 0))
	source.network_edges = [{"points": points, "flight": {"id": 1, "sent": 0, "arrival": 20}}]
	renderer.sync(source)
	var layer: Dictionary = renderer.layers.values()[0]
	assert(layer.node.draw_order == GPUParticles3D.DRAW_ORDER_VIEW_DEPTH)
	assert(layer.draw.render_priority > 0)
	assert(is_zero_approx(float(layer.draw.get_shader_parameter("admission_visibility"))))
	source.state.seconds = 0.225
	renderer.sync(source)
	assert(is_equal_approx(float(layer.draw.get_shader_parameter("admission_visibility")), 0.5))
	# Repeated sync at the same active clock cannot advance the fade during pause.
	renderer.sync(source)
	assert(is_equal_approx(float(layer.draw.get_shader_parameter("admission_visibility")), 0.5))
	source.state.seconds = 0.45
	renderer.sync(source)
	source.network_edges.clear()
	source.batch_origin = Vector2i(16, 0)
	source.state.seconds = 0.675
	renderer.sync(source)
	assert(renderer.layers.size() == 1 and layer.node.position == Vector3(-16, 0, 0))
	assert(is_equal_approx(float(layer.draw.get_shader_parameter("admission_visibility")), 0.5))
	source.state.seconds = 1.0
	renderer.sync(source)
	assert(renderer.layers.is_empty())
	source.queue_free()
	await process_frame
	print("SCENERY ADMISSION: admission, pause, retirement and rebasing passed")
	quit()
