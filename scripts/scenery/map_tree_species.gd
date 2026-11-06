extends Resource
## A visual tree species for the map-first world.

const Plan := preload("res://scripts/world/world_map_plan.gd")

@export var species_id: StringName
@export var model: AuthoredPlantDefinition
## This species can spawn on suitable sites in any of these biomes.
@export var biomes: Array[Plan.Biome] = [
	Plan.Biome.PLAINS, Plan.Biome.WOODLAND, Plan.Biome.HEATH, Plan.Biome.MARSH,
	Plan.Biome.COAST, Plan.Biome.DESERT, Plan.Biome.JUNGLE, Plan.Biome.SAVANNA,
	Plan.Biome.ALPINE, Plan.Biome.TUNDRA, Plan.Biome.TAIGA,
]
## Relative frequency among the species that can spawn in the same biome.
@export_range(0.0, 4.0, 0.05) var spawn_weight := 1.0
## Maximum canopy width before site variation and the shared Plant Scale.
@export_range(0.5, 12.0, 0.1) var canopy_width := 5.2
