@tool
extends RefCounted
const Wire = preload("res://tools/lab_bridge_wire.gd")
const CLOSING_PID_KEY := "solhunter_lab_closing_runtime_pid"
var server := TCPServer.new()
var wire = Wire.new()
var token := ""
var pid := -1
var connected := false
var message := "Choose a station."
var station_id := ""
var latest_image: Image
var image_revision := 0
var busy := false
var started_at := 0
var metrics: Dictionary = {}
var frame_pending := false
var inspection: Dictionary = {}
var suspended := false
var workspace_path := ""
var runtime_log := ""
var station_snapshots: Dictionary = {}
var preview_rate := 10.0
var transport_format := "jpg"
var cancel_requested := false

func start(entry: Dictionary) -> bool:
	var closing_pid := int(Engine.get_meta(CLOSING_PID_KEY, -1))
	if closing_pid > 0:
		if OS.is_process_running(closing_pid):
			message = "The previous authoring process is saving or needs recovery. Close its window before opening another."
			return false
		Engine.remove_meta(CLOSING_PID_KEY)
	if connected:
		cancel_requested = false
		station_id = entry.id
		busy = true
		return wire.send({"command": "station", "id": station_id})
	if pid > 0 and OS.is_process_running(pid):
		message = "The preview is still opening."
		return false
	server.stop()
	cancel_requested = false
	metrics.clear()
	inspection.clear()
	wire = Wire.new()
	if server.listen(0, "127.0.0.1") != OK:
		message = "Could not open the local preview connection."
		return false
	token = Crypto.new().generate_random_bytes(24).hex_encode()
	station_id = entry.id
	var args := PackedStringArray(["--path", ProjectSettings.globalize_path("res://"), "--rendering-method", RenderingServer.get_current_rendering_method(), "--rendering-driver", RenderingServer.get_current_rendering_driver_name(), "--script", "res://tools/lab_bridge_runner.gd", "--", "--lab-port=" + str(server.get_local_port()), "--lab-token=" + token, "--lab-station=" + station_id])
	var log_folder := workspace_path.get_base_dir() if not workspace_path.is_empty() else "user://workstation"
	DirAccess.make_dir_recursive_absolute(log_folder)
	runtime_log = log_folder.path_join("runtime_%d_%d.log" % [OS.get_process_id(), Time.get_ticks_msec()])
	args.insert(2, "--log-file")
	args.insert(3, ProjectSettings.globalize_path(runtime_log))
	if not workspace_path.is_empty(): args.append("--lab-workspace=" + workspace_path)
	pid = OS.create_process(OS.get_executable_path(), args, false)
	started_at = Time.get_ticks_msec()
	busy = true
	message = "Opening preview…"
	return pid > 0

func poll() -> void:
	if wire.peer == null and server.is_connection_available():
		wire.peer = server.take_connection()
		wire.peer.set_no_delay(true)
	for packet in wire.receive():
		if not connected:
			if packet.get("version") != Wire.VERSION or packet.get("token") != token:
				wire.peer.disconnect_from_host()
				wire = Wire.new()
				continue
			connected = true
			server.stop()
			wire.send({"command": "hello", "version": Wire.VERSION})
			wire.send({"command":"transport", "format":transport_format})
			if cancel_requested: wire.send({"command":"close"})
		if packet.has("status"):
			message = str(packet.status)
			busy = bool(packet.get("busy", false))
		if packet.has("metrics"):
			metrics = packet.metrics
			if metrics.has("snapshot"): station_snapshots[str(packet.get("station", station_id))] = str(metrics.snapshot)
		if packet.has("inspection"): inspection = packet.inspection
		if packet.has("suspended"): suspended = bool(packet.suspended)
		if packet.has("image"):
			frame_pending = false
			if packet.get("station", station_id) != station_id: continue
			var decoded := Image.new()
			var bytes := Marshalls.base64_to_raw(str(packet.image))
			var decode_error := decoded.load_jpg_from_buffer(bytes) if packet.get("format") == "jpg" else decoded.load_png_from_buffer(bytes)
			if decode_error == OK:
				latest_image = decoded
				image_revision += 1
			frame_pending = false
	if wire.failed:
		if wire.peer != null: wire.peer.disconnect_from_host()
		connected = false
		busy = false
		frame_pending = false
		message = "Preview protocol failed. Close the runtime session and reopen it."
	if wire.peer != null and connected and wire.peer.get_status() != StreamPeerTCP.STATUS_CONNECTED:
		connected = false
		busy = false
		frame_pending = false
		message = "Preview closed. Reopen to continue from the saved workspace."
		wire = Wire.new()
	if busy and not connected and Time.get_ticks_msec() - started_at > 60000:
		busy = false
		message = "Preview did not connect. Check the runtime log, then retry."
	if cancel_requested and (connected or busy): message = "Closing at the next safe boundary; local work will be saved."

func request_frame() -> void:
	if connected and not frame_pending and not busy:
		frame_pending = wire.send({"command": "frame"})

func send(packet: Dictionary) -> void:
	if connected: wire.send(packet)

func shutdown() -> void:
	# Release sockets before editor/OS teardown; the child saves on disconnect.
	if pid > 0 and OS.is_process_running(pid): Engine.set_meta(CLOSING_PID_KEY, pid)
	if connected: wire.send({"command":"close"})
	wire.flush()
	if wire.peer != null: wire.peer.disconnect_from_host()
	wire = Wire.new()
	server.stop()
	connected = false
	busy = false
	cancel_requested = false

func cancel_opening() -> void:
	cancel_requested = true
	if connected: wire.send({"command":"close"})
