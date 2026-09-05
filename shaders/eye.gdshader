shader_type spatial;
render_mode unshaded;

uniform vec3 gaze = vec3(0.0, 0.0, 1.0);
uniform vec4 white : source_color = vec4(0.94, 0.96, 0.91, 1.0);
uniform vec4 ink : source_color = vec4(0.025, 0.045, 0.055, 1.0);
varying vec3 eye_position;

void vertex() {
	eye_position = VERTEX;
}

void fragment() {
	float alignment = dot(normalize(eye_position), gaze);
	float edge = max(fwidth(alignment), 0.001);
	float pupil = smoothstep(0.86 - edge, 0.86 + edge, alignment);
	ALBEDO = mix(white.rgb, ink.rgb, pupil);
}
