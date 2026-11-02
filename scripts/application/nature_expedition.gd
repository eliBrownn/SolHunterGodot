extends Node
## Field-action adapter. ExpeditionState owns knowledge; existing follower owns motion.
var world: Node2D
var pending: Dictionary = {}
var elapsed := 0.0
var settings: NatureFieldSettings

func bind(source: Node2D) -> void:
	world = source
	settings = world.host.nature_field_settings if world.host.nature_field_settings != null and world.host.nature_field_settings.valid() else NatureFieldSettings.new()
	world.update_hud()
	if settings.enabled: world.message("Explore local signs. Observe plants and wildlife, then prepare another outing at camp.", false)

func available() -> bool:
	return settings.enabled and not world.paused and not world.moving and not world.encounter_active and not world.confirmation.visible

func near(at: Vector2i) -> bool:
	return settings.valid() and absi(at.x - world.cell.x) + absi(at.y - world.cell.y) <= settings.observation_distance

func observe(at: Vector2i) -> void:
	if not available() or not near(at): return
	var state: ExpeditionState = world.persistent_state
	var plant := state.flora_reading(at)
	if not plant.is_empty():
		state.record_finding("plant_reserve", at, AffinityImprint.key(at), float(plant.energy))
		for flight in state.flora_transfers()+state.ambient_transfers():
			if str(flight.get("source", "")) == AffinityImprint.key(at):
				state.record_finding("circulation", at, str(flight.source), float(flight.get("amount", 0)), str(flight.target))
	if world.terrain.is_walkable(at) and world.terrain.lake_distance(at) > 1.0 and world.terrain.lake_distance(at) < 1.5:
		state.record_finding("water_approach", at, AffinityImprint.key(at))
	var environment := state.environment_view(at, world.terrain.sample(at))
	if int(environment.get("overload", 0)) > 0 or not environment.get("conditions", {}).is_empty():
		state.record_finding("warning", at, AffinityImprint.key(at), maxf(0.0, float(environment.get("overload", 0))))
	var encounters: Node = world.host.encounters
	if not encounters.warning_id.is_empty():
		for member in world.host.sightings.members:
			if member.id == encounters.warning_id and world.host.sightings.current_cell(member) == at:
				state.record_finding("warning", at, member.id, 1.0)

func goal() -> String:
	if settings == null or not settings.enabled or not settings.valid(): return ""
	if world.terrain.world_seed != settings.sample_seed or world.terrain.generation_version != settings.sample_generation: return "Explore local signs · retain findings in Field Guide"
	var learned := {}
	for finding in world.persistent_state.finding_entries(): learned[finding.key] = true
	if not learned.has("plant_reserve") and world.terrain.fits(settings.grove_cell): return "Observe living plants near %d, %d · compare their reserves" % [settings.grove_cell.x, settings.grove_cell.y]
	if not learned.has("water_approach") and world.terrain.is_walkable(settings.bank_cell): return "Investigate the waterside approach at %d, %d" % [settings.bank_cell.x, settings.bank_cell.y]
	if not learned.has("warning"): return "Watch territorial signs along the eastern trail · approach or leave"
	if not world.terrain.is_camp(world.cell): return "Return to camp · recover and prepare another outing"
	return "Prepare your return · choose a companion and revisit a finding"

func record_contact(target: Dictionary) -> void:
	if settings.enabled and settings.valid() and target.get("hostile", false):
		world.persistent_state.record_finding("warning", target.cell, target.id, 1.0)

func action_for(at: Vector2i) -> String:
	if not available() or not settings.valid() or not pending.is_empty(): return ""
	var follower: Node3D = world.host.companion
	var active: Dictionary = world.persistent_state.active_sol_view()
	if not active.is_empty() and active.hp <= 0: return ""
	if follower == null or not follower.placed or follower.following or active.is_empty() or follower.identity != active.id: return ""
	var record: Dictionary = world.persistent_state.individual_view(active.id)
	if near(at) and follower.cell.distance_to(at) <= settings.observation_distance and record.get("species_id", "") in settings.inspection_species and not world.persistent_state.flora_reading(at).is_empty(): return "Inspect with companion"
	if record.get("species_id", "") in settings.listening_species and absi(at.x - world.cell.x) + absi(at.y - world.cell.y) <= settings.listening_distance and follower.cell.distance_to(at) <= settings.listening_distance:
		for member in world.host.sightings.members:
			if member.sprite.visible and world.persistent_state.wild_available(member.id) and world.host.sightings.current_cell(member) == at:
				return "Listen with companion"
	return ""

func cooperate(at: Vector2i) -> bool:
	var action := action_for(at)
	if action.is_empty(): return false
	var active: Dictionary = world.persistent_state.active_sol_view()
	pending = {"state": world.persistent_state, "identity": active.id, "cell": at, "origin": world.cell, "action": action, "duration": settings.cooperation_seconds}
	if action == "Listen with companion":
		for member in world.host.sightings.members:
			if member.sprite.visible and world.persistent_state.wild_available(member.id) and world.host.sightings.current_cell(member) == at:
				pending["target"] = member.id
				break
	world.host.companion.show_field_response("Inspecting the nearby plant" if action == "Inspect with companion" else "Listening beside the nearby Sol", settings.cooperation_seconds)
	elapsed = 0.0
	world.message(action + " · stay nearby while your companion responds.", false)
	return true

func _process(delta: float) -> void:
	if pending.is_empty(): return
	if world.persistent_state != pending.state or world.cell != pending.origin or world.encounter_active or world.persistent_state.active_sol_view().get("id", "") != pending.identity:
		world.host.companion.field_caption = ""
		pending.clear()
		return
	if world.paused: return
	elapsed += delta
	if elapsed < float(pending.duration): return
	var action := pending.duplicate()
	pending.clear()
	world.host.companion.field_caption = ""
	var observed_member := {}
	if action.action == "Listen with companion":
		for member in world.host.sightings.members:
			if member.id == action.get("target", "") and member.sprite.visible and world.persistent_state.wild_available(member.id):
				observed_member = member
				action.cell = world.host.sightings.current_cell(member)
				break
		if observed_member.is_empty(): return
	if action_for(action.cell) != action.action: return
	var id := "companion_inspect" if action.action == "Inspect with companion" else "companion_listen"
	var value := float(world.persistent_state.flora_reading(action.cell).get("energy", 0))
	var target: String = AffinityImprint.key(action.cell)
	var observation := ""
	if not observed_member.is_empty():
		target = observed_member.id
		var ecology: Dictionary = world.host.sightings.ecology_for(observed_member)
		if not ecology.has("reaction"): return
		observation = SolReactionPolicy.caption(str(ecology.reaction), world.persistent_state.roaming_view(target))
		world.persistent_state.record_sol_discovery(target, observed_member.entry.name, observation, action.cell)
	else:
		var plant: Dictionary = world.persistent_state.flora_reading(action.cell)
		observation = "%s · %s" % [str(plant.get("traits", {}).get("name", "Plant")), str(plant.get("activity", "idle")).capitalize()]
	world.persistent_state.record_finding(id, action.cell, action.identity, value, target, observation)
	observe(action.cell)
	world.message("Your companion inspected the plant's current reserve: %.0f · %s. Finding retained in Field Guide." % [value, observation] if id == "companion_inspect" else "Your companion listens: %s. Observation retained in Field Guide." % observation, false)
