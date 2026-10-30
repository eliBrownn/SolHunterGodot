shader_type particles;
render_mode disable_velocity;

uniform float animation_time = 0.0;
uniform int member_count = 128;
uniform int trail_samples = 10;
uniform float trail_seconds = 0.45;
uniform float flight_radius = 0.1;
uniform float motion_speed = 0.85;
uniform float spread = 0.8;
uniform float body_scale = 1.0;
uniform bool live_group = false;
uniform float group_seed = 0.0;
uniform float group_radius = 1.0;
uniform bool response_active = false;
uniform bool storm_active = false;
uniform bool recovering = false;

vec3 hash3(float value) {
	vec3 h = fract(vec3(value) * vec3(0.1031, 0.1030, 0.0973));
	h += dot(h, h.yxz + 33.33);
	return fract((h.xxy + h.yxx) * h.zyx);
}

vec3 waypoint(float index, float seed) {
	return (hash3(index + seed) - 0.5) * vec3(2.0, 1.6, 2.0) * flight_radius * body_scale;
}

vec3 flight_path(float clock, float seed) {
	float index = floor(clock);
	float f = fract(clock);
	float u = f - 0.82 * sin(f * 6.283185) / 6.283185;
	vec3 a = waypoint(index - 1.0, seed);
	vec3 b = waypoint(index, seed);
	vec3 c = waypoint(index + 1.0, seed);
	vec3 d = waypoint(index + 2.0, seed);
	return 0.5 * (2.0 * b + (-a + c) * u + (2.0 * a - 5.0 * b + 4.0 * c - d) * u * u + (-a + 3.0 * b - 3.0 * c + d) * u * u * u);
}

void start() {
	COLOR = vec4(1.0);
	TRANSFORM = mat4(1.0);
}

void process() {
	uint stride = uint(trail_samples + 1);
	float member = float(INDEX / stride);
	float age = float(INDEX % stride) / float(trail_samples + 1);
	float seed = hash3(member + 19.7 + group_seed).x;
	float phase = seed * 6.283185;
	float history_time = animation_time - age * trail_seconds;
	float clock = history_time * motion_speed * (0.8 + seed * 0.7) + phase;
	vec3 base = member_count == 1 ? vec3(0.0) : (hash3(member + 71.0) - 0.5) * vec3(spread * 2.0, 0.65, spread * 2.0) + vec3(0.0, 0.175, 0.0);
	TRANSFORM = mat4(1.0);
	TRANSFORM[3].xyz = base + flight_path(clock, phase * 13.0);
	if (live_group) {
		float speed = (0.4 + mod(member, 5.0) * 0.07) * (response_active ? 2.0 : 1.0);
		float angle = history_time * speed * (storm_active ? 0.2 : 0.03) + phase;
		float reach = group_radius * (0.3 + mod(member, 7.0) / 10.0);
		float lift = sin(history_time * 0.8 + phase) * 0.18;
		if (storm_active) { lift += mod(member, 6.0) * 0.24; }
		if (recovering) { lift -= 0.3; }
		TRANSFORM[3].xyz = vec3(cos(angle) * reach, lift, sin(angle * 1.07) * reach) + flight_path(clock, phase * 13.0);
	}
	CUSTOM = vec4(age, seed, 0.0, 1.0);
	COLOR = vec4(1.0);
	ACTIVE = true;
}
