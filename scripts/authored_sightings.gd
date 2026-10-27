extends Node3D
## Three original pixel placeholders over persistent authored individuals, not a wild generator.

const ENTRIES := [
	{"x": 8, "species": "seedmote", "name": "Seedmote", "lineage": "family_010", "class": "verdant", "affinity": "grove", "reaction": "Wary"},
	{"x": 26, "species": "bramblepup", "name": "Bramblepup", "lineage": "family_001", "class": "beast", "affinity": "grove", "reaction": "Watching"},
	{"x": 48, "species": "seedmote", "name": "Seedmote", "lineage": "family_010", "class": "verdant", "affinity": "gale", "reaction": "Guarding", "hostile": true}]

var world: Node2D
var settings: SightingSettings
var members: Array[Dictionary] = []
var elapsed := 0.0
var textures: Dictionary = {}
var roaming_state: ExpeditionState

func bind(source: Node2D, tuning: SightingSettings) -> void:
	world = source
	settings = tuning if tuning != null and tuning.valid() else SightingSettings.new()
	if settings != tuning:
		push_warning("Invalid sighting tuning; using default sighting settings.")
	world.rebuilt.connect(rebuild)
	world.state_replaced.connect(initialize_individuals)
	world.observe_requested.connect(observe_nearest)
	initialize_individuals(world.persistent_state)
	rebuild()

func initialize_individuals(_state: ExpeditionState) -> void:
	# Content admission occurs only at explicit expedition initialization/load, never render rebuild.
	if roaming_state != null and roaming_state.activity_advanced.is_connected(advance_roaming):
		roaming_state.activity_advanced.disconnect(advance_roaming)
	roaming_state = _state
	roaming_state.activity_advanced.connect(advance_roaming)
	if not settings.enabled:
		return
	for entry in ENTRIES:
		var home := Vector2i(entry.x, world.terrain.trail_y(entry.x))
		if not world.terrain.fits(home):
			continue
		var identity := SolIdentityContract.make(world.terrain.world_seed, home, entry.species)
		if not world.persistent_state.individual_view(identity).is_empty():
			continue
		var definition := SolSpeciesDefinition.new()
		definition.species_id = entry.species
		definition.lineage_id = entry.lineage
		definition.class_id = entry["class"]
		world.persistent_state.register_individual(definition, home, entry.affinity)

func rebuild() -> void:
	for member in members:
		member.sprite.free()
	members.clear()
	elapsed = 0.0
	if not settings.enabled:
		return
	for entry in ENTRIES:
		var home := Vector2i(entry.x, world.terrain.trail_y(entry.x))
		if not world.terrain.fits(home):
			continue # Never relocate an identity or overwrite terrain to fit a visual.
		var identity := SolIdentityContract.make(world.terrain.world_seed, home, entry.species)
		var record: Dictionary = world.persistent_state.individual_view(identity)
		if identity.is_empty() or record.get("location") != "wild":
			continue
		var sprite := Sprite3D.new()
		sprite.texture = texture_for(entry.species)
		sprite.pixel_size = 1.0 / 24.0
		sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		sprite.shaded = false
		sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		sprite.offset.y = 9
		add_child(sprite)
		var label := Label3D.new()
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.font_size = 24
		label.pixel_size = 0.012
		label.position.y = 1.1
		label.no_depth_test = false
		sprite.add_child(label)
		var saved: Dictionary = world.persistent_state.roaming_view(identity)
		members.append({"id": identity, "home": home, "sprite": sprite, "label": label, "entry": entry,
			"visual_cell": Vector2(float(saved.cell[0]), float(saved.cell[1]))})
	sync_views()

func texture_for(species: String) -> Texture2D:
	if textures.has(species):
		return textures[species]
	# Original code-native pixel silhouettes; not copied source artwork or final species art.
	var rows := ["................", ".......gg.......", "......ggg.......", ".....ddgg.......", "....dddddd......", "...ddllllld.....", "...dllwllwld....", "...dllllllld....", "....dlllld......", ".....dddd.......", "......dd........", ".....g..g.......", "................", "................", "................", "................"]
	if species == "bramblepup":
		rows = ["................", "...dd......dd...", "...dld....dld...", "...dlllddllld...", "....dlllllld....", "...dlwllllwld...", "...dlllllllld...", "....dllllddd....", ".....dddd.......", "....dllllld.....", "...dllllllld....", "...ddllllldd....", "....dd..dd......", "....dd..dd......", "................", "................"]
	var palette := {"d": Color("354b3c"), "l": Color("a8c77f"), "g": Color("6d9b51"), "w": Color("fff2cd")}
	var image := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	for y in range(16):
		for x in range(16):
			var key: String = rows[y][x]
			if palette.has(key):
				image.set_pixel(x, y, palette[key])
	textures[species] = ImageTexture.create_from_image(image)
	return textures[species]

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

func advance_roaming(tick: int) -> void:
	if world.persistent_state != roaming_state or world.paused or world.smoke_mode or not settings.valid() or not settings.enabled or not settings.movement_enabled:
		return
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
		var action := "idle"
		var goal: Vector2i = member.home
		if manhattan(position, member.home) > settings.home_radius:
			action = "return"
		elif member.entry.reaction == "Wary":
			if distance < settings.reaction_distance or (saved.action == "flee" and distance < settings.flee_release_distance):
				action = "flee"
				goal = world.cell
			elif distance > settings.flee_release_distance and position != member.home:
				action = "return"
		elif member.entry.reaction == "Watching":
			if distance > settings.comfort_distance and distance <= settings.reaction_distance:
				action = "approach"
				goal = world.cell
			elif distance > settings.reaction_distance and position != member.home:
				action = "return"
		else:
			action = "guard" if distance <= settings.reaction_distance else "idle"
		var target := position
		if action in ["flee", "approach", "return"]:
			for step in [Vector2i.UP, Vector2i.LEFT, Vector2i.RIGHT, Vector2i.DOWN]:
				var candidate: Vector2i = position + step
				var home_distance := manhattan(candidate, member.home)
				if occupied.has(candidate) or (home_distance > settings.home_radius and home_distance >= manhattan(position, member.home)) or home_distance > ExpeditionState.MAX_ROAMING_DISTANCE:
					continue
				if not world.terrain.can_step(position, candidate):
					continue
				if (action == "flee" and manhattan(candidate, goal) > manhattan(target, goal)) or (action != "flee" and manhattan(candidate, goal) < manhattan(target, goal)):
					target = candidate
		if roaming_state.record_roaming_step(member.id, target, action):
			# Keep both old and new cells reserved for this small decision batch.
			occupied[target] = true

func observable_member() -> Dictionary:
	if not settings.valid() or not settings.enabled or world.paused or world.moving or world.confirmation.visible:
		return {}
	var nearest: Dictionary = {}
	var best := 2147483647
	for member in members:
		var offset: Vector2i = current_cell(member) - world.cell
		var distance := absi(offset.x) + absi(offset.y)
		if distance > settings.observation_distance or Vector2(offset).length() > settings.visible_radius or world.persistent_state.individual_view(member.id).get("location") != "wild":
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
	var action: String = world.persistent_state.roaming_view(member.id).action
	var description: String = {"idle": "It watches its surroundings.", "flee": "It steps away to keep its distance.", "approach": "It approaches, leaving a comfortable distance.", "guard": "It holds its place and watches your approach.", "return": "It returns toward its home ground."}[action]
	if world.persistent_state.record_sol_discovery(member.id, member.entry.name, description, current_cell(member)):
		world.message("%s sighting recorded. Open Field Notes with %s." % [member.entry.name, world.key_label("journal")])
	else:
		world.message("This individual is already recorded in Field Notes.", false)
	sync_views()

func sync_views(delta: float = 0.0) -> void:
	var safe := settings != null and settings.valid() and settings.enabled
	for member in members:
		var position := current_cell(member)
		var difference: Vector2i = position - world.cell
		var available: bool = world.persistent_state.individual_view(member.id).get("location") == "wild"
		var was_visible: bool = member.sprite.visible
		member.sprite.visible = safe and available and Vector2(difference).length() <= settings.visible_radius
		if not member.sprite.visible:
			continue
		if not was_visible:
			member.visual_cell = Vector2(position)
		elif delta > 0:
			member.visual_cell = member.visual_cell.move_toward(Vector2(position), delta / settings.movement_blend_seconds)
		var relative: Vector2 = Vector2(member.visual_cell) * 32.0 + Vector2(16, 16) - world.camera.position
		member.sprite.position = Vector3(relative.x / 32.0, 0.08, relative.y / 32.0)
		member.sprite.offset.y = 9 + sin(elapsed * TAU * settings.bob_cycles + member.home.x) * settings.bob_pixels
		var reacting: bool = absi(difference.x) + absi(difference.y) <= settings.reaction_distance
		member.label.visible = reacting and not world.encounter_active
		member.label.text = member.entry.name + "\n" + member.entry.reaction if reacting else ""
		var row: Dictionary = world.persistent_state.roaming_view(member.id)
		if reacting and row.get("action", "idle") != "idle":
			member.label.text += " · " + str(row.action).capitalize()
		if reacting and absi(difference.x) + absi(difference.y) <= settings.observation_distance:
			member.label.text += "\n%s · %s" % [world.key_label("observe_sol"), "Recorded" if world.persistent_state.has_discovery(member.id) else "Observe"]
