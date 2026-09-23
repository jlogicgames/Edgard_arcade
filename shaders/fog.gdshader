// Port of the reference's fog.frag (originally Flame's crystal_ball example,
// via assets/shaders/fog.frag in edgard_in_kimeria_libgdx): a full-viewport
// drifting fog overlay.
shader_type canvas_item;

uniform vec2 u_size = vec2(640.0, 360.0);
uniform float u_ground_pos = 0.0;
uniform float u_ground_add = 0.0;
uniform float u_fade = 1.0;
uniform float u_time = 0.0;

float hash(vec2 p) {
	p = 50.0 * fract(p * 0.3183099 + vec2(0.71, 0.113));
	return -1.0 + 2.0 * fract(p.x * p.y * (p.x + p.y));
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);
	return mix(mix(hash(i + vec2(0.0, 0.0)), hash(i + vec2(1.0, 0.0)), u.x),
			   mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fractal_noise(vec2 uv) {
	float f = 0.0;
	uv *= 8.0;
	mat2 m = mat2(vec2(1.6, 1.2), vec2(-1.2, 1.6));
	f = 0.5000 * noise(uv);
	uv = m * uv;
	f += 0.2500 * noise(uv);
	uv = m * uv;
	f += 0.1250 * noise(uv);
	uv = m * uv;
	f += 0.0625 * noise(uv);
	return 0.5 + 0.5 * f;
}

vec4 layer(vec2 uv, float time_mult) {
	float waterline = u_ground_pos;
	float fade = u_fade;

	float tr = step(waterline - fade, uv.y);
	tr *= smoothstep(waterline - fade, waterline, uv.y);
	uv.y -= u_ground_add;
	uv.x += u_time * time_mult;

	float f = fractal_noise(uv);
	f *= tr;
	f *= 0.65;
	f = pow(f, 1.8);
	return vec4(vec3(0.8, 0.4, 1.0) * f, f);
}

void fragment() {
	vec2 uv = UV * vec2(u_size.x / u_size.y, 1.0);
	COLOR = layer(uv, 0.015) + layer(uv, -0.08);
}
