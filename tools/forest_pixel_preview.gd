extends Control
## Explicit nearest-neighbor upscaling, with the HUD at native resolution.

@export_group("Saved Filter Defaults")
## Enable lower-resolution 3D rendering with nearest-neighbor enlargement.
## Save this scene after editing; restart the preview to apply saved defaults.
@export var pixel_filter_enabled := false
## Stored strength is retained when Pixel Filter Enabled is turned off.
@export_enum("Smooth", "Very light 1.25x", "Light 1.5x", "Medium 1.75x", "Stronger 2x", "Deep 3x") var effect_mode := 2
## Independent nearest-neighbor sampling for imported texture materials.
@export var nearest_textures := false
## Start with the painterly foliage/lighting treatment instead of the baseline.
@export var painterly_style_enabled := true
const MODE_NAMES = ["A · Smooth", "B · Very light pixels · 1.25x", "C · Light pixels · 1.5x", "D · Medium pixels · 1.75x", "E · Stronger pixels · 2x", "F · Deep pixels · 3x"]
const RENDER_DIVISORS = [1.0, 1.25, 1.5, 1.75, 2.0, 3.0]
var forest: Node3D
var container := TextureRect.new()
var viewport := SubViewport.new()
var label := Label.new()
var buttons: Array[Button] = []
var texture_toggle := CheckBox.new()
var pixel_toggle := CheckBox.new()

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(container)
	container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	container.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(viewport)
	container.texture = viewport.get_texture()
	resized.connect(update_render_size)
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	forest = preload("res://scenes/forest_style_preview.tscn").instantiate()
	forest.baseline = not painterly_style_enabled
	viewport.add_child(forest)
	forest.label.get_parent().hide()
	var panel := PanelContainer.new()
	panel.position = Vector2(16, 16)
	add_child(panel)
	var column := VBoxContainer.new()
	panel.add_child(column)
	column.add_child(label)
	label.add_theme_font_size_override("font_size", 18)
	var row := HBoxContainer.new()
	column.add_child(row)
	for index in range(MODE_NAMES.size()):
		var button := Button.new()
		button.text = ["4 Smooth", "5 Very light", "6 Light", "7 Medium", "8 Stronger", "9 Deep"][index]
		button.pressed.connect(set_effect.bind(index))
		row.add_child(button)
		buttons.append(button)
	pixel_toggle.text = "Pixel filter enabled"
	pixel_toggle.toggled.connect(func(value: bool):
		pixel_filter_enabled = value
		if value and effect_mode == 0: effect_mode = 2
		apply_effect())
	column.add_child(pixel_toggle)
	texture_toggle.text = "Nearest textures (separate from pixel size)"
	texture_toggle.button_pressed = nearest_textures
	texture_toggle.toggled.connect(func(value: bool): nearest_textures = value; apply_effect())
	column.add_child(texture_toggle)
	apply_effect()

func set_effect(value: int) -> void:
	effect_mode = clampi(value, 0, MODE_NAMES.size() - 1)
	pixel_filter_enabled = effect_mode > 0
	apply_effect()

func apply_effect() -> void:
	effect_mode = clampi(effect_mode, 0, MODE_NAMES.size() - 1)
	update_render_size()
	# Isolate the upscale effect: texture filtering stays smooth in pixel modes.
	forest.nearest_filter = nearest_textures
	viewport.msaa_3d = Viewport.MSAA_DISABLED if pixel_filter_enabled and effect_mode > 0 else Viewport.MSAA_4X
	forest.apply_style()
	pixel_toggle.set_pressed_no_signal(pixel_filter_enabled)
	for index in range(buttons.size()): buttons[index].disabled = index == (effect_mode if pixel_filter_enabled else 0)

func update_render_size() -> void:
	# Fractional scales intentionally test a lighter effect; nearest enlargement
	# gives slightly uneven pixel widths at these ratios, unlike integer scales.
	var target: Vector2 = size / (RENDER_DIVISORS[effect_mode] if pixel_filter_enabled else 1.0)
	viewport.size = Vector2i(maxi(1, roundi(target.x)), maxi(1, roundi(target.y)))

func _process(_delta: float) -> void:
	label.text = "  %s · %s · %s  \n  B compare | 1 noon · 2 sunset · 3 night | F freeze wind  \n  Drag to orbit · Wheel to zoom · R reset  " % [MODE_NAMES[effect_mode if pixel_filter_enabled else 0], "Imported" if forest.baseline else "Painterly", ["Noon", "Sunset", "Night"][forest.condition]]

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode >= KEY_4 and event.keycode <= KEY_9:
		set_effect(event.keycode - KEY_4)
		get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	forest._unhandled_input(event)
