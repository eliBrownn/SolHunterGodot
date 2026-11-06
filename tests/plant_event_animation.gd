extends SceneTree
const PlantMotion = preload("res://scripts/presentation/plant_animation.gd")
const Chunk = preload("res://scripts/presentation/solid_chunk.gd")
var checks := 0
var failures := 0
class EventState extends RefCounted:
	var seconds := 0.0
	var tick := 0
	var flights: Array[Dictionary] = []
	var plants: Array[Dictionary] = []
	func activity_seconds() -> float: return seconds
	func activity_tick() -> int: return tick
	func flora_transfers() -> Array[Dictionary]: return flights.duplicate(true)
	func ecology_plants(_focus: Vector2i,_limit: int) -> Array[Dictionary]: return plants.duplicate(true)
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok:
		failures+=1
		push_error(message)
func _initialize() -> void: run.call_deferred()
func run() -> void:
	for kind in PlantMotion.KINDS:
		check(PlantMotion.pose(kind,0.0)==Basis.IDENTITY,"Starts at rest")
		check(PlantMotion.pose(kind,1.6)==Basis.IDENTITY,"Ends exactly at rest")
		check(PlantMotion.pose(kind,0.8,1.6,0.0)==Basis.IDENTITY,"Zero strength is rest")
		check(PlantMotion.pose(kind,0.8).is_finite(),"Finite event pose")
	var library = preload("res://scripts/scenery/plant_library.gd")
	var definition: Resource=library.procedural_definition(1,{"role":"reservoir","class":""},0)
	var model: Dictionary=library.model(definition)
	var chunk := Chunk.new()
	root.add_child(chunk)
	for index in range(4):
		var point: Vector3=[Vector3(0.5,0,0.5),Vector3(1.5,0,0.5),Vector3(2.5,0,0.5),Vector3(0.8,0,0.8)][index]
		var transform := Transform3D(Basis.IDENTITY,point)
		chunk.add_composed_nature({"asset":definition.plant_id,"model":model,"patch":"authored_plant","transform":transform,"bounds":transform*model.bounds,"cell":Vector2i(floori(point.x),floori(point.z)),"category":"tree","living":index!=2})
	chunk.finish()
	var source_cell := Vector2i.ZERO
	var target_cell := Vector2i.RIGHT
	check(chunk.plant_instances.size()==2,"Only explicitly living models animate")
	check(chunk.plant_instances[Vector2i.ZERO].values()[0].indices.size()==2,"Clumps sharing a cell retain separate ground pivots")
	var group: Dictionary=chunk.plant_instances[source_cell].values()[0]
	var target: Dictionary=chunk.plant_instances[target_cell].values()[0]
	var rest: Transform3D=group.mesh.get_instance_transform(group.indices[0])
	var target_rest: Transform3D=target.mesh.get_instance_transform(target.indices[0])
	var static_rest: Transform3D=group.mesh.get_instance_transform(2)
	var state := EventState.new()
	var animator := PlantMotion.new()
	var chunks := {Vector2i.ZERO:chunk}
	animator.update(state,chunks,Vector2i.ZERO)
	state.seconds=0.95
	state.tick=1
	state.flights=[{"sent":1,"arrival":2,"source_node":{"cell":[0,0]},"target_node":{"cell":[1,0]},"pending":true}]
	var before := state.flights.duplicate(true)
	animator.update(state,chunks,Vector2i.ZERO)
	check(animator.events[source_cell].kind=="releasing","Real send triggers a release")
	var deformed: Transform3D=group.mesh.get_instance_transform(group.indices[0])
	check(not deformed.is_equal_approx(rest),"Event moves the batched plant")
	check((deformed*rest.affine_inverse()*group.pivot).is_equal_approx(group.pivot),"Ground pivot remains fixed")
	check(target.mesh.get_instance_transform(target.indices[0]).is_equal_approx(target_rest),"Shared model's other cell stays still")
	check(group.mesh.get_instance_transform(2).is_equal_approx(static_rest),"Nonliving instance of the same mesh stays unchanged")
	animator.update(state,chunks,Vector2i.ZERO)
	check(group.mesh.get_instance_transform(group.indices[0]).is_equal_approx(deformed),"Paused clock freezes without transform drift")
	state.seconds=1.7
	state.tick=2
	animator.update(state,chunks,Vector2i.ZERO)
	check(not animator.events.has(target_cell),"Scheduled arrival alone cannot animate receiving")
	state.flights[0]["credited_tick"]=3
	state.flights[0].pending=false
	state.seconds=2.45
	state.tick=3
	animator.update(state,chunks,Vector2i.ZERO)
	check(animator.events[target_cell].kind=="receiving","Committed arrival triggers receiving")
	check(not target.mesh.get_instance_transform(target.indices[0]).is_equal_approx(target_rest),"Receiver moves independently")
	animator.update(state,chunks,Vector2i.ZERO,0.0)
	check(target.mesh.get_instance_transform(target.indices[0]).is_equal_approx(target_rest),"Disabling strength restores the model")
	state.seconds=5.0
	state.tick=6
	animator.update(state,chunks,Vector2i.ZERO)
	check(animator.events.is_empty(),"Expired transfers do not replay")
	check(group.mesh.get_instance_transform(group.indices[0]).is_equal_approx(rest) and not group.has("rest"),"Restored instance releases transient baseline storage")
	for activity in ["repairing","protecting","regulating"]:
		state.seconds+=2.0
		state.tick+=3
		state.plants=[{"cell":[1,0],"activity":activity}]
		animator.update(state,chunks,Vector2i.ZERO)
		check(animator.events[target_cell].kind==activity,"Specialist activity drives "+activity)
	animator.update(EventState.new(),chunks,Vector2i.ZERO)
	check(animator.events.is_empty() and target.mesh.get_instance_transform(target.indices[0]).is_equal_approx(target_rest),"New expedition clears stale reactions")
	check(before[0].pending and before[0].sent==1,"Read-only projections retain original event data")
	var saved := ExpeditionState.new(17)
	var snapshot := saved.snapshot()
	animator.update(saved,chunks,Vector2i.ZERO)
	check(saved.snapshot()==snapshot,"Real expedition projection stays read-only")
	for index in range(150): animator.trigger(Vector2i(index,0),"receiving",1.0,1.6)
	check(animator.events.size()==PlantMotion.MAX_EVENTS,"Transient animation work has a fixed bound")
	chunk.free()
	print("PLANT EVENT ANIMATION: %d checks, %d failures"%[checks,failures])
	quit(1 if failures else 0)
