extends SceneTree
const Builder=preload("res://scripts/scenery/plant_vastra_anatomy_mesh.gd")
func _initialize() -> void: run.call_deferred()
func run() -> void:
	root.size=Vector2i(1600,1000)
	var stage:=Node3D.new()
	root.add_child(stage)
	var environment:=WorldEnvironment.new()
	environment.environment=Environment.new()
	environment.environment.background_mode=Environment.BG_COLOR
	environment.environment.background_color=Color("25383b")
	environment.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_energy=0.8
	stage.add_child(environment)
	var sun:=DirectionalLight3D.new()
	sun.rotation_degrees=Vector3(-45,-30,0)
	sun.light_energy=1.2
	stage.add_child(sun)
	var camera:=Camera3D.new()
	stage.add_child(camera)
	camera.position=Vector3(4.5,6,14)
	camera.look_at(Vector3(4.5,2,0))
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	camera.size=14
	var builder:=Builder.new()
	var settings: Dictionary={"branches":6,"foliage":1.25,"node_count":5,"tree_fork_depth":2,"branching_depth":1,"foliage_fullness":1.5,"color_diversity":0.0,"spread_ratio":1.2}
	for index in range(2):
		settings["tree_leaf_cards"]=index==1
		var sample: Dictionary=builder.create_sample(0,1,73,settings,builder.make_anatomy_materials())
		var node:=Node3D.new()
		stage.add_child(node)
		node.position.x=index*9.0
		for mesh: ArrayMesh in [sample.body,sample.anatomy]:
			var part:=MeshInstance3D.new()
			part.mesh=mesh
			node.add_child(part)
		if "--vastra-routes" in OS.get_cmdline_user_args():
			var renderer = preload("res://scripts/presentation/vastra_currents.gd").new()
			var organs := {}
			for organ: Dictionary in sample.organs + sample.leaf_surfaces:
				organs[organ.id] = {"position":organ.position,"parent":organ.parent}
			var lines := ImmediateMesh.new()
			var ink := StandardMaterial3D.new()
			ink.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			ink.vertex_color_use_as_albedo = true
			ink.no_depth_test = true
			lines.surface_begin(Mesh.PRIMITIVE_LINES, ink)
			for endpoint: String in organs:
				if not endpoint.begins_with("leaf_") and not endpoint.begins_with("root"): continue
				var route: PackedVector3Array = renderer.organ_route({"organs":organs},endpoint)
				var leaf := endpoint.begins_with("leaf_")
				lines.surface_set_color(Color("ffe08a") if leaf else Color("71e6cf"))
				route.append(route[-1] + (Vector3.UP * 0.6 if leaf else Vector3(route[-1].x,0,route[-1].z).normalized() * 1.5))
				for point in range(1,route.size()):
					lines.surface_add_vertex(route[point-1])
					lines.surface_add_vertex(route[point])
			lines.surface_end()
			var overlay := MeshInstance3D.new()
			overlay.mesh = lines
			node.add_child(overlay)
			for child in [renderer.batch,renderer.wisp_batch,renderer.particle_batch,renderer.previous_batch,renderer.previous_wisps,renderer.heatmap_batch]: child.free()
			renderer.free()
		var label:=Label3D.new()
		label.text="MESH LEAVES" if index==0 else "SHADER LEAF CARDS"
		label.position=node.position+Vector3(0,-0.5,0)
		label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
		label.pixel_size=0.008
		stage.add_child(label)
	for frame in range(12): await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://artifacts/tree-leaf-cards")
	root.get_texture().get_image().save_png("res://artifacts/tree-leaf-cards/vastra-routes.png" if "--vastra-routes" in OS.get_cmdline_user_args() else "res://artifacts/tree-leaf-cards/comparison.png")
	stage.free()
	quit()
