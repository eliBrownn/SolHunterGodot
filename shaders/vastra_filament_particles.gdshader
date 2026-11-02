shader_type particles;
render_mode disable_velocity;
uniform float elapsed = 0.0;
uniform float duration = 1.0;
uniform float trail_seconds = 1.5;
uniform int trail_samples = 10;
uniform float release_seconds = 0.0;
uniform int head_count = 8;
uniform float filament_length = 1.1;
#include "res://shaders/vastra_particle_lab_paths.gdshaderinc"
void start() { TRANSFORM=mat4(1.0); COLOR=vec4(1.0); }
void process() {
 uint stride=uint(trail_samples+1);
 float id=float(INDEX/stride);
 float seed=fract(sin(id*13.17+9.7)*43758.5);
 float age=float(INDEX%stride)/float(trail_samples+1);
 float emission=release_seconds*id/max(float(head_count-1),1.0);
 float t=(elapsed-emission-age*trail_seconds)/max(duration,0.001);
 TRANSFORM=mat4(1.0);
 TRANSFORM[3].xyz=transfer_path(clamp(t,0.0,1.0),seed);
 // Keep the strip's tail moving after its head crosses the intake. The draw
 // shader clips only the portion beyond the surface, without a temporal fade.
 float span=max(live_path_length,length(target_position-source_position));
 float tail_fraction=filament_length/max(span,0.001);
 CUSTOM=vec4(age,id,step(0.0,t)*(1.0-step(1.0+tail_fraction,t)),t);
 COLOR=vec4(1.0);
 ACTIVE=true;
}
