shader_type spatial;
render_mode unshaded, cull_disabled, depth_test_disabled, shadows_disabled;
// แถบเลือดลอยเหนือหัว — หันเข้ากล้องเสมอ
// fill = เลือดปัจจุบัน, ghost = แถบสีอ่อนที่ค่อย ๆ ลดตาม (เห็นว่าเพิ่งเสียไปเท่าไร)

uniform float fill : hint_range(0.0, 1.0) = 1.0;
uniform float ghost : hint_range(0.0, 1.0) = 1.0;
uniform vec4 fill_color : source_color = vec4(0.86, 0.2, 0.2, 1.0);
uniform vec4 ghost_color : source_color = vec4(1.0, 0.85, 0.55, 1.0);
uniform vec4 bg_color : source_color = vec4(0.08, 0.05, 0.05, 0.85);
uniform vec2 bar_size = vec2(1.0, 0.11);

void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
}

void fragment() {
	vec2 px = UV * bar_size;
	float b = 0.016;
	vec4 c = bg_color;
	if (UV.x < ghost) { c = ghost_color; }
	if (UV.x < fill) { c = fill_color; }
	if (UV.y < 0.4 && UV.x < fill) { c.rgb *= 1.25; }
	if (px.x < b || px.y < b || px.x > bar_size.x - b || px.y > bar_size.y - b) { c = vec4(0.0, 0.0, 0.0, 1.0); }
	ALBEDO = c.rgb;
	ALPHA = c.a;
}
