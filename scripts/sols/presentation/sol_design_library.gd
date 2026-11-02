extends RefCounted
## Explicit local appearance overrides; species mechanics and identity stay catalog-owned.
const Recipe = preload("res://scripts/sols/presentation/sol_design_recipe.gd")
const ROOT := "user://sol_lab/exports/"
const INDEX := "user://sol_lab/appearance_overrides.json"

static func approved_scene(path: String, target_species: String = "") -> PackedScene:
	if not path.begins_with(ROOT) or ".." in path or not path.ends_with(".tscn") or not FileAccess.file_exists(path): return null
	var scene := load(path) as PackedScene
	if scene == null: return null
	var state := scene.get_state()
	var script: Script
	var recipe: Dictionary = {}
	for index in state.get_node_property_count(0):
		var key := state.get_node_property_name(0, index)
		if key == "script": script = state.get_node_property_value(0, index)
		if key == "appearance_recipe": recipe = state.get_node_property_value(0, index)
	if script == null or script.resource_path != "res://scripts/sols/presentation/sol_design_view.gd" or not Recipe.valid(recipe): return null
	var settings := Recipe.design(recipe)
	if settings.stage != "reviewed" or (not target_species.is_empty() and settings.target_species != target_species): return null
	return scene

static func overrides() -> Dictionary:
	if not FileAccess.file_exists(INDEX): return {}
	var value: Variant = JSON.parse_string(FileAccess.get_file_as_string(INDEX))
	return value if value is Dictionary else {}

static func presentation(species_id: String, fallback: PackedScene) -> PackedScene:
	var path: Variant = overrides().get(species_id)
	if not path is String: return fallback
	var scene := approved_scene(path, species_id)
	return scene if scene != null else fallback

static func set_override(species_id: String, path: String) -> Error:
	if not species_id.is_valid_identifier() or (not path.is_empty() and approved_scene(path, species_id) == null): return ERR_INVALID_DATA
	if FileAccess.file_exists(INDEX) and not JSON.parse_string(FileAccess.get_file_as_string(INDEX)) is Dictionary: return ERR_FILE_CORRUPT
	var data := overrides()
	if path.is_empty(): data.erase(species_id)
	else: data[species_id] = path
	var file := FileAccess.open(INDEX, FileAccess.WRITE)
	if file == null: return FileAccess.get_open_error()
	file.store_string(JSON.stringify(data, "\t"))
	file.flush()
	var result := file.get_error()
	file.close()
	return result
