extends RefCounted
## Consumer-owned validation memo. Snapshots retain values/IDs, never Resources.
## Direct nested edits, array edits, replacements and repacked scene roots invalidate it.
const Fields = preload("res://scripts/resource_storage_fields.gd")
var snapshot: Array = []
var result := false
var validation_runs := 0

func check(resource: Resource, dependencies: Array = []) -> bool:
	if resource == null:
		return false
	var roots: Array = [resource]
	roots.append_array(dependencies)
	if not snapshot.is_empty() and matches(snapshot, roots):
		return result
	snapshot = capture(roots, {})
	validation_runs += 1
	result = resource.valid()
	return result

func capture(value: Variant, seen: Dictionary) -> Array:
	var kind := typeof(value)
	if value is Resource:
		var id: int = value.get_instance_id()
		if seen.has(id):
			return [kind, id]
		seen[id] = true
		if value is PackedScene:
			var state: SceneState = value.get_state()
			var properties: Array = []
			if state.get_node_count() > 0:
				for index in range(state.get_node_property_count(0)):
					properties.append([state.get_node_property_name(0, index), capture(state.get_node_property_value(0, index), seen)])
			return [kind, id, -1, value.can_instantiate(), properties]
		var script: Script = value.get_script()
		if script == null:
			return [kind, id]
		var properties: Array = []
		for field in Fields.for_resource(value):
			# These engine bookkeeping fields are not inputs to tuning validators.
			if field in [&"resource_local_to_scene", &"resource_name", &"resource_path"] or str(field).begins_with("metadata/"):
				continue
			properties.append([field, capture(value.get(field), seen)])
		return [kind, id, script.get_instance_id(), properties]
	if value is Array:
		var entries: Array = []
		for entry in value:
			entries.append(capture(entry, seen))
		return [kind, entries]
	if value is Dictionary:
		var entries: Array = []
		for key in value:
			entries.append([capture(key, seen), capture(value[key], seen)])
		return [kind, entries]
	return [kind, value.duplicate() if kind >= TYPE_PACKED_BYTE_ARRAY else value]

func matches(saved: Array, value: Variant) -> bool:
	if saved[0] != typeof(value):
		return false
	if value is Resource:
		if saved[1] != value.get_instance_id():
			return false
		if saved.size() == 2:
			return true
		if saved[2] == -1:
			if not value is PackedScene or saved[3] != value.can_instantiate():
				return false
			var state: SceneState = value.get_state()
			var count := state.get_node_property_count(0) if state.get_node_count() > 0 else 0
			if count != saved[4].size():
				return false
			for index in range(count):
				if state.get_node_property_name(0, index) != saved[4][index][0] or not matches(saved[4][index][1], state.get_node_property_value(0, index)):
					return false
			return true
		var script: Script = value.get_script()
		if script == null or script.get_instance_id() != saved[2]:
			return false
		for field in saved[3]:
			var previous: Array = field[1]
			var current: Variant = value.get(field[0])
			if previous[0] != TYPE_OBJECT and previous[0] != TYPE_ARRAY and previous[0] != TYPE_DICTIONARY:
				# Most exported tuning is scalar or packed arrays. Avoid recursive
				# GDScript dispatch for each unchanged leaf in the resource graph.
				if previous[0] != typeof(current) or previous[1] != current:
					return false
			elif not matches(previous, current):
				return false
		return true
	if value is Array:
		if saved[1].size() != value.size():
			return false
		for index in range(value.size()):
			if not matches(saved[1][index], value[index]):
				return false
		return true
	if value is Dictionary:
		if saved[1].size() != value.size():
			return false
		var keys: Array = value.keys()
		for index in range(keys.size()):
			if not matches(saved[1][index][0], keys[index]) or not matches(saved[1][index][1], value[keys[index]]):
				return false
		return true
	return saved[1] == value
