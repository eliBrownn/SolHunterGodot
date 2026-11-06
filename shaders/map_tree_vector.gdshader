shader_type spatial;
render_mode cull_disabled, unshaded;

#include "res://shaders/map_tree_hue.gdshaderinc"

void vertex() {
	map_tree_hue = INSTANCE_CUSTOM.ra;
	mat4 world_to_tree = inverse(MODEL_MATRIX);
	vec3 camera = (world_to_tree * vec4(INV_VIEW_MATRIX[3].xyz, 1.0)).xyz;
	bool side = abs(camera.x) > abs(camera.z);
	if ((UV.x > 0.5) != side) {
		VERTEX = vec3(0.0);
	} else {
		vec2 world_heading = normalize(INV_VIEW_MATRIX[3].xz - MODEL_MATRIX[3].xz);
		vec3 right = vec3(world_heading.y, 0.0, -world_heading.x);
		float orientation = side ? -sign(camera.x) : sign(camera.z);
		vec3 tree_right = mat3(world_to_tree) * right * length(MODEL_MATRIX[0].xyz);
		VERTEX = tree_right * VERTEX.x * orientation + vec3(0.0, VERTEX.y, 0.0);
	}
}

void fragment() {
	ALBEDO = COLOR.a > 0.5 ? shift_map_tree_hue(COLOR.rgb) : COLOR.rgb;
}
