shader_type spatial;
render_mode unshaded, cull_disabled;

uniform vec2 world_origin = vec2(0.0);
uniform vec4 deep_color : source_color = vec4(0.15, 0.32, 0.37, 1.0);
uniform vec4 light_color : source_color = vec4(0.32, 0.53, 0.56, 1.0);
varying vec2 ground_position;

void vertex() {
	ground_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz + world_origin;
}

void fragment() {
	// Whole-pixel, three-step-per-second ripples anchored to absolute world cells.
	vec2 pixel = floor(ground_position * 32.0);
	float tick = floor(TIME * 3.0);
	float lane = mod(pixel.y + tick, 17.0);
	float segment = mod(pixel.x + floor(pixel.y / 17.0) * 11.0, 37.0);
	float ripple = (1.0 - step(1.0, lane)) * step(5.0, segment) * (1.0 - step(16.0, segment));
	float mottling = mod(floor(pixel.x / 8.0) + floor(pixel.y / 8.0) * 3.0, 5.0) * 0.022;
	ALBEDO = mix(deep_color.rgb, light_color.rgb, min(1.0, mottling + ripple * 0.65));
}
