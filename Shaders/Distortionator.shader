shader_type canvas_item;
//replace "blend_mix" with "blend_add" or "blend_sub" or "blend_mul" to change blend mode
render_mode blend_mix;

//these are variables
uniform float opacity = 1.0;
uniform vec2 screen_size = vec2(320, 180);
uniform vec2 move = vec2(0,0);
uniform vec2 ping_pong_speed = vec2(0,0);
uniform vec2 oscillation_amplitude = vec2(0,0);
uniform vec2 oscillation_frequency = vec2(0,0);
uniform vec2 oscillation_speed = vec2(0,0);
uniform vec2 osc_amp_ping_pong = vec2(0,0);
uniform vec2 osc_trans_ping_pong = vec2(0,0);

uniform vec2 compression_amplitude = vec2(0,0);
uniform vec2 compression_frequency = vec2(0,0);
uniform vec2 compression_speed = vec2(0,0);
uniform vec2 comp_amp_ping_pong = vec2(0,0);
uniform vec2 comp_trans_ping_pong = vec2(0,0);

uniform vec2 interlaced_amplitude = vec2(0,0);
uniform vec2 interlaced_frequency = vec2(0,0);
uniform vec2 interlaced_speed = vec2(0,0);
uniform vec2 inter_amp_ping_pong = vec2(0,0);
uniform vec2 inter_trans_ping_pong = vec2(0,0);

uniform float palette_shifting_speed = 0;
uniform sampler2D palette;
uniform bool palette_shifting;

uniform bool barrel = false;
uniform float effect = 1; // -1.0 is BARREL, 0.1 is PINCUSHION. For planets, ideally -1.1 to -4.
uniform float effect_scale = 2; // Play with this to slightly vary the results.
uniform vec2 barrelxy = vec2(1.0,1.0);

vec2 distort(vec2 p) {
	float d = length(p);
	float z = sqrt(1.0 + d * d * effect);
	float r = atan(d, z) / 3.14159;
	r *= effect_scale;
	float phi = atan(p.y, p.x);
	return vec2(r*cos(phi)+.5,r*sin(phi)+.5);
}

 void fragment(){
    vec2 newuv = UV;
	
	vec2 xy = vec2(2.0 * UV);
	
	xy -= barrelxy;
	
	if (barrel){
		newuv = distort(xy);
	} else {
		newuv = UV;
	}
	
	vec2 osc_time = vec2(TIME, TIME);
	if (osc_trans_ping_pong.x != 0.0) {
			osc_time.x = cos(osc_trans_ping_pong.x * TIME);
		}
	if (osc_trans_ping_pong.y != 0.0) {
			osc_time.y = cos(osc_trans_ping_pong.y * TIME);
		}
	
	if ((oscillation_frequency.x != 0.0) && (oscillation_amplitude.x != 0.0)) { //horizontal oscillation
		newuv.x += oscillation_amplitude.x * cos((oscillation_frequency.x * newuv.y) + osc_time.x * oscillation_speed.x) * cos(osc_amp_ping_pong.x * TIME);
	}
	if ((oscillation_frequency.y != 0.0) && (oscillation_amplitude.y != 0.0)) { //vertical oscillation
		newuv.y += oscillation_amplitude.y * cos((oscillation_frequency.y * newuv.x) + osc_time.y * oscillation_speed.y) * cos(osc_amp_ping_pong.y * TIME);
	}
	
	vec2 comp_time = vec2(TIME, TIME);
	if (comp_trans_ping_pong.x != 0.0) {
		comp_time.x = cos(comp_trans_ping_pong.x * TIME);
		}
	if (comp_trans_ping_pong.y != 0.0) {
		comp_time.y = cos(comp_trans_ping_pong.y * TIME);
		}
	
	if ((compression_frequency.x != 0.0) && (compression_amplitude.x != 0.0)) { //horizontal compression
		newuv.x += compression_amplitude.x * cos((compression_frequency.x * newuv.x) + comp_time.x * compression_speed.x) * cos(comp_amp_ping_pong.x * TIME);
	}
	if ((compression_frequency.y != 0.0) && (compression_amplitude.y != 0.0)) { //vertical compression
		newuv.y += compression_amplitude.y * cos((compression_frequency.y * newuv.y) + comp_time.y * compression_speed.y) * cos(comp_amp_ping_pong.y * TIME);
	}
	
	//The movement of the texture and the ping pong speed
	if (ping_pong_speed.x != 0.0) {
		newuv.x += move.x * cos(ping_pong_speed.x * TIME);
	} else {
		newuv.x += TIME * move.x/0.5;
	}
	if (ping_pong_speed.y != 0.0) {
		newuv.y += move.y * cos(ping_pong_speed.y * TIME);
	} else {
		newuv.y += TIME * move.y/0.5;
	}
	
	palette_shifting_speed * 2.0;
	vec4 c = texture(TEXTURE, newuv);
	COLOR = c;
	float ccycle = mod(c.r - TIME * palette_shifting_speed, 1.0);
	float diff_x = 0.0;
	float diff_y = 0.0;
	
	vec2 inter_time = vec2(TIME, TIME);
	if (inter_trans_ping_pong.x != 0.0) {
			inter_time.x = cos(inter_trans_ping_pong.x * TIME);
		}
	if (inter_trans_ping_pong.y != 0.0) {
			inter_time.y = cos(inter_trans_ping_pong.y * TIME);
		}
	
	//horizontal interlacing
	if ((interlaced_frequency.x != 0.0) && (interlaced_amplitude.x != 0.0)) {
		if ( int(UV.y * screen_size.y / 2.0)  % 2 == 0 ){
			diff_x += 0.05 * cos((interlaced_frequency.x * UV.y) + (interlaced_speed.x * inter_time.x)) * interlaced_amplitude.x * cos(inter_amp_ping_pong.x * TIME);
		} else{
			diff_x -= 0.05 * cos((interlaced_frequency.x * UV.y) + (interlaced_speed.x * inter_time.x)) * interlaced_amplitude.x * cos(inter_amp_ping_pong.x * TIME);
		}
	}
	//vertical interlacing
	if ((interlaced_frequency.y != 0.0) && (interlaced_amplitude.y != 0.0)) {
		if ( int(UV.x * screen_size.x / 4.0)  % 2 == 0 ){
			diff_y += 0.05 * cos((interlaced_frequency.y * UV.x) + (interlaced_speed.y * inter_time.y)) * interlaced_amplitude.y * cos(inter_amp_ping_pong.y * TIME);
		} else{
			diff_y -= 0.05 * cos((interlaced_frequency.y * UV.x) + (interlaced_speed.y * inter_time.y)) * interlaced_amplitude.y * cos(inter_amp_ping_pong.y * TIME);
		}
	}
	
	//the shifting of the palette
	if (palette_shifting) {
		COLOR = texture(TEXTURE, vec2(newuv.x + diff_x, newuv.y + diff_y));
		COLOR = vec4(texture(palette, vec2(ccycle, 0)).rgb, c.a);
	} else{
		COLOR = (textureLod(TEXTURE, vec2(newuv.x + diff_x, newuv.y + diff_y), 0));
	}
	COLOR.a = opacity;
}