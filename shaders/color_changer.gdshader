shader_type canvas_item;

uniform vec4 tint : source_color = vec4(1.0); // set per-layer
uniform float strength : hint_range(0.0, 1.0) = 1.0; // 1 = full tint, 0 = no tint

void fragment() {
    vec4 tex = texture(TEXTURE, UV);

    // Preserve original alpha
    vec3 tinted = tex.rgb * tint.rgb;

    // Blend between original and tinted
    vec3 out_rgb = mix(tex.rgb, tinted, strength);

    COLOR = vec4(out_rgb, tex.a);
}
