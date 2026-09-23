shader_type spatial;
render_mode specular_disabled;

uniform vec4 base_color : source_color;
uniform sampler2D albedo : source_color, hint_default_white, repeat_enable, filter_linear_mipmap;
uniform float grain_scale = 4.0;
varying vec2 ground_point;

void vertex() {
    ground_point = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
}

void fragment() {
    ALBEDO = texture(albedo, ground_point / grain_scale).rgb * base_color.rgb;
    ROUGHNESS = 1.0;
}

void light() {
    float facing = dot(NORMAL, LIGHT);
    // Terrain shades smoothly, because a stepped band draws a sharp-edged patch wherever a curved
    // slope, such as the Skatepark bowl's walls, turns across the step toward a light.
    float band = mix(0.2, 1.0, smoothstep(0.0, 0.7, facing));
    DIFFUSE_LIGHT += band * ATTENUATION * LIGHT_COLOR / PI;
}
