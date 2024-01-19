shader_type canvas_item;
//replace "blend_mix" with "blend_add" or "blend_sub" or "blend_mul" to change blend mode
render_mode blend_mix;

//these are variables
uniform bool horizontal_distortion;
uniform bvec2 vertical_distortion;
uniform vec2 amplitude = vec2(0,0);
uniform vec2 frequency = vec2(0,0);
uniform float scale = 0.0;
uniform vec2 move = vec2(0,0);
uniform bool ping_pong;

/// PALETTE SWAP CODE by KoBeWi
uniform bool palette_shifting = false;
uniform sampler2D palette;
uniform vec2 texture_size = vec2(0, 0);
uniform bool skip_first_row = true;
uniform bool use_palette_alpha = false;
uniform float fps = 6;
///

uniform bvec2 interleaved;
uniform float screen_height = 180;
uniform float screen_width = 320;

 void fragment(){
    vec2 newuv = UV;
	//tbh i dont know how to explain what it does, ill just say it makes the background move
	if (horizontal_distortion) { //oscillation
		newuv.x += amplitude.x * sin((frequency.x * newuv.y) + scale * TIME)/1.0;
	} else { //compression
		newuv.x += amplitude.x * sin((frequency.x * newuv.x) + scale * TIME)/1.0;
	}
	
	if (vertical_distortion.x) { //oscillation
		newuv.y += amplitude.y * cos((frequency.y * newuv.x) + scale * TIME)/1.0;
	} else if (vertical_distortion.y) { //compression
		newuv.y += amplitude.y * cos((frequency.y * newuv.y) + scale * TIME)/1.0;
	}
	//this one i can explain, it moves the texture to up and right using postives, down and left using negetives
	//the higher the number the faster it is
	if (ping_pong) {
		newuv.x += move.x * sin(scale * TIME);
		newuv.y += move.y * cos(scale * TIME);
	} else {
		newuv.x += TIME * move.x/0.5;
		newuv.y += TIME * move.y/0.5;
	}
	
	float diff_x = 0.0;
	float diff_y = 0.0;
	if (interleaved.x) {
		if ( int(UV.y * screen_height) % 2 == 0 ){
			diff_x += 0.075 * sin((amplitude.x * UV.y) + (2.0 * TIME));
		
		} else {
			diff_x += -0.075 * sin((amplitude.x * UV.y) + (2.0 * TIME));
		}
	}
	
	if (interleaved.y) {
		if ( int(UV.x * screen_width) % 2 == 0 ){
			diff_y += 0.075 * sin((amplitude.y * UV.x) + (2.0 * TIME));
		
		}else{
			diff_y += -0.075 * sin((amplitude.y * UV.x) + (2.0 * TIME));
		}
	}
	
	newuv.x += diff_x;
	newuv.y += diff_y;
	
	if (palette_shifting) {
	/// PALETTE SWAP CODE from KoBeWi
		vec4 original_color = texture(TEXTURE, newuv);
		ivec3 colori = ivec3(round(original_color.rgb * 255.0));
		
		ivec2 color_count = ivec2(texture_size);
		
		float idx = -1.0;
		for (int i = 0; i < color_count.x; i++) {
			vec3 color2 = texture(palette, vec2(float(i) / float(color_count.x - 1), 0)).rgb;
			ivec3 colori2 = ivec3(round(color2 * 255.0));
			
			if (colori == colori2) {
				idx = float(i);
				break;
			}
		}
		
		if (idx >= 0.0) {
			vec2 uv;
			uv.x = idx / float(color_count.x - 1);
			uv.y = (mod(TIME * fps, max(float(color_count.y - 1 - int(skip_first_row)), 1.0)) + float(skip_first_row))  / float(color_count.y - 1);
			
			vec4 palette_color = texture(palette, uv);
			COLOR = vec4(palette_color.rgb, mix(original_color.a, palette_color.a, float(use_palette_alpha)));
		} else {
			COLOR = original_color;
		}
	///
	}
	else {
		COLOR = texture(TEXTURE, newuv);
	}
}


