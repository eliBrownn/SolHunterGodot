class_name SolOrb
extends Sprite3D
## Original pixel sphere, ground shadow and bounded affinity motes in real 3D space.

var affinity := ""
var tint := Color.WHITE
var tuning: SolVisualSettings
var phase := 0.0
var ground_y := 0.08
var halo: Sprite3D
var shadow: MeshInstance3D
var motes: Array[Sprite3D] = []

func configure(assigned_affinity: String, settings: SolVisualSettings, phase_offset: float = 0.0) -> void:
	affinity = AffinityImprint.canonical(assigned_affinity)
	tuning = settings
	tint = tuning.color_for(affinity)
	phase = phase_offset
	texture = sphere_texture(Color.WHITE if affinity == "quantum" else tint)
	pixel_size = tuning.diameter / 24.0
	billboard = BaseMaterial3D.BILLBOARD_ENABLED
	texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	shaded = false
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	halo = make_sprite(disc_texture(Color(tint, tuning.aura_opacity)), tuning.diameter * 1.8 / 24.0)
	halo.render_priority = -1
	add_child(halo)
	shadow = MeshInstance3D.new()
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(tuning.diameter * 0.9, tuning.diameter * 0.6)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_texture = disc_texture(Color(0.04, 0.07, 0.09, 0.32))
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	shadow.mesh = mesh
	shadow.material_override = material
	shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(shadow)
	var effect_texture := mote_texture()
	for index in range(tuning.effect_count):
		var mote := make_sprite(effect_texture, tuning.diameter / 32.0)
		add_child(mote)
		motes.append(mote)
	animate(0.0, 1.0, 0.8)

static func make_sprite(image: Texture2D, scale_pixel: float) -> Sprite3D:
	var sprite := Sprite3D.new()
	sprite.texture = image
	sprite.pixel_size = scale_pixel
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	sprite.shaded = false
	sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return sprite

static func sphere_texture(color: Color) -> Texture2D:
	var image := Image.create(24, 24, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	for y in range(24):
		for x in range(24):
			var p := (Vector2(x, y) - Vector2(11.5, 11.5)) / 11.0
			var radius := p.length_squared()
			if radius > 1.0:
				continue
			var normal := Vector3(p.x, -p.y, sqrt(1.0 - radius))
			var light := normal.dot(Vector3(-0.45, 0.6, 0.7).normalized())
			var band := floorf(clampf(light, 0.0, 1.0) * 4.0) / 4.0
			var pixel := color.darkened(0.55 - band * 0.45)
			if radius > 0.83:
				pixel = color.darkened(0.65)
			elif Vector2(x - 8, y - 7).length_squared() < 6:
				pixel = color.lerp(Color.WHITE, 0.8)
			image.set_pixel(x, y, pixel)
	return ImageTexture.create_from_image(image)

static func disc_texture(color: Color) -> Texture2D:
	var image := Image.create(24, 24, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	for y in range(24):
		for x in range(24):
			var distance := ((Vector2(x, y) - Vector2(11.5, 11.5)) / 11.5).length()
			if distance < 1:
				image.set_pixel(x, y, Color(color, color.a * ceilf((1.0 - distance) * 3.0) / 3.0))
	return ImageTexture.create_from_image(image)

func mote_texture() -> Texture2D:
	var patterns := {
		"fire": ["..x..", "..xx.", ".xxx.", ".xxx.", "..x.."],
		"water": ["..x..", "..x..", ".xxx.", ".xxx.", "..x.."],
		"grove": ["...xx", "..xxx", ".xxx.", "xxx..", "xx..."],
		"air": [".xxx.", "x....", ".xxx.", "....x", ".xxx."],
		"lightning": ["..xx.", ".xx..", ".xxx.", "..x..", ".x..."],
		"earth": [".....", ".xxx.", ".xxx.", ".xxx.", "....."]}
	var rows: Array = patterns.get(affinity, ["..x..", "..x..", "xxxxx", "..x..", "..x.."])
	var image := Image.create(5, 5, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	for y in range(5):
		for x in range(5):
			if rows[y][x] == "x":
				image.set_pixel(x, y, tint.lerp(Color.WHITE, 0.35))
	return ImageTexture.create_from_image(image)

func animate(seconds: float, bob_pixels: float, bob_cycles: float) -> void:
	if affinity == "quantum":
		modulate = tint.lerp(Color("8beae9"), (sin(seconds * TAU * tuning.effect_speed) + 1.0) * 0.5)
	var bob := sin(seconds * TAU * bob_cycles + phase) * bob_pixels / 24.0
	var height := tuning.hover_height + bob
	position.y = ground_y + height
	shadow.position.y = -height + 0.015
	halo.modulate.a = 0.85 + sin(seconds * TAU * tuning.effect_speed + phase) * 0.15
	for index in range(motes.size()):
		var fraction := float(index) / motes.size()
		var cycle := seconds * tuning.effect_speed + fraction + phase / TAU
		var angle := cycle * TAU
		var radius := tuning.diameter * 0.72
		var mote := motes[index]
		mote.position = Vector3(cos(angle) * radius, sin(angle * 1.5) * radius * 0.35, sin(angle) * radius)
		mote.modulate.a = 0.5 + 0.5 * absf(sin(angle))
		if affinity == "fire":
			mote.position.y = (fposmod(cycle, 1.0) - 0.4) * tuning.diameter * 1.5
			mote.modulate.a = 1.0 - fposmod(cycle, 1.0)
		elif affinity == "water":
			mote.position.y = -absf(sin(angle)) * radius * 0.6
		elif affinity == "air":
			mote.position.y = sin(angle) * radius * 0.6
		elif affinity == "lightning":
			mote.modulate.a = 1.0 if sin(angle * 3) > 0.6 else 0.15
