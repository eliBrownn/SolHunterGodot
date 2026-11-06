shader_type spatial;
render_mode cull_disabled, specular_disabled;

#include "res://shaders/map_tree_hue.gdshaderinc"

void vertex() {
	map_tree_hue = INSTANCE_CUSTOM.ra;
}

void fragment() {
	ALBEDO = COLOR.a > 0.5 ? shift_map_tree_hue(COLOR.rgb) : COLOR.rgb;
	ROUGHNESS = 1.0;
	NORMAL = FRONT_FACING ? NORMAL : -NORMAL;
}
