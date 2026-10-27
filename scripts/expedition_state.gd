class_name ExpeditionState
extends RefCounted
## Sole persistent authority for observed territories, sparse deltas and individual records.

signal territory_observed(identity: String)
signal individual_changed(identity: String)
signal environment_changed(cell: Vector2i)
signal activity_advanced(tick: int)

const VERSION := 1
const TERRITORY_SIZE := 16 # Source development setting; independent of render chunk size.
const ACTIVITY_INTERVAL := 0.75
const MAX_CATCH_UP := 2
const MAX_SAFE_INTEGER := 9007199254740991 # Exact JSON integer range.
const MAX_TERRITORIES := 4096
const MAX_INDIVIDUALS := 2048
const MAX_TILE_DELTAS := 8192
const OWNED_LOCATIONS := ["sealed", "party", "storage"]

var _seed: int
var _territory_size: int
var _tick := 0
var _remainder := 0.0
var _territories: Dictionary = {}
var _individuals: Dictionary = {}
var _tile_deltas: Dictionary = {}

func _init(seed_value: int = 0, territory_size: int = TERRITORY_SIZE) -> void:
	_seed = seed_value
	_territory_size = territory_size

func activity_tick() -> int:
	return _tick

func counts() -> Dictionary:
	return {"territories": _territories.size(), "individuals": _individuals.size(), "tile_deltas": _tile_deltas.size()}

func advance_time(delta: float) -> int:
	if not is_finite(delta) or delta < 0 or not is_finite(_remainder + delta):
		return 0
	var total := _remainder + delta
	var steps := int(minf(floor(total / ACTIVITY_INTERVAL), MAX_CATCH_UP))
	if _tick > MAX_SAFE_INTEGER - steps:
		return 0
	_remainder = fmod(total, ACTIVITY_INTERVAL)
	for step in range(steps):
		_tick += 1
		activity_advanced.emit(_tick)
	return steps

func territory_id(cell: Vector2i) -> String:
	if _territory_size < 1 or _territory_size > 256:
		return ""
	var coordinate := Vector2i((cell.x - posmod(cell.x, _territory_size)) / _territory_size, (cell.y - posmod(cell.y, _territory_size)) / _territory_size)
	return "%d:territory:%d:%d:%d" % [_seed, _territory_size, coordinate.x, coordinate.y]

func observe_territory(cell: Vector2i) -> bool:
	if absi(cell.x) > 1000000 or absi(cell.y) > 1000000:
		return false
	var identity := territory_id(cell)
	if identity.is_empty():
		return false
	if not _territories.has(identity) and _territories.size() >= MAX_TERRITORIES:
		return false
	if _territories.get(identity, {}).get("observed_tick", -1) == _tick:
		return false
	_territories[identity] = {"observed_tick": _tick}
	territory_observed.emit(identity)
	return true

func territory_view(cell: Vector2i) -> Dictionary:
	var identity := territory_id(cell)
	if not _territories.has(identity):
		return {}
	# Observation is not a population census: missing ecological knowledge remains unknown.
	return {"id": identity, "observed_tick": _territories[identity].observed_tick, "population": null, "capacity": null}

func individual_view(identity: String) -> Dictionary:
	return _individuals.get(identity, {}).duplicate(true)

func register_individual(species: SolSpeciesDefinition, home: Vector2i, affinity: String, generation: int = 0) -> String:
	if species == null or not species.valid() or not SolSpeciesDefinition.text(affinity) or _individuals.size() >= MAX_INDIVIDUALS:
		return ""
	var identity := SolIdentityContract.make(_seed, home, species.species_id, generation)
	if identity.is_empty() or _individuals.has(identity):
		return ""
	var record := species.snapshot()
	record.merge({"id": identity, "home": [home.x, home.y], "generation": generation, "affinity": affinity, "location": "wild"})
	var candidate := snapshot()
	candidate.individuals[identity] = record
	if not valid_snapshot(candidate, _seed):
		return ""
	_individuals[identity] = record.duplicate(true)
	individual_changed.emit(identity)
	return identity

func acquire(identity: String, location: String = "sealed") -> bool:
	if not OWNED_LOCATIONS.has(location) or not _individuals.has(identity) or _individuals[identity].location != "wild":
		return false
	_individuals[identity].location = location
	individual_changed.emit(identity)
	return true

func relocate_owned(identity: String, location: String) -> bool:
	if not OWNED_LOCATIONS.has(location) or not _individuals.has(identity) or not OWNED_LOCATIONS.has(_individuals[identity].location) or _individuals[identity].location == location:
		return false
	_individuals[identity].location = location
	individual_changed.emit(identity)
	return true

func relationship_view(identity: String) -> Variant:
	if not _individuals.has(identity) or not _individuals[identity].has("sol_relationship"):
		return null
	return _individuals[identity].sol_relationship.duplicate(true)

func record_relationship(identity: String, evidence: Dictionary) -> bool:
	if not _individuals.has(identity) or not OWNED_LOCATIONS.has(_individuals[identity].location) or not valid_relationship(evidence, _tick):
		return false
	evidence = normalized_relationship(evidence)
	if _individuals[identity].get("sol_relationship") == evidence:
		return false
	var prior: Array = _individuals[identity].get("sol_relationship", {}).get("memories", [])
	if evidence.memories.size() < prior.size():
		return false
	for index in range(prior.size()):
		if evidence.memories[index] != prior[index]:
			return false
	_individuals[identity].sol_relationship = evidence.duplicate(true)
	individual_changed.emit(identity)
	return true

func set_environment(cell: Vector2i, changes: Dictionary) -> bool:
	if absi(cell.x) > 1000000 or absi(cell.y) > 1000000 or not valid_delta(changes):
		return false
	var key := "%d:%d" % [cell.x, cell.y]
	if not _tile_deltas.has(key) and _tile_deltas.size() >= MAX_TILE_DELTAS:
		return false
	var combined: Dictionary = _tile_deltas.get(key, {}).duplicate(true)
	for field in changes:
		combined[field] = int(changes[field])
	if _tile_deltas.get(key) == combined:
		return false
	_tile_deltas[key] = combined
	environment_changed.emit(cell)
	return true

func environment_view(cell: Vector2i, generated: Dictionary) -> Dictionary:
	var result := generated.duplicate(true)
	result.merge(_tile_deltas.get("%d:%d" % [cell.x, cell.y], {}), true)
	return result

func snapshot() -> Dictionary:
	return {"version": VERSION, "activity_tick": _tick, "remainder_seconds": _remainder,
		"territory_size": _territory_size, "territories": _territories.duplicate(true),
		"individuals": _individuals.duplicate(true), "tile_deltas": _tile_deltas.duplicate(true)}

static func restore(data: Variant, seed_value: int) -> ExpeditionState:
	if not valid_snapshot(data, seed_value):
		return null
	var state := ExpeditionState.new(seed_value, int(data.territory_size))
	state._tick = int(data.activity_tick)
	state._remainder = float(data.remainder_seconds)
	state._territories = data.territories.duplicate(true)
	state._individuals = data.individuals.duplicate(true)
	state._tile_deltas = data.tile_deltas.duplicate(true)
	for key in state._territories:
		state._territories[key].observed_tick = int(state._territories[key].observed_tick)
	for identity in state._individuals:
		var record: Dictionary = state._individuals[identity]
		record.home = [int(record.home[0]), int(record.home[1])]
		for field in ["generation", "ordinary_form", "footprint"]:
			record[field] = int(record[field])
		if record.has("sol_relationship"):
			record.sol_relationship = normalized_relationship(record.sol_relationship)
	for key in state._tile_deltas:
		for field in state._tile_deltas[key]:
			state._tile_deltas[key][field] = int(state._tile_deltas[key][field])
	return state

static func normalized_relationship(evidence: Dictionary) -> Dictionary:
	var result := evidence.duplicate(true)
	result.version = int(result.version)
	if result.trust != null:
		result.trust = int(result.trust)
	for memory in result.memories:
		memory.tick = int(memory.tick)
	return result

static func keys_match(data: Dictionary, expected: Array) -> bool:
	if data.size() != expected.size():
		return false
	for key in expected:
		if not data.has(key):
			return false
	return true

static func valid_delta(data: Variant) -> bool:
	if not data is Dictionary or data.is_empty() or data.size() > 2:
		return false
	for key in data:
		if key not in ["concentration", "overload"] or not SolSpeciesDefinition.whole(data[key], 0, 100):
			return false
	return true

static func valid_relationship(data: Variant, tick: int) -> bool:
	if not data is Dictionary or not keys_match(data, ["version", "trust", "memories"]) or not SolSpeciesDefinition.whole(data.version, 1, 1):
		return false
	if data.trust != null and not SolSpeciesDefinition.whole(data.trust, 0, 100):
		return false
	if not data.memories is Array or data.memories.size() > 32:
		return false
	var seen: Dictionary = {}
	var previous := 0
	for memory in data.memories:
		if not memory is Dictionary or not keys_match(memory, ["event_id", "kind", "tick", "note"]):
			return false
		if not SolSpeciesDefinition.text(memory.event_id, 128) or not SolSpeciesDefinition.text(memory.kind, 64) or not SolSpeciesDefinition.text(memory.note, 256) or not SolSpeciesDefinition.whole(memory.tick, previous, tick) or seen.has(memory.event_id):
			return false
		seen[memory.event_id] = true
		previous = int(memory.tick)
	return true

static func valid_snapshot(data: Variant, seed_value: int) -> bool:
	if not data is Dictionary or not keys_match(data, ["version", "activity_tick", "remainder_seconds", "territory_size", "territories", "individuals", "tile_deltas"]):
		return false
	if not SolSpeciesDefinition.whole(seed_value, 0, 2147483646) or not SolSpeciesDefinition.whole(data.version, VERSION, VERSION) or not SolSpeciesDefinition.whole(data.activity_tick, 0, MAX_SAFE_INTEGER) or not SolSpeciesDefinition.whole(data.territory_size, 1, 256):
		return false
	if not (data.remainder_seconds is float or data.remainder_seconds is int) or not is_finite(float(data.remainder_seconds)) or data.remainder_seconds < 0 or data.remainder_seconds >= ACTIVITY_INTERVAL:
		return false
	if not data.territories is Dictionary or data.territories.size() > MAX_TERRITORIES or not data.individuals is Dictionary or data.individuals.size() > MAX_INDIVIDUALS or not data.tile_deltas is Dictionary or data.tile_deltas.size() > MAX_TILE_DELTAS:
		return false
	for key in data.territories:
		if not key is String:
			return false
		var parts: PackedStringArray = key.split(":")
		if parts.size() != 5 or parts[1] != "territory" or not parts[3].is_valid_int() or not parts[4].is_valid_int():
			return false
		var coordinate := Vector2i(int(parts[3]), int(parts[4]))
		if absi(coordinate.x) > 1000000 or absi(coordinate.y) > 1000000 or key != "%d:territory:%d:%d:%d" % [seed_value, int(data.territory_size), coordinate.x, coordinate.y]:
			return false
		var size := int(data.territory_size)
		if coordinate.x * size > 1000000 or coordinate.y * size > 1000000 or (coordinate.x + 1) * size <= -1000000 or (coordinate.y + 1) * size <= -1000000:
			return false
		var record: Variant = data.territories[key]
		if not record is Dictionary or not keys_match(record, ["observed_tick"]) or not SolSpeciesDefinition.whole(record.observed_tick, 0, int(data.activity_tick)):
			return false
	var lineage_classes: Dictionary = {}
	var definitions: Dictionary = {}
	var wild_homes: Dictionary = {}
	for identity in data.individuals:
		var origin := SolIdentityContract.parse(identity)
		var record: Variant = data.individuals[identity]
		if origin.is_empty() or origin.seed != seed_value or not record is Dictionary:
			return false
		var expected := ["id", "home", "generation", "species_id", "lineage_id", "class_id", "ordinary_form", "footprint", "affinity", "location"]
		if record.has("sol_relationship"):
			expected.append("sol_relationship")
		if not keys_match(record, expected) or record.id != identity or not SolSpeciesDefinition.valid_record(record) or not SolSpeciesDefinition.text(record.affinity) or not record.location in ["wild", "sealed", "party", "storage"]:
			return false
		if not record.home is Array or record.home.size() != 2 or not SolSpeciesDefinition.whole(record.home[0], -1000000, 1000000) or not SolSpeciesDefinition.whole(record.home[1], -1000000, 1000000) or not SolSpeciesDefinition.whole(record.generation, 0, 2147483647):
			return false
		if int(record.home[0]) != origin.home[0] or int(record.home[1]) != origin.home[1] or int(record.generation) != origin.generation or record.species_id != origin.species_id:
			return false
		if record.location == "wild":
			var home_id := SolIdentityContract.make(seed_value, Vector2i(origin.home[0], origin.home[1]), origin.species_id)
			if wild_homes.has(home_id) or record.has("sol_relationship"):
				return false
			wild_homes[home_id] = true
		if record.has("sol_relationship") and not valid_relationship(record.sol_relationship, int(data.activity_tick)):
			return false
		if lineage_classes.has(record.lineage_id) and lineage_classes[record.lineage_id] != record.class_id:
			return false
		lineage_classes[record.lineage_id] = record.class_id
		var definition := {"lineage_id": record.lineage_id, "class_id": record.class_id, "ordinary_form": record.ordinary_form, "footprint": record.footprint}
		if definitions.has(record.species_id) and definitions[record.species_id] != definition:
			return false
		definitions[record.species_id] = definition
	for key in data.tile_deltas:
		if not key is String or not valid_delta(data.tile_deltas[key]):
			return false
		var parts: PackedStringArray = key.split(":")
		if parts.size() != 2 or not parts[0].is_valid_int() or not parts[1].is_valid_int():
			return false
		var cell := Vector2i(int(parts[0]), int(parts[1]))
		if absi(cell.x) > 1000000 or absi(cell.y) > 1000000 or key != "%d:%d" % [cell.x, cell.y]:
			return false
	return true
