extends "res://scripts/presentation/game_audio.gd"
## Consumer of existing simulation/presentation owners; no independent weather or battle rules.

var host: Node3D
var listener := AudioListener3D.new()
var previous_origin := Vector2.ZERO
var menu_open := false

func bind_expedition(scene: Node3D, tuning: GameAudioSettings) -> void:
	host = scene
	bind(tuning)
	process_priority = 10 # After simulation, camera rebasing and atmosphere.
	host.camera.add_child(listener)
	host.get_viewport().audio_listener_enable_3d = true
	listener.make_current()
	previous_origin = host.world.camera.position
	host.world.player_step_completed.connect(on_step)
	host.world.state_replaced.connect(func(_state: ExpeditionState) -> void: clear_shots())
	host.battles.playback.changed.connect(on_resolution)

func cell_position(cell: Vector2i) -> Vector3:
	var relative: Vector2 = (Vector2(cell) * 32.0 + Vector2(16, 16) - host.world.camera.position) / 32.0
	return Vector3(relative.x, host.ground_height(Vector2(cell) + Vector2(0.5, 0.5)) + 0.1, relative.y)

func on_step(_from: Vector2i, to: Vector2i) -> void:
	sync_origin()
	play_cue(&"footstep", cell_position(to))

func on_resolution(step: Dictionary) -> void:
	sync_origin()
	# Playback emits one visible cause at a time, unlike eagerly resolved combat rules.
	var cue: Dictionary = step.get("cue", {})
	if not cue.is_empty():
		var key := StringName("combat_" + str(cue.get("kind", "effect")))
		play_cue(key, cell_position(cue.get("cell", host.world.cell)))
	elif step.get("kind") == "outcome":
		play_cue(&"combat_outcome")

func sync_origin() -> void:
	var origin: Vector2 = host.world.camera.position
	var shift := (previous_origin - origin) / 32.0
	shift_emitters(Vector3(shift.x, 0, shift.y))
	previous_origin = origin

func _process(delta: float) -> void:
	if host == null:
		return
	sync_origin()
	var origin: Vector2 = host.world.camera.position
	var focus: Vector3 = host.camera_focus
	focus.y = host.ground_height(origin / 32.0 + Vector2(focus.x, focus.z))
	set_camera_distance(host.camera.position.distance_to(focus))
	var in_battle: bool = host.battles.session != null
	set_suspended(host.world.paused and not in_battle)
	set_bed("music", &"music_combat" if in_battle else &"music_exploration")
	set_bed("atmosphere", &"ambience_refuge" if host.world.terrain.is_camp(host.world.cell) else &"ambience_wilds")
	set_bed("detail", &"foliage_detail")
	var rain := 0.0
	if "atmosphere_controller" in host and host.atmosphere_controller != null:
		rain = host.atmosphere_controller.rain_strength
	set_bed("weather", &"weather_rain" if rain > 0 else &"")
	set_bed_level("weather", rain)
	if menu_open != host.world.menu.opened:
		menu_open = host.world.menu.opened
		play_cue(&"ui_open" if menu_open else &"ui_close")
	super._process(delta)
