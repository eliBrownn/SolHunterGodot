extends RefCounted
## Transient presentation of committed plant events. No ledger or simulation writes.
const KINDS := ["idle","receiving","releasing","repairing","protecting","regulating"]
const MAX_EVENTS := 128
var events: Dictionary = {}
var source_state: Object
var sampled_tick := -1
var observed_seconds := -1.0
var activities: Dictionary = {}
var active_chunks: Dictionary = {}
var last_pose_seconds := -1.0
var last_strength := -1.0
var last_events: Dictionary = {}
var chunk_updates := 0

static func pose(kind: String, age: float, duration: float = 1.6, strength: float = 1.0) -> Basis:
	if age<=0.0 or age>=duration or duration<=0.0: return Basis.IDENTITY
	var phase := age/duration
	var envelope := sin(PI*phase)*sin(PI*phase)*clampf(strength,0.0,2.0)*0.5
	var horizontal := 1.0
	var vertical := 1.0
	var bend := 0.0
	match kind:
		"receiving":
			# Intake is a small rigid sway: no transient growth or stretching.
			return Basis(Vector3.FORWARD,0.035*envelope)
		"releasing":
			horizontal-=0.035*envelope
			vertical-=0.045*envelope
			bend=sin(phase*TAU)*0.045*envelope
		"repairing":
			horizontal+=0.025*envelope
			vertical+=sin(phase*TAU*2.0)*0.025*envelope
		"protecting":
			horizontal+=0.065*envelope
			vertical-=0.05*envelope
		"regulating":
			horizontal+=sin(phase*TAU*2.0)*0.035*envelope
			bend=sin(phase*TAU)*0.025*envelope
	return Basis(Vector3(horizontal,0,0),Vector3(bend,vertical,bend*0.4),Vector3(0,0,horizontal))

func trigger(cell: Vector2i,kind: String,started: float,duration: float) -> void:
	if kind not in KINDS or kind=="idle": return
	var priority := 2 if kind in ["receiving","releasing"] else 1
	if events.has(cell) and events[cell].start+events[cell].duration>started and events[cell].priority>priority: return
	if not events.has(cell) and events.size()>=MAX_EVENTS: events.erase(events.keys()[0])
	events[cell]={"kind":kind,"start":started,"duration":duration,"priority":priority}

func update(state: Object,chunks: Dictionary,focus: Vector2i,strength: float=1.0,duration: float=1.6) -> void:
	var seconds: float=state.activity_seconds()
	duration=clampf(duration,0.5,3.0)
	if source_state!=state or seconds<observed_seconds:
		events.clear()
		activities.clear()
		sampled_tick=-1
		observed_seconds=seconds
		source_state=state
	if state.activity_tick()!=sampled_tick:
		for flight: Dictionary in state.flora_transfers():
			var sent := float(flight.sent)*ExpeditionContract.ACTIVITY_INTERVAL
			if sent>observed_seconds and sent<=seconds:
				trigger(Vector2i(int(flight.source_node.cell[0]),int(flight.source_node.cell[1])),"releasing",sent,duration)
			# Scheduled arrival is insufficient: wait for committed credit evidence.
			if flight.has("credited_tick"):
				var arrived := float(flight.credited_tick)*ExpeditionContract.ACTIVITY_INTERVAL
				if arrived>observed_seconds and arrived<=seconds:
					trigger(Vector2i(int(flight.target_node.cell[0]),int(flight.target_node.cell[1])),"receiving",arrived,duration)
		var active := {}
		for row: Dictionary in state.ecology_plants(focus,64):
			var cell := Vector2i(int(row.cell[0]),int(row.cell[1]))
			if row.activity in ["repairing","protecting","regulating"]:
				active[cell]=row.activity
				if activities.get(cell,"")!=row.activity or not events.has(cell): trigger(cell,row.activity,seconds,duration)
		activities=active
		sampled_tick=state.activity_tick()
		observed_seconds=seconds
	for cell in events.keys():
		if seconds>=events[cell].start+events[cell].duration: events.erase(cell)
	# Route by canonical cell rather than scanning every event in every chunk.
	var routed := {}
	for cell: Vector2i in events:
		var coord := Vector2i(WorldTerrain.floor_div(cell.x,16),WorldTerrain.floor_div(cell.y,16))
		if not routed.has(coord): routed[coord]={}
		routed[coord][cell]=events[cell]
	var wanted := active_chunks.duplicate()
	for coord in routed:
		if chunks.has(coord):
			if wanted.has(coord) and is_instance_valid(wanted[coord]) and wanted[coord]!=chunks[coord]:
				wanted[coord].apply_plant_animations({},seconds,strength)
			wanted[coord]=chunks[coord]
	for coord in wanted:
		if not is_instance_valid(wanted[coord]): continue
		var chunk: Node3D = wanted[coord]
		# Restore retired/cached nodes too, so re-admission never retains a stale pose.
		var local: Dictionary = routed.get(coord,{}) if chunks.get(coord)==chunk else {}
		if seconds!=last_pose_seconds or strength!=last_strength or events!=last_events or active_chunks.get(coord)!=chunk or local.is_empty():
			chunk.apply_plant_animations(local,seconds,strength)
			chunk_updates+=1
	active_chunks.clear()
	for coord in routed:
		if chunks.has(coord): active_chunks[coord]=chunks[coord]
	last_pose_seconds=seconds
	last_strength=strength
	last_events=events.duplicate()
