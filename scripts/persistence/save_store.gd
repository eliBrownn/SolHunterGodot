class_name ExpeditionSave
extends RefCounted

const FORMAT_VERSION := 4 # Captured site definition parameters.
const SAVE_PATH := "user://expedition.json"
const MAX_SAVE_BYTES := 16 * 1024 * 1024

static func snapshot(seed_value: int, cell: Vector2i, visited: bool, returned: bool, generation_version: int = WorldTerrain.GENERATION_VERSION, climate_parameters: Dictionary = {}, persistent_state: Dictionary = {}, relief_parameters: Dictionary = {}, scenery_parameters: Dictionary = {}) -> Dictionary:
	return {"save_version": FORMAT_VERSION, "generation_version": generation_version,
		"seed": seed_value, "player": [cell.x, cell.y], "landmark_visited": visited, "returned": returned,
		"climate": (climate_parameters if not climate_parameters.is_empty() else WorldTerrain.default_climate()).duplicate(true),
		"relief": (relief_parameters if not relief_parameters.is_empty() else WorldTerrain.default_relief()).duplicate(true),
		"scenery": (scenery_parameters if not scenery_parameters.is_empty() else WorldTerrain.default_scenery()).duplicate(true),
		"world_state": (persistent_state if not persistent_state.is_empty() else ExpeditionState.new(seed_value).snapshot()).duplicate(true)}

static func validate(data: Variant) -> bool:
	return not _prepare(data,false).is_empty()

## Validate once and retain the exact state/terrain admitted by those checks.
## This result is local to a load; no reusable trust flag or cross-load cache.
static func prepare(data: Variant) -> Dictionary:
	return _prepare(data,true)

static func _prepare(data: Variant, restore_state: bool) -> Dictionary:
	if not data is Dictionary:
		return {}
	if not whole_number(data.get("save_version")) or int(data.save_version) != FORMAT_VERSION or not whole_number(data.get("generation_version")):
		return {}
	if int(data.generation_version) != WorldTerrain.GENERATION_VERSION:
		return {}
	var seed_value: Variant = data.get("seed")
	if not whole_number(seed_value) or seed_value < 0 or seed_value > 2147483646:
		return {}
	if int(data.save_version) == FORMAT_VERSION:
		if not data.get("world_state") is Dictionary:
			return {}
	elif data.has("world_state"):
		return {}
	var cell: Variant = data.get("player")
	if not cell is Array or cell.size() != 2:
		return {}
	for value in cell:
		if not whole_number(value) or absf(value) > 1000000:
			return {}
	if not data.get("landmark_visited") is bool or not data.get("returned") is bool:
		return {}
	if data.returned and not data.landmark_visited:
		return {}
	if not WorldTerrain.valid_climate(data.get("climate")) or not TerrainReliefSettings.valid_parameters(data.get("relief")) or not ScenerySiteTemplate.valid_parameters(data.get("scenery")):
		return {}
	var state: ExpeditionState
	if restore_state:
		state = ExpeditionState.restore(data.world_state, int(seed_value))
		if state == null: return {}
	elif not ExpeditionState.valid_snapshot(data.world_state,int(seed_value)):
		return {}
	var terrain := WorldTerrain.new(int(seed_value), data.climate, data.relief, data.scenery)
	terrain.flora_specialist_percent=int(data.world_state.get("flora_specialist_percent",FloraTraits.LEGACY_SPECIALIST_PERCENT))
	for row: Dictionary in data.world_state.flora.nodes.values():
		var at := Vector2i(int(row.cell[0]), int(row.cell[1]))
		if terrain.flora_kind(at, terrain.sample(at)) != row.kind: return {}
	for identity in data.get("world_state", {}).get("roaming", {}):
		var row: Dictionary = data.world_state.roaming[identity]
		var individual: Dictionary = data.world_state.individuals[identity]
		var roaming_cell := Vector2i(int(row.cell[0]), int(row.cell[1]))
		if row.has("traversal"):
			if int(individual.footprint) != 1 or not SolTraversalPolicy.cell_valid(terrain, roaming_cell, row.traversal):
				return {}
		elif not terrain.fits(roaming_cell, int(individual.footprint)):
			return {}
	if not terrain.fits(Vector2i(int(cell[0]), int(cell[1]))): return {}
	return {"data": data, "state": state, "terrain": terrain}

static func whole_number(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) == floor(float(value))

static func write(data: Dictionary, path: String = SAVE_PATH) -> Error:
	if not validate(data) or int(data.generation_version) != WorldTerrain.GENERATION_VERSION or int(data.save_version) != FORMAT_VERSION:
		return ERR_INVALID_DATA
	var encoded := JSON.stringify(data, "", true, true)
	if encoded.to_utf8_buffer().size() > MAX_SAVE_BYTES:
		return ERR_OUT_OF_MEMORY
	var file := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(encoded)
	file.flush()
	var error := file.get_error()
	file.close()
	if error != OK:
		return error
	# Preserve the previous complete save before atomically replacing the destination.
	if FileAccess.file_exists(path):
		error = DirAccess.copy_absolute(path, path + ".bak")
		if error != OK:
			return error
	return DirAccess.rename_absolute(path + ".tmp", path)

static func read_save(path: String = SAVE_PATH) -> Dictionary:
	var candidate := read_candidate(path)
	return candidate.data if not candidate.is_empty() else {}

static func read_candidate(path: String = SAVE_PATH) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var input := FileAccess.open(path, FileAccess.READ)
	if input == null:
		return {}
	if input.get_length() > MAX_SAVE_BYTES:
		input.close()
		return {}
	var encoded := input.get_as_text()
	input.close()
	var parser := JSON.new()
	if parser.parse(encoded) != OK:
		return {}
	var data: Variant = parser.data
	return prepare(data)
