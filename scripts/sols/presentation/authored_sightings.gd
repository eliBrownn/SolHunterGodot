extends Node3D
## Persistent trail and wilderness individuals with articulated species views.

const ENTRIES := [
	{"x": 8, "species": "seedmote", "name": "Seedmote", "lineage": "family_010", "class": "verdant", "affinity": "earth", "reaction": "Wary"},
	{"x": 26, "species": "bramblepup", "name": "Bramblepup", "lineage": "family_001", "class": "beast", "affinity": "earth", "reaction": "Watching"},
	{"x": 48, "species": "seedmote", "name": "Seedmote", "lineage": "family_010", "class": "verdant", "affinity": "air", "reaction": "Guarding", "hostile": true, "behavior_profile": "trail_guard"}]

var world: Node2D
var settings: SightingSettings
var members: Array[Dictionary] = []
var elapsed := 0.0
var visual_settings: SolVisualSettings
var roaming_state: ExpeditionState
var battle_hidden_ids: Dictionary = {}
var ecology_cache: Dictionary = {}
var tuning_validation := preload("res://scripts/core/runtime_validation_cache.gd").new()
var ecology_configuration: Array = []
var ecology_validation_revision := -1
var members_by_id: Dictionary = {}
var motion_callback: Callable
var bank_homes: Dictionary = {}
var entries_source: WorldTerrain
var entries_sector := Vector2i.ZERO
var entries_revision := -1
var entries_cache: Array = []
var presentation_state: ExpeditionState
var presentation_revision := -1
var last_admitted_ids: Array = []
var roaming_batch_admitted := false

func bind(source: Node2D, tuning: SightingSettings, visuals: SolVisualSettings) -> void:
	world = source
	visual_settings = visuals if visuals != null and visuals.valid() else SolVisualSettings.new()
	if visual_settings != visuals:
		push_warning("Invalid Sol visual settings; using default affinity effects.")
	settings = tuning if tuning != null and tuning.valid() else SightingSettings.new()
	if settings != tuning:
		push_warning("Invalid sighting tuning; using default sighting settings.")
	world.rebuilt.connect(rebuild)
	world.player_step_completed.connect(admit_nearby)
	world.state_replaced.connect(initialize_individuals)
	world.observe_requested.connect(observe_nearest)
	initialize_individuals(world.persistent_state)
	rebuild()

func initialize_individuals(_state: ExpeditionState) -> void:
	last_admitted_ids.clear()
	# Content admission occurs only at explicit expedition initialization/load, never render rebuild.
	if roaming_state != null and roaming_state.activity_advanced.is_connected(advance_roaming):
		roaming_state.activity_advanced.disconnect(advance_roaming)
	if roaming_state != null and motion_callback.is_valid() and roaming_state.individual_changed.is_connected(motion_callback):
		roaming_state.individual_changed.disconnect(motion_callback)
	roaming_state = _state
	ecology_cache.clear()
	roaming_state.activity_advanced.connect(advance_roaming)
	motion_callback = queue_committed_motion.bind(_state)
	roaming_state.individual_changed.connect(motion_callback)
	if not settings.enabled:
		return
	for entry in local_entries():
		var home: Vector2i = entry_home(entry)
		if not world.terrain.fits(home):
			continue
		var identity := SolIdentityContract.make(world.terrain.world_seed, home, entry.species)
		if not world.persistent_state.individual_view(identity).is_empty():
			admit_movement(identity, entry.species)
			continue
		var authored := settings.catalog_record(entry.species)
		var definition: SolSpeciesDefinition = authored as SolSpeciesDefinition if authored != null else SolSpeciesDefinition.new()
		if authored == null:
			definition.species_id = entry.species
			definition.lineage_id = entry.lineage
			definition.class_id = entry["class"]
		var admitted: String = world.persistent_state.register_individual(definition, home, entry.affinity)
		if not admitted.is_empty():
			last_admitted_ids.append(admitted)
		admit_movement(identity, entry.species)

func admit_movement(identity: String, species_id: String) -> void:
	var authored := settings.catalog_record(species_id)
	if authored != null and authored.traversal.kind != "ground":
		world.persistent_state.admit_traversal(identity, authored.traversal.snapshot())

func entry_home(entry: Dictionary) -> Vector2i:
	return entry.get("home", Vector2i(entry.x, world.terrain.trail_y(entry.x)))

func local_entries() -> Array:
	if not settings_valid():
		return []
	var sector: Vector2i = world.terrain.chunk_of(world.cell)
	if entries_source != world.terrain or entries_sector != sector or entries_revision != tuning_validation.validation_runs:
		entries_cache = build_local_entries()
		entries_source = world.terrain
		entries_sector = sector
		entries_revision = tuning_validation.validation_runs
	return entries_cache.duplicate(true)

func build_local_entries() -> Array:
	var entries: Array = ENTRIES.duplicate(true)
	for placement in settings.catalog_sightings:
		var addition: Dictionary = placement.call("entry", settings.species_catalog)
		if addition.is_empty() or entries.any(func(row: Dictionary) -> bool: return row.x == addition.x):
			return [] # Invalid or colliding authored layouts never admit partial content.
		if addition.has("bank_radius"):
			var bank := bank_home(addition)
			if bank.is_empty():
				continue # Omit an unavailable bank; never rewrite water or fabricate a home.
			addition.home = bank.home
		entries.append(addition)
	var authored_entries: Array = entries.duplicate(true)
	if not settings.wilderness_enabled:
		return entries
	# Version-one prototype homes: one deterministic dry slot per 16-cell sector.
	# Terrain stays authoritative. Identity never depends on streaming or visit order.
	var sector: Vector2i = world.terrain.chunk_of(world.cell)
	for y in range(sector.y - 2, sector.y + 3):
		for x in range(sector.x - 2, sector.x + 3):
			var block := Vector2i(x, y) * 16
			for attempt in range(32):
				var salt: int = world.terrain.roll(Vector2i(x, y), 1700 + attempt)
				var home := block + Vector2i(salt % 16, (salt / 16) % 16)
				if world.terrain.is_camp(home) or world.terrain.is_landmark(home) or not world.terrain.fits(home):
					continue
				var overlaps := false
				for authored in authored_entries:
					if Vector2(entry_home(authored) - home).length() < 4:
						overlaps = true
				if overlaps:
					continue
				var entry: Dictionary = ENTRIES[salt % 2].duplicate(true)
				entry.home = home
				entry.affinity = ["earth", "air", "water", "fire"][world.terrain.roll(home, 1801) % 4]
				entries.append(entry)
				break
	return entries

func bank_home(entry: Dictionary) -> Dictionary:
	var anchor := Vector2i(entry.x, world.terrain.trail_y(entry.x))
	var key := "%d:%d:%d:%s" % [world.terrain.get_instance_id(), entry.x, entry.bank_radius, entry.bank_step]
	if bank_homes.has(key):
		return bank_homes[key]
	# Query cheap immutable water membership first; route/footprint checks only run at a bank.
	for radius in range(int(entry.bank_radius) + 1):
		for y in range(-radius, radius + 1):
			var edge := radius - absi(y)
			for x in ([-edge, edge] if edge > 0 else [0]):
				var water := anchor + Vector2i(x, y)
				if not SolTraversalPolicy.water(world.terrain, water):
					continue
				var at := Vector2(water) + Vector2(0.5, 0.5)
				for direction in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
					var land: Vector2i = water + direction
					if SolRoamingPolicy.distance(land, anchor) > int(entry.bank_radius) or not world.terrain.fits(land):
						continue
					if absf(world.terrain.display_height(Vector2(land) + Vector2(0.5, 0.5)) - world.terrain.display_height(at)) <= float(entry.bank_step):
						var found := {"home": land}
						if bank_homes.size() >= 512:
							bank_homes.clear()
						bank_homes[key] = found
						return found
	if bank_homes.size() >= 512:
		bank_homes.clear()
	bank_homes[key] = {}
	return {}
func admit_nearby(_from: Vector2i, _to: Vector2i) -> void:
	if world.encounter_active or not settings.enabled or not settings.wilderness_enabled:
		return
	if world.terrain.chunk_of(_from) == world.terrain.chunk_of(_to):
		return # Keep animation/interpolation intact until the local home window changes.
	# Explicit exploration admission, never performed by rebuild/render queries.
	initialize_individuals(world.persistent_state)
	rebuild(true)
	if world.host.battles != null:
		world.host.battles.ensure_movebooks(last_admitted_ids)

func rebuild(reuse_existing: bool = false) -> void:
	settings_valid()
	var reuse: bool = reuse_existing and presentation_state == world.persistent_state and presentation_revision == tuning_validation.validation_runs
	var previous: Dictionary = members_by_id.duplicate()
	if not reuse:
		for member in previous.values():
			member.sprite.free()
		previous.clear()
	members.clear()
	members_by_id.clear()
	if not reuse:
		elapsed = 0.0
	presentation_state = world.persistent_state
	presentation_revision = tuning_validation.validation_runs
	if not settings.enabled:
		for member in previous.values():
			member.sprite.free()
		return
	for entry in local_entries():
		var home: Vector2i = entry_home(entry)
		if not world.terrain.fits(home):
			continue # Never relocate an identity or overwrite terrain to fit a visual.
		var base := SolIdentityContract.make(world.terrain.world_seed, home, entry.species)
		var identity: String = world.persistent_state.home_occupant(base)
		var record: Dictionary = world.persistent_state.individual_view(identity)
		if identity.is_empty() or not world.persistent_state.wild_available(identity):
			continue
		# Saved identity fields also drive behavior filters after authored placement edits.
		entry = entry.duplicate(true)
		entry.affinity = record.affinity
		entry["class"] = record.class_id
		entry.lineage = record.lineage_id
		if previous.has(identity) and previous[identity].entry == entry:
			var retained: Dictionary = previous[identity]
			members.append(retained)
			members_by_id[identity] = retained
			previous.erase(identity)
			continue
		var sprite := SolSpeciesView.create(record.species_id, record.affinity, visual_settings, float(home.x), settings.species_catalog as SolSpeciesCatalog)
		if sprite == null:
			continue
		add_child(sprite)
		var label := Label3D.new()
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.font_size = 24
		label.pixel_size = 0.012
		label.position.y = visual_settings.diameter * 0.5 + 0.35
		label.no_depth_test = false
		sprite.add_child(label)
		var saved: Dictionary = world.persistent_state.roaming_view(identity)
		var motion := SolMotionTrack.new()
		motion.reset(Vector2i(int(saved.cell[0]), int(saved.cell[1])))
		members.append({"id": identity, "home": home, "sprite": sprite, "label": label, "entry": entry,
			"visual_cell": motion.position, "motion": motion})
		members_by_id[identity] = members.back()
	for member in previous.values():
		member.sprite.free()
	sync_views()

func queue_committed_motion(identity: String, owner: ExpeditionState) -> void:
	if owner != roaming_state or owner != world.persistent_state or not members_by_id.has(identity):
		return
	var member: Dictionary = members_by_id[identity]
	var row := owner.roaming_view(identity)
	if row.is_empty():
		member.sprite.hide()
		return
	var cell := Vector2i(int(row.cell[0]), int(row.cell[1]))
	var motion: SolMotionTrack = member.motion
	if cell == motion.target:
		return
	if (not roaming_batch_admitted and not settings_valid()) or not settings.enabled or not member.sprite.visible:
		motion.reset(cell)
		return
	# Every committed cell is observed here, including both ticks of a frame-stall batch.
	var duration := ExpeditionContract.ACTIVITY_INTERVAL * settings.movement_interval_ticks * settings.movement_travel_fraction
	motion.append(cell, duration)

func _process(delta: float) -> void:
	if not world.paused and not world.smoke_mode:
		elapsed += delta
		sync_views(delta)
	else:
		sync_views()

func current_cell(member: Dictionary) -> Vector2i:
	var row: Dictionary = world.persistent_state.roaming_view(member.id)
	return Vector2i(int(row.cell[0]), int(row.cell[1])) if not row.is_empty() else member.home

func manhattan(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)

func refresh_ecology_cache(admitted: bool = false) -> void:
	if not admitted:
		settings_valid() # Explicit callers must also detect direct nested edits.
	# settings_valid() already detects nested/in-place Inspector edits. Only
	# reconstruct the ecology snapshot when that admitted resource graph changes.
	if ecology_validation_revision != tuning_validation.validation_runs:
		var configuration := SolEcology.configuration(settings)
		ecology_cache.clear()
		ecology_configuration = configuration
		ecology_validation_revision = tuning_validation.validation_runs

func ecology_for(member: Dictionary) -> Dictionary:
	if not ecology_cache.has(member.id):
		ecology_cache[member.id] = SolEcology.resolve(member.id, member.entry, settings)
	return ecology_cache[member.id]

func patrol_goal_allowed(cell: Vector2i) -> bool:
	return world.terrain.fits(cell) and not world.persistent_state.environment_view(cell, {}).get("conditions", {}).has("barrier")

func advance_roaming(tick: int) -> void:
	if world.persistent_state != roaming_state or world.paused or world.encounter_active or world.smoke_mode or not settings_valid() or not settings.enabled or not settings.movement_enabled:
		return
	refresh_ecology_cache(true)
	roaming_batch_admitted = true
	var occupied := {world.cell: true}
	if world.moving:
		occupied[world.destination] = true
	for member in members:
		if not roaming_state.roaming_view(member.id).is_empty():
			occupied[current_cell(member)] = true
	for member in members:
		var saved := roaming_state.roaming_view(member.id)
		if saved.is_empty() or tick - maxi(0, int(saved.tick)) < settings.movement_interval_ticks:
			continue
		var position := current_cell(member)
		var distance := manhattan(position, world.cell)
		if mini(distance, manhattan(member.home, world.cell)) > settings.movement_radius:
			continue # Distant individuals retain their position and decision tick.
		var ecology := ecology_for(member)
		var traversal: Dictionary = saved.get("traversal", {})
		var geometry: Array = []
		if not traversal.is_empty():
			if not world.host.has_method("sol_clearance_bounds"):
				continue
			var prepared: Dictionary = world.host.sol_clearance_bounds(member.home, ExpeditionContract.MAX_ROAMING_DISTANCE + 2)
			if not prepared.ready:
				continue # Unpublished scenery is unknown clearance, never an empty corridor.
			geometry = prepared.bounds
		var allowed := func(cell: Vector2i) -> bool:
			if traversal.is_empty():
				return patrol_goal_allowed(cell)
			return not SolTraversalPolicy.blocked(world, cell) and (world.terrain.sample(cell).obstacle == 0 if traversal.policy.kind == "flight" else world.terrain.fits(cell) or SolTraversalPolicy.water(world.terrain, cell))
		var decision := SolEcology.decide(member.id, member.home, position, world.cell, saved, tick, ecology, allowed)
		var movement_action: String = decision.action
		if movement_action == "guard" and not decision.get("guard_advance", false):
			movement_action = "idle"
		var target := position
		if not traversal.is_empty():
			var movement := SolTraversalPolicy.advance(world, position, member.home, movement_action, decision.goal, traversal, occupied, geometry, ecology.tuning, tick, int(decision.get("minimum_player_distance", 0)))
			target = movement.target
			traversal = movement.traversal
		else:
			target = SolLocalNavigation.next_step(position, member.home, movement_action, decision.goal, occupied, world.can_step, ecology.tuning, world.cell, int(decision.get("minimum_player_distance", 0)))
		if target == position and (decision.action == "approach" or decision.get("guard_advance", false)) and not decision.get("response", {}).is_empty():
			# A blocked attempt must not continually renew attention and suppress every routine.
			decision.response.attention_until = saved.get("response", {}).get("attention_until", tick + settings.attention_ticks)
			decision.response.move_after = tick + maxi(1, settings.attention_ticks)
		if decision.action == "patrol" and target == position:
			if not decision.patrol.has("blocked_since"):
				decision.patrol.blocked_since = tick
			elif tick - int(decision.patrol.blocked_since) >= settings.blocked_goal_retry_ticks:
				decision.patrol.expires = 0
				decision.patrol.rest_until = tick
				decision.patrol.erase("blocked_since")
		else:
			decision.patrol.erase("blocked_since")
		if roaming_state.record_roaming_step(member.id, target, decision.action, decision.patrol, decision.get("response", {}), traversal):
			# Reserve both old and new cells for this decision batch.
			occupied[target] = true
	roaming_batch_admitted = false

func observable_member() -> Dictionary:
	if not settings_valid() or not settings.enabled or world.paused or world.moving or world.confirmation.visible:
		return {}
	var nearest: Dictionary = {}
	var best := 2147483647
	for member in members:
		var offset: Vector2i = current_cell(member) - world.cell
		var distance := absi(offset.x) + absi(offset.y)
		if distance > settings.observation_distance or Vector2(offset).length() > settings.visible_radius or not world.persistent_state.wild_available(member.id):
			continue
		if distance < best or (distance == best and str(member.id) < str(nearest.get("id", ""))):
			nearest = member
			best = distance
	return nearest

func observe_nearest() -> void:
	var member := observable_member()
	if member.is_empty():
		world.message("Stop near a Sol to observe it.", false)
		return
	observe_member(member)

func observe_member(member: Dictionary) -> void:
	if not settings_valid() or not settings.enabled or world.paused or world.moving or world.confirmation.visible or not world.persistent_state.wild_available(member.id):
		return
	if manhattan(current_cell(member), world.cell) > settings.observation_distance or Vector2(current_cell(member) - world.cell).length() > settings.visible_radius:
		world.message("Move closer and stop to record this Sol in Field Notes.", false)
		return
	var action: String = world.persistent_state.roaming_view(member.id).action
	var description: String = {"idle": "It watches its surroundings.", "flee": "It steps away to keep its distance.", "approach": "It approaches, leaving a comfortable distance.", "guard": "It defends its territory and watches your approach.", "return": "It returns toward its home ground.", "patrol": "It wanders through its home territory."}.get(action, "It watches its surroundings.")
	if world.persistent_state.record_sol_discovery(member.id, member.entry.name, description, current_cell(member)):
		world.message("%s sighting recorded. Open Field Notes with %s." % [member.entry.name, world.key_label("journal")])
	else:
		world.message("This individual is already recorded in Field Notes.", false)
	sync_views()

func sync_views(delta: float = 0.0) -> void:
	var safe := settings_valid() and settings.enabled
	if safe:
		refresh_ecology_cache(true)
	for member in members:
		var row: Dictionary = world.persistent_state.roaming_view(member.id)
		var position: Vector2i = Vector2i(int(row.cell[0]), int(row.cell[1])) if not row.is_empty() else member.home
		var difference: Vector2i = position - world.cell
		var available: bool = world.persistent_state.wild_available(member.id) and not battle_hidden_ids.has(member.id)
		var was_visible: bool = member.sprite.visible
		member.sprite.visible = safe and available and Vector2(difference).length() <= settings.visible_radius
		if not member.sprite.visible:
			member.motion.reset(position)
			if member.sprite.has_method("reset_locomotion"):
				member.sprite.call("reset_locomotion")
			continue
		if not was_visible:
			member.motion.reset(position)
		elif delta > 0 and not world.paused and not world.encounter_active:
			member.motion.advance(delta)
		member.visual_cell = member.motion.position
		var relative: Vector2 = Vector2(member.visual_cell) * 32.0 + Vector2(16, 16) - world.camera.position
		member.sprite.ground_y = world.host.ground_height(Vector2(member.visual_cell) + Vector2(0.5, 0.5)) + 0.08
		member.sprite.position = Vector3(relative.x / 32.0, 0.08, relative.y / 32.0)
		member.sprite.set_meta("world_cell", position)
		if member.sprite.has_method("set_traversal"):
			var at := Vector2(member.visual_cell) + Vector2(0.5, 0.5)
			member.sprite.call("set_traversal", SolTraversalPolicy.presentation(world.terrain, row, at, world.persistent_state.activity_seconds()))
			if row.get("traversal", {}).get("mode", "ground") != "ground":
				member.sprite.ground_y = world.terrain.display_height(at) + 0.08
		if member.sprite.has_method("sync_locomotion"):
			var motion_delta := delta if not world.paused and not world.encounter_active and was_visible else 0.0
			member.sprite.call("sync_locomotion", Vector2(member.visual_cell) + Vector2(0.5, 0.5), motion_delta, world.host.ground_height)
		if member.sprite.has_method("set_stance"):
			member.sprite.call("set_stance", "rest" if row.get("action", "idle") == "idle" else "alert")
		member.sprite.animate(elapsed, settings.bob_pixels, settings.bob_cycles)
		var ecology := ecology_for(member)
		var reacting: bool = row.has("response") or absi(difference.x) + absi(difference.y) <= ecology.tuning.reaction_distance
		member.label.visible = reacting and not world.encounter_active
		member.label.text = member.entry.name + " · " + str(member.sprite.affinity).capitalize() + "\n" + SolReactionPolicy.caption(ecology.reaction, row) if reacting else ""
		var mode: String = row.get("traversal", {}).get("mode", "ground")
		if reacting and mode != "ground":
			member.label.text += " · " + str({"takeoff": "Taking off", "air": "Flying", "landing": "Landing", "swim_enter": "Entering water", "wade": "Wading", "swim": "Swimming", "swim_exit": "Coming ashore"}.get(mode, ""))
		if reacting and absi(difference.x) + absi(difference.y) <= settings.observation_distance:
			var input_hint: String = world.host.gamepad.button_name("confirm") + " · Options" if world.host.gamepad != null and world.host.gamepad.active else "Right-click"
			member.label.text += "\n%s · %s" % [input_hint, "Recorded" if world.persistent_state.has_discovery(member.id) else "Observe / Engage"]

func settings_valid() -> bool:
	if settings == null:
		return false
	return tuning_validation.check(settings, [settings.species_catalog, settings._catalog_override_set, preload("res://resources/sol_ecology/behavior_library.tres")])
