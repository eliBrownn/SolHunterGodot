class_name SolSpeciesView
extends RefCounted
## Presentation adapter; keep render types out of the species data registry.

static func create(species_id: String, assigned_affinity: String, tuning: SolVisualSettings, phase_offset: float = 0.0, catalog: SolSpeciesCatalog = null) -> SolOrb:
	var source := catalog if catalog != null else load("res://resources/sol_species/catalog.tres") as SolSpeciesCatalog
	var entry: SolSpeciesRecord = source.find(species_id) if source != null else null
	var view: SolOrb
	if entry != null:
		if not entry.presentation_valid():
			return null
		view = entry.presentation_scene.instantiate() as SolOrb
	else:
		# Preserve legacy/unknown identity while replacing the old sphere fallback.
		view = load("res://scripts/sols/presentation/sol_prototype_creature.gd").new()
		view.prototype_kind = {"seedmote": 1, "bramblepup": 2, "ashkit": 3, "rillfin": 4}.get(species_id, 0)
		view.set_meta("provisional_creature_art", true)
	if view == null:
		return null
	view.set_meta("species_id", species_id)
	view.configure(assigned_affinity, tuning, phase_offset)
	return view
