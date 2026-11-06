uniform sampler2D atlas_flags : source_color, filter_linear, repeat_disable;
uniform sampler2D atlas_rivers : filter_linear_mipmap, repeat_disable;
uniform vec2 atlas_origin;
uniform vec2 atlas_extent;
uniform float water_detail_start = 150.0;
uniform float water_detail_end = 260.0;

float atlas_water_detail(float distance_to_view) {
	return 1.0 - smoothstep(water_detail_start, water_detail_end, distance_to_view);
}

float atlas_still_water(float mask) {
	return smoothstep(0.46, 0.54, mask);
}

float atlas_water_coverage(vec2 world_cells) {
	vec2 uv = (world_cells - atlas_origin) / atlas_extent;
	if (any(lessThan(uv, vec2(0.0))) || any(greaterThanEqual(uv, vec2(1.0)))) {
		return 1.0;
	}
	float still_water = atlas_still_water(texture(atlas_flags, uv).a);
	return max(still_water, smoothstep(0.40, 0.68, texture(atlas_rivers, uv).r));
}
