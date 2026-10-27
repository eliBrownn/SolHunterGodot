extends Node3D
## Three original pixel placeholders over persistent authored individuals, not a wild generator.

const ENTRIES := [
	{"x": 8, "species": "seedmote", "name": "Seedmote", "lineage": "family_010", "class": "verdant", "affinity": "grove", "reaction": "Wary"},
	{"x": 26, "species": "bramblepup", "name": "Bramblepup", "lineage": "family_001", "class": "beast", "affinity": "grove", "reaction": "Watching"},
	{"x": 48, "species": "seedmote", "name": "Seedmote", "lineage": "family_010", "class": "verdant", "affinity": "gale", "reaction": "Guarding"}]

var world: Node2D
var settings: SightingSettings
var members: Array[Dictionary] = []
var elapsed := 0.0
var textures: Dictionary = {}

func bind(source: Node2D, tuning: SightingSettings) -> void:
	world = source
	settings = tuning if tuning != null and tuning.valid() else SightingSettings.new()
	if settings != tuning:
		push_warning("Invalid sighting tuning; using default sighting settings.")
	world.rebuilt.connect(rebuild)
	world.state_replaced.connect(initialize_individuals)
	initialize_individuals(world.persistent_state)
	rebuild()

func initialize_individuals(_state: ExpeditionState) -> void:
	# Content admission occurs only at explicit expedition initialization/load, never render rebuild.
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
		members.append({"id": identity, "home": home, "sprite": sprite, "label": label, "entry": entry})
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
	sync_views()

func sync_views() -> void:
	var safe := settings != null and settings.valid() and settings.enabled
	for member in members:
		var difference: Vector2i = member.home - world.cell
		var available: bool = world.persistent_state.individual_view(member.id).get("location") == "wild"
		member.sprite.visible = safe and available and Vector2(difference).length() <= settings.visible_radius
		if not member.sprite.visible:
			continue
		var relative: Vector2 = world.center(member.home) - world.camera.position
		member.sprite.position = Vector3(relative.x / 32.0, 0.08, relative.y / 32.0)
		member.sprite.offset.y = 9 + sin(elapsed * TAU * settings.bob_cycles + member.home.x) * settings.bob_pixels
		var reacting: bool = absi(difference.x) + absi(difference.y) <= settings.reaction_distance
		member.label.visible = reacting
		member.label.text = member.entry.name + "\n" + member.entry.reaction if reacting else ""
