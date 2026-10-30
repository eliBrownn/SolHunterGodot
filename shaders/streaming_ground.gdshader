shader_type spatial;

uniform sampler2D ground_atlas : source_color, filter_nearest, repeat_disable;
uniform vec4 grass_uv;
uniform vec4 trail_uv;
uniform vec4 ground_base_color : source_color = vec4(0.48, 0.57, 0.34, 1.0);
uniform float ground_texture_strength = 0.15;
uniform vec2 world_origin = vec2(0.0);
varying vec2 ground_position;
varying float ground_kind;
varying float cliff;
varying float ground_height;

void vertex() {
	ground_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz + world_origin;
	ground_kind = UV.x;
	cliff = UV.y;
	ground_height = VERTEX.y;
}

void fragment() {
	if (ground_kind > 0.5 && ground_kind < 1.5) {
		ALBEDO = vec3(0.15, 0.32, 0.37);
	} else {
		vec4 region = ground_kind > 1.5 ? trail_uv : grass_uv;
		vec2 atlas_uv = mix(region.xy, region.zw, fract(ground_position));
		ALBEDO = texture(ground_atlas, atlas_uv).rgb * COLOR.rgb;
		if (ground_kind < 0.5) {
			float detail = dot(texture(ground_atlas, atlas_uv).rgb, vec3(0.2126, 0.7152, 0.0722));
			ALBEDO = ground_base_color.rgb * mix(1.0, 0.7 + detail, ground_texture_strength) * COLOR.rgb;
		}
	}
	float strata = 0.5 + 0.5 * sin(ground_height * 5.0);
	vec3 rock = mix(vec3(0.22, 0.24, 0.23), vec3(0.28, 0.29, 0.26), strata);
	ALBEDO = mix(ALBEDO, rock, cliff);
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
}
