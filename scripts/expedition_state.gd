class_name ExpeditionState
extends RefCounted
## Sole persistent authority for observed territories, sparse deltas and individual records.

signal territory_observed(identity: String)
signal individual_changed(identity: String)
signal environment_changed(cell: Vector2i)
signal activity_advanced(tick: int)
signal human_activity_applied(event: Dictionary, effect: Dictionary)
signal discovery_recorded(identity: String)

const VERSION := 4
const MAX_DISCOVERIES := 120 # Source journal retention: oldest discovery rows retire, not individuals.
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
var _human_activity := HumanVastraActivity.empty_ledger()
var _natural := VastraNatural.empty_schedule()
var _discoveries: Array[Dictionary] = []
# Derived indexes: never saved and never sources of population or individual identity.
var _known_homes: Dictionary = {}
var _wild_homes: Dictionary = {}
var _population_homes: Dictionary = {}
var _population_order: Array[String] = []
var _population_cache_limit := 256

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

func discovery_entries() -> Array[Dictionary]:
	return _discoveries.duplicate(true)

func has_discovery(identity: String) -> bool:
	for entry in _discoveries:
		if entry.key == identity:
			return true
	return false

func record_sol_discovery(identity: String, title: String, description: String, seen_at: Vector2i) -> bool:
	if not _individuals.has(identity) or _individuals[identity].location != "wild" or has_discovery(identity):
		return false
	var entry := {"key": identity, "title": title, "category": "Wild Sol", "description": description,
		"details": [], "first_seen": [seen_at.x, seen_at.y]}
	if not valid_discovery(entry, _individuals):
		return false
	_discoveries.append(entry)
	if _discoveries.size() > MAX_DISCOVERIES:
		_discoveries.pop_front()
	discovery_recorded.emit(identity)
	return true

func home_identity(identity: String) -> String:
	var origin := SolIdentityContract.parse(identity)
	if origin.is_empty() or origin.seed != _seed:
		return ""
	return SolIdentityContract.make(_seed, Vector2i(origin.home[0], origin.home[1]), origin.species_id)

func set_population_cache_limit(limit: Variant) -> bool:
	if not SolSpeciesDefinition.whole(limit, 1, 1024):
		return false
	if _population_cache_limit != int(limit):
		_population_cache_limit = int(limit)
		_population_homes.clear()
		_population_order.clear()
	return true

func invalidate_population_territory(cell: Vector2i) -> bool:
	var territory := territory_id(cell)
	if not _population_homes.has(territory):
		return false
	_population_homes.erase(territory)
	_population_order.erase(territory)
	return true

func remember_population_territory(cell: Vector2i, complete_homes: Array) -> bool:
	# The producer must supply complete home definitions before any viewport clipping.
	if absi(cell.x) > 1000000 or absi(cell.y) > 1000000 or complete_homes.size() > 256:
		return false
	var territory := territory_id(cell)
	if territory.is_empty():
		return false
	var normalized: Array[String] = []
	var coordinates: Dictionary = {}
	for identity in complete_homes:
		if not identity is String or not _known_homes.has(identity):
			return false
		var origin := SolIdentityContract.parse(identity)
		if origin.is_empty() or origin.generation != 0:
			return false
		var home := Vector2i(origin.home[0], origin.home[1])
		if territory_id(home) != territory or coordinates.has(home):
			return false
		coordinates[home] = true
		normalized.append(identity)
	_population_homes[territory] = normalized
	_population_order.erase(territory)
	_population_order.append(territory)
	if _population_order.size() > _population_cache_limit:
		_population_homes.erase(_population_order.pop_front())
	return true

func population_summary(cell: Vector2i, carrying_capacities: Dictionary = {}, region_resolver: Callable = Callable()) -> Dictionary:
	if absi(cell.x) > 1000000 or absi(cell.y) > 1000000 or carrying_capacities.size() > 128:
		return {}
	for region in carrying_capacities:
		if not SolSpeciesDefinition.text(region) or not SolSpeciesDefinition.whole(carrying_capacities[region], 0, 256):
			return {}
	if not carrying_capacities.is_empty() and not region_resolver.is_valid():
		return {}
	var territory := territory_id(cell)
	if not _population_homes.has(territory):
		return {} # Unknown, never an inferred zero or a generation request.
	var capacity: Variant = null
	if not carrying_capacities.is_empty():
		var origin := cell - Vector2i(posmod(cell.x, _territory_size), posmod(cell.y, _territory_size))
		var region: Variant = region_resolver.call(origin)
		if not SolSpeciesDefinition.text(region):
			return {}
		capacity = carrying_capacities.get(region)
	var available := 0
	for identity: String in _population_homes[territory]:
		if _wild_homes.has(identity):
			available += 1
	return {"territory_id": territory, "home_slots": _population_homes[territory].size(),
		"available": available, "tick": _tick, "carrying_capacity": capacity,
		"effective_population": mini(available, int(capacity)) if capacity != null else null}

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
	var base := home_identity(identity)
	_known_homes[base] = true
	_wild_homes[base] = identity
	individual_changed.emit(identity)
	return identity

func acquire(identity: String, location: String = "sealed") -> bool:
	if not OWNED_LOCATIONS.has(location) or not _individuals.has(identity) or _individuals[identity].location != "wild":
		return false
	_individuals[identity].location = location
	_wild_homes.erase(home_identity(identity))
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
	if not _tile_deltas.has(key):
		_natural.order.append(key)
	_tile_deltas[key] = combined
	if combined.get("overload", 0) == 0:
		_natural.recovery_ticks.erase(key)
	environment_changed.emit(cell)
	return true

func environment_view(cell: Vector2i, generated: Dictionary) -> Dictionary:
	var result := generated.duplicate(true)
	result.merge(_tile_deltas.get("%d:%d" % [cell.x, cell.y], {}), true)
	return result

func human_activity_view() -> Dictionary:
	return _human_activity.duplicate(true)

func apply_human_activity(event: Variant, generated: Dictionary = {}, region: String = "", budget: Variant = null) -> Dictionary:
	if not HumanVastraActivity.valid_event(event):
		return {}
	var cell := Vector2i(int(event.cell[0]), int(event.cell[1]))
	var prepared := HumanVastraActivity.prepare(_human_activity, event, _tick, environment_view(cell, generated), region, budget)
	if prepared.is_empty():
		return {}
	if prepared.effect.replayed:
		return prepared.effect.duplicate(true)
	var key := "%d:%d" % [cell.x, cell.y]
	var candidate := snapshot()
	candidate.tile_deltas[key] = {"concentration": prepared.effect.concentration, "overload": prepared.effect.overload}
	candidate.human_activity = prepared.ledger
	if not _tile_deltas.has(key):
		candidate.natural.order.append(key)
	if prepared.effect.overload > 0 and not candidate.natural.recovery_ticks.has(key):
		candidate.natural.recovery_ticks[key] = _tick
	elif prepared.effect.overload == 0:
		candidate.natural.recovery_ticks.erase(key)
	if not valid_snapshot(candidate, _seed):
		return {}
	# Install both authorities before observers run; no partial event is visible.
	_tile_deltas[key] = candidate.tile_deltas[key].duplicate(true)
	_human_activity = prepared.ledger.duplicate(true)
	_natural = candidate.natural.duplicate(true)
	environment_changed.emit(cell)
	human_activity_applied.emit(HumanVastraActivity.normalized_event(event), prepared.effect.duplicate(true))
	return prepared.effect.duplicate(true)

func natural_view() -> Dictionary:
	return _natural.duplicate(true)

func advance_environment(policy: Dictionary, profile_resolver: Callable = Callable()) -> int:
	var prepared := VastraNatural.prepare(_tile_deltas, _natural, _tick, policy, profile_resolver)
	if prepared.is_empty():
		return -1
	if not prepared.has("cursor"):
		return 0
	# All bounded candidates are prepared before any update or signal is published.
	for key in prepared.changes:
		_tile_deltas[key] = prepared.changes[key]
	for key in prepared.stamps:
		if prepared.stamps[key] == null:
			_natural.recovery_ticks.erase(key)
		else:
			_natural.recovery_ticks[key] = prepared.stamps[key]
	_natural.cursor = prepared.cursor
	_natural.last_tick = _tick
	for key: String in prepared.changes:
		var parts := key.split(":")
		environment_changed.emit(Vector2i(int(parts[0]), int(parts[1])))
	return int(prepared.processed)

func snapshot() -> Dictionary:
	return {"version": VERSION, "activity_tick": _tick, "remainder_seconds": _remainder,
		"territory_size": _territory_size, "territories": _territories.duplicate(true),
		"individuals": _individuals.duplicate(true), "tile_deltas": _tile_deltas.duplicate(true),
		"human_activity": _human_activity.duplicate(true), "natural": _natural.duplicate(true),
		"discoveries": _discoveries.duplicate(true)}

static func restore(data: Variant, seed_value: int) -> ExpeditionState:
	if not valid_snapshot(data, seed_value):
		return null
	var state := ExpeditionState.new(seed_value, int(data.territory_size))
	state._tick = int(data.activity_tick)
	state._remainder = float(data.remainder_seconds)
	state._territories = data.territories.duplicate(true)
	state._individuals = data.individuals.duplicate(true)
	state._tile_deltas = data.tile_deltas.duplicate(true)
	if int(data.version) >= 4:
		for entry in data.discoveries:
			var copy: Dictionary = entry.duplicate(true)
			copy.first_seen = [int(copy.first_seen[0]), int(copy.first_seen[1])]
			state._discoveries.append(copy)
	if int(data.version) >= 2:
		state._human_activity = HumanVastraActivity.normalized_ledger(data.human_activity)
	if int(data.version) >= 3:
		state._natural = data.natural.duplicate(true)
		state._natural.cursor = int(state._natural.cursor)
		state._natural.last_tick = int(state._natural.last_tick)
		for key in state._natural.recovery_ticks:
			state._natural.recovery_ticks[key] = int(state._natural.recovery_ticks[key])
	else:
		# Older envelopes have no scheduling order or known damage ages.
		state._natural.order = state._tile_deltas.keys()
	for key in state._territories:
		state._territories[key].observed_tick = int(state._territories[key].observed_tick)
	for identity in state._individuals:
		var record: Dictionary = state._individuals[identity]
		record.home = [int(record.home[0]), int(record.home[1])]
		for field in ["generation", "ordinary_form", "footprint"]:
			record[field] = int(record[field])
		if record.has("sol_relationship"):
			record.sol_relationship = normalized_relationship(record.sol_relationship)
		var base := state.home_identity(identity)
		state._known_homes[base] = true
		if record.location == "wild":
			state._wild_homes[base] = identity
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

static func valid_discovery(entry: Variant, individuals: Dictionary) -> bool:
	if not entry is Dictionary or not keys_match(entry, ["key", "title", "category", "description", "details", "first_seen"]):
		return false
	if not entry.key is String or not individuals.has(entry.key) or not SolSpeciesDefinition.text(entry.title, 80) or entry.category != "Wild Sol" or not SolSpeciesDefinition.text(entry.description, 400):
		return false
	if not entry.details is Array or entry.details.size() > 8 or not entry.first_seen is Array or entry.first_seen.size() != 2:
		return false
	for detail in entry.details:
		if not SolSpeciesDefinition.text(detail, 120):
			return false
	return SolSpeciesDefinition.whole(entry.first_seen[0], -1000000, 1000000) and SolSpeciesDefinition.whole(entry.first_seen[1], -1000000, 1000000)

static func valid_snapshot(data: Variant, seed_value: int) -> bool:
	if not data is Dictionary or not SolSpeciesDefinition.whole(data.get("version"), 1, VERSION):
		return false
	var expected_fields := ["version", "activity_tick", "remainder_seconds", "territory_size", "territories", "individuals", "tile_deltas"]
	if int(data.version) >= 2:
		expected_fields.append("human_activity")
	if int(data.version) >= 3:
		expected_fields.append("natural")
	if int(data.version) >= 4:
		expected_fields.append("discoveries")
	if not keys_match(data, expected_fields):
		return false
	if not SolSpeciesDefinition.whole(seed_value, 0, 2147483646) or not SolSpeciesDefinition.whole(data.activity_tick, 0, MAX_SAFE_INTEGER) or not SolSpeciesDefinition.whole(data.territory_size, 1, 256):
		return false
	if int(data.version) >= 2 and not HumanVastraActivity.valid_ledger(data.human_activity, int(data.activity_tick)):
		return false
	if not (data.remainder_seconds is float or data.remainder_seconds is int) or not is_finite(float(data.remainder_seconds)) or data.remainder_seconds < 0 or data.remainder_seconds >= ACTIVITY_INTERVAL:
		return false
	if not data.territories is Dictionary or data.territories.size() > MAX_TERRITORIES or not data.individuals is Dictionary or data.individuals.size() > MAX_INDIVIDUALS or not data.tile_deltas is Dictionary or data.tile_deltas.size() > MAX_TILE_DELTAS:
		return false
	if int(data.version) >= 4:
		if not data.discoveries is Array or data.discoveries.size() > MAX_DISCOVERIES:
			return false
		var discovery_keys: Dictionary = {}
		for entry in data.discoveries:
			if not valid_discovery(entry, data.individuals) or discovery_keys.has(entry.key):
				return false
			discovery_keys[entry.key] = true
	if int(data.version) >= 3:
		# Tile fields are checked below before schedule validation reads their values.
		for value in data.tile_deltas.values():
			if not valid_delta(value):
				return false
		if not VastraNatural.valid_schedule(data.natural, data.tile_deltas, int(data.activity_tick)):
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
