shader_type spatial;
render_mode cull_disabled;
uniform sampler2D ground_atlas : source_color, filter_nearest, repeat_disable;
uniform vec4 wet_bank_color : source_color = vec4(0.45, 0.43, 0.32, 1.0);
uniform vec4 dry_bank_color : source_color = vec4(0.65, 0.60, 0.45, 1.0);
uniform float bank_blend_height : hint_range(0.1, 0.8) = 0.32;
varying float ground_height;

void vertex() {
	ground_height = VERTEX.y;
}

void fragment() {
	vec4 grass = texture(ground_atlas, UV) * COLOR;
	// UV2 carries the same pond level across water- and land-center cells.
	float above_water = ground_height - UV2.x;
	float shore = UV2.y * (1.0 - smoothstep(0.02, bank_blend_height, above_water));
	vec3 bank = mix(wet_bank_color.rgb, dry_bank_color.rgb, smoothstep(0.0, bank_blend_height, above_water));
	ALBEDO = mix(grass.rgb, bank, shore);
	ROUGHNESS = mix(0.95, 0.7, shore);
	SPECULAR = 0.1;
}
