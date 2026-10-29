extends SubViewportContainer
## Isolated presentation of the same Sol model used in the world and combat.
var viewport := SubViewport.new()
var camera := Camera3D.new()
var model: SolOrb
var seconds := 0.0
var profile: Dictionary = {}
var settings: MenuSettings
func _ready() -> void:
	stretch = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	viewport.own_world_3d = true
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	viewport.handle_input_locally = true
	viewport.gui_disable_input = true
	add_child(viewport)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.current = true
	viewport.add_child(camera)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("12251f")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color.WHITE
	environment.environment.ambient_light_energy = 0.7
	viewport.add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-35, -25, 0)
	viewport.add_child(light)
	resized.connect(fit_model)
func show_profile(value: Dictionary, tuning: SolVisualSettings, menu_settings: MenuSettings, catalog: SolSpeciesCatalog = null) -> void:
	profile = value.duplicate(true)
	settings = menu_settings
	if model != null:
		viewport.remove_child(model)
		model.queue_free()
	model = SolSpeciesView.create(str(value.species_id), str(value.affinity), tuning, 0.0, catalog)
	if model == null:
		return
	model.shadow.hide()
	viewport.add_child(model)
	fit_model()
func fit_model() -> void:
	if model == null or size.y <= 0:
		return
	var diameter := model.tuning.diameter
	var aspect := maxf(0.1, size.x / size.y)
	var padding: float = settings.preview_framing if settings != null else 2.5
	camera.size = diameter * padding * maxf(1.0, 1.0 / aspect)
	var center := Vector3(0, model.ground_y + model.tuning.hover_height, 0)
	if model.has_method("preview_bounds"):
		var bounds: AABB = model.call("preview_bounds")
		center = bounds.get_center() + Vector3(0, model.ground_y, 0)
		# Fit horizontal width and vertical extent independently; include depth at camera tilt.
		# Creature envelopes already contain articulation margin. Use radius-relative
		# framing here so a small first form stays readable in the compact menu.
		camera.size = maxf(bounds.size.y + bounds.size.z * 0.35, bounds.size.x / aspect) * padding * 0.5
		diameter = maxf(bounds.size.x, maxf(bounds.size.y, bounds.size.z))
		# Small creature anatomy must not crop the independent affinity effects.
		if not model.motes.is_empty():
			camera.size = maxf(camera.size, model.tuning.diameter * 2.0 * maxf(1.0, 1.0 / aspect))
	camera.position = center + Vector3(0, diameter * 0.4, diameter * 4)
	camera.look_at(center)
func _process(delta: float) -> void:
	if model == null or not is_visible_in_tree():
		return
	seconds += maxf(0, delta)
	model.animate(seconds, 0.5, 0.5)
