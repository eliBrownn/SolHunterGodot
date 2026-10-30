shader_type spatial;
render_mode cull_disabled, alpha_to_coverage;
uniform sampler2D albedo_texture : source_color, filter_linear_mipmap_anisotropic;
uniform bool textured = false;
uniform vec4 ground_base_color : source_color = vec4(0.48, 0.57, 0.34, 1.0);
uniform float base_height = 0.0;
uniform float blade_length = 1.0;
uniform float wind_strength = 0.14;
uniform vec2 wind_direction = vec2(1.0, 0.0);
varying float blade_height;
void vertex() {
	blade_height = clamp((VERTEX.y - base_height) / max(blade_length, 0.001), 0.0, 1.0);
	vec3 world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float breeze = sin(TIME * 0.8 + dot(world.xz, vec2(0.3, 0.2)));
	vec3 push = vec3(wind_direction.x, 0.0, wind_direction.y) * breeze * wind_strength * 0.25 * blade_height * blade_height;
	VERTEX += inverse(mat3(MODEL_MATRIX)) * push;
}
void fragment() {
	ALBEDO = ground_base_color.rgb * COLOR.rgb * mix(0.95, 1.12, blade_height);
	NORMAL = normalize((VIEW_MATRIX * vec4(0.0, 1.0, 0.0, 0.0)).xyz);
	ALPHA = textured ? texture(albedo_texture, UV).a : 1.0;
	ALPHA_SCISSOR_THRESHOLD = 0.4;
	ALPHA_ANTIALIASING_EDGE = 0.3;
	ALPHA_TEXTURE_COORDINATE = UV * vec2(textureSize(albedo_texture, 0));
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
}
