extends SceneTree
var checks := 0
var failures := 0
func check(ok: bool, text: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(text)
func _initialize() -> void: run.call_deferred()
func run() -> void:
	var scene = load("res://scenes/world_3d.tscn").instantiate()
	root.add_child(scene)
	scene.world.smoke_mode = true
	var view: View3DSettings = scene.active_view
	check(view.valid(), "New settings validate")
	check(view.vastra_distance == 38.0, "Gameplay Vastra range stays 38 cells")
	check(view.starting_distance == 18.0 and view.maximum_distance == 26.0, "Camera fits the near detail range")
	check(view.grass_distance == 26.0 and view.detail_distance == 32.0 and view.tree_distance == 72.0, "Near detail and long tree horizon have distinct owners")
	view.zoom_enabled = false
	var distance: float = scene.target_size
	scene.zoom_camera(3.0)
	check(scene.target_size == distance, "Disabling zoom holds the current distance")
	view.zoom_enabled = true
	scene.zoom_camera(100.0)
	check(scene.target_size == 26.0, "Enabled zoom respects the adjusted maximum")
	scene.zoom_camera(-100.0)
	check(scene.target_size == view.minimum_distance, "Close zoom remains available")
	scene.reset_camera()
	var saved_chunks: Dictionary = scene.solid_chunks
	scene.solid_chunks = {}
	var nodes: Array[Node3D] = []
	for index in range(3):
		var chunk := Node3D.new()
		scene.add_child(chunk)
		chunk.global_position = scene.camera.global_position + Vector3(0,-scene.camera.global_position.y,[0,36,64][index])
		var mesh := MeshInstance3D.new()
		mesh.name = "nature_tree_test"
		mesh.mesh = BoxMesh.new()
		chunk.add_child(mesh)
		scene.solid_chunks[Vector2i(index,0)] = chunk
		nodes.append(chunk)
	scene.update_scenery_tiers()
	for index in range(3):
		check(is_equal_approx(nodes[index].get_child(0).lod_bias,[1.0,0.5,0.25][index]), "Distance selects the expected native LOD tier")
		check(nodes[index].get_child(0).cast_shadow == (GeometryInstance3D.SHADOW_CASTING_SETTING_ON if index==0 else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF), "Only near scenery casts detailed shadows")
	# Moving a distant chunk back must restore original detail and shadow policy.
	nodes[2].global_position = nodes[0].global_position
	scene.update_scenery_tiers()
	check(nodes[2].get_child(0).cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_ON and nodes[2].get_child(0).lod_bias == 1.0, "Returning near restores original presentation")
	scene.solid_chunks = saved_chunks
	for node in nodes: node.free()
	var menu = scene.world.menu
	menu.preferences_path = "user://distance-tier-options.cfg"
	menu.open("options")
	var toggle = menu.frame.find_child("CameraZoom",true,false)
	check(toggle != null, "Options exposes camera zoom")
	if toggle != null:
		toggle.button_pressed = false
		check(not scene.active_view.zoom_enabled, "Options toggle is wired live")
		menu.save_preferences()
		scene.active_view.zoom_enabled = true
		check(menu.load_preferences() and not scene.active_view.zoom_enabled, "Zoom preference is remembered locally")
	menu.close()
	if DisplayServer.get_name() != "headless":
		for frame in range(120): await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://artifacts/distance-tiers/world.png")
		menu.open("options")
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://artifacts/distance-tiers/options.png")
	print("DISTANCE TIERS: ",checks," checks, ",failures," failures")
	scene.free()
	quit(0 if failures==0 else 1)
