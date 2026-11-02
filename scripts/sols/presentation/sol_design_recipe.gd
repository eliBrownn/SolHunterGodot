extends RefCounted
## Shared appearance document; independent of gameplay identity and mechanics.
const VERSION := 1
const Wisp = preload("res://scripts/sols/presentation/sol_visual_core.gd")
const RANGES := {
	"body_length": [0.6, 2.4, 1.2], "body_width": [0.3, 1.3, 0.65],
	"body_height": [0.3, 1.3, 0.7], "head_size": [0.25, 1.0, 0.5],
	"leg_length": [0.3, 1.5, 0.65], "tail_length": [0.1, 1.8, 0.7],
	"ear_length": [0.1, 0.8, 0.35],
	"wing_span": [0.3, 2.5, 1.0], "horn_length": [0.1, 1.0, 0.3],
	"fin_size": [0.1, 1.0, 0.3], "muzzle_length": [0.05, 0.6, 0.15],
	"head_offset": [-0.15, 0.15, 0.0], "tail_angle": [-45.0, 45.0, 0.0],
	"limb_spread": [0.2, 0.6, 0.35], "structure_size": [0.2, 1.5, 0.7],
	"wisp_density": Wisp.RANGES.wisp_density, "wisp_length": Wisp.RANGES.wisp_length,
	"wisp_speed": Wisp.RANGES.wisp_speed, "wisp_spread": Wisp.RANGES.wisp_spread,
	"wisp_softness": Wisp.RANGES.wisp_softness, "wisp_opacity": Wisp.RANGES.wisp_opacity,
	"wisp_glow": Wisp.RANGES.wisp_glow,
	"core_size": [0.1, 1.2, 0.35], "core_offset_x": [-1.5, 1.5, 0.0],
	"core_offset_y": [-1.5, 1.5, 0.0], "core_offset_z": [-1.5, 1.5, 0.0]
}
const ORIGINAL := ["body_length", "body_width", "body_height", "head_size", "leg_length", "tail_length", "ear_length"]
const PLANS := ["quadruped", "biped", "avian", "serpentine", "aquatic", "insectoid"]
const MODULES := ["anatomical_head", "ears", "tail", "wings", "horns", "fins", "muzzle"]
const STRUCTURES := ["smooth", "ruff", "shell", "petal", "mushroom", "vine", "plates", "sail", "fan", "frill", "pouch", "spines", "burrow", "web", "fold", "wheel", "threads", "veil", "bell", "ribbon", "crystal", "totem", "cage", "mask", "antlers", "feathers", "coil", "centaur", "broadarms", "slender"]
const AFFINITIES := ["fire", "water", "earth", "air", "lightning", "void", "spectral", "quantum"]

static func authoring_defaults() -> Dictionary:
	return {"mode": "species", "body_plan": "quadruped", "structure": "smooth", "class_id": "", "core_anchor": "chest", "core_tint": "d0eaf0", "modules": {"anatomical_head": true, "ears": true, "tail": true, "wings": false, "horns": false, "fins": false, "muzzle": false}, "constraints": {}, "accent": "d9b59b", "pattern": "plain", "roughness": 0.85, "symmetry": true, "asymmetry": 0.0, "affinity": "air", "annotations": {}, "references": [], "stage": "draft", "target_species": "", "favorites": []}

static func design(value: Dictionary) -> Dictionary:
	var result := authoring_defaults()
	result.merge(value.get("design", {}), true)
	var modules: Dictionary = authoring_defaults().modules.duplicate(true)
	modules.merge(result.modules, true)
	result.modules = modules
	if value.get("design", {}).has("head_tint") and not value.get("design", {}).has("core_tint"): result.core_tint = value.design.head_tint
	result["motion"] = {"stride": 0.12, "lift": 0.08, "idle_rate": 0.6, "wingbeat_rate": 3.0, "swim_rate": 1.5}.merged(result.get("motion", {}), true)
	return result

static func resolved(value: Dictionary) -> Dictionary:
	var result := fresh()
	result.merge(value, true)
	return result

static func numeric_bounds(value: Dictionary, key: String) -> Array:
	var rule: Array = design(value).constraints.get(key, [RANGES[key][0], RANGES[key][1]])
	return rule

static func species_snapshot(value: Dictionary) -> Dictionary:
	var result := resolved(value).duplicate(true)
	result.erase("exploration")
	var settings := design(result)
	settings.erase("species_base")
	settings.mode = "species"
	settings.stage = "draft"
	settings.annotations = {}
	settings.references = []
	settings.favorites = []
	result.design = settings
	return result

static func fresh() -> Dictionary:
	var result := {"version": VERSION, "name": "Untitled Sol", "notes": "", "color": "668f99"}
	for key in RANGES: result[key] = RANGES[key][2]
	return result

static func valid(value: Variant) -> bool:
	if not value is Dictionary or value.get("version") != VERSION: return false
	if not value.get("name") is String or value.name.strip_edges().is_empty() or value.name.length() > 80: return false
	if not value.get("notes") is String or value.notes.length() > 20000: return false
	if not value.get("color") is String or not Color.html_is_valid(value.color): return false
	for key in RANGES:
		if key not in ORIGINAL and not value.has(key): continue
		if not (value.get(key) is float or value.get(key) is int): return false
		var number := float(value[key])
		if not is_finite(number) or number < RANGES[key][0] or number > RANGES[key][1]: return false
	if value.has("design") and not valid_design(value.design): return false
	if value.has("design") and value.design.get("mode") == "individual":
		var base: Dictionary = value.design.species_base
		for key in RANGES:
			var bounds := numeric_bounds(base, key)
			var number: float = value.get(key, RANGES[key][2])
			if number < bounds[0] or number > bounds[1]: return false
	return not value.has("exploration") or valid_exploration(value.exploration)

static func valid_design(value: Variant) -> bool:
	if not value is Dictionary: return false
	var settings := design({"design": value})
	if settings.mode not in ["species", "individual"] or settings.body_plan not in PLANS or settings.affinity not in AFFINITIES: return false
	if settings.structure not in STRUCTURES or not settings.class_id is String or settings.class_id.length() > 80: return false
	if settings.core_anchor not in ["head", "chest", "back", "root", "tail", "free"] or not settings.core_tint is String or not Color.html_is_valid(settings.core_tint): return false
	if settings.pattern not in ["plain", "stripes", "spots", "bands"] or settings.stage not in ["draft", "candidate", "reviewed"]: return false
	if not settings.accent is String or not Color.html_is_valid(settings.accent): return false
	if value.has("head_tint") and (not value.head_tint is String or not Color.html_is_valid(value.head_tint)): return false
	if not settings.symmetry is bool or not settings.target_species is String or settings.target_species.length() > 80: return false
	if value.has("motion"):
		if not value.motion is Dictionary: return false
		for row in [["stride", 0.04, 0.3], ["lift", 0.0, 0.15], ["idle_rate", 0.0, 2.0], ["wingbeat_rate", 1.0, 6.0], ["swim_rate", 0.5, 3.0]]:
			var number: Variant = value.motion.get(row[0], {"stride": 0.12, "lift": 0.08, "idle_rate": 0.6, "wingbeat_rate": 3.0, "swim_rate": 1.5}[row[0]])
			if not (number is int or number is float) or not is_finite(float(number)) or number < row[1] or number > row[2]: return false
	for key in ["roughness", "asymmetry"]:
		if not (settings[key] is int or settings[key] is float) or not is_finite(float(settings[key])) or settings[key] < 0 or settings[key] > 1: return false
	if not settings.modules is Dictionary or not settings.constraints is Dictionary or not settings.annotations is Dictionary: return false
	for key in settings.modules:
		if key not in MODULES or not settings.modules[key] is bool: return false
	for key in settings.constraints:
		var limits: Variant = settings.constraints[key]
		if not RANGES.has(key) or not limits is Array or limits.size() != 2: return false
		for number in limits:
			if not (number is int or number is float) or not is_finite(float(number)): return false
		if limits[0] < RANGES[key][0] or limits[1] > RANGES[key][1] or limits[0] > limits[1]: return false
		if key == "wisp_density" and (limits[0] != floor(limits[0]) or limits[1] != floor(limits[1])): return false
	for key in settings.annotations:
		if not key is String or not settings.annotations[key] is String or settings.annotations[key].length() > 5000: return false
	if not settings.references is Array or settings.references.size() > 12 or not settings.favorites is Array or settings.favorites.size() > 24: return false
	for path in settings.references:
		if not path is String or not path.begins_with("user://sol_lab/references/") or ".." in path or not path.ends_with(".png"): return false
	for favorite in settings.favorites:
		if not favorite is Dictionary or favorite.has("design") or favorite.has("exploration") or not valid(favorite): return false
		if favorite.has("appearance") and not valid_design(favorite.appearance): return false
	if settings.mode == "individual":
		var base: Variant = settings.get("species_base")
		if not base is Dictionary or base.get("design", {}).get("mode", "species") != "species" or base.get("design", {}).has("species_base") or not valid(base): return false
		var inherited := design(base)
		for key in ["body_plan", "structure", "modules", "constraints", "class_id", "core_anchor"]:
			if settings[key] != inherited[key]: return false
	return true

static func valid_exploration(setup: Variant) -> bool:
	if not setup is Dictionary or not setup.get("locks") is Dictionary: return false
	for key in setup.locks:
		if not RANGES.has(key) or not setup.locks[key] is bool: return false
	for key in ["seed", "strength"]:
		if not (setup.get(key) is int or setup.get(key) is float) or not is_finite(float(setup[key])): return false
	if setup.seed < 0 or setup.seed > 999999 or setup.seed != floor(setup.seed) or setup.strength < 0 or setup.strength > 1: return false
	if setup.has("parent"):
		if not setup.parent is Dictionary or setup.parent.has("exploration") or not valid(setup.parent): return false
	return true

static func write(path: String, value: Dictionary) -> Error:
	if not valid(value): return ERR_INVALID_DATA
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null: return FileAccess.get_open_error()
	file.store_string(JSON.stringify(value, "\t"))
	file.flush()
	var result := file.get_error()
	file.close()
	return result

static func read(path: String) -> Dictionary:
	if not FileAccess.file_exists(path): return {}
	var value: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not valid(value): return {}
	value = resolved(value)
	value.version = VERSION
	if value.has("exploration"): value.exploration.seed = int(value.exploration.seed)
	if value.has("exploration") and value.exploration.has("parent"):
		value.exploration.parent = resolved(value.exploration.parent)
		value.exploration.parent.version = VERSION
	return value
