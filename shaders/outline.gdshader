shader_type spatial;
render_mode cull_front, unshaded;
uniform float width = 2.5;
uniform vec4 ink : source_color = vec4(0.055, 0.08, 0.10, 1.0);
void vertex() {
    vec4 clip = PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
    vec3 normal_view = normalize(MODELVIEW_NORMAL_MATRIX * NORMAL);
    vec2 direction = (PROJECTION_MATRIX * vec4(normal_view, 0.0)).xy;
    clip.xy += direction / max(length(direction), 0.0001) * width * 2.0 / VIEWPORT_SIZE * clip.w;
    POSITION = clip;
}
void fragment() { ALBEDO = ink.rgb; }
