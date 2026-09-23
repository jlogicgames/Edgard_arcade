// Port of the reference's shockwave.frag (assets/shaders/shockwave.frag in
// edgard_in_kimeria_libgdx): an expanding thin ring, used for pickups.
shader_type canvas_item;

uniform vec2 u_size = vec2(64.0, 64.0);
uniform float u_time = 0.0;
uniform float u_progress = 0.0;
uniform float u_max_radius = 0.5;
uniform float u_width = 0.1;
uniform vec3 u_color = vec3(1.0, 1.0, 1.0);

void fragment() {
	vec2 uv = UV;
	vec2 p = uv - vec2(0.5);
	p.x *= u_size.x / u_size.y;
	float dist = length(p);

	float ramp = smoothstep(0.02, 1.0, u_progress);
	float radius = u_max_radius * ramp;

	float ripple = (u_max_radius * 0.01) * sin(40.0 * dist - 6.0 * u_progress + u_time * 6.0);
	float w = max(0.001, u_width * (1.0 - u_progress * 0.8));

	float d = abs(dist - radius + ripple);
	float ring = 1.0 - smoothstep(0.5 * w, 1.5 * w, d);

	float fade = ramp * (1.0 - u_progress);
	float alpha = clamp(ring * fade, 0.0, 1.0);

	float mask = smoothstep(0.001, 0.004, alpha);
	COLOR = vec4(u_color * alpha * mask, alpha * mask);
}
