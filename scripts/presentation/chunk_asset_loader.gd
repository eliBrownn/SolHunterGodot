extends RefCounted
## Main-thread owner for bounded engine background requests. No scene instantiation.
const MAX_PENDING := 16
const MAX_RETAINED := 32
const MAX_FILE_BYTES := 4 * 1024 * 1024
const MAX_RETAINED_FILE_BYTES := 32 * 1024 * 1024
var epoch := 0
var queued: Array[String] = []
var active := ""
var active_epoch := -1
var retained := {}
var failures := {}
var retained_file_bytes := 0
var requests := 0
var collections := 0
var stale := 0
var bypasses := 0
var peak_pending := 0
var peak_retained_file_bytes := 0
var max_collect_ms := 0.0
var closed := false
var owner_thread := OS.get_thread_caller_id()

func ensure(paths: Array[String]) -> bool:
	assert(OS.get_thread_caller_id() == owner_thread)
	var ready := true
	for path in paths:
		if failures.has(path) or retained.has(path): continue
		if active == path or queued.has(path):
			ready = false
			continue
		if ResourceLoader.has_cached(path): continue
		if closed or not path.begins_with("res://resources/plants/runtime_palette/") or not path.ends_with(".res") or "/../" in path or "\\" in path: continue
		if not FileAccess.file_exists(path): continue # Preserve the existing deterministic fallback.
		var file := FileAccess.open(path, FileAccess.READ)
		var size := file.get_length() if file != null else MAX_FILE_BYTES + 1
		if size > MAX_FILE_BYTES:
			remember_failure(path)
			bypasses += 1
			continue
		ready = false
		if queued.size() + int(not active.is_empty()) < MAX_PENDING: queued.append(path)
	peak_pending = maxi(peak_pending, queued.size() + int(not active.is_empty()))
	return ready

func advance() -> void:
	assert(OS.get_thread_caller_id() == owner_thread)
	if not active.is_empty():
		var status := ResourceLoader.load_threaded_get_status(active)
		if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS: return
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			var began := Time.get_ticks_usec()
			var asset: Resource = ResourceLoader.load_threaded_get(active)
			collections += 1
			max_collect_ms = maxf(max_collect_ms, (Time.get_ticks_usec() - began) / 1000.0)
			if active_epoch == epoch and asset != null:
				var file := FileAccess.open(active, FileAccess.READ)
				var size := file.get_length() if file != null else 0
				retained[active] = {"asset": asset, "file_bytes": size}
				retained_file_bytes += size
			else: stale += 1
		else:
			ResourceLoader.load_threaded_get(active)
			collections += 1
			remember_failure(active)
		active = ""
		trim()
	if closed or queued.is_empty(): return
	var path: String = queued.pop_front()
	if retained.has(path) or ResourceLoader.has_cached(path): return
	var error := ResourceLoader.load_threaded_request(path, "", false)
	if error != OK:
		remember_failure(path)
		return
	active = path
	active_epoch = epoch
	requests += 1

func remember_failure(path: String) -> void:
	if failures.size() >= 64: failures.erase(failures.keys()[0])
	failures[path] = true

func trim() -> void:
	while retained.size() > MAX_RETAINED or retained_file_bytes > MAX_RETAINED_FILE_BYTES:
		var oldest: String = retained.keys()[0]
		retained_file_bytes -= int(retained[oldest].file_bytes)
		retained.erase(oldest)
	peak_retained_file_bytes = maxi(peak_retained_file_bytes, retained_file_bytes)

func invalidate() -> void:
	assert(OS.get_thread_caller_id() == owner_thread)
	epoch += 1
	queued.clear()
	retained.clear()
	failures.clear()
	retained_file_bytes = 0
	# The engine exposes no cancellation. Keep polling/collecting the single old
	# request, discard it, then admit the current epoch. Never wait during frames.

func drop_queued() -> void:
	assert(OS.get_thread_caller_id() == owner_thread)
	queued.clear() # A canceled chunk no longer owns speculative queued dependencies.

func shutdown() -> void:
	assert(OS.get_thread_caller_id() == owner_thread)
	closed = true
	queued.clear()
	if not active.is_empty():
		# Explicit shutdown is the only place an unfinished resource may be waited.
		ResourceLoader.load_threaded_get(active)
		collections += 1
		active = ""
	retained.clear()
	retained_file_bytes = 0

func statistics() -> Dictionary:
	return {"requests": requests, "collections": collections, "stale": stale, "bypasses": bypasses, "pending": queued.size() + int(not active.is_empty()), "retained": retained.size(), "retained_file_bytes": retained_file_bytes, "peak_pending": peak_pending, "peak_retained_file_bytes": peak_retained_file_bytes, "max_collect_ms": max_collect_ms}
