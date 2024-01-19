shader_type canvas_item;
render_mode unshaded;

uniform float cut : hint_range(0.0, 1.0);
uniform float Size = 1.0;
uniform float screenWidth = 320;
uniform float screenHeight = 180;
uniform int fade: hint_range(0, 1);

void fragment()
{
	if (fade == 0){
		float alpha = smoothstep(cut, cut + 1.0 , UV.x * 0.0 + Size);
		COLOR = vec4(COLOR.rgb, alpha);
	} else if (fade == 1){
		float ratio = screenWidth / screenHeight;
		float dist = distance(vec2(0.5, 0.5), vec2(mix(0.5, UV.x, ratio), UV.y));
		COLOR.a = step(cut, dist);
	}
}