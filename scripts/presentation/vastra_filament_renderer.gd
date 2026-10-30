extends Node3D
## Optical consumer only. Exact authoritative transfer identity, clock and path.
var layers: Dictionary = {}
var configured := Vector2i.ZERO
var created := 0

func sync(owner_current: Node3D) -> void:
	var tuning: VastraParticleSettings=owner_current.tuning.particle_filaments
	if tuning==null or not tuning.enabled or not tuning.valid() or owner_current.study_mode or owner_current.tuning.current_debug_view!=0 or not owner_current.tuning.currents_enabled or owner_current.tuning.current_limit==0:
		for layer in layers.values(): layer.node.hide()
		return
	var shape := Vector2i(tuning.heads,tuning.history_samples)
	if shape!=configured:
		for layer in layers.values(): layer.node.queue_free()
		layers.clear()
		configured=shape
	var seen := {}
	var seconds: float=owner_current.state.activity_seconds()
	for edge in owner_current.network_edges:
		if seen.size()>=tuning.transfer_limit: break
		if not edge.has("flight"): continue
		var flight: Dictionary=edge.flight
		var key := str(flight.id)+":"+str(flight.sent)
		seen[key]=true
		if not layers.has(key): layers[key]=make_layer(owner_current,tuning)
		var layer: Dictionary=layers[key]
		var points := PackedVector3Array()
		for point in edge.points: points.append(point-Vector3(owner_current.batch_origin.x,0,owner_current.batch_origin.y))
		if points.size()!=9: continue
		var elapsed: float=seconds-float(flight.get("visual_sent",flight.sent))*ExpeditionContract.ACTIVITY_INTERVAL
		var duration: float=float(flight.arrival-flight.sent)*ExpeditionContract.ACTIVITY_INTERVAL
		if flight.get("pending",false): elapsed=minf(elapsed,maxf(duration-0.001,0))
		layer.node.visible=elapsed>=0 and elapsed<=duration+tuning.trail_seconds and tuning.visibility>0 and tuning.transfer_visibility>0
		for material: ShaderMaterial in [layer.motion,layer.draw]:
			material.set_shader_parameter("live_path",points)
			material.set_shader_parameter("source_position",points[0])
			material.set_shader_parameter("target_position",points[-1])
			material.set_shader_parameter("path_width",0.08)
		layer.motion.set_shader_parameter("elapsed",elapsed)
		layer.motion.set_shader_parameter("duration",duration)
		layer.motion.set_shader_parameter("trail_seconds",tuning.trail_seconds)
		for pair in [["opacity",tuning.visibility],["visibility_scale",tuning.transfer_visibility],["particle_size",tuning.thickness],["filament_length",tuning.filament_length],["refraction",tuning.refraction],["pulse_strength",tuning.send_pulse_strength],["pulse_amount",exp(-maxf(elapsed,0)/tuning.send_pulse_seconds)],["animation_time",seconds]]:
			layer.draw.set_shader_parameter(pair[0],pair[1])
		for name in ["sol_count","sol_voids"]:
			var value: Variant=owner_current.material.get_shader_parameter(name)
			if value!=null:
				if name=="sol_voids":
					var local_voids := PackedVector4Array()
					for hole in value: local_voids.append(hole-Vector4(owner_current.batch_origin.x,0,owner_current.batch_origin.y,0))
					layer.draw.set_shader_parameter(name,local_voids)
				else: layer.draw.set_shader_parameter(name,value)
	for key in layers.keys():
		if not seen.has(key):
			layers[key].node.queue_free()
			layers.erase(key)

func make_layer(owner_current: Node3D, tuning: VastraParticleSettings) -> Dictionary:
	var node := GPUParticles3D.new()
	node.amount=tuning.heads*(tuning.history_samples+1)
	node.lifetime=3600
	node.explosiveness=1
	node.local_coords=true
	node.fixed_fps=60
	node.use_fixed_seed=true
	node.seed=291030
	node.visibility_aabb=AABB(Vector3(-128,-16,-128),Vector3(256,96,256))
	node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var motion := ShaderMaterial.new()
	motion.shader=preload("res://shaders/vastra_filament_particles.gdshader")
	motion.set_shader_parameter("use_live_path",true)
	motion.set_shader_parameter("trail_samples",tuning.history_samples)
	node.process_material=motion
	var draw := ShaderMaterial.new()
	draw.shader=preload("res://shaders/vastra_particle_lab_draw.gdshader")
	draw.set_shader_parameter("use_live_path",true)
	draw.set_shader_parameter("transfer_packet",true)
	draw.set_shader_parameter("tint",Color.WHITE)
	draw.set_shader_parameter("field_noise",owner_current.optical_noise)
	var mesh: ArrayMesh=preload("res://scripts/presentation/vastra_filament_mesh.gd").create()
	mesh.surface_set_material(0,draw)
	node.draw_pass_1=mesh
	add_child(node)
	created+=1
	return {"node":node,"motion":motion,"draw":draw}
