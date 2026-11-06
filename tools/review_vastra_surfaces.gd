extends SceneTree
## Disposable visual fixture. Never reads or writes player expedition saves.
const Currents = preload("res://scripts/presentation/vastra_currents.gd")
var failures := 0
var density_coverage := 0.0
var measured_gpu := 0.0
var measured_cpu := 0.0
var directory := "res://artifacts/vastra-foundation"

func _initialize() -> void:
	create_timer(90).timeout.connect(func() -> void: quit(1))
	run.call_deferred()

func capture(label: String) -> Image:
	root.title = "Vastra automated comparison: " + label
	for frame in range(3):
		await process_frame
	await RenderingServer.frame_post_draw
	var result := root.get_texture().get_image()
	result.save_png(directory.path_join(label + ".png"))
	if label == "geometry-diagnostic":
		var covered := 0
		var samples := 0
		for y in range(0, result.get_height(), 2):
			for x in range(0, result.get_width(), 2):
				var color := result.get_pixel(x, y)
				samples += 1
				if color.r > color.g + 0.235 and color.b > color.g + 0.235:
					covered += 1
		density_coverage = 100.0 * float(covered) / float(samples)
	print("Captured " + label)
	return result

func frame_cost() -> float:
	for frame in range(8):
		await process_frame
		await RenderingServer.frame_post_draw
	measured_gpu = 0.0
	measured_cpu = 0.0
	var began := Time.get_ticks_usec()
	for frame in range(24):
		await process_frame
		await RenderingServer.frame_post_draw
		measured_gpu += RenderingServer.viewport_get_measured_render_time_gpu(root.get_viewport_rid()) / 24.0
		measured_cpu += RenderingServer.viewport_get_measured_render_time_cpu(root.get_viewport_rid()) / 24.0
	return float(Time.get_ticks_usec() - began) / 24000.0

func profile_field(_scene: Node3D, currents: Node3D) -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	RenderingServer.viewport_set_measure_render_time(root.get_viewport_rid(), true)
	var report := {"viewport": [root.size.x, root.size.y], "scope": "Development desktop, warmed 24-frame windows; no device acceptance"}
	for mode in ["disabled", "density", "wisps", "particles", "combined"]:
		currents.batch.visible = mode in ["density", "combined"]
		currents.wisp_batch.visible = mode in ["wisps", "combined"]
		currents.particle_batch.visible = mode in ["particles", "combined"]
		await frame_cost()
		var frame_ms := await frame_cost()
		report[mode] = {"frame_ms": frame_ms, "viewport_gpu_ms": measured_gpu, "viewport_cpu_ms": measured_cpu}
	currents.batch.visible = true
	currents.wisp_batch.visible = true
	currents.particle_batch.visible = true
	var began := Time.get_ticks_usec()
	for iteration in range(8):
		currents.refresh()
	report["rebuild_mean_ms"] = float(Time.get_ticks_usec() - began) / 8000.0
	currents.finish_transition()
	currents.sync_wisps()
	report["density_vertices"] = currents.network_vertices.size()
	report["wisp_vertices"] = currents.wisp_batch.mesh.surface_get_array_len(0)
	report["density_shell_raster_coverage_percent"] = density_coverage
	report["coverage_scope"] = "Sampled density silhouette union, not summed transparent overdraw"
	report["regions"] = mini(currents.living_groups.size(), currents.tuning.current_region_limit)
	var output := FileAccess.open(directory.path_join("performance.json"), FileAccess.WRITE)
	output.store_string(JSON.stringify(report, "\t"))
	print("Vastra profile: " + JSON.stringify(report))

func run() -> void:
	if OS.get_cmdline_user_args().has("--streaming-profile"):
		DirAccess.make_dir_recursive_absolute("res://artifacts/streaming-motion")
		profile_streaming()
		return
	print("VASTRA SURFACES: preparing read-only visual study")
	DirAccess.make_dir_recursive_absolute(directory)
	var scene: Node3D = load("res://scenes/world_3d.tscn").instantiate()
	scene.vastra_settings = load("res://resources/vastra_settings.tres").duplicate(true)
	root.add_child(scene)
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280, 800)
	var world: Node2D = scene.world
	world.smoke_mode = true
	world.new_expedition(17)
	scene.target_size = 11.0
	scene.view_elevation = 28.0
	scene.apply_camera()
	for frame in range(120):
		await process_frame
	scene.process_mode = Node.PROCESS_MODE_DISABLED
	Engine.time_scale = 0.0 # Freeze foliage TIME too, so disabled comparisons isolate Vastra.
	world.hud.visible = false
	var currents: Node3D
	for child in scene.get_children():
		if child.get_script() == Currents:
			currents = child
			currents.study_mode = true
			currents.mark_dirty()
	# A known concentration peak gives the eye a repeatable destination.
	for y in range(-16, 17):
		for x in range(-16, 17):
			var cell: Vector2i = world.cell + Vector2i(x, y)
			var concentration := roundi(12.0 + 82.0 * exp(-Vector2(x - 4, y).length_squared() / 45.0))
			world.persistent_state.set_environment(cell, {"concentration": concentration})
	var fixture: Dictionary = world.persistent_state.snapshot()
	for y in range(-16, 17):
		for x in range(-16, 17):
			fixture.affinity_tiles[AffinityImprint.key(world.cell + Vector2i(x, y))] = {"affinity": "water" if x < 0 else "fire", "conditions": {}}
	var state := ExpeditionState.restore(fixture, 17)
	if state == null:
		push_error("Vastra optical fixture failed admission")
		quit(1)
		return
	world.replace_persistent_state(state)
	world.state_replaced.emit(state)
	currents._process(0.6)
	currents.finish_transition()
	currents.refresh()
	currents.finish_transition()
	var before: Dictionary = state.snapshot()
	print("Vastra regions=%d, nodes=%d, vegetation=%d, vertices=%d" % [currents.living_groups.size(), currents.network_nodes.size(), currents.living_anchors.size(), currents.network_vertices.size()])
	currents.material.set_shader_parameter("diagnostic_surface", 1)
	await capture("geometry-diagnostic")
	currents.material.set_shader_parameter("diagnostic_surface", 2)
	await capture("opacity-diagnostic")
	currents.material.set_shader_parameter("diagnostic_surface", 0)

	currents.batch.visible = false
	currents.wisp_batch.visible = false
	currents.particle_batch.visible = false
	await capture("disabled")
	currents.batch.visible = true
	currents.wisp_batch.visible = true
	currents.particle_batch.visible = true
	currents.material.set_shader_parameter("active_seconds", 0.0)
	currents.material.set_shader_parameter("clock_seconds", 0.0)
	currents.sync_wisps()
	await capture("default-t0")
	currents.material.set_shader_parameter("active_seconds", 5.0)
	currents.material.set_shader_parameter("clock_seconds", 5.0 * scene.vastra_settings.current_flow_speed)
	currents.sync_wisps()
	await capture("default-t5")
	currents.sync_wisps()
	await capture("combined-t5")
	# Frame an actual destination and put a traveling peak directly at its endpoint.
	var saved_camera: Transform3D = scene.camera.transform
	if not currents.network_edges.is_empty():
		var edge: Dictionary = currents.network_edges[0]
		for candidate: Dictionary in currents.network_edges:
			if not candidate.bridge:
				edge = candidate
				break
		var root_phase: float = maxf(edge.start_phase, edge.end_phase)
		var endpoint: Vector3 = edge.points[0] if edge.start_phase >= edge.end_phase else edge.points[-1]
		var origin := Vector3(world.camera.position.x / 32.0, 0, world.camera.position.y / 32.0)
		var focus := endpoint - origin
		scene.camera.position = focus + Vector3(3.5, 2.2, 4.0)
		scene.camera.look_at(focus)
		var transport_rate: float = 0.35 + scene.vastra_settings.current_wind_velocity.length() * 0.25 + scene.vastra_settings.current_attraction * 0.4
		currents.material.set_shader_parameter("clock_seconds", (root_phase + 0.18) / transport_rate)
		currents.sync_wisps()
		await capture("asset-destination-peak")
		scene.camera.transform = saved_camera
		currents.material.set_shader_parameter("clock_seconds", 5.0 * scene.vastra_settings.current_flow_speed)
		currents.sync_wisps()
	# Match each tier at the middle of a traveling head, then its quiet interval.
	for kind in ["small", "medium", "large"]:
		for edge: Dictionary in currents.network_edges:
			if edge.kind != kind: continue
			var midpoint: Vector3 = edge.points[4]
			var origin := Vector3(world.camera.position.x / 32.0, 0, world.camera.position.y / 32.0)
			var focus := midpoint - origin
			var distance: float = maxf(2.0, edge.points[0].distance_to(edge.points[-1]) * 0.65)
			var travel: Vector3 = edge.points[-1] - edge.points[0]
			var side := Vector3(-travel.z, 0, travel.x).normalized()
			scene.camera.position = focus + side * distance * 1.2 + Vector3.UP * distance * 0.5
			scene.camera.look_at(focus)
			var rate: float = 0.35 + scene.vastra_settings.current_wind_velocity.length() * 0.25 + scene.vastra_settings.current_attraction * 0.4
			var middle_phase: float = (edge.start_phase + edge.end_phase) * 0.5
			currents.material.set_shader_parameter("clock_seconds", (middle_phase + minf(0.18, edge.profile.y * 0.18)) / rate)
			currents.sync_wisps()
			await capture("tier-" + kind + "-peak")
			currents.material.set_shader_parameter("clock_seconds", (middle_phase + edge.profile.x * 0.7) / rate)
			currents.sync_wisps()
			await capture("tier-" + kind + "-quiet")
			print("Tier ", kind, " span=", edge.points[0].distance_to(edge.points[-1]), " destination=", edge.destination_asset.get("id", ""))
			break
	scene.camera.transform = saved_camera
	currents.material.set_shader_parameter("clock_seconds", 5.0 * scene.vastra_settings.current_flow_speed)
	currents.sync_wisps()
	# Same geometry, colors, camera and lighting: isolate the optical contribution.
	currents.material.set_shader_parameter("distortion", 0.0)
	await capture("refraction-disabled")
	currents.material.set_shader_parameter("distortion", scene.vastra_settings.current_distortion)
	currents.material.set_shader_parameter("aberration", 0.0)
	currents.sync_wisps()
	await capture("aberration-disabled")
	currents.material.set_shader_parameter("aberration", scene.vastra_settings.current_aberration)
	currents.sync_wisps()
	if OS.get_cmdline_user_args().has("--profile"):
		await profile_field(scene, currents)
	if OS.get_cmdline_user_args().has("--animate"):
		var frames_dir := directory.path_join("frames")
		DirAccess.make_dir_recursive_absolute(frames_dir)
		for frame in range(360):
			var seconds := float(frame) / 60.0
			currents.material.set_shader_parameter("active_seconds", seconds)
			currents.material.set_shader_parameter("clock_seconds", seconds * scene.vastra_settings.current_flow_speed)
			currents.sync_wisps()
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(frames_dir.path_join("%03d.png" % frame))
	if state.snapshot() != before:
		push_error("Optical review mutated its fixture state")
		failures += 1
	scene.vastra_settings.current_debug_view = 1
	currents._process(0.6)
	await capture("heatmap-concentration")
	scene.vastra_settings.current_debug_view = 2
	currents._process(0.6)
	await capture("heatmap-revealed-field")
	scene.vastra_settings.current_debug_view = 0
	currents._process(0.6)
	# A real presented Sol clears the visual field; its saved identity/position is untouched.
	if not scene.sightings.members.is_empty() and not currents.network_nodes.is_empty():
		var sprite: Node3D = scene.sightings.members[0].sprite
		var original_position := sprite.position
		var original_visible := sprite.visible
		var at: Vector3 = currents.flow_focus
		var origin: Vector2 = world.camera.position / 32.0
		sprite.position = Vector3(at.x - origin.x, at.y, at.z - origin.y)
		sprite.visible = true
		currents.update_sol_voids()
		await capture("sol-dissipation")
		currents.material.set_shader_parameter("sol_count", 0)
		currents.wisp_material.set_shader_parameter("sol_count", 0)
		await capture("sol-dissipation-disabled")
		sprite.position = original_position
		sprite.visible = original_visible
		currents.update_sol_voids()
	var daylight: float = scene.sun.light_energy
	var sun_color: Color = scene.sun.light_color
	for lighting in ["twilight", "night"]:
		scene.sun.light_energy = 0.3 if lighting == "twilight" else 0.0
		scene.sun.light_color = Color(0.7, 0.5, 0.85)
		currents._process(0.0)
		await capture(lighting)
	scene.sun.light_energy = daylight
	scene.sun.light_color = sun_color
	currents._process(0.0)
	scene.view_elevation = 12.0
	scene.apply_camera()
	await capture("side-view")
	scene.view_elevation = 28.0
	scene.apply_camera()
	# Exercise the shared shader's unbatched combat mode as well as the web mode.
	var cue := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(1.25, 0.18)
	cue.mesh = quad
	cue.position = scene.player_visual.position + Vector3(0, 1.0, 0)
	var cue_material := ShaderMaterial.new()
	cue_material.shader = load("res://shaders/vastra_current.gdshader")
	cue_material.set_shader_parameter("current_color", Color("459fe8"))
	cue_material.set_shader_parameter("opacity", 0.3)
	cue.material_override = cue_material
	scene.add_child(cue)
	await capture("combat-mode-regression")
	cue.queue_free()
	if OS.get_cmdline_user_args().has("--slope"):
		var steepest := 1.0
		var target := Vector2i(24, 24)
		for y in range(12, 65, 4):
			for x in range(12, 65, 4):
				var at := Vector2i(x, y)
				if world.terrain.sample(at).ground == WorldTerrain.Ground.WATER:
					continue
				var normal_y: float = world.terrain.surface_normal(Vector2(at) + Vector2(0.5, 0.5)).y
				if normal_y < steepest:
					steepest = normal_y
					target = at
		world.cell = target
		world.rebuild_world()
		scene.apply_camera()
		scene.process_mode = Node.PROCESS_MODE_INHERIT
		world.set_process(false)
		for frame in range(16):
			await process_frame
		scene.process_mode = Node.PROCESS_MODE_DISABLED
		currents._process(0.6)
		currents.finish_transition()
		scene._process(1.0)
		await capture("generated-slope")
		print("Vastra generated-slope review: cell %s, grade %.2f degrees" % [target, rad_to_deg(acos(clampf(steepest, -1, 1)))])
	print("VASTRA SURFACES: captured default evolving surfaces, complementary water/fire fringes, and disabled comparisons; %d failures." % failures)
	scene.queue_free()
	await process_frame
	quit(0 if failures == 0 else 1)

func profile_streaming() -> void:
	var scene: Node3D = load("res://scenes/world_3d.tscn").instantiate()
	root.add_child(scene)
	scene.world.smoke_mode = true
	scene.world.new_expedition(17)
	scene.process_mode = Node.PROCESS_MODE_DISABLED
	var currents: Node3D
	for child in scene.get_children():
		if child.get_script() == Currents:
			currents = child
			currents.study_mode = true
			currents.mark_dirty()
	var costs: Array[float] = []
	var refresh_costs: Array[float] = []
	var started := Time.get_ticks_usec()
	for frame in range(300):
		var began := Time.get_ticks_usec()
		var at := Vector2(0.5 + float(maxi(0, frame - 60)) / 8.0, 0.5)
		scene.world.cell = Vector2i(at.floor())
		scene.world.explorer.position = at * 32.0
		scene.world.camera.position = at * 32.0
		scene.world.plan_chunks()
		scene.world._process(1.0 / 60.0)
		scene._process(1.0 / 60.0)
		var refresh_started := Time.get_ticks_usec()
		currents._process(1.0 / 60.0)
		refresh_costs.append(float(Time.get_ticks_usec() - refresh_started) / 1000.0)
		costs.append(float(Time.get_ticks_usec() - began) / 1000.0)
	costs.sort()
	refresh_costs.sort()
	var report := {"scope":"300 deterministic main-thread updates, 30-cell walk; headless CPU work only, not GPU or displayed FPS", "total_ms":float(Time.get_ticks_usec() - started)/1000.0,"p95_ms":costs[284],"p99_ms":costs[296],"max_ms":costs[-1],"current_p95_ms":refresh_costs[284],"current_max_ms":refresh_costs[-1],"pending":scene.world.pending.size(),"published":scene.solid_chunks.size(),"stream_step_peaks":scene.stream_step_peaks,"refreshes":currents.refresh_count,"current_stages":currents.refresh_stage_peaks}
	var label := "before" if OS.get_cmdline_user_args().has("--before") else "after"
	var file := FileAccess.open("res://artifacts/streaming-motion/" + label + ".json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	print(JSON.stringify(report))
	scene.free()
	quit()
