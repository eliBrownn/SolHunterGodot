shader_type spatial;
render_mode cull_disabled;

uniform sampler2D painted_atlas : source_color, filter_linear_mipmap_anisotropic;
uniform float leaf_saturation_min : hint_range(0.0,2.0) = 0.65;
uniform float leaf_saturation_max : hint_range(0.0,2.0) = 1.65;
uniform float wind_time = 0.0;
uniform float wind_strength = 0.5;
uniform vec2 wind_direction = vec2(1.0, 0.6);
uniform vec2 world_origin = vec2(0.0);
#include "res://shaders/foliage_condition.gdshaderinc"
uniform bool silhouette_view = false;
varying float reserve_fraction;
varying float reserve_connected;

varying float leaf_vivid;
void vertex() {
	reserve_connected = step(0.5, INSTANCE_CUSTOM.a);
	reserve_fraction = mix(1.0,foliage_reserve(INSTANCE_CUSTOM,wind_time),reserve_connected);
	vec3 world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world.xz += world_origin;
	float breeze = wind_strength * foliage_gust(world,wind_time,wind_direction);
	leaf_vivid=smoothstep(-0.75,0.75,sin(VERTEX.x*0.61+VERTEX.y*0.37)*cos(VERTEX.z*0.53));
	// UV.y=1 is the attached stem end. Weather time also freezes on pause.
	float free_tip = pow(1.0 - UV.y, 1.5);
	// Add reserve posture to wind; attached tips and authored anatomy remain fixed.
	VERTEX.y -= foliage_tip_drop(free_tip,reserve_fraction)*reserve_connected;
	float base_bend=pow(clamp(VERTEX.y/4.0,0.0,1.0),2.0)*0.2;
	float wave = sin(wind_time * 1.3 + world.x * 1.7 + world.z);
	float flutter = sin(wind_time * 2.7 + world.z * 2.3) * 0.02;
	vec3 push = vec3(wind_direction.x,0.0,wind_direction.y) * breeze * (wave * 0.10 * base_bend + (wave * 0.08 + flutter) * free_tip);
	VERTEX += inverse(mat3(MODEL_MATRIX)) * push * length(MODEL_MATRIX[1].xyz);
}

void fragment() {
	// Per-card habitat is carried in vertex alpha; materials stay shared.
	float habitat = floor(COLOR.a * 4.0);
	vec4 region = habitat == 1.0 ? vec4(0.005, 0.45, 0.29, 0.545) : vec4(0.035, 0.035, 0.17, 0.405);
	vec4 paint = texture(painted_atlas, region.xy + UV * region.zw);
	float luminance = dot(paint.rgb, vec3(0.21, 0.72, 0.07));
	float rib = pow(max(0.0, 1.0 - abs(UV.x - 0.5) * 25.0), 2.0);
	ALBEDO = COLOR.rgb * luminance * 1.1 * (1.0 + rib * 0.08);
	{
		float vivid=leaf_vivid;
		float grey=dot(ALBEDO,vec3(0.21,0.72,0.07));
		ALBEDO=clamp(mix(vec3(grey),ALBEDO,mix(leaf_saturation_min,leaf_saturation_max,vivid)),vec3(0.0),vec3(1.0));
	}
	// Empty reserves mute the authored pigment without lifting it toward white.
	ALBEDO=mix(ALBEDO,foliage_pigment(ALBEDO,reserve_fraction),reserve_connected);
	if (silhouette_view) ALBEDO = vec3(0.02);
	ALPHA = paint.a;
	ALPHA_SCISSOR_THRESHOLD = 0.45;
	ROUGHNESS = 0.9;
	SPECULAR = 0.12;
	NORMAL = FRONT_FACING ? NORMAL : -NORMAL;
	BACKLIGHT = ALBEDO * 0.22;
}
