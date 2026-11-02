// Read-only posture/pigment projection. Depletion never implies permanent damage.
uniform float reserve_transition_seconds : hint_range(0.1,3.0) = 1.2;
uniform float reserve_saturation_floor : hint_range(0.0,1.0) = 0.35;
uniform float reserve_droop : hint_range(0.0,0.6) = 0.30;
uniform float wind_gust_strength : hint_range(0.0,1.0) = 0.7;
uniform float wind_gust_seconds : hint_range(2.0,30.0) = 8.0;
uniform float wind_gust_cells : hint_range(4.0,64.0) = 24.0;

float foliage_reserve(vec4 reading, float seconds) {
	float blend = reading.b < 0.0 ? 1.0 : smoothstep(0.0,reserve_transition_seconds,max(0.0,seconds-reading.b));
	return clamp(mix(reading.r,reading.g,blend),0.0,1.0);
}

// Full reserves restore authored leaf posture; roots and leaf attachments stay fixed.
float foliage_tip_drop(float free_tip, float fraction) {
	return free_tip * (1.0 - fraction) * reserve_droop;
}

vec3 foliage_pigment(vec3 authored, float fraction) {
	float grey = dot(authored,vec3(0.21,0.72,0.07));
	return mix(vec3(grey),authored,mix(reserve_saturation_floor,1.0,smoothstep(0.0,1.0,fraction)));
}

float foliage_gust(vec3 absolute_position, float seconds, vec2 direction) {
	// Traveling gust fronts plus local variation; use the saved weather clock
	// and absolute position so pause/origin shifts do not reroll the motion.
	float phase = dot(absolute_position.xz,direction)*6.2831853/max(wind_gust_cells,0.01)-seconds*6.2831853/max(wind_gust_seconds,0.01);
	float front = pow(0.5+0.5*sin(phase+0.35*sin(phase*0.43+absolute_position.z*0.09)),2.0);
	return mix(1.0,0.25+2.0*front,wind_gust_strength);
}
