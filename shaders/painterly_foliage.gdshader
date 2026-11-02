shader_type spatial;
render_mode cull_disabled, diffuse_burley;

// Preserve the imported leaf texture and cutout; bark keeps its original material.
uniform sampler2D albedo_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D albedo_texture_nearest : source_color, filter_nearest_mipmap, repeat_enable;
uniform bool nearest_filter = false;
uniform vec4 albedo_tint : source_color = vec4(1.0);
uniform bool vertex_color_albedo = false;
uniform vec2 uv_scale = vec2(1.0);
uniform vec2 uv_offset = vec2(0.0);
uniform float alpha_cutoff : hint_range(0.0, 1.0) = 0.2;
uniform vec4 lower_tint : source_color = vec4(0.78, 0.89, 0.91, 1.0);
uniform vec4 upper_tint : source_color = vec4(1.0, 1.0, 0.83, 1.0);
uniform float color_variation : hint_range(0.0, 0.3) = 0.08;
uniform float gradient_strength : hint_range(0.0, 1.0) = 0.32;
uniform float backlight_strength : hint_range(0.0, 1.0) = 0.3;
uniform float roughness : hint_range(0.0, 1.0) = 0.88;
// Situation palette supplied by a presentation owner, independently of wind.
uniform vec4 mood_shadow : source_color = vec4(1.0);
uniform vec4 mood_light : source_color = vec4(1.0);
uniform vec4 mood_tint : source_color = vec4(1.0);
uniform float mood_saturation : hint_range(0.0, 1.5) = 1.0;
// Local mesh bounds are supplied when adapting each imported surface.
uniform float base_height = 0.0;
uniform float canopy_height = 1.0;
// World-space meters, so model scale does not amplify the sway.
uniform float wind_strength : hint_range(0.0, 0.3) = 0.08;
uniform float wind_speed : hint_range(0.0, 3.0) = 0.8;
uniform vec2 wind_direction = vec2(0.8, 0.3);
// Negative uses live TIME; a nonnegative value freezes a matched review frame.
uniform float preview_time = -1.0;
varying float height_fraction;
varying float patch_variation;

void vertex() {
	height_fraction = clamp((VERTEX.y - base_height) / max(canopy_height, 0.001), 0.0, 1.0);
	vec3 world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float time = (preview_time < 0.0 ? TIME : preview_time) * wind_speed;
	vec2 direction = wind_direction / max(length(wind_direction), 0.001);
	float phase = dot(world.xz, vec2(0.33, 0.24));
	float sway = sin(time + phase) * 0.7 + sin(time * 1.83 + phase * 2.1) * 0.3;
	vec3 displacement = vec3(direction.x, 0.0, direction.y) * sway * wind_strength * height_fraction * height_fraction;
	VERTEX += inverse(mat3(MODEL_MATRIX)) * displacement;
	// Broad variation follows the model, rather than sparkling on individual leaves.
	patch_variation = sin(dot(MODEL_MATRIX[3].xz, vec2(1.37, 2.71)));
}

void fragment() {
	vec2 leaf_uv = UV * uv_scale + uv_offset;
	vec4 leaf = (nearest_filter ? texture(albedo_texture_nearest, leaf_uv) : texture(albedo_texture, leaf_uv)) * albedo_tint;
	if (vertex_color_albedo) { leaf *= COLOR; }
	if (leaf.a < alpha_cutoff) { discard; }
	vec3 gradient = mix(lower_tint.rgb, upper_tint.rgb, smoothstep(0.0, 1.0, height_fraction));
	ALBEDO = leaf.rgb * mix(vec3(1.0), gradient, gradient_strength) * (1.0 + patch_variation * color_variation);
	ALBEDO *= mood_tint.rgb * mix(mood_shadow.rgb, mood_light.rgb, smoothstep(0.0, 1.0, height_fraction));
	float luminance = dot(ALBEDO, vec3(0.2126, 0.7152, 0.0722));
	ALBEDO = max(mix(vec3(luminance), ALBEDO, mood_saturation), vec3(0.0));
	NORMAL = FRONT_FACING ? NORMAL : -NORMAL;
	ROUGHNESS = roughness;
	SPECULAR = 0.15;
	// Light-dependent transmission, not emission: leaves remain dark at night.
	BACKLIGHT = ALBEDO * backlight_strength;
}
