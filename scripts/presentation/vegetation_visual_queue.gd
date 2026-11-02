extends RefCounted
## Shared fair queue for derived vegetation writes; never owns ecological state.
var jobs: Dictionary = {}
var order: Array = []
var head := 0
var active_owners: Dictionary = {}
var last_writes := 0
var total_writes := 0

func begin_frame(chunks: Dictionary) -> void:
	var active := {}
	for chunk in chunks.values(): active[chunk.get_instance_id()] = true
	var removed := false
	for key in jobs.keys():
		if not active.has(jobs[key].owner_id) or jobs[key].owner.get_ref() == null:
			jobs.erase(key)
			removed = true
	if removed:
		var retained: Array = []
		for index in range(head, order.size()):
			if jobs.has(order[index]): retained.append(order[index])
		order = retained
		head = 0
	# A cached chunk may have left with partially applied visual data. Re-admit
	# it from canonical reserve readings and its original rest transforms.
	for chunk in chunks.values():
		if active_owners.has(chunk.get_instance_id()): continue
		for cell in chunk.plant_instances:
			for group in chunk.plant_instances[cell].values():
				group.erase("reserve_level")
				if group.has("rest"):
					enqueue(chunk, cell, group, "pose", {"shape": Basis.IDENTITY, "rest": group.rest, "individual_roots": group.individual_roots, "pivot": group.pivot})
	active_owners = active
	last_writes = 0

func enqueue(owner: Node3D, cell: Vector2i, group: Dictionary, channel: String, value: Variant) -> void:
	if group.indices.is_empty(): return
	var key := "%d:%s:%d:%d:%s" % [owner.get_instance_id(), str(cell), group.mesh.get_instance_id(), group.indices[0], channel]
	if jobs.has(key):
		var job: Dictionary = jobs[key]
		# Earlier instances in a partial sweep must eventually receive the latest value too.
		if job.cursor > 0: job.again = true
		job.value = value
		return
	jobs[key] = {"owner": weakref(owner), "owner_id": owner.get_instance_id(),
		"mesh": weakref(group.mesh), "indices": group.indices, "channel": channel,
		"value": value, "cursor": 0, "again": false}
	order.append(key)

func drain(limit: int = 512) -> int:
	var left := maxi(0, limit)
	while left > 0 and head < order.size():
		var key: String = order[head]
		head += 1
		if not jobs.has(key): continue
		var job: Dictionary = jobs[key]
		var mesh: MultiMesh = job.mesh.get_ref()
		if mesh == null or job.owner.get_ref() == null:
			jobs.erase(key)
			continue
		var count := mini(32, mini(left, job.indices.size() - int(job.cursor)))
		for offset in range(count):
			var position: int = int(job.cursor) + offset
			var index: int = job.indices[position]
			if job.channel == "reserve":
				mesh.set_instance_custom_data(index, job.value)
			else:
				var value: Dictionary = job.value
				var rest: Transform3D = value.rest[position]
				var pivot: Vector3 = rest.origin if value.individual_roots else value.pivot
				mesh.set_instance_transform(index, Transform3D(value.shape, pivot - value.shape * pivot) * rest)
		job.cursor += count
		left -= count
		last_writes += count
		if job.cursor == job.indices.size():
			if job.again:
				job.cursor = 0
				job.again = false
			else:
				jobs.erase(key)
		if jobs.has(key): order.append(key)
	if head == order.size() or head > 1024:
		order = order.slice(head)
		head = 0
	total_writes += last_writes
	return last_writes
