shader_type sky;

// Uses the owner's two procedural cloud textures with a daylight/night gradient.
uniform sampler2D cloud_tex_01 : filter_linear, repeat_enable;
uniform sampler2D cloud_tex_02 : filter_linear, repeat_enable;
uniform vec4 sky_day : source_color = vec4(0.2, 0.45, 0.75, 1.0);
uniform vec4 horizon_day : source_color = vec4(0.7, 0.83, 0.93, 1.0);
uniform float horizon_curve = 0.4;
uniform vec2 wind_speed = vec2(0.1, 0.035);
uniform float sky_time = 0.0;
uniform float cloud_scale = 0.16;
uniform float cloud_density = 0.35;
uniform float cloud_softness = 0.12;
uniform vec4 cloud_color : source_color = vec4(0.97, 0.98, 1.0, 1.0);
uniform vec4 cloud_shadow : source_color = vec4(0.65, 0.75, 0.86, 1.0);
uniform vec3 sun_direction = vec3(0.0, 0.8, 0.6);
uniform vec4 sun_color : source_color = vec4(1.0, 0.94, 0.82, 1.0);
uniform vec4 moon_color : source_color = vec4(0.64, 0.78, 0.95, 1.0);
uniform float daylight = 1.0;

float hash21(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void sky() {
	vec3 ray = normalize(EYEDIR);
	float height = clamp(ray.y, 0.0, 1.0);
	vec3 color = mix(horizon_day.rgb, sky_day.rgb, pow(height, horizon_curve));
	vec2 uv = ray.xz / max(ray.y, 0.04) * cloud_scale + wind_speed * sky_time * 0.01;
	float primary = texture(cloud_tex_01, uv).r;
	float secondary = texture(cloud_tex_02, uv * 1.7 + vec2(0.31, 0.17)).r;
	float shape = primary * 0.75 + secondary * 0.25;
	float threshold = mix(0.78, 0.2, cloud_density);
	float clouds = smoothstep(threshold, threshold + cloud_softness, shape);
	clouds *= smoothstep(0.08, 0.25, ray.y) * step(0.001, cloud_density);
	vec3 cloud_light = mix(cloud_shadow.rgb, cloud_color.rgb, smoothstep(threshold, 0.85, primary));
	color = mix(color, cloud_light, clouds);
	float sun_dot = dot(ray, normalize(sun_direction));
	float sun_disc = smoothstep(cos(0.013), cos(0.01), sun_dot);
	float sun_halo = pow(max(sun_dot, 0.0), 350.0) * 0.14;
	color += sun_color.rgb * (sun_disc * 2.0 + sun_halo) * (1.0 - clouds) * smoothstep(-0.02, 0.04, sun_direction.y);
	float moon_dot = dot(ray, -normalize(sun_direction));
	float moon_disc = smoothstep(cos(0.011), cos(0.008), moon_dot);
	color += moon_color.rgb * moon_disc * (1.0 - clouds) * (1.0 - daylight) * 1.2;
	vec2 star_uv = SKY_COORDS * vec2(1200.0, 600.0);
	vec2 star_cell = floor(star_uv);
	float star_shape = 1.0 - smoothstep(0.1, 0.45, length(fract(star_uv) - 0.5));
	float stars = step(0.998, hash21(star_cell)) * hash21(star_cell + 17.0) * star_shape;
	color += vec3(stars) * (1.0 - daylight) * (1.0 - clouds) * smoothstep(0.0, 0.15, ray.y);
	COLOR = color;
}
