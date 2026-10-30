// Presentation-only material variation in absolute geographic coordinates.
uniform sampler2DArray terrain_palette : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2DArray terrain_normals : filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2DArray terrain_heights : filter_linear_mipmap_anisotropic, repeat_enable;
uniform float terrain_relief_depth : hint_range(0.0, 0.1) = 0.0225;
// Fade subpixel relief/normal detail while retaining geographic color and blends.
// Zero disables the corresponding distance reduction for comparison.
uniform float terrain_relief_distance = 56.0;
uniform float terrain_normal_distance = 88.0;
varying vec3 terrain_view_direction;
uniform bool terrain_palette_enabled = true;
uniform float terrain_tile_size = 4.0;
uniform float terrain_color_strength = 0.45;
uniform float terrain_detail_strength = 0.35;
uniform float terrain_depth_strength : hint_range(0.0, 1.0) = 0.5;
uniform float terrain_region_size = 128.0;
uniform float terrain_palette_seed = 0.0;
uniform float terrain_blend_softness = 1.0;
uniform float terrain_blend_detail = 0.18;
uniform float trail_texture_strength = 0.85;
uniform float terrain_cliff_start_degrees = 32.0;
uniform float terrain_cliff_full_degrees = 52.0;
varying vec2 terrain_blend_weights;
// Evaluate gradients before material branches, keeping mip selection stable at seams.


float terrain_hash(vec2 p) {
	return fract(sin(dot(p + vec2(terrain_palette_seed), vec2(127.1, 311.7))) * 43758.5453);
}

float terrain_region(vec2 p) {
	vec2 cell = floor(p / terrain_region_size);
	vec2 f = smoothstep(vec2(0.0), vec2(1.0), fract(p / terrain_region_size));
	return mix(mix(terrain_hash(cell), terrain_hash(cell + vec2(1.0, 0.0)), f.x),
		mix(terrain_hash(cell + vec2(0.0, 1.0)), terrain_hash(cell + vec2(1.0)), f.x), f.y);
}

// Parallax uses the provided displacement maps. Offset color and normals together.
float terrain_distance_detail(float end_distance) {
	if (end_distance <= 0.0) { return 1.0; }
	return 1.0 - smoothstep(end_distance * 0.6, end_distance, length(terrain_view_direction));
}

vec2 terrain_relief_uv(vec2 uv, float layer, vec2 tangent_view, float normal_view, vec2 dx, vec2 dy) {
	float relief = terrain_relief_depth * terrain_distance_detail(terrain_relief_distance);
	if (relief <= 0.0) { return uv; }
	vec2 travel = tangent_view / max(abs(normal_view), 0.3) * relief;
	travel /= max(1.0, length(travel) / 0.12);
	vec2 current = uv;
	float depth = 0.0;
	float previous_delta = 0.0;
	for (int i = 0; i < 12; i++) {
		float surface_depth = 1.0 - textureGrad(terrain_heights, vec3(current, layer), dx, dy).r;
		float delta = depth - surface_depth;
		if (delta >= 0.0) {
			float weight = delta / max(delta - previous_delta, 0.0001);
			return current + travel / 12.0 * weight;
		}
		previous_delta = delta;
		current -= travel / 12.0;
		depth += 1.0 / 12.0;
	}
	return current;
}

vec2 terrain_top_uv(vec3 p, float layer, vec3 terrain_dx, vec3 terrain_dy) {
	vec3 view = normalize(terrain_view_direction);
	return terrain_relief_uv(p.xz / terrain_tile_size, layer, view.xz, view.y, terrain_dx.xz / terrain_tile_size, terrain_dy.xz / terrain_tile_size);
}

vec3 terrain_layer(vec3 p, vec3 n, float layer, bool rock, vec3 terrain_dx, vec3 terrain_dy) {
	vec2 uv = terrain_top_uv(p, layer, terrain_dx, terrain_dy);
	if (!rock) { return textureGrad(terrain_palette, vec3(uv, layer), terrain_dx.xz / terrain_tile_size, terrain_dy.xz / terrain_tile_size).rgb; }
	vec3 weights = pow(abs(n), vec3(4.0));
	weights /= max(dot(weights, vec3(1.0)), 0.001);
	return textureGrad(terrain_palette, vec3(terrain_relief_uv(p.zy / terrain_tile_size, layer, normalize(terrain_view_direction).zy, normalize(terrain_view_direction).x, terrain_dx.zy / terrain_tile_size, terrain_dy.zy / terrain_tile_size), layer), terrain_dx.zy / terrain_tile_size, terrain_dy.zy / terrain_tile_size).rgb * weights.x
		+ textureGrad(terrain_palette, vec3(uv, layer), terrain_dx.xz / terrain_tile_size, terrain_dy.xz / terrain_tile_size).rgb * weights.y
		+ textureGrad(terrain_palette, vec3(terrain_relief_uv(p.xy / terrain_tile_size, layer, normalize(terrain_view_direction).xy, normalize(terrain_view_direction).z, terrain_dx.xy / terrain_tile_size, terrain_dy.xy / terrain_tile_size), layer), terrain_dx.xy / terrain_tile_size, terrain_dy.xy / terrain_tile_size).rgb * weights.z;
}

vec3 terrain_family(vec3 p, vec3 n, float first, float count, bool rock, vec3 terrain_dx, vec3 terrain_dy) {
	float selection = terrain_region(p.xz + vec2(first * 37.0)) * (count - 1.0);
	float a = floor(selection);
	return mix(terrain_layer(p, n, first + a, rock, terrain_dx, terrain_dy), terrain_layer(p, n, first + min(a + 1.0, count - 1.0), rock, terrain_dx, terrain_dy), smoothstep(0.15, 0.85, fract(selection)));
}

vec3 terrain_stylize(vec3 detail, vec3 tint) {
	float value = dot(detail, vec3(0.2126, 0.7152, 0.0722));
	vec3 soft_color = mix(vec3(value), detail, 0.55);
	return mix(tint, soft_color * tint * 1.8, terrain_color_strength)
		* mix(1.0, clamp(0.8 + value, 0.8, 1.2), terrain_detail_strength);
}

// All material boundaries use the same stable absolute-coordinate blend.
float terrain_blend_weight(vec3 p, float raw_weight) {
 float weight=clamp(raw_weight,0.0,1.0);
 float breakup=sin(dot(p.xz,vec2(1.37,0.91))) * sin(dot(p.xz,vec2(-0.57,1.73)));
 weight=clamp(weight+breakup*terrain_blend_detail*weight*(1.0-weight)*4.0,0.0,1.0);
 return mix(weight,smoothstep(0.0,1.0,weight),terrain_blend_softness);
}

// Shared vertex normals keep this material mask continuous across tile edges.
// Tile-wide movement flags must not stamp square material patches onto hills.
float terrain_rock_weight(vec3 p, vec3 n) {
	float slope = 1.0 - abs(n.y);
	return terrain_blend_weight(p, smoothstep(
		1.0 - cos(radians(terrain_cliff_start_degrees)),
		1.0 - cos(radians(terrain_cliff_full_degrees)), slope));
}

vec3 terrain_surface(vec3 p, vec3 n, vec3 tint, float soil) {
	vec3 terrain_dx = dFdx(p);
	vec3 terrain_dy = dFdy(p);
	float rock = terrain_rock_weight(p,n);
	float path = terrain_blend_weight(p,terrain_blend_weights.x);
	float earth_weight = terrain_blend_weight(p,soil);
	vec3 ground = vec3(0.0);
	// Sample only contributing families. Exact endpoints preserve every blend.
	if (rock < 1.0) {
		if (path < 1.0) {
			if (earth_weight < 1.0) { ground += terrain_stylize(terrain_family(p,n,0.0,3.0,false, terrain_dx, terrain_dy),tint) * (1.0-earth_weight); }
			if (earth_weight > 0.0) { ground += terrain_stylize(terrain_family(p,n,3.0,4.0,false, terrain_dx, terrain_dy),vec3(0.34,0.29,0.20)) * earth_weight; }
		}
		if (path > 0.0) {
			vec3 detail = terrain_layer(p,n,3.0,false, terrain_dx, terrain_dy);
			vec3 trail = mix(terrain_stylize(detail,vec3(0.43,0.35,0.24)),detail*vec3(0.8,0.72,0.6),trail_texture_strength);
			ground = mix(ground,trail,path);
		}
	}
	if (rock > 0.0) { ground = mix(ground,terrain_stylize(terrain_family(p,n,7.0,6.0,true, terrain_dx, terrain_dy),vec3(0.30,0.32,0.29)),rock); }
	return ground;
}

// Supplied OpenGL tangent normals; no color-derived height or mesh displacement.
vec3 terrain_normal_slope(vec2 uv, float layer, vec2 dx, vec2 dy) {
	vec3 detail = textureGrad(terrain_normals, vec3(uv, layer), dx, dy).xyz * 2.0 - 1.0;
	return vec3(detail.xy / max(detail.z, 0.25), 0.0);
}

vec3 terrain_layer_slope(vec3 p, vec3 n, float layer, bool rock, vec3 terrain_dx, vec3 terrain_dy) {
	vec3 top = terrain_normal_slope(terrain_top_uv(p, layer, terrain_dx, terrain_dy), layer, terrain_dx.xz / terrain_tile_size, terrain_dy.xz / terrain_tile_size);
	vec3 slope = vec3(top.x, 0.0, top.y);
	if (rock) {
		vec3 weights = pow(abs(n), vec3(4.0));
		weights /= max(dot(weights, vec3(1.0)), 0.001);
		vec3 side_x = terrain_normal_slope(terrain_relief_uv(p.zy / terrain_tile_size, layer, normalize(terrain_view_direction).zy, normalize(terrain_view_direction).x, terrain_dx.zy / terrain_tile_size, terrain_dy.zy / terrain_tile_size), layer, terrain_dx.zy / terrain_tile_size, terrain_dy.zy / terrain_tile_size);
		vec3 side_z = terrain_normal_slope(terrain_relief_uv(p.xy / terrain_tile_size, layer, normalize(terrain_view_direction).xy, normalize(terrain_view_direction).z, terrain_dx.xy / terrain_tile_size, terrain_dy.xy / terrain_tile_size), layer, terrain_dx.xy / terrain_tile_size, terrain_dy.xy / terrain_tile_size);
		slope = vec3(0.0, side_x.y, side_x.x) * weights.x
			+ slope * weights.y + vec3(side_z.x, side_z.y, 0.0) * weights.z;
	}
	return slope - n * dot(slope, n);
}

vec3 terrain_family_slope(vec3 p, vec3 n, float first, float count, bool rock, vec3 terrain_dx, vec3 terrain_dy) {
	float selection = terrain_region(p.xz + vec2(first * 37.0)) * (count - 1.0);
	float a = floor(selection);
	return mix(terrain_layer_slope(p, n, first + a, rock, terrain_dx, terrain_dy),
		terrain_layer_slope(p, n, first + min(a + 1.0, count - 1.0), rock, terrain_dx, terrain_dy),
		smoothstep(0.15, 0.85, fract(selection)));
}

vec3 terrain_surface_normal(vec3 p, vec3 n, float soil) {
	vec3 terrain_dx = dFdx(p);
	vec3 terrain_dy = dFdy(p);
	float strength = terrain_depth_strength * terrain_distance_detail(terrain_normal_distance);
	if (strength <= 0.0) { return n; }
	float rock = terrain_rock_weight(p,n);
	float path = terrain_blend_weight(p,terrain_blend_weights.x);
	float earth_weight = terrain_blend_weight(p,soil);
	vec3 ground = vec3(0.0);
	if (rock < 1.0) {
		if (path < 1.0) {
			if (earth_weight < 1.0) { ground += terrain_family_slope(p,n,0.0,3.0,false, terrain_dx, terrain_dy) * (1.0-earth_weight); }
			if (earth_weight > 0.0) { ground += terrain_family_slope(p,n,3.0,4.0,false, terrain_dx, terrain_dy) * earth_weight; }
		}
		if (path > 0.0) { ground = mix(ground,terrain_layer_slope(p,n,3.0,false, terrain_dx, terrain_dy),path); }
	}
	if (rock > 0.0) { ground = mix(ground,terrain_family_slope(p,n,7.0,6.0,true, terrain_dx, terrain_dy),rock); }
	return normalize(n + ground * strength);
}
