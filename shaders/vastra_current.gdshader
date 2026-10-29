shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform vec4 current_color : source_color = vec4(1.0);
uniform float clock_seconds = 0.0;
uniform float phase = 0.0;
uniform float disturbance = 0.0;
uniform float opacity = 0.07;
uniform float distortion = 0.003;
uniform bool batched = false;
varying vec3 ribbon_data;
varying vec3 ribbon_color;

void vertex() {
	ribbon_data = batched ? INSTANCE_CUSTOM.xyz : vec3(phase, disturbance, opacity);
	ribbon_color = batched ? COLOR.rgb : current_color.rgb;
	float flow = UV.x * 7.0 - clock_seconds * 0.7 + ribbon_data.x;
	VERTEX.y += sin(flow) * 0.08 + ribbon_data.y * sin(flow * 3.3 + clock_seconds * 2.0) * 0.16;
}

void fragment() {
	float flow = UV.x * 14.0 - clock_seconds * 1.4 + ribbon_data.x;
	float center = 0.5 + sin(flow) * (0.10 + ribbon_data.y * 0.18);
	float strand = exp(-abs(UV.y - center) * 35.0);
	float ends = smoothstep(0.0, 0.14, UV.x) * smoothstep(0.0, 0.14, 1.0 - UV.x);
	float surge = 1.0 + ribbon_data.y * pow(max(0.0, sin(clock_seconds * 3.0 + ribbon_data.x)), 8.0) * 2.0;
	vec2 offset = vec2(sin(flow), cos(flow * 0.7)) * distortion * ends * (1.0 + ribbon_data.y);
	vec3 refracted = textureLod(screen_texture, SCREEN_UV + offset, 0.0).rgb;
	ALBEDO = mix(refracted, ribbon_color, strand * 0.45);
	EMISSION = ribbon_color * strand * 0.22 * surge;
	ALPHA = clamp(ribbon_data.z * ends * (0.3 + strand) * surge, 0.0, 0.75);
}
