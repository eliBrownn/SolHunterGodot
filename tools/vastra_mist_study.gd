extends RefCounted
## Bounded art patch in the existing exploration fixture; no runtime adoption.
const Flow = preload("res://scripts/presentation/vastra_mist_flow.gd")
const DIRECTORY := "res://artifacts/vastra-mist"
const FPS := 30
const FRAMES := 420
const PARTICLES := 1400
var anchors := PackedVector3Array()
var sizes := PackedFloat32Array()
var floors := PackedFloat32Array()
var floor_grid := PackedFloat32Array()
const FLOOR_SIZE := Vector2i(41, 29)
const FLOOR_CELL := 0.25
var origin := Vector3.ZERO
var solve_times: Array[float] = []
var upload_times: Array[float] = []

func route(t: float) -> Vector3:
	# Idle, walk through, stop, run back, turn, return and settle.
	if t < 1.0: return Vector3(-2.5, 0, 0)
	if t < 5.0: return Vector3(lerpf(-2.5, 2.5, (t - 1.0) / 4.0), 0, 0)
	if t < 6.0: return Vector3(2.5, 0, 0)
	if t < 8.0: return Vector3(lerpf(2.5, -2.5, (t - 6.0) / 2.0), 0, 0.45 * sin((t - 6.0) * PI))
	if t < 10.0:
		var angle := (t - 8.0) * PI * 0.5
		return Vector3(-2.5 + 0.75 * sin(angle), 0, 0.75 - 0.75 * cos(angle))
	if t < 12.0: return Vector3(lerpf(-2.5, 0.0, (t - 10.0) / 2.0), 0, 1.5)
	return Vector3(0, 0, 1.5)

func distribution(values: Array[float]) -> Dictionary:
	var sorted := values.duplicate()
	sorted.sort()
	return {"p50_ms": sorted[int(sorted.size() * 0.5)], "p95_ms": sorted[int(sorted.size() * 0.95)], "p99_ms": sorted[int(sorted.size() * 0.99)], "max_ms": sorted.back()}

func make_patch(scene: Node3D, terrain: WorldTerrain, floating: Vector3) -> MultiMeshInstance3D:
	# Conservative four-corner floor lookup over the whole displaced patch.
	# This cache belongs to the disposable fixture, never to terrain generation.
	for z in range(FLOOR_SIZE.y):
		for x in range(FLOOR_SIZE.x):
			floor_grid.append(terrain.surface_height(Vector2(origin.x - 5 + x * FLOOR_CELL, origin.z - 3.5 + z * FLOOR_CELL)))
	var random := RandomNumberGenerator.new()
	random.seed = 17029
	var batch := MultiMeshInstance3D.new()
	var instances := MultiMesh.new()
	instances.transform_format = MultiMesh.TRANSFORM_3D
	instances.use_colors = true
	instances.use_custom_data = true
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE
	instances.mesh = quad
	instances.instance_count = PARTICLES
	batch.multimesh = instances
	var material := ShaderMaterial.new()
	material.shader = preload("res://shaders/vastra_mist_study.gdshader")
	batch.material_override = material
	batch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	batch.custom_aabb = AABB(origin - floating - Vector3(5, 1, 5), Vector3(10, 5, 10))
	scene.add_child(batch)
	for i in range(PARTICLES):
		var at := origin + Vector3(random.randf_range(-3.5, 3.5), 0, random.randf_range(-2.3, 2.3))
		var floor_y := terrain.surface_height(Vector2(at.x, at.z))
		at.y = floor_y + float([0.18, 0.65, 1.9][i % 3]) + random.randf_range(-0.06, 0.06)
		anchors.append(at)
		floors.append(floor_y)
		sizes.append(random.randf_range(0.25, 0.52))
		instances.set_instance_custom_data(i, Color(random.randf(), 0, 0, 1))
	return batch

func update_patch(batch: MultiMeshInstance3D, flow: RefCounted, floating: Vector3, enabled: bool, seconds: float) -> void:
	for i in range(PARTICLES):
		var at := anchors[i]
		var reading: Vector4 = flow.sample(at) if enabled else Vector4(0, 0, 0, 1)
		var displaced := at + Vector3(reading.x, reading.y, reading.z)
		var floor_at := Vector2i(Vector2((displaced.x - origin.x + 5) / FLOOR_CELL, (displaced.z - origin.z + 3.5) / FLOOR_CELL).floor())
		floor_at = floor_at.clamp(Vector2i.ZERO, FLOOR_SIZE - Vector2i(2, 2))
		var floor_y := maxf(floor_grid[floor_at.y * FLOOR_SIZE.x + floor_at.x], floor_grid[floor_at.y * FLOOR_SIZE.x + floor_at.x + 1])
		floor_y = maxf(floor_y, maxf(floor_grid[(floor_at.y + 1) * FLOOR_SIZE.x + floor_at.x], floor_grid[(floor_at.y + 1) * FLOOR_SIZE.x + floor_at.x + 1]))
		displaced.y = maxf(displaced.y, floor_y + 0.07)
		var edge := 1.0 - smoothstep(2.5, 3.5, absf(at.x - origin.x))
		edge *= 1.0 - smoothstep(1.5, 2.3, absf(at.z - origin.z))
		var color := Color(0.35, 0.85, 0.74, 0.17 * reading.w * edge)
		if i % 3 == 2: color = Color(0.55, 0.7, 0.95, 0.09 * edge * reading.w)
		batch.multimesh.set_instance_transform(i, Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * sizes[i]), displaced - floating))
		batch.multimesh.set_instance_color(i, color)
	batch.material_override.set_shader_parameter("clock_seconds", seconds)

func diagnostic(flow: RefCounted, label: String) -> void:
	var image := Image.create(Flow.SIZE.x * 12, Flow.SIZE.z * 12, false, Image.FORMAT_RGB8)
	for z in range(Flow.SIZE.z):
		for x in range(Flow.SIZE.x):
			var i: int = flow.index(x, 2, z)
			var v: Vector3 = flow.velocity[i]
			var color := Color(clampf(0.5 + v.x * 0.3, 0, 1), flow.density[i], clampf(0.5 + v.z * 0.3, 0, 1))
			image.fill_rect(Rect2i(x * 12, z * 12, 12, 12), color)
	image.save_png(DIRECTORY.path_join(label + "-velocity-density.png"))

func run(tree: SceneTree) -> void:
	DirAccess.make_dir_recursive_absolute(DIRECTORY)
	var scene: Node3D = load("res://scenes/world_3d.tscn").instantiate()
	scene.vastra_settings = load("res://resources/vastra_settings.tres").duplicate(true)
	scene.atmosphere_settings = scene.atmosphere_settings.duplicate(true)
	tree.root.add_child(scene)
	tree.root.mode = Window.MODE_WINDOWED
	tree.root.size = Vector2i(960, 600)
	var world: Node2D = scene.world
	world.smoke_mode = true
	world.new_expedition(17)
	world.hud.hide()
	world.set_process(false)
	for frame in range(75): await tree.process_frame
	scene.process_mode = Node.PROCESS_MODE_DISABLED
	var before: Dictionary = world.persistent_state.snapshot()
	var floating := Vector3(world.camera.position.x / 32.0, 0, world.camera.position.y / 32.0)
	origin = scene.player_visual.position + floating
	origin.y = world.terrain.surface_height(Vector2(origin.x, origin.z))
	scene.camera.position = origin - floating + Vector3(5, 3.5, 6)
	scene.camera.look_at(origin - floating + Vector3(0, 0.5, 0))
	scene.atmosphere_settings.cycle_enabled = false
	scene.atmosphere_settings.starting_phase = 0.5
	scene.atmosphere_settings.weather = "clear"
	scene.apply_atmosphere_settings()
	var patch := make_patch(scene, world.terrain, floating)
	patch.hide()
	for frame in range(3): await tree.process_frame
	await RenderingServer.frame_post_draw
	tree.root.get_texture().get_image().save_png(DIRECTORY.path_join("current-baseline.png"))
	for child in scene.get_children():
		if child.get_script() == preload("res://scripts/presentation/vastra_currents.gd"): child.hide()
	patch.show()
	RenderingServer.viewport_set_measure_render_time(tree.root.get_viewport_rid(), true)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var report := {"scope": "Bounded daytime art study, seed 17, same route/camera; no runtime adoption or device acceptance. Render wait excludes solver/upload/readback; total includes solver/upload/wait, excludes PNG capture. Zero GPU samples mean unavailable.", "grid": [17, 7, 17], "cell_cells": Flow.CELL, "fixed_hz": 30, "max_steps_per_frame": Flow.MAX_STEPS, "field_buffers_bytes": Flow.COUNT * 56, "floor_cache_bytes": FLOOR_SIZE.x * FLOOR_SIZE.y * 4, "particles": PARTICLES, "upload_bytes_per_frame": PARTICLES * 64, "passes": {}}
	var animate := OS.get_cmdline_user_args().has("--animate")
	for mode in ["unforced", "interactive"]:
		var enabled: bool = mode == "interactive"
		var flow := Flow.new()
		flow.reset(origin + route(0))
		solve_times.clear()
		upload_times.clear()
		var frame_times: Array[float] = []
		var total_times: Array[float] = []
		var gpu_times: Array[float] = []
		if animate: DirAccess.make_dir_recursive_absolute(DIRECTORY.path_join(mode))
		for frame in range(FRAMES):
			var seconds := float(frame) / FPS
			var at := origin + route(seconds)
			at.y = world.terrain.surface_height(Vector2(at.x, at.z)) + 0.06
			scene.player_visual.position = at - floating
			var next := origin + route(seconds + 1.0 / FPS)
			var moving := Vector2(next.x - at.x, next.z - at.z).length() > 0.00001
			var animation := ("Running_A" if seconds >= 6 and seconds < 8 else "Walking_A") if moving else "Idle_A"
			if scene.player_visual.animator.current_animation != animation: scene.player_visual.animator.play(animation)
			scene.player_visual.animator.advance(1.0 / FPS)
			if moving: scene.player_visual.model.rotation.y = atan2(next.x - at.x, next.z - at.z)
			var total_began := Time.get_ticks_usec()
			var began := total_began
			if enabled: flow.advance(1.0 / FPS, at)
			solve_times.append(float(Time.get_ticks_usec() - began) / 1000.0)
			began = Time.get_ticks_usec()
			update_patch(patch, flow, floating, enabled, seconds)
			upload_times.append(float(Time.get_ticks_usec() - began) / 1000.0)
			began = Time.get_ticks_usec()
			await tree.process_frame
			await RenderingServer.frame_post_draw
			if frame >= 30:
				total_times.append(float(Time.get_ticks_usec() - total_began) / 1000.0)
				frame_times.append(float(Time.get_ticks_usec() - began) / 1000.0)
				gpu_times.append(RenderingServer.viewport_get_measured_render_time_gpu(tree.root.get_viewport_rid()))
			if animate: tree.root.get_texture().get_image().save_png(DIRECTORY.path_join(mode).path_join("%04d.png" % frame))
			if frame in [90, 147, 225, 330, 419]:
				tree.root.get_texture().get_image().save_png(DIRECTORY.path_join("%s-%04d.png" % [mode, frame]))
				if enabled: diagnostic(flow, "%04d" % frame)
		var gpu_available: bool = gpu_times.max() > 0.0
		report.passes[mode] = {"solver": distribution(solve_times.slice(30)), "sample_and_upload": distribution(upload_times.slice(30)), "render_wait": distribution(frame_times), "total_work": distribution(total_times), "gpu_timing_available": gpu_available, "viewport_gpu": distribution(gpu_times) if gpu_available else null, "steps": flow.steps}
		print("MIST STUDY ", mode, ": ", JSON.stringify(report.passes[mode]))
	report["persistent_state_unchanged"] = world.persistent_state.snapshot() == before
	var file := FileAccess.open(DIRECTORY.path_join("performance.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	var unchanged: bool = report.persistent_state_unchanged
	scene.queue_free()
	await tree.process_frame
	tree.quit(0 if unchanged else 1)
