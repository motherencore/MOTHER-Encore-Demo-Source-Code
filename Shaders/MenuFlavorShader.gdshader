shader_type canvas_item;

uniform vec4 OLDCOLOR1 : hint_color;
uniform vec4 NEWCOLOR1: hint_color;
uniform vec4 OLDCOLOR2 : hint_color;
uniform vec4 NEWCOLOR2: hint_color;
uniform vec4 OLDCOLOR3 : hint_color;
uniform vec4 NEWCOLOR3: hint_color;
uniform vec4 OLDCOLOR4 : hint_color;
uniform vec4 NEWCOLOR4: hint_color;
uniform vec4 OLDCOLOR5 : hint_color;
uniform vec4 NEWCOLOR5: hint_color;

void fragment() {
	vec4 curr_pixel = texture(TEXTURE, UV);
	if (distance(curr_pixel, OLDCOLOR1) < 0.01){
		COLOR = NEWCOLOR1;
		}
	else if (distance(curr_pixel, OLDCOLOR2) < 0.01){
		COLOR = NEWCOLOR2;
		}
	else if (distance(curr_pixel, OLDCOLOR3) < 0.01){
		COLOR = NEWCOLOR3;
		}
	else if (distance(curr_pixel, OLDCOLOR4) < 0.01){
		COLOR = NEWCOLOR4;
		}
	else if (distance(curr_pixel, OLDCOLOR5) < 0.01){
		COLOR = NEWCOLOR5;
		}
	else {
		COLOR = curr_pixel;
	}
}