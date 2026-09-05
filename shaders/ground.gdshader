shader_type spatial;
render_mode specular_disabled;

uniform vec4 base_color : source_color;
uniform sampler2D albedo : source_color, hint_default_white, repeat_enable, filter_linear_mipmap;
uniform float grain_scale = 4.0;
varying vec2 ground_point;

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float grain(vec2 p) {
    vec2 cell = floor(p);
    vec2 blend = smoothstep(vec2(0.0), vec2(1.0), fract(p));
    return mix(mix(hash(cell), hash(cell + vec2(1.0, 0.0)), blend.x),
        mix(hash(cell + vec2(0.0, 1.0)), hash(cell + vec2(1.0, 1.0)), blend.x), blend.y);
}

void vertex() {
    ground_point = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
}

void fragment() {
    float mottling = grain(ground_point * grain_scale);
    float fine = grain(ground_point * grain_scale * 4.7);
    ALBEDO = texture(albedo, ground_point / grain_scale).rgb * base_color.rgb * (0.82 + mottling * 0.22 + fine * 0.1);
    ROUGHNESS = 1.0;
}

void light() {
    float facing = dot(NORMAL, LIGHT);
    float band = facing > 0.55 ? 1.0 : (facing > 0.05 ? 0.65 : 0.2);
    DIFFUSE_LIGHT += band * ATTENUATION * LIGHT_COLOR / PI;
}
