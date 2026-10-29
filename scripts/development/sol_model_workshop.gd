extends Node3D
## Isolated artist workspace. Exercises model presentation without admitting a species.

## Drop a creature scene here. It must derive from SolCreature and accept configure().
@export var model_scene: PackedScene = preload("res://scenes/sols/crown_ear.tscn")
## Rest, repeated straight travel, square turns, or sloped terrain.
@export_enum("Rest", "Walk", "Turns", "Slope", "Flight", "Swimming") var exercise := 1
## World metres per second on the workshop route. Does not change game balance.
@export_range(0.1, 2.0, 0.05) var walk_speed := 0.3
## Actual test individual's affinity. Species skin must stay independent.
@export var affinity := "air"

var model: SolOrb
var elapsed := 0.0
var running := true
var floor_mesh: MeshInstance3D
var caption: Label
var water_mesh: MeshInstance3D

func _ready() -> void:
	if model_scene == null or affinity not in AffinityImprint.IDS or not is_finite(walk_speed) or walk_speed < 0.1 or walk_speed > 2.0 or exercise < 0 or exercise > 5:
		push_error("Invalid Sol workshop scene, affinity or exercise settings.")
		set_process(false)
		return
	var scene_check := SolSpeciesRecord.new()
	scene_check.presentation_scene = model_scene
	if not scene_check.presentation_valid():
		push_error("Workshop model scene has an incompatible root or invalid creature tuning.")
		set_process(false)
		return
	var candidate := model_scene.instantiate()
	model = candidate as SolOrb
	if model == null:
		candidate.free()
		push_error("Workshop models must extend SolOrb.")
		return
	model.configure(affinity, SolVisualSettings.new())
	add_child(model)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 2.4
	camera.position = Vector3(1.6, 1.3, 2.6)
	add_child(camera)
	camera.look_at(Vector3(0, 0.2, 0))
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-45, -25, 0)
	light.shadow_enabled = true
	add_child(light)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("273b36")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color.WHITE
	environment.environment.ambient_light_energy = 0.65
	add_child(environment)
	floor_mesh = MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(20, 20)
	floor_mesh.mesh = plane
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("465b56")
	material.roughness = 1.0
	floor_mesh.material_override = material
	add_child(floor_mesh)
	water_mesh = MeshInstance3D.new()
	var water_plane := PlaneMesh.new()
	water_plane.size = Vector2(20, 20)
	water_mesh.mesh = water_plane
	var water_material := StandardMaterial3D.new()
	water_material.albedo_color = Color(0.2, 0.48, 0.57, 0.65)
	water_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	water_material.roughness = 0.2
	water_mesh.material_override = water_material
	add_child(water_mesh)
	var layer := CanvasLayer.new()
	add_child(layer)
	caption = Label.new()
	caption.position = Vector2(24, 24)
	caption.add_theme_font_size_override("font_size", 22)
	layer.add_child(caption)
	reset_view()

func reset_view() -> void:
	elapsed = 0.0
	if model != null and model.has_method("reset_locomotion"):
		model.call("reset_locomotion")
	if floor_mesh != null:
		floor_mesh.quaternion = Quaternion(Vector3.UP, Vector3(-0.1, 1.0, -0.05).normalized()) if exercise == 3 else Quaternion.IDENTITY
		floor_mesh.position.y = -0.6 if exercise == 5 else 0.0
	if water_mesh != null:
		water_mesh.visible = exercise == 5
	update_model(0.0)

func surface(at: Vector2) -> float:
	return at.x * 0.1 + at.y * 0.05 if exercise == 3 else 0.0

func route(seconds: float) -> Vector2:
	if exercise == 0:
		return Vector2.ZERO
	var distance := seconds * walk_speed
	if exercise == 2:
		var corners := [Vector2(-0.5, -0.5), Vector2(0.5, -0.5), Vector2(0.5, 0.5), Vector2(-0.5, 0.5)]
		var index := floori(distance) % 4
		return Vector2(corners[index]).lerp(corners[(index + 1) % 4], fposmod(distance, 1.0))
	var cycle := fposmod(distance, 4.0)
	return Vector2((cycle if cycle <= 2.0 else 4.0 - cycle) - 1.0, 0)

func update_model(delta: float) -> void:
	if model == null:
		return
	var at := route(elapsed)
	model.position = Vector3(at.x, surface(at), at.y)
	model.ground_y = surface(at)
	if model.has_method("set_stance"):
		model.call("set_stance", "rest" if exercise == 0 else "alert")
	if model.has_method("set_traversal"):
		var state: Dictionary = {}
		if exercise == 4:
			var cycle := fposmod(elapsed, 12.0)
			var amount := clampf(cycle - 1.0, 0.0, 1.0) if cycle < 8.0 else clampf(9.0 - cycle, 0.0, 1.0)
			state = {"kind": "flight", "mode": "takeoff" if cycle < 2 else "air" if cycle < 8 else "landing" if cycle < 9 else "ground", "amount": amount, "height": surface(at) + amount * 0.8, "clock": elapsed}
		elif exercise == 5:
			state = {"kind": "swim", "mode": "swim", "amount": 1.0, "height": -0.18, "clock": elapsed}
		model.call("set_traversal", state)
	if model.has_method("sync_locomotion"):
		model.call("sync_locomotion", at, delta, surface)
	model.animate(elapsed, 0.0, 0.0)
	if caption != null:
		caption.text = "%s · %s · %s\nSpace: pause/resume    M: exercise    R: reset\nG: signature    J: attack    H: hit (then recovery)" % [model.name, ["Rest", "Walk", "Turns", "Slope", "Flight", "Swimming"][exercise], "Running" if running else "Paused"]

func _process(delta: float) -> void:
	if running:
		elapsed += delta
	update_model(delta if running else 0.0)

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	match event.physical_keycode:
		KEY_SPACE: running = not running
		KEY_M:
			exercise = (exercise + 1) % 6
			reset_view()
		KEY_R: reset_view()
		KEY_G: model.call("play_action", "signature", elapsed)
		KEY_J: model.call("play_action", "attack", elapsed)
		KEY_H: model.call("play_action", "hit", elapsed)
