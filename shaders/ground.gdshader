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
    float band = facing > 0.55 ? 1.0 : (facing > 0.05 ? 0.65 : 0.2);
    DIFFUSE_LIGHT += band * ATTENUATION * LIGHT_COLOR / PI;
}
