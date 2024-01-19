shader_type canvas_item;
render_mode blend_disabled;

uniform vec4 OLDCOLOR : hint_color;
uniform vec4 NEWCOLOR: hint_color;


void fragment() {
	vec4 curr_pixel = texture(TEXTURE, UV);
	if (curr_pixel == OLDCOLOR){
		COLOR = NEWCOLOR;
		}
	else{
		//vec4 final = texture(TEXTURE, UV);
		if (curr_pixel.a == 1.0) {
			curr_pixel = texture(SCREEN_TEXTURE, SCREEN_UV);
		}
		COLOR = curr_pixel;
	}
}
