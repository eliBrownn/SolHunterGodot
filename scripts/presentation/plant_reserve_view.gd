extends RefCounted
## Bounded visual projection of saved reserves onto registered leaf instances.
## No plant admission, transfers, transforms or material copies occur here.
var source_id := 0
var known_chunks: Dictionary = {}
var order: Array = []
var chunk_cursor := 0
var sampled_tick := -1
var remaining := 0
var last_view := Vector3.INF
var last_radius := INF

func update(state: ExpeditionState, chunks: Dictionary, limit: int = 64, view: Vector3 = Vector3.INF, radius: float = INF) -> void:
	if source_id != state.get_instance_id():
		source_id = state.get_instance_id()
		known_chunks.clear()
		order.clear()
	var changed := false
	for coord in known_chunks.keys():
		if not chunks.has(coord) or known_chunks[coord].chunk.get_ref() != chunks[coord]:
			known_chunks.erase(coord)
			changed = true
	for coord in chunks:
		var chunk: Node3D = chunks[coord]
		if not known_chunks.has(coord) or known_chunks[coord].cells.size() != chunk.plant_instances.size():
			# Capture only the new/replaced parent's cell list, not every live cell.
			known_chunks[coord] = {"chunk": weakref(chunk), "cells": chunk.plant_instances.keys(), "cursor": 0}
			changed = true
	if changed:
		order = known_chunks.keys()
		chunk_cursor = 0
	if order.is_empty(): return
	var refill_step := floori(state.activity_seconds()/(ExpeditionContract.ACTIVITY_INTERVAL/6.0))
	if changed or sampled_tick != refill_step or view != last_view or radius != last_radius:
		last_radius = radius
		last_view = view
		remaining = 0
		for row in known_chunks.values(): remaining += maxi(1, row.cells.size())
		sampled_tick = refill_step
	for index in range(mini(clampi(limit, 1, 256), remaining)):
		remaining -= 1
		var row: Dictionary = known_chunks[order[chunk_cursor]]
		var chunk: Node3D = row.chunk.get_ref()
		if row.cells.is_empty() or not is_instance_valid(chunk):
			chunk_cursor = (chunk_cursor + 1) % order.size()
			continue
		var cell: Vector2i = row.cells[row.cursor]
		row.cursor = (int(row.cursor) + 1) % row.cells.size()
		if row.cursor == 0: chunk_cursor = (chunk_cursor + 1) % order.size()
		if view.is_finite() and radius > 0 and Vector2(cell).distance_to(Vector2(view.x, view.z)) > radius + 2.0: continue
		var fraction := state.flora_reserve_fraction(cell)
		if fraction >= 0.0:
			chunk.apply_plant_reserve(cell,fraction,state.activity_seconds())
