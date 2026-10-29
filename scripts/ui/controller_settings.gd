class_name ControllerSettings
extends Resource
## Local input preferences; never expedition or identity data.
const DEFAULT_BUTTONS := {"confirm": 0, "back": 1, "details": 2, "targets": 3, "menu": 6, "pause": 4, "sprint": 7, "reset_camera": 8, "previous": 9, "next": 10}
const NAMES := {"confirm": "Choose / interact", "back": "Back / cancel", "details": "Details", "targets": "Targets / battle actions", "menu": "Field menu", "pause": "Pause", "sprint": "Run (hold)", "reset_camera": "Reset camera", "previous": "Previous target", "next": "Next target"}
## Radial stick deadzone, fraction of full travel; applies immediately.
@export_range(0.05, 0.5, 0.01) var deadzone := 0.22
## Right-stick orbit/tilt speed, degrees per second; applies immediately.
@export_range(30.0, 180.0, 5.0) var camera_speed := 90.0
## Time before held direction repeats in menus/targeting, seconds.
@export_range(0.15, 0.6, 0.01) var repeat_delay := 0.3
## Interval between repeated menu/target steps, seconds.
@export_range(0.08, 0.3, 0.01) var repeat_interval := 0.14
@export var invert_camera_y := false
var buttons: Dictionary = DEFAULT_BUTTONS.duplicate()

func valid() -> bool:
	if not is_finite(deadzone) or deadzone < 0.05 or deadzone > 0.5 or not is_finite(camera_speed) or camera_speed < 30 or camera_speed > 180 or not is_finite(repeat_delay) or repeat_delay < 0.15 or repeat_delay > 0.6 or not is_finite(repeat_interval) or repeat_interval < 0.08 or repeat_interval > 0.3:
		return false
	if buttons.size() != DEFAULT_BUTTONS.size():
		return false
	var used := {}
	for action in DEFAULT_BUTTONS:
		var button: Variant = buttons.get(action)
		if not button is int or button < 0 or button >= JOY_BUTTON_MAX or button in [5, 11, 12, 13, 14] or used.has(button):
			return false
		used[button] = true
	return true

func bind_button(action: String, button: int) -> bool:
	if not DEFAULT_BUTTONS.has(action) or button < 0 or button >= JOY_BUTTON_MAX or button in [5, 11, 12, 13, 14]:
		return false
	var previous: int = buttons[action]
	for other in buttons:
		if buttons[other] == button:
			buttons[other] = previous
	buttons[action] = button
	return valid()

func install_actions() -> void:
	# This router owns controller UI input. Preserve native keyboard UI actions,
	# but prevent a native popup and the router from both accepting one pad press.
	for name in InputMap.get_actions():
		if str(name).begins_with("ui_"):
			for event in InputMap.action_get_events(name):
				if event is InputEventJoypadButton or event is InputEventJoypadMotion:
					InputMap.action_erase_event(name, event)
	for action in buttons:
		var name := "pad_" + str(action)
		if not InputMap.has_action(name):
			InputMap.add_action(name)
		InputMap.action_erase_events(name)
		var event := InputEventJoypadButton.new()
		event.device = -1
		event.button_index = buttons[action]
		InputMap.action_add_event(name, event)

func save_preferences(path: String) -> Error:
	var config := ConfigFile.new()
	config.set_value("controller", "version", 1)
	for key in ["deadzone", "camera_speed", "invert_camera_y", "buttons"]:
		config.set_value("controller", key, get(key))
	return config.save(path)

func load_preferences(path: String) -> bool:
	var config := ConfigFile.new()
	if config.load(path) != OK or config.get_value("controller", "version") != 1:
		return false
	var candidate := ControllerSettings.new()
	for key in ["deadzone", "camera_speed"]:
		var value: Variant = config.get_value("controller", key)
		if not (value is float or value is int):
			return false
		candidate.set(key, float(value))
	var inversion: Variant = config.get_value("controller", "invert_camera_y")
	var mapping: Variant = config.get_value("controller", "buttons")
	if not inversion is bool or not mapping is Dictionary:
		return false
	candidate.invert_camera_y = inversion
	candidate.buttons = mapping.duplicate()
	if not candidate.valid():
		return false
	for key in ["deadzone", "camera_speed", "invert_camera_y", "buttons"]:
		set(key, candidate.get(key))
	return true
