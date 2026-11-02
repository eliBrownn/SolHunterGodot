// Original SolHunter sky, November 2, 2026. No supplied sky source reused.
shader_type sky;

uniform sampler2D cloud_tex_01 : repeat_enable, filter_linear;
uniform sampler2D cloud_tex_02 : repeat_enable, filter_linear;
uniform vec3 sky_day : source_color = vec3(0.26, 0.53, 0.78);
uniform vec3 horizon_day : source_color = vec3(0.72, 0.83, 0.93);
uniform float cloud_density : hint_range(0.0, 1.0) = 0.65;
uniform vec2 wind_speed = vec2(0.1, 0.035);
uniform float sky_time = 0.0;
uniform float daylight : hint_range(0.0, 1.0) = 1.0;
uniform vec3 sun_direction = vec3(0.0, 1.0, 0.0);
uniform vec3 sun_color : source_color = vec3(1.0, 0.96, 0.86);
uniform vec3 moon_color : source_color = vec3(0.5, 0.6, 0.8);
uniform float horizon_curve = 0.6;
uniform float cloud_scale = 1.0;
uniform float cloud_softness = 0.15;
uniform vec3 cloud_color : source_color = vec3(0.98);
uniform vec3 cloud_shadow : source_color = vec3(0.65, 0.74, 0.83);

void sky() {
	float altitude = max(EYEDIR.y, 0.0);
	vec3 base = mix(horizon_day, sky_day, pow(altitude, max(horizon_curve, 0.05)));
	vec2 drift = wind_speed * sky_time * 0.001;
	vec2 plane = EYEDIR.xz / max(altitude + 0.2, 0.2) * max(cloud_scale, 0.01) * 0.18;
	float noise = texture(cloud_tex_01, plane + drift).r * 0.7;
	noise += texture(cloud_tex_02, plane * 1.9 + drift * 0.6).r * 0.3;
	float softness = max(cloud_softness, 0.01);
	float threshold = mix(1.1, 0.1, cloud_density);
	float clouds = smoothstep(threshold, threshold + softness, noise);
	clouds *= smoothstep(0.0, 0.15, altitude) * step(0.001, cloud_density);
	vec3 lit_cloud = mix(cloud_shadow, cloud_color, noise);
	base = mix(base, lit_cloud, clouds);
	float alignment = dot(EYEDIR, normalize(sun_direction));
	float sun = smoothstep(0.9995, 0.9998, alignment) * daylight;
	float moon = smoothstep(0.9995, 0.9998, -alignment) * (1.0 - daylight);
	COLOR = base + (sun_color * sun + moon_color * moon) * (1.0 - clouds);
}
