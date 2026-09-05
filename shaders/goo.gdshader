shader_type spatial;
render_mode diffuse_toon, specular_toon;

uniform float celebration : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	float facing = clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0);
	vec3 pigment = mix(COLOR.rgb, vec3(1.0, 0.95, 0.78), celebration * 0.6);
	ALBEDO = pigment * mix(0.25, 1.0, smoothstep(0.02, 0.2, facing));
	ROUGHNESS = 0.38;
	SPECULAR = 0.55;
	EMISSION = pigment * celebration * 0.55;
}
