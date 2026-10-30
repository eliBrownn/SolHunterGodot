shader_type spatial;
render_mode cull_disabled;
uniform sampler2D palette : source_color, filter_linear_mipmap_anisotropic;
uniform vec4 leaf_tint : source_color = vec4(0.56,0.67,0.45,1.0);
uniform float base_height = 0.0;
uniform float plant_height = 1.0;
uniform float normal_up_bias = 0.2;
uniform float backlight_strength = 0.1;
uniform float wind_displacement = 0.018;
uniform float wind_time = 0.0;
uniform vec2 wind_direction = vec2(1.0,0.0);
uniform vec2 world_origin = vec2(0.0);
varying float height_fraction;
void vertex() {
 height_fraction=clamp((VERTEX.y-base_height)/max(plant_height,0.001),0.0,1.0);
 vec3 at=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
 float sway=sin(wind_time*0.8+dot(at.xz+world_origin,vec2(0.47,0.31)));
 vec3 push=vec3(wind_direction.x,0.0,wind_direction.y)*sway*wind_displacement*height_fraction*height_fraction;
 VERTEX+=inverse(mat3(MODEL_MATRIX))*push;
}
void fragment() {
 vec4 sample_color=texture(palette,UV);
 // Tint only green leaf swatches: preserve flower, stem and seed-head palette colors.
 float green=smoothstep(0.01,0.07,sample_color.g-max(sample_color.r,sample_color.b));
 vec3 pigment=mix(sample_color.rgb,sample_color.rgb*leaf_tint.rgb,green);
 ALBEDO=pigment*mix(0.8,1.08,smoothstep(0.0,1.0,height_fraction));
 vec3 up=normalize((VIEW_MATRIX*vec4(0.0,1.0,0.0,0.0)).xyz);
 NORMAL=normalize(mix(FRONT_FACING ? NORMAL : -NORMAL,up,normal_up_bias));
 ROUGHNESS=1.0;
 SPECULAR=0.0;
 BACKLIGHT=ALBEDO*green*backlight_strength;
}
