extends CanvasLayer
## Presentation-only sampling of the world before the full-resolution HUD.
## Keeps camera projection, picking coordinates, simulation and saves unchanged.

const DIVISORS = [1.0, 1.25, 1.5, 1.75, 2.0, 3.0]
const LABELS = ["Off", "Very light", "Light", "Medium", "Strong", "Deep"]
var level := 0
var material := ShaderMaterial.new()
var surface := ColorRect.new()
var native_msaa := Viewport.MSAA_2X

func _ready() -> void:
	layer = -10
	material.shader = preload("res://shaders/world_pixels.gdshader")
	surface.material = material
	surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(surface)
	surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	set_level(level)

func set_level(value: int) -> void:
	level = clampi(value, 0, DIVISORS.size() - 1)
	surface.visible = level > 0
	material.set_shader_parameter("pixel_divisor", DIVISORS[level])
	if is_inside_tree():
		get_viewport().msaa_3d = native_msaa if level == 0 else Viewport.MSAA_DISABLED
		get_viewport().screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
