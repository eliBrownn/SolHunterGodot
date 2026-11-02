extends "res://tools/review_vastra_surfaces.gd"
## Visual examples in the real world scene. The arch/path are explicitly staged;
## they do not register a discovery, add life, or modify expedition state.

func _initialize() -> void:
	if OS.get_cmdline_user_args().has("--mist"):
		create_timer(600).timeout.connect(func() -> void:
			push_error("Mist study timed out")
			quit(1))
		run.call_deferred()
	else:
		super._initialize()

func run() -> void:
	if OS.get_cmdline_user_args().has("--mist"):
		await preload("res://tools/vastra_mist_study.gd").new().run(self)
		return
	directory = "res://artifacts/vastra-exploration"
	DirAccess.make_dir_recursive_absolute(directory)
	var scene: Node3D = load("res://scenes/world_3d.tscn").instantiate()
	scene.vastra_settings = load("res://resources/vastra_settings.tres").duplicate(true)
	scene.atmosphere_settings = scene.atmosphere_settings.duplicate(true)
	root.add_child(scene)
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280, 800)
	var world: Node2D = scene.world
	world.smoke_mode = true
	world.new_expedition(17)
	world.hud.visible = false
	scene.target_size = 11.0
	scene.view_elevation = 28.0
	scene.apply_camera()
	for frame in range(90):
		await process_frame
	scene.process_mode = Node.PROCESS_MODE_DISABLED
	Engine.time_scale = 0.0
	var currents: Node3D
	for child in scene.get_children():
		if child.get_script() == Currents:
			currents = child
			currents.study_mode = true
			currents.mark_dirty()
	if currents == null or currents.living_groups.is_empty():
		push_error("No complete living region for exploration study")
		quit(1)
		return
	var before: Dictionary = world.persistent_state.snapshot()
	var group: Dictionary = currents.living_groups[0]
	for candidate: Dictionary in currents.living_groups:
		if currents.network_nodes.has(candidate.id * 16) and int(candidate.members) > int(group.members):
			group = candidate
	var origin := Vector3(world.camera.position.x / 32.0, 0, world.camera.position.y / 32.0)
	var focus: Vector3 = group.center - origin
	scene.camera.position = focus + Vector3(7, 4.5, 9)
	scene.camera.look_at(focus)
	scene.atmosphere_settings.cycle_enabled = false
	scene.atmosphere_settings.starting_phase = 0.5
	scene.atmosphere_settings.weather = "clear"
	scene.apply_atmosphere_settings()
	currents.material.set_shader_parameter("clock_seconds", 2.0)
	currents.sync_wisps()
	await capture("grove-daylight")
	currents.material.set_shader_parameter("diagnostic_surface", 1)
	await capture("geometry-diagnostic")
	currents.material.set_shader_parameter("diagnostic_surface", 0)
	await profile_field(scene, currents)
	var destination: Vector3 = group.center + Vector3(4, 0, -2)
	# Choose clear ground for the temporary arch; do not plant it around a tree.
	var found := false
	for distance in [4.0, 6.0, 8.0]:
		for angle in range(8):
			var candidate: Vector3 = group.center + Vector3(cos(float(angle) * TAU / 8.0), 0, sin(float(angle) * TAU / 8.0)) * distance
			var clear := true
			for anchor: Vector4 in currents.living_anchors:
				if Vector2(candidate.x - anchor.x, candidate.z - anchor.z).length() < 2.3:
					clear = false
			if clear and world.terrain.surface_normal(Vector2(candidate.x, candidate.z)).y > 0.8:
				destination = candidate
				found = true
				break
		if found:
			break
	destination.y = world.terrain.surface_height(Vector2(destination.x, destination.z))
	var local_destination := destination - origin
	for part in [[Vector3(-0.9, 1.2, 0), Vector3(0.45, 2.4, 0.65)], [Vector3(0.9, 1.2, 0), Vector3(0.45, 2.4, 0.65)], [Vector3(0, 2.5, 0), Vector3(2.35, 0.45, 0.8)]]:
		var stone := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = part[1]
		stone.mesh = mesh
		stone.position = local_destination + part[0]
		var material := StandardMaterial3D.new()
		material.albedo_color = Color("6e7771")
		material.roughness = 0.95
		stone.material_override = material
		scene.add_child(stone)
	var start: Vector3 = group.center - Vector3(3, 0, 0)
	var finish := destination + Vector3(0, 1.0, 0.5)
	var points := PackedVector3Array()
	for i in range(17):
		var t := float(i) / 16.0
		points.append(start.bezier_interpolate(start + Vector3(3, 1, 0), finish - Vector3(2, 0, 0), finish, t))
	var arrays := {"colors": [], "uvs": [], "readings": [], "indices": [], "tile_cache": {}, "field_groups": [group]}
	var saved_vertices: PackedVector3Array = currents.network_vertices.duplicate()
	currents.network_vertices.clear()
	currents.append_surface(points, 0.5, 0.0, start.distance_to(finish), arrays, null)
	var invitation := MeshInstance3D.new()
	invitation.mesh = currents.mesh_from_arrays(arrays)
	invitation.material_override = currents.wisp_material
	invitation.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	currents.add_child(invitation)
	currents.network_vertices = saved_vertices
	focus = (Vector3(group.center) + destination) * 0.5 - origin
	scene.camera.position = focus + Vector3(7, 5, 10)
	scene.camera.look_at(focus)
	await capture("ruin-opening-staged-daylight")
	if not scene.sightings.members.is_empty():
		var sprite: Node3D = scene.sightings.members[0].sprite
		var old_position := sprite.position
		var old_visible := sprite.visible
		var at: Vector3 = points[8]
		at.y = world.terrain.surface_height(Vector2(at.x, at.z))
		sprite.position = at - origin
		sprite.visible = true
		currents.update_sol_voids()
		currents.sync_wisps()
		await capture("sol-clearing-current")
		var frames_dir := directory.path_join("sol-frames")
		DirAccess.make_dir_recursive_absolute(frames_dir)
		for frame in range(32):
			var fraction := float(frame) / 31.0
			sprite.position = at - origin + Vector3(0, 0, lerpf(-3.0, 3.0, fraction))
			currents.material.set_shader_parameter("clock_seconds", 2.0 + fraction * 4.0)
			currents.material.set_shader_parameter("active_seconds", fraction * 4.0)
			currents.update_sol_voids()
			currents.sync_wisps()
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(frames_dir.path_join("%03d.png" % frame))
		sprite.position = old_position
		sprite.visible = old_visible
		currents.update_sol_voids()
		currents.sync_wisps()
	scene.atmosphere_settings.starting_phase = 0.0
	scene.apply_atmosphere_settings()
	currents._process(0.0)
	await capture("ruin-opening-staged-moonlight")
	if world.persistent_state.snapshot() != before:
		push_error("Exploration presentation modified expedition state")
		failures += 1
	print("EXPLORATION REVIEW: staged arch/invitation only; real vegetation and Sol presentation; failures=", failures)
	scene.queue_free()
	await process_frame
	quit(0 if failures == 0 else 1)
