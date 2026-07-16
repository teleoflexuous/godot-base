shader_type canvas_item;

uniform float strength : hint_range(0.0, 0.08) = 0.02;
uniform float speed : hint_range(0.0, 8.0) = 1.5;

void vertex() {
	float weight = UV.y;
	VERTEX.x += sin(TIME * speed + VERTEX.y * 0.1) * strength * 100.0 * weight;
}
