extends Node3D
## Optical consumer only. Exact authoritative transfer identity, clock and path.
var layers: Dictionary = {}
var configured := Vector2i.ZERO
var created := 0
var path_uploads := 0
var uniform_uploads := 0
var last_seconds := -1.0
var void_signature: Array = []
var local_voids := PackedVector4Array()
const ADMISSION_SECONDS := 0.45

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
	var delta := maxf(0.0, seconds-last_seconds) if last_seconds >= 0.0 else 0.0
	last_seconds=seconds
	var count: Variant=owner_current.material.get_shader_parameter("sol_count")
	var voids: Variant=owner_current.material.get_shader_parameter("sol_voids")
	var signature: Array=[owner_current.batch_origin,count,voids]
	if signature!=void_signature:
		void_signature=signature.duplicate(true)
		local_voids=PackedVector4Array()
		if voids!=null:
			for hole in voids: local_voids.append(hole-Vector4(owner_current.batch_origin.x,0,owner_current.batch_origin.y,0))
	for edge in owner_current.network_edges:
		if seen.size()>=tuning.transfer_limit: break
		if not edge.has("flight"): continue
		var flight: Dictionary=edge.flight
		var key := str(flight.id)+":"+str(flight.sent)
		seen[key]=true
		var admitted := not layers.has(key)
		if admitted: layers[key]=make_layer(owner_current,tuning)
		var layer: Dictionary=layers[key]
		if not admitted: layer.weight=minf(1.0,float(layer.weight)+delta/ADMISSION_SECONDS)
		layer.node.position=Vector3.ZERO
		set_cached(layer.draw,layer.draw_values,"admission_visibility",smoothstep(0.0,1.0,float(layer.weight)))
		if edge.points.size()<2 or edge.points.size()>64: continue
		if layer.origin!=owner_current.batch_origin or layer.path!=edge.points:
			layer.origin=owner_current.batch_origin
			layer.path=edge.points.duplicate()
			var points := PackedVector3Array()
			for point in edge.points: points.append(point-Vector3(layer.origin.x,0,layer.origin.y))
			var point_count := points.size()
			while points.size()<64: points.append(points[-1])
			for pair in [[layer.motion,layer.motion_values],[layer.draw,layer.draw_values]]:
				set_cached(pair[0],pair[1],"live_path_count",point_count)
				set_cached(pair[0],pair[1],"live_path",points)
				set_cached(pair[0],pair[1],"source_position",points[0])
				set_cached(pair[0],pair[1],"target_position",points[-1])
				set_cached(pair[0],pair[1],"path_width",0.08)
			path_uploads+=1
		var elapsed: float=seconds-float(flight.get("visual_sent",flight.sent))*ExpeditionContract.ACTIVITY_INTERVAL
		var duration: float=float(flight.arrival-flight.sent)*ExpeditionContract.ACTIVITY_INTERVAL
		if flight.get("pending",false): elapsed=minf(elapsed,maxf(duration-0.001,0))
		layer.node.visible=elapsed>=0 and elapsed<=duration+tuning.trail_seconds and tuning.visibility>0 and tuning.transfer_visibility>0
		set_cached(layer.motion,layer.motion_values,"elapsed",elapsed)
		set_cached(layer.motion,layer.motion_values,"duration",duration)
		set_cached(layer.motion,layer.motion_values,"trail_seconds",tuning.trail_seconds)
		for pair in [["opacity",tuning.visibility],["visibility_scale",tuning.transfer_visibility],["particle_size",tuning.thickness],["filament_length",tuning.filament_length],["refraction",tuning.refraction],["pulse_strength",tuning.send_pulse_strength],["pulse_amount",exp(-maxf(elapsed,0)/tuning.send_pulse_seconds)],["animation_time",seconds]]:
			set_cached(layer.draw,layer.draw_values,pair[0],pair[1])
		if count!=null: set_cached(layer.draw,layer.draw_values,"sol_count",count)
		if voids!=null: set_cached(layer.draw,layer.draw_values,"sol_voids",local_voids)
	for key in layers.keys():
		if not seen.has(key):
			var layer: Dictionary=layers[key]
			layer.weight=maxf(0.0,float(layer.weight)-delta/ADMISSION_SECONDS)
			# Retired paths keep their absolute placement across floating-origin rebases.
			var offset: Vector2i=layer.origin-owner_current.batch_origin
			layer.node.position=Vector3(offset.x,0,offset.y)
			set_cached(layer.draw,layer.draw_values,"admission_visibility",smoothstep(0.0,1.0,float(layer.weight)))
			if layer.weight<=0.0:
				layer.node.queue_free()
				layers.erase(key)

func make_layer(owner_current: Node3D, tuning: VastraParticleSettings) -> Dictionary:
	var node := GPUParticles3D.new()
	node.amount=tuning.heads*(tuning.history_samples+1)
	node.lifetime=3600
	node.explosiveness=1
	node.local_coords=true
	# A transfer contains many transparent strips at different depths. Index order
	# can composite a distant wake over a nearer head as the camera orbits.
	node.draw_order=GPUParticles3D.DRAW_ORDER_VIEW_DEPTH
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
	# Composite after ordinary transparent scenery, while retaining the shader's
	# depth test against opaque/cutout scenery in front of the actual strip.
	draw.render_priority=10
	draw.shader=preload("res://shaders/vastra_particle_lab_draw.gdshader")
	draw.set_shader_parameter("use_live_path",true)
	draw.set_shader_parameter("transfer_packet",true)
	draw.set_shader_parameter("admission_visibility",0.0)
	draw.set_shader_parameter("tint",Color.WHITE)
	draw.set_shader_parameter("field_noise",owner_current.optical_noise)
	var mesh: ArrayMesh=preload("res://scripts/presentation/vastra_filament_mesh.gd").create()
	mesh.surface_set_material(0,draw)
	node.draw_pass_1=mesh
	add_child(node)
	created+=1
	return {"node":node,"motion":motion,"draw":draw,"weight":0.0,"origin":owner_current.batch_origin,"path":PackedVector3Array(),"motion_values":{},"draw_values":{}}

# Runtime edits are compared by value; paused clocks do not resend identical uniforms.
func set_cached(material: ShaderMaterial, values: Dictionary, name: String, value: Variant) -> void:
	if values.has(name) and values[name]==value: return
	values[name]=value
	material.set_shader_parameter(name,value)
	uniform_uploads+=1
