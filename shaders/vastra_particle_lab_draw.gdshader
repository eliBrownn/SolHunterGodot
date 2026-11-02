shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;
uniform float particle_size = 0.075;
uniform float opacity = 0.45;
uniform float visibility_scale = 1.0;
uniform float admission_visibility = 1.0;
uniform float pulse_strength = 0.0;
uniform float pulse_amount = 0.0;
uniform float glow = 0.0;
uniform float filament_length = 1.1;
uniform float refraction = 0.003;
uniform float fine_detail = 0.9;
uniform int appearance = 0;
uniform float animation_time = 0.0;
uniform sampler3D field_noise : filter_linear, repeat_enable;
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform sampler2D scene_depth : hint_depth_texture, filter_nearest, repeat_disable;
uniform bool all_affinities = false;
uniform vec4 tint : source_color = vec4(0.72,0.93,0.9,1.0);
uniform bool transfer_packet = false;
uniform float intersection_softness = 0.12;
uniform float breathing_strength = 0.18;
uniform float breathing_seconds = 6.0;
uniform float flow_phase = 0.0;
uniform float energy_visibility = 1.0;
// Zero keeps standalone art fixtures unrestricted. Live play sets a finite radius.
uniform float effect_range = 0.0;
uniform float effect_fade = 6.0;
#include "res://shaders/vastra_particle_lab_paths.gdshaderinc"
#include "res://shaders/vastra_field.gdshaderinc"
varying vec3 filament_world;
varying float visibility;
varying float age;
varying float seed;
varying float along;
varying float path_fraction;
vec3 affinity(float n) {
 int i=int(floor(n*8.0));
 if(i==0) return vec3(1.0,0.573,0.329);
 if(i==1) return vec3(0.271,0.624,0.91);
 if(i==2) return vec3(0.729,0.58,0.396);
 if(i==3) return vec3(0.718,0.933,0.902);
 if(i==4) return vec3(0.961,0.839,0.357);
 if(i==5) return vec3(0.376,0.251,0.6);
 if(i==6) return vec3(0.616,0.945,0.792);
 return vec3(0.929,0.557,0.867);
}
void vertex() {
 visibility=transfer_packet ? INSTANCE_CUSTOM.z : 1.0;
 age=INSTANCE_CUSTOM.x;
 visibility*=visibility_scale*admission_visibility*(transfer_packet ? energy_visibility : 1.0);
 float id=INSTANCE_CUSTOM.y;
 seed=transfer_packet ? fract(sin(id*13.17+9.7)*43758.5) : hash3(id+7.0).x;
 float parameter=INSTANCE_CUSTOM.w;
 path_fraction=parameter;
 float path_span=use_live_path && live_path_length>0.0 ? live_path_length : length(target_position-source_position);
 along=transfer_packet ? parameter*path_span : MODEL_MATRIX[3].x;
 if(appearance==1) {
  VERTEX*=particle_size*mix(1.0,0.4,age);
 } else {
  // Sample the complete shared path for every strip vertex, not just its tangent.
  // A transfer strip trails its head; it must not protrude ahead of the
  // authoritative arrival position and appear to enter before actual credit.
  float offset=(UV.x-(transfer_packet ? 1.0 : 0.5))*filament_length;
  float span=max(path_span,0.001);
  float raw_u=parameter+offset/span;
  float u=clamp(raw_u,0.0,1.0);
  path_fraction=transfer_packet ? raw_u : u;
  vec3 center=transfer_packet ? transfer_path(clamp(parameter,0.0,1.0),seed) : ambient_path(parameter,id,0.0);
  vec3 at=transfer_packet ? transfer_path(u,seed) : ambient_path(parameter,id,offset);
  vec3 before=transfer_packet ? transfer_path(clamp(u-0.005,0.0,1.0),seed) : ambient_path(parameter,id,offset-0.01);
  vec3 after=transfer_packet ? transfer_path(clamp(u+0.005,0.0,1.0),seed) : ambient_path(parameter,id,offset+0.01);
  vec2 direction=normalize((VIEW_MATRIX*vec4(after-before,0.0)).xy+vec2(0.0001));
  vec2 across=vec2(-direction.y,direction.x);
  VERTEX=(VIEW_MATRIX*vec4(at-center,0.0)).xyz;
  VERTEX.xy+=across*(UV.y-0.5)*particle_size*1.4*mix(1.0,0.8,age)*(1.0+0.2*pulse_strength*pulse_amount*exp(-age*5.0));
 }
 filament_world=MODEL_MATRIX[3].xyz+(INV_VIEW_MATRIX*vec4(VERTEX,0.0)).xyz;
 MODELVIEW_MATRIX=VIEW_MATRIX*mat4(INV_VIEW_MATRIX[0],INV_VIEW_MATRIX[1],INV_VIEW_MATRIX[2],MODEL_MATRIX[3]);
}
void fragment() {
 if(opacity<=0.0 || visibility<=0.0) { discard; }
 // Remove crossed particles/fragments at the actual intake, leaving the rest
 // of the strand fully present as its tail enters the ring.
 if(transfer_packet && (path_fraction>=1.0 || path_fraction<0.0)) { discard; }
 float range_weight=effect_range>0.0 ? 1.0-smoothstep(effect_range-effect_fade,effect_range,length(filament_world.xz)) : 1.0;
 if(range_weight<=0.0) { discard; }
 float openness=vastra_sol_openness(filament_world);
 if(transfer_packet) {
  // A nearby Sol's optical clearing must not erase the actual plant intake.
  float span=max(live_path_length,length(target_position-source_position));
  float intake=smoothstep(max(0.0,1.0-0.25/max(span,0.001)),1.0,path_fraction);
  openness=mix(openness,1.0,intake);
 }
 float pulse=1.0+pulse_strength*pulse_amount*exp(-age*5.0);
 // Travel is the real packet clock. Only its brightness fluctuates, using the
 // source phase and distance along the connected route rather than camera time.
 if(transfer_packet) pulse*=1.0+breathing_strength*sin(along*2.0-animation_time*6.283185/max(breathing_seconds,0.01)+flow_phase);
 float contact=1.0;
 if(transfer_packet) {
  float depth=textureLod(scene_depth,SCREEN_UV,0.0).r;
  vec4 view_depth=INV_PROJECTION_MATRIX*vec4(SCREEN_UV*2.0-1.0,depth,1.0);
  float approach_head=1.0-smoothstep(0.0,0.12,age);
  contact=smoothstep(0.0,intersection_softness*mix(1.0,0.15,approach_head),-view_depth.z/view_depth.w+VERTEX.z);
 }
 vec3 color=all_affinities ? affinity(seed) : tint.rgb;
 if(appearance==1) {
  float r=length(UV-0.5)*2.0;
  float halo=exp(-r*r*5.5)*(1.0-smoothstep(0.75,1.0,r));
  float head=1.0-step(0.001,age);
  float core=(1.0-smoothstep(0.08,0.3,r))*head;
  ALBEDO=mix(color,vec3(1.0),core*0.5);
  EMISSION=color*glow*(0.5+core);
  ALPHA=(halo*0.55+core*0.45)*(transfer_packet ? 1.0 : pow(1.0-age,1.7))*opacity*visibility*pulse*openness;
 } else {
  // Same seeded optical noise, complementary fringes and restrained light as the
  // in-game current; particles overlap into air folds instead of circular heads.
  float longitudinal=along+(UV.x-0.5)*filament_length;
  vec3 p=vec3(longitudinal*1.6-animation_time*0.15,UV.y*5.0,seed*4.0);
  vec3 broad=textureLod(field_noise,p/48.0,0.0).rgb;
  vec3 dust=textureLod(field_noise,p*vec3(0.65,2.2,1.0)/24.0+vec3(0.31,0.57,0.13),0.0).rgb;
  float shift=(broad.r-0.5)*0.2;
  float cross_flow=UV.y*2.0-1.0;
  float pixel=max(fwidth(UV.y)*0.85,0.012);
  float fiber_a=exp(-pow((UV.y-0.3-shift-(dust.g-0.5)*0.12)/max(pixel,0.026),2.0));
  float fiber_b=exp(-pow((UV.y-0.53+shift-(dust.r-0.5)*0.18)/max(pixel,0.018),2.0));
  float fiber_c=exp(-pow((UV.y-0.72-shift*0.5)/max(pixel,0.02),2.0));
  float fibers=(fiber_a*0.04+fiber_b+fiber_c*0.03)*fine_detail;
  float folds=exp(-pow((cross_flow-shift)*1.7,2.0));
  float mist=folds*smoothstep(0.22,0.7,dust.r)*(0.25+0.75*broad.g);
  float head=1.0-smoothstep(0.0,0.12,age);
  float tip=transfer_packet ? head : 0.0;
  float ends=smoothstep(0.0,0.2,UV.x)*mix(1.0-smoothstep(0.72,1.0,UV.x),1.0,tip);
  float edges=1.0-smoothstep(0.4,1.0,abs(cross_flow));
  float path_ends=transfer_packet ? smoothstep(0.0,0.025,path_fraction) : 1.0;
  float fade=(transfer_packet ? 1.0 : pow(1.0-age,1.3))*visibility*ends*edges*contact*path_ends;
  float color_spread=max(color.r,max(color.g,color.b))-min(color.r,min(color.g,color.b));
  vec3 primary=color_spread<0.025 ? vec3(0.18,0.42,0.55) : color;
  vec3 secondary=vec3(max(primary.r,max(primary.g,primary.b))+min(primary.r,min(primary.g,primary.b)))-primary;
  vec3 fringe=mix(secondary,primary,smoothstep(-0.25,0.25,cross_flow-shift));
  vec2 slope=normalize(vec2(dFdx(longitudinal),dFdy(longitudinal))+vec2(0.001));
  vec2 offset=slope*refraction*folds*edges*0.25;
  vec2 safe=clamp(SCREEN_UV+offset,vec2(0.001),vec2(0.999));
  float foreground=textureLod(scene_depth,safe,0.0).r;
  if(foreground>FRAGCOORD.z+0.00001) safe=SCREEN_UV;
  vec3 background=textureLod(screen_texture,safe,0.0).rgb;
  vec3 first=textureLod(screen_texture,clamp(safe+offset*0.6,vec2(0.001),vec2(0.999)),0.0).rgb;
  vec3 second=textureLod(screen_texture,clamp(safe-offset*0.6,vec2(0.001),vec2(0.999)),0.0).rgb;
  vec3 refracted=vec3(first.r,background.g,second.b);
  ALBEDO=mix(refracted,fringe,clamp(mist*0.18+fibers*0.85,0.0,0.9));
  EMISSION=fringe*glow*(mist*0.05+fibers*0.08);
  ALPHA=clamp((mist*0.012+fibers*0.42)*opacity*fade*pulse*openness,0.0,0.24);
 }
 ALPHA*=range_weight;
}
