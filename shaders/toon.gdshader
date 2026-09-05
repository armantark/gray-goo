shader_type spatial;
render_mode diffuse_toon, specular_toon;
uniform vec4 base_color : source_color = vec4(0.8, 0.8, 0.8, 1.0);
uniform float glow = 0.0;
uniform float cut_side = 0.0;
varying vec3 local_vertex;
void vertex() { local_vertex = VERTEX; }
void fragment() {
    if (cut_side != 0.0 && local_vertex.x * cut_side < 0.0) { discard; }
    ALBEDO = base_color.rgb * COLOR.rgb;
    ROUGHNESS = 0.78;
    SPECULAR = 0.28;
    EMISSION = base_color.rgb * glow;
}
