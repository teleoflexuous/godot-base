shader_type canvas_item;

uniform vec4 flash_color : source_color = vec4(1.0);
uniform float flash_amount : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 sampled = texture(TEXTURE, UV) * COLOR;
	sampled.rgb = mix(sampled.rgb, flash_color.rgb, flash_amount * sampled.a);
	COLOR = sampled;
}
