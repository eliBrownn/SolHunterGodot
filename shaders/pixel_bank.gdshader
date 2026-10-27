shader_type spatial;
render_mode unshaded, cull_disabled;

uniform vec2 world_origin = vec2(0.0);
uniform vec4 soil_color : source_color = vec4(0.38, 0.39, 0.27, 1.0);
uniform vec4 wet_color : source_color = vec4(0.24, 0.34, 0.29, 1.0);
uniform vec4 rim_color : source_color = vec4(0.51, 0.53, 0.34, 1.0);
varying vec3 ground_position;

void vertex() {
	ground_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	ground_position.xz += world_origin;
}

void fragment() {
	vec3 pixel = floor(ground_position * 32.0);
	float grain = mod(pixel.x + pixel.z * 3.0, 7.0) / 7.0;
	vec3 base = ground_position.y < -0.15 ? wet_color.rgb : soil_color.rgb;
	if (ground_position.y > -0.025) {
		base = rim_color.rgb;
	}
	ALBEDO = base * (0.90 + grain * 0.12);
}
