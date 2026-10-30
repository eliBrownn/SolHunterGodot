shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;
#include "res://shaders/vastra_field.gdshaderinc"

uniform sampler2D scene_depth : hint_depth_texture, filter_nearest, repeat_disable;
uniform sampler3D field_noise : filter_linear, repeat_enable;
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform vec4 current_color : source_color = vec4(1.0);
uniform float clock_seconds = 0.0;
uniform float phase = 0.0;
uniform float disturbance = 0.0;
uniform float opacity = 0.07;
uniform float distortion = 0.003;
uniform bool batched = false;
uniform bool network = false;
uniform int diagnostic_surface = 0;
uniform bool wisp_layer = false;
uniform float layer_visibility = 1.0;
uniform float strand_shake = 0.18;
uniform float flow_spread = 0.6;
uniform float spread_distance = 3.0;
uniform float distance_taper = 1.5;
uniform float emission_energy = 3.5;
uniform float haze_strength : hint_range(0.0, 1.0) = 0.4;
uniform float aberration = 0.35;
uniform float fine_detail = 0.55;
uniform float glint_strength = 0.25;
uniform vec3 sun_direction = vec3(0.3, 0.8, 0.3);
uniform vec4 sun_color : source_color = vec4(1.0);
uniform float sun_strength = 1.0;
varying vec3 web_position;
uniform vec3 wind_velocity = vec3(0.7, 0.12, 0.25);
uniform float attraction = 0.8;
uniform float pulse_strength = 0.2;
uniform float pulse_seconds = 6.0;
uniform float active_seconds = 0.0;
varying vec3 ribbon_data;
varying vec3 ribbon_color;
varying vec4 strand_profile;
varying vec4 flight_profile;

float web_noise(vec3 p) {
	return textureLod(field_noise, p / 32.0, 0.0).r;
}

void vertex() {
	ribbon_data = batched ? INSTANCE_CUSTOM.xyz : vec3(phase, disturbance, opacity);
	ribbon_color = batched ? COLOR.rgb : current_color.rgb;
	if (network) {
		strand_profile = CUSTOM0;
		flight_profile = CUSTOM1;
		ribbon_data = vec3(0.0, UV2.y, COLOR.a);
		ribbon_color = COLOR.rgb;
		web_position = VERTEX;
		// Geometry stays world-anchored. Energy advects along its spatial paths below.
	} else {
		float flow = UV.x * 7.0 - clock_seconds * 0.7 + ribbon_data.x;
		VERTEX.y += sin(flow) * 0.08 + ribbon_data.y * sin(flow * 3.3 + clock_seconds * 2.0) * 0.16;
	}
}

// Complement the palette hue in sRGB, then return to linear light for rendering.
vec3 complementary_color(vec3 linear_color) {
	vec3 srgb = mix(linear_color * 12.92, 1.055 * pow(max(linear_color, vec3(0.0)), vec3(1.0 / 2.4)) - 0.055, step(vec3(0.0031308), linear_color));
	float high = max(srgb.r, max(srgb.g, srgb.b));
	float low = min(srgb.r, min(srgb.g, srgb.b));
	vec3 opposite = vec3(high + low) - srgb;
	return mix(opposite / 12.92, pow((opposite + 0.055) / 1.055, vec3(2.4)), step(vec3(0.04045), opposite));
}

vec2 background_uv(vec2 candidate, vec2 original, float surface_depth) {
	// Forward+ reverse-Z: do not pull nearer scenery onto a current behind it.
	float sampled_depth = textureLod(scene_depth, candidate, 0.0).r;
	return sampled_depth > surface_depth + 0.00001 ? original : candidate;
}

void fragment() {
	if (network) {
		// One broad transparent carrier contains folds at several evolving scales.
		float color_spread = max(ribbon_color.r, max(ribbon_color.g, ribbon_color.b)) - min(ribbon_color.r, min(ribbon_color.g, ribbon_color.b));
		bool neutral = color_spread < 0.025;
		// Neutral density has no invented tile affinity; light dispersion supplies optical fringes.
		vec3 optical_primary = neutral ? vec3(0.18, 0.42, 0.55) : ribbon_color;
		vec3 optical_secondary = complementary_color(optical_primary);
		float intensity = smoothstep(0.15, 0.9, UV2.x);
		float open_space = vastra_sol_openness(web_position);
		// Soft contact and camera fade use reconstructed view depth, not explorer distance.
		float depth = textureLod(scene_depth, SCREEN_UV, 0.0).r;
		vec4 ground_view = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, depth, 1.0);
		float scene_distance = -ground_view.z / ground_view.w;
		float surface_distance = -VERTEX.z;
		float contact = smoothstep(0.0, 0.45, scene_distance - surface_distance);
		float radius_fade = contact * smoothstep(0.2, 1.2, surface_distance);
		if (open_space <= 0.001 || radius_fade <= 0.001 || (diagnostic_surface == 0 && ribbon_data.z <= 0.001)) {
			discard;
		}
		float t = clock_seconds * (0.35 + length(wind_velocity) * 0.25 + attraction * 0.4);
		bool finite_stream = flight_profile.w > 0.5;
		if (finite_stream) {
			float elapsed = active_seconds - flight_profile.x;
			// A budget-delayed credit keeps the real packet at B; only its delivered
			// tail expires. Rendering never removes or credits the pending energy.
			if (flight_profile.w > 1.5) { elapsed = min(elapsed, flight_profile.y); }
			if (elapsed < 0.0 || elapsed > flight_profile.y * (1.0 + strand_profile.y / max(flight_profile.z, 0.001))) { discard; }
			t = elapsed / max(flight_profile.y, 0.001) * flight_profile.z;
		}
		float transport = UV.x - t;
		// Stretch low-frequency variation along the flow: long air folds, no closed isocontours.
		vec3 p = vec3((UV.x - t) * 1.6, UV.y * 5.0, web_position.y * 0.2);
		vec3 variation = textureLod(field_noise, p / 48.0, 0.0).rgb;
		float broad = variation.r;
		float middle = variation.g;
		float small = variation.b;
		// Layered astral dust: stretched mist broken by finer dark lanes.
		vec3 dust = textureLod(field_noise, p * vec3(0.65, 2.2, 1.0) / 24.0 + vec3(0.31, 0.57, 0.13), 0.0).rgb;
		float cross_flow = UV.y * 2.0 - 1.0;
		// Shake the threads inside their existing carrier; anchored endpoints and
		// clearance/culling bounds remain unchanged and the clock still freezes.
		float dispersion = finite_stream ? 1.0 + flow_spread * min(UV.x / max(spread_distance, 0.1), 4.0) : 1.0;
		// Reuse the broad advected noise for irregular bends without a rhythmic shake
		// or another texture sample; these same folds already move with the flow.
		float wiggle = clamp((broad - 0.5) * 2.0 + (middle - 0.5), -1.0, 1.0);
		float ripple = min(strand_shake * strand_profile.z * dispersion, 0.38) * wiggle;
		float shift = (broad - 0.5) * 0.25;
		float folds = exp(-pow((cross_flow - shift) * 1.7, 2.0)) * (0.45 + broad * 0.55);
		// Thin, soft strands carry energy; the broad carrier is only refractive space.
		float pixel_width = max(fwidth(UV.y) * 0.9, 0.022);
		// Preserve broad wandering while thinning visible fibers with distance.
		// The pixel floor keeps the head perceptible through its actual arrival.
		float sizing = finite_stream ? max(0.08, 1.0 / (1.0 + distance_taper * max(UV.x, 0.0) / max(spread_distance, 0.1))) : 1.0;
		float fiber_a = exp(-pow((UV.y - (0.25 + ripple + shift * 0.5 + (dust.g - 0.5) * 0.12)) / max(pixel_width, 0.04 * sizing), 2.0));
		float fiber_b = exp(-pow((UV.y - (0.50 + ripple - shift * 0.4 + (dust.r - 0.5) * 0.18)) / max(pixel_width, 0.03 * sizing), 2.0));
		float fiber_c = exp(-pow((UV.y - (0.73 + ripple + shift * 0.3 + (dust.b - 0.5) * 0.10)) / max(pixel_width, 0.035 * sizing), 2.0));
		float filaments = (fiber_a * 0.16 + fiber_b + fiber_c * 0.12) * fine_detail;
		float dust_lane = smoothstep(0.28, 0.65, dust.g) * smoothstep(0.2, 0.65, broad);
		float star_mist = folds * smoothstep(0.22, 0.7, dust.r) * (0.25 + 0.75 * middle) * (1.0 - dust_lane * 0.8) * fine_detail;
		// Continuous advected samples avoid cell-ID changes that pop between frames.
		float star_footprint = length(fwidth(vec2(transport * 3.0, UV.y * 12.0)));
		float star = smoothstep(0.76, 0.94, dust.b) * smoothstep(0.6, 0.85, small) * filaments * glint_strength * (1.0 - smoothstep(0.6, 1.8, star_footprint));
		float transverse = abs(cross_flow);
		float soft_edges = 1.0 - smoothstep(0.4, 1.0, transverse);
		// A shared phase carries brief impulses through branches and junctions.
		float signal_phase = (UV.x - t) * 6.2831853 / pulse_seconds;
		float signal = pow(max(0.0, sin(signal_phase)), 8.0);
		float pulse = 1.0 + pulse_strength * signal;
		float travel = (0.2 + 0.8 * smoothstep(0.25, 0.75, broad)) * (0.65 + 0.35 * sin(transport));
		// Refraction and intermittent wisps have separate coverage and material layers.
		// A short leading edge and long fading tail make travel direction legible.
		float tail_length = max(strand_profile.y, 0.8);
		float head_width = min(0.18, tail_length * 0.18);
		float behind_head = finite_stream ? t - UV.x + head_width : mod(t - UV.x, max(strand_profile.x, 3.0));
		float head = exp(-pow((behind_head - head_width) / head_width, 2.0));
		float streak = smoothstep(0.0, 0.12, behind_head) * exp(-max(0.0, behind_head - head_width) / (tail_length * 0.32)) * (1.0 - smoothstep(tail_length * 0.76, tail_length, behind_head));
		float packet = 0.001 + streak + head * 1.3;
		// Soft astral matter connects the sparse bright threads even between packets.
		float nebula = star_mist * haze_strength;
		float cloud_density = (0.35 + dust.r * 0.65) * (1.0 - dust_lane * 0.8);
		float coverage = soft_edges * (wisp_layer ? (filaments * 0.9 + nebula * 0.1) * packet + star * 0.15 : folds * (0.065 + haze_strength * 0.22) * cloud_density * (0.04 + 0.96 * clamp(streak + head, 0.0, 1.0))) * pulse * (1.0 + UV2.y * 0.25);
		vec2 path_screen = vec2(dFdx(UV.x), dFdy(UV.x));
		vec2 slope = normalize(path_screen + vec2(0.001)) * (0.35 + broad * 0.65) + vec2(middle - 0.5, small - 0.5) * 0.06;
		vec2 offset = slope * (wisp_layer ? 0.0 : distortion) * soft_edges * (0.2 + intensity * 0.8) * open_space;
		vec2 separation = slope * (wisp_layer ? 0.0 : distortion) * aberration * (0.15 + intensity * 0.85) * (folds + filaments) * soft_edges * open_space;
		vec3 refracted = vec3(0.0);
		if (!wisp_layer) {
			vec2 safe_uv = background_uv(clamp(SCREEN_UV + offset, vec2(0.001), vec2(0.999)), SCREEN_UV, FRAGCOORD.z);
			vec3 base = textureLod(screen_texture, safe_uv, 0.0).rgb;
			vec3 first = textureLod(screen_texture, background_uv(clamp(safe_uv + separation, vec2(0.001), vec2(0.999)), SCREEN_UV, FRAGCOORD.z), 0.0).rgb;
			vec3 second = textureLod(screen_texture, background_uv(clamp(safe_uv - separation, vec2(0.001), vec2(0.999)), SCREEN_UV, FRAGCOORD.z), 0.0).rgb;
			// Opposite optical colors weight the separated images; no permanent rainbow outline.
			vec3 weights = optical_primary / max(optical_primary + optical_secondary, vec3(0.001));
			refracted = neutral ? vec3(first.r, base.g, second.b) : mix(second, first, weights);
		}
		vec3 view_world = normalize((INV_VIEW_MATRIX * vec4(VIEW, 0.0)).xyz);
		vec3 surface_normal = normalize(cross(dFdx(web_position), dFdy(web_position)));
		if (dot(surface_normal, view_world) < 0.0) { surface_normal = -surface_normal; }
		vec3 fold_normal = normalize(surface_normal + vec3(slope.x, 0.0, slope.y) * 0.15);
		vec3 halfway = normalize(normalize(sun_direction) + view_world);
		float glint = pow(max(0.0, dot(fold_normal, halfway)), 12.0) * filaments * glint_strength * clamp(sun_strength, 0.0, 2.0);
		vec3 fringe = mix(optical_secondary, optical_primary, smoothstep(-0.25, 0.25, cross_flow - shift));
		ALBEDO = wisp_layer ? fringe * (0.5 + clamp(sun_strength, 0.0, 1.0) * 0.4) : mix(refracted, fringe, nebula * 0.7);
		// Transparent air needs a sparse light-catching cue even over low-contrast grass.
		float light_catch = clamp(sun_strength, 0.0, 1.5) * (0.2 + 0.8 * max(0.0, dot(fold_normal, normalize(sun_direction))));
		float night = 1.0 - smoothstep(0.05, 0.65, sun_strength);
		EMISSION = wisp_layer ? (mix(fringe, vec3(1.0), head * 0.6) * (1.0 + head * 2.0 + night * 0.5 + glint * 0.5) + mix(fringe, vec3(1.0), 0.35) * star * 1.5) * open_space : fringe * haze_strength * cloud_density * (0.25 + night * 0.35) * open_space;
		EMISSION *= emission_energy;
		ALPHA = layer_visibility * clamp(ribbon_data.z * coverage * (wisp_layer ? 8.0 : 5.0) * radius_fade * open_space, 0.0, wisp_layer ? 0.55 : 0.22);
		if (diagnostic_surface == 1) {
			ALBEDO = vec3(1.0, 0.0, 0.8);
			EMISSION = vec3(0.5, 0.0, 0.4);
			ALPHA = radius_fade * 0.8;
		} else if (diagnostic_surface == 2) {
			ALBEDO = vec3(ribbon_data.z * 3.0);
			EMISSION = vec3(0.0);
			ALPHA = radius_fade;
		}

	} else {
		float flow = UV.x * (network ? 1.0 : 14.0) - clock_seconds * 1.4 + ribbon_data.x;
		float center = network ? 0.5 : 0.5 + sin(flow) * (0.10 + ribbon_data.y * 0.18);
		float strand = exp(-abs(UV.y - center) * 35.0);
		float ends = network ? 1.0 : smoothstep(0.0, 0.14, UV.x) * smoothstep(0.0, 0.14, 1.0 - UV.x);
		float surge = 1.0 + ribbon_data.y * pow(max(0.0, sin(clock_seconds * 3.0 + ribbon_data.x)), 8.0) * 2.0;
		vec2 offset = vec2(sin(flow), cos(flow * 0.7)) * distortion * ends * (1.0 + ribbon_data.y);
		vec3 refracted = textureLod(screen_texture, SCREEN_UV + offset, 0.0).rgb;
		ALBEDO = mix(refracted, ribbon_color, strand * 0.45);
		EMISSION = ribbon_color * strand * 0.22 * surge;
		ALPHA = clamp(ribbon_data.z * ends * (0.3 + strand) * surge, 0.0, 0.75);
	}
}
