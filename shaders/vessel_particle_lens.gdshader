shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;
uniform float body_scale = 1.0;
uniform float anger = 0.5;
uniform float refraction_pixels = 14.0;
uniform float aberration_pixels = 12.0;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;
varying float age;
void vertex() {
	age = INSTANCE_CUSTOM.x;
	VERTEX *= body_scale;
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
}
void fragment() {
	if (age > 0.001) { discard; }
	vec2 local = (UV - 0.5) * 2.0;
	float r = length(local);
	if (r >= 1.0) { discard; }
	vec2 pixel = 1.0 / vec2(textureSize(screen_texture, 0));
	vec2 direction = local / max(r, 0.001);
	float falloff = sin(r * 3.141593);
	// Almost still when calm; the anger slider smoothly opens the lens.
	float bend = refraction_pixels * (0.005 + 1.995 * anger * anger) * falloff;
	vec2 center = SCREEN_UV + direction * bend * pixel;
	vec2 split = direction * aberration_pixels * anger * anger * falloff * pixel;
	ALBEDO = vec3(textureLod(screen_texture, center + split, 0.0).r,
		textureLod(screen_texture, center, 0.0).g,
		textureLod(screen_texture, center - split, 0.0).b);
	ALPHA = smoothstep(0.08, 0.25, r) * (1.0 - smoothstep(0.72, 1.0, r)) * 0.9;
}
