uniform int sol_count = 0;
uniform vec4 sol_voids[16];

float vastra_sol_openness(vec3 point) {
	float openness = 1.0;
	for (int i = 0; i < 16; i++) {
		if (i >= sol_count) { break; }
		vec3 difference = point - sol_voids[i].xyz;
		difference.y *= 0.5;
		openness = min(openness, smoothstep(sol_voids[i].w * 0.25, sol_voids[i].w, length(difference)));
	}
	return openness;
}
