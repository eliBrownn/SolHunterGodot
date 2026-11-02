extends RefCounted
## Main-owned coordinator. Exactly one admitted/running/completed CPU job; no queue.
const Task = preload("res://scripts/presentation/chunk_buffer_task.gd")
const MAX_RESERVED_BYTES := 16 * 1024 * 1024
var epoch := 0
var sequence := 0
var handle := -1
var task_id := -1
var task: RefCounted
var identity: Array = []
var reserved_bytes := 0
var completed := false
var abandoned := false
var closed := false
var submitted := 0
var reaped := 0
var discarded := 0
var failed := 0
var taken := 0
var peak_reserved_bytes := 0
var compute_ms := 0.0
var submitted_usec := 0
var max_age_ms := 0.0
var max_submit_ms := 0.0
var max_poll_ms := 0.0
var owner_thread := OS.get_thread_caller_id()

func make_task() -> RefCounted:
	return Task.new()

func submit(poses: Array[Transform3D], colors: Array[Color], custom: bool, stamp: Array) -> int:
	assert(OS.get_thread_caller_id() == owner_thread)
	var began := Time.get_ticks_usec()
	poll()
	var reservation := poses.size() * 256 + 4096
	if closed or task != null or reservation > MAX_RESERVED_BYTES: return -1
	var candidate := make_task()
	candidate.poses = poses
	candidate.colors = colors
	candidate.custom = custom
	if not candidate.valid_input(): return -1
	# Only primitive identity values cross this main-owned freshness boundary.
	for value in stamp:
		if not (value is int or value is String or value is Vector2i): return -1
	identity = stamp.duplicate()
	identity.push_front(epoch)
	sequence += 1
	handle = sequence
	task = candidate
	reserved_bytes = reservation
	peak_reserved_bytes = maxi(peak_reserved_bytes, reservation)
	completed = false
	abandoned = false
	submitted_usec = Time.get_ticks_usec()
	task_id = WorkerThreadPool.add_task(task.run, false, "Chunk instance buffer")
	if task_id < 0:
		failed += 1
		clear_slot()
		return -1
	submitted += 1
	max_submit_ms = maxf(max_submit_ms, (Time.get_ticks_usec() - began) / 1000.0)
	return handle

func poll() -> void:
	assert(OS.get_thread_caller_id() == owner_thread)
	if task_id < 0 or not WorkerThreadPool.is_task_completed(task_id): return
	var began := Time.get_ticks_usec()
	# Reap only completed work during frames. This is never an unfinished wait.
	WorkerThreadPool.wait_for_task_completion(task_id)
	task_id = -1
	reaped += 1
	compute_ms += task.compute_ms
	max_age_ms = maxf(max_age_ms, (Time.get_ticks_usec() - submitted_usec) / 1000.0)
	completed = true
	if abandoned or identity[0] != epoch:
		discarded += 1
		clear_slot()
	max_poll_ms = maxf(max_poll_ms, (Time.get_ticks_usec() - began) / 1000.0)

func take(request: int, stamp: Array) -> Dictionary:
	poll()
	if task == null or request != handle: return {"status": "stale"}
	var expected := stamp.duplicate()
	expected.push_front(epoch)
	if identity != expected:
		cancel(request)
		return {"status": "stale"}
	if not completed: return {"status": "pending"}
	var result := {"status": "ready", "buffer": task.buffer, "worker_id": task.worker_id}
	if not task.error.is_empty() or task.buffer.size() != task.poses.size() * (20 if task.custom else 16):
		result = {"status": "failed", "error": task.error}
		failed += 1
	else:
		taken += 1
	clear_slot()
	return result

func cancel(request: int) -> void:
	assert(OS.get_thread_caller_id() == owner_thread)
	if task == null or request != handle: return
	abandoned = true
	task.request_cancel()
	if completed:
		discarded += 1
		clear_slot()

func invalidate() -> void:
	assert(OS.get_thread_caller_id() == owner_thread)
	epoch += 1
	cancel(handle)
	poll()

func clear_slot() -> void:
	task = null
	handle = -1
	reserved_bytes = 0
	identity.clear()
	completed = false
	abandoned = false

func shutdown() -> void:
	assert(OS.get_thread_caller_id() == owner_thread)
	closed = true
	if task == null: return
	task.request_cancel()
	# Explicit shutdown boundary: inputs remain owned until the finite task ends.
	if task_id >= 0:
		WorkerThreadPool.wait_for_task_completion(task_id)
		task_id = -1
		reaped += 1
	discarded += 1
	clear_slot()

func statistics() -> Dictionary:
	return {"submitted": submitted, "reaped": reaped, "taken": taken, "discarded": discarded, "failed": failed, "in_flight": int(task_id >= 0), "completed_pending": int(completed), "reserved_bytes": reserved_bytes, "peak_reserved_bytes": peak_reserved_bytes, "compute_ms": compute_ms, "max_age_ms": max_age_ms, "max_submit_ms": max_submit_ms, "max_poll_ms": max_poll_ms}
