shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;
uniform sampler2D scene_depth : hint_depth_texture, filter_nearest, repeat_disable;
uniform float clock_seconds = 0.0;
varying float mist_depth;
varying float seed;
void vertex() {
	vec3 center = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	vec4 view_center = VIEW_MATRIX * vec4(center, 1.0);
	float size = length(MODEL_MATRIX[0].xyz);
	VERTEX = vec3(VERTEX.xy * size, 0.0);
	MODELVIEW_MATRIX = mat4(vec4(1,0,0,0), vec4(0,1,0,0), vec4(0,0,1,0), view_center);
	mist_depth = -view_center.z;
	seed = INSTANCE_CUSTOM.x;
}
void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float radial = max(0.0, 1.0 - dot(p, p));
	float veil = radial * radial;
	float detail = 0.65 + 0.35 * sin(p.x * 5.0 + p.y * 3.0 + seed * 50.0 + clock_seconds * 0.4);
	float depth = textureLod(scene_depth, SCREEN_UV, 0.0).r;
	vec4 scenery = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, depth, 1.0);
	float contact = smoothstep(0.0, 0.15, -scenery.z / scenery.w - mist_depth);
	ALBEDO = COLOR.rgb;
	EMISSION = COLOR.rgb * 0.7;
	ALPHA = veil * detail * COLOR.a * contact;
}
