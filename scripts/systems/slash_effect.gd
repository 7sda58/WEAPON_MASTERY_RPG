class_name SlashEffect
extends MeshInstance3D
## รอยอาวุธ — ฟัน/ปัด = รอยโค้ง, แทง = รอยพุ่งตรง — ติดไปกับตัวผู้โจมตี แล้วจางหายเอง
## Task 2.12 — Combat Feedback
## เรียกใช้: SlashEffect.spawn(self, Vector3(0, 0.8, 0), yaw)          ← ฟัน
##          SlashEffect.spawn_thrust(self, Vector3(0, 0.75, 0), yaw, 2.5) ← แทง

static var _arc_mesh: ArrayMesh
static var _thrust_mesh: ArrayMesh


## sweep_sign: +1 = กวาดจากขวาไปซ้าย, -1 = จากซ้ายไปขวา | size: ขนาดวงโค้ง (1 = ดาบ)
## tilt_deg: เอียงระนาบรอยฟัน (องศา) — 0 = แนวนอน, ลบ = ด้านขวาต่ำ, บวก = ด้านขวาสูง
static func spawn(parent: Node3D, local_pos: Vector3, yaw: float, color: Color = Color(1.0, 0.97, 0.8), sweep_sign: float = 1.0, size: float = 1.0, tilt_deg: float = 0.0) -> void:
	var s := SlashEffect.new()
	s.mesh = _get_mesh()
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.vertex_color_use_as_albedo = true
	mat.albedo_color = color
	s.material_override = mat
	s.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(s)
	s.position = local_pos
	s.rotation = Vector3(deg_to_rad(-12.0), yaw, deg_to_rad(tilt_deg))  # เอียงเล็กน้อยให้มองเห็นจากกล้องด้านหลัง
	s.scale = Vector3.ONE * 0.75 * size
	var t := s.create_tween().set_parallel(true)
	t.tween_property(s, "scale", Vector3.ONE * 1.1 * size, 0.16).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.tween_property(s, "rotation:y", yaw + 0.5 * sweep_sign, 0.16)     # กวาดตามทิศอาวุธ
	t.tween_property(mat, "albedo_color:a", 0.0, 0.2).set_delay(0.04)
	t.chain().tween_callback(s.queue_free)


## รอยแทง: แท่งแสงรูปเพชรยาวพุ่งไปข้างหน้า (แนวนอน + แนวตั้ง มองเห็นได้ทุกมุม)
## length = ระยะปลายรอย (เมตร)
static func spawn_thrust(parent: Node3D, local_pos: Vector3, yaw: float, length: float, color: Color = Color(0.85, 0.95, 1.0)) -> void:
	var s := SlashEffect.new()
	s.mesh = _get_thrust_mesh()
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.vertex_color_use_as_albedo = true
	mat.albedo_color = color
	s.material_override = mat
	s.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var cross := MeshInstance3D.new()      # แผ่นแนวตั้ง ตัดกับแผ่นแนวนอน
	cross.mesh = s.mesh
	cross.material_override = mat
	cross.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	cross.rotation.z = PI / 2.0
	s.add_child(cross)
	parent.add_child(s)
	s.position = local_pos
	s.rotation = Vector3(0.0, yaw, 0.0)
	s.scale = Vector3(1.0, 1.0, length * 0.35)
	var t := s.create_tween().set_parallel(true)
	t.tween_property(s, "scale", Vector3(0.7, 0.7, length), 0.08).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.tween_property(mat, "albedo_color:a", 0.0, 0.16).set_delay(0.05)
	t.chain().tween_callback(s.queue_free)


## รูปเพชรยาว 1 หน่วย (ฐานที่ z=0 ปลายที่ z=-1) — ฐานโปร่ง ปลายสว่าง
static func _get_thrust_mesh() -> ArrayMesh:
	if _thrust_mesh:
		return _thrust_mesh
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var base := Vector3(0, 0, 0.0)
	var wide_l := Vector3(-0.14, 0, -0.7)
	var wide_r := Vector3(0.14, 0, -0.7)
	var tip := Vector3(0, 0, -1.0)
	var c_base := Color(1, 1, 1, 0.0)
	var c_wide := Color(1, 1, 1, 0.75)
	var c_tip := Color(1, 1, 1, 1.0)
	st.set_color(c_base); st.add_vertex(base)
	st.set_color(c_wide); st.add_vertex(wide_l)
	st.set_color(c_wide); st.add_vertex(wide_r)
	st.set_color(c_wide); st.add_vertex(wide_l)
	st.set_color(c_tip); st.add_vertex(tip)
	st.set_color(c_wide); st.add_vertex(wide_r)
	_thrust_mesh = st.commit()
	return _thrust_mesh


## สร้างรูปพระจันทร์เสี้ยวครั้งเดียวแล้วใช้ซ้ำ — ขอบนอกสว่าง ขอบในโปร่ง ปลายสองข้างจาง
static func _get_mesh() -> ArrayMesh:
	if _arc_mesh:
		return _arc_mesh
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var seg: int = 16
	var inner: float = 0.45
	var outer: float = 1.4
	var half_angle: float = deg_to_rad(75.0)
	for i in seg:
		var a0: float = lerpf(-half_angle, half_angle, float(i) / seg)
		var a1: float = lerpf(-half_angle, half_angle, float(i + 1) / seg)
		var f0: float = sin(PI * float(i) / seg)
		var f1: float = sin(PI * float(i + 1) / seg)
		var d0 := Vector3(sin(a0), 0.0, -cos(a0))
		var d1 := Vector3(sin(a1), 0.0, -cos(a1))
		var o0 := Color(1, 1, 1, 0.95 * f0)
		var o1 := Color(1, 1, 1, 0.95 * f1)
		var n := Color(1, 1, 1, 0.0)
		st.set_color(n); st.add_vertex(d0 * inner)
		st.set_color(o0); st.add_vertex(d0 * outer)
		st.set_color(o1); st.add_vertex(d1 * outer)
		st.set_color(n); st.add_vertex(d0 * inner)
		st.set_color(o1); st.add_vertex(d1 * outer)
		st.set_color(n); st.add_vertex(d1 * inner)
	_arc_mesh = st.commit()
	return _arc_mesh
