shader_type spatial;
render_mode cull_disabled;

#include "res://shaders/map_tree_hue.gdshaderinc"

uniform sampler2D painted_atlas : source_color, filter_linear_mipmap_anisotropic;
uniform float wind_time = 0.0;
uniform float wind_strength = 0.5;
uniform vec2 wind_direction = vec2(1.0, 0.6);
uniform vec2 world_origin = vec2(0.0);
uniform bool silhouette_view = false;

void vertex() {
	map_tree_hue = INSTANCE_CUSTOM.ra;
	vec3 world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world.xz += world_origin;
	// UV.y=1 is the attached stem end. Weather time also freezes on pause.
	float free_tip = pow(1.0 - UV.y, 1.5);
	float wave = sin(wind_time * 1.3 + world.x * 1.7 + world.z);
	float flutter = sin(wind_time * 2.7 + world.z * 2.3) * 0.02;
	VERTEX.xz += wind_direction * (wave * 0.08 + flutter) * wind_strength * free_tip;
}

void fragment() {
	// Per-card habitat is carried in vertex alpha; materials stay shared.
	float habitat = floor(COLOR.a * 4.0);
	vec4 region = habitat == 1.0 ? vec4(0.005, 0.45, 0.29, 0.545) : vec4(0.035, 0.035, 0.17, 0.405);
	vec4 paint = texture(painted_atlas, region.xy + UV * region.zw);
	float luminance = dot(paint.rgb, vec3(0.21, 0.72, 0.07));
	float rib = pow(max(0.0, 1.0 - abs(UV.x - 0.5) * 25.0), 2.0);
	ALBEDO = shift_map_tree_hue(COLOR.rgb) * luminance * 1.1 * (1.0 + rib * 0.08);
	if (silhouette_view) ALBEDO = vec3(0.02);
	ALPHA = paint.a;
	ALPHA_SCISSOR_THRESHOLD = 0.45;
	ROUGHNESS = 0.9;
	SPECULAR = 0.12;
	NORMAL = FRONT_FACING ? NORMAL : -NORMAL;
	BACKLIGHT = ALBEDO * 0.22;
}
