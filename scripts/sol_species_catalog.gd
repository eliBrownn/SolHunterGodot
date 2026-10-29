class_name SolSpeciesCatalog
extends Resource
## Authoring lookup, not saved individual state or world generation.

const MAX_SPECIES := 512 # Finite content-admission ceiling, allowing the 151-entry target and development content.
const CLASS_NAMES := {"beast": "Beast", "cinderkin": "CinderKin", "tideborn": "Abyssal",
	"verdant": "Bloom", "stormforged": "Stormforged", "frostbound": "Frostbound",
	"warborn": "Warborn", "blightborn": "Blight", "earthbound": "Earthbound", "skyborne": "Zephyr",
	"mindweaver": "Mindweaver", "swarmkin": "Chitin", "wraithborn": "Wraith", "wyrmkin": "Wyrmkin",
	"umbral": "Umbral", "construct": "Construct", "feyborn": "Feyborn", "eldritch": "Eldritch",
	"stonebound": "Stonebound (legacy)"}

## Shared authored records. Isolated scenarios must also copy editable external records and ecology profiles.
@export var entries: Array[SolSpeciesRecord] = []

func find(species_id: String) -> SolSpeciesRecord:
	for entry in entries:
		if entry != null and entry.species_id == species_id:
			return entry
	return null

func valid() -> bool:
	if entries.size() > MAX_SPECIES:
		return false
	var ids := {}
	var names := {}
	var families := {}
	var stages := {}
	var profiles := {}
	for entry in entries:
		if entry == null or not entry.valid() or ids.has(entry.species_id) or names.has(entry.display_name.to_lower()) or profiles.has(entry.ecology.profile_id):
			return false
		var family := [entry.class_id, entry.evolution_forms]
		var stage := "%s:%d" % [entry.lineage_id, entry.ordinary_form]
		if (families.has(entry.lineage_id) and families[entry.lineage_id] != family) or stages.has(stage):
			return false
		ids[entry.species_id] = true
		names[entry.display_name.to_lower()] = true
		families[entry.lineage_id] = family
		stages[stage] = true
		profiles[entry.ecology.profile_id] = true
	return true

func moves_valid(known_moves: Dictionary) -> bool:
	for entry in entries:
		for id in entry.learnable_moves:
			if not known_moves.has(id):
				return false
	return true

func ecology_configuration() -> Array:
	var result: Array = []
	for entry in entries:
		var values: Array = [entry.species_id if entry != null else ""]
		if entry != null and entry.ecology != null:
			for field in preload("res://scripts/resource_storage_fields.gd").for_resource(entry.ecology):
				var value: Variant = entry.ecology.get(field)
				values.append(value.duplicate() if value is PackedStringArray else value)
		result.append(values)
	return result

static func class_display_name(id: String) -> String:
	return CLASS_NAMES.get(id, id.replace("_", " ").capitalize())

