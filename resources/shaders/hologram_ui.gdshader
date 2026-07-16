shader_type canvas_item;

uniform vec4 glow_color : source_color = vec4(0.1, 0.9, 1.0, 1.0);
uniform float glow_strength : hint_range(0.0, 2.0) = 0.0;
uniform float scanline_strength : hint_range(0.0, 1.0) = 0.0;
uniform float glitch_strength : hint_range(0.0, 0.05) = 0.0;

void fragment() {
	float pulse = sin(TIME * 14.0 + UV.y * 90.0) * glitch_strength;
	vec4 base = texture(TEXTURE, UV + vec2(pulse, 0.0)) * COLOR;
	float lines = mix(1.0, 0.7 + 0.3 * sin(UV.y * 720.0), scanline_strength);
	base.rgb = mix(base.rgb, glow_color.rgb, base.a * glow_strength) * lines;
	COLOR = base;
}
