extends SceneTree
const Streaming = preload("res://scripts/presentation/view_streaming.gd")
const Task = preload("res://scripts/presentation/chunk_preparation_task.gd")
var checks := 0
var failures := 0

class WorldProbe extends Node2D:
	var paused := false

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var expected := [Vector2i.ZERO, Vector2i(1,0), Vector2i(1,1), Vector2i(0,1), Vector2i(-1,1), Vector2i(-1,0), Vector2i(-1,-1), Vector2i(0,-1), Vector2i(1,-1), Vector2i(2,-1)]
	for index in range(expected.size()):
		check(Streaming.spiral_index(expected[index]) == index, "Spiral winds through complete rings")
	var indices := {}
	for y in range(-16,17):
		for x in range(-16,17): indices[Streaming.spiral_index(Vector2i(x,y))] = true
	check(indices.size() == 33*33, "Every chunk has a unique spiral position")
	for index in range(33*33):
		check(indices.has(index), "Spiral contains no gaps across maximum radius")
	for heading in [Vector2.RIGHT,Vector2.DOWN,Vector2.LEFT,Vector2.UP]:
		check(Streaming.spiral_index(Streaming.facing_offset(Vector2i(heading),heading)) == 1, "Travel direction leads its ring")
	var host = preload("res://scripts/application/world_solid.gd").new()
	host.world = WorldProbe.new()
	host.active_view = View3DSettings.new()
	var wanted: Array[Vector2i] = [Vector2i.ZERO, Vector2i(1,0), Vector2i(1,1)]
	check(host.active_view.spiral_chunk_loading, "Experiment is enabled by default")
	check(host.spiral_population_target(wanted) == Vector2i.ZERO, "Idle pipeline chooses first spiral request")
	host.nearby_stream_chunks[Vector2i.ZERO] = true
	var deadline := Time.get_ticks_usec()+1000000
	check(host.chunk_detail_deadline(wanted,deadline) == deadline, "Nearby half keeps normal budget")
	host.nearby_stream_chunks.clear()
	check(host.chunk_detail_deadline(wanted,deadline) < deadline, "Outer half uses smaller budget")
	host.active_view.spiral_chunk_loading = false
	check(host.chunk_detail_deadline(wanted,deadline) == deadline, "Disabling experiment restores normal budget")
	host.active_view.spiral_chunk_loading = true
	var task := Task.new()
	task.coord = Vector2i(1,0)
	host.population.slots.append({"task":task,"state":"generating","handle":-1,"context":null,"epoch":0})
	check(host.spiral_population_target(wanted) == task.coord, "Reordering retains admitted worker chunk")
	host.population.slots[0].state = "ready"
	check(host.next_population_coord(wanted) == task.coord, "Completed result is next publication")
	host.population.slots.clear()
	host.stream_job = task
	check(host.spiral_population_target(wanted) == task.coord, "Publication retains ownership until complete")
	check(host.next_population_coord(wanted) == task.coord, "Publication resumes before closer requests")
	wanted.erase(task.coord)
	check(host.spiral_population_target(wanted) == Vector2i.ZERO, "Out-of-range work stops blocking requests")
	host.stream_job = null
	wanted.clear()
	check(host.spiral_population_target(wanted) == null, "Empty queue stays idle")
	check(host.active_view.valid(), "Default staged settings are valid")
	host.active_view.nearby_chunk_fraction = NAN
	check(not host.active_view.valid(), "Nonfinite nearby fraction is rejected")
	host.active_view.nearby_chunk_fraction = 0.5
	host.active_view.distant_chunk_work_ms = 0.0
	check(not host.active_view.valid(), "Zero background budget is rejected")
	host.population.shutdown()
	# This scheduling probe never enters the scene tree; release constructor nodes.
	for node in [host.world,host.pointer_ring,host.surface,host.viewport,host.camera,host.solid_root,host.sun,host.streaming_ground,host.selection,host.player_shadow]:
		node.free()
	host.free()
	print("SPIRAL LOADING: %d checks, %d failures" % [checks,failures])
	quit(0 if failures == 0 else 1)
