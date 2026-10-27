class_name MoveLibrary
extends Resource
## Explicit species eligibility and starter learnsets. Numeric defaults are prototype tuning.
@export var moves: Array[SolMove] = []
## Species ID to learnable move IDs, independent of individual affinity.
@export var species_pools: Dictionary[String, PackedStringArray] = {}
## Initial remembered moves, a subset of the species pool. First four are equipped.
@export var starting_moves: Dictionary[String, PackedStringArray] = {}
## Active exploration ticks per condition recovery stage (0.75 seconds per tick).
@export_range(1, 1000) var recovery_interval := 8
## Shared Fire/Lightning condition damage per tactical round, in HP. No affinity immunity is inferred.
@export_range(0, 10) var field_damage := 2
## Extra rough-ground movement uses this many points per cardinal cell.
@export_range(1, 4) var rough_cost := 2
## Favorable current/wind and vertical warp entry movement cost. Zero allows free favorable steps.
@export_range(0, 1) var assisted_cost := 0
## Opposing current/wind and horizontal warp entry movement cost.
@export_range(1, 4) var resisted_cost := 2
@export_group("World Condition Timing")
## Exploration seconds multiplier on rough ground, applied to the root Move Seconds.
@export_range(0.25, 4.0, 0.05) var world_rough_multiplier := 1.5
## Exploration seconds multipliers with and against a current/wind.
@export_range(0.25, 4.0, 0.05) var world_flow_assisted := 0.75
@export_range(0.25, 4.0, 0.05) var world_flow_resisted := 1.5
## Exploration seconds multipliers for vertical and horizontal warp entry.
@export_range(0.25, 4.0, 0.05) var world_warp_short := 0.5
@export_range(0.25, 4.0, 0.05) var world_warp_long := 2.0

func find(id: String) -> Dictionary:
	for move in moves:
		if move.move_id == id:
			return move.snapshot()
	return {}

func valid() -> bool:
	if moves.is_empty() or moves.size() > 128 or species_pools.size() > 64 or not SolSpeciesDefinition.whole(recovery_interval, 1, 1000) or not SolSpeciesDefinition.whole(field_damage, 0, 10) or not SolSpeciesDefinition.whole(rough_cost, 1, 4) or not SolSpeciesDefinition.whole(assisted_cost, 0, 1) or not SolSpeciesDefinition.whole(resisted_cost, 1, 4):
		return false
	var ids := {}
	for value in [world_rough_multiplier, world_flow_assisted, world_flow_resisted, world_warp_short, world_warp_long]:
		if not is_finite(value) or value < 0.25 or value > 4:
			return false
	for move in moves:
		if move == null or not SolMove.valid(move.snapshot()) or ids.has(move.move_id):
			return false
		ids[move.move_id] = true
	for species in species_pools:
		var pool: PackedStringArray = species_pools[species]
		var initial: PackedStringArray = starting_moves.get(species, PackedStringArray())
		if pool.is_empty() or pool.size() > 32 or initial.is_empty() or initial.size() > 32:
			return false
		var seen := {}
		for id in pool:
			if not ids.has(id) or seen.has(id):
				return false
			seen[id] = true
		seen.clear()
		for id in initial:
			if not pool.has(id) or seen.has(id):
				return false
			seen[id] = true
	return true

func book(species: String) -> Dictionary:
	if not valid() or not species_pools.has(species):
		return {}
	var learned := {}
	var equipped: Array = []
	for id in starting_moves[species]:
		learned[id] = find(id)
		if equipped.size() < 4:
			equipped.append(id)
	return {"pool": Array(species_pools[species]), "learned": learned, "equipped": equipped}

static func valid_book(book: Variant) -> bool:
	if not book is Dictionary or not ExpeditionState.keys_match(book, ["pool", "learned", "equipped"]) or not book.pool is Array or book.pool.is_empty() or book.pool.size() > 32 or not book.learned is Dictionary or book.learned.is_empty() or book.learned.size() > 32 or not book.equipped is Array or book.equipped.is_empty() or book.equipped.size() > 4:
		return false
	var seen := {}
	for id in book.pool:
		if not SolSpeciesDefinition.text(id, 80) or seen.has(id):
			return false
		seen[id] = true
	for id in book.learned:
		if not book.pool.has(id) or not SolMove.valid(book.learned[id]) or book.learned[id].id != id:
			return false
	seen.clear()
	for id in book.equipped:
		if not id is String or not book.learned.has(id) or seen.has(id):
			return false
		seen[id] = true
	return true
