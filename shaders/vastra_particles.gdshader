shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;
#include "res://shaders/vastra_field.gdshaderinc"
uniform sampler2D particle_texture : source_color, filter_linear_mipmap;
uniform sampler2D scene_depth : hint_depth_texture, filter_nearest, repeat_disable;
uniform float layer_visibility = 1.0;
uniform float emission_energy = 3.5;
varying vec3 field_position;
varying float particle_depth;
void vertex() {
	field_position = INSTANCE_CUSTOM.xyz;
	vec3 center = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	vec4 view_center = VIEW_MATRIX * vec4(center, 1.0);
	float size = length(MODEL_MATRIX[0].xyz);
	VERTEX = vec3(VERTEX.xy * size, 0.0);
	MODELVIEW_MATRIX = mat4(vec4(1.0, 0.0, 0.0, 0.0), vec4(0.0, 1.0, 0.0, 0.0), vec4(0.0, 0.0, 1.0, 0.0), view_center);
	particle_depth = -view_center.z;
}
void fragment() {
	float depth = textureLod(scene_depth, SCREEN_UV, 0.0).r;
	vec4 scenery = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, depth, 1.0);
	float contact = smoothstep(0.0, 0.18, -scenery.z / scenery.w - particle_depth);
	float light = texture(particle_texture, UV).a;
	ALBEDO = COLOR.rgb;
	EMISSION = COLOR.rgb * emission_energy;
	ALPHA = light * COLOR.a * contact * layer_visibility * vastra_sol_openness(field_position);
}
