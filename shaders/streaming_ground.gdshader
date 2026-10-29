shader_type spatial;

uniform sampler2D ground_atlas : source_color, filter_nearest, repeat_disable;
uniform vec4 grass_uv;
uniform vec4 trail_uv;
uniform vec2 world_origin = vec2(0.0);
varying vec2 ground_position;
varying float ground_kind;

void vertex() {
	ground_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz + world_origin;
	ground_kind = UV.x;
}

void fragment() {
	if (ground_kind > 0.5 && ground_kind < 1.5) {
		ALBEDO = vec3(0.15, 0.32, 0.37);
	} else {
		vec4 region = ground_kind > 1.5 ? trail_uv : grass_uv;
		vec2 atlas_uv = mix(region.xy, region.zw, fract(ground_position));
		ALBEDO = texture(ground_atlas, atlas_uv).rgb * COLOR.rgb;
	}
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
}
