class_name SolOrb
extends MeshInstance3D
## Shared individual identity and ground shadow. Decorative affinity effects are retired.

var affinity := ""
var tint := Color.WHITE
var tuning: SolVisualSettings
var phase := 0.0
var ground_y := 0.08
var halo: MeshInstance3D
var orb_material := StandardMaterial3D.new()
var halo_material: StandardMaterial3D # Retired compatibility field; no aura material allocation.
var shadow: MeshInstance3D
var motes: Array[Sprite3D] = []

func configure(assigned_affinity: String, settings: SolVisualSettings, phase_offset: float = 0.0) -> void:
	affinity = AffinityImprint.canonical(assigned_affinity)
	tuning = settings
	tint = tuning.color_for(affinity)
	phase = phase_offset
	# Identity/palette remain available to UI and combat; no sphere, aura or motes.
	halo = MeshInstance3D.new()
	halo.hide()
	add_child(halo)
	shadow = MeshInstance3D.new()
	var shadow_mesh := PlaneMesh.new()
	shadow_mesh.size = Vector2(tuning.diameter * 0.9, tuning.diameter * 0.6)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_texture = disc_texture(Color(0.04, 0.07, 0.09, 0.32))
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	shadow.mesh = shadow_mesh
	shadow.material_override = material
	shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(shadow)
	animate(0.0, 0.0, 0.0)

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

func animate(_seconds: float, _bob_pixels: float, _bob_cycles: float) -> void:
	position.y = ground_y
	shadow.position.y = 0.015
