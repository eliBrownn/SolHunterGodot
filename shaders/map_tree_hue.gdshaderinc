// Hue is stored in custom.r as turns. Custom.a opts map trees into recoloring.
varying vec2 map_tree_hue;

vec3 shift_map_tree_hue(vec3 color) {
	if (map_tree_hue.y < 0.5 || map_tree_hue.x == 0.0) {
		return color;
	}
	// Rotate saturated colors around the neutral axis while preserving lightness.
	vec3 axis = vec3(0.577350269);
	float angle = TAU * map_tree_hue.x;
	return max(vec3(0.0), color * cos(angle) + cross(axis, color) * sin(angle)
		+ axis * dot(axis, color) * (1.0 - cos(angle)));
}
