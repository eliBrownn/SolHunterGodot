extends SceneTree
const Ground = preload("res://scripts/presentation/ground_reserve_view.gd")
const Library = preload("res://scripts/scenery/plant_library.gd")
const Chunk = preload("res://scripts/presentation/solid_chunk.gd")
var checks := 0
var failures := 0
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)
func _initialize() -> void: run.call_deferred()

func run() -> void:
	var state := ExpeditionState.new(17)
	state.configure_flora(VastraSettings.new().plant_parameters())
	var definitions: Array[Dictionary] = []
	for y in range(6):
		for x in range(6): definitions.append({"id":AffinityImprint.key(Vector2i(x,y)),"cell":[x,y],"kind":"plant"})
	state.admit_flora(definitions)
	var saved := state.snapshot()
	for row: Dictionary in saved.flora.nodes.values():
		row.energy = float(int(row.cell[0])/2)*50.0
		saved.flora.absorbed += row.energy
	state = ExpeditionState.restore(saved,17)
	check(state != null,"Low/mid/full fixture uses valid conserved canonical reserves")
	var before := state.snapshot()
	var settings := NatureSettings.new()
	var map := Ground.new()
	var material := ShaderMaterial.new()
	material.shader = preload("res://shaders/shore_ground.gdshader")
	settings.apply_terrain_material(material)
	for scan in range(64): map.update(state,Vector2i(3,3),settings)
	for x in [0,2,4]:
		var pixel := Vector2i(x,0)-map.origin
		check(is_equal_approx(map.image.get_pixelv(pixel).g,float(x/2)*0.5),"Ground texture reads its canonical cell reserve")
	check(material.get_shader_parameter("ground_reserve_map") == map.texture,"Ground material consumes the live shared reserve texture")
	var upload_count := map.uploads
	map.update(state,Vector2i(3,3),settings)
	check(map.uploads == upload_count,"Unchanged paused ground does not upload or restart transitions")
	map.update(state,Vector2i(17,3),settings)
	check(is_equal_approx(map.image.get_pixelv(Vector2i(2,0)-map.origin).g,0.5),"Moving the geographic window preserves overlapping cell readings")
	check(state.snapshot() == before,"Leaf/ground presentation never writes energy or admission")
	var chunk := Chunk.new()
	root.add_child(chunk)
	var samples: Array = [Library.foliage_definition(0,1,"emanator",true),Library.procedural_definition(0,{"role":"receiver","class":FloraTraits.CLASSES[0]},0),Library.procedural_definition(0,{"role":"reservoir","class":""},0)]
	for row in range(3):
		var item: Resource = samples[row]
		var model: Dictionary = Library.model(item)
		for column in range(3):
			var cell := Vector2i(column*2,row*2)
			var scale := Vector3.ONE*(0.9/maxf(model.bounds.size.y,0.001))
			var pose := Transform3D(Basis.from_scale(scale),Vector3(cell.x+0.5,-model.bounds.position.y*scale.y,cell.y+0.5))
			chunk.add_composed_nature({"asset":item.plant_id,"model":model,"transform":pose,"bounds":pose*model.bounds,"cell":cell,"category":"detail","living":true,"patch":"authored_plant"})
	var blades := preload("res://scripts/scenery/meadow_art.gd").mesh()
	settings.apply_plant_material(blades.surface_get_material(0))
	Chunk.meshes["meadow_reserve_fixture"] = blades
	var blade_pose := Transform3D(Basis.IDENTITY.scaled(Vector3.ONE*0.5),Vector3(1.5,0,1.5))
	chunk.batches["meadow_reserve_fixture"] = [{"transform":blade_pose,"color":Color("62a54a"),"plant_cell":Vector2i(1,1),"plant_pivot":blade_pose.origin}]
	chunk.finish()
	var projection := preload("res://scripts/presentation/plant_reserve_view.gd").new()
	projection.update(state,{Vector2i.ZERO:chunk},256)
	for cell: Vector2i in chunk.plant_instances:
		var leaf_groups := 0
		for group: Dictionary in chunk.plant_instances[cell].values():
			if group.mesh.use_custom_data:
				leaf_groups += 1
				check(is_equal_approx(group.reserve_transition.g,float(cell.x/2)*0.5),"Grass/plant/tree leaves receive the actual normalized reserve")
		check(leaf_groups > 0,"Each living sample has connected leaf instances")
	check(chunk.plant_instances[Vector2i(1,1)].values()[0].mesh.use_custom_data,"Alternate meadow grass uploads actual reserve instance data")
	check(blades.surface_get_material(0).get_shader_parameter("reserve_droop") == settings.reserve_droop,"Alternate blade grass consumes the shared leaf-lift tuning")
	if DisplayServer.get_name() != "headless":
		await render_missing_cell_regression()
		# The gallery compares the production leaf-grass, plants and tree cards.
		# The optional blade fixture above verifies its uploaded reserve buffer.
		for view in chunk.get_children():
			if view is MultiMeshInstance3D and view.multimesh.mesh == blades: view.hide()
		await render_review(chunk,material,map)
	state.set_flora_active(["0:0"])
	state.advance_time(ExpeditionContract.ACTIVITY_INTERVAL)
	state.advance_flora(func(_cell: Vector2i,_reach: float) -> Array[Dictionary]: return [],func(_cell: Vector2i) -> Dictionary: return {"concentration":100,"overload":0})
	for scan in range(64): map.update(state,Vector2i(17,3),settings)
	var changed := map.image.get_pixelv(-map.origin)
	check(changed.r == 0.0 and changed.g > 0.0 and is_equal_approx(changed.b,state.activity_seconds()),"Absorbed energy starts a ground-color transition from the displayed reserve")
	var same := state.snapshot()
	map.update(state,Vector2i(33,3),settings)
	check(map.image.get_pixelv(-map.origin).is_equal_approx(changed) and state.snapshot() == same,"Window movement preserves an in-progress reserve transition without state writes")
	chunk.free()
	if DisplayServer.get_name() != "headless":
		for frame in range(3): await process_frame
		await RenderingServer.frame_post_draw
	print("LEAF RESERVE LINKS: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)

func render_missing_cell_regression() -> void:
	var viewport := SubViewport.new()
	viewport.size=Vector2i(96,32)
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var shader := Shader.new()
	shader.code='shader_type canvas_item;\n#include "res://shaders/ground_reserve.gdshaderinc"\nvoid fragment() { vec2 at=vec2(floor(UV.x*3.0)*4.0+4.5,4.5); COLOR=vec4(ground_reserve_color(vec3(0.1,0.8,0.2),at,1.0),1.0); }'
	var material := ShaderMaterial.new()
	material.shader=shader
	var readings := Image.create(16,9,false,Image.FORMAT_RGBAF)
	readings.fill(Color(0,0,0,0))
	# Left: depleted turf. Middle: no plant at a rock/road cell, but depleted
	# neighbors two cells away. Right: truly full turf. No simulated nodes added.
	readings.set_pixel(4,4,Color(0,0,-1,1))
	for at in [Vector2i(6,4),Vector2i(10,4),Vector2i(8,2),Vector2i(8,6)]: readings.set_pixelv(at,Color(0,0,-1,1))
	readings.set_pixel(12,4,Color(1,1,-1,1))
	material.set_shader_parameter("ground_reserve_map",ImageTexture.create_from_image(readings))
	material.set_shader_parameter("ground_reserve_enabled",true)
	material.set_shader_parameter("ground_reserve_seconds",10.0)
	var quad := ColorRect.new()
	quad.size=Vector2(96,32)
	quad.material=material
	viewport.add_child(quad)
	for frame in range(4): await process_frame
	await RenderingServer.frame_post_draw
	var picture := viewport.get_texture().get_image()
	var low := picture.get_pixel(16,16)
	var hole := picture.get_pixel(48,16)
	var full := picture.get_pixel(80,16)
	check(absf(low.s-hole.s)<0.03,"Missing rock/road cells inherit nearby depleted pigment instead of full saturation")
	check(full.s-low.s>0.25,"Known low and full grass reserves stay visually distinct")
	DirAccess.make_dir_recursive_absolute("res://artifacts/grass-reserve-blend")
	picture.save_png("res://artifacts/grass-reserve-blend/missing-cell.png")
	viewport.free()

func render_review(chunk: Node3D, material: ShaderMaterial, map: RefCounted) -> void:
	root.size = Vector2i(1100,800)
	var camera := Camera3D.new()
	root.add_child(camera)
	camera.position = Vector3(3,8,10)
	camera.look_at(Vector3(3,0,2.5))
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 8.0
	var light := DirectionalLight3D.new()
	root.add_child(light)
	light.rotation_degrees = Vector3(-60,-25,0)
	var world_environment := WorldEnvironment.new()
	world_environment.environment = Environment.new()
	world_environment.environment.background_mode = Environment.BG_COLOR
	world_environment.environment.background_color = Color("8caaa0")
	world_environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world_environment.environment.ambient_light_color = Color.WHITE
	world_environment.environment.ambient_light_energy = 0.6
	root.add_child(world_environment)
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for point in [Vector3(0,-0.01,0),Vector3(0,-0.01,6),Vector3(6,-0.01,0),Vector3(6,-0.01,0),Vector3(0,-0.01,6),Vector3(6,-0.01,6)]:
		surface.set_normal(Vector3.UP)
		surface.set_uv(Vector2.ZERO)
		surface.set_uv2(Vector2.ZERO)
		surface.set_color(Color.WHITE)
		surface.add_vertex(point)
	var plane := MeshInstance3D.new()
	plane.mesh = surface.commit()
	var white := Image.create(2,2,false,Image.FORMAT_RGBA8)
	white.fill(Color.WHITE)
	material.set_shader_parameter("ground_atlas",ImageTexture.create_from_image(white))
	material.set_shader_parameter("terrain_palette_enabled",false)
	material.set_shader_parameter("ground_base_color",Color("438a30"))
	plane.material_override = material
	root.add_child(plane)
	Library.set_weather(Vector2.ZERO,10.0,0.0)
	material.set_shader_parameter("ground_reserve_seconds",10.0)
	for frame in range(5): await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://artifacts/leaf-reserve")
	root.get_texture().get_image().save_png("res://artifacts/leaf-reserve/low-mid-full.png")
	# Exercise the production terrain palette too: forest soil and blended road
	# shoulders previously exempted the underlying living ground from depletion.
	material.set_shader_parameter("terrain_palette_enabled",true)
	for mask: Vector3 in [Vector3.ZERO,Vector3(0,0.65,1),Vector3(0.4,0,0)]:
		var arrays := surface.commit().surface_get_arrays(0)
		var custom := PackedFloat32Array()
		for index in range(arrays[Mesh.ARRAY_VERTEX].size()): custom.append_array(PackedFloat32Array([mask.x,mask.y,mask.z]))
		arrays[Mesh.ARRAY_CUSTOM0]=custom
		var skin := ArrayMesh.new()
		skin.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays,[],{},Mesh.ARRAY_CUSTOM_RGB_FLOAT<<Mesh.ARRAY_FORMAT_CUSTOM0_SHIFT)
		plane.mesh=skin
		for frame in range(3): await process_frame
		await RenderingServer.frame_post_draw
		var label := "woodland" if mask.z>0 else "road-edge" if mask.x>0 else "meadow"
		root.get_texture().get_image().save_png("res://artifacts/grass-reserve-blend/%s.png"%label)
	world_environment.environment = null
	plane.free()
	world_environment.free()
	light.free()
	camera.free()
	for frame in range(3): await process_frame
	await RenderingServer.frame_post_draw
