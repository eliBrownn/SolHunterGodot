shader_type spatial;

uniform bool cool_water_enabled = false;
#include "res://shaders/map_water_mask.gdshaderinc"
varying vec2 world_cells;
varying float elevation;
varying float upness;

void vertex() {
	vec3 world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_cells = world_position.xz;
	elevation = world_position.y;
	upness = (MODEL_NORMAL_MATRIX * NORMAL).y;
}

void fragment() {
	vec2 uv = (world_cells - atlas_origin) / atlas_extent;
	bool in_atlas = all(greaterThanEqual(uv, vec2(0.0))) && all(lessThan(uv, vec2(1.0)));
	vec4 flags = texture(atlas_flags, uv);
	float still_water = in_atlas ? atlas_still_water(flags.a) : 1.0;
	float river = in_atlas ? texture(atlas_rivers, uv).r : 0.0;
	float wet_surface = max(still_water, smoothstep(0.40, 0.68, river));
	float distance_to_view = length(VERTEX);

	// Narrow distant biome color transitions without switching to nearest
	// sampling. Subpixel atlas cells keep their regular filtered blend.
	vec2 atlas_size = vec2(textureSize(atlas_flags, 0));
	vec2 atlas_texel = uv * atlas_size - 0.5;
	vec2 footprint = fwidth(atlas_texel);
	vec2 blend_width = clamp(footprint * 0.5, vec2(0.20), vec2(0.50));
	vec2 blend_weight = smoothstep(vec2(0.5) - blend_width, vec2(0.5) + blend_width, fract(atlas_texel));
	vec2 sharp_uv = (floor(atlas_texel) + 0.5 + blend_weight) / atlas_size;
	float edge_detail = smoothstep(500.0, 850.0, distance_to_view)
		* (1.0 - smoothstep(0.65, 1.0, max(footprint.x, footprint.y)));
	vec3 terrain = texture(atlas_flags, mix(uv, sharp_uv, edge_detail)).rgb;
	float exposed = smoothstep(45.0, 125.0, elevation) * (1.0 - smoothstep(0.67, 0.98, upness));
	terrain = mix(terrain, vec3(0.24, 0.22, 0.20), exposed * 0.63);

	vec3 sea = vec3(0.041, 0.115, 0.184);
	vec3 water = mix(vec3(0.045, 0.23, 0.34), in_atlas ? flags.rgb : sea, still_water);
	float waves = sin(world_cells.x * 0.28 + world_cells.y * 0.13 + TIME * 0.8) * sin(world_cells.y * 0.23 - TIME * 0.7);
	water *= 1.0 + waves * 0.09 * (1.0 - smoothstep(24.0, 140.0, distance_to_view));
	if (cool_water_enabled) {
		vec3 sediment = vec3(0.17, 0.14, 0.095);
		water = mix(water, sediment, 0.72 * atlas_water_detail(distance_to_view));
	}
	ALBEDO = mix(terrain, water, wet_surface);
	ROUGHNESS = mix(1.0, 0.34, wet_surface);
}
