// The ground batches opt in with custom.b, then carry size and density class.
uniform vec2 map_ground_asset_range;

float map_ground_asset_retention(vec4 instance_data, vec2 root, vec2 camera_position) {
	if (instance_data.b < 0.5) {
		return 1.0;
	}
	float distance_to_camera = distance(root, camera_position);
	float tree_distance = distance_to_camera / max(instance_data.r, 0.01);
	float retention = 1.0 - smoothstep(map_ground_asset_range.x, map_ground_asset_range.y, tree_distance);
	if (instance_data.g > 0.5) {
		retention *= 1.0 - smoothstep(56.0, 96.0, distance_to_camera);
	}
	return retention;
}
