extends RefCounted
## Shared layout proposal. Generation owns admission; this writes no reserves.
## Stateless candidate priority and a complete fixed halo make queries order independent.
var seed_value := 73
var patch_size := 10.0
var coverage := 0.65
var spacing := 2.0
var canopy_influence := 0.65
var habitat := 1
var patches := FastNoiseLite.new()
var candidate_cache := {}
var trees_only := false
var candidate_window := preload("res://scripts/core/derived_cache_window.gd").new(8192)

func clear_cache() -> void:
	# Invalidate when the callback's underlying terrain changes.
	candidate_cache.clear()

func configure(seed_number: int, size: float, density: float, distance: float, canopy: float, biome: int) -> void:
	seed_value = seed_number
	patch_size = clampf(size, 3.0, 24.0)
	coverage = clampf(density, 0.0, 1.0)
	spacing = clampf(distance, 0.5, 4.0)
	canopy_influence = clampf(canopy, 0.0, 1.0)
	habitat = clampi(biome, 0, 3)
	clear_cache()
	patches.seed = seed_value
	patches.frequency = 1.0 / patch_size
	patches.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH

func roll(cell: Vector2i, salt: int) -> float:
	var value := posmod(cell.x * 73856093 + cell.y * 19349663 + seed_value * 83492791 + salt * 26544357, 2147483647)
	value = posmod((value ^ (value >> 16)) * 73244475, 2147483647)
	value = posmod((value ^ (value >> 16)) * 73244475, 2147483647)
	return float(value ^ (value >> 16)) / 2147483647.0

func patch_at(cell: Vector2i) -> float:
	return clampf(0.5 + patches.get_noise_2d(cell.x, cell.y) * 0.75, 0.0, 1.0)

func candidate(cell: Vector2i, site: Callable, community: bool) -> Dictionary:
	var key := [cell,site.get_object_id(),site.get_method(),community] # Avoid retaining the terrain owner.
	if not candidate_cache.has(key):
		candidate_window.store(candidate_cache,key,make_candidate(cell,site,community))
	return candidate_cache[key].duplicate()

func make_candidate(cell: Vector2i, site: Callable, community: bool) -> Dictionary:
	var context: Dictionary = site.call(cell)
	if not bool(context.get("admitted", false)): return {}
	var biome := clampi(int(context.get("habitat",habitat)),0,3)
	var wetness := clampf(float(context.get("wetness", 0.5)), 0.0, 1.0)
	var patch := patch_at(cell)
	var suitability := lerpf(0.45, 1.0, wetness) if biome == 3 else lerpf(1.0, 0.5, wetness) if biome == 2 else 0.8
	var density := coverage * (lerpf(0.12, 1.65, patch) * suitability if community else 0.8) * float(context.get("slope_suitability",1.0))
	if roll(cell, 19) >= density: return {}
	var tree_chance: float = [0.05, 0.32, 0.06, 0.12][biome]
	var tree := roll(cell, 43) < tree_chance * (lerpf(0.3, 1.7, patch) if community else 1.0)
	if trees_only and not tree: return {}
	var radius := spacing * (0.55 if tree else 0.22)
	# Site admission tests the whole proposed footprint, not just its center.
	var reach := ceili(radius)
	for y in range(-reach, reach + 1):
		for x in range(-reach, reach + 1):
			if Vector2(x,y).length() > radius + 0.71: continue
			if not bool(site.call(cell + Vector2i(x,y)).get("admitted", false)): return {}
	return {"cell":cell, "tree":tree, "radius":radius, "priority":roll(cell, 89), "patch":patch, "height":float(context.get("height",0.0))}

func sample(cell: Vector2i, site: Callable, community: bool = true) -> Dictionary:
	var current := candidate(cell, site, community)
	if current.is_empty() or not community: return current
	# Maximum combined radius is 4.4 cells; ground-to-canopy influence <= 4.
	# A conservative six-cell halo covers both at every supported slider value.
	var shade := 0.0
	for y in range(-6,7):
		for x in range(-6,7):
			if x == 0 and y == 0: continue
			var distance := Vector2(x,y).length()
			if distance > maxf(4.0,spacing*1.1): continue
			var neighbor := candidate(cell + Vector2i(x,y), site, true)
			if neighbor.is_empty(): continue
			if bool(neighbor.tree) and not bool(current.tree):
				shade = maxf(shade, maxf(0.0, 1.0-distance/4.0))
			# Separate canopy and understory layers; groundcover can share canopy space.
			if neighbor.tree != current.tree or distance >= float(current.radius)+float(neighbor.radius): continue
			var wins: bool = neighbor.priority > current.priority or (neighbor.priority == current.priority and (neighbor.cell.x < cell.x or (neighbor.cell.x == cell.x and neighbor.cell.y < cell.y)))
			if wins: return {}
	if not current.tree and roll(cell,131) < shade * canopy_influence * 0.65: return {}
	current["shade"] = shade
	return current
