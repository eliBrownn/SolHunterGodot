shader_type sky;
// Original public-checkout fallback. No supplied sky archive source is redistributed.
uniform sampler2D cloud_tex_01 : repeat_enable;
uniform sampler2D cloud_tex_02 : repeat_enable;
uniform vec4 sky_day : source_color = vec4(0.2,0.45,0.75,1.0);
uniform vec4 horizon_day : source_color = vec4(0.7,0.83,0.93,1.0);
uniform float horizon_curve = 0.4;
uniform vec2 wind_speed = vec2(0.1,0.035);
uniform float sky_time = 0.0;
uniform float cloud_scale = 0.16;
uniform float cloud_density = 0.35;
uniform float cloud_softness = 0.12;
uniform vec4 cloud_color : source_color = vec4(0.97,0.98,1.0,1.0);
uniform vec4 cloud_shadow : source_color = vec4(0.65,0.75,0.86,1.0);
uniform vec3 sun_direction = vec3(0.0,0.8,0.6);
uniform vec4 sun_color : source_color = vec4(1.0,0.94,0.82,1.0);
uniform vec4 moon_color : source_color = vec4(0.64,0.78,0.95,1.0);
uniform float daylight = 1.0;
void sky() {
 vec3 ray=normalize(EYEDIR);
 float elevation=pow(clamp(ray.y,0.0,1.0),max(horizon_curve,0.05));
 vec3 day=mix(horizon_day.rgb,sky_day.rgb,elevation);
 vec3 color=mix(vec3(0.012,0.02,0.055),day,daylight);
 vec2 uv=ray.xz/max(abs(ray.y)+0.25,0.25)*cloud_scale+wind_speed*sky_time*0.002;
 float cloud=texture(cloud_tex_01,uv).r*0.7+texture(cloud_tex_02,uv*1.7).r*0.3;
 float cover=smoothstep(1.0-cloud_density-cloud_softness,1.0-cloud_density+cloud_softness,cloud)*smoothstep(0.0,0.2,ray.y);
 color=mix(color,mix(cloud_shadow.rgb,cloud_color.rgb,cloud)*(0.15+daylight*0.85),cover*0.8);
 float sun=pow(max(dot(ray,normalize(sun_direction)),0.0),900.0);
 float moon=pow(max(dot(ray,-normalize(sun_direction)),0.0),1200.0);
 COLOR=color+sun_color.rgb*sun*daylight+moon_color.rgb*moon*(1.0-daylight);
}
