class_name ExpeditionSettings
extends Resource
## Inspector tuning. Territory size applies to new expeditions; saves retain their own.

@export_group("Exploration")
## Seed used at startup. The New Seed action still advances deterministically from the current seed.
@export_range(0, 2147483646) var initial_seed := 2601026
## Seconds per cardinal tile; diagonal travel takes sqrt(2) times this duration. Lower is faster.
@export_range(0.04, 1.0, 0.005) var move_seconds := 0.135

@export_group("Territories")
## Home-territory width in cells for NEW expeditions, independent of rendering chunks. Loaded saves retain their size.
@export_range(1, 256) var territory_size := 16
## Runtime summary-cache capacity. Applied on startup, new expedition, and load; changing it does not delete individuals.
@export_range(1, 1024) var population_cache_territories := 256

func parameters() -> Dictionary:
	return {"initial_seed": initial_seed, "move_seconds": move_seconds,
		"territory_size": territory_size, "population_cache_territories": population_cache_territories}

func valid() -> bool:
	return SolSpeciesDefinition.whole(initial_seed, 0, 2147483646) and is_finite(move_seconds) and move_seconds >= 0.04 and move_seconds <= 1.0 and SolSpeciesDefinition.whole(territory_size, 1, 256) and SolSpeciesDefinition.whole(population_cache_territories, 1, 1024)
