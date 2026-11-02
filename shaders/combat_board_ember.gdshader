shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, world_vertex_coords;

uniform vec4 mark_color : source_color = vec4(0.7, 0.95, 0.86, 0.7);
uniform float rise_height = 0.22;
uniform float ember_size = 0.035;

varying float life;

void vertex() {
	// Every instance is rooted on the marked pattern; only its tiny ember rises.
	life = fract(TIME * (0.48 + INSTANCE_CUSTOM.y * 0.16) + INSTANCE_CUSTOM.x);
	vec3 origin = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	float size = ember_size * (1.0 - life * 0.65);
	vec3 drift = vec3(sin(life * 5.0 + INSTANCE_CUSTOM.x * 20.0) * 0.018 * life, rise_height * life, 0.0);
	VERTEX = origin + drift + INV_VIEW_MATRIX[0].xyz * (UV.x - 0.5) * size + INV_VIEW_MATRIX[1].xyz * (UV.y - 0.5) * size * 1.6;
}

void fragment() {
	vec2 p = (UV - 0.5) * 2.0;
	float core = 1.0 - smoothstep(0.05, 1.0, length(p));
	float fade = smoothstep(0.0, 0.12, life) * (1.0 - smoothstep(0.45, 1.0, life));
	ALBEDO = mix(mark_color.rgb, vec3(1.0), core * 0.25);
	EMISSION = ALBEDO * 1.8;
	ALPHA = core * fade * mark_color.a;
}
