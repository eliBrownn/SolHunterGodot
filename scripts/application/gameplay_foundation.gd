extends Node3D

const DIRECTIONS := {
	KEY_W: Vector2i.UP, KEY_UP: Vector2i.UP,
	KEY_A: Vector2i.LEFT, KEY_LEFT: Vector2i.LEFT,
	KEY_S: Vector2i.DOWN, KEY_DOWN: Vector2i.DOWN,
	KEY_D: Vector2i.RIGHT, KEY_RIGHT: Vector2i.RIGHT,
}
const MOVE_SPEED := 48.0
const SPRINT_SPEED := 144.0
const CENTER_SPEED := 24.0
const KNIGHT_HEIGHT := 0.85
const CAMERA_FOLLOW_RATE := 48.0
const CAMERA_HEIGHT_FOLLOW_RATE := 14.0
const CAMERA_ZOOM_RATE := 14.0
const ORBIT_SENSITIVITY := PI / 720.0

var cell := Vector2i.ZERO
var _held_keys: Dictionary[Key, bool] = {}
var _input_focused := true
var _camera_dragging := false
var _camera_center: Vector3
var _camera_zoom := 1.0
var _camera_zoom_target := 1.0
var _fps_refresh := 0.0

@onready var _terrain := $Terrain
@onready var _player: Node3D = $Player
@onready var _knight := $Player/GraveKnight
@onready var _camera: Camera3D = $Camera3D
@onready var _storms := $VastraStorms
@onready var _fps: Label = $HUD/FPS
@onready var _biome: Label = $HUD/Biome
@onready var _camera_start_rotation := _camera.rotation
@onready var _camera_local_offset := _camera.basis.inverse() * _camera.position


func _ready() -> void:
	_knight.prepare_static(KNIGHT_HEIGHT)
	_storms.layout_seed = _terrain.world_seed
	var spawn: Dictionary = _terrain.beach_spawn()
	cell = spawn.cell
	var heading: Vector2i = spawn.heading
	_camera_start_rotation.y = atan2(-heading.x, -heading.y)
	_camera.rotation = _camera_start_rotation
	_knight.rotation.y = _camera.rotation.y
	var center := Vector2(cell) + Vector2(0.5, 0.5)
	_player.position = Vector3(center.x, _terrain.height_at(center), center.y)
	_terrain.cover(cell)
	_biome.text = _terrain.biome_name(cell)
	_camera_center = _player.position
	_update_camera_position()


func _process(delta: float) -> void:
	# Follow the step without moving the camera and knight in lockstep on a uniform grid.
	var height := lerpf(_camera_center.y, _player.position.y, 1.0 - exp(-CAMERA_HEIGHT_FOLLOW_RATE * delta))
	_camera_center = _camera_center.lerp(_player.position, 1.0 - exp(-CAMERA_FOLLOW_RATE * delta))
	_camera_center.y = clampf(height, _player.position.y - 1.25, _player.position.y + 1.25)
	_camera_zoom = lerpf(_camera_zoom, _camera_zoom_target, 1.0 - exp(-CAMERA_ZOOM_RATE * delta))
	_update_camera_position()
	_storms.advance(delta, cell, _terrain.height_at, _terrain.is_land_at)
	_fps_refresh -= delta
	if _fps_refresh <= 0.0:
		_fps.text = "%d FPS" % Engine.get_frames_per_second()
		_fps_refresh = 0.25


func _update_camera_position() -> void:
	var camera_position := _camera_center + _camera.basis * _camera_local_offset * _camera_zoom
	var ground: float = _terrain.height_at(Vector2(camera_position.x, camera_position.z))
	camera_position.y = maxf(camera_position.y, ground + 0.65)
	_camera.position = camera_position


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_MIDDLE:
				_camera_dragging = event.pressed
			MOUSE_BUTTON_WHEEL_UP:
				if event.pressed:
					_camera_zoom_target = maxf(0.48, _camera_zoom_target / 1.12)
			MOUSE_BUTTON_WHEEL_DOWN:
				if event.pressed:
					_camera_zoom_target = minf(3.0, _camera_zoom_target * 1.12)
	elif event is InputEventMouseMotion and _camera_dragging:
		_camera.rotation.y = wrapf(_camera.rotation.y - event.relative.x * ORBIT_SENSITIVITY, -PI, PI)
		_camera.rotation.x = clampf(_camera.rotation.x - event.relative.y * ORBIT_SENSITIVITY,
			deg_to_rad(-72.0), deg_to_rad(-9.0))
		_update_camera_position()


func _unhandled_key_input(event: InputEvent) -> void:
	var key_event := event as InputEventKey
	var key := key_event.physical_keycode
	if key == KEY_HOME and key_event.pressed and not key_event.echo:
		_camera.rotation = _camera_start_rotation
		_camera_zoom = 1.0
		_camera_zoom_target = 1.0
		_camera_dragging = false
		_update_camera_position()
		return
	if not DIRECTIONS.has(key) or key_event.echo:
		return
	if key_event.pressed:
		_held_keys[key] = true
	else:
		_held_keys.erase(key)


func _physics_process(delta: float) -> void:
	var input := _movement_input()
	if input != Vector2.ZERO:
		var direction := Vector3(input.x, 0.0, input.y).rotated(Vector3.UP, _camera.rotation.y)
		var speed := SPRINT_SPEED if Input.is_physical_key_pressed(KEY_SHIFT) else MOVE_SPEED
		_player.position += direction * speed * delta
		_knight.rotation.y = atan2(direction.x, direction.z)
	else:
		var center := Vector3(cell.x + 0.5, _player.position.y, cell.y + 0.5)
		_player.position = _player.position.move_toward(center, CENTER_SPEED * delta)
	_player.position.y = _terrain.height_at(Vector2(_player.position.x, _player.position.z))
	var next_cell := Vector2i(floori(_player.position.x), floori(_player.position.z))
	if next_cell != cell:
		cell = next_cell
		_biome.text = _terrain.biome_name(cell)
		_terrain.cover(cell)


func _movement_input() -> Vector2:
	if not _input_focused:
		return Vector2.ZERO
	var directions: Dictionary[Vector2i, bool] = {}
	for key in _held_keys:
		directions[DIRECTIONS[key]] = true
	var keyboard := Vector2.ZERO
	for direction in directions:
		keyboard += Vector2(direction)
	if keyboard != Vector2.ZERO:
		return keyboard.normalized()
	for device in Input.get_connected_joypads():
		var stick := Vector2(Input.get_joy_axis(device, JOY_AXIS_LEFT_X),
			Input.get_joy_axis(device, JOY_AXIS_LEFT_Y))
		if stick.length() > 0.2:
			return stick.normalized() * remap(minf(stick.length(), 1.0), 0.2, 1.0, 0.0, 1.0)
	return Vector2.ZERO


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_held_keys.clear()
		_camera_dragging = false
		_input_focused = false
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		_input_focused = true
