uniform float flow_speed = 0.65;
uniform float turbulence = 0.2;
uniform float spread = 4.0;
uniform float field_height = 1.6;
uniform float disturbance = 0.0;
uniform vec3 body_position = vec3(0.0);
uniform int pattern = 0;
uniform vec3 plant_ports[5];
vec3 hash3(float n) { return fract(sin(vec3(n,n+17.0,n+41.0))*vec3(43758.5,22578.1,19642.3)); }
vec3 ambient_path(float t, float id, float offset) {
 vec3 h=hash3(id+7.0);
 float clock=t*flow_speed;
 float lane=floor(h.z*7.0);
 float x=mod(h.x*spread*2.0+clock,spread*2.0)-spread;
 float z=(lane/6.0-0.5)*spread*1.5;
 float bend=sin(x*0.85+lane*1.7)*0.38;
 float y=0.15+h.y*field_height;
 vec3 p=vec3(x,y,z+bend);
 if(pattern==0) {
  int edge=int(floor(h.z*4.0));
  vec3 a=edge==0 ? plant_ports[0] : (edge==1 ? plant_ports[1] : (edge==2 ? plant_ports[2] : plant_ports[4]));
  vec3 b=edge==2 ? plant_ports[3] : plant_ports[2];
  float u=clamp(fract(h.x+clock/max(length(b-a),0.1))+offset/max(length(b-a),0.1),0.0,1.0);
  vec3 side=normalize(cross(b-a,vec3(0.0,1.0,0.001)));
  float envelope=sin(u*3.14159265);
  p=mix(a,b,u);
  p.y+=envelope*0.3*field_height/1.6;
  p+=side*envelope*(sin(u*6.283185+float(edge)*1.7)*0.16+(h.y-0.5)*0.07);
 }
 if(pattern==1) {
  float a=h.x*6.283185+clock*(0.3+h.y*0.3)+offset/(0.7+h.z*spread*0.8);
  float r=0.7+h.z*spread*0.8;
  p=vec3(cos(a)*r,y+sin(a*2.0)*0.12,sin(a)*r);
 }
 if(pattern==2) {
  float a=h.x*6.283185+clock*(0.8+h.y)+offset/(0.4+h.z*spread*0.6);
  float r=0.4+h.z*spread*0.6;
  p=vec3(cos(a)*r,0.2+mod(h.y*field_height+clock*0.35,field_height),sin(a)*r);
 }
 p+=vec3(sin(t*1.9+h.z*4.0),sin(t*2.3+h.z*5.0)*0.5,cos(t*1.7+h.z*4.0))*turbulence*(pattern==0 ? 0.18 : 1.0);
 vec2 away=p.xz-body_position.xz;
 float d=length(away);
 p.xz+=away/max(d,0.01)*exp(-d*d*1.8)*disturbance;
 p.y=max(0.08,p.y);
 return p;
}
uniform vec3 source_position = vec3(0.0);
uniform vec3 target_position = vec3(2.0,0.0,0.0);
uniform float arc_height = 0.8;
uniform float path_width = 0.15;
uniform bool use_live_path = false;
uniform vec3 live_path[9];
vec3 transfer_path(float u, float seed) {
 if(use_live_path) {
  float f=clamp(u,0.0,1.0)*8.0;
  int i=min(int(floor(f)),7);
  float t=f-float(i);
  vec3 a=live_path[max(i-1,0)];
  vec3 b=live_path[i];
  vec3 c=live_path[i+1];
  vec3 d=live_path[min(i+2,8)];
  vec3 p=0.5*(2.0*b+(-a+c)*t+(2.0*a-5.0*b+4.0*c-d)*t*t+(-a+3.0*b-3.0*c+d)*t*t*t);
  p.y=max(p.y,mix(b.y,c.y,t));
  vec3 side=normalize(cross(c-b,vec3(0.0,1.0,0.001)));
  return p+side*sin(u*3.14159265)*(seed-0.5)*path_width;
 }
 vec3 direction=normalize(target_position-source_position);
 vec3 side=cross(direction,vec3(0.0,1.0,0.0));
 if(length(side)<0.01) side=vec3(1.0,0.0,0.0);
 side=normalize(side);
 vec3 p=mix(source_position,target_position,u);
 p.y+=sin(u*3.14159265)*arc_height;
 p+=side*sin(u*3.14159265)*(sin(u*4.0+seed*0.45)*path_width);
 return p;
}
