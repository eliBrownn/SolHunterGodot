class_name ExpeditionState
extends RefCounted
## Sole persistent authority for observed territories, sparse deltas and individual records.

signal territory_observed(identity: String)
signal individual_changed(identity: String)
signal environment_changed(cell: Vector2i)
signal activity_advanced(tick: int)
signal human_activity_applied(event: Dictionary, effect: Dictionary)
signal discovery_recorded(identity: String)
signal battle_progress_changed

const VERSION := 9
const MAX_DISCOVERIES := 120 # Source journal retention: oldest discovery rows retire, not individuals.
const MAX_ROAMING_DISTANCE := 5 # Saved movement schema bound; tuning may choose a smaller home range.
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
var _roaming: Dictionary = {}
var _battle := BattleProgress.empty()
var _battle_enemy := ""
var _movebooks: Dictionary = {}
var _affinity_tiles: Dictionary = {}
var _wild_population: Dictionary = {}
var _collection := CollectionProgress.empty()
var _progression_policy := ProgressionSettings.new().parameters()
var _wild_recovery_delay := 0 # Bare domain instances do not invent a live recovery policy.
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

func wild_available(identity: String) -> bool:
	return _individuals.get(identity, {}).get("location") == "wild" and not _battle.defeated.has(identity)

func battle_progress() -> Dictionary:
	return _battle.duplicate(true)

func starter_view() -> Dictionary:
	return {} if _battle.starter_id.is_empty() else {"id": _battle.starter_id, "profile": _battle.profile.duplicate(true), "hp": _battle.hp}

func choose_starter(profile: Dictionary, index: int) -> bool:
	if _battle.active or not _battle.starter_id.is_empty() or index < 0 or index > 2 or not BattleProfile.valid_snapshot(profile):
		return false
	for record in _individuals.values():
		if record.location in OWNED_LOCATIONS:
			return false # Do not infer/rewrite a legacy owned collection as a new starter.
	var identity := SolIdentityContract.make(_seed, Vector2i(index, 0), profile.species_id)
	if _individuals.has(identity) or _individuals.size() >= MAX_INDIVIDUALS:
		return false
	var record := {"id": identity, "home": [index, 0], "generation": 0, "species_id": profile.species_id,
		"lineage_id": profile.lineage_id, "class_id": profile.class_id, "ordinary_form": 1,
		"footprint": 1, "affinity": AffinityImprint.canonical(profile.affinity), "location": "party"}
	var candidate := snapshot()
	candidate.individuals[identity] = record
	candidate.battle.starter_id = identity
	candidate.battle.profile = BattleProfile.normalized(profile)
	candidate.battle.profile.affinity = AffinityImprint.canonical(profile.affinity)
	candidate.battle.hp = int(profile.max_hp)
	candidate.collection.selected = identity
	candidate.collection.owned[identity] = CollectionProgress.entry(candidate.battle.profile, int(profile.max_hp))
	if not valid_snapshot(candidate, _seed):
		return false
	_individuals[identity] = record
	_known_homes[home_identity(identity)] = true
	_battle = candidate.battle
	_collection = candidate.collection
	battle_progress_changed.emit()
	return true

func begin_battle(enemy_id: String) -> int:
	var hero := active_sol_view()
	if _affinity_tiles.size() > MAX_TILE_DELTAS - 169 or _battle.active or hero.is_empty() or hero.hp <= 0 or not wild_available(enemy_id) or _battle.serial >= MAX_SAFE_INTEGER:
		return 0
	if _individuals[hero.id].location != "party":
		return 0
	_battle.serial += 1
	_battle.active = true
	_battle_enemy = enemy_id
	return int(_battle.serial)

func complete_battle(serial: int, hp: int, outcome: String, grace_steps: int, imprint: Dictionary = {}, details: Dictionary = {}) -> bool:
	var hero := active_sol_view()
	if not _battle.active or serial != _battle.serial or hero.is_empty() or not wild_available(_battle_enemy) or outcome not in ["victory", "exhaustion", "retreat", "captured"] or not SolSpeciesDefinition.whole(hp, 0, int(hero.profile.max_hp)) or grace_steps < 0 or grace_steps > 8:
		return false
	if (outcome == "exhaustion") != (hp == 0):
		return false
	var candidate := snapshot()
	candidate.battle.active = false
	candidate.battle[{"victory": "wins", "exhaustion": "losses", "retreat": "retreats", "captured": "captures"}[outcome]] += 1
	candidate.battle.last_result = {"serial": serial, "enemy_id": _battle_enemy, "outcome": outcome}
	candidate.battle.grace_steps = grace_steps
	candidate.collection.owned[hero.id].hp = hp
	if outcome == "victory":
		candidate.battle.defeated[_battle_enemy] = true
		if details.get("participated", false) == true:
			var level: Variant = details.get("enemy_level", 1)
			if not SolSpeciesDefinition.whole(level, 1, 55):
				return false
			var reward := maxi(int(_progression_policy.minimum_xp), int(_progression_policy.victory_base) + int(level) * int(_progression_policy.xp_per_enemy_level))
			candidate.collection.owned[hero.id] = CollectionProgress.grow(candidate.collection.owned[hero.id], reward, _progression_policy)
			if int(candidate.collection.owned[hero.id].profile.level) > int(hero.profile.level):
				learn_earned_moves(candidate.collection.owned[hero.id], candidate.movebooks.get(hero.id, {}), details.get("move_definitions", {}))
	if outcome == "captured":
		var capture: Variant = details.get("capture")
		if not capture is Dictionary or not keys_match(capture, ["profile", "hp", "unlocks"]) or not capture.unlocks is Dictionary or not BattleProfile.valid_snapshot(capture.profile) or not SolSpeciesDefinition.whole(capture.hp, 1, int(capture.profile.max_hp)) or candidate.collection.owned.has(_battle_enemy) or not candidate.movebooks.has(_battle_enemy):
			return false
		for field in ["species_id", "lineage_id", "class_id", "affinity"]:
			if capture.profile[field] != candidate.individuals[_battle_enemy][field]:
				return false
		var party := 0
		for id in candidate.individuals:
			if candidate.individuals[id].location == "party":
				party += 1
		candidate.individuals[_battle_enemy].location = "party" if party < CollectionProgress.PARTY_LIMIT else "storage"
		candidate.individuals[_battle_enemy].sol_relationship = {"version": 1, "trust": null, "memories": []}
		candidate.collection.owned[_battle_enemy] = CollectionProgress.entry(capture.profile, int(capture.hp))
		candidate.collection.owned[_battle_enemy].unlocks = capture.unlocks.duplicate(true)
	if hero.id == candidate.battle.starter_id:
		candidate.battle.profile = candidate.collection.owned[hero.id].profile.duplicate(true)
		candidate.battle.hp = candidate.collection.owned[hero.id].hp
	var tiles: Variant = AffinityImprint.apply(_affinity_tiles, imprint, _tick, MAX_TILE_DELTAS)
	if tiles == null:
		return false
	candidate.affinity_tiles = tiles
	if outcome in ["victory", "captured"]:
		candidate.roaming.erase(_battle_enemy)
		var population := WildPopulation.deplete(_wild_population, _battle_enemy, _tick, _wild_recovery_delay)
		if WildPopulation.valid(population, _seed, _tick, candidate.individuals, candidate.battle.defeated):
			candidate.wild_population = population
	if not valid_snapshot(candidate, _seed):
		return false
	var enemy := _battle_enemy
	_battle = candidate.battle
	_collection = candidate.collection
	_individuals = candidate.individuals
	_movebooks = candidate.movebooks
	_affinity_tiles = candidate.affinity_tiles
	_wild_population = candidate.wild_population
	_roaming = candidate.roaming
	_battle_enemy = ""
	if outcome in ["victory", "captured"]:
		_wild_homes.erase(home_identity(enemy))
	battle_progress_changed.emit()
	individual_changed.emit(enemy)
	return true

func recover_starter() -> bool:
	if _battle.active or _battle.starter_id.is_empty() or _battle.hp == _battle.profile.max_hp:
		return false
	_battle.hp = int(_battle.profile.max_hp)
	_collection.owned[_battle.starter_id].hp = _battle.hp
	battle_progress_changed.emit()
	return true

func recover_party() -> bool:
	if _battle.active:
		return false
	var changed := false
	for id in _collection.owned:
		if _individuals[id].location == "party" and _collection.owned[id].hp < _collection.owned[id].profile.max_hp:
			_collection.owned[id].hp = int(_collection.owned[id].profile.max_hp)
			changed = true
	if not _battle.starter_id.is_empty():
		_battle.hp = _collection.owned[_battle.starter_id].hp
	if changed:
		battle_progress_changed.emit()
	return changed

func battle_grace() -> int:
	return int(_battle.grace_steps)

func consume_battle_grace() -> void:
	_battle.grace_steps = maxi(0, int(_battle.grace_steps) - 1)

func roaming_view(identity: String) -> Dictionary:
	var record: Dictionary = _individuals.get(identity, {})
	if not wild_available(identity):
		return {}
	return _roaming.get(identity, {"cell": record.home, "action": "idle", "tick": -1}).duplicate(true)

func record_roaming_step(identity: String, target: Vector2i, action: String) -> bool:
	var previous := roaming_view(identity)
	if previous.is_empty() or int(previous.tick) >= _tick:
		return false
	var from := Vector2i(int(previous.cell[0]), int(previous.cell[1]))
	var change := target - from
	if absi(change.x) + absi(change.y) > 1:
		return false
	var candidate := {"cell": [target.x, target.y], "action": action, "tick": _tick}
	if not valid_roaming(candidate, _individuals[identity], _tick):
		return false
	_roaming[identity] = candidate
	individual_changed.emit(identity)
	return true

func discovery_entries() -> Array[Dictionary]:
	return _discoveries.duplicate(true)

func has_discovery(identity: String) -> bool:
	for entry in _discoveries:
		if entry.key == identity:
			return true
	return false

func record_sol_discovery(identity: String, title: String, description: String, seen_at: Vector2i) -> bool:
	if not wild_available(identity) or has_discovery(identity):
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
	record.merge({"id": identity, "home": [home.x, home.y], "generation": generation, "affinity": AffinityImprint.canonical(affinity), "location": "wild"})
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
	if _battle.active or not OWNED_LOCATIONS.has(location) or not wild_available(identity):
		return false
	_individuals[identity].location = location
	var population := WildPopulation.deplete(_wild_population, identity, _tick, _wild_recovery_delay)
	if WildPopulation.valid(population, _seed, _tick, _individuals, _battle.defeated):
		_wild_population = population
	_wild_homes.erase(home_identity(identity))
	_roaming.erase(identity)
	individual_changed.emit(identity)
	return true

func relocate_owned(identity: String, location: String) -> bool:
	if _collection.owned.has(identity):
		return transfer_companion(identity, location)
	if _battle.active or not OWNED_LOCATIONS.has(location) or not _individuals.has(identity) or not OWNED_LOCATIONS.has(_individuals[identity].location) or _individuals[identity].location == location:
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
	result.merge(_affinity_tiles.get(AffinityImprint.key(cell), {}).duplicate(true), true)
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
		"discoveries": _discoveries.duplicate(true), "roaming": _roaming.duplicate(true), "battle": _battle.duplicate(true), "movebooks": _movebooks.duplicate(true), "affinity_tiles": _affinity_tiles.duplicate(true), "wild_population": _wild_population.duplicate(true), "collection": _collection.duplicate(true)}

static func restore(data: Variant, seed_value: int) -> ExpeditionState:
	if not valid_snapshot(data, seed_value):
		return null
	var state := ExpeditionState.new(seed_value, int(data.territory_size))
	state._tick = int(data.activity_tick)
	state._remainder = float(data.remainder_seconds)
	state._territories = data.territories.duplicate(true)
	state._individuals = data.individuals.duplicate(true)
	state._tile_deltas = data.tile_deltas.duplicate(true)
	if int(data.version) >= 9:
		state._collection = CollectionProgress.normalized(data.collection)
	if int(data.version) >= 8:
		state._wild_population = WildPopulation.normalized(data.wild_population)
	if int(data.version) >= 7:
		state._movebooks = data.movebooks.duplicate(true)
		for book in state._movebooks.values():
			for id in book.learned:
				book.learned[id] = SolMove.normalized(book.learned[id])
		state._affinity_tiles = data.affinity_tiles.duplicate(true)
		for row in state._affinity_tiles.values():
			for effect in row.conditions.values():
				for field in ["level", "since", "interval"]:
					effect[field] = int(effect[field])
				effect.direction = [int(effect.direction[0]), int(effect.direction[1])]
	if int(data.version) >= 6:
		state._battle = BattleProgress.normalized(data.battle)
		if not state._battle.profile.is_empty():
			state._battle.profile.affinity = AffinityImprint.canonical(state._battle.profile.affinity)
	if int(data.version) >= 5:
		state._roaming = data.roaming.duplicate(true)
		for identity in state._roaming:
			var row: Dictionary = state._roaming[identity]
			row.cell = [int(row.cell[0]), int(row.cell[1])]
			row.tick = int(row.tick)
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
		record.affinity = AffinityImprint.canonical(record.affinity)
		record.home = [int(record.home[0]), int(record.home[1])]
		for field in ["generation", "ordinary_form", "footprint"]:
			record[field] = int(record[field])
		if record.has("sol_relationship"):
			record.sol_relationship = normalized_relationship(record.sol_relationship)
		var base := state.home_identity(identity)
		state._known_homes[base] = true
		if state.wild_available(identity):
			state._wild_homes[base] = identity
	for key in state._tile_deltas:
		for field in state._tile_deltas[key]:
			state._tile_deltas[key][field] = int(state._tile_deltas[key][field])
	if int(data.version) < 9 and not state._battle.starter_id.is_empty():
		state._collection.selected = state._battle.starter_id
		state._collection.owned[state._battle.starter_id] = CollectionProgress.entry(state._battle.profile, int(state._battle.hp))
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

static func valid_roaming(row: Variant, individual: Dictionary, tick: int) -> bool:
	if not row is Dictionary or not keys_match(row, ["cell", "action", "tick"]) or individual.get("location") != "wild":
		return false
	if row.action not in ["idle", "flee", "approach", "guard", "return"] or not SolSpeciesDefinition.whole(row.tick, 0, tick) or not row.cell is Array or row.cell.size() != 2:
		return false
	if not SolSpeciesDefinition.whole(row.cell[0], -1000000, 1000000) or not SolSpeciesDefinition.whole(row.cell[1], -1000000, 1000000):
		return false
	return absi(int(row.cell[0]) - int(individual.home[0])) + absi(int(row.cell[1]) - int(individual.home[1])) <= MAX_ROAMING_DISTANCE

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
	if int(data.version) >= 5:
		expected_fields.append("roaming")
	if int(data.version) >= 6:
		expected_fields.append("battle")
	if int(data.version) >= 7:
		expected_fields.append("movebooks")
		expected_fields.append("affinity_tiles")
	if int(data.version) >= 8:
		expected_fields.append("wild_population")
	if int(data.version) >= 9:
		expected_fields.append("collection")
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
			var depleted: bool = int(data.version) >= 6 and data.battle is Dictionary and data.battle.get("defeated") is Dictionary and data.battle.defeated.has(identity)
			if (wild_homes.has(home_id) and not depleted) or record.has("sol_relationship"):
				return false
			if not depleted:
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
	if int(data.version) >= 7:
		if not data.movebooks is Dictionary or data.movebooks.size() > data.individuals.size() or not AffinityImprint.valid_tiles(data.affinity_tiles, int(data.activity_tick), MAX_TILE_DELTAS):
			return false
		for identity in data.movebooks:
			if not identity is String or not data.individuals.has(identity) or not MoveLibrary.valid_book(data.movebooks[identity]):
				return false
	if int(data.version) >= 6 and not BattleProgress.valid(data.battle, data.individuals):
		return false
	if int(data.version) >= 9 and (not data.battle.has("captures") or not CollectionProgress.valid(data.collection, data.individuals, data.battle)):
		return false
	if int(data.version) >= 8 and not WildPopulation.valid(data.wild_population, seed_value, int(data.activity_tick), data.individuals, data.battle.defeated):
		return false
	if int(data.version) >= 5:
		if not data.roaming is Dictionary or data.roaming.size() > data.individuals.size():
			return false
		for identity in data.roaming:
			if int(data.version) >= 6 and data.battle.defeated.has(identity):
				return false
			if not identity is String or not data.individuals.has(identity) or not valid_roaming(data.roaming[identity], data.individuals[identity], int(data.activity_tick)):
				return false
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

func movebook(identity: String) -> Dictionary:
	return _movebooks.get(identity, {}).duplicate(true)

func admit_movebook(identity: String, book: Dictionary) -> bool:
	if _battle.active or not _individuals.has(identity) or _movebooks.has(identity) or not MoveLibrary.valid_book(book):
		return false
	_movebooks[identity] = book.duplicate(true)
	return true

func learn_move(identity: String, move: Dictionary) -> bool:
	if _battle.active or not _movebooks.has(identity) or _individuals[identity].location not in OWNED_LOCATIONS or not SolMove.valid(move):
		return false
	var book: Dictionary = _movebooks[identity]
	if not book.pool.has(move.id) or book.learned.has(move.id) or (_collection.owned.has(identity) and int(_collection.owned[identity].unlocks.get(move.id, 55)) > int(_collection.owned[identity].profile.level)):
		return false
	book.learned[move.id] = SolMove.normalized(move)
	return true

func equip_moves(identity: String, ids: Array) -> bool:
	if _battle.active or not _movebooks.has(identity) or _individuals[identity].location not in OWNED_LOCATIONS:
		return false
	var book := movebook(identity)
	book.equipped = ids.duplicate()
	if not MoveLibrary.valid_book(book):
		return false
	_movebooks[identity] = book
	return true

func affinity_tiles() -> Dictionary:
	return _affinity_tiles.duplicate(true)

func recover_affinity_conditions() -> void:
	# Bounded round-robin service; elapsed active ticks retain recovery debt.
	var keys := _affinity_tiles.keys()
	if keys.is_empty():
		return
	for index in range(mini(32, keys.size())):
		var at: String = keys[(_tick * 32 + index) % keys.size()]
		var row: Dictionary = _affinity_tiles[at]
		for kind in row.conditions.keys():
			var effect: Dictionary = row.conditions[kind]
			var stages := int((_tick - int(effect.since)) / int(effect.interval))
			if stages <= 0:
				continue
			effect.level = maxi(0, int(effect.level) - stages)
			effect.since += stages * int(effect.interval)
			if effect.level == 0:
				row.conditions.erase(kind)

func configure_wild_recovery(interval_ticks: int) -> bool:
	if interval_ticks < 0 or interval_ticks > 1000000:
		return false
	_wild_recovery_delay = interval_ticks
	return true

func wild_population_view() -> Dictionary:
	return _wild_population.duplicate(true)

func home_occupant(home: String) -> String:
	return _wild_homes.get(home, "")

func schedule_historical_recovery(home: String) -> bool:
	if _battle.active or _wild_recovery_delay == 0 or _wild_homes.has(home) or not _known_homes.has(home):
		return false
	if _wild_population.has(home) and not _wild_population[home].active:
		return false
	var latest := ""
	var generation := -1
	for identity in _individuals:
		if home_identity(identity) == home and int(_individuals[identity].generation) > generation:
			generation = int(_individuals[identity].generation)
			latest = identity
	if latest.is_empty():
		return false
	var candidate := WildPopulation.deplete(_wild_population, latest, _tick, _wild_recovery_delay)
	if candidate == _wild_population:
		return false
	_wild_population = candidate
	return true

func activate_wild_home(home: String, species: SolSpeciesDefinition, affinity: String, book: Dictionary, vacant: bool) -> String:
	if _battle.active or not vacant or _wild_homes.has(home) or not _wild_population.has(home) or _individuals.size() >= MAX_INDIVIDUALS or species == null or not species.valid() or not MoveLibrary.valid_book(book):
		return ""
	var row: Dictionary = _wild_population[home]
	var origin := SolIdentityContract.parse(home)
	if row.active or _tick < int(row.ready_at) or origin.is_empty() or species.species_id != origin.species_id:
		return ""
	var cell := Vector2i(int(origin.home[0]), int(origin.home[1]))
	var identity := SolIdentityContract.make(_seed, cell, origin.species_id, int(row.generation))
	if identity.is_empty() or _individuals.has(identity):
		return ""
	var record := species.snapshot()
	record.merge({"id": identity, "home": [cell.x, cell.y], "generation": int(row.generation), "affinity": AffinityImprint.canonical(affinity), "location": "wild"})
	var candidate := snapshot()
	candidate.individuals[identity] = record
	candidate.movebooks[identity] = book.duplicate(true)
	candidate.wild_population[home].active = true
	if not valid_snapshot(candidate, _seed):
		return ""
	_individuals[identity] = record
	_movebooks[identity] = book.duplicate(true)
	_wild_population[home].active = true
	_known_homes[home] = true
	_wild_homes[home] = identity
	individual_changed.emit(identity)
	return identity

func collection_view() -> Dictionary:
	return _collection.duplicate(true)

func active_sol_view() -> Dictionary:
	var id: String = _collection.selected
	return companion_view(id)

func companion_view(id: String) -> Dictionary:
	if not _collection.owned.has(id):
		return {}
	var row: Dictionary = _collection.owned[id]
	return {"id": id, "profile": row.profile.duplicate(true), "hp": int(row.hp), "xp": int(row.xp), "unlocks": row.unlocks.duplicate(true)}

func select_companion(id: String) -> bool:
	if _battle.active or not _collection.owned.has(id) or _individuals[id].location != "party":
		return false
	_collection.selected = id
	battle_progress_changed.emit()
	return true

func transfer_companion(id: String, destination: String) -> bool:
	if _battle.active or not _collection.owned.has(id) or destination not in ["party", "storage"]:
		return false
	var party: Array[String] = []
	for identity in _collection.owned:
		if _individuals[identity].location == "party":
			party.append(identity)
	if destination == "party" and party.size() >= CollectionProgress.PARTY_LIMIT:
		return false
	if destination == "storage" and party.has(id) and party.size() <= 1:
		return false
	if _individuals[id].location == destination:
		return false
	var candidate := snapshot()
	candidate.individuals[id].location = destination
	if destination == "storage" and _collection.selected == id and party.has(id):
		party.erase(id)
		candidate.collection.selected = party[0]
	if not valid_snapshot(candidate, _seed):
		return false
	_individuals = candidate.individuals
	_collection = candidate.collection
	individual_changed.emit(id)
	battle_progress_changed.emit()
	return true

func configure_progression(settings: ProgressionSettings) -> bool:
	if settings == null or not settings.valid():
		return false
	_progression_policy = settings.parameters()
	return true

func configure_learning(id: String, levels: Dictionary) -> bool:
	if _battle.active or not _collection.owned.has(id) or not _collection.owned[id].unlocks.is_empty():
		return false
	var candidate := snapshot()
	candidate.collection.owned[id].unlocks = levels.duplicate(true)
	if not valid_snapshot(candidate, _seed):
		return false
	_collection.owned[id].unlocks = levels.duplicate(true)
	return true

func learn_earned_moves(row: Dictionary, book: Dictionary, definitions: Dictionary) -> void:
	if book.is_empty():
		return
	for id in row.unlocks:
		if int(row.unlocks[id]) > int(row.profile.level) or book.learned.has(id) or not book.pool.has(id) or not definitions.has(id) or not SolMove.valid(definitions[id]) or definitions[id].id != id:
			continue
		book.learned[id] = SolMove.normalized(definitions[id])
		if book.equipped.size() < 4:
			book.equipped.append(id)
