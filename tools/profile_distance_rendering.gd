extends SceneTree
## Isolated paired terrain shader probe, not whole-game FPS or device acceptance.
## Save the prior include under artifacts/distance-optimization before editing it.
var output := "res://artifacts/distance-optimization"
var view: SubViewport
var material := ShaderMaterial.new()
var camera: Camera3D
var reports: Array = []

func _initialize() -> void:
	create_timer(120).timeout.connect(func(): quit(1))
	run.call_deferred()

func shader_for(include_path: String) -> Shader:
	var shader := Shader.new()
	shader.code = "shader_type spatial;\nrender_mode cull_disabled;\n" + FileAccess.get_file_as_string(include_path) + """
uniform vec2 probe_weights = vec2(0.0);
uniform float probe_slope = 0.0;
varying vec3 probe_position;
void vertex() {
 terrain_blend_weights = probe_weights;
 probe_position = (MODEL_MATRIX * vec4(VERTEX,1.0)).xyz;
 terrain_view_direction = CAMERA_POSITION_WORLD - probe_position;
}
void fragment() {
 vec3 n = normalize(vec3(probe_slope,1.0,0.0));
 ALBEDO = terrain_surface(probe_position,n,vec3(0.48,0.57,0.34),probe_weights.y,0.0);
 NORMAL = normalize((VIEW_MATRIX * vec4(terrain_surface_normal(probe_position,n,probe_weights.y),0.0)).xyz);
 ROUGHNESS = 1.0;
}
"""
	return shader

func sample_frames() -> Dictionary:
	for frame in range(45): await process_frame
	var samples: Array[float] = []
	var last := Time.get_ticks_usec()
	var gpu := 0.0
	for frame in range(120):
		await process_frame
		gpu += RenderingServer.viewport_get_measured_render_time_gpu(view.get_viewport_rid()) / 120.0
		var now := Time.get_ticks_usec()
		samples.append((now-last)/1000.0)
		last = now
	samples.sort()
	return {"median_ms":samples[60],"p95_ms":samples[114],"gpu_ms":gpu}

func grass_probe(plane: MeshInstance3D) -> void:
	plane.hide()
	var grass := MultiMeshInstance3D.new()
	var blade := preload("res://scripts/scenery/grass_blade_mesh.gd").create(0.028,0.06)
	var full := ArrayMesh.new()
	full.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,blade.surface_get_arrays(0))
	var grass_material := StandardMaterial3D.new()
	grass_material.albedo_color = Color("67934a")
	grass_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	grass.material_override = grass_material
	grass.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	grass.multimesh = MultiMesh.new()
	grass.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	grass.multimesh.mesh = full
	grass.multimesh.instance_count = 6400
	for index in range(6400):
		grass.multimesh.set_instance_transform(index,Transform3D(Basis.from_scale(Vector3(3,2,3)),Vector3((index%80-40)*0.25,0,(index/80-40)*0.25)))
	view.add_child(grass)
	camera.position = Vector3(0,20,15)
	camera.look_at(Vector3.ZERO)
	var row := {"condition":"grass_geometry","instances":6400}
	for kind in ["before","after"]:
		grass.multimesh.mesh = full if kind=="before" else blade
		row[kind] = await sample_frames()
		row[kind]["primitives"] = Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)
		await RenderingServer.frame_post_draw
		view.get_texture().get_image().save_png(output+"/grass_"+kind+".png")
	reports.append(row)
	print(JSON.stringify(row))
	# Godot's LOD primitive monitor can omit the MultiMesh instance multiplier;
	# retain it as a raw diagnostic, not a submitted-triangle acceptance metric.

func run() -> void:
	Engine.max_fps = 0
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	view = SubViewport.new()
	view.size = Vector2i(1280,800)
	view.own_world_3d = true
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(view)
	RenderingServer.viewport_set_measure_render_time(view.get_viewport_rid(),true)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("b7d4ed")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color.WHITE
	environment.environment.ambient_light_energy = 0.5
	view.add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55,-30,0)
	view.add_child(sun)
	var plane := MeshInstance3D.new()
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(120,120)
	plane.mesh = mesh
	plane.material_override = material
	view.add_child(plane)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 28
	camera.far = 200
	view.add_child(camera)
	var nature: NatureSettings = load("res://resources/nature_biomes.tres")
	var shaders := {"before":shader_for(output+"/terrain_palette_before.gdshaderinc"),"after":shader_for("res://shaders/terrain_palette.gdshaderinc")}
	for condition in [
		{"name":"near_grass","distance":22.0,"weights":Vector2.ZERO,"slope":0.0},
		{"name":"near_blend","distance":22.0,"weights":Vector2(0.4,0.5),"slope":0.8},
		{"name":"far_grass","distance":72.0,"weights":Vector2.ZERO,"slope":0.0},
		{"name":"far_rock","distance":100.0,"weights":Vector2.ZERO,"slope":2.0}]:
		camera.position = Vector3(0,condition.distance*0.8,condition.distance*0.6)
		camera.look_at(Vector3.ZERO)
		var row := {"condition":condition.name}
		for kind in ["before","after"]:
			material.shader = shaders[kind]
			nature.apply_terrain_material(material)
			material.set_shader_parameter("probe_weights",condition.weights)
			material.set_shader_parameter("probe_slope",condition.slope)
			row[kind] = await sample_frames()
			await RenderingServer.frame_post_draw
			view.get_texture().get_image().save_png(output+"/"+condition.name+"_"+kind+".png")
		reports.append(row)
		print(JSON.stringify(row))
	await grass_probe(plane)
	var file := FileAccess.open(output+"/render.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"engine":Engine.get_version_info().string,"resolution":"1280x800","before_sha256":FileAccess.get_sha256(output+"/terrain_palette_before.gdshaderinc"),"after_sha256":FileAccess.get_sha256("res://shaders/terrain_palette.gdshaderinc"),"note":"Uncapped isolated terrain, warm shaders, fixed screen coverage; frame intervals include CPU and GPU. GPU timings are viewport measurements. Raw LOD primitive counters may omit instance multipliers. No whole-game speedup claim.","samples":reports},"\t"))
	view.free()
	quit()
