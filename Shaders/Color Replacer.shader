shader_type canvas_item;

uniform vec4 OLDCOLOR : hint_color;
uniform vec4 NEWCOLOR: hint_color;

void fragment() {
	vec4 curr_pixel = texture(TEXTURE, UV);
	if (curr_pixel == OLDCOLOR){
		COLOR = NEWCOLOR;
		}
	else {
		COLOR = curr_pixel;
	}
}