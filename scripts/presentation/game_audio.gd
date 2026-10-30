extends Node
## Root mix -> category buses -> cue trim. Scene-owned; never writes expedition state.

const ROOT_BUS := "SolHunter"
const BED_LAYERS := ["music", "atmosphere", "detail", "weather"]
var settings: GameAudioSettings
var cue_index: Dictionary = {}
var volumes: Dictionary = {}
var voices: Array[Node] = []
var beds: Dictionary = {}
var last_played: Dictionary = {}
var preferences_path := "user://audio_preferences.cfg"
var save_timer := Timer.new()
var zoom_blend := 0.0
var suspended := false

func bind(tuning: GameAudioSettings, load_preferences: bool = true) -> void:
	settings = tuning if tuning != null and tuning.valid() else GameAudioSettings.new()
	if settings != tuning:
		push_warning("Invalid audio settings; using silent default audio policy.")
	for cue in settings.cues:
		cue_index[cue.key] = cue
	ensure_bus(ROOT_BUS, "Master")
	volumes["Master"] = settings.master_volume
	for category: String in GameAudioSettings.CATEGORIES:
		ensure_bus(bus_name(category), ROOT_BUS)
		volumes[category] = settings.get(category.to_lower() + "_volume")
	if load_preferences:
		var config := ConfigFile.new()
		if config.load(preferences_path) == OK:
			for category: String in volumes:
				var value: Variant = config.get_value("volume", category, volumes[category])
				if (value is float or value is int) and is_finite(float(value)):
					volumes[category] = clampf(float(value), 0, 100)
	add_child(save_timer)
	save_timer.one_shot = true
	save_timer.wait_time = 0.4
	save_timer.timeout.connect(save_preferences)
	apply_volumes()

func bus_name(category: String) -> String:
	return ROOT_BUS if category == "Master" else ROOT_BUS + category

func ensure_bus(bus: String, parent: String) -> void:
	if AudioServer.get_bus_index(bus) < 0:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, bus)
	AudioServer.set_bus_send(AudioServer.get_bus_index(bus), parent)

func set_volume(category: String, percent: float) -> void:
	if not volumes.has(category) or not is_finite(percent):
		return
	volumes[category] = clampf(percent, 0, 100)
	apply_volumes()
	save_timer.start()

func apply_volumes() -> void:
	for category: String in volumes:
		var gain := float(volumes[category]) / 100.0
		if category == "Atmosphere":
			gain *= lerpf(settings.close_atmosphere_gain, 1.0, zoom_blend)
		elif category == "Details":
			gain *= lerpf(1.0, settings.wide_detail_gain, zoom_blend)
		var index := AudioServer.get_bus_index(bus_name(category))
		AudioServer.set_bus_volume_db(index, linear_to_db(maxf(gain, 0.0001)))
		AudioServer.set_bus_mute(index, gain <= 0)

func set_camera_distance(distance: float) -> void:
	if not is_finite(distance):
		return
	var blend := smoothstep(settings.close_distance, settings.wide_distance, distance)
	if is_equal_approx(blend, zoom_blend):
		return
	zoom_blend = blend
	apply_volumes()

func play_cue(key: StringName, at: Vector3 = Vector3.ZERO) -> bool:
	var cue: GameAudioCue = cue_index.get(key)
	if cue == null or cue.stream == null or cue.looping or (suspended and cue.category != "UI"):
		return false
	var now := Time.get_ticks_msec() / 1000.0
	if voices.size() >= settings.voice_budget or now - float(last_played.get(key, -1000.0)) < cue.cooldown_seconds:
		return false
	var player: Node = AudioStreamPlayer3D.new() if cue.spatial else AudioStreamPlayer.new()
	player.stream = cue.stream
	player.bus = bus_name(cue.category)
	player.volume_db = cue.volume_db
	add_child(player)
	if player is AudioStreamPlayer3D:
		player.position = at
		player.max_distance = cue.max_distance
	voices.append(player)
	last_played[key] = now
	player.finished.connect(func() -> void:
		voices.erase(player)
		player.queue_free(), CONNECT_ONE_SHOT)
	player.play()
	return true

func set_bed(layer: String, key: StringName) -> void:
	# Each layer owns at most one incoming and one outgoing voice.
	if layer not in BED_LAYERS:
		return
	if beds.has(layer) and beds[layer].key == key:
		return
	var old: Dictionary = beds.get(layer, {})
	if not old.is_empty() and old.outgoing != null:
		old.outgoing.queue_free()
	var outgoing: AudioStreamPlayer = old.get("player")
	var cue: GameAudioCue = cue_index.get(key)
	var player: AudioStreamPlayer
	if cue != null and cue.stream != null and cue.looping:
		player = AudioStreamPlayer.new()
		player.stream = cue.stream
		player.bus = bus_name(cue.category)
		player.volume_db = -80
		add_child(player)
		player.finished.connect(player.play)
		player.play()
		player.stream_paused = suspended
	beds[layer] = {"key": key, "player": player, "outgoing": outgoing, "gain": 0.0, "level": 1.0, "out_gain": float(old.get("gain", 0.0)), "out_trim": float(old.get("trim", 1.0)), "trim": db_to_linear(cue.volume_db) if cue != null else 1.0}

func set_bed_level(layer: String, level: float) -> void:
	if beds.has(layer) and is_finite(level):
		beds[layer].level = clampf(level, 0, 1)

func set_suspended(value: bool) -> void:
	if suspended == value:
		return
	suspended = value
	clear_shots()
	for bed: Dictionary in beds.values():
		for player in [bed.player, bed.outgoing]:
			if player != null:
				player.stream_paused = value

func clear_shots() -> void:
	for player in voices:
		player.stop()
		player.queue_free()
	voices.clear()
	last_played.clear()

func shift_emitters(offset: Vector3) -> void:
	for player in voices:
		if player is AudioStreamPlayer3D:
			player.position += offset

func _process(delta: float) -> void:
	if settings == null or suspended:
		return
	var step := delta / settings.fade_seconds if settings.fade_seconds > 0 else 1.0
	for bed: Dictionary in beds.values():
		bed.gain = move_toward(bed.gain, bed.level, step)
		if bed.player != null:
			bed.player.volume_db = linear_to_db(maxf(0.0001, bed.gain * bed.trim))
		if bed.outgoing != null:
			bed.out_gain = move_toward(bed.out_gain, 0.0, step)
			# Preserve the outgoing cue's trim rather than adopting the next cue's trim.
			bed.outgoing.volume_db = linear_to_db(maxf(0.0001, bed.out_gain * bed.out_trim))
			if bed.out_gain <= 0:
				bed.outgoing.queue_free()
				bed.outgoing = null

func save_preferences() -> void:
	var config := ConfigFile.new()
	for category: String in volumes:
		config.set_value("volume", category, volumes[category])
	if config.save(preferences_path) != OK:
		push_warning("Audio preferences could not be saved.")

func _exit_tree() -> void:
	if not save_timer.is_stopped():
		save_preferences()
