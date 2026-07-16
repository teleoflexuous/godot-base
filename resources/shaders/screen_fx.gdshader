shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.0;
uniform float crt_strength : hint_range(0.0, 1.0) = 0.0;
uniform float shockwave_strength : hint_range(0.0, 0.1) = 0.0;
uniform vec2 shockwave_center = vec2(0.5);

void fragment() {
	vec2 from_center = SCREEN_UV - shockwave_center;
	float distance_from_center = length(from_center);
	vec2 distorted_uv = SCREEN_UV + normalize(from_center + vec2(0.0001)) * shockwave_strength * sin(distance_from_center * 50.0 - TIME * 8.0);
	vec4 base = texture(screen_texture, distorted_uv);
	float vignette = 1.0 - smoothstep(0.25, 0.75, distance(SCREEN_UV, vec2(0.5))) * vignette_strength;
	float scanlines = mix(1.0, 0.82 + 0.18 * sin(SCREEN_UV.y * 900.0), crt_strength);
	COLOR = vec4(base.rgb * vignette * scanlines, base.a);
}
