extends RefCounted
## Atlas-scale drainage and bounded, gravity-fed irrigation.

const RIVER_THRESHOLD := 140.0
const INTAKE_SPACING := 36
const IRRIGATION_REACH := 8
const CARDINAL := [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]

var receivers: PackedInt32Array
var rivers := PackedFloat32Array()
var lakes := PackedFloat32Array()
# Zero is dry. Positive values are the supplying intake index plus one.
var irrigation := PackedInt32Array()

var _size: Vector2i
var _elevation: PackedFloat32Array


func _init(size: Vector2i, elevation: PackedFloat32Array, moisture: PackedFloat32Array,
		temperature: PackedFloat32Array) -> void:
	_size = size
	_elevation = elevation
	var count := elevation.size()
	rivers.resize(count)
	lakes.resize(count)
	irrigation.resize(count)
	var drainage := TerrainDrainage.analyze(PackedFloat64Array(Array(elevation)), size.x, size.y, count)
	receivers = drainage.receivers
	var order: PackedInt32Array = drainage.order
	var runoff := PackedFloat32Array()
	runoff.resize(count)
	for offset in range(order.size() - 1, -1, -1):
		var index := order[offset]
		if elevation[index] <= 0.0:
			continue
		runoff[index] += 0.08 + moisture[index] * moisture[index]
		if runoff[index] >= RIVER_THRESHOLD:
			rivers[index] = runoff[index]
		if receivers[index] >= 0:
			runoff[receivers[index]] += runoff[index]
	_fill_lakes(drainage.filled, runoff)
	_build_irrigation(moisture, temperature)


func _fill_lakes(filled: PackedFloat64Array, runoff: PackedFloat32Array) -> void:
	var seen := PackedByteArray()
	seen.resize(_elevation.size())
	for index in _elevation.size():
		if seen[index] or _elevation[index] <= 0.0 or filled[index] - _elevation[index] <= 0.0015:
			continue
		var level := filled[index]
		var basin := PackedInt32Array([index])
		var cursor := 0
		var deepest := 0.0
		var supply := 0.0
		seen[index] = 1
		while cursor < basin.size():
			var cell := basin[cursor]
			cursor += 1
			var at := _cell(cell)
			deepest = maxf(deepest, level - _elevation[cell])
			supply = maxf(supply, runoff[cell])
			for direction in CARDINAL:
				var next := _index(at + direction)
				if next < 0 or seen[next] or _elevation[next] <= 0.0:
					continue
				if absf(filled[next] - level) < 0.000001 and level - _elevation[next] > 0.0015:
					seen[next] = 1
					basin.append(next)
		if basin.size() >= 12 and deepest >= 0.008 and supply >= 35.0:
			for cell in basin:
				lakes[cell] = level


func _build_irrigation(moisture: PackedFloat32Array, temperature: PackedFloat32Array) -> void:
	var intakes: Dictionary[Vector2i, int] = {}
	var scores: Dictionary[Vector2i, float] = {}
	for index in rivers.size():
		var height := _elevation[index]
		if rivers[index] < 190.0 or lakes[index] > 0.0 or height < 0.045 or height > 0.42:
			continue
		if temperature[index] < 0.34 or moisture[index] > 0.62 or receivers[index] < 0:
			continue
		var drop := absf(height - _elevation[receivers[index]])
		if drop > 0.012:
			continue
		var sector := _cell(index) / INTAKE_SPACING
		var score := (0.70 - moisture[index]) * 100.0 + minf(rivers[index], 1500.0) / 75.0 - drop * 1500.0
		if score > scores.get(sector, -INF):
			scores[sector] = score
			intakes[sector] = index
	for source: int in intakes.values():
		_irrigate_from(source, moisture, temperature)


func _irrigate_from(source: int, moisture: PackedFloat32Array, temperature: PackedFloat32Array) -> void:
	var head := _elevation[source]
	var budget := clampi(int(rivers[source] / 12.0), 15, 58)
	var queue := PackedInt32Array([source])
	var steps := PackedByteArray([0])
	var seen := {source: true}
	var cursor := 0
	while cursor < queue.size() and budget > 0:
		var cell := queue[cursor]
		var distance := int(steps[cursor])
		cursor += 1
		if distance >= IRRIGATION_REACH:
			continue
		var at := _cell(cell)
		for direction in CARDINAL:
			var next := _index(at + direction)
			if next < 0 or seen.has(next):
				continue
			var height := _elevation[next]
			if height < head - 0.032 or height > head + 0.001 or height <= 0.0:
				continue
			if rivers[next] > 0.0 or lakes[next] > 0.0 or irrigation[next] > 0:
				continue
			if temperature[next] < 0.32 or moisture[next] > 0.65:
				continue
			if absf(height - _elevation[cell]) > 0.010:
				continue
			seen[next] = true
			irrigation[next] = source + 1
			queue.append(next)
			steps.append(distance + 1)
			budget -= 1
			if budget == 0:
				break


func _cell(index: int) -> Vector2i:
	return Vector2i(index % _size.x, index / _size.x)


func _index(cell: Vector2i) -> int:
	if cell.x < 0 or cell.y < 0 or cell.x >= _size.x or cell.y >= _size.y:
		return -1
	return cell.y * _size.x + cell.x
