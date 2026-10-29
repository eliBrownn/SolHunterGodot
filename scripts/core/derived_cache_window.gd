extends RefCounted
## FIFO eviction for disposable derived values. Never stores authoritative state.
var capacity: int
var keys: Array = []
var cursor := 0

func _init(limit: int) -> void:
	capacity = maxi(1, limit)

func store(values: Dictionary, key: Variant, value: Variant) -> void:
	# Callers may explicitly clear their derived dictionaries during a rebuild.
	if values.is_empty():
		keys.clear()
		cursor = 0
	if not values.has(key):
		if keys.size() < capacity:
			keys.append(key)
		else:
			values.erase(keys[cursor])
			keys[cursor] = key
			cursor = (cursor + 1) % capacity
	values[key] = value
