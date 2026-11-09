shader_type canvas_item;
// 배경 그림의 바다 부분만 일렁이게 한다 (새로 그리지 않고 받은 그림을 움직인다).
// - water_top ~ water_bottom (그림 세로 비율) 사이에서, 바다색(파랑이 빨강보다 진한 곳)만 움직인다
//   그래서 테트라포드, 섬, 등대 바위는 그대로 있다
// - 멀리는 잔잔하게, 가까이는 크게 출렁인다
// - 그림 속 하얀 물결 반짝임은 자리마다 다른 박자로 깜빡인다

uniform float water_top = 0.345;
uniform float water_bottom = 0.70;
uniform float strength = 1.0;

float water_mask(vec4 c) {
	return smoothstep(0.06, 0.18, c.b - c.r);
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 uv = UV;
	float band = smoothstep(water_top, water_top + 0.012, uv.y) * (1.0 - smoothstep(water_bottom - 0.01, water_bottom, uv.y));
	float depth = clamp((uv.y - water_top) / (water_bottom - water_top), 0.0, 1.0); // 0 먼 물, 1 가까운 물
	float amp = mix(0.0008, 0.0062, depth * depth) * strength;
	// 가로로 길게 밀려오는 물결 두 겹
	float w1 = sin(uv.y * mix(520.0, 160.0, depth) - TIME * 1.7 + sin(uv.x * 9.0 + TIME * 0.4) * 1.5);
	float w2 = sin(uv.x * 34.0 + uv.y * 70.0 + TIME * 1.1);
	vec2 off = vec2(w1 * amp, (w1 * 0.6 + w2 * 0.4) * amp * 0.45);
	vec4 base = texture(TEXTURE, uv);
	vec4 moved = texture(TEXTURE, uv + off * band);
	float m = band * water_mask(base) * water_mask(moved);
	vec4 col = mix(base, moved, m);
	// 반짝임: 원래 밝은 물결 픽셀만 자리마다 다른 박자로 밝아졌다 어두워졌다
	float lum = dot(col.rgb, vec3(0.299, 0.587, 0.114));
	float hi = smoothstep(0.62, 0.85, lum) * m;
	float cell = hash(floor(uv * vec2(90.0, 260.0)));
	float tw = 0.5 + 0.5 * sin(TIME * (1.5 + cell * 2.5) + cell * 6.28);
	col.rgb += hi * (tw - 0.45) * 0.35 * strength;
	COLOR = col * COLOR;
}
