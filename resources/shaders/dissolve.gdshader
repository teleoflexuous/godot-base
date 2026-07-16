shader_type canvas_item;

uniform sampler2D noise_texture : repeat_enable;
uniform float threshold : hint_range(0.0, 1.0) = 0.0;
uniform float edge_width : hint_range(0.0, 0.2) = 0.03;
uniform vec4 edge_color : source_color = vec4(1.0, 0.5, 0.1, 1.0);

void fragment() {
	vec4 base = texture(TEXTURE, UV) * COLOR;
	float noise = texture(noise_texture, UV).r;
	float visible = step(threshold, noise);
	float edge = smoothstep(threshold, threshold + edge_width, noise) - visible;
	COLOR = mix(vec4(edge_color.rgb, edge_color.a * edge), base, visible);
}
