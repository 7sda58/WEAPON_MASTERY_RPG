class_name SlashEffect
extends MeshInstance3D
## รอยดาบโค้งตอนฟัน — ติดไปกับตัวผู้ฟัน แล้วจางหายเอง
## Task 2.12 — Combat Feedback
## เรียกใช้: SlashEffect.spawn(self, Vector3(0, 0.8, 0), yaw)

static var _arc_mesh: ArrayMesh


static func spawn(parent: Node3D, local_pos: Vector3, yaw: float, color: Color = Color(1.0, 0.97, 0.8)) -> void:
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
	s.rotation = Vector3(deg_to_rad(-12.0), yaw, 0.0)  # เอียงเล็กน้อยให้มองเห็นจากกล้องด้านหลัง
	s.scale = Vector3.ONE * 0.75
	var t := s.create_tween().set_parallel(true)
	t.tween_property(s, "scale", Vector3.ONE * 1.1, 0.16).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.tween_property(s, "rotation:y", yaw + 0.5, 0.16)                  # กวาดจากขวาไปซ้าย (ตามดาบ)
	t.tween_property(mat, "albedo_color:a", 0.0, 0.2).set_delay(0.04)
	t.chain().tween_callback(s.queue_free)


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
