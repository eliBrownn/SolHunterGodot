class_name TerrainDrainage
extends RefCounted
## Finite-grid Priority-Flood analysis. Boundary outlets are explicit study/local-catchment limits.
## Receivers and accumulation are derived data, never a render or ecology authority.

static func less(a: Vector2, b: Vector2) -> bool:
	return a.x < b.x or (a.x == b.x and a.y < b.y)

static func push(heap: Array[Vector2], item: Vector2) -> void:
	heap.append(item)
	var child := heap.size() - 1
	while child > 0:
		var parent := (child - 1) / 2
		if not less(heap[child], heap[parent]):
			break
		var swap := heap[parent]
		heap[parent] = heap[child]
		heap[child] = swap
		child = parent

static func pop(heap: Array[Vector2]) -> Vector2:
	var item := heap[0]
	var last: Vector2 = heap.pop_back()
	if heap.is_empty():
		return item
	heap[0] = last
	var parent := 0
	while parent * 2 + 1 < heap.size():
		var child := parent * 2 + 1
		if child + 1 < heap.size() and less(heap[child + 1], heap[child]):
			child += 1
		if not less(heap[child], heap[parent]):
			break
		var swap := heap[parent]
		heap[parent] = heap[child]
		heap[child] = swap
		parent = child
	return item

static func analyze(heights: PackedFloat64Array, width: int, height: int) -> Dictionary:
	if width < 2 or height < 2 or width * height > 65536 or heights.size() != width * height:
		return {}
	for value in heights:
		if not is_finite(value):
			return {}
	var filled := heights.duplicate()
	var receivers := PackedInt32Array()
	var visited := PackedByteArray()
	var accumulation := PackedInt32Array()
	receivers.resize(heights.size())
	receivers.fill(-1)
	visited.resize(heights.size())
	accumulation.resize(heights.size())
	accumulation.fill(1)
	var heap: Array[Vector2] = []
	var order := PackedInt32Array()
	for y in range(height):
		for x in range(width):
			if x == 0 or y == 0 or x == width - 1 or y == height - 1:
				var index := y * width + x
				visited[index] = 1
				push(heap, Vector2(filled[index], index))
	while not heap.is_empty():
		var item := pop(heap)
		var index := int(item.y)
		order.append(index)
		var at := Vector2i(index % width, index / width)
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				var next := at + Vector2i(dx, dy)
				if next.x < 0 or next.y < 0 or next.x >= width or next.y >= height:
					continue
				var neighbor := next.y * width + next.x
				if visited[neighbor] != 0:
					continue
				visited[neighbor] = 1
				receivers[neighbor] = index
				filled[neighbor] = maxf(heights[neighbor], filled[index])
				push(heap, Vector2(filled[neighbor], neighbor))
	for offset in range(order.size() - 1, -1, -1):
		var index := order[offset]
		if receivers[index] >= 0:
			accumulation[receivers[index]] += accumulation[index]
	return {"filled": filled, "receivers": receivers, "accumulation": accumulation, "order": order}
