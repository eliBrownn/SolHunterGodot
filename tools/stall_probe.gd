extends RefCounted
## Used only by profile_frame_stalls.gd and wrappers in its isolated runtime copy.
## Frame wall time includes engine/render waits; nested scope times are inclusive.
static var enabled := false
static var phase := "setup"
static var phase_serial := 0
static var bucket_phase := "setup"
static var bucket_serial := 0
static var pending: Dictionary = {}
static var spans: Array = []
static var frames: Array = []
static var previous_usec := 0
static var last_phase := "setup"
static var last_serial := 0
static var all_scope_calls := 0
static var pipeline_monitors: Dictionary = {}
static var pipeline_monitors_checked := false

static func set_phase(value: String) -> void:
	phase = value
	phase_serial += 1

static func enter() -> int:
	return Time.get_ticks_usec()

static func leave(key: String, started: int) -> void:
	var elapsed := Time.get_ticks_usec() - started
	all_scope_calls += 1
	if pending.is_empty():
		bucket_phase = phase
		bucket_serial = phase_serial
	if not pending.has(key): pending[key] = {"calls": 0, "total_ms": 0.0, "max_ms": 0.0}
	var row: Dictionary = pending[key]
	row.calls += 1
	row.total_ms += elapsed / 1000.0
	row.max_ms = maxf(row.max_ms, elapsed / 1000.0)
	# Keep bounded detail in memory, never write logs in the measured frame.
	if elapsed >= 1000:
		spans.append({"scope": key, "start_usec": started, "ms": elapsed / 1000.0})
		if spans.size() > 64:
			spans.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.ms > b.ms)
			spans.resize(64)

static func frame(world: Node, host: Node) -> void:
	var now := Time.get_ticks_usec()
	if previous_usec > 0:
		var row := {"frame": Engine.get_process_frames() - 1,
			"interval_start_usec": previous_usec, "interval_end_usec": now,
			"phase": last_phase, "phase_serial": last_serial,
			"boundary": last_serial != phase_serial or (not pending.is_empty() and bucket_serial != last_serial),
			"wall_ms": (now - previous_usec) / 1000.0,
			"cell": str(world.cell), "tick": world.persistent_state.activity_tick(),
			"pending_detail": world.pending.size(), "live_detail": world.chunks.size(),
			"draw_calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
			"primitives": Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
			"engine_static_bytes": Performance.get_monitor(Performance.MEMORY_STATIC),
			"process_ms_monitor": Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0}
		if enabled:
			if not pipeline_monitors_checked:
				pipeline_monitors_checked = true
				for name in ClassDB.class_get_integer_constant_list("Performance"):
					if str(name).begins_with("PIPELINE_COMPILATIONS_"):
						pipeline_monitors[str(name)] = ClassDB.class_get_integer_constant("Performance", name)
			row["pipeline_compilations"] = {}
			for name in pipeline_monitors:
				row.pipeline_compilations[name] = Performance.get_monitor(pipeline_monitors[name])
			row["scopes"] = pending
			if row.wall_ms >= 33.4:
				row["spans_over_1ms"] = spans
		frames.append(row)
	previous_usec = now
	last_phase = phase
	last_serial = phase_serial
	pending = {}
	spans = []
