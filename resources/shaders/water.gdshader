shader_type canvas_item;

uniform vec2 flow_direction = vec2(0.08, 0.02);
uniform float wave_strength : hint_range(0.0, 0.05) = 0.008;
uniform float wave_frequency : hint_range(1.0, 40.0) = 12.0;

void fragment() {
	vec2 offset = vec2(sin((UV.y + TIME * flow_direction.x) * wave_frequency), cos((UV.x + TIME * flow_direction.y) * wave_frequency)) * wave_strength;
	COLOR = texture(TEXTURE, UV + offset) * COLOR;
}
