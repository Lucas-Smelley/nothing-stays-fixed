shader_type canvas_item;

uniform float fade_speed : hint_range(0.1, 10.0) = 3.0;
uniform float min_alpha : hint_range(0.0, 1.0) = 0.3;
uniform float max_alpha : hint_range(0.0, 1.0) = 1.0;
uniform bool phase_active = false;

void fragment() {
    vec4 tex = texture(TEXTURE, UV);

    float alpha = tex.a;

    if (phase_active) {
        float pulse = sin(TIME * fade_speed) * 0.5 + 0.5;
        float target_alpha = mix(min_alpha, max_alpha, pulse);
        alpha *= target_alpha;
    }

    COLOR = vec4(tex.rgb, alpha);
}