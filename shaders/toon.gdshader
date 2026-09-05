shader_type spatial;
render_mode specular_disabled;
uniform vec4 base_color : source_color = vec4(0.8, 0.8, 0.8, 1.0);
uniform sampler2D albedo : source_color, hint_default_white, filter_linear_mipmap;
uniform bool recolor = false;
uniform float glow = 0.0;
uniform float cut_side = 0.0;
varying vec3 local_vertex;
void vertex() { local_vertex = VERTEX; }
void fragment() {
    if (cut_side != 0.0 && local_vertex.x * cut_side < 0.0) { discard; }
	vec3 texel = texture(albedo, UV).rgb;
	if (recolor) {
		texel = vec3(sqrt(dot(texel, vec3(0.2126, 0.7152, 0.0722))));
	}
	ALBEDO = texel * base_color.rgb * COLOR.rgb;
    ROUGHNESS = 0.78;
    SPECULAR = 0.0;
    EMISSION = ALBEDO * glow;
}

void light() {
    float facing = dot(NORMAL, LIGHT);
    float band = facing > 0.55 ? 1.0 : (facing > 0.05 ? 0.65 : 0.2);
    DIFFUSE_LIGHT += band * ATTENUATION * LIGHT_COLOR / PI;
}
