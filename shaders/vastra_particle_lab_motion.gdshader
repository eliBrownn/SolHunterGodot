shader_type particles;
render_mode disable_velocity;
uniform float animation_time = 0.0;
uniform int trail_samples = 10;
uniform float trail_seconds = 0.65;
#include "res://shaders/vastra_particle_lab_paths.gdshaderinc"
void start() { TRANSFORM=mat4(1.0); COLOR=vec4(1.0); }
void process() {
 uint stride=uint(trail_samples+1);
 float id=float(INDEX/stride);
 float age=float(INDEX%stride)/float(trail_samples+1);
 TRANSFORM=mat4(1.0);
 TRANSFORM[3].xyz=ambient_path(animation_time-age*trail_seconds,id,0.0);
 vec3 tangent=normalize(ambient_path(animation_time-age*trail_seconds,id,0.01)-ambient_path(animation_time-age*trail_seconds,id,-0.01)+vec3(0.00001));
 vec3 side=normalize(cross(tangent,vec3(0.0,1.0,0.001)));
 TRANSFORM[0].xyz=tangent;
 TRANSFORM[1].xyz=normalize(cross(side,tangent));
 TRANSFORM[2].xyz=side;
 CUSTOM=vec4(age,id,0.0,animation_time-age*trail_seconds);
 COLOR=vec4(1.0);
 ACTIVE=true;
}
