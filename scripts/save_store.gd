class_name ExpeditionSave
extends RefCounted

const FORMAT_VERSION := 2
const SAVE_PATH := "user://expedition.json"
const MAX_SAVE_BYTES := 16 * 1024 * 1024

static func snapshot(seed_value: int, cell: Vector2i, visited: bool, returned: bool, generation_version: int = WorldTerrain.GENERATION_VERSION, climate_parameters: Dictionary = {}, persistent_state: Dictionary = {}) -> Dictionary:
	return {"save_version": FORMAT_VERSION, "generation_version": generation_version,
		"seed": seed_value, "player": [cell.x, cell.y], "landmark_visited": visited, "returned": returned,
		"climate": (climate_parameters if not climate_parameters.is_empty() else WorldTerrain.default_climate()).duplicate(true),
		"world_state": (persistent_state if not persistent_state.is_empty() else ExpeditionState.new(seed_value).snapshot()).duplicate(true)}

static func validate(data: Variant) -> bool:
	if not data is Dictionary:
		return false
	if not whole_number(data.get("save_version")) or int(data.save_version) not in [1, FORMAT_VERSION] or not whole_number(data.get("generation_version")):
		return false
	if int(data.generation_version) not in [1, 2, 3, 4, WorldTerrain.GENERATION_VERSION]:
		return false
	var seed_value: Variant = data.get("seed")
	if not whole_number(seed_value) or seed_value < 0 or seed_value > 2147483646:
		return false
	if int(data.save_version) == FORMAT_VERSION:
		if not ExpeditionState.valid_snapshot(data.get("world_state"), int(seed_value)):
			return false
	elif data.has("world_state"):
		return false
	var cell: Variant = data.get("player")
	if not cell is Array or cell.size() != 2:
		return false
	for value in cell:
		if not whole_number(value) or absf(value) > 1000000:
			return false
	if not data.get("landmark_visited") is bool or not data.get("returned") is bool:
		return false
	if data.returned and not data.landmark_visited:
		return false
	# Version 4 introduced saved climate parameters; preserve and validate them on migration.
	if int(data.generation_version) >= 4 and not WorldTerrain.valid_climate(data.get("climate")):
		return false
	# Previous generations are validated structurally and migrated on read.
	if int(data.generation_version) < WorldTerrain.GENERATION_VERSION:
		return true
	if not WorldTerrain.valid_climate(data.get("climate")):
		return false
	var terrain := WorldTerrain.new(int(seed_value), data.climate)
	return terrain.fits(Vector2i(int(cell[0]), int(cell[1])))

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
	if not validate(data):
		return {}
	var copy: Dictionary = data.duplicate(true)
	if int(copy.generation_version) < WorldTerrain.GENERATION_VERSION:
		copy = migrate(copy)
	if copy.is_empty():
		return {}
	if int(copy.save_version) == 1:
		copy["migrated_save_version"] = 1
		copy["save_version"] = FORMAT_VERSION
		copy["world_state"] = ExpeditionState.new(int(copy.seed)).snapshot()
	return copy if validate(copy) else {}

static func migrate(data: Dictionary) -> Dictionary:
	# No source file is changed on load. Keep seed and progress; if the new
	# geography blocks the saved cell, deterministically choose a nearby dry cell.
	var climate_parameters: Dictionary = data.get("climate", {})
	if not WorldTerrain.valid_climate(climate_parameters):
		climate_parameters = WorldTerrain.default_climate()
	var terrain := WorldTerrain.new(int(data.seed), climate_parameters)
	var original := Vector2i(int(data.player[0]), int(data.player[1]))
	var destination := original
	if not terrain.fits(destination):
		var found := false
		for radius in range(1, 65):
			for y in range(-radius, radius + 1):
				for x in range(-radius, radius + 1):
					if maxi(absi(x), absi(y)) != radius:
						continue
					var candidate := original + Vector2i(x, y)
					if absi(candidate.x) <= 1000000 and absi(candidate.y) <= 1000000 and terrain.fits(candidate):
						destination = candidate
						found = true
						break
				if found:
					break
			if found:
				break
		if not found:
			return {}
	data["migrated_from"] = int(data.generation_version)
	data["migration_moved"] = destination != original
	data["player"] = [destination.x, destination.y]
	data["generation_version"] = WorldTerrain.GENERATION_VERSION
	data["climate"] = terrain.climate.duplicate(true)
	return data if validate(data) else {}
