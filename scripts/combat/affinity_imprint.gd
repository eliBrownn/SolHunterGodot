class_name AffinityImprint
extends RefCounted
## Sparse persistent affinity + recoverable conditions, separate from Vastra overload.
const IDS := ["fire", "water", "earth", "air", "lightning", "void", "spectral", "quantum"]
const CONDITIONS := ["heat", "wet", "rough", "barrier", "wind", "charge", "phase", "warp", "entangled"]

static func canonical(id: String) -> String:
	return {"grove": "earth", "ember": "fire", "tide": "water", "gale": "air"}.get(id, id)

static func key(cell: Vector2i) -> String:
	return "%d:%d" % [cell.x, cell.y]

static func valid_key(value: Variant) -> bool:
	if not value is String:
		return false
	var parts: PackedStringArray = value.split(":")
	if parts.size() != 2 or not parts[0].is_valid_int() or not parts[1].is_valid_int():
		return false
	var cell := Vector2i(int(parts[0]), int(parts[1]))
	return absi(cell.x) <= 1000000 and absi(cell.y) <= 1000000 and key(cell) == value

static func valid_tiles(tiles: Variant, tick: int, limit: int) -> bool:
	if not tiles is Dictionary or tiles.size() > limit:
		return false
	for at in tiles:
		var row: Variant = tiles[at]
		if not valid_key(at) or not row is Dictionary or not RecordShape.keys_match(row, ["affinity", "conditions"]) or row.affinity not in IDS or not row.conditions is Dictionary or row.conditions.size() > CONDITIONS.size():
			return false
		for kind in row.conditions:
			var effect: Variant = row.conditions[kind]
			if kind not in CONDITIONS or not effect is Dictionary or not RecordShape.keys_match(effect, ["level", "since", "interval", "direction"]) or not SolSpeciesDefinition.whole(effect.level, 1, 3) or not SolSpeciesDefinition.whole(effect.since, 0, tick) or not SolSpeciesDefinition.whole(effect.interval, 1, 1000) or not effect.direction is Array or effect.direction.size() != 2 or not SolSpeciesDefinition.whole(effect.direction[0], -1, 1) or not SolSpeciesDefinition.whole(effect.direction[1], -1, 1):
				return false
	return true

static func apply(tiles: Dictionary, report: Dictionary, tick: int, limit: int) -> Variant:
	if report.is_empty():
		return tiles.duplicate(true)
	if not RecordShape.keys_match(report, ["winner", "tiles", "fields", "interval"]) or report.winner not in IDS or not report.tiles is Array or report.tiles.size() > 169 or not report.fields is Dictionary or not SolSpeciesDefinition.whole(report.interval, 1, 1000):
		return null
	var result := tiles.duplicate(true)
	var seen := {}
	for at in report.tiles:
		if not valid_key(at) or seen.has(at):
			return null
		seen[at] = true
		var row: Dictionary = result.get(at, {"affinity": report.winner, "conditions": {}}).duplicate(true)
		row.affinity = report.winner
		row.conditions.clear() # The battle's final field replaces/clears prior conditions on affected tiles.
		if report.fields.has(at):
			var field: Variant = report.fields[at]
			if not field is Dictionary or not RecordShape.keys_match(field, ["kind", "direction"]) or field.kind not in CONDITIONS or not field.direction is Array or field.direction.size() != 2:
				return null
			row.conditions[field.kind] = {"level": 3, "since": tick, "interval": int(report.interval), "direction": field.direction.duplicate()}
		result[at] = row
	for at in report.fields:
		if not seen.has(at):
			return null
	return result if valid_tiles(result, tick, limit) else null
