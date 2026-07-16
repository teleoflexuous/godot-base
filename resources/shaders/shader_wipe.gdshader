shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float softness : hint_range(0.001, 0.5) = 0.08;

void fragment() {
	vec4 base = texture(TEXTURE, UV) * COLOR;
	float edge = mix(-softness, 1.0 + softness, progress);
	base.a *= smoothstep(edge - softness, edge + softness, UV.x);
	COLOR = base;
}
