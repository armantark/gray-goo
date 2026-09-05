shader_type spatial;
render_mode blend_mix, depth_draw_always, cull_disabled, diffuse_burley, specular_schlick_ggx;

uniform vec4 pigment : source_color = vec4(0.16, 0.66, 0.79, 0.68);
uniform bool fabric = false;
uniform sampler2D albedo : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D depletion_mask : filter_linear, repeat_disable;
uniform vec2 extent = vec2(1.0);
uniform float mask_threshold = 0.015;
varying vec3 surface_point;

void vertex() {
	surface_point = VERTEX;
	float wave = sin(VERTEX.x * 1.8 + TIME * 0.65) * cos(VERTEX.z * 1.45 - TIME * 0.5);
	VERTEX.y += wave * (fabric ? 0.035 : 0.018);
}

void fragment() {
	vec2 texels = vec2(textureSize(depletion_mask, 0));
	vec2 uv = surface_point.xz / (extent * 2.0) + 0.5;
	float fill = texture(depletion_mask, (uv * (texels - 1.0) + 0.5) / texels).r;
	if (fill <= mask_threshold) { discard; }
	float ripple = sin(surface_point.x * 3.4 + surface_point.z * 1.7 + TIME * 0.8);
	float glint = pow(max(0.0, ripple), 18.0);
	vec3 color = pigment.rgb;
	if (fabric) {
		color = texture(albedo, surface_point.xz / 48.0).rgb * 0.035;
		glint = 0.0;
		EMISSION = color * 0.1;
	}
	ALBEDO = color + glint * 0.075;
	ROUGHNESS = fabric ? 0.58 : 0.18;
	METALLIC = fabric ? 0.0 : 0.08;
	ALPHA = pigment.a * smoothstep(mask_threshold, 0.08, fill);
}
