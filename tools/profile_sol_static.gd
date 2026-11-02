extends SceneTree
## Bounded frozen-world CPU comparison; no player saves or simulation changes.
var report := {}
func _initialize() -> void:
	run.call_deferred()
func run() -> void:
	var label := "before"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--label="): label = arg.trim_prefix("--label=")
	var rendered := OS.get_cmdline_user_args().has("--rendered")
	if rendered:
		root.size = Vector2i(1280, 800)
		Engine.max_fps = 0
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var scene = load("res://scenes/world_3d.tscn").instantiate()
	root.add_child(scene)
	scene.world.smoke_mode = true
	scene.sightings.set_process(false)
	var sightings = scene.sightings
	var saved: Dictionary = scene.world.persistent_state.snapshot()
	var windows: Array = []
	for window in range(6):
		var start := Time.get_ticks_usec()
		for frame in range(240):
			sightings.elapsed += 1.0 / 60.0
			sightings.sync_views(1.0 / 60.0)
		if window > 0: windows.append((Time.get_ticks_usec() - start) / 240000.0)
	var visible := 0
	for member in sightings.members:
		if member.sprite.visible: visible += 1
	report = {"label": label, "engine": Engine.get_version_info().string, "display": DisplayServer.get_name(), "members": sightings.members.size(), "visible": visible, "sync_views_ms_per_call": windows, "state_unchanged": saved == scene.world.persistent_state.snapshot(), "scope": "Frozen startup population; 240 warmup calls then five 240-call CPU windows; no renderer timing or whole-game FPS claim"}
	DirAccess.make_dir_recursive_absolute("res://artifacts/sol-static-presentation")
	var file := FileAccess.open("res://artifacts/sol-static-presentation/" + label + ".json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	if rendered:
		var frames: Array = []
		var sync_costs: Array = []
		var last := Time.get_ticks_usec()
		for frame in range(420):
			await process_frame
			var now := Time.get_ticks_usec()
			if frame >= 120: frames.append((now - last) / 1000.0)
			last = now
			var started := Time.get_ticks_usec()
			sightings.elapsed += 1.0 / 60.0
			sightings.sync_views(1.0 / 60.0)
			if frame >= 120: sync_costs.append((Time.get_ticks_usec() - started) / 1000.0)
		report["viewport_pixels"] = [root.size.x, root.size.y]
		report["rendered_frame_ms"] = frames
		report["rendered_sync_ms"] = sync_costs
		report["rendered_state_unchanged"] = saved == scene.world.persistent_state.snapshot()
		report["rendered_scope"] = "D3D12 Forward+, actual viewport recorded separately; frozen simulation, uncapped/VSync off, 120 warmup then 300 frames, live streaming; one sample per version"
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://artifacts/sol-static-presentation/" + label + ".png")
		file = FileAccess.open("res://artifacts/sol-static-presentation/" + label + ".json", FileAccess.WRITE)
		file.store_string(JSON.stringify(report, "\t"))
		file.close()
	print("STATIC SOL PROFILE ", label, " members=", report.members, " visible=", report.visible, " state_unchanged=", report.state_unchanged)
	scene.free()
	quit(0 if report.state_unchanged and visible > 0 else 1)
