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
signal story_changed(event_id: String, choice_id: String)

const VERSION := 17 # Authored event decisions and explicit story facts.
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
var _story := StoryLedger.empty()
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
var _sol_stats: Dictionary = {}
var _stat_settings: SolStatSettings = preload("res://resources/sol_stat_settings.tres")
var _buff_settings: ClassBuffSettings = preload("res://resources/class_buff_settings.tres")
var _retraining_items := 3
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

func story_view() -> Dictionary:
	return _story.duplicate(true)

func record_story_choice(event: StoryEvent, choice_id: String) -> bool:
	if _battle.active:
		return false
	var candidate := StoryLedger.select(_story, event, choice_id, _tick)
	if candidate.is_empty():
		return false
	_story = candidate
	story_changed.emit(event.id, choice_id)
	return true

func activity_seconds() -> float:
	return float(_tick) * ACTIVITY_INTERVAL + _remainder

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

func individual_ids() -> Array:
	return _individuals.keys() # Isolated membership without copying the full expedition.

func wild_available(identity: String) -> bool:
	return _individuals.get(identity, {}).get("location") == "wild" and not _battle.defeated.has(identity)

func battle_progress() -> Dictionary:
	return _battle.duplicate(true)

func starter_view() -> Dictionary:
	return {} if _battle.starter_id.is_empty() else {"id": _battle.starter_id, "profile": _battle.profile.duplicate(true), "hp": _battle.hp}

func choose_starter(profile: Dictionary, index: int, forms: int = 3) -> bool:
	if _battle.active or not _stat_settings.valid() or not _buff_settings.valid() or not _battle.starter_id.is_empty() or index < 0 or index > 2 or not BattleProfile.valid_snapshot(profile):
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
	candidate.sol_stats[identity] = new_stat_record(identity, record.class_id)
	candidate.sol_stats[identity].base = BattleProfile.normalized(profile)
	candidate.sol_stats[identity].base.affinity = record.affinity
	candidate.sol_stats[identity].forms = forms
	var resolved := SolStats.resolve(candidate.sol_stats[identity], int(profile.level))
	candidate.battle.starter_id = identity
	candidate.battle.profile = resolved
	candidate.battle.profile.affinity = AffinityImprint.canonical(profile.affinity)
	candidate.battle.hp = int(resolved.max_hp)
	candidate.collection.selected = identity
	candidate.collection.owned[identity] = CollectionProgress.entry(candidate.battle.profile, int(resolved.max_hp))
	if not valid_snapshot(candidate, _seed):
		return false
	_individuals[identity] = record
	_known_homes[home_identity(identity)] = true
	_battle = candidate.battle
	_collection = candidate.collection
	_sol_stats = candidate.sol_stats
	battle_progress_changed.emit()
	return true

func begin_battle(enemy_id: String) -> int:
	var hero := active_sol_view()
	if _affinity_tiles.size() > MAX_TILE_DELTAS - 169 or _tile_deltas.size() > MAX_TILE_DELTAS - VastraCombat.MAX_BATTLE_CELLS or _battle.active or hero.is_empty() or hero.hp <= 0 or not wild_available(enemy_id) or _battle.serial >= MAX_SAFE_INTEGER:
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
			var grown: Dictionary = candidate.collection.owned[hero.id]
			grown.profile = SolStats.resolve(candidate.sol_stats[hero.id], int(grown.profile.level))
			grown.hp = mini(int(grown.profile.max_hp), hp + maxi(0, int(grown.profile.max_hp) - int(hero.profile.max_hp)))
			if details.get("contributed", false) == true:
				var traits: Dictionary = candidate.sol_stats[hero.id]
				var difference := int(level) - int(hero.profile.level)
				if difference > -int(traits.policy.weak_level_gap):
					var training_reward := maxi(1, int(traits.policy.training_reward) + difference)
					traits.earned = mini(int(SolStats.capacity(traits, int(candidate.individuals[hero.id].ordinary_form)).total), int(traits.earned) + training_reward)
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
		if candidate.sol_stats[_battle_enemy].base.is_empty():
			candidate.sol_stats[_battle_enemy].base = BattleProfile.normalized(capture.profile)
			candidate.sol_stats[_battle_enemy].base.affinity = candidate.individuals[_battle_enemy].affinity
		var captured_profile := SolStats.resolve(candidate.sol_stats[_battle_enemy], int(capture.profile.level))
		candidate.collection.owned[_battle_enemy] = CollectionProgress.entry(captured_profile, mini(int(capture.hp), int(captured_profile.max_hp)))
		candidate.collection.owned[_battle_enemy].unlocks = capture.unlocks.duplicate(true)
	if hero.id == candidate.battle.starter_id:
		candidate.battle.profile = candidate.collection.owned[hero.id].profile.duplicate(true)
		candidate.battle.hp = candidate.collection.owned[hero.id].hp
	var tiles: Variant = AffinityImprint.apply(_affinity_tiles, imprint, _tick, MAX_TILE_DELTAS)
	if tiles == null:
		return false
	candidate.affinity_tiles = tiles
	var vastra_changes: Variant = details.get("vastra_overloads", {})
	if not VastraCombat.apply(candidate, vastra_changes, _tick):
		return false
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
	_sol_stats = candidate.sol_stats
	_individuals = candidate.individuals
	_movebooks = candidate.movebooks
	_affinity_tiles = candidate.affinity_tiles
	_tile_deltas = candidate.tile_deltas
	_natural = candidate.natural
	_wild_population = candidate.wild_population
	_roaming = candidate.roaming
	_battle_enemy = ""
	if outcome in ["victory", "captured"]:
		_wild_homes.erase(home_identity(enemy))
	for key: String in vastra_changes:
		var parts := key.split(":")
		environment_changed.emit(Vector2i(int(parts[0]), int(parts[1])))
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

func admit_traversal(identity: String, policy: Dictionary) -> bool:
	var row := roaming_view(identity)
	if row.is_empty() or not SolTraversalProfile.valid_policy(policy) or policy.kind == "ground":
		return false
	if row.has("traversal"):
		return true # Admitted capability is not re-authored on load or view reconstruction.
	row.tick = maxi(0, int(row.tick))
	row.traversal = {"policy": policy.duplicate(true), "mode": "ground", "mode_tick": _tick, "from": row.cell.duplicate(), "settle": false}
	if not valid_roaming(row, _individuals[identity], _tick):
		return false
	_roaming[identity] = row
	individual_changed.emit(identity)
	return true

func request_ground(identity: String) -> bool:
	var row := roaming_view(identity)
	if row.is_empty() or not row.has("traversal"):
		return false
	row.traversal.settle = true
	_roaming[identity] = row
	individual_changed.emit(identity)
	return true

func record_roaming_step(identity: String, target: Vector2i, action: String, patrol: Dictionary = {}, response: Dictionary = {}, traversal: Dictionary = {}) -> bool:
	var previous := roaming_view(identity)
	if previous.is_empty() or int(previous.tick) >= _tick:
		return false
	var from := Vector2i(int(previous.cell[0]), int(previous.cell[1]))
	var change := target - from
	if absi(change.x) + absi(change.y) > 1:
		return false
	var candidate := {"cell": [target.x, target.y], "action": action, "tick": _tick}
	var travel: Dictionary = traversal if not traversal.is_empty() else previous.get("traversal", {})
	if not travel.is_empty():
		candidate.traversal = travel.duplicate(true)
	if not patrol.is_empty():
		candidate.patrol = patrol.duplicate(true)
	if not response.is_empty():
		candidate.response = response.duplicate(true)
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
	if _battle.active or species == null or not species.valid() or not SolSpeciesDefinition.text(affinity) or _individuals.size() >= MAX_INDIVIDUALS or not _stat_settings.valid() or not _buff_settings.valid():
		return ""
	var identity := SolIdentityContract.make(_seed, home, species.species_id, generation)
	var base := SolIdentityContract.make(_seed, home, species.species_id)
	if identity.is_empty() or _individuals.has(identity) or _wild_homes.has(base):
		return ""
	var definition := species.snapshot()
	# Validate only the new row and taxonomy relationships. Revalidating every
	# saved trait on every admission needlessly copies and rechecks immutable rows.
	for existing in _individuals.values():
		if existing.lineage_id == species.lineage_id and existing.class_id != species.class_id:
			return ""
		if existing.species_id == species.species_id:
			for key in ["lineage_id", "class_id", "ordinary_form", "footprint"]:
				if existing[key] != definition[key]:
					return ""
	var record := definition
	record.merge({"id": identity, "home": [home.x, home.y], "generation": generation, "affinity": AffinityImprint.canonical(affinity), "location": "wild"})
	var traits := new_stat_record(identity, record.class_id)
	if not SolStats.valid(traits, record):
		return ""
	_individuals[identity] = record
	_sol_stats[identity] = traits
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
	var previous_overload := int(combined.get("overload", 0))
	for field in changes:
		combined[field] = int(changes[field])
	if _tile_deltas.get(key) == combined:
		return false
	if not _tile_deltas.has(key):
		_natural.order.append(key)
	_tile_deltas[key] = combined
	if combined.get("overload", 0) == 0 or signi(int(combined.get("overload", 0))) != signi(previous_overload):
		_natural.recovery_ticks.erase(key)
	environment_changed.emit(cell)
	return true

func environment_view(cell: Vector2i, generated: Dictionary) -> Dictionary:
	var result := generated.duplicate(true)
	result.merge(_tile_deltas.get("%d:%d" % [cell.x, cell.y], {}), true)
	result.merge(_affinity_tiles.get(AffinityImprint.key(cell), {}).duplicate(true), true)
	return result

func vastra_changes_near(center: Vector2i, radius: int) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var extent := clampi(radius, 0, 24)
	# Sparse expeditions should not probe every empty coordinate in the local square.
	if _tile_deltas.size() <= extent * extent:
		for key: String in _tile_deltas:
			if _tile_deltas[key].get("overload", 0) == 0:
				continue
			var parts := key.split(":")
			var cell := Vector2i(int(parts[0]), int(parts[1]))
			if cell.distance_squared_to(center) <= extent * extent:
				result.append(cell)
		# Preserve the spatial query's row order, including equal-distance visual ties.
		result.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.y < b.y if a.y != b.y else a.x < b.x)
		return result
	for y in range(-extent, extent + 1):
		for x in range(-extent, extent + 1):
			if x * x + y * y > extent * extent:
				continue
			var cell := center + Vector2i(x, y)
			if _tile_deltas.get(AffinityImprint.key(cell), {}).get("overload", 0) != 0:
				result.append(cell)
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
	if prepared.effect.overload != 0 and (not candidate.natural.recovery_ticks.has(key) or signi(int(_tile_deltas.get(key, {}).get("overload", 0))) != signi(int(prepared.effect.overload))):
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

func advance_environment(policy: Dictionary, profile_resolver: Callable = Callable(), tuning: VastraSettings = null) -> int:
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
	# Same-tick save/reload cannot repeat assistance: the saved natural last_tick gates it.
	if tuning != null and tuning.valid() and _tick % 8 == 0:
		var homes := _wild_population.keys()
		for index in range(mini(32, homes.size())):
			var home: String = homes[(int(_tick / 8) * 32 + index) % homes.size()]
			var row: Dictionary = _wild_population[home]
			if row.active or int(row.ready_at) <= _tick:
				continue
			var origin := SolIdentityContract.parse(home)
			var key := "%d:%d" % [int(origin.home[0]), int(origin.home[1])]
			var overload := int(_tile_deltas.get(key, {}).get("overload", 0))
			var bonus_ticks := floori(8.0 * VastraCombat.restoration_factor(overload, tuning))
			row.ready_at = maxi(_tick, int(row.ready_at) - bonus_ticks)
	for key: String in prepared.changes:
		var parts := key.split(":")
		environment_changed.emit(Vector2i(int(parts[0]), int(parts[1])))
	return int(prepared.processed)

func snapshot() -> Dictionary:
	return {"version": VERSION, "story": _story.duplicate(true), "activity_tick": _tick, "remainder_seconds": _remainder,
		"territory_size": _territory_size, "territories": _territories.duplicate(true),
		"individuals": _individuals.duplicate(true), "tile_deltas": _tile_deltas.duplicate(true),
		"human_activity": _human_activity.duplicate(true), "natural": _natural.duplicate(true),
		"discoveries": _discoveries.duplicate(true), "roaming": _roaming.duplicate(true), "battle": _battle.duplicate(true), "movebooks": _movebooks.duplicate(true), "affinity_tiles": _affinity_tiles.duplicate(true), "wild_population": _wild_population.duplicate(true), "collection": _collection.duplicate(true), "sol_stats": _sol_stats.duplicate(true), "retraining_items": _retraining_items}

static func restore(data: Variant, seed_value: int) -> ExpeditionState:
	if not valid_snapshot(data, seed_value):
		return null
	var state := ExpeditionState.new(seed_value, int(data.territory_size))
	state._tick = int(data.activity_tick)
	if int(data.version) >= 17:
		state._story = data.story.duplicate(true)
		for row in state._story.decisions.values():
			row.tick = int(row.tick)
	state._remainder = float(data.remainder_seconds)
	state._territories = data.territories.duplicate(true)
	state._individuals = data.individuals.duplicate(true)
	state._tile_deltas = data.tile_deltas.duplicate(true)
	if int(data.version) >= 10:
		state._sol_stats = data.sol_stats.duplicate(true)
		for id in state._sol_stats:
			state._sol_stats[id] = SolStats.normalized(state._sol_stats[id])
		state._retraining_items = int(data.retraining_items)
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
			if row.has("traversal"):
				row.traversal.mode_tick = int(row.traversal.mode_tick)
				row.traversal.from = [int(row.traversal.from[0]), int(row.traversal.from[1])]
			if row.has("response"):
				row.response.until = int(row.response.until)
				row.response.move_after = int(row.response.move_after)
				if row.response.has("attention_until"):
					row.response.attention_until = int(row.response.attention_until)
				if row.response.has("routine_until"):
					row.response.routine_until = int(row.response.routine_until)
			if row.has("patrol"):
				row.patrol.goal = [int(row.patrol.goal[0]), int(row.patrol.goal[1])]
				for field in ["leg", "expires", "rest_until"]:
					row.patrol[field] = int(row.patrol[field])
				if row.patrol.has("blocked_since"):
					row.patrol.blocked_since = int(row.patrol.blocked_since)
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
	if int(data.version) < 10:
		# One-time deterministic migration, never a roll during rendering or battle construction.
		for id in state._individuals:
			state._sol_stats[id] = state.new_stat_record(id, state._individuals[id].class_id)
			state._sol_stats[id].forms = maxi(3, int(state._individuals[id].ordinary_form))
			if state._collection.owned.has(id):
				var row: Dictionary = state._collection.owned[id]
				state._sol_stats[id].base = BattleProfile.normalized(row.profile)
				row.profile = SolStats.resolve(state._sol_stats[id], int(row.profile.level))
				row.hp = mini(int(row.hp), int(row.profile.max_hp))
		state.sync_starter()
	if not valid_snapshot(state.snapshot(), seed_value):
		return null
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
		if key not in ["concentration", "overload"] or not SolSpeciesDefinition.whole(data[key], VastraCombat.MIN_OVERLOAD if key == "overload" else 0, 100):
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

static func valid_roaming(row: Variant, individual: Dictionary, tick: int, allow_patrol: bool = true, allow_response: bool = true, max_patrol_leg: int = 2147483646, allow_activity: bool = true, allow_traversal: bool = true) -> bool:
	if not row is Dictionary:
		return false
	var fields := ["cell", "action", "tick"]
	if row.has("traversal"):
		if not allow_traversal or not row.get("cell") is Array or row.cell.size() != 2 or not SolTraversalProfile.valid_state(row.traversal, tick, row.cell):
			return false
		fields.append("traversal")
	if allow_response and row.has("response"):
		fields.append("response")
		if not valid_response(row.response, tick, allow_activity):
			return false
	if allow_patrol and row.has("patrol"):
		fields.append("patrol")
		if not valid_patrol(row.patrol, individual, tick, max_patrol_leg, allow_activity):
			return false
	if not keys_match(row, fields) or individual.get("location") != "wild":
		return false
	if row.action not in ["idle", "flee", "approach", "guard", "return", "patrol"] or (row.action == "patrol" and (not allow_patrol or not row.has("patrol"))) or not SolSpeciesDefinition.whole(row.tick, 0, tick) or not row.cell is Array or row.cell.size() != 2:
		return false
	if not SolSpeciesDefinition.whole(row.cell[0], -1000000, 1000000) or not SolSpeciesDefinition.whole(row.cell[1], -1000000, 1000000):
		return false
	return absi(int(row.cell[0]) - int(individual.home[0])) + absi(int(row.cell[1]) - int(individual.home[1])) <= MAX_ROAMING_DISTANCE

static func valid_response(memory: Variant, tick: int, allow_activity: bool = true) -> bool:
	if not memory is Dictionary:
		return false
	var fields := ["mode", "until", "move_after"]
	for field in ["attention_until", "routine_until"]:
		if allow_activity and memory.has(field):
			fields.append(field)
			if not SolSpeciesDefinition.whole(memory[field], 0, mini(tick + 128, MAX_SAFE_INTEGER)):
				return false
	if not keys_match(memory, fields) or memory.mode not in ["alert", "settling"]:
		return false
	for field in ["until", "move_after"]:
		if not SolSpeciesDefinition.whole(memory[field], 0, mini(tick + 128, MAX_SAFE_INTEGER)):
			return false
	return (memory.mode == "alert" and int(memory.until) == 0) or (memory.mode == "settling" and int(memory.move_after) == 0)

static func valid_patrol(memory: Variant, individual: Dictionary, tick: int, max_leg: int = 2147483646, allow_activity: bool = true) -> bool:
	if not memory is Dictionary:
		return false
	var fields := ["goal", "leg", "expires", "rest_until"]
	if allow_activity and memory.has("blocked_since"):
		fields.append("blocked_since")
		if not SolSpeciesDefinition.whole(memory.blocked_since, 0, tick):
			return false
	if not keys_match(memory, fields):
		return false
	if not memory.goal is Array or memory.goal.size() != 2 or not SolSpeciesDefinition.whole(memory.leg, 0, max_leg):
		return false
	for coordinate in memory.goal:
		if not SolSpeciesDefinition.whole(coordinate, -1000000, 1000000):
			return false
	# Safety envelope exceeds every authored deadline without becoming a balance slider.
	if not SolSpeciesDefinition.whole(memory.expires, 0, mini(tick + 128, MAX_SAFE_INTEGER)) or not SolSpeciesDefinition.whole(memory.rest_until, 0, mini(tick + 128, MAX_SAFE_INTEGER)):
		return false
	return absi(int(memory.goal[0]) - int(individual.home[0])) + absi(int(memory.goal[1]) - int(individual.home[1])) <= MAX_ROAMING_DISTANCE

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
	if int(data.version) >= 10:
		expected_fields.append_array(["sol_stats", "retraining_items"])
	if int(data.version) >= 17:
		expected_fields.append("story")
	if not keys_match(data, expected_fields):
		return false
	if not SolSpeciesDefinition.whole(seed_value, 0, 2147483646) or not SolSpeciesDefinition.whole(data.activity_tick, 0, MAX_SAFE_INTEGER) or not SolSpeciesDefinition.whole(data.territory_size, 1, 256):
		return false
	if int(data.version) >= 17 and not StoryLedger.valid(data.story, int(data.activity_tick)):
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
			if not valid_delta(value) or (int(data.version) < 16 and value.get("overload", 0) < 0):
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
		if int(data.version) >= 10 and record.has("birth_species_id"):
			expected.append("birth_species_id")
		if not keys_match(record, expected) or record.id != identity or not SolSpeciesDefinition.valid_record(record) or not SolSpeciesDefinition.text(record.affinity) or not record.location in ["wild", "sealed", "party", "storage"]:
			return false
		if not record.home is Array or record.home.size() != 2 or not SolSpeciesDefinition.whole(record.home[0], -1000000, 1000000) or not SolSpeciesDefinition.whole(record.home[1], -1000000, 1000000) or not SolSpeciesDefinition.whole(record.generation, 0, 2147483647):
			return false
		if int(record.home[0]) != origin.home[0] or int(record.home[1]) != origin.home[1] or int(record.generation) != origin.generation or record.get("birth_species_id", record.species_id) != origin.species_id:
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
	if int(data.version) >= 10:
		if not data.sol_stats is Dictionary or data.sol_stats.size() != data.individuals.size() or not SolSpeciesDefinition.whole(data.retraining_items, 0, 9999):
			return false
		for id in data.sol_stats:
			if not data.individuals.has(id) or not SolStats.valid(data.sol_stats[id], data.individuals[id]):
				return false
			if data.individuals[id].location == "wild" and (data.sol_stats[id].earned != 0 or SolStats.spent(data.sol_stats[id]) != 0):
				return false
		if data.collection is Dictionary and data.collection.get("owned") is Dictionary:
			for id in data.collection.owned:
				var owned_row: Variant = data.collection.owned[id]
				if not data.sol_stats.has(id) or not owned_row is Dictionary or not owned_row.get("profile") is Dictionary or not BattleProfile.valid_snapshot(owned_row.profile) or SolStats.resolve(data.sol_stats[id], int(owned_row.profile.level)) != BattleProfile.normalized(owned_row.profile):
					return false
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
			if not identity is String or not data.individuals.has(identity) or not valid_roaming(data.roaming[identity], data.individuals[identity], int(data.activity_tick), int(data.version) >= 11, int(data.version) >= 12, 2147483646 if int(data.version) >= 13 else 3, int(data.version) >= 14, int(data.version) >= 15):
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

## Presentation snapshot: copy only nearby affinity strings, never mutable tile records.
func affinity_colors_near(center: Vector2i, radius: int) -> Dictionary:
	var result := {}
	var extent := clampi(radius, 0, 32)
	var squared := extent * extent
	if _affinity_tiles.size() < (extent * 2 + 1) * (extent * 2 + 1):
		for key: String in _affinity_tiles:
			var parts := key.split(":")
			var cell := Vector2i(int(parts[0]), int(parts[1]))
			if (cell - center).length_squared() <= squared:
				result[cell] = str(_affinity_tiles[key].affinity)
	else:
		for y in range(-extent, extent + 1):
			for x in range(-extent, extent + 1):
				if x * x + y * y > squared:
					continue
				var cell := center + Vector2i(x, y)
				var key := AffinityImprint.key(cell)
				if _affinity_tiles.has(key):
					result[cell] = str(_affinity_tiles[key].affinity)
	return result

func recover_affinity_conditions(tuning: VastraSettings = null) -> void:
	# Bounded round-robin service; elapsed active ticks retain recovery debt.
	var keys := _affinity_tiles.keys()
	if keys.is_empty():
		return
	for index in range(mini(32, keys.size())):
		var at: String = keys[(_tick * 32 + index) % keys.size()]
		var row: Dictionary = _affinity_tiles[at]
		for kind in row.conditions.keys():
			var effect: Dictionary = row.conditions[kind]
			var interval := int(effect.interval)
			if tuning != null and tuning.valid():
				var overload := int(_tile_deltas.get(at, {}).get("overload", 0))
				interval = maxi(1, ceili(float(interval) / (1.0 + VastraCombat.restoration_factor(overload, tuning))))
			var stages := int((_tick - int(effect.since)) / interval)
			if stages <= 0:
				continue
			effect.level = maxi(0, int(effect.level) - stages)
			effect.since += stages * interval
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
	candidate.sol_stats[identity] = new_stat_record(identity, record.class_id)
	candidate.movebooks[identity] = book.duplicate(true)
	candidate.wild_population[home].active = true
	if not valid_snapshot(candidate, _seed):
		return ""
	_individuals[identity] = record
	_sol_stats[identity] = candidate.sol_stats[identity]
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


func new_stat_record(id: String, class_id: String) -> Dictionary:
	var row := SolStats.generate(id, class_id, _stat_settings, _buff_settings)
	row.hp_growth = int(_progression_policy.hp_growth)
	row.stat_growth = int(_progression_policy.stat_growth)
	return row

func configure_sol_stats(settings: SolStatSettings, buffs: ClassBuffSettings) -> bool:
	if _battle.active or settings == null or not settings.valid() or buffs == null or not buffs.valid():
		return false
	_stat_settings = settings
	_buff_settings = buffs
	if _individuals.is_empty():
		_retraining_items = settings.retraining_items
	return true

func stat_view(id: String) -> Dictionary:
	return _sol_stats.get(id, {}).duplicate(true)

func retraining_items() -> int:
	return _retraining_items

func admit_stat_profile(id: String, profile: Dictionary, forms: int = 3) -> bool:
	if _battle.active or not _sol_stats.has(id) or not _sol_stats[id].base.is_empty() or not BattleProfile.valid_snapshot(profile) or forms < int(_individuals[id].ordinary_form) or forms > 3:
		return false
	var candidate: Dictionary = _sol_stats[id].duplicate(true)
	candidate.base = BattleProfile.normalized(profile)
	candidate.base.affinity = _individuals[id].affinity
	candidate.forms = forms
	if not SolStats.valid(candidate, _individuals[id]):
		return false
	_sol_stats[id] = candidate
	return true

func wild_profile(id: String) -> Dictionary:
	if not wild_available(id) or not _sol_stats.has(id) or _sol_stats[id].base.is_empty():
		return {}
	return SolStats.resolve(_sol_stats[id], int(_sol_stats[id].base.level))

func sync_starter() -> void:
	if not _battle.starter_id.is_empty() and _collection.owned.has(_battle.starter_id):
		_battle.profile = _collection.owned[_battle.starter_id].profile.duplicate(true)
		_battle.hp = int(_collection.owned[_battle.starter_id].hp)

func allocate_training(id: String, stat: String, points: int) -> bool:
	if _battle.active or not _collection.owned.has(id) or stat not in SolStats.STATS or points <= 0 or points > 1000:
		return false
	var traits := stat_view(id)
	var caps := SolStats.capacity(traits, int(_individuals[id].ordinary_form))
	if int(traits.training[stat]) + points > int(caps.stat) or SolStats.spent(traits) + points > int(traits.earned):
		return false
	traits.training[stat] += points
	return install_training(id, traits)

func reset_training(id: String) -> bool:
	if _battle.active or not _collection.owned.has(id) or _retraining_items <= 0 or SolStats.spent(_sol_stats[id]) == 0:
		return false
	var traits := stat_view(id)
	for stat in SolStats.STATS:
		traits.training[stat] = 0
	_retraining_items -= 1
	if not install_training(id, traits):
		_retraining_items += 1
		return false
	return true

func install_training(id: String, traits: Dictionary) -> bool:
	if not SolStats.valid(traits, _individuals[id]):
		return false
	var row: Dictionary = _collection.owned[id]
	var resolved := SolStats.resolve(traits, int(row.profile.level))
	# Reallocation never heals: preserve absolute HP, clamped to a reduced maximum.
	_sol_stats[id] = traits
	row.profile = resolved
	row.hp = mini(int(row.hp), int(resolved.max_hp))
	sync_starter()
	battle_progress_changed.emit()
	individual_changed.emit(id)
	return true

func evolve_companion(id: String, species: SolSpeciesDefinition, profile: Dictionary, book: Dictionary) -> bool:
	# Explicit authored transition only. No automatic level/species/evolution rules are invented.
	if _battle.active or not _collection.owned.has(id) or species == null or not species.valid() or not BattleProfile.valid_snapshot(profile) or not MoveLibrary.valid_book(book):
		return false
	var current: Dictionary = _individuals[id]
	if species.lineage_id != current.lineage_id or species.class_id != current.class_id or species.ordinary_form != int(current.ordinary_form) + 1 or species.ordinary_form > int(_sol_stats[id].forms) or profile.species_id != species.species_id or profile.class_id != current.class_id or profile.lineage_id != current.lineage_id:
		return false
	var candidate := snapshot()
	var record: Dictionary = candidate.individuals[id]
	record.birth_species_id = record.get("birth_species_id", record.species_id)
	record.species_id = species.species_id
	record.ordinary_form = species.ordinary_form
	record.footprint = species.footprint
	candidate.sol_stats[id].base = BattleProfile.normalized(profile)
	candidate.sol_stats[id].base.affinity = current.affinity
	var row: Dictionary = candidate.collection.owned[id]
	row.profile = SolStats.resolve(candidate.sol_stats[id], int(row.profile.level))
	row.hp = mini(int(row.hp), int(row.profile.max_hp))
	var evolved_book := book.duplicate(true)
	var previous_book := movebook(id)
	for move_id in previous_book.get("learned", {}):
		if not evolved_book.pool.has(move_id):
			evolved_book.pool.append(move_id)
		evolved_book.learned[move_id] = previous_book.learned[move_id].duplicate(true)
	if not previous_book.is_empty():
		evolved_book.equipped = previous_book.equipped.duplicate()
	if not MoveLibrary.valid_book(evolved_book):
		return false
	candidate.movebooks[id] = evolved_book
	row.unlocks = {}
	if id == candidate.battle.starter_id:
		candidate.battle.profile = row.profile.duplicate(true)
		candidate.battle.hp = row.hp
	if not valid_snapshot(candidate, _seed):
		return false
	_individuals = candidate.individuals
	_sol_stats = candidate.sol_stats
	_collection = candidate.collection
	_movebooks = candidate.movebooks
	_battle = candidate.battle
	individual_changed.emit(id)
	battle_progress_changed.emit()
	return true
