shader_type canvas_item;

render_mode skip_vertex_transform;

uniform vec4 OLDCOLOR : hint_color;
uniform sampler2D overlay_tex;
uniform float tex_size = 300; //the size of the overlay texture
uniform float speed = 0;
varying vec2 world_position;
varying vec2 tex_position;

void vertex(){
	// calculate the world position for use in the fragment shader
	world_position = (vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	// get og texture pixels
	vec4 curr_pixel = texture(TEXTURE, UV);
	// only apply overlay_tex on the fully red parts of the original tiles
	if (curr_pixel == OLDCOLOR){
		float mix_amount = floor(COLOR.r);
		// sample the overlay_tex using worldPos
		vec2 worldpos = world_position * (1.0/tex_size) - TIME * speed;
		vec4 overlay_color = texture(overlay_tex, worldpos);
		// combine original color and overlay color together
		vec4 newCOLOR = mix(COLOR, overlay_color, mix_amount);
		COLOR = newCOLOR;
		
		
	} 
	else{
		COLOR = curr_pixel;
	}
	
}