shader_type spatial;
render_mode cull_front, unshaded;
uniform float width = 0.012;
uniform vec4 ink : source_color = vec4(0.055, 0.08, 0.10, 1.0);
void vertex() { VERTEX += NORMAL * width; }
void fragment() { ALBEDO = ink.rgb; }
