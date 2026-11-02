shader_type spatial;
render_mode cull_disabled, unshaded, depth_draw_never;

uniform float animation_time = 0.0;
uniform float travel_amount = 1.0;
uniform float flight_radius = 0.1;
uniform float motion_speed = 0.85;
uniform float anger : hint_range(0.0, 1.0) = 0.0;
uniform float refraction_pixels : hint_range(0.0, 3.0) = 0.55;
uniform float aberration_pixels : hint_range(0.0, 4.0) = 2.0;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;
uniform vec4 affinity_tint : source_color = vec4(0.92, 0.84, 0.49, 1.0);
varying vec4 body_color;

vec3 waypoint(float index, float seed) {
	// Arithmetic hash keeps curve evaluation inexpensive across many small bodies.
	vec3 h = fract(vec3(index + seed) * vec3(0.1031, 0.1030, 0.0973));
	h += dot(h, h.yxz + 33.33);
	h = fract((h.xxy + h.yxx) * h.zyx);
	return (h - 0.5) * vec3(2.0, 1.6, 2.0) * flight_radius;
}

vec3 flight_path(float clock, float seed, out vec3 tangent, out vec3 curvature) {
	float index = floor(clock);
	float f = fract(clock);
	// Continuous speed at joins: linger, accelerate into a swoop, then settle.
	float u = f - 0.82 * sin(f * 6.283185) / 6.283185;
	vec3 a = waypoint(index - 1.0, seed);
	vec3 b = waypoint(index, seed);
	vec3 c = waypoint(index + 1.0, seed);
	vec3 d = waypoint(index + 2.0, seed);
	vec3 c1 = -a + c;
	vec3 c2 = 2.0 * a - 5.0 * b + 4.0 * c - d;
	vec3 c3 = -a + 3.0 * b - 3.0 * c + d;
	tangent = 0.5 * (c1 + 2.0 * c2 * u + 3.0 * c3 * u * u);
	curvature = c2 + 3.0 * c3 * u;
	return 0.5 * (2.0 * b + c1 * u + c2 * u * u + c3 * u * u * u);
}

void vertex() {
	body_color = COLOR;
	float phase = INSTANCE_CUSTOM.r * 6.283185;
	float t = animation_time;
	// Gauzy wing edges drift gently while the radial silhouette stays open.
	float tail = max(UV.x, 0.0);
	VERTEX.x += sin(t * 0.8 - tail * 3.5 + phase) * 0.003 * tail;
	VERTEX.y += sin(t * 0.6 - tail * 2.5 + phase) * 0.004 * tail;
	// C1-continuous 3D flight with tangent pitch/yaw and curvature-driven banking.
	float clock = t * motion_speed * (0.8 + INSTANCE_CUSTOM.r * 0.7) + phase;
	float seed = phase * 13.0;
	vec3 velocity;
	vec3 curvature;
	vec3 at = flight_path(clock, seed, velocity, curvature);
	vec3 forward = normalize(velocity + vec3(0.0, 0.0, -0.000001));
	vec3 right = normalize(vec3(-forward.z, 0.0, forward.x) + vec3(0.00001, 0.0, 0.0));
	vec3 up = normalize(cross(right, forward));
	float bank = clamp(cross(forward, normalize(velocity + curvature * 0.06 + vec3(0.000001))).y * -3.0, -0.5, 0.5);
	vec3 bank_right = right * cos(bank) + up * sin(bank);
	vec3 bank_up = up * cos(bank) - right * sin(bank);
	VERTEX = bank_right * VERTEX.x + bank_up * VERTEX.y - forward * VERTEX.z;
	VERTEX += at * travel_amount;
}

void fragment() {
	float kernel = 1.0 - step(0.0, UV.x);
	float u = clamp(UV.x, 0.0, 1.0);
	float v = UV.y;
	float flow = animation_time * 1.2;
	// Fine origin filament opens into drifting strands; most of the wing is air.
	float guide = exp(-abs(v) * 48.0) * (1.0 - smoothstep(0.38, 0.85, u));
	float curl_a = sin(u * 8.0 - flow) * u * 0.6;
	float curl_b = sin(u * 11.0 - flow * 0.73 + 1.8) * u * 0.62;
	float strand_a = exp(-pow((v - curl_a) * 16.0, 2.0));
	float strand_b = exp(-pow((v - curl_b) * 22.0, 2.0));
	float haze = exp(-pow((v - curl_a) * 4.0, 2.0)) * 0.2;
	float taper = (1.0 - smoothstep(0.75, 1.0, u)) * smoothstep(0.0, 0.08, u);
	float wisp = clamp(guide * 0.8 + (strand_a * 0.5 + strand_b * 0.38 + haze) * taper, 0.0, 1.0);
	vec3 body = mix(body_color.rgb, affinity_tint.rgb, 0.25);
	vec2 pixel = 1.0 / vec2(textureSize(screen_texture, 0));
	vec2 bend = vec2(sin(UV.x * 8.0 + animation_time * 1.3), cos(UV.y * 3.0 + animation_time)) * refraction_pixels * mix(1.0, 2.0, anger);
	float split = 0.12 + aberration_pixels * anger * anger;
	vec2 center = SCREEN_UV + bend * pixel;
	vec3 refracted = vec3(textureLod(screen_texture, center + vec2(split, 0.0) * pixel, 0.0).r,
		textureLod(screen_texture, center, 0.0).g,
		textureLod(screen_texture, center - vec2(split, 0.0) * pixel, 0.0).b);
	ALBEDO = mix(refracted, body, mix(0.45, 1.0, kernel));
	vec3 light_tint = mix(body, affinity_tint.rgb, 0.4);
	EMISSION = light_tint * mix(0.65 + guide * 0.5, 0.65, kernel);
	ALPHA = mix(wisp, 0.85, kernel);
}
