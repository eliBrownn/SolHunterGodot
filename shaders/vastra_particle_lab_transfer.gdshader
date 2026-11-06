shader_type particles;
render_mode disable_velocity;
uniform float elapsed = 0.0;
uniform float duration = 2.0;
uniform float trail_seconds = 0.65;
uniform int trail_samples = 10;
#include "res://shaders/vastra_particle_lab_paths.gdshaderinc"
void start() { TRANSFORM=mat4(1.0); COLOR=vec4(1.0); }
void process() {
 uint stride=uint(trail_samples+1);
 float id=float(INDEX/stride);
 float seed=fract(sin(id*13.17+9.7)*43758.5);
 float age=float(INDEX%stride)/float(trail_samples+1);
 // Each head starts separately; historical samples follow that same head's path.
 float t=(elapsed-seed*0.25-age*trail_seconds)/duration;
 float visible=step(0.0,t)*(1.0-step(1.0,t));
 TRANSFORM=mat4(1.0);
 TRANSFORM[3].xyz=transfer_path(clamp(t,0.0,1.0),seed);
 vec3 tangent=normalize(transfer_path(clamp(t+0.01,0.0,1.0),seed)-transfer_path(clamp(t-0.01,0.0,1.0),seed)+vec3(0.00001));
 vec3 side=normalize(cross(tangent,vec3(0.0,1.0,0.001)));
 TRANSFORM[0].xyz=tangent;
 TRANSFORM[1].xyz=normalize(cross(side,tangent));
 TRANSFORM[2].xyz=side;
 CUSTOM=vec4(age,id,visible,clamp(t,0.0,1.0));
 COLOR=vec4(1.0);
 ACTIVE=true;
}
