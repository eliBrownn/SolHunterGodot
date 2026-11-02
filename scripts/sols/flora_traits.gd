class_name FloraTraits
extends RefCounted
## Stable functional identities, separate from affinity and the rendered clump count.
const DEFAULT_SPECIALIST_PERCENT := 5
const LEGACY_SPECIALIST_PERCENT := 25
const COMMUNITY_CELLS := 32
const CLASSES := ["warden", "mender", "regulator"]
const NAMES := {"warden": "Warden shrub", "mender": "Mender flower", "regulator": "Regulator plant"}
const CACHE_LIMIT := 4096
static var cache: Dictionary = {}

static func describe(seed: int, row: Dictionary, specialist_percent: int = DEFAULT_SPECIALIST_PERCENT) -> Dictionary:
	return cached(seed, row, specialist_percent).duplicate()

static func category(seed: int, row: Dictionary, specialist_percent: int = DEFAULT_SPECIALIST_PERCENT) -> String:
	return str(cached(seed, row, specialist_percent)["class"])

static func role(seed: int, row: Dictionary, specialist_percent: int = DEFAULT_SPECIALIST_PERCENT) -> String:
	return str(cached(seed, row, specialist_percent).role)

static func cached(seed: int, row: Dictionary, specialist_percent: int = DEFAULT_SPECIALIST_PERCENT) -> Dictionary:
	# The bounded shared cache belongs to the main owner. Worker evaluation uses
	# the identical pure resolver, so it cannot race cache insertion or eviction.
	if OS.get_thread_caller_id() != OS.get_main_thread_id(): return resolve(seed,row,specialist_percent)
	var key := "%d:%s:%s:%d" % [seed, str(row.id), str(row.kind),specialist_percent]
	if cache.has(key): return cache[key]
	var result := resolve(seed, row, specialist_percent)
	if cache.size() >= CACHE_LIMIT: cache.erase(cache.keys()[0])
	cache[key] = result
	return result

static func resolve(seed: int, row: Dictionary, specialist_percent: int = DEFAULT_SPECIALIST_PERCENT) -> Dictionary:
	if row.kind == "tree":
		return {"form": "tree", "role": "reservoir", "class": "", "name": "Tree"}
	var cell: Array = row.cell
	var choice := absi(hash("flora-class-v1:%d:%d:%d" % [seed, int(cell[0]), int(cell[1])])) % 12
	if choice>=3:
		return {"form":"grass","role":"emanator","class":"","name":"Grass patch"}
	# Rarity thins the old stable classes, rather than rerolling their identities.
	# Geographic potential can be zero; no region is required to contain a class.
	var percentage:=clampi(specialist_percent,0,LEGACY_SPECIALIST_PERCENT)
	var retained:=true
	if percentage<LEGACY_SPECIALIST_PERCENT:
		var chance:=percentage/25.0*community_weight(seed,Vector2i(int(cell[0]),int(cell[1])))
		retained=float(absi(hash("flora-rarity-v1:%d:%d:%d"%[seed,int(cell[0]),int(cell[1])]))%10000)/10000.0<chance
	if not retained:
		return {"form": "grass", "role": "emanator", "class": "", "name": "Grass patch"}
	var category: String = CLASSES[choice]
	return {"form": "shrub" if category == "warden" else "flower", "role": "receiver", "class": category, "name": NAMES[category]}

## Static generation potential only. Later birth/death mechanics own live changes.
static func community_weight(seed: int, cell: Vector2i) -> float:
	var owner:=Vector2i(WorldTerrain.floor_div(cell.x,COMMUNITY_CELLS),WorldTerrain.floor_div(cell.y,COMMUNITY_CELLS))
	var local:=Vector2(cell-owner*COMMUNITY_CELLS)/float(COMMUNITY_CELLS)
	local=Vector2(smoothstep(0,1,local.x),smoothstep(0,1,local.y))
	var corners: Array[float]=[]
	for offset in [Vector2i.ZERO,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.ONE]:
		var key: Vector2i=owner+offset
		corners.append(0.0 if absi(hash("flora-community-v1:%d:%d:%d"%[seed,key.x,key.y]))%2==0 else 2.0)
	return lerpf(lerpf(corners[0],corners[1],local.x),lerpf(corners[2],corners[3],local.x),local.y)

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
