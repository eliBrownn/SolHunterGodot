extends RefCounted
## Eight detail levels drawn from the same authored tree surfaces.

const DISTANCES := [512.0, 608.0, 704.0, 896.0, 1152.0, 1408.0, 1792.0]
const BLEND_DISTANCE := 32.0
const AUTHORED_FRACTIONS := [1.0, 0.75, 0.48, 0.30, 0.18, 0.09, 0.045, 0.02]
const FORCED_REDUCTION_START := 6
const LEAF_CARDS_SHADER := preload("res://shaders/tree_leaf_cards.gdshader")


static func tier(distance: float) -> int:
	var level := 0
	while level < DISTANCES.size() and distance >= DISTANCES[level]:
		level += 1
	return level


static func blend(distance: float, level: int) -> float:
	if level == 0:
		return 1.0
	var start: float = DISTANCES[level - 1]
	return smoothstep(start, start + BLEND_DISTANCE, distance)


static func build(pieces: Array, bounds: AABB) -> Array[Mesh]:
	var levels: Array[Mesh] = []
	for level in AUTHORED_FRACTIONS.size():
		var mesh := ArrayMesh.new()
		mesh.custom_aabb = bounds
		levels.append(mesh)
	for piece: Dictionary in pieces:
		var source: ArrayMesh = piece.mesh
		for surface in source.get_surface_count():
			var material := source.surface_get_material(surface)
			var arrays := source.surface_get_arrays(surface)
			var original: Variant = arrays[Mesh.ARRAY_INDEX]
			var can_thin_cards: bool = material is ShaderMaterial and material.shader == LEAF_CARDS_SHADER \
				and _is_card_index_set(original)
			var previous: Variant = original
			for level in AUTHORED_FRACTIONS.size():
				var reduced := arrays.duplicate()
				if level > 0:
					previous = _authored_indices(arrays, piece.lod_indices, level, can_thin_cards, previous)
					reduced[Mesh.ARRAY_INDEX] = previous
				var mesh: ArrayMesh = levels[level]
				mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, reduced)
				mesh.surface_set_material(mesh.get_surface_count() - 1, material)
	return levels


static func _is_card_index_set(indices: Variant) -> bool:
	if indices == null or indices.is_empty() or indices.size() % 6 != 0:
		return false
	# Each authored leaf card consists of two adjacent triangles sharing an edge.
	for offset in range(0, indices.size(), 6):
		var shared := 0
		for second in range(offset + 3, offset + 6):
			for first in range(offset, offset + 3):
				if indices[first] == indices[second]:
					shared += 1
		if shared != 2:
			return false
	return true


static func _authored_indices(arrays: Array, lods: Array[PackedInt32Array], level: int,
		thin_cards: bool, previous: Variant) -> Variant:
	var original: Variant = arrays[Mesh.ARRAY_INDEX]
	var count: int = original.size() if original != null and not original.is_empty() else arrays[Mesh.ARRAY_VERTEX].size()
	var target: float = count * AUTHORED_FRACTIONS[level]
	if thin_cards:
		if level == 1:
			return original
		var cards := count / 6
		var remaining := maxi(1, roundi(cards * sqrt(AUTHORED_FRACTIONS[level])))
		return _thin_faces(original, count, remaining, 6)
	var best: Variant = original
	var error := count - target
	for indices in lods:
		if indices.is_empty() or indices.size() >= count or (level == 1 and indices.size() < count * 0.5):
			continue
		var candidate := absf(indices.size() - target)
		if candidate <= error:
			best = indices
			error = candidate
	if level < FORCED_REDUCTION_START:
		return best
	# The last two levels keep reducing even after the simplifier runs out
	# of candidates. Fall back to thinning complete triangles from its output.
	var previous_count: int = previous.size() if previous != null and not previous.is_empty() else count
	var remaining := clampi(roundi(target / 3.0), 1, maxi(1, previous_count / 3 - 1))
	var best_count: int = best.size() if best != null and not best.is_empty() else count
	if best_count <= remaining * 3:
		return best
	if previous_count < best_count:
		best = previous
		best_count = previous_count
	return _thin_faces(best, best_count, remaining, 3)


static func _thin_faces(indices: Variant, count: int, remaining: int, stride: int) -> PackedInt32Array:
	var retained := PackedInt32Array()
	for index in remaining:
		var first := floori((float(index) + 0.5) * (count / stride) / remaining) * stride
		for corner in stride:
			retained.append(indices[first + corner] if indices != null and not indices.is_empty() else first + corner)
	return retained
