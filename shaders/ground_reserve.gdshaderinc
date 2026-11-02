// Canonical cell-center samples, smooth across tile and render-chunk boundaries.
uniform sampler2D ground_reserve_map : filter_nearest, repeat_disable;
uniform bool ground_reserve_enabled = false;
uniform vec2 ground_reserve_origin = vec2(0.0);
uniform float ground_reserve_seconds = 0.0;
uniform float ground_reserve_transition_seconds = 1.2;
uniform float ground_reserve_saturation_floor = 0.35;

// Unknown/nonliving cells carry no vote, rather than a fictitious full reserve.
vec2 ground_cell_reserve(ivec2 pixel) {
	ivec2 size = textureSize(ground_reserve_map,0);
	if (any(lessThan(pixel,ivec2(0))) || any(greaterThanEqual(pixel,size))) { return vec2(0.0); }
	vec4 reading = texelFetch(ground_reserve_map,pixel,0);
	if (reading.a < 0.5) { return vec2(0.0); }
	float t = smoothstep(0.0,ground_reserve_transition_seconds,max(0.0,ground_reserve_seconds-reading.b));
	return vec2(clamp(mix(reading.r,reading.g,t),0.0,1.0),1.0);
}

vec3 ground_reserve_color(vec3 authored, vec2 absolute_position, float grass_weight) {
	if (!ground_reserve_enabled || grass_weight <= 0.0) { return authored; }
	vec2 sample_position = absolute_position-ground_reserve_origin-vec2(0.5);
	ivec2 cell = ivec2(floor(sample_position));
	vec2 blend = smoothstep(vec2(0.0),vec2(1.0),fract(sample_position));
	vec2 reserve = mix(mix(ground_cell_reserve(cell),ground_cell_reserve(cell+ivec2(1,0)),blend.x),
		mix(ground_cell_reserve(cell+ivec2(0,1)),ground_cell_reserve(cell+ivec2(1,1)),blend.x),blend.y);
	if (reserve.y < 0.0001) {
		// A rock/road cell can have no plant of its own. Continue nearby ground
		// pigment across that hole without admitting flora or assigning energy.
		ivec2 nearest = ivec2(round(sample_position));
		for (int radius=1; radius<=4; radius*=2) {
			reserve = ground_cell_reserve(nearest+ivec2(-radius,0))+ground_cell_reserve(nearest+ivec2(radius,0))
				+ground_cell_reserve(nearest+ivec2(0,-radius))+ground_cell_reserve(nearest+ivec2(0,radius));
			if (reserve.y > 0.0001) { break; }
		}
	}
	float fraction = reserve.y > 0.0001 ? reserve.x/reserve.y : 1.0;
	float grey = dot(authored,vec3(0.21,0.72,0.07));
	vec3 pigment = mix(vec3(grey),authored,mix(ground_reserve_saturation_floor,1.0,smoothstep(0.0,1.0,fraction)));
	return mix(authored,pigment,clamp(grass_weight,0.0,1.0));
}
