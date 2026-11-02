shader_type spatial;
render_mode cull_disabled, alpha_to_coverage;
uniform sampler2D albedo_texture : source_color, filter_linear_mipmap_anisotropic;
uniform bool textured = false;
uniform vec4 ground_base_color : source_color = vec4(0.48,0.57,0.34,1.0);
uniform float base_height = 0.0;
uniform float blade_length = 1.0;
uniform float wind_strength = 1.0;
uniform vec2 wind_direction = vec2(1.0,0.0);
uniform float wind_time = 0.0;
#include "res://shaders/foliage_condition.gdshaderinc"
varying float reserve_fraction;
varying float reserve_connected;
uniform float wind_displacement = 0.045;
uniform float wind_speed = 0.8;
uniform float root_shade = 0.78;
uniform float tip_brightness = 1.18;
uniform float texture_detail = 0.2;
uniform float patch_variation = 0.08;
uniform float normal_up_bias = 0.65;
uniform float backlight_strength = 0.12;
uniform float alpha_cutoff = 0.45;
uniform vec2 world_origin = vec2(0.0);
uniform float density_start = 24.0;
uniform float density_end = 44.0;
uniform float distant_density = 0.4;
varying float blade_height;
varying vec3 grass_world;
void vertex() {
 // Stable per-clump thinning: nearby blades are unchanged, distant clumps
 // shrink into their roots without forcing foliage into a transparent pass.
 vec2 root_position=MODEL_MATRIX[3].xz;
 float distance_to_camera=distance(root_position,INV_VIEW_MATRIX[3].xz);
 float density=mix(1.0,distant_density,smoothstep(density_start,density_end,distance_to_camera));
 float rank=COLOR.a;
 float retained=smoothstep(rank*0.94,rank*0.94+0.06,density);
 VERTEX=mix(vec3(0.0,base_height,0.0),VERTEX,retained);
 blade_height=clamp((VERTEX.y-base_height)/max(blade_length,0.001),0.0,1.0);
 grass_world=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
 float phase=dot(grass_world.xz+world_origin,vec2(0.47,0.31));
 float t=wind_time*wind_speed;
 float breeze=sin(t+phase)*0.7+sin(t*1.73+phase*0.63)*0.3;
 float tip=blade_height*blade_height;
 reserve_connected=step(0.5,INSTANCE_CUSTOM.a);
 reserve_fraction=mix(1.0,foliage_reserve(INSTANCE_CUSTOM,wind_time),reserve_connected);
 VERTEX.y-=blade_length*foliage_tip_drop(tip,reserve_fraction)*reserve_connected;
 vec3 push=vec3(wind_direction.x,0.0,wind_direction.y)*breeze*wind_strength*wind_displacement*tip;
 // Fixed roots, coherent gusts, slightly yielding tips rather than sliding cards.
 push.y=-length(push)*blade_height*0.16;
 VERTEX+=inverse(mat3(MODEL_MATRIX))*push;
}
void fragment() {
 vec4 sample_color=textured ? texture(albedo_texture,UV) : vec4(1.0);
 if(textured && sample_color.a<alpha_cutoff-0.08) { discard; }
 float detail=dot(sample_color.rgb,vec3(0.2126,0.7152,0.0722));
 float patch=sin(dot(grass_world.xz+world_origin,vec2(0.29,0.37)))*0.6+sin(dot(grass_world.xz+world_origin,vec2(0.13,-0.21)))*0.4;
 vec3 base=ground_base_color.rgb*COLOR.rgb;
 float shade=mix(root_shade,tip_brightness,smoothstep(0.0,1.0,blade_height));
 ALBEDO=base*shade*(1.0+patch*patch_variation)*mix(1.0,0.8+detail*0.4,texture_detail);
 ALBEDO=mix(ALBEDO,foliage_pigment(ALBEDO,reserve_fraction),reserve_connected);
 vec3 up=normalize((VIEW_MATRIX*vec4(0.0,1.0,0.0,0.0)).xyz);
 vec3 blade=normalize(FRONT_FACING ? NORMAL : -NORMAL);
 NORMAL=normalize(mix(blade,up,normal_up_bias));
 ROUGHNESS=1.0;
 SPECULAR=0.0;
 BACKLIGHT=ALBEDO*backlight_strength*blade_height;
 ALPHA=sample_color.a;
 ALPHA_SCISSOR_THRESHOLD=alpha_cutoff;
 ALPHA_ANTIALIASING_EDGE=max(0.01,alpha_cutoff-0.08);
 ALPHA_TEXTURE_COORDINATE=UV*vec2(textureSize(albedo_texture,0));
}
