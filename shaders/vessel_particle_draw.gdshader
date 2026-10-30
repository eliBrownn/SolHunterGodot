shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;
uniform float body_scale = 1.0;
uniform float anger = 0.5;
uniform float aberration_pixels = 12.0;
uniform vec4 affinity_tint : source_color = vec4(0.92, 0.84, 0.49, 1.0);
varying float age;
varying vec2 sprite_uv;
void vertex() {
    age = INSTANCE_CUSTOM.x;
    sprite_uv = UV;
    VERTEX *= body_scale * mix(1.0, 0.38, age);
    MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
}
void fragment() {
    vec2 local = (sprite_uv - 0.5) * 2.0;
    float r = length(local);
    float halo = exp(-r * r * 5.5) * (1.0 - smoothstep(0.75, 1.0, r));
    float head = 1.0 - step(0.001, age);
    float core = (1.0 - smoothstep(0.12, 0.38, r)) * head;
    vec2 shift = vec2(aberration_pixels * anger * anger * 0.015, 0.0);
    vec3 glow = vec3(exp(-dot(local + shift, local + shift) * 5.5), halo,
        exp(-dot(local - shift, local - shift) * 5.5));
    vec3 light = affinity_tint.rgb * glow + vec3(core * 0.8);
    ALBEDO = light;
    EMISSION = light * 2.0;
    ALPHA = clamp(halo * mix(0.24, 0.7, head) + core * 0.85, 0.0, 1.0) * pow(1.0 - age, 1.7);
}
