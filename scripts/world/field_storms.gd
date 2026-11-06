extends Node3D
## The seed owns permanent sites. Nearby particle nodes are presentation only.

const LAB := preload("res://tools/vastra_particle_lab.gd")
const FILAMENT := preload("res://scripts/presentation/vastra_filament_mesh.gd")
const REGION_SIZE := 18
const VISUAL_RADIUS := 20

@export var layout_seed := 2601026

var _emitters: Dictionary[Vector2i, GPUParticles3D] = {}
var _noise: ImageTexture3D
var _last_cell := Vector2i(2147483647, 2147483647)
var _time := 0.0


func _ready() -> void:
	_noise = LAB.optical_noise()


func site_for(region: Vector2i) -> Variant:
	if region == Vector2i.ZERO:
		return Vector2i(2, -2)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("field-storm:%d:%d:%d" % [layout_seed, region.x, region.y])
	if rng.randf() >= 0.65:
		return null
	return region * REGION_SIZE + Vector2i(rng.randi_range(-6, 6), rng.randi_range(-6, 6))


func advance(delta: float, player_cell: Vector2i, ground_height: Callable, is_land: Callable = Callable()) -> void:
	_time += delta
	if player_cell != _last_cell:
		_last_cell = player_cell
		_refresh_emitters(player_cell, ground_height, is_land)
	for particles: GPUParticles3D in _emitters.values():
		particles.process_material.set_shader_parameter("animation_time", _time)
		particles.draw_pass_1.surface_get_material(0).set_shader_parameter("animation_time", _time)


func _refresh_emitters(player_cell: Vector2i, ground_height: Callable, is_land: Callable) -> void:
	var margin := Vector2i.ONE * (VISUAL_RADIUS + 6)
	var first := Vector2i((Vector2(player_cell - margin) / REGION_SIZE).floor())
	var last := Vector2i((Vector2(player_cell + margin) / REGION_SIZE).floor())
	var nearby: Array[Vector2i] = []
	for z in range(first.y, last.y + 1):
		for x in range(first.x, last.x + 1):
			var site: Variant = site_for(Vector2i(x, z))
			if site != null and player_cell.distance_squared_to(site) <= VISUAL_RADIUS * VISUAL_RADIUS \
					and (not is_land.is_valid() or is_land.call(Vector2(site) + Vector2(0.5, 0.5))):
				nearby.append(site)
	nearby.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return player_cell.distance_squared_to(a) < player_cell.distance_squared_to(b))
	nearby.resize(mini(nearby.size(), 4))
	for site: Vector2i in _emitters.keys():
		if site not in nearby:
			var particles := _emitters[site]
			remove_child(particles)
			particles.queue_free()
			_emitters.erase(site)
	for site in nearby:
		if not _emitters.has(site):
			var center := Vector2(site) + Vector2(0.5, 0.5)
			var particles := _make_vortex()
			particles.position = Vector3(center.x, ground_height.call(center), center.y)
			add_child(particles)
			_emitters[site] = particles


func _make_vortex() -> GPUParticles3D:
	var preset: Array = LAB.VALUES[LAB.STORM_PRESET]
	var motion := ShaderMaterial.new()
	motion.shader = preload("res://shaders/vastra_particle_lab_motion.gdshader")
	var draw := ShaderMaterial.new()
	draw.shader = preload("res://shaders/vastra_particle_lab_draw.gdshader")
	for material in [motion, draw]:
		material.set_shader_parameter("pattern", 2)
		material.set_shader_parameter("flow_speed", preset[2])
		material.set_shader_parameter("turbulence", preset[3])
		material.set_shader_parameter("field_height", 2.8)
		material.set_shader_parameter("spread", 4.0)
		material.set_shader_parameter("trail_seconds", 0.65)
	draw.set_shader_parameter("particle_size", preset[4])
	draw.set_shader_parameter("opacity", preset[5])
	draw.set_shader_parameter("all_affinities", true)
	draw.set_shader_parameter("filament_length", 2.0)
	draw.set_shader_parameter("refraction", 0.01)
	draw.set_shader_parameter("field_noise", _noise)
	var mesh := FILAMENT.create()
	mesh.surface_set_material(0, draw)
	var particles := GPUParticles3D.new()
	particles.amount = 128 * 11
	particles.amount_ratio = float(preset[0]) / 100.0
	particles.lifetime = 3600.0
	particles.explosiveness = 1.0
	particles.local_coords = true
	particles.fixed_fps = 60
	particles.use_fixed_seed = true
	particles.seed = 291030
	particles.process_material = motion
	particles.draw_pass_1 = mesh
	particles.visibility_aabb = AABB(Vector3(-5.0, -1.0, -5.0), Vector3(10.0, 6.0, 10.0))
	particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	particles.preprocess = 0.1
	return particles
