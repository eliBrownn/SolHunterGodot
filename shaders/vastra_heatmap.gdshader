shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;
#include "res://shaders/vastra_field.gdshaderinc"

uniform int density_mode = 1;

varying vec3 field_position;
varying float concentration;
varying float nature_reveal;

void vertex() {
	field_position = VERTEX;
	concentration = UV2.x;
	nature_reveal = COLOR.a;
}

void fragment() {
	float fade = 1.0;
	float value = concentration;
	if (density_mode == 2) {
		value *= nature_reveal * vastra_sol_openness(field_position);
	}
	vec3 cold = vec3(0.025, 0.10, 0.40);
	vec3 middle = vec3(0.02, 0.55, 0.45);
	vec3 warm = vec3(0.95, 0.70, 0.05);
	vec3 hot = vec3(0.85, 0.06, 0.02);
	vec3 color = mix(cold, middle, smoothstep(0.0, 0.35, value));
	color = mix(color, warm, smoothstep(0.35, 0.7, value));
	color = mix(color, hot, smoothstep(0.7, 1.0, value));
	ALBEDO = color;
	EMISSION = color * 0.1;
	ALPHA = fade * 0.65;
}
