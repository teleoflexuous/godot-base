shader_type canvas_item;

uniform sampler2D noise_texture : repeat_enable;
uniform float threshold : hint_range(0.0, 1.0) = 0.0;
uniform float edge_width : hint_range(0.0, 0.2) = 0.03;
uniform vec4 edge_color : source_color = vec4(1.0, 0.5, 0.1, 1.0);

void fragment() {
	vec4 base = texture(TEXTURE, UV) * COLOR;
	float noise = texture(noise_texture, UV).r;
	float visible = step(threshold, noise);
	float edge = visible * (1.0 - smoothstep(threshold, threshold + max(edge_width, 0.0001), noise));
	base.rgb = mix(base.rgb, edge_color.rgb, edge);
	base.a *= visible;
	COLOR = base;
}
