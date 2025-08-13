shader_type canvas_item;
//replace "blend_mix" with "blend_add" or "blend_sub" or "blend_mul" to change blend mode
render_mode blend_mix;

uniform float opacity = 1.0;
uniform int blending = 0;
uniform vec2 screen_size = vec2(320, 180);

// SCROLL
uniform vec2 move = vec2(0,0);

// PING PONG
uniform vec2 ping_pong_speed = vec2(0,0);

// OSCILLATION
uniform vec2 oscillation_amplitude = vec2(0,0);
uniform vec2 oscillation_frequency = vec2(0,0);
uniform vec2 oscillation_speed = vec2(0,0);
uniform vec2 osc_amp_ping_pong = vec2(0,0);
uniform vec2 osc_trans_ping_pong = vec2(0,0);

// COMPRESSION
uniform vec2 compression_amplitude = vec2(0,0);
uniform vec2 compression_frequency = vec2(0,0);
uniform vec2 compression_speed = vec2(0,0);
uniform vec2 comp_amp_ping_pong = vec2(0,0);
uniform vec2 comp_trans_ping_pong = vec2(0,0);

// INTERLACING
uniform vec2 interlaced_amplitude = vec2(0,0);
uniform vec2 interlaced_frequency = vec2(0,0);
uniform vec2 interlaced_speed = vec2(0,0);
uniform vec2 inter_amp_ping_pong = vec2(0,0);
uniform vec2 inter_trans_ping_pong = vec2(0,0);

// PALETTE SHIFTING
uniform float palette_shifting_speed = 0;
uniform sampler2D palette;
uniform bool palette_shifting;
uniform int palette_anim_frame_count;

// BARREL
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


vec4 apply_blending(vec4 base, vec4 blend, int type){
	if (type == 1) { // SCREEN
		return 1.0 - (1.0 - base) * (1.0 - blend);
	} else if (type == 2) { // MULTIPLY
		return 1.0 - (1.0 - base) * (1.0 - blend);
	} else if (type == 3) { // DARKEN
		return min(base, blend);
	} else if (type == 4) { // LIGHTEN
		return max(base, blend);
	} else if (type == 5) { // DIFFERENCE
		return abs(vec4(base.rgb,0) - vec4(blend.rgb,0)) + vec4(0,0,0,blend.a);
	} else if (type == 6) { // EXCLUSION
		return (base + blend - 2.0 * base * blend) + vec4(0,0,0,blend.a);
	} else if (type == 7) { // OVERLAY
		vec4 limit = step(0.5, base);
		return mix(2.0 * base * blend, 1.0 - 2.0 * (1.0 - base) * (1.0 - blend), limit);
	} else if (type == 8) { // HARD LIGHT
		vec4 limit = step(0.5, blend);
		return mix(2.0 * base * blend, 1.0 - 2.0 * (1.0 - base) * (1.0 - blend), limit);
	} else if (type == 9) { // SOFT LIGHT
		vec4 limit = step(0.5, blend);
		return mix(2.0 * base * blend + base * base * (1.0 - 2.0 * blend), sqrt(base) * (2.0 * blend - 1.0) + (2.0 * base) * (1.0 - blend), limit);
	} else if (type == 10) { // COLOR DODGE
		return base / (1.0 - blend);
	} else if (type == 11) { // LINEAR DODGE
		return base + blend;
	} else if (type == 12) { // COLOR BURN
		return 1.0 - (1.0 - base) / blend;
	} else if (type == 13) { // LINEAR BURN
		return base + blend - 1.0;
	} else {
		return 1.0 - (1.0 - base) * (1.0 - blend);
	}
}

 void fragment(){
	//UV variable for distortions
	vec2 newuv = UV;
	
	//Original modulate
	vec4 modulate = COLOR;
	
	//BARREL
	if (barrel){
		vec2 xy = vec2(2.0 * UV) - barrelxy;
		newuv = distort(xy);
	} else {
		newuv = UV;
	}
	
	// OSCILATION
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
	
	// COMPRESSION
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
	
	// PING PONG!
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
	
	// INTERLACING
	float diff_x = 0.0;
	float diff_y = 0.0;
	
	vec2 inter_time = vec2(TIME, TIME);
	if (inter_trans_ping_pong.x != 0.0) {
			inter_time.x = cos(inter_trans_ping_pong.x * TIME);
		}
	if (inter_trans_ping_pong.y != 0.0) {
			inter_time.y = cos(inter_trans_ping_pong.y * TIME);
		}
	
	// INTERLACING (X)
	if ((interlaced_frequency.x != 0.0) && (interlaced_amplitude.x != 0.0)) {
		if ( int(UV.y * screen_size.y / 2.0)  % 2 == 0 ){
			diff_x += 0.05 * cos((interlaced_frequency.x * UV.y) + (interlaced_speed.x * inter_time.x)) * interlaced_amplitude.x * cos(inter_amp_ping_pong.x * TIME);
		} else{
			diff_x -= 0.05 * cos((interlaced_frequency.x * UV.y) + (interlaced_speed.x * inter_time.x)) * interlaced_amplitude.x * cos(inter_amp_ping_pong.x * TIME);
		}
	}
	
	// INTERLACING (Y)
	if ((interlaced_frequency.y != 0.0) && (interlaced_amplitude.y != 0.0)) {
		if ( int(UV.x * screen_size.x / 4.0)  % 2 == 0 ){
			diff_y += 0.05 * cos((interlaced_frequency.y * UV.x) + (interlaced_speed.y * inter_time.y)) * interlaced_amplitude.y * cos(inter_amp_ping_pong.y * TIME);
		} else{
			diff_y -= 0.05 * cos((interlaced_frequency.y * UV.x) + (interlaced_speed.y * inter_time.y)) * interlaced_amplitude.y * cos(inter_amp_ping_pong.y * TIME);
		}
	}
	
	
	// Apply all distortions!
	COLOR = (textureLod(TEXTURE, vec2(newuv.x + diff_x, newuv.y + diff_y), 0));
	
	
	// PALETTE SHIFTING
	
	
	if (blending <= 0) {
		if (palette_shifting) {
			COLOR = vec4(texture(palette, vec2(COLOR.r, mod(-TIME * palette_shifting_speed * 1.0 / float(palette_anim_frame_count), 1.0))).rgb, COLOR.a);
		}
	} else if (blending > 0) {
		//Assuming the paper sprite is on the 'texture' of your Sprite2D or TetureRect
		vec4 blend = texture(TEXTURE, newuv + vec2(diff_x,diff_y));
		//Gets the colour of the screen at the same pixel for the base.
		vec4 base = texture(SCREEN_TEXTURE, SCREEN_UV);

		// To preview how it looks like.
		vec4 final_color = apply_blending(base, blend, blending);
		//final_color = (textureLod(TEXTURE, vec2(newuv.x + diff_x, newuv.y + diff_y), 0));
		if (palette_shifting) {
			COLOR = final_color + vec4(texture(palette, vec2(COLOR.r, mod(-TIME * palette_shifting_speed * 1.0 / float(palette_anim_frame_count), 1.0))).rgb, COLOR.a);
		} else {
			COLOR = final_color;
		}
		

	}
	
	
	// OPACITY
	COLOR.a *= opacity;
	
	
}