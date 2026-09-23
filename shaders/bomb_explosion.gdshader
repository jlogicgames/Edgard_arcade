// Port of the reference's bomb_explosion.frag (Krapas, shadertoy.com/view/X3dGz2,
// via assets/shaders/bomb_explosion.frag in edgard_in_kimeria_libgdx).
shader_type canvas_item;

uniform vec2 u_size = vec2(64.0, 64.0);
uniform float u_time = 0.0;
uniform float u_progress = 0.0;

vec3 n_rand3(vec3 p) {
	vec3 r = fract(sin(vec3(
		dot(p, vec3(127.1, 311.7, 371.8)),
		dot(p, vec3(269.5, 183.3, 456.1)),
		dot(p, vec3(352.5, 207.3, 198.67))
	)) * 43758.5453) * 2.0 - 1.0;
	return normalize(vec3(r.x / cos(r.x), r.y / cos(r.y), r.z / cos(r.z)));
}

float noise(vec3 p) {
	vec3 fv = fract(p);
	vec3 nv = floor(p);
	vec3 u = fv * fv * fv * (fv * (fv * 6.0 - 15.0) + 10.0);
	return mix(
		mix(
			mix(dot(n_rand3(nv + vec3(0.0, 0.0, 0.0)), fv - vec3(0.0, 0.0, 0.0)),
				dot(n_rand3(nv + vec3(1.0, 0.0, 0.0)), fv - vec3(1.0, 0.0, 0.0)), u.x),
			mix(dot(n_rand3(nv + vec3(0.0, 1.0, 0.0)), fv - vec3(0.0, 1.0, 0.0)),
				dot(n_rand3(nv + vec3(1.0, 1.0, 0.0)), fv - vec3(1.0, 1.0, 0.0)), u.x),
			u.y),
		mix(
			mix(dot(n_rand3(nv + vec3(0.0, 0.0, 1.0)), fv - vec3(0.0, 0.0, 1.0)),
				dot(n_rand3(nv + vec3(1.0, 0.0, 1.0)), fv - vec3(1.0, 0.0, 1.0)), u.x),
			mix(dot(n_rand3(nv + vec3(0.0, 1.0, 1.0)), fv - vec3(0.0, 1.0, 1.0)),
				dot(n_rand3(nv + vec3(1.0, 1.0, 1.0)), fv - vec3(1.0, 1.0, 1.0)), u.x),
			u.y),
		u.z);
}

float worley(vec3 s) {
	vec3 si = floor(s);
	vec3 sf = fract(s);
	float m_dist = 1.0;
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			for (int z = -1; z <= 1; z++) {
				vec3 neighbor = vec3(float(x), float(y), float(z));
				vec3 point = fract(n_rand3(si + neighbor));
				point = 0.5 + 0.5 * sin(u_time + 6.2831 * point);
				vec3 diff = neighbor + point - sf;
				m_dist = min(m_dist, length(diff));
			}
		}
	}
	return m_dist;
}

float boom(vec2 p, float t) {
	float repeat = t;
	float shape = 1.0 - pow(distance(vec3(p, 0.0), vec3(0.0)), 2.0) / (repeat * 12.0) - repeat * 2.0;
	float distortion = noise(vec3(p * 0.5, u_time * 0.5));
	float bubbles = 0.5 - pow(worley(vec3(p * 1.2, u_time * 2.0)), 3.0);
	float bw = 0.5;
	return shape + (bw * bubbles + (1.0 - bw) * distortion);
}

float smoke(vec2 p, float t) {
	float repeat = t;
	vec2 drift = vec2(0.0, 2.0) * pow(repeat / 1.45, 2.0) * 1.5;
	float shape = 1.0 - pow(distance(vec3(p + drift, 0.0), vec3(0.0)), 2.0) / (repeat * 16.0) - pow(repeat * 1.5, 0.5);
	float distortion = noise(vec3(p * 1.5 + drift, u_time * 0.1));
	vec2 drift2 = vec2(0.0, 2.0) * pow(repeat / 1.65, 2.0) * 1.5;
	float bubbles = 0.5 - pow(worley(vec3((p / pow(repeat, 0.35)) + drift2, u_time * 0.1)), 2.0);
	float bw = 0.75;
	return shape + (bw * bubbles + (1.0 - bw) * distortion);
}

float posterize(float v, float n) {
	return floor(v * n) / (n - 1.0);
}

void fragment() {
	vec3 boom_pal0 = vec3(0.2, 0.15, 0.3);
	vec3 boom_pal1 = vec3(0.9, 0.15, 0.05);
	vec3 boom_pal2 = vec3(0.9, 0.5, 0.1);
	vec3 boom_pal3 = vec3(0.95, 0.95, 0.35);
	vec3 smoke_pal0 = vec3(0.2, 0.15, 0.3);
	vec3 smoke_pal1 = vec3(0.35, 0.3, 0.45);
	vec3 smoke_pal2 = vec3(0.5, 0.45, 0.6);

	vec2 uv = UV;
	vec2 center = vec2(0.5, 0.4);
	vec2 p = uv - center;
	p.x *= u_size.x / u_size.y;
	p *= 7.0;
	float t = max(u_progress, 0.01);

	float bpl = 4.0;
	float spl = 3.0;

	float boom_val = boom(p, t);
	float boom_a = step(0.0, boom_val);
	int boom_idx = int(clamp(posterize(boom_val, bpl) * bpl, 0.0, bpl - 1.0));
	vec3 boom_col = boom_pal0;
	if (boom_idx == 1) {
		boom_col = boom_pal1;
	} else if (boom_idx == 2) {
		boom_col = boom_pal2;
	} else if (boom_idx == 3) {
		boom_col = boom_pal3;
	}
	boom_col = boom_col - vec3(1.0 - boom_a);

	float smoke_val = smoke(p, t);
	float smoke_a = step(0.0, smoke_val);
	int smoke_idx = int(clamp(posterize(smoke_val, spl) * spl, 0.0, spl - 1.0));
	vec3 smoke_col = smoke_pal0;
	if (smoke_idx == 1) {
		smoke_col = smoke_pal1;
	} else if (smoke_idx == 2) {
		smoke_col = smoke_pal2;
	}
	smoke_col = smoke_col - vec3(1.0 - smoke_a);

	float bw = step(smoke_val * 1.25, boom_val);
	vec3 color = bw * boom_col + (1.0 - bw) * smoke_col;
	float alpha = bw * boom_a + (1.0 - bw) * smoke_a;

	float ground_fade = smoothstep(0.18, 0.0, p.y / 7.0);
	alpha *= ground_fade;

	COLOR = vec4(color, alpha);
}
