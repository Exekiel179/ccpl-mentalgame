shader_type canvas_item;

uniform float radius : hint_range(0.05, 0.5) = 0.18;
uniform float softness : hint_range(0.01, 0.1) = 0.04;

void fragment() {
	float aspect = 1280.0 / 720.0;
	vec2 uv = (UV - vec2(0.5)) * vec2(aspect, 1.0);
	float dist = length(uv);
	float alpha = smoothstep(radius - softness, radius + softness, dist);
	COLOR = vec4(0.0, 0.0, 0.0, alpha * 0.97);
}
