// Port of the reference's chroma_glitch.frag (../edgard_in_kimeria/shaders,
// carried into edgard_in_kimeria_libgdx and edgard_in_kimeria_rs's
// postprocess.rs as chroma_intensity/chroma_shift): a chromatic-aberration
// glitch with a horizontal shake, sampled from the frozen frame while paused.
shader_type canvas_item;

uniform float u_time = 0.0;
uniform float u_intensity = 1.0;
uniform float u_shift = 0.01;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

void fragment() {
	vec2 uv = SCREEN_UV;

	float red_shift = u_intensity * u_shift;
	float blue_shift = -u_intensity * u_shift;

	float shake_x = sin(u_time * 15.0) * (u_shift * 0.25) * u_intensity;
	vec2 shaken_uv = uv + vec2(shake_x, 0.0);

	vec2 red_uv = clamp(shaken_uv + vec2(red_shift, 0.0), vec2(0.0), vec2(1.0));
	vec2 green_uv = clamp(shaken_uv, vec2(0.0), vec2(1.0));
	vec2 blue_uv = clamp(shaken_uv + vec2(blue_shift, 0.0), vec2(0.0), vec2(1.0));

	float red = texture(screen_texture, red_uv).r;
	float green = texture(screen_texture, green_uv).g;
	float blue = texture(screen_texture, blue_uv).b;

	COLOR = vec4(red, green, blue, 1.0);
}
