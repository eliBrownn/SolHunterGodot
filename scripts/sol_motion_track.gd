class_name SolMotionTrack
extends RefCounted
## Bounded display-only replay of committed cardinal steps. Never changes domain cells.

const MAX_SEGMENTS := 8 # Recovery ceiling, not a balance slider. Normal clock catch-up is at most two ticks.
var position := Vector2.ZERO
var target := Vector2i.ZERO
var segments: Array[Dictionary] = []

func reset(cell: Vector2i) -> void:
	position = Vector2(cell)
	target = cell
	segments.clear()

func append(cell: Vector2i, seconds: float) -> void:
	if cell == target:
		return
	var change := cell - target
	if not is_finite(seconds) or seconds <= 0 or absi(change.x) + absi(change.y) != 1 or segments.size() >= MAX_SEGMENTS:
		reset(cell) # An unobserved relocation/overflow is not a route we can invent.
		return
	segments.append({"from": Vector2(target), "to": Vector2(cell), "seconds": maxf(0.001, seconds), "elapsed": 0.0})
	target = cell

func advance(delta: float) -> Vector2:
	var remaining := maxf(0, delta)
	while remaining > 0 and not segments.is_empty():
		var segment: Dictionary = segments[0]
		var used := minf(remaining, float(segment.seconds) - float(segment.elapsed))
		segment.elapsed += used
		remaining -= used
		position = Vector2(segment.from).lerp(segment.to, clampf(float(segment.elapsed) / float(segment.seconds), 0, 1))
		if float(segment.seconds) - float(segment.elapsed) <= 0.00000001:
			position = segment.to
			segments.pop_front()
	return position
