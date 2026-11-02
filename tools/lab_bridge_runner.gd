extends SceneTree
## Runtime-only owner. The editor receives pixels and sends bounded input events.
const Wire = preload("res://tools/lab_bridge_wire.gd")
const Catalogue = preload("res://tools/lab_station_catalogue.gd")
const Storage = preload("res://tools/lab_bridge_storage.gd")
var wire = Wire.new()
var options := {}
var surface: SubViewport
var host: Control
var active_entry: Dictionary = {}
var authenticated := false
var suspended := false
var capturing := false
var closing := false
var last_input := 0
var dirty := false
var opened_at := 0
var frame_times: Array[float] = []
var last_capture_ms := 0.0
var last_action_ms := 0.0
var dependency_snapshot := ""
var hidden_viewports := {}
var hidden_particles := {}
var hidden_audio := {}
var transport := "jpg"
var held_inputs: Dictionary = {}
var pending_station := ""
var switch_queued := false
var first_tick := true
var recovering := false
var sol_session: Dictionary = {}

func _initialize() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--lab-") and "=" in argument:
			options[argument.get_slice("=", 0)] = argument.substr(argument.find("=") + 1)
	if not options.has("--lab-port") or not options.has("--lab-token"):
		push_error("Lab bridge requires a local editor session.")
		quit(1)
		return
	Engine.max_fps = 60
	Engine.set_meta("lab_bridge_attached", true)
	auto_accept_quit = false
	root.close_requested.connect(close_session)
	surface = SubViewport.new()
	root.size = Vector2i(1440, 900)
	root.gui_embed_subwindows = true
	root.hide()
	surface.size = root.size
	surface.own_world_3d = true
	surface.gui_embed_subwindows = true
	surface.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(surface)
	wire.peer = StreamPeerTCP.new()
	wire.peer.connect_to_host("127.0.0.1", int(options["--lab-port"]))
	opened_at = Time.get_ticks_msec()
	last_input = opened_at
	print("LAB RUNTIME: initialized")

func _process(delta: float) -> bool:
	if first_tick:
		first_tick = false
		print("LAB RUNTIME: processing")
	if closing: return false
	if recovering: return false
	if wire.peer == null: return false
	wire.peer.poll()
	if not authenticated and wire.peer.get_status() == StreamPeerTCP.STATUS_CONNECTED:
		wire.send({"version": Wire.VERSION, "token": options["--lab-token"]})
	for packet in wire.receive():
		if not authenticated:
			if packet.get("command") != "hello" or packet.get("version") != Wire.VERSION: continue
			authenticated = true
			request_station(str(options.get("--lab-station", "plants.maker")))
			continue
		command(packet)
	if authenticated and wire.peer.get_status() != StreamPeerTCP.STATUS_CONNECTED:
		close_session()
	if not authenticated and Time.get_ticks_msec() - opened_at > 20000: quit(1)
	if not suspended:
		frame_times.append(delta * 1000.0)
		if frame_times.size() > 600: frame_times.pop_front()
	if dirty and Time.get_ticks_msec() - last_input > 1500:
		flush_workspace()
	return false

func command(packet: Dictionary) -> void:
	if packet.get("command") in ["inspect", "parameter", "station"]: print("LAB RUNTIME: command ", packet.get("command"))
	match packet.get("command", ""):
		"station": request_station(str(packet.get("id", "")))
		"frame":
			if not capturing and not suspended: capture.call_deferred()
		"input":
			if suspended: return
			var event := decode_input(packet)
			if event != null:
				var started := Time.get_ticks_usec()
				Input.parse_input_event(event)
				surface.push_input(event, true)
				if event is InputEventKey or event is InputEventMouseButton:
					var input_key := str((event.physical_keycode if event.physical_keycode != 0 else event.keycode) if event is InputEventKey else event.button_index) + event.get_class()
					if event.pressed: held_inputs[input_key] = event
					else: held_inputs.erase(input_key)
				last_action_ms = (Time.get_ticks_usec() - started) / 1000.0
				dirty = true
				last_input = Time.get_ticks_msec()
		"suspend": set_suspended(bool(packet.get("value", true)))
		"release_inputs": release_inputs()
		"transport": transport = "png" if packet.get("format") == "png" else "jpg"
		"resize":
			surface.size = Vector2i(clampi(int(packet.get("width", 1440)), 800, 1920), clampi(int(packet.get("height", 900)), 600, 1200))
			root.size = surface.size
		"save": flush_workspace()
		"inspect": send_inspection()
		"parameter":
			if is_instance_valid(host) and active_entry.get("host") == "workstation":
				var key := str(packet.get("key", ""))
				var proposed := {key: packet.get("value")}
				var admitted: Dictionary = host.admit_settings(host.fixture, proposed)
				if admitted.values.has(key):
					var start := Time.get_ticks_usec()
					host.apply_parameter(key, admitted.values[key])
					last_action_ms = (Time.get_ticks_usec() - start) / 1000.0
					dirty = true
					last_input = Time.get_ticks_msec()
		"action":
			if is_instance_valid(host) and active_entry.get("host") == "workstation":
				match packet.get("action"):
					"undo": host.undo_tuning()
					"baseline": host.set_baseline()
					"reset": host.restore_defaults()
					"pause": host.set_paused(not host.paused)
					"capture": host.capture()
		"close": close_session()
		"restart":
			var id: String = active_entry.get("id", "")
			if flush_workspace():
				if is_instance_valid(host):
					surface.remove_child(host)
					host.queue_free()
				host = null
				request_station(id)

func request_station(id: String) -> void:
	pending_station = id
	if not switch_queued:
		switch_queued = true
		apply_pending_station.call_deferred()

func apply_pending_station() -> void:
	switch_queued = false
	open_station(pending_station)

func release_inputs() -> void:
	for input_event in held_inputs.values():
		var released: InputEvent = input_event.duplicate()
		released.pressed = false
		Input.parse_input_event(released)
		surface.push_input(released, true)
	held_inputs.clear()

func open_station(id: String) -> void:
	if closing or recovering: return
	var entry := Catalogue.find(id)
	if entry.is_empty() or entry.get("host") not in ["workstation", "sol"]:
		wire.send({"status": "This station has no supported preview adapter.", "busy": false})
		return
	wire.send({"status": "Preparing " + str(entry.title) + "…", "busy": true})
	var snapshot_before := Catalogue.fingerprint(entry, true)
	set_suspended(false)
	if is_instance_valid(host) and active_entry.get("host") != entry.host:
		if not flush_workspace(): return
		if active_entry.get("host") == "sol" and host.has_method("lab_session_snapshot"): sol_session = host.lab_session_snapshot()
		surface.remove_child(host)
		host.free()
		host = null
	var start := Time.get_ticks_usec()
	if not is_instance_valid(host):
		if entry.host == "workstation":
			if not options.has("--lab-workspace"):
				for paths in [["user://workstation/workspace.cfg", "user://workstation/editor_bridge.cfg"], ["user://workstation/reviews.cfg", "user://workstation/editor_bridge-reviews.cfg"]]:
					var migrated := Storage.seed_workspace(paths[0], paths[1])
					if migrated.has("error"):
						wire.send({"status": migrated.error, "busy": false})
						return
			Engine.set_meta("workstation_session_path", str(options.get("--lab-workspace", "user://workstation/editor_bridge.cfg")))
			Engine.set_meta("lab_initial_station", entry.fixture_key)
			host = load("res://scenes/development_workstation.tscn").instantiate()
		else:
			host = load(entry.scene).instantiate()
		surface.add_child(host)
		host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		if entry.host == "sol":
			if not sol_session.is_empty() and host.has_method("lab_restore_session"): host.lab_restore_session(sol_session)
			elif host.has_method("lab_load_workspace"): host.lab_load_workspace()
	else:
		var index: int = host.FIXTURES.values().find(entry.fixture_key)
		if index >= 0 and host.active_key != entry.fixture_key:
			host.picker.select(index)
			host.load_fixture()
	active_entry = entry
	if entry.host == "workstation":
		host.picker.hide()
		host.save_timer.stop()
		# Editor navigation is the sole station picker in a bridged workspace.
		for node in host.descendants(host):
			if node is Button and node.text in ["Browse", "Creative additions"]: node.hide()
	dependency_snapshot = snapshot_before
	last_action_ms = (Time.get_ticks_usec() - start) / 1000.0
	wire.send({"status": "Ready · " + str(entry.domain) + " / " + str(entry.title), "busy": false, "metrics": {"open_ms": last_action_ms, "snapshot": dependency_snapshot}})
	dirty = true
	last_input = Time.get_ticks_msec()

func flush_workspace() -> bool:
	if not is_instance_valid(host): return true
	if active_entry.get("host") == "workstation":
		if not host.save_workspace():
			last_input = Time.get_ticks_msec()
			wire.send({"status":"Workspace save failed. Work remains open; check the storage location before closing.", "busy":false})
			return false
	elif not host.preserve_dirty():
		wire.send({"status": "Draft could not be saved. Correct its name before leaving this workspace.", "busy": false})
		last_input = Time.get_ticks_msec()
		return false
	elif host.has_method("lab_save_workspace") and not host.lab_save_workspace():
		last_input = Time.get_ticks_msec()
		wire.send({"status":"Could not save the Sol editor workspace. Work remains open for recovery.", "busy":false})
		return false
	dirty = false
	return true

func close_session() -> void:
	if closing: return
	if not flush_workspace():
		# Retain the authoring owner for recovery if editor shutdown lost the bridge.
		if wire.peer.get_status() != StreamPeerTCP.STATUS_CONNECTED and not recovering:
			surface.remove_child(host)
			root.add_child(host)
			host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			surface.queue_free()
			recovering = true
			root.show()
		return
	closing = true
	quit()

func set_suspended(value: bool) -> void:
	if suspended == value: return
	if value:
		release_inputs()
		flush_workspace()
		for node in surface.find_children("*", "GPUParticles3D", true, false) + surface.find_children("*", "GPUParticles2D", true, false):
			hidden_particles[node] = node.speed_scale
			node.speed_scale = 0.0
		for node in surface.find_children("*", "AudioStreamPlayer", true, false) + surface.find_children("*", "AudioStreamPlayer3D", true, false) + surface.find_children("*", "AudioStreamPlayer2D", true, false):
			hidden_audio[node] = node.stream_paused
			node.stream_paused = true
		hidden_viewports.clear()
		for viewport in surface.find_children("*", "SubViewport", true, false) + [surface]:
			hidden_viewports[viewport] = viewport.render_target_update_mode
			viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	else:
		for node in hidden_particles:
			if is_instance_valid(node): node.speed_scale = hidden_particles[node]
		hidden_particles.clear()
		for node in hidden_audio:
			if is_instance_valid(node): node.stream_paused = hidden_audio[node]
		hidden_audio.clear()
		for viewport in hidden_viewports:
			if is_instance_valid(viewport): viewport.render_target_update_mode = hidden_viewports[viewport]
		hidden_viewports.clear()
	if is_instance_valid(host): host.process_mode = Node.PROCESS_MODE_DISABLED if value else Node.PROCESS_MODE_INHERIT
	suspended = value
	Engine.max_fps = 5 if value else 60
	wire.send({"suspended": value})

func send_inspection() -> void:
	if not is_instance_valid(host): return
	var data := {"station": active_entry.id, "snapshot": dependency_snapshot, "suspended": suspended, "host_id": host.get_instance_id()}
	data["rendering_enabled"] = surface.render_target_update_mode != SubViewport.UPDATE_DISABLED
	if active_entry.host == "workstation":
		data["settings"] = host.exported_settings(host.fixture)
		data["fixture_id"] = host.fixture.get_instance_id()
		data["notes"] = host.notes.text
		data["baseline"] = not host.baseline.is_empty()
		var geometry := ""
		for node in host.descendants(host.fixture) if active_entry.get("fixture_key") == "plant_maker" else []:
			if node is MeshInstance3D and node.mesh is ArrayMesh:
				for surface_index in range(node.mesh.get_surface_count()):
					var vertices: PackedVector3Array = node.mesh.surface_get_arrays(surface_index)[Mesh.ARRAY_VERTEX]
					geometry += str(hash(vertices))
		data["geometry"] = geometry.sha256_text()
	var controls: Array[Dictionary] = []
	for node in host.find_children("*", "Control", true, false):
		if node is BaseButton or node is Range or node is LineEdit or node is TextEdit or node is ItemList or node is TabContainer:
			var row := {"type": node.get_class(), "path": str(host.get_path_to(node)), "visible": node.is_visible_in_tree()}
			if node is BaseButton: row["label"] = node.text
			if node is Range: row.merge({"value": node.value, "min": node.min_value, "max": node.max_value, "step": node.step})
			if node is BaseButton or node is ItemList:
				var at: Vector2 = node.get_global_rect().get_center()
				row.merge({"x": at.x, "y": at.y})
			controls.append(row)
	data["controls"] = controls
	print("LAB RUNTIME: inspection controls ", controls.size(), "; sent ", wire.send({"inspection": data}))

func capture() -> void:
	if capturing or suspended: return
	capturing = true
	await RenderingServer.frame_post_draw
	var started := Time.get_ticks_usec()
	var image := surface.get_texture().get_image()
	if image != null and not image.is_empty():
		var encoded: PackedByteArray
		if transport == "jpg":
			image.convert(Image.FORMAT_RGB8)
			encoded = image.save_jpg_to_buffer(0.95)
		else: encoded = image.save_png_to_buffer()
		last_capture_ms = (Time.get_ticks_usec() - started) / 1000.0
		var sorted := frame_times.duplicate()
		sorted.sort()
		var median: float = sorted[sorted.size() / 2] if not sorted.is_empty() else 0.0
		var p95: float = sorted[mini(sorted.size() - 1, int(sorted.size() * 0.95))] if not sorted.is_empty() else 0.0
		wire.send({"image": Marshalls.raw_to_base64(encoded), "station":active_entry.get("id", ""), "format": transport, "metrics": {"transport": transport, "capture_ms": last_capture_ms, "last_action_ms": last_action_ms, "median_ms": median, "p95_ms": p95, "samples": sorted.size(), "renderer": RenderingServer.get_current_rendering_method(), "driver": RenderingServer.get_current_rendering_driver_name(), "viewport": str(surface.size), "snapshot": dependency_snapshot, "bytes": encoded.size()}})
	capturing = false

static func decode_input(packet: Dictionary) -> InputEvent:
	var event: InputEvent
	match packet.get("kind", ""):
		"button":
			var button := InputEventMouseButton.new()
			button.position = Vector2(float(packet.get("x", 0)), float(packet.get("y", 0)))
			button.global_position = button.position
			button.button_index = clampi(int(packet.get("button", 1)), 1, 9)
			button.button_mask = int(packet.get("mask", 0))
			button.pressed = bool(packet.get("pressed", false))
			button.double_click = bool(packet.get("double", false))
			event = button
		"motion":
			var motion := InputEventMouseMotion.new()
			motion.position = Vector2(float(packet.get("x", 0)), float(packet.get("y", 0)))
			motion.global_position = motion.position
			motion.relative = Vector2(float(packet.get("dx", 0)), float(packet.get("dy", 0)))
			motion.button_mask = int(packet.get("mask", 0))
			event = motion
		"key":
			var key := InputEventKey.new()
			key.keycode = int(packet.get("keycode", 0))
			key.physical_keycode = int(packet.get("physical", 0))
			key.unicode = int(packet.get("unicode", 0))
			key.pressed = bool(packet.get("pressed", false))
			key.echo = bool(packet.get("echo", false))
			event = key
	if event is InputEventWithModifiers:
		event.shift_pressed = bool(packet.get("shift", false))
		event.ctrl_pressed = bool(packet.get("ctrl", false))
		event.alt_pressed = bool(packet.get("alt", false))
	return event
