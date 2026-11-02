extends SceneTree
## Render the production shoreline shader around the packed cliff-flag boundary.
var failures := 0
func _initialize() -> void:
	create_timer(30).timeout.connect(func(): quit(1))
	run.call_deferred()
func run() -> void:
	if DisplayServer.get_name()=="headless":
		push_error("Terrain flag shading requires a real rendering driver")
		quit(1)
		return
	var stage:=Node3D.new()
	root.add_child(stage)
	var environment:=WorldEnvironment.new()
	environment.environment=Environment.new()
	environment.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color=Color.WHITE
	environment.environment.ambient_light_energy=1.0
	stage.add_child(environment)
	var camera:=Camera3D.new()
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	camera.size=6.0
	stage.add_child(camera)
	camera.position=Vector3(0,10,0)
	camera.look_at(Vector3.ZERO,Vector3.FORWARD)
	camera.current=true
	var image:=Image.create(1,1,false,Image.FORMAT_RGB8)
	image.fill(Color.WHITE)
	var material:=ShaderMaterial.new()
	material.shader=load("res://shaders/shore_ground.gdshader")
	material.set_shader_parameter("terrain_palette_enabled",false)
	material.set_shader_parameter("ground_atlas",ImageTexture.create_from_image(image))
	material.set_shader_parameter("ground_base_color",Color(0.05,0.8,0.05))
	material.set_shader_parameter("ground_texture_strength",0.0)
	material.set_shader_parameter("wet_bank_color",Color(0.8,0.05,0.05))
	material.set_shader_parameter("dry_bank_color",Color(0.8,0.05,0.05))
	var flags: Array[float]=[2.0-0.000001,2.0,2.0+0.000001,3.0-0.000001,3.0,3.0+0.000001]
	for index in range(flags.size()):
		var quad:=PlaneMesh.new()
		quad.size=Vector2(0.8,0.8)
		var arrays:=quad.surface_get_arrays(0)
		arrays[Mesh.ARRAY_TEX_UV2]=PackedVector2Array([Vector2(100,flags[index]),Vector2(100,flags[index]),Vector2(100,flags[index]),Vector2(100,flags[index])])
		var mesh:=ArrayMesh.new()
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
		var tile:=MeshInstance3D.new()
		tile.mesh=mesh
		tile.material_override=material
		tile.position.x=float(index)-2.5
		stage.add_child(tile)
	for frame in range(4): await process_frame
	await RenderingServer.frame_post_draw
	var result:=root.get_texture().get_image()
	result.save_png("res://artifacts/cliff-fix/flag-test.png")
	for index in range(flags.size()):
		var pixel:=Vector2i(camera.unproject_position(Vector3(float(index)-2.5,0,0))*Vector2(result.get_size())/root.get_visible_rect().size)
		var color:=result.get_pixelv(pixel)
		var correct: bool=(color.g>0.2 and absf(color.r-color.g)<0.08 and absf(color.b-color.g)<0.08) if index<3 else color.r>color.g*2.0
		if not correct:
			failures+=1
			push_error("Packed flag %s incorrectly shades as %s"%[flags[index],color])
	print("TERRAIN FLAG SHADING: 6 checks, %d failures"%failures)
	stage.free()
	quit(0 if failures==0 else 1)
