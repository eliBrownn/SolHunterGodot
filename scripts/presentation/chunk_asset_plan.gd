extends RefCounted
## Conservative prefetch hints only. The existing library still owns selection,
## baked-manifest validation, authored priority, footprint admission and fallback.
const Library = preload("res://scripts/scenery/plant_library.gd")
const Distribution = preload("res://scripts/scenery/foliage_distribution.gd")

static func for_cell(terrain: WorldTerrain, cell: Vector2i, data: Dictionary, nature: NatureSettings, catalog: RefCounted = null) -> Array[String]:
	var result: Array[String] = []
	if catalog == null and (not Library.use_baked_palette or not Library.palette_checked or not Library.palette_current): return result
	var kind := terrain.flora_kind(cell, data)
	if kind.is_empty() or data.ground not in [0, 1, 2, 3]: return result
	var biome := int(data.ground)
	var traits := FloraTraits.describe(terrain.world_seed, {"id": FloraCatalog.id_for(cell), "cell": [cell.x, cell.y], "kind": kind}, terrain.flora_specialist_percent)
	var authored_candidates: Array[Resource] = []
	for item: Resource in (catalog.entries if catalog != null else Library.entries):
		if item.enabled_in_world and item.biome == biome and item.circulation_role == traits.role and item.specialist_class == traits["class"]: authored_candidates.append(item)
	var authored_selected := false
	if not authored_candidates.is_empty():
		var candidate: Resource = authored_candidates[terrain.roll(cell, 771931) % authored_candidates.size()]
		authored_selected = terrain.roll(cell, 771933) % 100 < candidate.frequency_percent
	if not authored_selected:
		var official := Library.official_candidates(biome, traits, catalog)
		if not official.is_empty(): add(result, "official_" + official[terrain.roll(cell, 771937) % official.size()])
		if traits.role != "emanator":
			var role := 1 if traits.role == "reservoir" else 3 + FloraTraits.CLASSES.find(traits["class"])
			if official.is_empty(): add(result, "procedural_%d_%d_%d" % [biome, role, terrain.roll(cell, 771937) % 3])
			if kind == "tree" and authored_candidates.is_empty() and terrain.roll(cell, 771943) % 100 < 65: add(result, "procedural_%d_%d_%d" % [biome, role, terrain.roll(cell, 771945) % 9])
		elif nature.meadow_enabled and nature.foliage_coverage > 0:
			var proposal := Distribution.proposal(terrain, cell, data, nature.foliage_coverage, catalog.distribution_field if catalog != null else null)
			if not proposal.is_empty():
				add(result, "foliage_%d_%d_emanator" % [proposal.biome, proposal.variation])
				if not official.is_empty(): add(result, "official_" + official[int(proposal.variation) % official.size()])
	# A cell uses a seeded subset of five shared cover designs. Loading these five
	# is bounded and avoids evaluating placement or consuming its random stream.
	if nature.meadow_enabled and nature.foliage_coverage > 0:
		for variation in range(5): add(result, "foliage_%d_%d_emanator_cover" % [biome, variation])
	# Placement can retry with the confined small-tree fallback.
	if kind == "tree": add(result, "procedural_%d_1_0" % biome)
	return result

static func add(result: Array[String], key: String) -> void:
	var path := "res://resources/plants/runtime_palette/" + key + ".res"
	if not result.has(path): result.append(path)
