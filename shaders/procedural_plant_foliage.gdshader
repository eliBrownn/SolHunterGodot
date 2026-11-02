shader_type spatial;
render_mode cull_disabled;
uniform sampler2D painted_atlas : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float leaf_saturation_min : hint_range(0.0,2.0) = 0.65;
uniform float leaf_saturation_max : hint_range(0.0,2.0) = 1.65;
uniform float wind_time = 0.0;
uniform float wind_strength = 0.5;
uniform vec2 wind_direction = vec2(1.0,0.6);
uniform vec2 world_origin = vec2(0.0);
#include "res://shaders/foliage_condition.gdshaderinc"
uniform bool flower_surface = false;
uniform bool vastra_surface = false;
uniform float palette_recolor : hint_range(0.0,1.0) = 0.0;
uniform float palette_gain : hint_range(0.8,1.5) = 1.4;
uniform bool bark_surface = false;
uniform bool tree_surface = false;
// Only ground-cover instances opt in; trees and ordinary foliage keep zero.
uniform vec2 grass_fade_range = vec2(0.0);
varying float grass_visibility;
varying vec3 grass_position;
uniform sampler2D authored_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
varying float reserve_fraction;
varying float reserve_connected;
varying float leaf_vivid;
varying float bark_texture_scale;
void vertex() {
	bark_texture_scale=(tree_surface && bark_surface) ? length(MODEL_MATRIX[1].xyz) : 1.0;
	reserve_connected = (bark_surface || vastra_surface || flower_surface) ? 0.0 : step(0.5, INSTANCE_CUSTOM.a);
	reserve_fraction = mix(1.0,foliage_reserve(INSTANCE_CUSTOM,wind_time),reserve_connected);
	vec3 world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	grass_visibility = grass_fade_range.y > 0.0 ? 1.0 - smoothstep(grass_fade_range.x,grass_fade_range.y,length(world-CAMERA_POSITION_WORLD)) : 1.0;
	world.xz += world_origin;
	grass_position = world;
	float breeze = wind_strength * foliage_gust(world,wind_time,wind_direction);
	leaf_vivid=smoothstep(-0.75,0.75,sin(VERTEX.x*0.61+VERTEX.y*0.37)*cos(VERTEX.z*0.53));
	float height_bend=pow(clamp(VERTEX.y/(tree_surface ? 2.5 : 0.5),0.0,1.0),1.5);
	float free_tip=pow(clamp((0.40-UV.y)/0.33,0.0,1.0),1.5);
	float base_bend=tree_surface ? pow(clamp(VERTEX.y/4.0,0.0,1.0),2.0)*0.2 : 0.0;
	// Full reserves retain authored posture. Depletion bends the free tip down;
	// weather adds motion over that reversible posture, without moving attachments.
	float bend=base_bend+(bark_surface ? 0.0 : free_tip*height_bend);
	VERTEX.y -= foliage_tip_drop(free_tip*height_bend,reserve_fraction)*reserve_connected;
	// Airflow is world-aligned even when individual plants are rotated/scaled.
	vec3 push = vec3(wind_direction.x,0.0,wind_direction.y) * sin(wind_time * 1.3 + world.x * 1.7 + world.z) * breeze * 0.10 * bend;
	VERTEX += inverse(mat3(MODEL_MATRIX)) * push * length(MODEL_MATRIX[1].xyz);
}
void fragment() {
	// World-anchored stippling spreads the transition across individual leaves,
	// instead of dropping a whole chunk at its batch center. Depth stays opaque.
	if (grass_fade_range.y > 0.0) {
		float grain = fract(sin(dot(floor(grass_position*128.0),vec3(12.9898,78.233,37.719)))*43758.5453);
		if (grain >= grass_visibility) { discard; }
	}
	vec2 uv = UV;
	if (bark_surface) uv*=bark_texture_scale;
	// Reuse the painted pink petal's interior, with geometry owning its outline.
	if (flower_surface) uv = vec2(0.51 + (UV.x - 0.119) * 0.7, 0.40 + (UV.y - 0.23) * 0.24);
	vec4 pigment = texture(painted_atlas, uv);
	if (vastra_surface) pigment.rgb = mix(vec3(dot(pigment.rgb,vec3(0.333))), vec3(0.62,0.76,0.74),0.8);
	vec3 paint = mix(pigment.rgb,vec3(dot(pigment.rgb,vec3(0.21,0.72,0.07))*palette_gain),palette_recolor);
	ALBEDO = paint * COLOR.rgb;
	if (!bark_surface && !vastra_surface && !flower_surface) {
		float vivid=leaf_vivid;
		float grey=dot(ALBEDO,vec3(0.21,0.72,0.07));
		ALBEDO=clamp(mix(vec3(grey),ALBEDO,mix(leaf_saturation_min,leaf_saturation_max,vivid)),vec3(0.0),vec3(1.0));
	}
	// Empty reserves mute the authored pigment without lifting it toward white.
	ALBEDO = mix(ALBEDO,foliage_pigment(ALBEDO,reserve_fraction),reserve_connected);
	ALPHA = pigment.a;
	ALPHA_SCISSOR_THRESHOLD = 0.5;
	ROUGHNESS = 0.9;
	SPECULAR = 0.15;
	NORMAL = FRONT_FACING ? NORMAL : -NORMAL;
	if (bark_surface) NORMAL_MAP = texture(authored_normal,uv).rgb;
	BACKLIGHT = ALBEDO * (bark_surface ? 0.0 : 0.15);
}
