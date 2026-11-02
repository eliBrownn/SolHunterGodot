shader_type spatial;
render_mode cull_disabled;
#include "res://shaders/terrain_palette.gdshaderinc"
uniform vec2 world_origin = vec2(0.0);
uniform bool terrain_trail = false;
varying vec3 terrain_position;
varying vec3 terrain_normal;
uniform sampler2D ground_atlas : source_color, filter_nearest, repeat_disable;
uniform vec4 ground_base_color : source_color = vec4(0.48, 0.57, 0.34, 1.0);
uniform float ground_texture_strength = 0.15;
uniform vec4 wet_bank_color : source_color = vec4(0.45, 0.43, 0.32, 1.0);
uniform vec4 dry_bank_color : source_color = vec4(0.65, 0.60, 0.45, 1.0);
uniform float bank_blend_height : hint_range(0.1, 0.8) = 0.32;
varying float ground_height;

void vertex() {
	terrain_blend_weights = CUSTOM0.xy;
	terrain_woodland = CUSTOM0.z;
	terrain_view_direction = CAMERA_POSITION_WORLD - (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	ground_height = VERTEX.y;
	terrain_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz + vec3(world_origin.x, 0.0, world_origin.y);
	terrain_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
}

void fragment() {
	vec4 texel = texture(ground_atlas, UV);
	float detail = dot(texel.rgb, vec3(0.2126, 0.7152, 0.0722));
	vec4 grass = vec4(ground_base_color.rgb * mix(1.0, 0.7 + detail, ground_texture_strength), 1.0) * COLOR;
	// UV2 carries the same pond level across water- and land-center cells.
	float above_water = ground_height - UV2.x;
	// These are discrete tile flags, not a continuous shoreline coordinate.
	// Interpolation can turn 2.0 into 1.999999: mod then decodes a false shore
	// weight near 2, extrapolating the bank color into noisy stretched patches.
	float tile_flags = floor(UV2.y + 0.5);
	float shore = mod(tile_flags, 2.0) * (1.0 - smoothstep(0.02, bank_blend_height, above_water));
	vec3 bank = mix(wet_bank_color.rgb, dry_bank_color.rgb, smoothstep(0.0, bank_blend_height, above_water));
	ALBEDO = mix(grass.rgb, bank, shore);
	// Exposed stone marks cells rejected by the actual slope admission rule.
	// Height bands help reveal the face's shape without adding collision geometry.
	float cliff = step(1.5, tile_flags);
	float strata = 0.5 + 0.5 * sin(ground_height * 5.0);
	vec3 rock = mix(vec3(0.22, 0.24, 0.23), vec3(0.28, 0.29, 0.26), strata);
	ALBEDO = mix(ALBEDO, rock, cliff * (1.0 - shore));
	if (terrain_palette_enabled) {
		float woodland = terrain_blend_weights.y;
		float soil = max(shore,woodland);
		ALBEDO = terrain_surface(terrain_position, normalize(terrain_normal), grass.rgb, soil);
		NORMAL = normalize((VIEW_MATRIX * vec4(terrain_surface_normal(terrain_position, normalize(terrain_normal), soil), 0.0)).xyz);
		ALBEDO *= mix(1.0, 0.78, shore);
	}
	ROUGHNESS = mix(0.95, 0.7, shore);
	if (!terrain_palette_enabled) { ALBEDO = ground_reserve_color(ALBEDO,terrain_position.xz,(1.0-shore)*(1.0-cliff)); }
	SPECULAR = 0.1;
}
