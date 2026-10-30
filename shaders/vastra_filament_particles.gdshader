shader_type particles;
render_mode disable_velocity;
uniform float elapsed = 0.0;
uniform float duration = 1.0;
uniform float trail_seconds = 1.5;
uniform int trail_samples = 10;
#include "res://shaders/vastra_particle_lab_paths.gdshaderinc"
void start() { TRANSFORM=mat4(1.0); COLOR=vec4(1.0); }
void process() {
 uint stride=uint(trail_samples+1);
 float id=float(INDEX/stride);
 float seed=fract(sin(id*13.17+9.7)*43758.5);
 float age=float(INDEX%stride)/float(trail_samples+1);
 float t=(elapsed-age*trail_seconds)/max(duration,0.001);
 TRANSFORM=mat4(1.0);
 TRANSFORM[3].xyz=transfer_path(clamp(t,0.0,1.0),seed);
 CUSTOM=vec4(age,id,step(0.0,t)*(1.0-step(1.0,t)),clamp(t,0.0,1.0));
 COLOR=vec4(1.0);
 ACTIVE=true;
}
