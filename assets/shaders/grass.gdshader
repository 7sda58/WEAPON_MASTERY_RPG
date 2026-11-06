shader_type spatial;
render_mode cull_disabled, diffuse_lambert, specular_disabled;
// หญ้าไหวตามลม — สีมาจาก vertex color (โคนเข้ม ปลายอ่อน)

uniform float wind_strength = 0.12;
uniform float wind_speed = 1.6;
uniform vec3 tip_tint : source_color = vec3(1.0);

void vertex() {
	// เฉพาะส่วนบนของใบหญ้าที่ไหว (VERTEX.y มากขึ้น = ไหวมากขึ้น)
	vec3 world = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	float sway = sin(TIME * wind_speed + world.x * 0.35 + world.z * 0.25);
	float gust = sin(TIME * 0.5 + world.x * 0.05) * 0.5 + 0.5;
	VERTEX.x += sway * wind_strength * VERTEX.y * (0.6 + gust);
	VERTEX.z += cos(TIME * wind_speed * 0.8 + world.z * 0.3) * wind_strength * 0.5 * VERTEX.y;
}

void fragment() {
	ALBEDO = COLOR.rgb * mix(vec3(1.0), tip_tint, COLOR.a);
	ROUGHNESS = 0.95;
}
