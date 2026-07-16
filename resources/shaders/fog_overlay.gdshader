shader_type canvas_item;

uniform sampler2D noise_texture : repeat_enable;
uniform vec4 fog_color : source_color = vec4(0.7, 0.8, 0.9, 0.35);
uniform vec2 drift = vec2(0.015, 0.0);
uniform float density : hint_range(0.0, 1.0) = 0.4;

void fragment() {
	float noise = texture(noise_texture, UV + TIME * drift).r;
	COLOR = vec4(fog_color.rgb, fog_color.a * smoothstep(1.0 - density, 1.0, noise)) * COLOR;
}
