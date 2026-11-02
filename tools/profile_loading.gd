extends SceneTree
## Disposable load study; never reads or overwrites the player's expedition.
var report := {"engine":Engine.get_version_info().string,"display":DisplayServer.get_name(),"scope":"Disposable loading sample; OS and driver caches retained"}
var settle := "--settle" in OS.get_cmdline_user_args()
var drain := "--drain" in OS.get_cmdline_user_args()
func _initialize() -> void:
	report["baked_palette"] = not "--unbaked" in OS.get_cmdline_user_args()
	run.call_deferred()
func run() -> void:
	var started := Time.get_ticks_usec()
	# Include palette/script dependency loading in the resource measurement.
	var library = load("res://scripts/scenery/plant_library.gd")
	library.use_baked_palette = report.baked_palette
	var packed := load("res://scenes/world_3d.tscn") as PackedScene
	report.resource_ms = (Time.get_ticks_usec()-started)/1000.0
	started = Time.get_ticks_usec()
	var scene := packed.instantiate()
	root.add_child(scene)
	report.ready_ms = (Time.get_ticks_usec()-started)/1000.0
	scene.world.smoke_mode = true
	report.initial_chunks = scene.world.chunks.size()
	report.initial_pending = scene.world.pending.size()
	report.initial_ground = scene.streaming_ground.chunks.size()
	DirAccess.make_dir_recursive_absolute("res://artifacts/loading")
	if settle or drain:
		await process_frame
		await process_frame
		if DisplayServer.get_name()!="headless":
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://artifacts/loading/first_view.png")
	started = Time.get_ticks_usec()
	scene.world.rebuild_world()
	report.rebuild_ms = (Time.get_ticks_usec()-started)/1000.0
	# Remove only this profiler-owned fixture, so a failed write cannot reuse it.
	DirAccess.remove_absolute("res://artifacts/loading/disposable.json")
	started = Time.get_ticks_usec()
	scene.world.save_game("res://artifacts/loading/disposable.json")
	report["save_ms"] = (Time.get_ticks_usec()-started)/1000.0
	if not FileAccess.file_exists("res://artifacts/loading/disposable.json"):
		push_error("Disposable loading save was not admitted")
		scene.free()
		quit(1)
		return
	started = Time.get_ticks_usec()
	scene.world.load_game("res://artifacts/loading/disposable.json")
	report.load_ms = (Time.get_ticks_usec()-started)/1000.0
	if settle or drain:
		started=Time.get_ticks_usec()
		var frames := 0
		for frame in range(18000 if drain else 1800):
			if scene.world.pending.is_empty(): break
			await process_frame
			frames += 1
		report.detail_sample_ms=(Time.get_ticks_usec()-started)/1000.0
		report["detail_sample_frames"] = frames
		report.remaining_pending=scene.world.pending.size()
		report["detail_completed"] = scene.world.pending.is_empty()
		if DisplayServer.get_name()!="headless":
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://artifacts/loading/streaming_view.png")
	report.stream_slice_ms=scene.max_stream_slice_ms
	report.chunk_geometry_ms=scene.max_stream_geometry_ms
	report.stream_stages=scene.stream_step_peaks
	report.saved_flora = scene.world.persistent_state.snapshot().flora.nodes.size()
	var output := FileAccess.open("res://artifacts/loading/profile.json",FileAccess.WRITE)
	output.store_string(JSON.stringify(report,"\t"))
	output.close()
	print("LOADING PROFILE ", JSON.stringify(report))
	scene.environment.sky=null
	scene.free()
	quit()
