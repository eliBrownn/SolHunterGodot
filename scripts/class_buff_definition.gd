class_name ClassBuffDefinition
extends Resource
## Individual potency is rolled once, inclusively, and saved. Percent unless the passive uses turns/tiles.
@export var class_id := "beast"
@export_multiline var description := ""
@export var display_name := "Terrain Resonance"
@export_range(0, 100) var minimum := 5
@export_range(0, 100) var maximum := 10

func valid() -> bool:
	return SolSpeciesDefinition.text(class_id, 80) and SolSpeciesDefinition.text(display_name, 80) and minimum >= 0 and minimum <= maximum and maximum <= 100
