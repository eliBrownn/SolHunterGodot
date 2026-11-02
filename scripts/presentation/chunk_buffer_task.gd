extends RefCounted
## Exclusive task context: value-only input, local output, one cancellation lock.
const MAX_ROWS := 32768
var poses: Array[Transform3D] = []
var colors: Array[Color] = []
var custom := false
var buffer := PackedFloat32Array()
var compute_ms := 0.0
var error := ""
var worker_id := -1
var cancellation := Mutex.new()
var cancelled := false

static func append_row(output: PackedFloat32Array, pose: Transform3D, source_color: Color, with_custom: bool) -> void:
	var color := source_color.srgb_to_linear()
	output.append_array(PackedFloat32Array([pose.basis.x.x, pose.basis.y.x, pose.basis.z.x, pose.origin.x,
		pose.basis.x.y, pose.basis.y.y, pose.basis.z.y, pose.origin.y,
		pose.basis.x.z, pose.basis.y.z, pose.basis.z.z, pose.origin.z,
		color.r, color.g, color.b, color.a]))
	if with_custom: output.append_array(PackedFloat32Array([1.0, 1.0, -1.0, 1.0]))

func request_cancel() -> void:
	cancellation.lock()
	cancelled = true
	cancellation.unlock()

func is_cancelled() -> bool:
	cancellation.lock()
	var value := cancelled
	cancellation.unlock()
	return value

func checkpoint() -> bool:
	return is_cancelled()

func valid_input() -> bool:
	return not poses.is_empty() and poses.size() <= MAX_ROWS and poses.size() == colors.size() and poses.is_read_only() and colors.is_read_only()

func run() -> void:
	var began := Time.get_ticks_usec()
	worker_id = WorkerThreadPool.get_caller_task_id()
	if not valid_input():
		error = "Invalid detached instance snapshot"
		return
	var result := PackedFloat32Array()
	for index in range(poses.size()):
		if index % 32 == 0 and checkpoint(): return
		var pose := poses[index]
		var color := colors[index]
		if not pose.is_finite() or not is_finite(color.r) or not is_finite(color.g) or not is_finite(color.b) or not is_finite(color.a):
			error = "Nonfinite instance snapshot"
			return
		append_row(result, pose, color, custom)
	if not is_cancelled(): buffer = result
	compute_ms = (Time.get_ticks_usec() - began) / 1000.0
