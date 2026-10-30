shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never;
uniform float glow_strength = 0.03;
uniform float disruption = 0.0;
uniform vec3 packet_position = vec3(0.0);
uniform bool packet_active = false;
varying float fissure;
varying vec3 world_point;
void vertex() {
	fissure = COLOR.a;
	world_point = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
void fragment() {
	float pulse = packet_active ? exp(-distance(world_point, packet_position) * 14.0) * 0.4 : 0.0;
	float uneven = mix(1.0, step(0.35, fract(dot(world_point, vec3(1.9, 2.7, 1.3)))), clamp(disruption, 0.0, 1.0));
	ALBEDO = vec3(0.65, 0.72, 0.77);
	ALPHA = clamp(fissure * (glow_strength + pulse) * uneven, 0.0, 0.65);
}
