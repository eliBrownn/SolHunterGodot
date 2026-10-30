shader_type spatial;
render_mode cull_disabled;
uniform sampler2D painted_atlas : source_color, filter_linear_mipmap_anisotropic;
uniform float wind_time = 0.0;
uniform float wind_strength = 0.5;
uniform vec2 wind_direction = vec2(1.0,0.6);
uniform vec2 world_origin = vec2(0.0);
uniform bool flower_surface = false;
uniform bool vastra_surface = false;
uniform float palette_recolor : hint_range(0.0,1.0) = 0.0;
uniform float palette_gain : hint_range(0.8,1.5) = 1.4;
uniform bool bark_surface = false;
uniform sampler2D authored_normal : hint_normal, filter_linear_mipmap_anisotropic;
void vertex() {
	vec3 world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world.xz += world_origin;
	float bend = bark_surface ? 0.0 : pow(clamp(VERTEX.y / 2.5, 0.0, 1.0), 1.5);
	VERTEX.x += sin(wind_time * 1.3 + world.x * 1.7 + world.z) * wind_strength * 0.10 * bend * wind_direction.x;
	VERTEX.z += cos(wind_time + world.z * 1.2) * wind_strength * 0.06 * bend * wind_direction.y;
}
void fragment() {
	vec2 uv = UV;
	// Reuse the painted pink petal's interior, with geometry owning its outline.
	if (flower_surface) uv = vec2(0.51 + (UV.x - 0.119) * 0.7, 0.40 + (UV.y - 0.23) * 0.24);
	vec4 pigment = texture(painted_atlas, uv);
	if (vastra_surface) pigment.rgb = mix(vec3(dot(pigment.rgb,vec3(0.333))), vec3(0.62,0.76,0.74),0.8);
	vec3 paint = mix(pigment.rgb,vec3(dot(pigment.rgb,vec3(0.21,0.72,0.07))*palette_gain),palette_recolor);
	ALBEDO = paint * COLOR.rgb;
	ALPHA = pigment.a;
	ALPHA_SCISSOR_THRESHOLD = 0.5;
	ROUGHNESS = 0.9;
	SPECULAR = 0.15;
	NORMAL = FRONT_FACING ? NORMAL : -NORMAL;
	if (bark_surface) NORMAL_MAP = texture(authored_normal,UV).rgb;
	BACKLIGHT = ALBEDO * (bark_surface ? 0.0 : 0.15);
}
