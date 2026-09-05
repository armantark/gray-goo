shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_back;

uniform sampler2D albedo : source_color, hint_default_white, filter_linear_mipmap;
uniform vec4 base_color : source_color = vec4(1.0);
uniform float density = 0.28;
uniform bool recolor = false;
uniform float core_radius = 0.0;
varying vec3 local_position;

void vertex() {
	local_position = VERTEX;
}

void fragment() {
	vec3 texel = texture(albedo, UV).rgb;
	float light = max(texel.r, max(texel.g, texel.b));
	float edge = pow(abs(dot(normalize(NORMAL), normalize(VIEW))), 1.8);
	vec3 color = recolor ? vec3(sqrt(light)) * base_color.rgb : texel * base_color.rgb;
	ALBEDO = color * 2.4;
	ALPHA = COLOR.a * edge * mix(density, 0.85, smoothstep(0.45, 0.9, light));
	if (core_radius > 0.0) {
		float core = max(0.0, 1.0 - length(local_position.xz) / core_radius);
		ALBEDO = mix(color, vec3(1.0, 0.93, 0.79), sqrt(core)) * 2.4;
		ALPHA *= pow(core, 1.3);
	}
}
