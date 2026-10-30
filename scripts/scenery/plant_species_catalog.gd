class_name PlantSpeciesCatalog
extends RefCounted
## Read-only approved baselines and per-species variation envelopes.
const PATH := "res://resources/plants/official_catalog.json"
static var records: Dictionary={}
static var loaded:=false
static func all() -> Array[Dictionary]:
 ensure_loaded()
 var result: Array[Dictionary]=[]
 for entry: Dictionary in records.values(): result.append(entry.duplicate(true))
 return result
static func ensure_loaded() -> void:
 if loaded: return
 loaded=true
 var data: Variant=JSON.parse_string(FileAccess.get_file_as_string(PATH))
 if not data is Dictionary or data.get("version")!=1 or not data.get("plants") is Array: return
 for entry: Variant in data.plants:
  if entry is Dictionary and entry.get("design_id") is String and entry.get("baseline_recipe") is Dictionary and entry.get("variation_limits") is Dictionary:
   for key: String in data.get("integer_fields",[]):
    if entry.baseline_recipe.has(key): entry.baseline_recipe[key]=int(entry.baseline_recipe[key])
    if entry.variation_limits.fixed.has(key): entry.variation_limits.fixed[key]=int(entry.variation_limits.fixed[key])
   records[entry.design_id]=entry.duplicate(true)
static func get_design(id: String) -> Dictionary:
 ensure_loaded()
 return records.get(id,{}).duplicate(true)
static func constrain(recipe: Dictionary,id: String) -> Dictionary:
 var entry:=get_design(id)
 if entry.is_empty(): return {}
 var result:=recipe.duplicate(true)
 var individual: Variant=result.get("specimen_seed_override",0)
 if not individual is int or individual<1 or individual>2147483646: result.specimen_seed_override=entry.baseline_recipe.specimen_seed_override
 for key in entry.variation_limits.fixed: result[key]=entry.variation_limits.fixed[key]
 for key in entry.variation_limits.numeric_ranges:
  var value: Variant=result.get(key,entry.baseline_recipe[key])
  if typeof(value) not in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(value)): value=entry.baseline_recipe[key]
  var limits: Array=entry.variation_limits.numeric_ranges[key]
  var bounded:=clampf(float(value),float(limits[0]),float(limits[1]))
  result[key]=roundi(bounded) if entry.baseline_recipe[key] is int else bounded
 return result
static func valid_recipe(recipe: Dictionary,id: String) -> bool:
 var entry:=get_design(id)
 if entry.is_empty() or str(recipe.get("catalog_design_id",""))!=id: return false
 if not recipe.get("specimen_seed_override") is int or recipe.specimen_seed_override<1 or recipe.specimen_seed_override>2147483646: return false
 for key in entry.variation_limits.fixed:
  if not recipe.has(key) or recipe[key]!=entry.variation_limits.fixed[key]: return false
 for key in entry.variation_limits.numeric_ranges:
  var value: Variant=recipe.get(key)
  if typeof(value) not in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(value)): return false
  var limits: Array=entry.variation_limits.numeric_ranges[key]
  if float(value)<float(limits[0])-0.000001 or float(value)>float(limits[1])+0.000001: return false
 return true
static func random_recipe(id: String,seed_value: int) -> Dictionary:
 var entry:=get_design(id)
 if entry.is_empty(): return {}
 var recipe: Dictionary=entry.baseline_recipe.duplicate(true)
 var random:=RandomNumberGenerator.new()
 random.seed=seed_value
 for key in entry.variation_limits.numeric_ranges:
  var limits: Array=entry.variation_limits.numeric_ranges[key]
  recipe[key]=random.randi_range(int(limits[0]),int(limits[1])) if entry.baseline_recipe[key] is int else random.randf_range(float(limits[0]),float(limits[1]))
 recipe.specimen_seed_override=random.randi_range(1,2147483646)
 return constrain(recipe,id)
