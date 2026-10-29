shader_type spatial;
render_mode unshaded, depth_test_disabled, depth_draw_never, cull_back, blend_mix;
uniform sampler2D scene_depth : hint_depth_texture, filter_nearest, repeat_disable;
uniform vec4 silhouette_color : source_color = vec4(0.88, 0.78, 0.53, 0.65);
// Imported body parts overlap; exclude the model's own surface thickness.
uniform float self_depth_margin = 1.1;
void fragment() {
	float depth = texture(scene_depth, SCREEN_UV).r;
	#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
	vec3 ndc = vec3(SCREEN_UV, depth) * 2.0 - 1.0;
	#else
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth);
	#endif
	vec4 scene_position = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	float obstacle_distance = -scene_position.z / scene_position.w;
	if (obstacle_distance + self_depth_margin >= -VERTEX.z) { discard; }
	ALBEDO = silhouette_color.rgb;
	ALPHA = silhouette_color.a;
}
