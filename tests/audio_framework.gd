extends SceneTree
## Silent transport fixtures exercise routing/lifetime without authored or generated sound data.

const Audio = preload("res://scripts/presentation/game_audio.gd")
var checks := 0
var failures := 0

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)

func _initialize() -> void:
	create_timer(120).timeout.connect(func() -> void: quit(1))
	run.call_deferred()

func run() -> void:
	if OS.get_cmdline_user_args().has("--capture-audio-options"):
		root.mode = Window.MODE_WINDOWED
		root.size = Vector2i(1280, 800)
		root.unfocusable = true
	var authored: GameAudioSettings = load("res://resources/audio/game_audio.tres")
	check(authored.valid(), "Authored audio hierarchy admits approved assets and empty slots")
	for cue in authored.cues:
		check(cue.stream == null or cue.stream.get_length() > 0, "Assigned audio decodes to a nonempty stream")
	var tuning: GameAudioSettings = authored.duplicate(true)
	# Transport fixtures stay silent regardless of the project's approved content.
	for cue in tuning.cues:
		cue.stream = null
	tuning.voice_budget = 2
	var shot := GameAudioCue.new()
	shot.key = &"test_shot"
	shot.spatial = true
	shot.cooldown_seconds = 0.5
	# Never push buffers: this is a silent engine transport, not synthesized audio.
	shot.stream = AudioStreamGenerator.new()
	tuning.cues.append(shot)
	var loop := GameAudioCue.new()
	loop.key = &"test_bed"
	loop.category = "Atmosphere"
	loop.looping = true
	loop.stream = shot.stream
	tuning.cues.append(loop)
	var audio := Audio.new()
	audio.preferences_path = "user://audio_framework_test.cfg"
	root.add_child(audio)
	audio.bind(tuning, false)
	check(not audio.play_cue(&"missing") and not audio.play_cue(&"footstep"), "Unknown and unassigned cues fail silently")
	var details := AudioServer.get_bus_index(audio.bus_name("Details"))
	var atmosphere := AudioServer.get_bus_index(audio.bus_name("Atmosphere"))
	check(AudioServer.get_bus_send(details) == "SolHunter", "Child categories route through the root mix")
	audio.set_camera_distance(tuning.close_distance)
	var close_details := AudioServer.get_bus_volume_db(details)
	var close_atmosphere := AudioServer.get_bus_volume_db(atmosphere)
	audio.set_camera_distance((tuning.close_distance + tuning.wide_distance) / 2)
	var middle_details := AudioServer.get_bus_volume_db(details)
	audio.set_camera_distance(tuning.wide_distance)
	check(close_details > middle_details and middle_details > AudioServer.get_bus_volume_db(details), "Detail recedes smoothly while zooming out")
	check(AudioServer.get_bus_volume_db(atmosphere) > close_atmosphere, "Wide zoom brings forward atmosphere")
	audio.set_volume("Details", 0)
	check(AudioServer.is_bus_mute(details), "Zero category volume mutes its descendants")
	audio.set_camera_distance(tuning.close_distance)
	check(AudioServer.is_bus_mute(details), "Zoom cannot override the owner's mute preference")
	audio.set_volume("Details", 80)
	check(audio.play_cue(&"test_shot", Vector3(2, 0, 1)), "Positional request admitted")
	check(audio.voices[0] is AudioStreamPlayer3D and audio.voices[0].bus == audio.bus_name("Details"), "Cue inherits category routing and uses spatial playback")
	check(not audio.play_cue(&"test_shot"), "Shared cue cooldown prevents repeated requests")
	audio.shift_emitters(Vector3(-1, 0, 0))
	check(audio.voices[0].position == Vector3(1, 0, 1), "Spatial emitters follow the world's rebased origin")
	audio.last_played.clear()
	check(audio.play_cue(&"test_shot"), "A second voice fits the parent budget")
	audio.last_played.clear()
	check(not audio.play_cue(&"test_shot"), "Child requests cannot exceed the shared voice budget")
	audio.voices[0].finished.emit()
	check(audio.voices.size() == 1, "Completed one-shots release their budget")
	audio.set_bed("weather", &"test_bed")
	audio.set_bed("unowned_layer", &"test_bed")
	check(not audio.beds.has("unowned_layer"), "Child requests cannot create unbounded continuous layers")
	audio._process(tuning.fade_seconds)
	check(audio.beds.weather.gain == 1, "Continuous bed fades to full level")
	audio.set_bed_level("weather", 0.4)
	audio._process(tuning.fade_seconds)
	check(is_equal_approx(audio.beds.weather.gain, 0.4), "Weather owner can narrow the inherited bed level")
	audio.set_suspended(true)
	check(audio.voices.is_empty() and audio.beds.weather.player.stream_paused, "True pause clears one-shots and holds continuous beds")
	audio.set_suspended(false)
	check(not audio.beds.weather.player.stream_paused, "Resume releases the existing bed")
	audio.set_bed("weather", &"")
	audio._process(tuning.fade_seconds)
	check(audio.beds.weather.outgoing == null, "Replacing with silence releases outgoing playback")
	audio.save_preferences()
	var restored := Audio.new()
	restored.preferences_path = audio.preferences_path
	root.add_child(restored)
	restored.bind(tuning)
	check(restored.volumes.Details == 80, "Audio preferences restore separately from expedition saves")
	audio.save_timer.stop()
	audio.free()
	restored.free()
	DirAccess.remove_absolute("user://audio_framework_test.cfg")
	var invalid: GameAudioSettings = authored.duplicate(true)
	invalid.cues.append(invalid.cues[0])
	check(not invalid.valid(), "Duplicate cue ownership is rejected")
	invalid = authored.duplicate(true)
	invalid.wide_distance = invalid.close_distance
	check(not invalid.valid(), "Invalid hierarchy mix bounds are rejected")
	var scene: Node3D = load("res://scenes/world_3d.tscn").instantiate()
	root.add_child(scene)
	scene.world.smoke_mode = true
	await process_frame
	var before: Dictionary = scene.world.persistent_state.snapshot()
	check(scene.audio.listener.get_parent() == scene.camera and scene.audio.listener.is_current(), "The active listener is attached to the actual game camera")
	check(scene.get_viewport().audio_listener_enable_3d, "The camera viewport processes positional audio")
	scene.audio._process(0)
	check(scene.world.persistent_state.snapshot() == before, "Audio consumes state without changing gameplay or saves")
	scene.zoom_camera(-1000)
	scene.audio._process(0)
	var near_mix: float = scene.audio.zoom_blend
	scene.zoom_camera(1000)
	scene.audio._process(0)
	check(scene.audio.zoom_blend > near_mix, "Actual camera zoom drives the inherited atmosphere/detail mix")
	check(scene.audio.listener.global_position.is_equal_approx(scene.camera.global_position), "Listener follows the camera through zoom and orbit")
	# Assign only silent test transports, leaving authored cue resources unchanged.
	var footstep: GameAudioCue = shot.duplicate()
	footstep.key = &"footstep"
	scene.audio.cue_index[footstep.key] = footstep
	scene.world.player_step_completed.emit(Vector2i.ZERO, Vector2i(1, 0))
	check(scene.audio.voices.size() == 1, "Completed exploration steps request positional audio")
	scene.world.camera.position += Vector2(32, 0)
	var damage: GameAudioCue = shot.duplicate()
	damage.key = &"combat_damage"
	damage.category = "Combat"
	scene.audio.cue_index[damage.key] = damage
	scene.battles.playback.changed.emit({"kind": "effect", "actor": "ally", "cue": {"kind": "damage", "cell": Vector2i(1, 0), "amount": 1, "affinity": "", "caption": "Transport fixture"}})
	check(scene.audio.voices.size() == 2, "Visible battle playback requests its effect cue")
	var emitted_at: Vector3 = scene.audio.voices[1].position
	scene.audio._process(0)
	check(scene.audio.voices[1].position.is_equal_approx(emitted_at), "New cues after a camera rebase are not shifted a second time")
	scene.world.state_replaced.emit(scene.world.persistent_state)
	check(scene.audio.voices.is_empty(), "State replacement discards sounds from the old expedition")
	scene.world.menu.open("options")
	var slider: HSlider = find_slider(scene.world.menu.frame, "Details volume")
	check(slider != null, "Options exposes category volume controls through the existing menu")
	if slider != null:
		slider.value = 31
		check(scene.audio.volumes.Details == 31 and scene.audio.volumes.Atmosphere != 31, "Options control changes its own category")
	if OS.get_cmdline_user_args().has("--capture-audio-options"):
		for frame in range(5):
			await process_frame
		await RenderingServer.frame_post_draw
		check(root.get_texture().get_image().save_png("res://artifacts/audio-options.png") == OK, "Rendered audio Options capture saved")
	# Do not let test UI changes overwrite the user's local audio preferences.
	scene.audio.save_timer.stop()
	scene.free()
	await process_frame
	print("AUDIO FRAMEWORK: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func find_slider(node: Node, label: String) -> HSlider:
	if node is HSlider and node.get_meta("pad_label", "") == label:
		return node
	for child in node.get_children():
		var found := find_slider(child, label)
		if found != null:
			return found
	return null
