shader_type canvas_item;
render_mode unshaded;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform float pixel_divisor : hint_range(1.0, 3.0) = 1.75;
void fragment() {
	vec2 grid = max(vec2(1.0), floor(vec2(textureSize(screen_texture, 0)) / pixel_divisor + 0.5));
	vec2 sample_uv = (floor(SCREEN_UV * grid) + 0.5) / grid;
	COLOR = textureLod(screen_texture, sample_uv, 0.0);
}
