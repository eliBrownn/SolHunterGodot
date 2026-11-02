shader_type spatial;
render_mode unshaded, depth_test_disabled, depth_draw_never, cull_disabled, blend_mix;

uniform sampler2D actor_texture : source_color, filter_nearest, repeat_disable;
uniform sampler2D scene_depth : hint_depth_texture, filter_nearest, repeat_disable;
uniform vec4 atlas_region = vec4(0.0, 0.0, 1.0, 1.0);
uniform bool flip_h = false;
uniform vec4 silhouette_color : source_color = vec4(0.88, 0.78, 0.53, 0.65);

void fragment() {
	vec2 actor_uv = UV;
	if (flip_h) {
		actor_uv.x = 1.0 - actor_uv.x;
	}
	float alpha = texture(actor_texture, atlas_region.xy + actor_uv * atlas_region.zw).a;
	if (alpha < 0.35) {
		discard;
	}
	float depth = texture(scene_depth, SCREEN_UV).r;
	#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
	vec3 ndc = vec3(SCREEN_UV, depth) * 2.0 - 1.0;
	#else
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth);
	#endif
	vec4 view_position = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	float obstacle_distance = -view_position.z / view_position.w;
	float actor_distance = -VERTEX.z;
	if (obstacle_distance + 0.03 >= actor_distance) {
		discard;
	}
	ALBEDO = silhouette_color.rgb;
	ALPHA = silhouette_color.a;
}
