extends Node
## Bounded authored-home recovery on active simulation ticks, never from a render/read query.
var world: Node2D
var sightings: Node3D
var settings: WildRecoverySettings
var state: ExpeditionState

func bind(source: Node2D, actors: Node3D, tuning: WildRecoverySettings) -> void:
	world = source
	sightings = actors
	settings = tuning if tuning != null and tuning.valid() else WildRecoverySettings.new()
	if settings != tuning:
		push_warning("Invalid wild recovery settings; using source-derived defaults.")
	world.state_replaced.connect(on_state)
	on_state(world.persistent_state)

func on_state(next: ExpeditionState) -> void:
	if state != null and state.activity_advanced.is_connected(on_tick):
		state.activity_advanced.disconnect(on_tick)
	state = next
	state.configure_wild_recovery(settings.interval_ticks)
	state.activity_advanced.connect(on_tick)

func on_tick(_tick: int) -> void:
	if world.paused or world.encounter_active or world.smoke_mode or not settings.valid() or not sightings.settings.enabled:
		return
	state.configure_wild_recovery(settings.interval_ticks)
	var occupied := {world.cell: true}
	if world.moving:
		occupied[world.destination] = true
	for member in sightings.members:
		if state.wild_available(member.id):
			occupied[sightings.current_cell(member)] = true
	var library: MoveLibrary = world.host.move_library
	if library == null or not library.valid():
		library = preload("res://resources/move_library.tres")
	var births := 0
	for entry in sightings.ENTRIES:
		var home := Vector2i(entry.x, world.terrain.trail_y(entry.x))
		if Vector2(home - world.cell).length() > settings.local_radius:
			continue
		var base := SolIdentityContract.make(world.terrain.world_seed, home, entry.species)
		state.schedule_historical_recovery(base)
		if occupied.has(home) or not world.terrain.fits(home) or state.environment_view(home, {}).get("conditions", {}).has("barrier"):
			continue
		var definition := SolSpeciesDefinition.new()
		definition.species_id = entry.species
		definition.lineage_id = entry.lineage
		definition.class_id = entry["class"]
		var identity := state.activate_wild_home(base, definition, entry.affinity, library.book(entry.species), true)
		if not identity.is_empty():
			occupied[home] = true
			births += 1
	if births > 0:
		sightings.rebuild()
		world.message("A new wild Sol has settled nearby.")

func describe_home(cell: Vector2i) -> String:
	var records := state.wild_population_view()
	for entry in sightings.ENTRIES:
		var home := Vector2i(entry.x, world.terrain.trail_y(entry.x))
		if home != cell:
			continue
		var base := SolIdentityContract.make(world.terrain.world_seed, home, entry.species)
		if not records.has(base) or records[base].active:
			return ""
		var seconds := ceili(maxi(0, int(records[base].ready_at) - state.activity_tick()) * ExpeditionState.ACTIVITY_INTERVAL)
		if seconds == 0:
			return "Wildlife return awaits clear ground."
		return "Wildlife recovering · %d:%02d of exploration time" % [int(seconds / 60), seconds % 60]
	return ""
