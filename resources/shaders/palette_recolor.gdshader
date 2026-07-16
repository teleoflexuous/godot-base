shader_type canvas_item;

uniform vec4 source_color : source_color = vec4(1.0, 0.0, 1.0, 1.0);
uniform vec4 replacement_color : source_color = vec4(0.0, 1.0, 1.0, 1.0);
uniform float tolerance : hint_range(0.0, 1.0) = 0.08;

void fragment() {
	vec4 base = texture(TEXTURE, UV) * COLOR;
	float matches = 1.0 - smoothstep(tolerance, tolerance * 1.5, distance(base.rgb, source_color.rgb));
	base.rgb = mix(base.rgb, replacement_color.rgb, matches);
	COLOR = base;
}
