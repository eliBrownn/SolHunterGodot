class_name ExpeditionSave
extends RefCounted

const FORMAT_VERSION := 5 # Captured plant-community layout.
const SAVE_PATH := "user://expedition.json"
const MAX_SAVE_BYTES := 16 * 1024 * 1024

static func snapshot(seed_value: int, cell: Vector2i, visited: bool, returned: bool, generation_version: int = WorldTerrain.GENERATION_VERSION, climate_parameters: Dictionary = {}, persistent_state: Dictionary = {}, relief_parameters: Dictionary = {}, scenery_parameters: Dictionary = {}, community_parameters: Dictionary = {}) -> Dictionary:
	return {"save_version": FORMAT_VERSION, "generation_version": generation_version,
		"seed": seed_value, "player": [cell.x, cell.y], "landmark_visited": visited, "returned": returned,
		"climate": (climate_parameters if not climate_parameters.is_empty() else WorldTerrain.default_climate()).duplicate(true),
		"relief": (relief_parameters if not relief_parameters.is_empty() else WorldTerrain.default_relief()).duplicate(true),
		"community": (community_parameters if not community_parameters.is_empty() else WorldTerrain.default_community()).duplicate(true),
		"scenery": (scenery_parameters if not scenery_parameters.is_empty() else WorldTerrain.default_scenery()).duplicate(true),
		"world_state": (persistent_state if not persistent_state.is_empty() else ExpeditionState.new(seed_value).snapshot()).duplicate(true)}

static func validate(data: Variant, terrain_hint: WorldTerrain = null) -> bool:
	return not _prepare(data,false,terrain_hint).is_empty()

## Validate once and retain the exact state/terrain admitted by those checks.
## A matching live generation owner may supply its derived caches. Every save
## candidate still validates its complete state, flora, roaming and player data.
static func prepare(data: Variant, terrain_hint: WorldTerrain = null) -> Dictionary:
	return _prepare(data,true,terrain_hint)

static func _prepare(data: Variant, restore_state: bool, terrain_hint: WorldTerrain = null) -> Dictionary:
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
	if not WorldTerrain.CommunitySettings.valid_parameters(data.get("community")) or not WorldTerrain.valid_climate(data.get("climate")) or not TerrainReliefSettings.valid_parameters(data.get("relief")) or not ScenerySiteTemplate.valid_parameters(data.get("scenery")):
		return {}
	var state: ExpeditionState
	if restore_state:
		state = ExpeditionState.restore(data.world_state, int(seed_value))
		if state == null: return {}
	elif not ExpeditionState.valid_snapshot(data.world_state,int(seed_value)):
		return {}
	var specialist_percent := int(data.world_state.get("flora_specialist_percent",FloraTraits.LEGACY_SPECIALIST_PERCENT))
	var terrain: WorldTerrain = terrain_hint if matching_terrain(terrain_hint, data, specialist_percent) else null
	if terrain == null:
		terrain = WorldTerrain.new(int(seed_value),data.climate,data.relief,data.scenery,data.community)
		terrain.flora_specialist_percent = specialist_percent
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

## Only the immutable production generator qualifies. Subclass overrides and
## any differing captured generation value require an independent reconstruction.
static func matching_terrain(terrain: WorldTerrain, data: Dictionary, specialist_percent: int) -> bool:
	return terrain != null and terrain.get_script() == WorldTerrain and terrain.generation_version == int(data.generation_version) and terrain.world_seed == int(data.seed) and terrain.flora_specialist_percent == specialist_percent and _same_generation_value(terrain.climate, data.climate) and _same_generation_value(terrain.relief, data.relief) and _same_generation_value(terrain.scenery_parameters, data.scenery) and _same_generation_value(terrain.community_parameters,data.community)

## JSON reads whole numbers as floats, including nested clearing coordinates.
## Compare numeric values exactly without conflating booleans, missing keys or
## different container shapes. Captured generation structures are shallow/bounded.
static func _same_generation_value(a: Variant, b: Variant, depth: int = 0) -> bool:
	if depth > 8: return false
	if (a is int or a is float) and (b is int or b is float): return float(a) == float(b)
	if typeof(a) != typeof(b): return false
	if a is Dictionary:
		if a.size() != b.size(): return false
		for key in a:
			if not b.has(key) or not _same_generation_value(a[key], b[key], depth + 1): return false
		return true
	if a is Array:
		if a.size() != b.size(): return false
		for index in range(a.size()):
			if not _same_generation_value(a[index], b[index], depth + 1): return false
		return true
	return a == b

static func whole_number(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) == floor(float(value))

static func write(data: Dictionary, path: String = SAVE_PATH, terrain_hint: WorldTerrain = null) -> Error:
	if not validate(data, terrain_hint) or int(data.generation_version) != WorldTerrain.GENERATION_VERSION or int(data.save_version) != FORMAT_VERSION:
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

static func read_candidate(path: String = SAVE_PATH, terrain_hint: WorldTerrain = null) -> Dictionary:
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
	return prepare(data, terrain_hint)
