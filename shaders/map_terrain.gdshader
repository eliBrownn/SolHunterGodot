shader_type spatial;

uniform sampler2D atlas_colors : source_color, filter_linear, repeat_disable;
uniform sampler2D atlas_ground_masks : filter_linear, repeat_disable;
uniform sampler2D atlas_ground_weights : filter_linear, repeat_disable;
uniform sampler2DArray ground_albedos : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2DArray ground_normals : filter_linear_mipmap_anisotropic, repeat_enable;
uniform bool ground_detail_enabled = false;
const float GROUND_TILE_CELLS[5] = {10.0, 5.0, 14.0, 9.0, 12.0};
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
	vec2 atlas_size = vec2(textureSize(atlas_colors, 0));
	vec2 atlas_texel = uv * atlas_size - 0.5;
	vec2 footprint = fwidth(atlas_texel);
	vec2 blend_width = clamp(footprint * 0.5, vec2(0.20), vec2(0.50));
	vec2 blend_weight = smoothstep(vec2(0.5) - blend_width, vec2(0.5) + blend_width, fract(atlas_texel));
	vec2 sharp_uv = (floor(atlas_texel) + 0.5 + blend_weight) / atlas_size;
	float edge_detail = smoothstep(500.0, 850.0, distance_to_view)
		* (1.0 - smoothstep(0.65, 1.0, max(footprint.x, footprint.y)));
	vec3 terrain = texture(atlas_colors, mix(uv, sharp_uv, edge_detail)).rgb;
	float mottling = sin(world_cells.x * 0.19 + sin(world_cells.y * 0.15)) * cos(world_cells.y * 0.23);
	terrain *= 1.0 + mottling * 0.12 * (1.0 - smoothstep(30.0, 160.0, distance_to_view));
	float exposed = smoothstep(45.0, 125.0, elevation) * (1.0 - smoothstep(0.67, 0.98, upness));
	terrain = mix(terrain, vec3(0.24, 0.22, 0.20), exposed * 0.63);

	vec2 field_uv = uv + vec2(sin(world_cells.y * 0.14), cos(world_cells.x * 0.14)) * 4.0 / atlas_extent;
	vec2 ground_masks = in_atlas ? texture(atlas_ground_masks, field_uv).rg : vec2(0.0);
	float irrigated = smoothstep(0.34, 0.68, ground_masks.r);
	float ground_detail = (1.0 - wet_surface)
		* smoothstep(0.28, 0.63, upness)
		* (1.0 - smoothstep(238.0, 700.0, distance_to_view));
	vec2 ground_uv = world_cells * vec2(1.0, -1.0);
	vec2 ground_dx = dFdx(ground_uv);
	vec2 ground_dy = dFdy(ground_uv);
	if (ground_detail_enabled && in_atlas && ground_detail > 0.0) {
		vec4 weights = textureLod(atlas_ground_weights, field_uv, 0.0);
		// The Beach art includes water. Use it along the damp fringe and use
		// the sand layer for the dry portion of the coast.
		float dry_beach = weights.r * (1.0 - smoothstep(0.24, 0.46, flags.a));
		weights.r -= dry_beach;
		weights.b += dry_beach;
		vec3 color_delta = vec3(0.0);
		vec2 bump = vec2(0.0);
		for (int layer = 0; layer < 5; layer++) {
			float weight = layer == 4 ? ground_masks.g : weights[min(layer, 3)];
			if (weight > 0.0) {
				float scale = 1.0 / GROUND_TILE_CELLS[layer];
				vec3 coord = vec3(ground_uv * scale, float(layer));
				vec2 dx = ground_dx * scale;
				vec2 dy = ground_dy * scale;
				color_delta += (textureGrad(ground_albedos, coord, dx, dy).rgb - terrain) * weight;
				bump += (textureGrad(ground_normals, coord, dx, dy).rg * 2.0 - 1.0) * weight;
			}
		}
		terrain += color_delta * ground_detail * 0.88;
		vec3 ground_normal = normalize(NORMAL);
		vec3 world_x = VIEW_MATRIX[0].xyz;
		vec3 tangent = normalize(world_x - ground_normal * dot(world_x, ground_normal));
		vec3 bitangent = cross(ground_normal, tangent);
		NORMAL = normalize(ground_normal + (tangent * bump.x + bitangent * bump.y) * ground_detail * 0.5);
	}
	float rows = 0.87 + 0.13 * smoothstep(0.1, 0.4, abs(fract(world_cells.x / 4.0) - 0.5));
	float field_shade = mix(rows, 0.95, smoothstep(30.0, 200.0, distance_to_view));
	terrain *= mix(1.0, field_shade, irrigated);

	vec2 edge_distance = abs(fract(world_cells + 0.5) - 0.5);
	vec2 pixel = max(fwidth(world_cells), vec2(0.0001));
	vec2 line = 1.0 - smoothstep(vec2(0.0), pixel, edge_distance);
	float grid = max(line.x, line.y) * (1.0 - smoothstep(8.0, 20.0, distance_to_view));
	terrain *= 1.0 - grid * 0.16;

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
