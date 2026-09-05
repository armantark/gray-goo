shader_type spatial;
render_mode specular_disabled;

uniform float celebration : hint_range(0.0, 1.0) = 0.0;

void vertex() {
	COLOR.rgb = mix(COLOR.rgb / 12.92, pow((COLOR.rgb + 0.055) / 1.055, vec3(2.4)), step(vec3(0.04045), COLOR.rgb));
}

void fragment() {
	float facing = clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0);
	vec3 pigment = mix(COLOR.rgb, vec3(1.0, 0.95, 0.78), celebration * 0.6);
	ALBEDO = pigment * mix(0.4, 1.0, smoothstep(0.02, 0.16, facing));
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
	EMISSION = pigment * celebration * 0.4;
}

void light() {
	float diffuse = dot(normalize(NORMAL), normalize(LIGHT));
	float band = mix(0.35, 0.72, step(0.1, diffuse));
	band = mix(band, 1.0, step(0.58, diffuse));
	DIFFUSE_LIGHT += LIGHT_COLOR * ATTENUATION * band / PI;
}
