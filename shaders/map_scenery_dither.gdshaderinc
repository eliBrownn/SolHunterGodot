// Complementary screen-door masks keep both representations depth-tested.
global uniform float map_coverage_mix;
instance uniform float map_coverage_role : instance_index(0) = 0.0;
instance uniform vec2 map_lod_dither : instance_index(1) = vec2(1.0, 0.0);
instance uniform float map_plant_visibility : instance_index(2) = 1.0;

float map_dither_rank(vec2 pixel) {
	return fract(52.9829189 * fract(dot(floor(pixel), vec2(0.06711056, 0.00583715))));
}

bool map_coverage_visible(vec2 pixel) {
	if (map_coverage_role == 0.0) {
		return true;
	}
	float rank = map_dither_rank(pixel);
	return map_coverage_role > 0.0 ? rank < map_coverage_mix : rank >= map_coverage_mix;
}

bool map_lod_visible(vec2 pixel) {
	if (map_plant_visibility < 1.0 && map_dither_rank(pixel + vec2(41.0, 11.0)) >= map_plant_visibility) {
		return false;
	}
	if (map_lod_dither.y == 0.0) {
		return true;
	}
	float rank = map_dither_rank(pixel + vec2(23.0, 47.0));
	return map_lod_dither.y > 0.0 ? rank < map_lod_dither.x : rank >= map_lod_dither.x;
}
