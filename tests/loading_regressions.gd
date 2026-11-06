extends "res://tests/runtime_optimization.gd"
const Motion = preload("res://scripts/presentation/plant_animation.gd")
const Filaments = preload("res://scripts/presentation/vastra_filament_renderer.gd")
class EventState extends RefCounted:
	var seconds := 1.0
	func activity_seconds() -> float: return seconds
	func activity_tick() -> int: return 0
	func flora_transfers() -> Array[Dictionary]: return []
	func ecology_plants(_focus: Vector2i,_limit: int) -> Array[Dictionary]: return []
class AnimationChunk extends Node3D:
	var calls := 0
	var received := {}
	func apply_plant_animations(events: Dictionary,_seconds: float,_strength: float) -> void:
		calls+=1
		received=events.duplicate(true)
func run() -> void:
	var state := EventState.new()
	var animator := Motion.new()
	var near := AnimationChunk.new()
	var far := AnimationChunk.new()
	var chunks := {Vector2i(-1,-1):near,Vector2i(5,5):far}
	animator.update(state,chunks,Vector2i.ZERO)
	animator.trigger(Vector2i(-1,-1),"receiving",1.0,1.6)
	state.seconds=1.2
	animator.update(state,chunks,Vector2i.ZERO)
	check(near.received.has(Vector2i(-1,-1)) and far.calls==0,"Negative cells route only to their owner chunk")
	var calls: int=near.calls
	animator.update(state,chunks,Vector2i.ZERO)
	check(near.calls==calls,"Paused unchanged poses skip transform work")
	chunks.erase(Vector2i(-1,-1))
	animator.update(state,chunks,Vector2i.ZERO)
	check(near.received.is_empty(),"Cached retired chunks restore before re-admission")
	near.free()
	far.free()
	var scene: Node3D=load("res://scenes/world_3d.tscn").instantiate()
	root.add_child(scene)
	var world: Node2D=scene.world
	world.smoke_mode=true
	check(world.chunks.size()==1 and not world.pending.is_empty(),"Only the player detail chunk blocks initial loading")
	var planes: Array[Plane]=scene.camera.get_frustum()
	for coord: Vector2i in world.pending:
		if preload("res://scripts/presentation/view_streaming.gd").visible_with_planes(planes,Vector2(coord*16)-world.camera.position/32.0,scene.height_bound(),0.0,-scene.height_bound()):
			check(scene.streaming_ground.chunks.has(coord),"Every pending visible chunk has initial coarse ground")
	# Cold fallback coverage must not prevent detail from reaching publication.
	# Keep a bounded real production queue and advance normal frame scheduling.
	world.pending.resize(mini(2, world.pending.size()))
	var requested: Array[Vector2i] = world.pending.duplicate()
	scene.streaming_ground.clear()
	var generation_before: Dictionary = world.terrain.relief.duplicate(true)
	for frame in range(20000):
		if world.pending.is_empty(): break
		world._process(0.0)
	check(world.pending.is_empty(), "Cold coverage and detailed chunks both finish through normal frame scheduling")
	for coord: Vector2i in requested:
		check(scene.solid_chunks.has(coord) and not scene.streaming_ground.chunks.has(coord), "Published detail replaces temporary ground")
	check(world.terrain.relief == generation_before, "Streaming completion does not change captured generation settings")
	world.prepare_flora(Time.get_ticks_usec()+100000)
	var data := ExpeditionSave.snapshot(world.terrain.world_seed,world.cell,false,false,world.terrain.generation_version,world.terrain.climate,world.persistent_state.snapshot(),world.terrain.relief,world.terrain.scenery_parameters)
	check(not data.world_state.flora.nodes.is_empty(),"Save fixture includes registered living plants")
	var candidate := ExpeditionSave.prepare(data)
	check(not candidate.is_empty(),"Current save prepares a validated load candidate")
	if not candidate.is_empty():
		check(candidate.state.snapshot()==world.persistent_state.snapshot(),"Prepared state preserves the saved expedition")
		check(candidate.terrain.extract_chunk(Vector2i.ZERO)==world.terrain.extract_chunk(Vector2i.ZERO),"Retained validation terrain matches generation")
	var bad := data.duplicate(true)
	bad.world_state.version=-1
	check(ExpeditionSave.prepare(bad).is_empty(),"Malformed state cannot bypass candidate validation")
	bad=data.duplicate(true)
	bad.player=[0.5,0]
	check(ExpeditionSave.prepare(bad).is_empty(),"Malformed player cannot bypass candidate validation")
	var current: Node3D
	for child in scene.get_children():
		if child.get_script()==preload("res://scripts/presentation/vastra_currents.gd"): current=child
	current.set_process(false)
	current.tuning=current.tuning.duplicate(true)
	current.tuning.particle_filaments=VastraParticleSettings.new()
	current.tuning.current_light_limit=0
	current.last_particle_clock=-123.0
	current.sync_wisps()
	check(current.last_particle_clock==-123.0 and not current.particle_batch.visible,"Filaments skip invisible legacy particle work")
	var renderer: Node3D=current.filament_renderer
	var points := PackedVector3Array()
	for index in range(9): points.append(Vector3(index,1,0))
	current.network_edges=[{"points":points,"flight":{"id":"cache-test","sent":0,"arrival":20}}]
	renderer.sync(current)
	var uploads: int=renderer.path_uploads
	var uniforms: int=renderer.uniform_uploads
	renderer.sync(current)
	check(renderer.uniform_uploads==uniforms,"Paused unchanged filaments skip uniform uploads")
	check(renderer.path_uploads==uploads,"Unchanged transfer paths are uploaded once")
	current.batch_origin+=Vector2i(16,0)
	renderer.sync(current)
	check(renderer.path_uploads==uploads+1,"Origin changes invalidate filament path uploads")
	current.network_edges[0].points[1]+=Vector3.UP
	renderer.sync(current)
	check(renderer.path_uploads==uploads+2,"In-place path edits invalidate filament uploads")
	scene.environment.sky=null
	scene.free()
	print("LOADING REGRESSIONS: %d checks, %d failures"%[checks,failures])
	quit(1 if failures else 0)
