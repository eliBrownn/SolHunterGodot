extends RefCounted
## Appearance-only exploration. Each feature has its own deterministic stream.
const Document = preload("res://tools/sol_lab_document.gd")

static func settings() -> Dictionary:
	return {"seed": 1, "strength": 0.25, "locks": {}}

static func valid(value: Variant) -> bool:
	return Document.valid_exploration(value)

static func generate(parent: Dictionary, setup: Dictionary, count: int = 6) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	if not Document.valid(parent) or not valid(setup) or count < 1 or count > 12: return results
	parent = Document.resolved(parent)
	for index in count:
		var candidate := Document.resolved(parent).duplicate(true)
		for key: String in Document.RANGES:
			if setup.locks.get(key, false) or setup.strength == 0: continue
			var random := RandomNumberGenerator.new()
			random.seed = ("sol-lab-v1/%d/%d/%s" % [int(setup.seed), index, key]).sha256_text().left(12).hex_to_int()
			var bounds: Array = Document.numeric_bounds(parent, key)
			var radius: float = (bounds[1] - bounds[0]) * setup.strength * 0.5
			candidate[key] = snappedf(clampf(float(parent[key]) + random.randf_range(-radius, radius), bounds[0], bounds[1]), 0.01)
			if key == "wisp_density": candidate[key] = float(roundi(candidate[key]))
		results.append(candidate)
	return results
