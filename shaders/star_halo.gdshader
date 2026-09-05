shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled;
uniform vec4 color : source_color = vec4(1.0, 0.9, 0.7, 1.0);
void fragment() {
	float radius = length(UV * 2.0 - 1.0);
	ALBEDO = color.rgb * COLOR.rgb;
	ALPHA = exp(-radius * radius * 6.0) * (1.0 - smoothstep(0.65, 1.0, radius)) * 0.5 * COLOR.a;
}
