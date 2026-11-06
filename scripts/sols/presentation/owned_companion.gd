extends Node3D
## Presentation of the selected owned identity. Never creates a wild Sol or writes domain motion.

var world: Node2D
var settings: OwnedCompanionSettings
var source_state: ExpeditionState
var identity := ""
var profile: Dictionary = {}
var cell := Vector2i.ZERO
var placed := false
var sprite: SolOrb
var caption := Label3D.new()
var motion := SolMotionTrack.new()
var elapsed := 0.0
var resting := 0.0
var moment_remaining := 0.0
var following := false
var action := "rest"
var selected_behavior := "idle"
const MOMENT_CAPTIONS := {"crown_ear_listen": "Listening, then checking back", "bellroot_tend": "Inspecting the undergrowth",
	"ashquill_preens": "Smoothing its feathers", "rattlehorn_footing": "Testing the footing", "rimefold_investigate": "Unfolding a soft fin",
	"browguard_moment": "Lowers its padded brow toward a companion",
	"bitterfrill_moment": "Relaxes and ripples its frill",
	"knucklemole_moment": "Tests the ground with its nose",
	"sailcrest_moment": "Briefly spreads its membranes",
	"glass_throat_moment": "Aligns its throat rings and tilts its head",
	"claspback_moment": "Closes its front hooks like a clasp",
	"foldling_moment": "Unfolds one band to watch a companion",
	"mournveil_moment": "Lifts its living veil to uncover its face",
	"pebblewyrm_moment": "Curls its tail and lowers its blunt snout",
	"shadepelt_moment": "Parts its shoulder strands to expose its face",
	"kilnling_moment": "Taps its short hands together",
	"thimblehart_moment": "Dips its small antler cups toward a companion"}
var body_policy: Dictionary = {}
var geometry: Array = []
var route_radius := 0
var route_origin := Vector2i.ZERO
var decision_after := 0.0
var admission_retry := 0.0
var tuning_validation := preload("res://scripts/core/runtime_validation_cache.gd").new()
var travel := OwnedCompanionTraversal.new()

func bind(source: Node2D, tuning: OwnedCompanionSettings) -> void:
	world = source
	settings = tuning
	caption.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	caption.font_size = 28
	caption.pixel_size = 0.008
	caption.position.y = 1.25
	add_child(caption)
	sync_identity()
	sync_view(0.0)

func clear_view() -> void:
	if sprite != null:
		sprite.hide()
		sprite.queue_free()
		sprite = null
	placed = false
	identity = ""
	profile = {}
	caption.hide()

func occupied_cells() -> Dictionary:
	var occupied := {}
	if world.moving:
		occupied[world.destination] = true
	for member in world.host.sightings.members:
		if world.persistent_state.wild_available(member.id):
			occupied[world.host.sightings.current_cell(member)] = true
	return occupied

func sync_identity() -> void:
	var active: Dictionary = world.persistent_state.active_sol_view()
	var record: Dictionary = world.persistent_state.individual_view(active.get("id", ""))
	if active.is_empty() or record.get("location", "") != "party":
		clear_view()
		source_state = world.persistent_state
		return
	if source_state == world.persistent_state and identity == active.id and profile == active.profile:
		return
	var same_identity: bool = source_state == world.persistent_state and identity == active.id
	var was_placed := placed
	clear_view()
	source_state = world.persistent_state
	identity = active.id
	profile = active.profile.duplicate(true)
	var catalog: SolSpeciesCatalog = load("res://resources/sol_species/catalog.tres")
	var species := catalog.find(profile.species_id)
	body_policy = species.traversal.snapshot() if species != null else {}
	sprite = SolSpeciesView.create(profile.species_id, record.affinity, world.host.sol_visual_settings, SolEcology.sample(identity, "activity") * TAU)
	if sprite != null:
		add_child(sprite)
		# Initial selection/load is an admission, never an in-world catch-up shortcut.
		if same_identity:
			placed = was_placed
		else:
			admit()
	if same_identity:
		return # Level/profile updates cannot relocate an already-present individual.
	travel.reset(body_policy, cell)
	elapsed = 0.0
	decision_after = 0.0
	admission_retry = 0.0
	resting = 0.0
	moment_remaining = 0.0
	following = false

func admit() -> void:
	if not prepare_clearance(world.cell):
		return
	var occupied := occupied_cells()
	var preferred: Vector2i = {"west": Vector2i.LEFT, "east": Vector2i.RIGHT, "south": Vector2i.DOWN, "north": Vector2i.UP}[settings.admission_side]
	var directions: Array = [preferred]
	for direction in SolLocalNavigation.DIRECTIONS:
		if direction != preferred:
			directions.append(direction)
	for direction in directions:
		var candidate: Vector2i = world.cell + direction
		if not occupied.has(candidate) and ground_step(world.cell, candidate):
			cell = candidate
			placed = true
			motion.reset(cell)
			return

func prepare_clearance(origin: Vector2i) -> bool:
	route_origin = origin
	route_radius = settings.search_radius
	geometry = []
	if body_policy.is_empty() or not world.host.has_method("sol_clearance_bounds"):
		return true
	# Reduce the search to published scenery; missing geometry is never assumed clear.
	for radius in [settings.search_radius + 1, 5, 3, 2]:
		var prepared: Dictionary = world.host.sol_clearance_bounds(origin, radius)
		if prepared.ready:
			geometry = prepared.bounds
			route_radius = mini(settings.search_radius, radius - 1)
			return true
	return false

func ground_step(from: Vector2i, to: Vector2i) -> bool:
	if SolRoamingPolicy.distance(to, route_origin) > route_radius or not world.can_step(from, to):
		return false
	if body_policy.is_empty():
		return true
	var a := Vector2(from) + Vector2(0.5, 0.5)
	var b := Vector2(to) + Vector2(0.5, 0.5)
	return SolTraversalPolicy.corridor(Vector3(a.x, world.host.ground_height(a) + 0.02, a.y), Vector3(b.x, world.host.ground_height(b) + 0.02, b.y), body_policy, geometry)

func _process(delta: float) -> void:
	if world == null:
		return
	if settings == null or not tuning_validation.check(settings) or not settings.enabled:
		hide()
		return
	show()
	sync_identity()
	if sprite == null:
		return
	if world.paused or world.encounter_active:
		sync_view(0.0)
		return
	var used := minf(maxf(delta, 0), 0.1)
	if not placed:
		admission_retry = maxf(0, admission_retry - used)
		if admission_retry <= 0:
			admit() # Retry only an individual never admitted to the world.
			admission_retry = settings.step_seconds
	if not placed:
		sync_view(0.0)
		return
	elapsed += used
	motion.advance(used)
	var distance := SolRoamingPolicy.distance(cell, world.cell)
	if distance == 0 or distance >= settings.resume_distance:
		following = true
	if distance > 0 and distance <= settings.stop_distance:
		following = false
	if following or world.moving:
		resting = 0.0
		moment_remaining = 0.0
	elif travel.grounded():
		resting += used
		moment_remaining = maxf(0.0, moment_remaining - used)
		if resting >= settings.rest_after_seconds:
			resting = 0.0
			var entry := {"species": profile.species_id, "class": profile.class_id, "affinity": profile.affinity}
			var behavior := settings.behavior_library.select("idle", entry)
			selected_behavior = behavior.get("id", "idle")
			if MOMENT_CAPTIONS.has(selected_behavior):
				moment_remaining = settings.moment_seconds
				if sprite.has_method("play_action"):
					sprite.set("action_seconds", settings.moment_seconds)
					sprite.call("play_action", "signature", elapsed)
	action = "follow" if following else "moment" if moment_remaining > 0 else "rest"
	if (following or not travel.grounded()) and motion.segments.is_empty() and elapsed >= decision_after:
		decision_after = elapsed + settings.step_seconds
		var next := cell
		if prepare_clearance(cell):
			var bounded_edge := func(from: Vector2i, to: Vector2i) -> bool:
				return SolRoamingPolicy.distance(to, route_origin) <= route_radius and ground_step(from, to)
			next = travel.advance(world, cell, world.cell, occupied_cells(), geometry, bounded_edge, settings, elapsed, following, route_radius)
		if next != cell:
			cell = next
			motion.append(cell, settings.step_seconds)
		elif following and not travel.transition():
			action = "waiting"
	sync_view(used)

func sync_view(delta: float) -> void:
	if sprite == null:
		caption.hide()
		return
	var supported: bool = world.terrain.fits(cell) if travel.state.is_empty() else SolTraversalPolicy.cell_valid(world.terrain, cell, travel.state)
	var visible_now: bool = placed and not world.encounter_active and Vector2(cell - world.cell).length() <= settings.visible_radius and supported
	sprite.visible = visible_now
	caption.visible = visible_now
	if not visible_now:
		return
	var at := motion.position + Vector2(0.5, 0.5)
	var relative: Vector2 = at - world.camera.position / 32.0
	sprite.position = Vector3(relative.x, 0.0, relative.y)
	sprite.ground_y = world.host.ground_height(at) + 0.08
	if sprite.has_method("set_traversal"):
		var visual := travel.visual(world.terrain, cell, at, elapsed)
		if not visual.is_empty():
			visual.height += 0.08
			sprite.ground_y = world.terrain.display_height(at) + 0.08
		sprite.call("set_traversal", visual)
	if sprite.has_method("sync_locomotion"):
		sprite.call("sync_locomotion", at, delta, world.host.ground_height)
	if sprite.has_method("set_stance"):
		sprite.call("set_stance", "alert" if following else "rest")
	sprite.animate(elapsed, world.host.sighting_settings.bob_pixels, world.host.sighting_settings.bob_cycles)
	var top := 1.0
	if sprite.has_method("preview_bounds"):
		var bounds: AABB = sprite.call("preview_bounds")
		top = bounds.end.y
	caption.position = sprite.position + Vector3.UP * (top + settings.caption_clearance)
	var description := "%s · Companion" % profile.display_name
	if settings.routine_captions or action in ["waiting", "moment"]:
		description += "\n" + str({"follow": "Following you", "waiting": "Waiting for a clear route", "rest": "Resting nearby", "moment": MOMENT_CAPTIONS.get(selected_behavior, "Resting nearby")}.get(action, "Resting nearby"))
	if not travel.grounded():
		description += " · " + str({"takeoff": "Taking off", "air": "Flying", "landing": "Landing", "swim_enter": "Entering water", "swim": "Swimming", "wade": "Wading", "swim_exit": "Coming ashore"}.get(travel.mode(), ""))
	if caption.text != description:
		caption.text = description
