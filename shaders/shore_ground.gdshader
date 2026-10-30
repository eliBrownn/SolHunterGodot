shader_type spatial;
render_mode cull_disabled;
uniform sampler2D ground_atlas : source_color, filter_nearest, repeat_disable;
uniform vec4 ground_base_color : source_color = vec4(0.48, 0.57, 0.34, 1.0);
uniform float ground_texture_strength = 0.15;
uniform vec4 wet_bank_color : source_color = vec4(0.45, 0.43, 0.32, 1.0);
uniform vec4 dry_bank_color : source_color = vec4(0.65, 0.60, 0.45, 1.0);
uniform float bank_blend_height : hint_range(0.1, 0.8) = 0.32;
varying float ground_height;

void vertex() {
	ground_height = VERTEX.y;
}

void fragment() {
	vec4 texel = texture(ground_atlas, UV);
	float detail = dot(texel.rgb, vec3(0.2126, 0.7152, 0.0722));
	vec4 grass = vec4(ground_base_color.rgb * mix(1.0, 0.7 + detail, ground_texture_strength), 1.0) * COLOR;
	// UV2 carries the same pond level across water- and land-center cells.
	float above_water = ground_height - UV2.x;
	float shore = mod(UV2.y, 2.0) * (1.0 - smoothstep(0.02, bank_blend_height, above_water));
	vec3 bank = mix(wet_bank_color.rgb, dry_bank_color.rgb, smoothstep(0.0, bank_blend_height, above_water));
	ALBEDO = mix(grass.rgb, bank, shore);
	// Exposed stone marks cells rejected by the actual slope admission rule.
	// Height bands help reveal the face's shape without adding collision geometry.
	float cliff = step(1.5, UV2.y);
	float strata = 0.5 + 0.5 * sin(ground_height * 5.0);
	vec3 rock = mix(vec3(0.22, 0.24, 0.23), vec3(0.28, 0.29, 0.26), strata);
	ALBEDO = mix(ALBEDO, rock, cliff * (1.0 - shore));
	ROUGHNESS = mix(0.95, 0.7, shore);
	SPECULAR = 0.1;
}
