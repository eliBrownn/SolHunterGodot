extends SceneTree
const Queue = preload("res://scripts/presentation/vegetation_visual_queue.gd")
const Chunk = preload("res://scripts/presentation/solid_chunk.gd")
var checks := 0
var failures := 0
func check(ok: bool, text: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(text)
func _initialize() -> void: run.call_deferred()
func make_chunk() -> Node3D:
	var chunk = Chunk.new()
	root.add_child(chunk)
	var mesh := MultiMesh.new()
	mesh.transform_format = MultiMesh.TRANSFORM_3D
	mesh.use_custom_data = true
	mesh.mesh = BoxMesh.new()
	mesh.instance_count = 1030
	for index in range(1030): mesh.set_instance_transform(index, Transform3D(Basis.IDENTITY, Vector3(index,0,0)))
	var large := PackedInt32Array()
	for index in range(1025): large.append(index)
	chunk.plant_instances[Vector2i.ZERO] = {
		"large": {"mesh":mesh,"indices":large,"pivot":Vector3.ZERO,"individual_roots":true},
		"small_same_cell": {"mesh":mesh,"indices":PackedInt32Array([1025,1026]),"pivot":Vector3.ZERO,"individual_roots":true}}
	chunk.plant_instances[Vector2i.ONE] = {"small": {"mesh":mesh,"indices":PackedInt32Array([1027,1028,1029]),"pivot":Vector3.ZERO,"individual_roots":true}}
	return chunk
func run() -> void:
	var queue = Queue.new()
	var queued = make_chunk()
	var reference = make_chunk()
	queued.vegetation_visual_queue = queue
	var chunks := {Vector2i.ZERO:queued}
	queue.begin_frame(chunks)
	for chunk in [queued,reference]:
		chunk.apply_plant_reserve(Vector2i.ZERO,0.2,0.0)
		chunk.apply_plant_reserve(Vector2i.ONE,0.9,0.0)
		chunk.apply_plant_animations({Vector2i.ZERO:{"kind":"protecting","start":0.0,"duration":1.6}},0.8,1.0)
	check(queue.drain(96) == 96, "Budget counts writes across both channels")
	var mesh: MultiMesh = queued.plant_instances[Vector2i.ZERO].large.mesh
	check(not queue.jobs.values().any(func(job: Dictionary) -> bool: return job.indices[0] == 1027), "Small cell receives a turn before dense cell completes")
	# Change a target while its first sweep is incomplete; then retire the reaction.
	for chunk in [queued,reference]:
		chunk.apply_plant_reserve(Vector2i.ZERO,0.7,0.2)
		chunk.apply_plant_animations({},2.0,1.0)
	var frames := 0
	while not queue.jobs.is_empty() and frames < 100:
		queue.begin_frame(chunks)
		check(queue.drain(128) <= 128,"Per-frame bound holds during catch-up")
		frames += 1
	check(queue.jobs.is_empty(),"Latest state drains completely without starvation")
	var expected: MultiMesh = reference.plant_instances[Vector2i.ZERO].large.mesh
	for index in range(1030):
		check(mesh.get_instance_transform(index).is_equal_approx(expected.get_instance_transform(index)),"Expired poses restore exact neutral transforms")
		check(mesh.get_instance_custom_data(index).is_equal_approx(expected.get_instance_custom_data(index)),"Every instance receives latest reserve data")
	# A new event after a deferred reset must still use original resting transforms.
	for chunk in [queued,reference]: chunk.apply_plant_animations({Vector2i.ZERO:{"kind":"receiving","start":3.0,"duration":1.6}},3.8,1.0)
	while not queue.jobs.is_empty():
		queue.begin_frame(chunks)
		queue.drain(512)
	for index in range(1030): check(mesh.get_instance_transform(index).is_equal_approx(expected.get_instance_transform(index)),"Later event preserves original roots")
	queued.apply_plant_reserve(Vector2i.ZERO,0.0,4.0)
	queue.begin_frame({})
	check(queue.jobs.is_empty() and queue.drain(512)==0,"Removed chunk cancels pending writes")
	queue.begin_frame(chunks)
	queued.apply_plant_reserve(Vector2i.ZERO,0.0,4.0)
	while not queue.jobs.is_empty():
		queue.begin_frame(chunks)
		queue.drain(512)
	check(mesh.get_instance_custom_data(0).g == 0.0 and mesh.get_instance_transform(0).basis.is_equal_approx(Basis.IDENTITY), "Cached chunk re-entry refreshes reserves and restores retired poses")
	queued.free()
	reference.free()
	print("VEGETATION QUEUE: ",checks," checks, ",failures," failures; catch-up frames=",frames)
	quit(0 if failures==0 else 1)
