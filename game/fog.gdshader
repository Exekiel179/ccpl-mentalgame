shader_type canvas_item;

uniform float radius : hint_range(0.05, 0.5) = 0.24;
uniform float softness : hint_range(0.01, 0.20) = 0.09;
uniform float clear_core : hint_range(0.02, 0.45) = 0.16;
uniform float cloud_scale : hint_range(1.0, 12.0) = 5.8;
uniform float cloud_strength : hint_range(0.0, 1.0) = 0.56;
uniform float reveal_boost : hint_range(0.0, 0.5) = 0.0;
uniform float completion_amount : hint_range(0.0, 1.0) = 0.0;
uniform float explored_strength : hint_range(0.0, 1.0) = 0.40;
uniform float explored_floor_boost : hint_range(0.0, 1.0) = 0.24;
uniform vec2 reveal_center = vec2(0.5, 0.5);
uniform vec2 canvas_offset = vec2(0.0, 0.0);
uniform vec2 maze_origin = vec2(0.0, 0.0);
uniform vec2 maze_size = vec2(1.0, 1.0);
uniform sampler2D explored_mask : source_color, filter_linear, repeat_disable;
uniform vec4 fog_tint : source_color = vec4(0.82, 0.84, 0.85, 0.92);
uniform vec4 ground_tint : source_color = vec4(0.97, 0.94, 0.88, 0.0);
uniform vec4 motif_color : source_color = vec4(0.60, 0.66, 0.72, 0.28);
uniform vec4 grass_glow : source_color = vec4(0.68, 0.80, 0.62, 0.40);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

float fbm(vec2 p) {
	float value = 0.0;
	float amplitude = 0.5;
	for (int i = 0; i < 5; i++) {
		value += amplitude * noise(p);
		p *= 2.0;
		amplitude *= 0.5;
	}
	return value;
}

void fragment() {
	float aspect = VIEWPORT_SIZE.x / max(VIEWPORT_SIZE.y, 1.0);
	vec2 centered_uv = (UV - reveal_center) * vec2(aspect, 1.0);
	float dist = length(centered_uv);
	vec2 screen_pos = UV * VIEWPORT_SIZE;
	vec2 world_pos = screen_pos - canvas_offset;
	vec2 mask_uv = (world_pos - maze_origin) / max(maze_size, vec2(1.0, 1.0));
	float explored = 0.0;
	if (all(greaterThanEqual(mask_uv, vec2(0.0))) ) {
		if (all(lessThanEqual(mask_uv, vec2(1.0)))) {
			explored = texture(explored_mask, mask_uv).r;
		}
	}

	float active_radius = radius + reveal_boost + completion_amount * 1.5;
	float core_radius = min(clear_core + reveal_boost * 0.6 + completion_amount * 1.0, active_radius - 0.02);
	if (dist <= core_radius) {
		discard;
	}

	float fog_transition = smoothstep(core_radius, active_radius, dist);
	float reveal_mask = 1.0 - smoothstep(active_radius - softness, active_radius + softness, dist);
	float current_visibility = 1.0 - fog_transition;
	float explored_visibility = explored * explored_strength * (1.0 - current_visibility * 0.65);
	float visibility = clamp(max(current_visibility, explored_visibility), 0.0, 1.0);

	vec2 cloud_uv = UV * cloud_scale + vec2(TIME * 0.018, TIME * 0.012);
	float cloud_noise = fbm(cloud_uv);
	float cloud_alpha = (0.38 + cloud_noise * 0.56) * cloud_strength;
	float fog_alpha = cloud_alpha * (1.0 - visibility) * (1.0 - completion_amount);

	float geometry = step(0.72, fbm(UV * 10.0 + vec2(4.0, -2.0)));
	float geometry_alpha = geometry * 0.08 * (1.0 - reveal_mask) * (1.0 - completion_amount) * (1.0 - visibility);

	float grass_shape = smoothstep(0.66, 0.96, fbm(UV * 13.0 + vec2(-3.0, 6.0)));
	float grass_alpha = grass_shape * visibility * (0.03 + reveal_boost * 0.28 + completion_amount * 0.16 + explored * 0.08);

	vec3 base_color = ground_tint.rgb * clamp(visibility + explored * explored_floor_boost, 0.0, 1.0);
	vec3 fog_color = fog_tint.rgb * fog_alpha;
	vec3 motif = motif_color.rgb * geometry_alpha;
	vec3 grass = grass_glow.rgb * grass_alpha;

	float alpha = clamp(max(max(fog_alpha, geometry_alpha), grass_alpha * 0.65), 0.0, 1.0);
	COLOR = vec4(base_color + fog_color + motif + grass, alpha);
}
