class_name SolCatalogSighting
extends Resource
## Explicit scenario placement. Affinity belongs to this individual, not the species.

## Stable species ID in the shared catalog.
@export var species_id := ""
## Existing trail coordinate; terrain admission still requires a legal dry home. No terrain is rewritten.
@export_range(-1000000, 1000000) var trail_x := 12
## Trail home, or a deterministic legal dry bank near that trail anchor.
@export_enum("trail", "bank") var placement := "trail"
## Maximum Manhattan search distance for a generated pond bank; bank placements only.
@export_range(1, 128) var bank_radius := 128
## Authored individual affinity; world generation and species classification do not change it.
@export_enum("fire", "water", "earth", "air", "lightning", "void", "spectral", "quantum") var affinity := "earth"

func valid(catalog: SolSpeciesCatalog) -> bool:
	return catalog != null and catalog.find(species_id) != null and SolSpeciesDefinition.whole(trail_x, -1000000, 1000000) and affinity in AffinityImprint.IDS and placement in ["trail", "bank"] and SolSpeciesDefinition.whole(bank_radius, 1, 128) and (placement != "bank" or catalog.find(species_id).traversal.kind == "swim")

func entry(catalog: SolSpeciesCatalog) -> Dictionary:
	if not valid(catalog):
		return {}
	var species := catalog.find(species_id)
	var reaction := "Observing"
	for action in species.ecology.behaviors:
		if action in ["flee", "approach", "guard"]:
			reaction = {"flee": "Wary", "approach": "Watching", "guard": "Guarding"}[action]
	var result := {"x": trail_x, "species": species_id, "name": species.display_name,
		"lineage": species.lineage_id, "class": species.class_id, "affinity": affinity, "reaction": reaction}
	if placement == "bank":
		result.bank_radius = bank_radius
		result.bank_step = species.traversal.shore_step
	return result
