extends RefCounted
## Script property names are stable; values are always read fresh for live tuning.
const CACHE_KEY := &"_solhunter_storage_field_names"

static func for_resource(resource: Resource) -> Array[StringName]:
	var script: Script = resource.get_script()
	# Keep only names on the owning Script, avoiding a global cache that retains
	# scripts or their preloaded assets after a scene/test has been released.
	if script != null and script.has_meta(CACHE_KEY):
		return script.get_meta(CACHE_KEY)
	var fields: Array[StringName] = []
	for property in resource.get_property_list():
		if int(property.usage) & PROPERTY_USAGE_STORAGE and property.name != "script":
			fields.append(property.name)
	if script != null:
		script.set_meta(CACHE_KEY, fields)
	return fields
