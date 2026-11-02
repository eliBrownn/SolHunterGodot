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

func reset() -> void:
	for layer in layers.values():
		layer.node.hide()
		layer.node.queue_free()
	layers.clear()
	last_seconds = -1.0
	void_signature.clear()
	local_voids.clear()

static func bounds_for_path(points: PackedVector3Array, padding: float) -> AABB:
	if points.is_empty(): return AABB()
	var bounds := AABB(points[0],Vector3.ZERO)
	for point in points: bounds = bounds.expand(point)
	return bounds.grow(padding)

func sync(owner_current: Node3D) -> void:
	var tuning: VastraParticleSettings=owner_current.tuning.particle_filaments
	if tuning==null or not tuning.enabled or not tuning.valid() or owner_current.study_mode or owner_current.tuning.current_debug_view!=0 or not owner_current.tuning.currents_enabled or owner_current.tuning.current_limit==0:
		for layer in layers.values(): layer.node.hide()
		return
	var shape := Vector2i(tuning.heads,tuning.history_samples)
	var view: View3DSettings = owner_current.world.host.get("active_view")
	if shape!=configured:
		for layer in layers.values(): layer.node.queue_free()
		layers.clear()
		configured=shape
	while layers.size() > tuning.transfer_limit * 2:
		var oldest: String = layers.keys()[0]
		layers[oldest].node.queue_free()
		layers.erase(oldest)
	var seen := {}
	var seconds: float=owner_current.state.activity_seconds()
	var optical_packet_size := float(owner_current.state.flora_policy().get("threshold",100.0))
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
		if edge.points.size()<2 or edge.points.size()>64: continue
		if view != null:
			var player: Vector2 = owner_current.world.camera.position / 32.0
			var path_bounds := bounds_for_path(edge.points, view.vastra_distance + 4.0)
			if not Rect2(Vector2(path_bounds.position.x, path_bounds.position.z), Vector2(path_bounds.size.x, path_bounds.size.z)).has_point(player): continue
		var flight: Dictionary=edge.flight
		var key := str(flight.id)+":"+str(flight.sent)
		var admitted := not layers.has(key)
		# Active paths plus one fading generation. Churn cannot accumulate layers.
		if admitted and (layers.size() >= tuning.transfer_limit * 2 or get_child_count() >= tuning.transfer_limit * 2): continue
		seen[key]=true
		if admitted: layers[key]=make_layer(owner_current,tuning)
		var layer: Dictionary=layers[key]
		if not admitted: layer.weight=minf(1.0,float(layer.weight)+delta/ADMISSION_SECONDS)
		layer.node.position=Vector3.ZERO
		set_cached(layer.draw,layer.draw_values,"effect_range",view.vastra_distance if view != null else 0.0)
		set_cached(layer.draw,layer.draw_values,"effect_fade",view.vastra_fade_cells if view != null else 6.0)
		set_cached(layer.draw,layer.draw_values,"admission_visibility",smoothstep(0.0,1.0,float(layer.weight)))
		if edge.points.size()<2 or edge.points.size()>64: continue
		if layer.origin!=owner_current.batch_origin or layer.path!=edge.points:
			layer.origin=owner_current.batch_origin
			layer.path=edge.points.duplicate()
			var points := PackedVector3Array()
			for point in edge.points: points.append(point-Vector3(layer.origin.x,0,layer.origin.y))
			var point_count := points.size()
			var path_length := 0.0
			for index in range(1,point_count): path_length += points[index-1].distance_to(points[index])
			layer["path_length"]=path_length
			# Covers the maximum supported length/thickness, including live edits.
			layer.node.visibility_aabb = bounds_for_path(points,4.0)
			while points.size()<64: points.append(points[-1])
			for pair in [[layer.motion,layer.motion_values],[layer.draw,layer.draw_values]]:
				set_cached(pair[0],pair[1],"live_path_count",point_count)
				set_cached(pair[0],pair[1],"live_path_length",path_length)
				set_cached(pair[0],pair[1],"live_path",points)
				set_cached(pair[0],pair[1],"source_position",points[0])
				set_cached(pair[0],pair[1],"target_position",points[-1])
				set_cached(pair[0],pair[1],"path_width",0.08)
			path_uploads+=1
		var elapsed: float=seconds-float(flight.get("visual_sent",flight.sent))*ExpeditionContract.ACTIVITY_INTERVAL
		# One packet/source phase for all its heads; nearby plants are not forced
		# into a global pulse. This modulates optics, never amount or travel time.
		var phase := float(posmod(hash(flight.get("source",str(flight.id))),4096))/4096.0*TAU
		set_cached(layer.draw,layer.draw_values,"flow_phase",phase)
		set_cached(layer.draw,layer.draw_values,"breathing_strength",tuning.breathing_strength)
		set_cached(layer.draw,layer.draw_values,"breathing_seconds",tuning.breathing_seconds)
		set_cached(layer.draw,layer.draw_values,"intersection_softness",tuning.intersection_softness)
		var threshold: float = optical_packet_size
		set_cached(layer.draw,layer.draw_values,"energy_visibility",sqrt(clampf(float(flight.get("amount",threshold))/threshold,0.0,1.0)))
		var duration: float=float(flight.arrival-flight.sent)*ExpeditionContract.ACTIVITY_INTERVAL
		var release_seconds: float = float(flight.get("release_ticks",0))*ExpeditionContract.ACTIVITY_INTERVAL
		if flight.get("pending",false): elapsed=minf(elapsed,maxf(duration+release_seconds-0.001,0))
		elif flight.has("release_ticks") and flight.has("credited_tick"):
			elapsed=minf(elapsed,duration+release_seconds+maxf(0.0,seconds-float(flight.credited_tick)*ExpeditionContract.ACTIVITY_INTERVAL))
		var strip_seconds: float = duration*tuning.filament_length/maxf(float(layer.get("path_length",0.001)),0.001)
		layer.node.visible=elapsed>=0 and elapsed<=duration+release_seconds+tuning.trail_seconds+strip_seconds and tuning.visibility>0 and tuning.transfer_visibility>0
		set_cached(layer.motion,layer.motion_values,"elapsed",elapsed)
		set_cached(layer.motion,layer.motion_values,"duration",duration)
		set_cached(layer.motion,layer.motion_values,"release_seconds",release_seconds)
		set_cached(layer.motion,layer.motion_values,"head_count",tuning.heads)
		set_cached(layer.motion,layer.motion_values,"filament_length",tuning.filament_length)
		set_cached(layer.motion,layer.motion_values,"trail_seconds",tuning.trail_seconds)
		for pair in [["opacity",tuning.visibility],["visibility_scale",tuning.transfer_visibility],["particle_size",tuning.thickness],["filament_length",tuning.filament_length],["refraction",tuning.refraction],["pulse_strength",tuning.send_pulse_strength],["pulse_amount",exp(-maxf(elapsed,0)/tuning.send_pulse_seconds)],["animation_time",seconds]]:
			set_cached(layer.draw,layer.draw_values,pair[0],pair[1])
		if count!=null: set_cached(layer.draw,layer.draw_values,"sol_count",count)
		if voids!=null: set_cached(layer.draw,layer.draw_values,"sol_voids",local_voids)
	for key in layers.keys():
		set_cached(layers[key].draw,layers[key].draw_values,"effect_range",view.vastra_distance if view != null else 0.0)
		set_cached(layers[key].draw,layers[key].draw_values,"effect_fade",view.vastra_fade_cells if view != null else 6.0)
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
