class_name FloraTraits
extends RefCounted
## Stable functional identities, separate from affinity and the rendered clump count.
const CLASSES := ["warden", "mender", "regulator"]
const NAMES := {"warden": "Warden shrub", "mender": "Mender flower", "regulator": "Regulator plant"}
const CACHE_LIMIT := 4096
static var cache: Dictionary = {}

static func describe(seed: int, row: Dictionary) -> Dictionary:
	return cached(seed, row).duplicate()

static func category(seed: int, row: Dictionary) -> String:
	return str(cached(seed, row)["class"])

static func role(seed: int, row: Dictionary) -> String:
	return str(cached(seed, row).role)

static func cached(seed: int, row: Dictionary) -> Dictionary:
	var key := "%d:%s:%s" % [seed, str(row.id), str(row.kind)]
	if cache.has(key): return cache[key]
	var result := resolve(seed, row)
	if cache.size() >= CACHE_LIMIT: cache.erase(cache.keys()[0])
	cache[key] = result
	return result

static func resolve(seed: int, row: Dictionary) -> Dictionary:
	if row.kind == "tree":
		return {"form": "tree", "role": "reservoir", "class": "", "name": "Tree"}
	var cell: Array = row.cell
	var choice := absi(hash("flora-class-v1:%d:%d:%d" % [seed, int(cell[0]), int(cell[1])])) % 12
	if choice >= 3:
		return {"form": "grass", "role": "emanator", "class": "", "name": "Grass patch"}
	var category: String = CLASSES[choice]
	return {"form": "shrub" if category == "warden" else "flower", "role": "receiver", "class": category, "name": NAMES[category]}

static func appearance(traits: Dictionary, activity: String) -> String:
	var base := "Low grass grows in an uneven patch."
	match traits.get("class", ""):
		"warden": base = "Broad, overlapping leaves form a compact shrub."
		"mender": base = "Low flowers gather around a spreading rosette."
		"regulator": base = "Upright stems carry small, staggered flower heads."
	if traits.get("form") == "tree": base = "A solid trunk rises into a leafy canopy."
	match activity:
		"protecting": base += " Short pulses gather around its leaves."
		"repairing": base += " Small pulses gather beneath its flowers."
		"regulating": base += " Small pulses pass through its stems in a measured rhythm."
	return base
