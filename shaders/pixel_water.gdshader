shader_type spatial;
render_mode cull_disabled;

uniform vec2 world_origin = vec2(0.0);
uniform vec4 deep_color : source_color = vec4(0.14, 0.31, 0.38, 1.0);
uniform vec4 shallow_color : source_color = vec4(0.33, 0.59, 0.56, 1.0);
uniform float depth_color_range : hint_range(0.1, 1.0) = 0.4;
uniform float foam_depth : hint_range(0.01, 0.15) = 0.06;
uniform float ripple_strength : hint_range(0.0, 0.15) = 0.006;
uniform float ripple_speed : hint_range(0.0, 2.0) = 0.6;
uniform sampler2D ripple_noise : filter_linear_mipmap, repeat_enable;
varying vec2 ground_position;

void vertex() {
	ground_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz + world_origin;
}

void fragment() {
	float clock = TIME * ripple_speed;
	vec2 flow = ground_position * 0.08 + vec2(clock * 0.01, -clock * 0.007);
	float first = texture(ripple_noise, flow).r;
	float second = texture(ripple_noise, ground_position * 0.137 - vec2(clock * 0.006, clock * 0.009)).r;
	float drift = (first + second) * 0.5;
	float depth = max(0.0, UV2.x);
	float deep = smoothstep(0.0, depth_color_range, depth);
	vec3 color = mix(shallow_color.rgb, deep_color.rgb, deep);
	color += vec3(0.018, 0.028, 0.024) * (drift - 0.5);
	float foam = (1.0 - smoothstep(0.005, foam_depth, depth)) * (0.55 + 0.15 * sin(clock + drift * 12.0));
	ALBEDO = mix(color, vec3(0.72, 0.83, 0.77), foam * UV2.y);
	vec2 slope = vec2(texture(ripple_noise, flow + vec2(0.006, 0.0)).r - first, texture(ripple_noise, flow + vec2(0.0, 0.006)).r - first) * ripple_strength * 16.0;
	NORMAL = normalize((VIEW_MATRIX * vec4(normalize(vec3(-slope.x, 1.0, -slope.y)), 0.0)).xyz);
	ROUGHNESS = 0.38;
	SPECULAR = 0.3;
}
