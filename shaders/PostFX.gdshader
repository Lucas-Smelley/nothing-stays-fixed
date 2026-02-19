shader_type canvas_item;

uniform float vignette_strength : hint_range(0.0, 1.0) = 0.35;
uniform float vignette_softness : hint_range(0.1, 3.0) = 1.3;

uniform float scanline_strength : hint_range(0.0, 1.0) = 0.15;
uniform float scanline_density : hint_range(100.0, 800.0) = 360.0;

uniform float noise_strength : hint_range(0.0, 1.0) = 0.06;
uniform float chroma_strength : hint_range(0.0, 2.0) = 0.35;

uniform float warp_strength : hint_range(0.0, 1.0) = 0.08; // CRT curve
uniform float flicker_strength : hint_range(0.0, 1.0) = 0.04;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;


float rand(vec2 co) {
	return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}

vec2 crt_warp(vec2 uv) {
	// center to -1..1
	vec2 p = uv * 2.0 - 1.0;
	float r2 = dot(p, p);
	// barrel distortion
	p *= 1.0 + warp_strength * r2;
	// back to 0..1
	return (p * 0.5 + 0.5);
}

void fragment() {
	vec2 uv = SCREEN_UV;

	// CRT warp (slight)
	vec2 wuv = crt_warp(uv);

	// Sample with chromatic aberration (RGB offsets)
	vec2 dir = (wuv - vec2(0.5)) * 0.003 * chroma_strength;
	float r = textureLod(SCREEN_TEXTURE, wuv + dir, 0.0).r;
	float g = textureLod(SCREEN_TEXTURE, wuv, 0.0).g;
	float b = textureLod(SCREEN_TEXTURE, wuv - dir, 0.0).b;
	vec3 col = vec3(r, g, b);

	// Scanlines
	float scan = sin(wuv.y * scanline_density * 3.14159) * 0.5 + 0.5;
	col *= 1.0 - scanline_strength * (0.6 - scan);

	// Subtle flicker
	float flicker = (rand(vec2(TIME, 0.123)) - 0.5) * 2.0;
	col *= 1.0 + flicker * flicker_strength;

	// Noise / film grain
	float n = rand(wuv * vec2(1920.0, 1080.0) + TIME);
	col += (n - 0.5) * noise_strength;

	// Vignette
	vec2 d = uv - vec2(0.5);
	float dist = length(d);
	float vig = smoothstep(0.55, 0.55 * vignette_softness, dist);
	col *= 1.0 - vig * vignette_strength;

	COLOR = vec4(col, 1.0);
}
